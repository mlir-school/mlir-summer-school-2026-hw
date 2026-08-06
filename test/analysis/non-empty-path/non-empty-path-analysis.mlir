// RUN: tutorial-opt --print-list-non-empty-path-analysis --split-input-file %s | FileCheck %s

// Facts introduced by ordinary operations are carried through the dense state.
// CHECK-LABEL: func.func @definition_fact
func.func @definition_fact(%value: i32) -> !list.list<i32> {
  %empty = list.empty : !list.list<i32>
  %list = list.push_back %empty, %value : !list.list<i32>
  // CHECK: list.pop_front {{.*}} {list.input_non_empty = true}
  %result = list.pop_front %list : !list.list<i32>
  return %result : !list.list<i32>
}

// -----

// The true edge of `length != 0` refines the state for the same SSA value.
// CHECK-LABEL: func.func @true_edge_of_not_equal
func.func @true_edge_of_not_equal(%input: !list.list<i32>) -> !list.list<i32> {
  %length = list.length %input : !list.list<i32> -> i32
  %zero = arith.constant 0 : i32
  %non_empty = arith.cmpi ne, %length, %zero : i32
  cf.cond_br %non_empty, ^safe, ^empty

^safe:
  // CHECK: list.length {{.*}} {list.input_non_empty = true}
  %length_again = list.length %input : !list.list<i32> -> i32
  // CHECK: list.pop_front {{.*}} {list.input_non_empty = true}
  %result = list.pop_front %input : !list.list<i32>
  return %result : !list.list<i32>

^empty:
  // CHECK: list.length {{.*}} {list.input_non_empty = false}
  %unused = list.length %input : !list.list<i32> -> i32
  return %input : !list.list<i32>
}

// -----

// The false edge of `length == 0` also establishes non-emptiness.
// CHECK-LABEL: func.func @false_edge_of_equal
func.func @false_edge_of_equal(%input: !list.list<i32>) -> !list.list<i32> {
  %length = list.length %input : !list.list<i32> -> i32
  %zero = arith.constant 0 : i32
  %is_empty = arith.cmpi eq, %zero, %length : i32
  cf.cond_br %is_empty, ^empty, ^safe

^empty:
  return %input : !list.list<i32>

^safe:
  // CHECK: list.pop_front {{.*}} {list.input_non_empty = true}
  %result = list.pop_front %input : !list.list<i32>
  return %result : !list.list<i32>
}

// -----

// A fact present on only one predecessor does not survive a merge.
// CHECK-LABEL: func.func @merge_intersects_facts
func.func @merge_intersects_facts(%input: !list.list<i32>) -> !list.list<i32> {
  %length = list.length %input : !list.list<i32> -> i32
  %zero = arith.constant 0 : i32
  %non_empty = arith.cmpi ne, %length, %zero : i32
  cf.cond_br %non_empty, ^known, ^not_known

^known:
  cf.br ^merge

^not_known:
  cf.br ^merge

^merge:
  // CHECK: list.pop_front {{.*}} {list.input_non_empty = false}
  %result = list.pop_front %input : !list.list<i32>
  return %result : !list.list<i32>
}

// -----

// A definition-derived fact present on every predecessor survives a merge.
// CHECK-LABEL: func.func @merge_preserves_common_fact
func.func @merge_preserves_common_fact(%condition: i1, %value: i32) -> !list.list<i32> {
  %empty = list.empty : !list.list<i32>
  %list = list.push_back %empty, %value : !list.list<i32>
  cf.cond_br %condition, ^left, ^right

^left:
  cf.br ^merge

^right:
  cf.br ^merge

^merge:
  // CHECK: list.pop_front {{.*}} {list.input_non_empty = true}
  %result = list.pop_front %list : !list.list<i32>
  return %result : !list.list<i32>
}
