//===- ListPasses.h - List dialect passes -----------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Declares and registers the transformations of the list dialect.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LIST_TRANSFORMS_LISTPASSES_H
#define MLIR_DIALECT_LIST_TRANSFORMS_LISTPASSES_H

#include "mlir/Pass/Pass.h"

namespace mlir {
namespace list {

//===----------------------------------------------------------------------===//
// Passes
//===----------------------------------------------------------------------===//

#define GEN_PASS_DECL
#include "list/Transforms/ListPasses.h.inc"

//===----------------------------------------------------------------------===//
// Registration
//===----------------------------------------------------------------------===//

#define GEN_PASS_REGISTRATION
#include "list/Transforms/ListPasses.h.inc"

} // namespace list
} // namespace mlir

#endif // MLIR_DIALECT_LIST_TRANSFORMS_LISTPASSES_H
