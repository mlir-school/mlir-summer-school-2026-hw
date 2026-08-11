// RUN: tutorial-opt %s -split-input-file -canonicalize | FileCheck %s

// CHECK-LABEL: func.func @constant_range
// CHECK:         %[[C5:.*]] = arith.constant 5 : i32
// CHECK-NEXT:    return %[[C5]] : i32
func.func @constant_range() -> i32 {
  %lower = arith.constant 2 : i32
  %upper = arith.constant 7 : i32
  %list = list.range %lower to %upper : !list.list<i32>
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// -----

// A range whose upper bound is not greater than its lower bound is empty.

// CHECK-LABEL: func.func @empty_range
// CHECK:         %[[C0:.*]] = arith.constant 0 : i32
// CHECK-NEXT:    return %[[C0]] : i32
func.func @empty_range() -> i32 {
  %lower = arith.constant 7 : i32
  %upper = arith.constant 2 : i32
  %list = list.range %lower to %upper : !list.list<i32>
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// -----

// A block argument has no defining operation through which to query the
// constant-integer interface.

// CHECK-LABEL: func.func @unknown_lower
// CHECK-SAME:    %[[LOWER:.*]]: i32
// CHECK:         %[[RANGE:.*]] = list.range %[[LOWER]]
// CHECK:         %[[LENGTH:.*]] = list.length %[[RANGE]]
// CHECK-NEXT:    return %[[LENGTH]] : i32
func.func @unknown_lower(%lower: i32) -> i32 {
  %upper = arith.constant 7 : i32
  %list = list.range %lower to %upper : !list.list<i32>
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// -----

// Exercise 2 composes with every implementation from Exercise 1.

// CHECK-LABEL: func.func @range_chain
// CHECK:         %[[C6:.*]] = arith.constant 6 : i32
// CHECK-NEXT:    return %[[C6]] : i32
func.func @range_chain() -> i32 {
  %lower = arith.constant 2 : i32
  %upper = arith.constant 7 : i32
  %range = list.range %lower to %upper : !list.list<i32>
  %mapped = list.map %range with (%element : i32) -> i64 {
    %extended = arith.extsi %element : i32 to i64
    list.yield %extended : i64
  }
  %reversed = list.reverse %mapped : !list.list<i64>
  %item = arith.constant 42 : i64
  %longer = list.push_back %reversed, %item : !list.list<i64>
  %length = list.length %longer : !list.list<i64> -> i32
  return %length : i32
}
