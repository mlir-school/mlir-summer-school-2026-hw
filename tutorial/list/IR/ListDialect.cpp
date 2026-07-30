//===- ListDialect.cpp - MLIR List dialect implementation -----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "list/IR/List.h"

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

void ListDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "list/IR/ListOps.cpp.inc"

      >();

  addTypes<
#define GET_TYPEDEF_LIST
#include "list/IR/ListOpsTypes.cpp.inc"

      >();
}
