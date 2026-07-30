//===- ListTypes.td - List dialect types -------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LIST_IR_LISTTYPES
#define MLIR_DIALECT_LIST_IR_LISTTYPES

include "list/IR/ListDialect.td"
include "mlir/IR/AttrTypeBase.td"

class List_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<List_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

def List_ListType : List_Type<"List", "list"> {
  let summary = "list of integers";
  let description = [{
    `!list.list` is a dynamically-sized sequence of integers of a fixed element
    type.

    Example:

    ```mlir
    !list.list<i32>
    ```
  }];

  let parameters = (ins "::mlir::IntegerType":$elementType);
  let assemblyFormat = "`<` $elementType `>`";

  let builders = [
    TypeBuilderWithInferredContext<(ins "::mlir::IntegerType":$elementType), [{
      return $_get(elementType.getContext(), elementType);
    }]>
  ];
}

#endif // MLIR_DIALECT_LIST_IR_LISTTYPES
