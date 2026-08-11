// RUN: tutorial-opt %s -split-input-file -canonicalize | FileCheck %s

// The supplied EmptyOp implementation is the reference for the exercise.

// CHECK-LABEL: func.func @empty
// CHECK:         %[[C0:.*]] = arith.constant 0 : i32
// CHECK-NEXT:    return %[[C0]] : i32
func.func @empty() -> i32 {
  %list = list.empty : !list.list<i32>
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @from_elements
// CHECK:         %[[C3:.*]] = arith.constant 3 : i32
// CHECK-NEXT:    return %[[C3]] : i32
func.func @from_elements(%a: i32, %b: i32, %c: i32) -> i32 {
  %list = list.from_elements %a, %b, %c
      : (i32, i32, i32) -> !list.list<i32>
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @reverse
// CHECK:         %[[C2:.*]] = arith.constant 2 : i32
// CHECK-NEXT:    return %[[C2]] : i32
func.func @reverse(%a: i32, %b: i32) -> i32 {
  %input = list.from_elements %a, %b
      : (i32, i32) -> !list.list<i32>
  %list = list.reverse %input : !list.list<i32>
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @map
// CHECK:         %[[C2:.*]] = arith.constant 2 : i32
// CHECK-NEXT:    return %[[C2]] : i32
func.func @map(%a: i32, %b: i32) -> i32 {
  %input = list.from_elements %a, %b
      : (i32, i32) -> !list.list<i32>
  %mapped = list.map %input with (%element : i32) -> i64 {
    %extended = arith.extsi %element : i32 to i64
    list.yield %extended : i64
  }
  %length = list.length %mapped : !list.list<i64> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @push_back
// CHECK:         %[[C3:.*]] = arith.constant 3 : i32
// CHECK-NEXT:    return %[[C3]] : i32
func.func @push_back(%a: i32, %b: i32) -> i32 {
  %input = list.from_elements %a, %b
      : (i32, i32) -> !list.list<i32>
  %list = list.push_back %input, %a : !list.list<i32>
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @chain
// CHECK:         %[[C4:.*]] = arith.constant 4 : i32
// CHECK-NEXT:    return %[[C4]] : i32
func.func @chain(%a: i32, %b: i32, %c: i32) -> i32 {
  %input = list.from_elements %a, %b, %c
      : (i32, i32, i32) -> !list.list<i32>
  %mapped = list.map %input with (%element : i32) -> i64 {
    %extended = arith.extsi %element : i32 to i64
    list.yield %extended : i64
  }
  %reversed = list.reverse %mapped : !list.list<i64>
  %item = arith.extsi %a : i32 to i64
  %longer = list.push_back %reversed, %item : !list.list<i64>
  %length = list.length %longer : !list.list<i64> -> i32
  return %length : i32
}

// -----

// A value with no defining operation has no interface to query.

// CHECK-LABEL: func.func @unknown
// CHECK-SAME:    %[[LIST:.*]]: !list.list<i32>
// CHECK:         %[[LENGTH:.*]] = list.length %[[LIST]]
// CHECK-NEXT:    return %[[LENGTH]] : i32
func.func @unknown(%list: !list.list<i32>) -> i32 {
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}
