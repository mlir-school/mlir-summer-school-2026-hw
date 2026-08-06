//===- ListOps.cpp - MLIR List dialect operations -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "list/IR/List.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/PatternMatch.h"
#include "llvm/ADT/STLExtras.h"

using namespace mlir;
using namespace mlir::list;

//===----------------------------------------------------------------------===//
// ConstantOp
//===----------------------------------------------------------------------===//

OpFoldResult ConstantOp::fold(FoldAdaptor adaptor) { return getValueAttr(); }

//===----------------------------------------------------------------------===//
// FromElementsOp
//===----------------------------------------------------------------------===//

/// Builds a list without any element with `list.empty` instead:
///
/// ```mlir
/// %li = list.from_elements : () -> !list.list<i32>
/// ```
///
/// becomes:
///
/// ```mlir
/// %li = list.empty : !list.list<i32>
/// ```
LogicalResult FromElementsOp::canonicalize(FromElementsOp op,
                                           PatternRewriter &rewriter) {
  if (!op.getElements().empty())
    return rewriter.notifyMatchFailure(op, "list has elements");

  rewriter.replaceOpWithNewOp<EmptyOp>(op, op.getResult().getType());
  return success();
}

//===----------------------------------------------------------------------===//
// MapOp
//===----------------------------------------------------------------------===//

void MapOp::build(OpBuilder &builder, OperationState &state, Value input,
                  IntegerType resultElementType) {
  state.addOperands(input);
  state.addTypes(ListType::get(resultElementType));
  Block &body = state.addRegion()->emplaceBlock();
  body.addArgument(cast<ListType>(input.getType()).getElementType(),
                   input.getLoc());
}

/// Parses everything between the `with` keyword and the attribute dictionary of
/// a `list.map` operation:
///
///   (%elem : i32) -> i64 { ... }
///
/// Neither list type is spelled out; both are derived from the element types
/// given here.
static ParseResult parseMapBody(OpAsmParser &parser, Region &body,
                                Type &inputType, Type &resultType) {
  if (parser.parseLParen())
    return failure();

  OpAsmParser::Argument bodyArg;
  llvm::SMLoc bodyArgLoc = parser.getCurrentLocation();
  if (parser.parseArgument(bodyArg, /*allowType=*/true))
    return failure();
  auto inputElementType = dyn_cast_if_present<IntegerType>(bodyArg.type);
  if (!inputElementType)
    return parser.emitError(bodyArgLoc,
                            "expected the body argument to have an integer "
                            "type");

  if (parser.parseRParen() || parser.parseArrow())
    return failure();

  llvm::SMLoc resultElementTypeLoc = parser.getCurrentLocation();
  Type parsedResultElementType;
  if (parser.parseType(parsedResultElementType))
    return failure();
  auto resultElementType = dyn_cast<IntegerType>(parsedResultElementType);
  if (!resultElementType)
    return parser.emitError(resultElementTypeLoc,
                            "expected an integer result element type");

  if (parser.parseRegion(body, bodyArg))
    return failure();

  inputType = ListType::get(inputElementType);
  resultType = ListType::get(resultElementType);
  return success();
}

static void printMapBody(OpAsmPrinter &p, Operation *op, Region &body,
                         Type inputType, Type resultType) {
  p << '(';
  p.printRegionArgument(body.front().getArgument(0));
  p << ") -> " << cast<ListType>(resultType).getElementType() << ' ';
  p.printRegion(body, /*printEntryBlockArgs=*/false);
}

LogicalResult MapOp::verifyRegions() {
  Block &body = getBodyBlock();
  if (body.getNumArguments() != 1)
    return emitOpError("expects the body to have exactly one argument");

  Type inputElementType = getInput().getType().getElementType();
  if (body.getArgument(0).getType() != inputElementType)
    return emitOpError("expects the body argument type (")
           << body.getArgument(0).getType()
           << ") to match the element type of the operand list ("
           << inputElementType << ")";

  // The 'SingleBlockImplicitTerminator' trait has already verified that the
  // terminator is a 'list.yield'.
  auto yieldOp = cast<YieldOp>(body.getTerminator());
  Type resultElementType = getResult().getType().getElementType();
  if (yieldOp.getYielded().getType() != resultElementType)
    return emitOpError("expects the yielded type (")
           << yieldOp.getYielded().getType()
           << ") to match the element type of the result list ("
           << resultElementType << ")";

  return success();
}

namespace {
/// Merges a `list.map` whose operand is produced by another `list.map` into a
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
///
/// The producer is left behind for dead code elimination.
struct MergeConsecutiveMaps : OpRewritePattern<MapOp> {
  using OpRewritePattern::OpRewritePattern;

  LogicalResult matchAndRewrite(MapOp mapOp,
                                PatternRewriter &rewriter) const override {
    auto producer = mapOp.getInput().getDefiningOp<MapOp>();
    if (!producer)
      return rewriter.notifyMatchFailure(mapOp, "operand is not a list.map");

    // Merging copies the body of the producer into the consumer. If the
    // producer has other users, it stays behind and its body ends up being
    // evaluated twice: fewer operations, but more work. Whether that trade is
    // worth making is a decision for a pass, not for a canonicalization.
    if (!producer.getResult().hasOneUse())
      return rewriter.notifyMatchFailure(producer, "producer has other users");

    // The effects of the producer would move to where the consumer is, past
    // whatever happens between the two operations.
    if (!isMemoryEffectFree(producer))
      return rewriter.notifyMatchFailure(producer,
                                         "producer has side effects");

    // The merged operation maps over the producer's operand and yields the
    // element type that `mapOp` yields.
    auto elementType = mapOp.getResult().getType().getElementType();
    auto mergedOp = MapOp::create(rewriter, mapOp.getLoc(), producer.getInput(),
                                  elementType);
    Block &mergedBody = mergedOp.getBodyBlock();

    // Clone rather than move the body of the producer: the producer is only
    // known to be unused once `mapOp` has been replaced below.
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
} // namespace

void MapOp::getCanonicalizationPatterns(RewritePatternSet &results,
                                        MLIRContext *context) {
  results.add<MergeConsecutiveMaps>(context);
}

//===----------------------------------------------------------------------===//
// TableGen'd op definitions
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "list/IR/ListOps.cpp.inc"
