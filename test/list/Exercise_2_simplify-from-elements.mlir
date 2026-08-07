// RUN: tutorial-opt %s -split-input-file -list-simplify | FileCheck %s

// Every element is appended with a `list.push_back`, from the front of the list
// to its back.

// CHECK-LABEL: @unroll_from_elements(
// CHECK-SAME:      %[[A:.*]]: i32, %[[B:.*]]: i32, %[[C:.*]]: i32
// CHECK:         %[[EMPTY:.*]] = list.empty : !list.list<i32>
// CHECK-NEXT:    %[[ONE:.*]] = list.push_back %[[EMPTY]], %[[A]] : !list.list<i32>
// CHECK-NEXT:    %[[TWO:.*]] = list.push_back %[[ONE]], %[[B]] : !list.list<i32>
// CHECK-NEXT:    %[[THREE:.*]] = list.push_back %[[TWO]], %[[C]] : !list.list<i32>
// CHECK-NEXT:    return %[[THREE]] : !list.list<i32>
// CHECK-NOT:     list.from_elements
func.func @unroll_from_elements(%a: i32, %b: i32, %c: i32) -> !list.list<i32> {
  %li = list.from_elements %a, %b, %c : (i32, i32, i32) -> !list.list<i32>
  return %li : !list.list<i32>
}

// -----

// A `list.from_elements` without any element becomes a `list.empty`, which is
// what terminates the unrolling.

// CHECK-LABEL: @from_no_elements(
// CHECK:         %[[EMPTY:.*]] = list.empty : !list.list<i64>
// CHECK-NEXT:    return %[[EMPTY]] : !list.list<i64>
// CHECK-NOT:     list.from_elements
func.func @from_no_elements() -> !list.list<i64> {
  %li = list.from_elements : () -> !list.list<i64>
  return %li : !list.list<i64>
}

// -----

// Nothing is known about the operand list, so the push stays as it is.

// CHECK-LABEL: @push_back_on_opaque_list(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>, %[[ITEM:[^:]*]]: i32
// CHECK:         %[[LONGER:.*]] = list.push_back %[[LI]], %[[ITEM]] : !list.list<i32>
// CHECK:         return %[[LONGER]] : !list.list<i32>
func.func @push_back_on_opaque_list(%li: !list.list<i32>, %item: i32)
    -> !list.list<i32> {
  %longer = list.push_back %li, %item : !list.list<i32>
  return %longer : !list.list<i32>
}
