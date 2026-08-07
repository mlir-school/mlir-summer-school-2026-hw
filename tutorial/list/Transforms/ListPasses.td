//===-- ListPasses.td - List transformation definitions ----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Defines the transformations of the list dialect.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LIST_TRANSFORMS_LISTPASSES
#define MLIR_DIALECT_LIST_TRANSFORMS_LISTPASSES

include "mlir/Pass/PassBase.td"

def ListLowerFromElements : Pass<"list-lower-from-elements"> {
  let summary = "Lower list.from_elements to list.empty and list.push_back";
  let description = [{
    Lowers every `list.from_elements` operation to a `list.empty` followed by a
    sequence of `list.push_back` operations, one per element, by walking the IR
    and rewriting operations directly without a pattern rewriter.

    Example:

    ```mlir
    %li = list.from_elements %a, %b, %c : (i32, i32, i32) -> !list.list<i32>
    ```

    becomes:

    ```mlir
    %empty = list.empty : !list.list<i32>
    %0 = list.push_back %empty, %a : !list.list<i32>
    %1 = list.push_back %0, %b : !list.list<i32>
    %li = list.push_back %1, %c : !list.list<i32>
    ```
  }];
}

def ListSimplify : Pass<"list-simplify"> {
  let summary = "Simplify and partially lower list operations";
  let description = [{
    Applies the following patterns to the IR:

    - Exercise 2: A non-empty `list.from_elements` is replaced by a
      `list.from_elements` containing all but its last element, followed by a
      `list.push_back` of that last element. Repeated application produces a
      `list.empty` followed by one `list.push_back` per element.
    - Exercise 3: Two consecutive `list.map` operations are merged into a
      single one that
      applies both computations to every element, provided the producer map is
      free of side effects: `list.map(list.map(%x))` becomes `list.map(%x)`.
      An unused producer is left for DCE.
    - Exercise 4: A `list.map` becomes an `scf.while` loop that carries the
      elements that still have to be mapped and the mapped elements collected
      so far. Every iteration takes the first element that is left, applies the
      body of the `list.map` to it and appends the mapped element to the back of
      the result list.

    The map merge is given a higher benefit than the map lowering, so that
    consecutive maps are merged into one before the result is lowered to a loop.
  }];

  let dependentDialects = [
    "arith::ArithDialect",
    "list::ListDialect",
    "scf::SCFDialect"
  ];
}

#endif // MLIR_DIALECT_LIST_TRANSFORMS_LISTPASSES
