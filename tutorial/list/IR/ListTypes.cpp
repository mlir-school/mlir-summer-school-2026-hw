//===- ListTypes.cpp - MLIR List dialect types ----------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "list/IR/List.h"

using namespace mlir;
using namespace mlir::list;

LogicalResult
RefType::verify(llvm::function_ref<InFlightDiagnostic()> emitError,
                Type elementType) {
  if (!isa<IntegerType, ListType>(elementType))
    return emitError() << "expected an integer or list element type, but got "
                       << elementType;
  return success();
}
