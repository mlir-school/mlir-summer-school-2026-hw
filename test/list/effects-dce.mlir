// RUN: tutorial-opt %s -split-input-file -list-simplify | FileCheck %s

// Unused list ops without side effects are removed, including a map with a
// pure body and ops that are NoMemoryEffect but not Pure (peek/pop/get).

// CHECK-LABEL: @remove_unused_side_effect_free_ops(
// CHECK-NEXT:    return
func.func @remove_unused_side_effect_free_ops(
    %li: !list.list<i32>, %item: i32) {
  %empty = list.empty : !list.list<i32>
  %from = list.from_elements %item : (i32) -> !list.list<i32>
  %only = list.get_elements %li : (!list.list<i32>) -> (i32)
  %is_empty = list.is_empty %li : !list.list<i32> -> i1
  %length = list.length %li : !list.list<i32> -> i32
  %element = list.peek_front %li : !list.list<i32> -> i32
  %rest = list.pop_front %li : !list.list<i32>
  %longer = list.push_back %li, %item : !list.list<i32>
  %fronted = list.push_front %li, %item : !list.list<i32>
  %range = list.range %item to %item : !list.list<i32>
  %reversed = list.reverse %li : !list.list<i32>
  %mapped = list.map %li with (%arg : i32) -> i32 {
    %doubled = arith.addi %arg, %arg : i32
    list.yield %doubled : i32
  }
  return
}

// -----

// An unused map whose body prints must not be DCE'd; it is lowered to a loop
// that performs the print.

// CHECK-LABEL: @keep_unused_map_with_print(
// CHECK:         scf.while
// CHECK:           list.print
func.func @keep_unused_map_with_print(%li: !list.list<i32>) {
  %mapped = list.map %li with (%arg : i32) -> i32 {
    list.print %li : !list.list<i32>
    list.yield %arg : i32
  }
  return
}
