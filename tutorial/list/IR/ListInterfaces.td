//===- ListInterfaces.td - List dialect interfaces --------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LIST_IR_LISTINTERFACES
#define MLIR_DIALECT_LIST_IR_LISTINTERFACES

include "mlir/IR/OpBase.td"

def ListLengthOpInterface : OpInterface<"ListLengthOpInterface"> {
  let description = [{
    An interface for list-producing operations that may know the length of
    their result statically.
  }];

  let cppNamespace = "::mlir::list";

  let methods = [
    InterfaceMethod<
      "Return the statically known result length, if one is available",
      "::std::optional<int64_t>",
      "getStaticLength"
    >
  ];
}

#endif // MLIR_DIALECT_LIST_IR_LISTINTERFACES
