//===- ListDialect.td - List dialect definition ------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LIST_IR_LISTDIALECT
#define MLIR_DIALECT_LIST_IR_LISTDIALECT

include "mlir/IR/OpBase.td"

def List_Dialect : Dialect {
  let name = "list";
  let cppNamespace = "::mlir::list";

  let summary = "Types and operations on lists of integers";
  let description = [{
    The `list` dialect describes immutable, dynamically-sized sequences of
    integers, together with a small set of operations that produce, consume and
    transform them.
  }];

  let useDefaultAttributePrinterParser = 1;
  let useDefaultTypePrinterParser = 1;

  // Provides 'materializeConstant', which turns the attribute returned by a
  // folder back into an operation: a 'list.list' attribute becomes a
  // 'list.constant', an integer becomes an 'arith.constant'.
  let hasConstantMaterializer = 1;

  // 'materializeConstant' builds operations of the arith dialect, which
  // therefore has to be loaded whenever this dialect is.
  let dependentDialects = ["::mlir::arith::ArithDialect"];
}

#endif // MLIR_DIALECT_LIST_IR_LISTDIALECT
