//===- ListOps.cpp - MLIR List dialect operations -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "list/IR/List.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/Interfaces/Utils/MemorySlotUtils.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/ErrorHandling.h"

using namespace mlir;
using namespace mlir::list;

//===----------------------------------------------------------------------===//
// FromElementsOp
//===----------------------------------------------------------------------===//

LogicalResult FromElementsOp::verify() {
  Type elementType = cast<ListType>(getResult().getType()).getElementType();
  for (auto [index, type] : llvm::enumerate(getElements().getTypes()))
    if (type != elementType)
      return emitOpError("expects operand #")
             << index << " to have the element type of the result list ("
             << elementType << "), but got " << type;
  return success();
}

//===----------------------------------------------------------------------===//
// GetElementsOp
//===----------------------------------------------------------------------===//

LogicalResult GetElementsOp::verify() {
  Type elementType = cast<ListType>(getInput().getType()).getElementType();
  for (auto [index, type] : llvm::enumerate(getResultTypes()))
    if (type != elementType)
      return emitOpError("expects result #")
             << index << " to have the element type of the operand list ("
             << elementType << "), but got " << type;
  return success();
}

//===----------------------------------------------------------------------===//
// FoldOp
//===----------------------------------------------------------------------===//

void FoldOp::build(OpBuilder &builder, OperationState &state, Value input,
                   ValueRange iterArgs) {
  state.addOperands(input);
  state.addOperands(iterArgs);
  state.addTypes(iterArgs.getTypes());

  Block &body = state.addRegion()->emplaceBlock();
  body.addArgument(cast<ListType>(input.getType()).getElementType(),
                   input.getLoc());
  for (Value iterArg : iterArgs)
    body.addArgument(iterArg.getType(), iterArg.getLoc());
}

ParseResult FoldOp::parse(OpAsmParser &parser, OperationState &result) {
  OpAsmParser::UnresolvedOperand input;
  if (parser.parseOperand(input) || parser.parseKeyword("with") ||
      parser.parseLParen())
    return failure();

  OpAsmParser::Argument elementArgument;
  if (parser.parseArgument(elementArgument, /*allowType=*/true) ||
      parser.parseRParen())
    return failure();

  SmallVector<OpAsmParser::Argument> bodyArguments{elementArgument};
  SmallVector<OpAsmParser::UnresolvedOperand> iterArgOperands;
  SmallVector<Type> iterArgTypes;
  SMLoc iterArgsLoc = parser.getCurrentLocation();

  if (succeeded(parser.parseOptionalKeyword("iter_args"))) {
    if (parser.parseCommaSeparatedList(AsmParser::Delimiter::Paren,
                                       [&]() -> ParseResult {
                                         OpAsmParser::Argument argument;
                                         OpAsmParser::UnresolvedOperand operand;
                                         if (parser.parseArgument(argument) ||
                                             parser.parseEqual() ||
                                             parser.parseOperand(operand))
                                           return failure();
                                         bodyArguments.push_back(argument);
                                         iterArgOperands.push_back(operand);
                                         return success();
                                       }) ||
        parser.parseArrow() || parser.parseLParen() ||
        parser.parseTypeList(iterArgTypes) || parser.parseRParen())
      return failure();
  }

  if (iterArgOperands.size() != iterArgTypes.size())
    return parser.emitError(iterArgsLoc)
           << "expected " << iterArgOperands.size()
           << " iter_arg types, but got " << iterArgTypes.size();

  auto inputElementType =
      dyn_cast_if_present<IntegerType>(elementArgument.type);
  if (!inputElementType)
    return parser.emitError(elementArgument.ssaName.location,
                            "expected the element argument to have an integer "
                            "type");

  for (Type type : iterArgTypes)
    if (!isa<IntegerType, ListType>(type))
      return parser.emitError(iterArgsLoc,
                              "expected iter_args to be integers or lists");

  for (auto [index, type] : llvm::enumerate(iterArgTypes))
    bodyArguments[index + 1].type = type;

  if (parser.resolveOperand(input, ListType::get(inputElementType),
                            result.operands) ||
      parser.resolveOperands(iterArgOperands, iterArgTypes, iterArgsLoc,
                             result.operands))
    return failure();

  result.addTypes(iterArgTypes);
  Region *body = result.addRegion();
  if (parser.parseRegion(*body, bodyArguments) ||
      parser.parseOptionalAttrDict(result.attributes))
    return failure();

  return success();
}

void FoldOp::print(OpAsmPrinter &p) {
  p << ' ' << getInput() << " with (";
  p.printRegionArgument(getBodyBlock().getArgument(0));
  p << ')';

  if (!getIterArgs().empty()) {
    p << " iter_args(";
    llvm::interleaveComma(
        llvm::zip(getBodyBlock().getArguments().drop_front(), getIterArgs()), p,
        [&](auto pair) {
          p.printRegionArgument(std::get<0>(pair), /*argAttrs=*/{},
                                /*omitType=*/true);
          p << " = " << std::get<1>(pair);
        });
    p << ") -> (";
    llvm::interleaveComma(getIterArgs().getTypes(), p,
                          [&](Type type) { p << type; });
    p << ')';
  }

  p << ' ';
  p.printRegion(getBody(), /*printEntryBlockArgs=*/false);
  p.printOptionalAttrDict((*this)->getAttrs());
}

LogicalResult FoldOp::verify() {
  Block &body = getBodyBlock();
  unsigned expectedBodyArgumentCount = getIterArgs().size() + 1;
  if (body.getNumArguments() != expectedBodyArgumentCount)
    return emitOpError("expects the body to have exactly ")
           << expectedBodyArgumentCount << " arguments";

  if (getRes().size() != getIterArgs().size())
    return emitOpError("expects ")
           << getIterArgs().size() << " results, but got " << getRes().size();

  Type inputElementType = cast<ListType>(getInput().getType()).getElementType();
  if (body.getArgument(0).getType() != inputElementType)
    return emitOpError("expects the element argument type (")
           << body.getArgument(0).getType()
           << ") to match the element type of the input list ("
           << inputElementType << ")";

  for (auto [index, blockArgument] :
       llvm::enumerate(body.getArguments().drop_front())) {
    Type iterArgType = getIterArgs()[index].getType();
    if (blockArgument.getType() != iterArgType)
      return emitOpError("expects iter_arg block argument #")
             << index << " to have type " << iterArgType << ", but got "
             << blockArgument.getType();
    if (getRes()[index].getType() != iterArgType)
      return emitOpError("expects result #")
             << index << " to have type " << iterArgType << ", but got "
             << getRes()[index].getType();
  }

  auto yieldOp =
      dyn_cast_if_present<YieldOp>(body.empty() ? nullptr : &body.back());
  if (!yieldOp)
    return emitOpError("expects the body to be terminated by '")
           << YieldOp::getOperationName() << "'";

  if (yieldOp.getYielded().size() != getIterArgs().size())
    return emitOpError("expects ")
           << getIterArgs().size() << " yielded values, but got "
           << yieldOp.getYielded().size();

  for (auto [index, yielded] : llvm::enumerate(yieldOp.getYielded())) {
    Type iterArgType = getIterArgs()[index].getType();
    if (yielded.getType() != iterArgType)
      return emitOpError("expects yielded value #")
             << index << " to have type " << iterArgType << ", but got "
             << yielded.getType();
  }

  return success();
}

bool FoldOp::isRegionPromotable(const MemorySlot &, Region *, bool) {
  assert(0 && "unimplemented");
}

void FoldOp::setupPromotion(
    const MemorySlot &slot, Value reachingDef, bool hasValueStores,
    llvm::SmallMapVector<Region *, Value, 2> &regionsToProcess) {
  assert(0 && "unimplemented");
}

Value FoldOp::finalizePromotion(
    const MemorySlot &slot, Value entryReachingDef, bool hasValueStores,
    const llvm::DenseMap<Block *, Value> &reachingAtBlockEnd,
    OpBuilder &builder) {
  assert(0 && "unimplemented");
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

LogicalResult MapOp::verify() {
  Block &body = getBodyBlock();
  if (body.getNumArguments() != 1)
    return emitOpError("expects the body to have exactly one argument");

  Type inputElementType = cast<ListType>(getInput().getType()).getElementType();
  if (body.getArgument(0).getType() != inputElementType)
    return emitOpError("expects the body argument type (")
           << body.getArgument(0).getType()
           << ") to match the element type of the operand list ("
           << inputElementType << ")";

  auto yieldOp =
      dyn_cast_if_present<YieldOp>(body.empty() ? nullptr : &body.back());
  if (!yieldOp)
    return emitOpError("expects the body to be terminated by '")
           << YieldOp::getOperationName() << "'";

  if (yieldOp.getYielded().size() != 1)
    return emitOpError("expects the body to yield exactly one value");

  Type resultElementType =
      cast<ListType>(getResult().getType()).getElementType();
  if (yieldOp.getYielded().front().getType() != resultElementType)
    return emitOpError("expects the yielded type (")
           << yieldOp.getYielded().front().getType()
           << ") to match the element type of the result list ("
           << resultElementType << ")";

  return success();
}

bool MapOp::isRegionPromotable(const MemorySlot &, Region *,
                               bool hasValueStores) {
  assert(0 && "unimplemented");
}

void MapOp::setupPromotion(
    const MemorySlot &, Value reachingDef, bool hasValueStores,
    llvm::SmallMapVector<Region *, Value, 2> &regionsToProcess) {
  assert(0 && "unimplemented");
}

Value MapOp::finalizePromotion(const MemorySlot &, Value entryReachingDef,
                               bool hasValueStores,
                               const llvm::DenseMap<Block *, Value> &,
                               OpBuilder &) {
  assert(0 && "unimplemented");
}

//===----------------------------------------------------------------------===//
// AllocaOp
//===----------------------------------------------------------------------===//

SmallVector<MemorySlot> AllocaOp::getPromotableSlots() {
  assert(0 && "unimplemented");
}

Value AllocaOp::getDefaultValue(const MemorySlot &slot, OpBuilder &builder) {
  assert(0 && "unimplemented");
}

void AllocaOp::handleBlockArgument(const MemorySlot &, BlockArgument,
                                   OpBuilder &) {}

std::optional<PromotableAllocationOpInterface>
AllocaOp::handlePromotionComplete(const MemorySlot &, Value defaultValue,
                                  OpBuilder &) {
  assert(0 && "unimplemented");
}

//===----------------------------------------------------------------------===//
// StoreOp
//===----------------------------------------------------------------------===//

ParseResult StoreOp::parse(OpAsmParser &parser, OperationState &result) {
  // Uncomment and adapt to your design.

  /*
  OpAsmParser::UnresolvedOperand value;
  OpAsmParser::UnresolvedOperand ref;
  Type type;
  if (parser.parseOperand(value) || parser.parseComma() ||
      parser.parseOperand(ref) ||
      parser.parseOptionalAttrDict(result.attributes) ||
      parser.parseColonType(type))
    return failure();

  auto refType = dyn_cast<RefType>(type);
  if (!refType)
    return parser.emitError(parser.getCurrentLocation(),
                            "expected a list reference type");

  if (parser.resolveOperand(value, refType.getElementType(), result.operands) ||
      parser.resolveOperand(ref, refType, result.operands))
    return failure();
  return success();
  */
  assert(0 && "unimplemented");
}

void StoreOp::print(OpAsmPrinter &printer) {
  // Uncomment and adapt to your design.

  /*
  printer << ' ' << getValue() << ", " << getRef();
  printer.printOptionalAttrDict((*this)->getAttrs());
  printer << " : " << getRef().getType();
  */
  assert(0 && "unimplemented");
}

LogicalResult StoreOp::verify() { assert(0 && "unimplemented"); }

bool StoreOp::loadsFrom(const MemorySlot &) { assert(0 && "unimplemented"); }

bool StoreOp::storesTo(const MemorySlot &slot) { assert(0 && "unimplemented"); }

Value StoreOp::getStored(const MemorySlot &, OpBuilder &, Value,
                         const DataLayout &) {
  assert(0 && "unimplemented");
}

bool StoreOp::canUsesBeRemoved(
    const MemorySlot &slot,
    const llvm::SmallPtrSetImpl<OpOperand *> &blockingUses,
    llvm::SmallVectorImpl<OpOperand *> &, const DataLayout &) {
  assert(0 && "unimplemented");
}

DeletionKind
StoreOp::removeBlockingUses(const MemorySlot &,
                            const llvm::SmallPtrSetImpl<OpOperand *> &,
                            OpBuilder &, Value, const DataLayout &) {
  assert(0 && "unimplemented");
}

//===----------------------------------------------------------------------===//
// LoadOp
//===----------------------------------------------------------------------===//

ParseResult LoadOp::parse(OpAsmParser &parser, OperationState &result) {
  // Uncomment and adapt to your design.

  /*
  OpAsmParser::UnresolvedOperand ref;
  Type type;
  if (parser.parseOperand(ref) ||
      parser.parseOptionalAttrDict(result.attributes) ||
      parser.parseColonType(type))
    return failure();

  auto refType = dyn_cast<RefType>(type);
  if (!refType)
    return parser.emitError(parser.getCurrentLocation(),
                            "expected a list reference type");

  result.addTypes(refType.getElementType());
  return parser.resolveOperand(ref, refType, result.operands);
  */
  assert(0 && "unimplemented");
}

void LoadOp::print(OpAsmPrinter &printer) {
  // Uncomment and adapt to your design.

  /*
  printer << ' ' << getRef();
  printer.printOptionalAttrDict((*this)->getAttrs());
  printer << " : " << getRef().getType();
  */
  assert(0 && "unimplemented");
}

LogicalResult LoadOp::verify() { assert(0 && "unimplemented"); }

bool LoadOp::loadsFrom(const MemorySlot &slot) { assert(0 && "unimplemented"); }

bool LoadOp::storesTo(const MemorySlot &) { assert(0 && "unimplemented"); }

Value LoadOp::getStored(const MemorySlot &, OpBuilder &, Value,
                        const DataLayout &) {
  assert(0 && "unimplemented");
}

bool LoadOp::canUsesBeRemoved(
    const MemorySlot &slot,
    const llvm::SmallPtrSetImpl<OpOperand *> &blockingUses,
    llvm::SmallVectorImpl<OpOperand *> &, const DataLayout &) {
  assert(0 && "unimplemented");
}

DeletionKind LoadOp::removeBlockingUses(
    const MemorySlot &, const llvm::SmallPtrSetImpl<OpOperand *> &, OpBuilder &,
    Value reachingDefinition, const DataLayout &) {
  assert(0 && "unimplemented");
}

//===----------------------------------------------------------------------===//
// TableGen'd op definitions
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "list/IR/ListOps.cpp.inc"
