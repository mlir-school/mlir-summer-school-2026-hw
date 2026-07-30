//===- ListOps.td - List dialect operations ----------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LIST_IR_LISTOPS
#define MLIR_DIALECT_LIST_IR_LISTOPS

include "list/IR/ListDialect.td"
include "list/IR/ListTypes.td"
include "mlir/IR/CommonTypeConstraints.td"
include "mlir/IR/OpBase.td"

class List_Op<string mnemonic, list<Trait> traits = []>
    : Op<List_Dialect, mnemonic, traits>;

// Denotes that `itemArg` has the element type of the list `listArg`.
class List_ItemTypeMatchesElementType<string listArg, string itemArg>
    : TypesMatchWith<"type of '" # itemArg # "' matches the element type of '"
                     # listArg # "'", listArg, itemArg,
                     "::llvm::cast<::mlir::list::ListType>($_self)"
                     ".getElementType()">;

def List_EmptyOp : List_Op<"empty"> {
  let summary = "list without any element";
  let description = [{
    Creates a list that holds no element.

    Example:

    ```mlir
    %li = list.empty : !list.list<i32>
    ```
  }];

  let results = (outs List_ListType:$result);

  let assemblyFormat = "attr-dict `:` qualified(type($result))";
}

def List_LengthOp : List_Op<"length"> {
  let summary = "number of elements of a list";
  let description = [{
    Returns the number of elements of the operand list.

    Example:

    ```mlir
    %len = list.length %li : !list.list<i32> -> i32
    ```
  }];

  let arguments = (ins List_ListType:$input);
  let results = (outs I32:$result);

  let assemblyFormat =
      "$input attr-dict `:` qualified(type($input)) `->` type($result)";

  let builders = [
    OpBuilder<(ins "::mlir::Value":$input), [{
      build($_builder, $_state, $_builder.getI32Type(), input);
    }]>
  ];
}

def List_PushBackOp : List_Op<"push_back",
    [AllTypesMatch<["input", "result"]>,
     List_ItemTypeMatchesElementType<"input", "item">]> {
  let summary = "list with an element appended";
  let description = [{
    Returns the operand list with `$item` appended to it.

    Example:

    ```mlir
    %longer = list.push_back %li, %item : !list.list<i32>
    ```
  }];

  let arguments = (ins List_ListType:$input, AnyInteger:$item);
  let results = (outs List_ListType:$result);

  let assemblyFormat = "$input `,` $item attr-dict `:` qualified(type($input))";

  let builders = [
    OpBuilder<(ins "::mlir::Value":$input, "::mlir::Value":$item), [{
      build($_builder, $_state, input.getType(), input, item);
    }]>
  ];
}

#endif // MLIR_DIALECT_LIST_IR_LISTOPS
