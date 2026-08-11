//===- ListExternalModels.cpp - External models for the list dialect ------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "list/IR/List.h"

#include "mlir/Dialect/Arith/IR/Arith.h"

using namespace mlir;
using namespace mlir::list;

namespace {

/// An external model lets an operation defined in another dialect implement
/// an interface without changing that operation's definition.
struct ArithConstantIntModel
    : ConstantIntOpInterface::ExternalModel<ArithConstantIntModel,
                                            arith::ConstantOp> {
  std::optional<int64_t>
  getConstantIntValue(Operation *operation) const {
    auto constant = cast<arith::ConstantOp>(operation);
    auto value = dyn_cast<IntegerAttr>(constant.getValue());
    if (!value)
      return std::nullopt;
    return value.getInt();
  }
};

} // namespace

void mlir::list::registerListExternalModels(DialectRegistry &registry) {
  registry.addExtension(+[](MLIRContext *context, arith::ArithDialect *) {
    arith::ConstantOp::attachInterface<ArithConstantIntModel>(*context);
  });
}
