// RUN: tutorial-opt %s -split-input-file -canonicalize | FileCheck %s

// Unpacking a list that was just packed hands back the values that went into
// it. No operation is left behind.

// CHECK-LABEL: @get_elements_of_from_elements(
// CHECK-SAME:      %[[A:.*]]: i32, %[[B:.*]]: i32
// CHECK-NEXT:    return %[[A]], %[[B]] : i32, i32
func.func @get_elements_of_from_elements(%a: i32, %b: i32) -> (i32, i32) {
  %li = list.from_elements %a, %b : (i32, i32) -> !list.list<i32>
  %0, %1 = list.get_elements %li : (!list.list<i32>) -> (i32, i32)
  return %0, %1 : i32, i32
}

// -----

// The elements of a constant list are constants. The list dialect has no
// operation for a single integer, so they are materialized as `arith.constant`.

// CHECK-LABEL: @get_elements_of_constant(
// CHECK:         %[[ONE:.*]] = arith.constant 1 : i32
// CHECK:         %[[TWO:.*]] = arith.constant 2 : i32
// CHECK:         return %[[ONE]], %[[TWO]] : i32, i32
func.func @get_elements_of_constant() -> (i32, i32) {
  %li = list.constant #list.list<[1, 2]> : !list.list<i32>
  %0, %1 = list.get_elements %li : (!list.list<i32>) -> (i32, i32)
  return %0, %1 : i32, i32
}

// -----

// Asking for a different number of elements than the list holds is undefined;
// nothing is folded.

// CHECK-LABEL: @get_elements_wrong_length(
// CHECK:         %[[LI:.*]] = list.from_elements
// CHECK:         %[[ELEM:.*]] = list.get_elements %[[LI]]
// CHECK:         return %[[ELEM]] : i32
func.func @get_elements_wrong_length(%a: i32, %b: i32) -> i32 {
  %li = list.from_elements %a, %b : (i32, i32) -> !list.list<i32>
  %0 = list.get_elements %li : (!list.list<i32>) -> (i32)
  return %0 : i32
}

// -----

// CHECK-LABEL: @is_empty_of_empty(
// CHECK:         %[[TRUE:.*]] = arith.constant true
// CHECK-NEXT:    return %[[TRUE]] : i1
func.func @is_empty_of_empty() -> i1 {
  %li = list.empty : !list.list<i32>
  %0 = list.is_empty %li : !list.list<i32> -> i1
  return %0 : i1
}

// -----

// Nothing is known about the operand list, but a list that an element has just
// been appended to holds at least that element.

// CHECK-LABEL: @is_empty_of_push_back(
// CHECK:         %[[FALSE:.*]] = arith.constant false
// CHECK-NEXT:    return %[[FALSE]] : i1
func.func @is_empty_of_push_back(%li: !list.list<i32>, %item: i32) -> i1 {
  %longer = list.push_back %li, %item : !list.list<i32>
  %0 = list.is_empty %longer : !list.list<i32> -> i1
  return %0 : i1
}

// -----

// CHECK-LABEL: @length_of_empty(
// CHECK:         %[[ZERO:.*]] = arith.constant 0 : i32
// CHECK-NEXT:    return %[[ZERO]] : i32
func.func @length_of_empty() -> i32 {
  %li = list.empty : !list.list<i32>
  %0 = list.length %li : !list.list<i32> -> i32
  return %0 : i32
}

// -----

// CHECK-LABEL: @length_of_constant(
// CHECK:         %[[THREE:.*]] = arith.constant 3 : i32
// CHECK-NEXT:    return %[[THREE]] : i32
func.func @length_of_constant() -> i32 {
  %li = list.constant #list.list<[1, 2, 3]> : !list.list<i32>
  %0 = list.length %li : !list.list<i32> -> i32
  return %0 : i32
}

// -----

// Taking the front off a list that something was just prepended to gives back
// the operands of the prepend, whatever the list holds.

// CHECK-LABEL: @peek_and_pop_front_of_push_front(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>, %[[ITEM:[^:]*]]: i32
// CHECK-NEXT:    return %[[ITEM]], %[[LI]] : i32, !list.list<i32>
func.func @peek_and_pop_front_of_push_front(%li: !list.list<i32>, %item: i32)
    -> (i32, !list.list<i32>) {
  %longer = list.push_front %li, %item : !list.list<i32>
  %front = list.peek_front %longer : !list.list<i32> -> i32
  %rest = list.pop_front %longer : !list.list<i32>
  return %front, %rest : i32, !list.list<i32>
}

// -----

// CHECK-LABEL: @peek_and_pop_front_of_constant(
// CHECK:         %[[ONE:.*]] = arith.constant 1 : i32
// CHECK:         %[[REST:.*]] = list.constant #list.list<[2, 3]> : !list.list<i32>
// CHECK:         return %[[ONE]], %[[REST]] : i32, !list.list<i32>
func.func @peek_and_pop_front_of_constant() -> (i32, !list.list<i32>) {
  %li = list.constant #list.list<[1, 2, 3]> : !list.list<i32>
  %front = list.peek_front %li : !list.list<i32> -> i32
  %rest = list.pop_front %li : !list.list<i32>
  return %front, %rest : i32, !list.list<i32>
}

// -----

// Adding a constant element to a constant list gives a longer constant list.

// CHECK-LABEL: @push_constants(
// CHECK:         %[[BACK:.*]] = list.constant #list.list<[2, 3]> : !list.list<i32>
// CHECK:         %[[FRONT:.*]] = list.constant #list.list<[1, 2]> : !list.list<i32>
// CHECK:         return %[[BACK]], %[[FRONT]]
func.func @push_constants() -> (!list.list<i32>, !list.list<i32>) {
  %li = list.constant #list.list<[2]> : !list.list<i32>
  %one = arith.constant 1 : i32
  %three = arith.constant 3 : i32
  %back = list.push_back %li, %three : !list.list<i32>
  %front = list.push_front %li, %one : !list.list<i32>
  return %back, %front : !list.list<i32>, !list.list<i32>
}

// -----

// A constant element is not enough: nothing is known about the operand list.

// CHECK-LABEL: @push_back_on_opaque_list(
// CHECK-SAME:      %[[LI:.*]]: !list.list<i32>
// CHECK:         %[[LONGER:.*]] = list.push_back %[[LI]]
// CHECK:         return %[[LONGER]] : !list.list<i32>
func.func @push_back_on_opaque_list(%li: !list.list<i32>) -> !list.list<i32> {
  %item = arith.constant 1 : i32
  %longer = list.push_back %li, %item : !list.list<i32>
  return %longer : !list.list<i32>
}

// -----

// CHECK-LABEL: @range_of_constants(
// CHECK:         %[[LI:.*]] = list.constant #list.list<[1, 2, 3]> : !list.list<i32>
// CHECK-NEXT:    return %[[LI]] : !list.list<i32>
func.func @range_of_constants() -> !list.list<i32> {
  %lb = arith.constant 1 : i32
  %ub = arith.constant 4 : i32
  %li = list.range %lb to %ub : !list.list<i32>
  return %li : !list.list<i32>
}

// -----

// Folding a range writes down one element per integer in it, so a long range is
// left alone: it is cheaper to compute than to spell out.

// CHECK-LABEL: @long_range(
// CHECK:         %[[LI:.*]] = list.range
// CHECK-NEXT:    return %[[LI]] : !list.list<i32>
func.func @long_range() -> !list.list<i32> {
  %lb = arith.constant 0 : i32
  %ub = arith.constant 1000 : i32
  %li = list.range %lb to %ub : !list.list<i32>
  return %li : !list.list<i32>
}

// -----

// CHECK-LABEL: @reverse_of_reverse(
// CHECK-SAME:      %[[LI:.*]]: !list.list<i32>
// CHECK-NEXT:    return %[[LI]] : !list.list<i32>
func.func @reverse_of_reverse(%li: !list.list<i32>) -> !list.list<i32> {
  %once = list.reverse %li : !list.list<i32>
  %twice = list.reverse %once : !list.list<i32>
  return %twice : !list.list<i32>
}

// -----

// CHECK-LABEL: @reverse_of_constant(
// CHECK:         %[[LI:.*]] = list.constant #list.list<[3, 2, 1]> : !list.list<i32>
// CHECK-NEXT:    return %[[LI]] : !list.list<i32>
func.func @reverse_of_constant() -> !list.list<i32> {
  %li = list.constant #list.list<[1, 2, 3]> : !list.list<i32>
  %reversed = list.reverse %li : !list.list<i32>
  return %reversed : !list.list<i32>
}
