//===- Exercise_1_ListLowerFromElements.cpp ---------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the `list-lower-from-elements` pass.
//
//===----------------------------------------------------------------------===//

#include "list/Transforms/ListPasses.h"

#include "list/IR/List.h"
#include "mlir/IR/Builders.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir {
namespace list {

#define GEN_PASS_DEF_LISTLOWERFROMELEMENTS
#include "list/Transforms/ListPasses.h.inc"

namespace {

struct ListLowerFromElementsPass
    : public impl::ListLowerFromElementsBase<ListLowerFromElementsPass> {

  void runOnOperation() override {
    getOperation()->emitError("exercise 1 not implemented");
    signalPassFailure();
  }
};

} // namespace

} // namespace list
} // namespace mlir
