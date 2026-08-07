//===- Exercise_2_3_4_ListSimplify.cpp --------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the `list-simplify` pass.
//
//===----------------------------------------------------------------------===//

#include "list/Transforms/ListPasses.h"

#include "list/IR/List.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir {
namespace list {

#define GEN_PASS_DEF_LISTSIMPLIFY
#include "list/Transforms/ListPasses.h.inc"

namespace {

//===----------------------------------------------------------------------===//
// Exercise 2: list.from_elements patterns
//===----------------------------------------------------------------------===//

/// Build a list without any element with `list.empty`.
struct ReplaceEmptyFromElements : OpRewritePattern<FromElementsOp> {
  using OpRewritePattern::OpRewritePattern;

  LogicalResult matchAndRewrite(FromElementsOp op,
                                PatternRewriter &rewriter) const override {
    if (!op.getElements().empty())
      return rewriter.notifyMatchFailure(op, "list has elements");

    rewriter.replaceOpWithNewOp<EmptyOp>(op, op.getResult().getType());
    return success();
  }
};

/// Peel the last element from `list.from_elements` into a `list.push_back`:
///
/// ```mlir
/// %li = list.from_elements %a, %b, %c : (i32, i32, i32) -> !list.list<i32>
/// ```
///
/// becomes:
///
/// ```mlir
/// %shorter = list.from_elements %a, %b : (i32, i32) -> !list.list<i32>
/// %li = list.push_back %shorter, %c : !list.list<i32>
/// ```
///
/// Repeated greedy application eventually leaves an empty `from_elements`,
/// which `ReplaceEmptyFromElements` replaces with `list.empty`.
struct PeelFromElements : OpRewritePattern<FromElementsOp> {
  using OpRewritePattern::OpRewritePattern;

  LogicalResult matchAndRewrite(FromElementsOp op,
                                PatternRewriter &rewriter) const override {
    if (op.getElements().empty())
      return rewriter.notifyMatchFailure(op, "list has no elements");

    Location loc = op.getLoc();
    Type resultType = op.getResult().getType();
    ValueRange elements = op.getElements();
    auto shorter = FromElementsOp::create(rewriter, loc, resultType,
                                          elements.drop_back());
    rewriter.replaceOpWithNewOp<PushBackOp>(op, shorter.getResult(),
                                            elements.back());
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Exercise 3: merge consecutive list.map operations
//===----------------------------------------------------------------------===//

/// Merge a `list.map` whose operand is produced by another `list.map` into a
/// single `list.map` that applies both computations to every element:
///
/// ```mlir
/// %0 = list.map %x with (%a: i32) -> i32 { ... list.yield %p : i32 }
/// %1 = list.map %0 with (%b: i32) -> i64 { ... list.yield %c : i64 }
/// ```
///
/// becomes:
///
/// ```mlir
/// %1 = list.map %x with (%a: i32) -> i64 {
///   ...              // computes %p from %a
///   ...              // computes %c from %p
///   list.yield %c : i64
/// }
/// ```
struct MergeConsecutiveMaps : OpRewritePattern<MapOp> {
  using OpRewritePattern::OpRewritePattern;

  LogicalResult matchAndRewrite(MapOp mapOp,
                                PatternRewriter &rewriter) const override {
    auto producer = mapOp.getInput().getDefiningOp<MapOp>();
    if (!producer)
      return rewriter.notifyMatchFailure(mapOp, "operand is not a list.map");
    if (!isMemoryEffectFree(producer))
      return rewriter.notifyMatchFailure(producer,
                                         "producer has side effects");

    // The merged operation maps over the producer's operand and yields the
    // element type that `mapOp` yields.
    auto elementType =
        cast<ListType>(mapOp.getResult().getType()).getElementType();
    auto mergedOp = MapOp::create(rewriter, mapOp.getLoc(), producer.getInput(),
                                  elementType);
    Block &mergedBody = mergedOp.getBodyBlock();

    // Clone the producer's body so it can remain if it still has other users.
    // If it becomes unused, DCE removes it.
    Block &producerBody = producer.getBodyBlock();
    auto producerYield = cast<YieldOp>(producerBody.getTerminator());
    IRMapping mapping;
    mapping.map(producerBody.getArgument(0), mergedBody.getArgument(0));
    rewriter.setInsertionPointToEnd(&mergedBody);
    for (Operation &op : producerBody.without_terminator())
      rewriter.clone(op, mapping);
    Value producerElement = mapping.lookupOrDefault(producerYield.getYielded());

    // Append the body of `mapOp`, which consumes the element that the
    // producer's body computes.
    rewriter.inlineBlockBefore(&mapOp.getBodyBlock(), &mergedBody,
                               mergedBody.end(), producerElement);

    rewriter.replaceOp(mapOp, mergedOp.getResult());
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Exercise 4: lower list.map
//===----------------------------------------------------------------------===//

/// Turn a `list.map` operation into a loop over the elements of the mapped
/// list:
///
/// ```mlir
/// %result = list.map %input with (%element : i32) -> i64 {
///   %mapped = ...
///   list.yield %mapped : i64
/// }
/// ```
///
/// becomes:
///
/// ```mlir
/// %empty = list.empty : !list.list<i64>
/// %loop:2 = scf.while (%remaining = %input, %collected = %empty)
///     : (!list.list<i32>, !list.list<i64>) -> (!list.list<i32>,
///                                              !list.list<i64>) {
///   %is_empty = list.is_empty %remaining : !list.list<i32> -> i1
///   %true = arith.constant true
///   %not_empty = arith.xori %is_empty, %true : i1
///   scf.condition(%not_empty) %remaining, %collected
///       : !list.list<i32>, !list.list<i64>
/// } do {
/// ^bb0(%remaining : !list.list<i32>, %collected : !list.list<i64>):
///   %element = list.peek_front %remaining : !list.list<i32> -> i32
///   %rest = list.pop_front %remaining : !list.list<i32>
///   %mapped = ...
///   %longer = list.push_back %collected, %mapped : !list.list<i64>
///   scf.yield %rest, %longer : !list.list<i32>, !list.list<i64>
/// }
/// // %loop#1 replaces %result
/// ```
///
/// The loop carries two lists: the elements that still have to be mapped and
/// the mapped elements collected so far. Taking the elements off the front of
/// the first list and appending them to the back of the second one keeps the
/// order of the elements intact.
struct LowerMapToWhileLoop : OpRewritePattern<MapOp> {
  using OpRewritePattern::OpRewritePattern;

  LogicalResult matchAndRewrite(MapOp mapOp,
                                PatternRewriter &rewriter) const override {
    Location loc = mapOp.getLoc();
    Type remainingType = mapOp.getInput().getType();
    Type collectedType = mapOp.getResult().getType();

    // The list of mapped elements starts out empty.
    Value empty = EmptyOp::create(rewriter, loc, collectedType);

    // Both loop-carried lists are passed on unchanged by the condition of the
    // loop, so the operation results and the arguments of both regions all have
    // the same types.
    SmallVector<Type> loopTypes = {remainingType, collectedType};
    SmallVector<Value> inits = {mapOp.getInput(), empty};
    auto whileOp = scf::WhileOp::create(rewriter, loc, loopTypes, inits,
                                        /*beforeBuilder=*/nullptr,
                                        /*afterBuilder=*/nullptr);

    // The "before" region decides whether another element is left to map.
    {
      OpBuilder::InsertionGuard guard(rewriter);
      rewriter.setInsertionPointToEnd(whileOp.getBeforeBody());
      Value remaining = whileOp.getBeforeArguments()[0];
      Value isEmpty = IsEmptyOp::create(rewriter, loc, remaining);
      Value trueVal = arith::ConstantOp::create(rewriter, loc,
                                                rewriter.getBoolAttr(true));
      Value notEmpty = arith::XOrIOp::create(rewriter, loc, isEmpty, trueVal);
      scf::ConditionOp::create(rewriter, loc, notEmpty,
                               whileOp.getBeforeArguments());
    }

    // The "after" region maps a single element.
    {
      OpBuilder::InsertionGuard guard(rewriter);
      Block *afterBody = whileOp.getAfterBody();
      rewriter.setInsertionPointToEnd(afterBody);
      Value remaining = whileOp.getAfterArguments()[0];
      Value collected = whileOp.getAfterArguments()[1];
      Value element = PeekFrontOp::create(rewriter, loc, remaining);
      Value rest = PopFrontOp::create(rewriter, loc, remaining);

      // Move the body of the `list.map` into the loop and let it compute on the
      // element that was just taken off the list. The yield operation is looked
      // up before inlining, but its operand is read afterwards: inlining
      // replaces the block argument of the body, which the yield may use.
      // Terminators are never trivially dead, so the yield must be erased by
      // hand (and leaving it would leave the block with two terminators).
      auto yieldOp = cast<YieldOp>(mapOp.getBodyBlock().getTerminator());
      rewriter.inlineBlockBefore(&mapOp.getBodyBlock(), afterBody,
                                 afterBody->end(), element);
      Value mapped = yieldOp.getYielded();
      rewriter.eraseOp(yieldOp);

      rewriter.setInsertionPointToEnd(afterBody);
      Value longer = PushBackOp::create(rewriter, loc, collected, mapped);
      scf::YieldOp::create(rewriter, loc, ValueRange{rest, longer});
    }

    // The loop ends with an empty list of remaining elements, which is of no
    // interest; the mapped elements are the result of the `list.map`.
    rewriter.replaceOp(mapOp, whileOp.getResult(1));
    return success();
  }
};

struct ListSimplifyPass : public impl::ListSimplifyBase<ListSimplifyPass> {

  void runOnOperation() override {
    RewritePatternSet patterns(&getContext());

    // MergeConsecutiveMaps has a higher benefit than LowerMapToWhileLoop so
    // that a chain of maps is merged into a single map before it becomes a loop.
    patterns.add<MergeConsecutiveMaps>(patterns.getContext(), /*benefit=*/2);
    patterns.add<ReplaceEmptyFromElements, PeelFromElements,
                 LowerMapToWhileLoop>(patterns.getContext());

    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace

} // namespace list
} // namespace mlir
