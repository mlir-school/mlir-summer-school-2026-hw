//===- ListOps.cpp - MLIR List dialect operations -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "list/IR/List.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/ADT/STLExtras.h"

using namespace mlir;
using namespace mlir::list;

//===----------------------------------------------------------------------===//
// ConstantOp
//===----------------------------------------------------------------------===//

OpFoldResult ConstantOp::fold(FoldAdaptor adaptor) { return getValueAttr(); }

//===----------------------------------------------------------------------===//
// Integer element range propagation
//===----------------------------------------------------------------------===//

void FromElementsOp::inferResultRanges(ArrayRef<ConstantIntRanges> argRanges,
                                       SetIntRangeFn setResultRanges) {
  // Get the bitwidth of the list element type.
  // This is important to set the correct range for some lists.
  unsigned elementWidth = ConstantIntRanges::getStorageBitwidth(
      getResult().getType().getElementType());

  // If the list is empty, the result range is set at an arbitrary constant (0).
  if (argRanges.empty()) {
    setResultRanges(getResult(),
                    ConstantIntRanges::constant(APInt::getZero(elementWidth)));
    return;
  }

  // Otherwise, compute the union of all argument ranges.
  ConstantIntRanges resultRange = argRanges.front();
  for (const ConstantIntRanges &range : argRanges.drop_front())
    resultRange = resultRange.rangeUnion(range);
  setResultRanges(getResult(), resultRange);
}

void PeekFrontOp::inferResultRanges(ArrayRef<ConstantIntRanges> argRanges,
                                    SetIntRangeFn setResultRanges) {
  // EXERCISE 1: Change this line
  ConstantIntRanges range = ConstantIntRanges::maxRange(
      ConstantIntRanges::getStorageBitwidth(getResult().getType()));

  setResultRanges(getItem(), range);
}

void PopFrontOp::inferResultRanges(ArrayRef<ConstantIntRanges> argRanges,
                                   SetIntRangeFn setResultRanges) {
  // EXERCISE 1: Change this line
  ConstantIntRanges range = ConstantIntRanges::maxRange(
      ConstantIntRanges::getStorageBitwidth(
          getResult().getType().getElementType()));

  setResultRanges(getResult(), range);
}

void PushFrontOp::inferResultRanges(ArrayRef<ConstantIntRanges> argRanges,
                                    SetIntRangeFn setResultRanges) {
  // EXERCISE 1: Change this line
  ConstantIntRanges range = ConstantIntRanges::maxRange(
      ConstantIntRanges::getStorageBitwidth(
          getResult().getType().getElementType()));

  setResultRanges(getResult(), range);
}

//===----------------------------------------------------------------------===//
// LengthOp
//===----------------------------------------------------------------------===//

void LengthOp::inferResultRanges(ArrayRef<ConstantIntRanges>,
                                 SetIntRangeFn setResultRanges) {
  // EXERCISE 1: Change this line
  ConstantIntRanges range = ConstantIntRanges::maxRange(
      ConstantIntRanges::getStorageBitwidth(getResult().getType()));

  setResultRanges(getResult(), range);
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

//===----------------------------------------------------------------------===//
// TableGen'd op definitions
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "list/IR/ListOps.cpp.inc"
