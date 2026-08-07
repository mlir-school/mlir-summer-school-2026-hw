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
    return rewriter.notifyMatchFailure(op, "exercise 2 not implemented");
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
    return rewriter.notifyMatchFailure(mapOp, "exercise 3 not implemented");
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
    return rewriter.notifyMatchFailure(mapOp, "exercise 4 not implemented");
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
