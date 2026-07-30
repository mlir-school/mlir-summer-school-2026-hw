// RUN: tutorial-opt --split-input-file %s | FileCheck %s

func.func @empty() -> !list.list<i32> {
  %0 = list.empty : !list.list<i32>
  return %0 : !list.list<i32>
}

// CHECK-LABEL: func.func @empty
// CHECK: %[[LIST:.*]] = list.empty : !list.list<i32>
// CHECK: return %[[LIST]] : !list.list<i32>

// -----

func.func @push_back(%item: i32) -> !list.list<i32> {
  %empty = list.empty : !list.list<i32>
  %list = list.push_back %empty, %item : !list.list<i32>
  return %list : !list.list<i32>
}

// CHECK-LABEL: func.func @push_back
// CHECK: %[[EMPTY:.*]] = list.empty : !list.list<i32>
// CHECK: %[[LIST:.*]] = list.push_back %[[EMPTY]], %{{.*}} : !list.list<i32>
// CHECK: return %[[LIST]] : !list.list<i32>

// -----

func.func @length(%list: !list.list<i32>) -> i32 {
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// CHECK-LABEL: func.func @length
// CHECK: %[[LENGTH:.*]] = list.length %{{.*}} : !list.list<i32> -> i32
// CHECK: return %[[LENGTH]] : i32
