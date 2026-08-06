// RUN: tutorial-opt --print-list-size-range-analysis --split-input-file %s | FileCheck %s

// CHECK-LABEL: func.func @exact_ranges
func.func @exact_ranges(%value: i32) -> i32 {
  // CHECK: list.empty {list.size_range = "[0, 0]"}
  %empty = list.empty : !list.list<i32>

  // CHECK: list.push_back {{.*}} {list.size_range = "[1, 1]"}
  %one = list.push_back %empty, %value : !list.list<i32>

  // CHECK: list.push_back {{.*}} {list.size_range = "[2, 2]"}
  %two = list.push_back %one, %value : !list.list<i32>

  // CHECK: list.concat {{.*}} {list.size_range = "[3, 3]"}
  %three = list.concat %one, %two : !list.list<i32>

  // list.length propagates the input's size interval to its i32 result.
  // CHECK: list.length {{.*}} {list.size_range = "[3, 3]"}
  %length = list.length %three : !list.list<i32> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @pop_front_range
func.func @pop_front_range(%value: i32) -> i32 {
  %empty = list.empty : !list.list<i32>
  %one = list.push_back %empty, %value : !list.list<i32>
  // CHECK: list.pop_front {{.*}} {list.size_range = "[0, 0]"}
  %popped = list.pop_front %one : !list.list<i32>
  // CHECK: list.length {{.*}} {list.size_range = "[0, 0]"}
  %length = list.length %popped : !list.list<i32> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @unbounded_ranges
func.func @unbounded_ranges(%input: !list.list<i32>, %value: i32) -> i32 {
  // A function argument can have any non-negative size.
  // CHECK: list.push_back {{.*}} {list.size_range = "[1, +inf]"}
  %one_or_more = list.push_back %input, %value : !list.list<i32>

  // CHECK: list.concat {{.*}} {list.size_range = "[2, +inf]"}
  %two_or_more = list.concat %one_or_more, %one_or_more : !list.list<i32>

  // CHECK: list.length {{.*}} {list.size_range = "[2, +inf]"}
  %length = list.length %two_or_more : !list.list<i32> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @control_flow_join
func.func @control_flow_join(%condition: i1, %value: i32) -> i32 {
  %result = scf.if %condition -> (!list.list<i32>) {
    %empty = list.empty : !list.list<i32>
    scf.yield %empty : !list.list<i32>
  } else {
    %empty = list.empty : !list.list<i32>
    %one = list.push_back %empty, %value : !list.list<i32>
    scf.yield %one : !list.list<i32>
  }
  // CHECK: {list.size_range = "[0, 1]"}

  // CHECK: list.length {{.*}} {list.size_range = "[0, 1]"}
  %length = list.length %result : !list.list<i32> -> i32
  return %length : i32
}

// -----

// CHECK-LABEL: func.func @loop_widening
func.func @loop_widening(%upper: index, %value: i32) -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %empty = list.empty : !list.list<i32>
  %result = scf.for %i = %c0 to %upper step %c1
      iter_args(%current = %empty) -> (!list.list<i32>) {
    %next = list.push_back %current, %value : !list.list<i32>
    scf.yield %next : !list.list<i32>
  }
  // The loop may execute any number of times, so widening removes its upper
  // bound while preserving the lower bound from the zero-iteration path.
  // CHECK: {list.size_range = "[0, +inf]"}

  // CHECK: list.length {{.*}} {list.size_range = "[0, +inf]"}
  %length = list.length %result : !list.list<i32> -> i32
  return %length : i32
}
