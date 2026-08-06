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
include "mlir/Interfaces/InferIntRangeInterface.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

class List_Op<string mnemonic, list<Trait> traits = []>
    : Op<List_Dialect, mnemonic, traits>;

// Denotes that `itemArg` has the element type of the list `listArg`.
class List_ItemTypeMatchesElementType<string listArg, string itemArg>
    : TypesMatchWith<"type of '" # itemArg # "' matches the element type of '"
                     # listArg # "'", listArg, itemArg,
                     "::llvm::cast<::mlir::list::ListType>($_self)"
                     ".getElementType()">;

// Denotes that every value of the variadic `itemsArg` has the element type of
// the list `listArg`. The element type is repeated as often as there are items
// to compare it against all of their types at once.
class List_ItemTypesMatchElementType<string listArg, string itemsArg>
    : RangedTypesMatchWith<"types of '" # itemsArg # "' match the element type "
                           "of '" # listArg # "'", listArg, itemsArg,
                           "::llvm::SmallVector<::mlir::Type>($" # itemsArg
                           # ".size(), ::llvm::cast<::mlir::list::ListType>"
                           "($_self).getElementType())">;

def List_ConcatOp : List_Op<"concat",
    [Pure, AllTypesMatch<["lhs", "rhs", "result"]>]> {
  let summary = "concatenation of two lists";
  let description = [{
    Returns a list containing the elements of `$lhs`, followed by the elements
    of `$rhs`.

    Example:

    ```mlir
    %combined = list.concat %lhs, %rhs : !list.list<i32>
    ```
  }];

  let arguments = (ins List_ListType:$lhs, List_ListType:$rhs);
  let results = (outs List_ListType:$result);

  let assemblyFormat =
      "$lhs `,` $rhs attr-dict `:` qualified(type($result))";

  let builders = [
    OpBuilder<(ins "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, lhs.getType(), lhs, rhs);
    }]>
  ];
}

def List_ConstantOp : List_Op<"constant",
    [ConstantLike, Pure, AllTypesMatch<["value", "result"]>]> {
  let summary = "list of constants";
  let description = [{
    Creates the list described by the `$value` attribute. Every element of the
    attribute is truncated to the element type of the result list.

    Example:

    ```mlir
    %li = list.constant #list.list<[1, 2, 3]> : !list.list<i32>
    ```
  }];

  let arguments = (ins List_ListAttr:$value);
  let results = (outs List_ListType:$result);

  let assemblyFormat = "qualified($value) attr-dict";

  let hasFolder = 1;
}

def List_EmptyOp : List_Op<"empty", [Pure]> {
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

def List_FromElementsOp : List_Op<"from_elements",
    [Pure, List_ItemTypesMatchElementType<"result", "elements">,
     DeclareOpInterfaceMethods<InferIntRangeInterface,
                               ["inferResultRanges"]>]> {
  let summary = "list holding the given elements";
  let description = [{
    Creates a list of the operands, in the order in which they are given. The
    resulting list is empty if there are no operands.

    Example:

    ```mlir
    %li = list.from_elements %a, %b, %c : (i32, i32, i32) -> !list.list<i32>
    ```
  }];

  let arguments = (ins Variadic<AnyInteger>:$elements);
  let results = (outs List_ListType:$result);

  let assemblyFormat =
      "$elements attr-dict `:` functional-type($elements, $result)";
}

// NoMemoryEffect rather than Pure: the op is undefined if the result count
// does not match the list length, so it must not be treated as always
// speculatable (e.g. by loop-invariant code motion).
def List_GetElementsOp : List_Op<"get_elements",
    [NoMemoryEffect, List_ItemTypesMatchElementType<"input", "elements">]> {
  let summary = "elements of a list";
  let description = [{
    Returns the elements of the operand list, in the order in which they are
    stored in the list.

    The number of results must be the length of the operand list. The behavior
    is undefined if the list has a different length.

    Example:

    ```mlir
    %a, %b, %c = list.get_elements %li : (!list.list<i32>) -> (i32, i32, i32)
    ```
  }];

  let arguments = (ins List_ListType:$input);
  let results = (outs Variadic<AnyInteger>:$elements);

  let assemblyFormat =
      "$input attr-dict `:` functional-type($input, $elements)";
}

def List_IsEmptyOp : List_Op<"is_empty", [Pure]> {
  let summary = "whether a list holds no element";
  let description = [{
    Returns whether the operand list holds no element.

    Example:

    ```mlir
    %is_empty = list.is_empty %li : !list.list<i32> -> i1
    ```
  }];

  let arguments = (ins List_ListType:$input);
  let results = (outs I1:$result);

  let assemblyFormat =
      "$input attr-dict `:` qualified(type($input)) `->` type($result)";

  let builders = [
    OpBuilder<(ins "::mlir::Value":$input), [{
      build($_builder, $_state, $_builder.getI1Type(), input);
    }]>
  ];
}

def List_LengthOp : List_Op<"length",
    [Pure,
     DeclareOpInterfaceMethods<InferIntRangeInterface,
                               ["inferResultRanges"]>]> {
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

def List_MapOp : List_Op<"map",
    [RecursiveMemoryEffects,
     SingleBlockImplicitTerminator<"::mlir::list::YieldOp">]> {
  let summary = "apply a computation to every element of a list";
  let description = [{
    Produces a list of the same length as the operand list, where every element
    is the result of evaluating the body region with the corresponding element
    of the operand list bound to the region argument. The body is evaluated
    exactly once per element, in order from front to back. The body region is
    terminated by a `list.yield` operation whose operand type determines the
    element type of the result list.

    Example:

    ```mlir
    %doubled = list.map %li with (%elem : i32) -> i64 {
      %ext = arith.extsi %elem : i32 to i64
      %res = arith.addi %ext, %ext : i64
      list.yield %res : i64
    }
    ```
  }];

  let arguments = (ins List_ListType:$input);
  let regions = (region SizedRegion<1>:$body);
  let results = (outs List_ListType:$result);

  let assemblyFormat = [{
    $input `with` custom<MapBody>($body, type($input), type($result)) attr-dict
  }];

  // A region verifier rather than a plain verifier: it runs after the body
  // region and the traits above have been verified and may therefore assume
  // that the body block is terminated by a `list.yield`.
  let hasRegionVerifier = 1;

  let builders = [
    OpBuilder<(ins "::mlir::Value":$input, "::mlir::IntegerType":$resultElementType)>
  ];

  let extraClassDeclaration = [{
    /// Returns the single block of the body region.
    ::mlir::Block &getBodyBlock() { return getBody().front(); }
  }];
}

// NoMemoryEffect rather than Pure: undefined on an empty list, so not always
// speculatable.
def List_PeekFrontOp : List_Op<"peek_front",
    [NoMemoryEffect, List_ItemTypeMatchesElementType<"input", "item">,
     DeclareOpInterfaceMethods<InferIntRangeInterface,
                               ["inferResultRanges"]>]> {
  let summary = "first element of a list";
  let description = [{
    Returns the first element of the operand list. The behavior is undefined if
    the list is empty.

    Example:

    ```mlir
    %item = list.peek_front %li : !list.list<i32> -> i32
    ```
  }];

  let arguments = (ins List_ListType:$input);
  let results = (outs AnyInteger:$item);

  let assemblyFormat =
      "$input attr-dict `:` qualified(type($input)) `->` type($item)";

  let builders = [
    OpBuilder<(ins "::mlir::Value":$input), [{
      build($_builder, $_state,
            ::llvm::cast<ListType>(input.getType()).getElementType(), input);
    }]>
  ];
}

// NoMemoryEffect rather than Pure: undefined on an empty list, so not always
// speculatable.
def List_PopFrontOp : List_Op<"pop_front",
    [NoMemoryEffect, AllTypesMatch<["input", "result"]>,
     DeclareOpInterfaceMethods<InferIntRangeInterface,
                               ["inferResultRanges"]>]> {
  let summary = "list without its first element";
  let description = [{
    Returns the operand list without its first element. The behavior is
    undefined if the list is empty.

    Example:

    ```mlir
    %shorter = list.pop_front %li : !list.list<i32>
    ```
  }];

  let arguments = (ins List_ListType:$input);
  let results = (outs List_ListType:$result);

  let assemblyFormat = "$input attr-dict `:` qualified(type($input))";

  let builders = [
    OpBuilder<(ins "::mlir::Value":$input), [{
      build($_builder, $_state, input.getType(), input);
    }]>
  ];
}

def List_PrintOp : List_Op<"print", [MemoryEffects<[MemWrite]>]> {
  let summary = "print the elements of a list";
  let description = [{
    Prints the elements of the operand list.

    Example:

    ```mlir
    list.print %li : !list.list<i32>
    ```
  }];

  let arguments = (ins List_ListType:$input);

  let assemblyFormat = "$input attr-dict `:` qualified(type($input))";
}

def List_PushBackOp : List_Op<"push_back",
    [Pure, AllTypesMatch<["input", "result"]>,
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

def List_PushFrontOp : List_Op<"push_front",
    [Pure, AllTypesMatch<["input", "result"]>,
     List_ItemTypeMatchesElementType<"input", "item">,
     DeclareOpInterfaceMethods<InferIntRangeInterface,
                               ["inferResultRanges"]>]> {
  let summary = "list with an element prepended";
  let description = [{
    Returns the operand list with `$item` prepended to it.

    Example:

    ```mlir
    %longer = list.push_front %li, %item : !list.list<i32>
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

def List_RangeOp : List_Op<"range", [Pure]> {
  let summary = "list of consecutive integers";
  let description = [{
    Creates the list of consecutive integers from `$lower`, inclusive, to
    `$upper`, exclusive. The list is empty if `$upper` is not greater than
    `$lower`.

    Example:

    ```mlir
    %li = list.range %lb to %ub : !list.list<i32>
    ```
  }];

  let arguments = (ins I32:$lower, I32:$upper);
  let results = (outs List_ListType:$result);

  let assemblyFormat =
      "$lower `to` $upper attr-dict `:` qualified(type($result))";
}

def List_ReverseOp : List_Op<"reverse",
    [Pure, AllTypesMatch<["input", "result"]>]> {
  let summary = "list with its elements in reverse order";
  let description = [{
    Returns the elements of the operand list in reverse order.

    Example:

    ```mlir
    %reversed = list.reverse %li : !list.list<i32>
    ```
  }];

  let arguments = (ins List_ListType:$input);
  let results = (outs List_ListType:$result);

  let assemblyFormat = "$input attr-dict `:` qualified(type($input))";

  let builders = [
    OpBuilder<(ins "::mlir::Value":$input), [{
      build($_builder, $_state, input.getType(), input);
    }]>
  ];
}

def List_YieldOp : List_Op<"yield", [Pure, Terminator, HasParent<"MapOp">]> {
  let summary = "terminate and yield from a list.map body";
  let description = [{
    Terminates the body region of a `list.map` operation and yields the value
    computed for one element of the mapped list.

    Example:

    ```mlir
    list.yield %res : i64
    ```
  }];

  let arguments = (ins AnyInteger:$yielded);

  let assemblyFormat = "$yielded attr-dict `:` type($yielded)";
}

#endif // MLIR_DIALECT_LIST_IR_LISTOPS
