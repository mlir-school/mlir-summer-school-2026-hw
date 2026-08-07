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
    // Collect all from_elements ops before walking to avoid modifying the IR
    // while iterating over it.
    SmallVector<FromElementsOp> ops;
    getOperation()->walk([&](FromElementsOp op) { ops.push_back(op); });

    for (FromElementsOp op : ops) {
      OpBuilder builder(op);
      Location loc = op.getLoc();
      Type listType = op.getResult().getType();

      // Build the list one element at a time: start with an empty list and
      // append each element to the back in order.
      Value result = EmptyOp::create(builder, loc, listType);
      for (Value element : op.getElements())
        result = PushBackOp::create(builder, loc, result, element);

      op.getResult().replaceAllUsesWith(result);
      op.erase();
    }
  }
};

} // namespace

} // namespace list
} // namespace mlir
