//===- List.h - MLIR List dialect -------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the list dialect, describing lists of integers and
// operations on them.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LIST_IR_LIST_H
#define MLIR_DIALECT_LIST_IR_LIST_H

#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/Interfaces/InferIntRangeInterface.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

//===----------------------------------------------------------------------===//
// List Dialect
//===----------------------------------------------------------------------===//

#include "list/IR/ListOpsDialect.h.inc"

//===----------------------------------------------------------------------===//
// List Dialect Types
//===----------------------------------------------------------------------===//

#define GET_TYPEDEF_CLASSES
#include "list/IR/ListOpsTypes.h.inc"

//===----------------------------------------------------------------------===//
// List Dialect Attributes
//===----------------------------------------------------------------------===//

#define GET_ATTRDEF_CLASSES
#include "list/IR/ListOpsAttrs.h.inc"

//===----------------------------------------------------------------------===//
// List Dialect Operations
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "list/IR/ListOps.h.inc"

#endif // MLIR_DIALECT_LIST_IR_LIST_H
