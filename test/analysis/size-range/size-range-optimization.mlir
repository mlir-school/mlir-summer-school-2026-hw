// RUN: tutorial-opt --optimize-list-size-ranges --split-input-file %s | FileCheck %s

// A list result proven to have size zero is replaced with list.empty.
// CHECK-LABEL: func.func @zero_pop_front
// CHECK-NOT: list.pop_front
// CHECK: %[[EMPTY:.*]] = list.empty : !list.list<i32>
// CHECK: return %[[EMPTY]] : !list.list<i32>
func.func @zero_pop_front(%value: i32) -> !list.list<i32> {
  %empty = list.empty : !list.list<i32>
  %one = list.push_back %empty, %value : !list.list<i32>
  %zero = list.pop_front %one : !list.list<i32>
  return %zero : !list.list<i32>
}
