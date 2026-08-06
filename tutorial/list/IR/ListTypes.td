//===- ListTypes.td - List dialect types and attributes ----*- tablegen -*-===//
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
include "mlir/IR/BuiltinAttributeInterfaces.td"

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

class List_Attr<string name, string attrMnemonic, list<Trait> traits = []>
    : AttrDef<List_Dialect, name, traits> {
  let mnemonic = attrMnemonic;
}

def List_ListAttr : List_Attr<"List", "list", [TypedAttrInterface]> {
  let summary = "constant list of integers";
  let description = [{
    A constant list of integers. The type of the attribute is the `!list.list`
    type of the list; its elements are stored as 64-bit integers regardless of
    the element type of that list.

    Example:

    ```mlir
    #list.list<[1, 2, 3]> : !list.list<i32>
    ```
  }];

  let parameters = (ins
      AttributeSelfTypeParameter<"", "::mlir::list::ListType">:$type,
      OptionalArrayRefParameter<"int64_t">:$elements);

  let assemblyFormat = "`<` `[` (`]`) : ($elements^ `]`)? `>`";

  let builders = [
    AttrBuilderWithInferredContext<(ins "::mlir::list::ListType":$type,
                                       "::llvm::ArrayRef<int64_t>":$elements), [{
      return $_get(type.getContext(), type, elements);
    }]>
  ];
}

#endif // MLIR_DIALECT_LIST_IR_LISTTYPES
