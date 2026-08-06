// RUN: tutorial-opt --optimize-list-non-empty-paths --split-input-file %s | FileCheck %s

// A comparison repeated on the non-empty edge can be folded.
// CHECK-LABEL: func.func @fold_on_true_edge
// CHECK-DAG: %[[FALSE:.*]] = arith.constant false
// CHECK-DAG: %[[TRUE:.*]] = arith.constant true
// CHECK: cf.cond_br {{.*}}, ^[[MERGE:bb[0-9]+]](%[[TRUE]] : i1), ^[[MERGE]](%[[FALSE]] : i1)
// CHECK: ^[[MERGE]](%[[PATH_RESULT:.*]]: i1):
// CHECK: return %[[FALSE]], %[[PATH_RESULT]] : i1, i1
func.func @fold_on_true_edge(%input: !list.list<i32>) -> (i1, i1) {
  %length = list.length %input : !list.list<i32> -> i32
  %zero = arith.constant 0 : i32
  %non_empty = arith.cmpi ne, %length, %zero : i32
  cf.cond_br %non_empty, ^safe, ^empty

^safe:
  %length_again = list.length %input : !list.list<i32> -> i32
  %is_empty_again = arith.cmpi eq, %length_again, %zero : i32
  %is_non_empty_again = arith.cmpi ne, %zero, %length_again : i32
  return %is_empty_again, %is_non_empty_again : i1, i1

^empty:
  %false = arith.constant false
  return %false, %false : i1, i1
}

// -----

// The false edge of an equality comparison carries the same useful fact.
// CHECK-LABEL: func.func @fold_on_false_edge
// CHECK: %[[TRUE:.*]] = arith.constant true
// CHECK: %[[FALSE:.*]] = arith.constant false
// CHECK: cf.cond_br {{.*}}, ^[[MERGE:bb[0-9]+]](%[[FALSE]] : i1), ^[[MERGE]](%[[TRUE]] : i1)
// CHECK: ^[[MERGE]](%[[RESULT:.*]]: i1):
// CHECK: return %[[RESULT]] : i1
func.func @fold_on_false_edge(%input: !list.list<i32>) -> i1 {
  %length = list.length %input : !list.list<i32> -> i32
  %zero = arith.constant 0 : i32
  %is_empty = arith.cmpi eq, %length, %zero : i32
  cf.cond_br %is_empty, ^empty, ^safe

^empty:
  %false = arith.constant false
  return %false : i1

^safe:
  %length_again = list.length %input : !list.list<i32> -> i32
  %is_non_empty = arith.cmpi ne, %length_again, %zero : i32
  return %is_non_empty : i1
}

// -----

// A fact introduced by list.push_back is also available at later program points.
// CHECK-LABEL: func.func @fold_definition_fact
// CHECK: %[[TRUE:.*]] = arith.constant true
// CHECK: return %[[TRUE]] : i1
func.func @fold_definition_fact(%value: i32) -> i1 {
  %empty = list.empty : !list.list<i32>
  %list = list.push_back %empty, %value : !list.list<i32>
  %length = list.length %list : !list.list<i32> -> i32
  %zero = arith.constant 0 : i32
  %non_empty = arith.cmpi ne, %length, %zero : i32
  return %non_empty : i1
}

// -----

// The empty edge does not establish non-emptiness, so its check is preserved.
// CHECK-LABEL: func.func @do_not_fold_on_empty_edge
// CHECK-COUNT-2: arith.cmpi
func.func @do_not_fold_on_empty_edge(%input: !list.list<i32>) -> i1 {
  %length = list.length %input : !list.list<i32> -> i32
  %zero = arith.constant 0 : i32
  %non_empty = arith.cmpi ne, %length, %zero : i32
  cf.cond_br %non_empty, ^safe, ^empty

^safe:
  %true = arith.constant true
  return %true : i1

^empty:
  %length_again = list.length %input : !list.list<i32> -> i32
  %is_empty_again = arith.cmpi eq, %length_again, %zero : i32
  return %is_empty_again : i1
}

// -----

// A path-specific fact is discarded when it is not common to every predecessor.
// CHECK-LABEL: func.func @do_not_fold_after_merge
// CHECK: arith.cmpi ne
// CHECK: arith.cmpi eq
func.func @do_not_fold_after_merge(%input: !list.list<i32>) -> i1 {
  %length = list.length %input : !list.list<i32> -> i32
  %zero = arith.constant 0 : i32
  %non_empty = arith.cmpi ne, %length, %zero : i32
  cf.cond_br %non_empty, ^known, ^not_known

^known:
  cf.br ^merge

^not_known:
  cf.br ^merge

^merge:
  %length_again = list.length %input : !list.list<i32> -> i32
  %is_empty = arith.cmpi eq, %length_again, %zero : i32
  return %is_empty : i1
}
