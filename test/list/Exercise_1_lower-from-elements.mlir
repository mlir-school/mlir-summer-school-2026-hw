// RUN: tutorial-opt %s -split-input-file -list-lower-from-elements | FileCheck %s

// Every `list.from_elements` becomes a `list.empty` followed by one
// `list.push_back` per element, appending them in order.

// CHECK-LABEL: @from_elements(
// CHECK-SAME:      %[[A:.*]]: i32, %[[B:.*]]: i32, %[[C:.*]]: i32
// CHECK:         %[[EMPTY:.*]] = list.empty : !list.list<i32>
// CHECK-NEXT:    %[[ONE:.*]] = list.push_back %[[EMPTY]], %[[A]] : !list.list<i32>
// CHECK-NEXT:    %[[TWO:.*]] = list.push_back %[[ONE]], %[[B]] : !list.list<i32>
// CHECK-NEXT:    %[[THREE:.*]] = list.push_back %[[TWO]], %[[C]] : !list.list<i32>
// CHECK-NEXT:    return %[[THREE]] : !list.list<i32>
// CHECK-NOT:     list.from_elements
func.func @from_elements(%a: i32, %b: i32, %c: i32) -> !list.list<i32> {
  %li = list.from_elements %a, %b, %c : (i32, i32, i32) -> !list.list<i32>
  return %li : !list.list<i32>
}

// -----

// A `list.from_elements` without any element becomes a `list.empty`.

// CHECK-LABEL: @no_elements(
// CHECK:         %[[EMPTY:.*]] = list.empty : !list.list<i64>
// CHECK-NEXT:    return %[[EMPTY]] : !list.list<i64>
// CHECK-NOT:     list.from_elements
func.func @no_elements() -> !list.list<i64> {
  %li = list.from_elements : () -> !list.list<i64>
  return %li : !list.list<i64>
}

// -----

// A `list.from_elements` with a single element becomes an `empty` followed by
// one `push_back`.

// CHECK-LABEL: @one_element(
// CHECK-SAME:      %[[ITEM:.*]]: i32
// CHECK:         %[[EMPTY:.*]] = list.empty : !list.list<i32>
// CHECK-NEXT:    %[[LI:.*]] = list.push_back %[[EMPTY]], %[[ITEM]] : !list.list<i32>
// CHECK-NEXT:    return %[[LI]] : !list.list<i32>
// CHECK-NOT:     list.from_elements
func.func @one_element(%item: i32) -> !list.list<i32> {
  %li = list.from_elements %item : (i32) -> !list.list<i32>
  return %li : !list.list<i32>
}

// -----

// All `list.from_elements` operations in the function are lowered.

// CHECK-LABEL: @two_from_elements(
// CHECK-SAME:      %[[A:.*]]: i32, %[[B:.*]]: i32
// CHECK:         %[[EMPTY1:.*]] = list.empty : !list.list<i32>
// CHECK-NEXT:    %[[FIRST:.*]] = list.push_back %[[EMPTY1]], %[[A]] : !list.list<i32>
// CHECK:         %[[EMPTY2:.*]] = list.empty : !list.list<i32>
// CHECK-NEXT:    %[[SECOND:.*]] = list.push_back %[[EMPTY2]], %[[B]] : !list.list<i32>
// CHECK:         return %[[FIRST]], %[[SECOND]] : !list.list<i32>, !list.list<i32>
// CHECK-NOT:     list.from_elements
func.func @two_from_elements(%a: i32, %b: i32)
    -> (!list.list<i32>, !list.list<i32>) {
  %first = list.from_elements %a : (i32) -> !list.list<i32>
  %second = list.from_elements %b : (i32) -> !list.list<i32>
  return %first, %second : !list.list<i32>, !list.list<i32>
}
