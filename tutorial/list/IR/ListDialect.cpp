//===- ListDialect.cpp - MLIR List dialect implementation -----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "list/IR/List.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace mlir::list;

#include "list/IR/ListOpsDialect.cpp.inc"

//===----------------------------------------------------------------------===//
// TableGen'd type definitions
//===----------------------------------------------------------------------===//

#define GET_TYPEDEF_CLASSES
#include "list/IR/ListOpsTypes.cpp.inc"

//===----------------------------------------------------------------------===//
// TableGen'd attribute definitions
//===----------------------------------------------------------------------===//

#define GET_ATTRDEF_CLASSES
#include "list/IR/ListOpsAttrs.cpp.inc"

void ListDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "list/IR/ListOps.cpp.inc"

      >();

  addTypes<
#define GET_TYPEDEF_LIST
#include "list/IR/ListOpsTypes.cpp.inc"

      >();

  addAttributes<
#define GET_ATTRDEF_LIST
#include "list/IR/ListOpsAttrs.cpp.inc"

      >();
}

/// Turns the result of a successful fold back into an operation. The folding
/// infrastructure calls this whenever a folder returns an attribute instead of
/// an existing value, e.g. when 'list.reverse' of a 'list.constant' is folded
/// into the reversed list.
Operation *ListDialect::materializeConstant(OpBuilder &builder, Attribute value,
                                            Type type, Location loc) {
  if (auto listValue = dyn_cast<ListAttr>(value)) {
    if (listValue.getType() != type)
      return nullptr;
    return ConstantOp::create(builder, loc, listValue.getType(), listValue);
  }

  // Folders of this dialect also produce integers and booleans: the length of a
  // list, whether it is empty, one of its elements. There is no list operation
  // that holds those, so they are materialized as an 'arith.constant'. A fold
  // whose result cannot be materialized is silently dropped, which is why this
  // is not optional.
  return arith::ConstantOp::materialize(builder, value, type, loc);
}
