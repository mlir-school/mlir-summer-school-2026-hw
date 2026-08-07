// RUN: tutorial-opt %s -split-input-file -loop-invariant-code-motion | FileCheck %s

// `list.peek_front` is undefined on an empty list, so it must not be hoisted
// out of a loop that may run zero times.

// CHECK-LABEL: @no_hoist_peek_front(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>, %[[ACC:[^:]*]]: i32
// CHECK-NOT:     list.peek_front
// CHECK:         scf.while
// CHECK:         } do {
// CHECK:           list.peek_front %[[LI]]
func.func @no_hoist_peek_front(%li: !list.list<i32>, %acc: i32) -> i32 {
  %c0 = arith.constant 0 : i32
  %c1 = arith.constant 1 : i32
  %c10 = arith.constant 10 : i32
  %result:2 = scf.while (%i = %c0, %sum = %acc) : (i32, i32) -> (i32, i32) {
    %cond = arith.cmpi slt, %i, %c10 : i32
    scf.condition(%cond) %i, %sum : i32, i32
  } do {
  ^bb0(%i: i32, %sum: i32):
    %front = list.peek_front %li : !list.list<i32> -> i32
    %next_sum = arith.addi %sum, %front : i32
    %next_i = arith.addi %i, %c1 : i32
    scf.yield %next_i, %next_sum : i32, i32
  }
  return %result#1 : i32
}

// -----

// CHECK-LABEL: @no_hoist_pop_front(
// CHECK-NOT:     list.pop_front
// CHECK:         scf.while
// CHECK:         } do {
// CHECK:           list.pop_front
func.func @no_hoist_pop_front(%li: !list.list<i32>, %acc: !list.list<i32>)
    -> !list.list<i32> {
  %c0 = arith.constant 0 : i32
  %c1 = arith.constant 1 : i32
  %c10 = arith.constant 10 : i32
  %result:2 = scf.while (%i = %c0, %cur = %acc) : (i32, !list.list<i32>)
      -> (i32, !list.list<i32>) {
    %cond = arith.cmpi slt, %i, %c10 : i32
    scf.condition(%cond) %i, %cur : i32, !list.list<i32>
  } do {
  ^bb0(%i: i32, %cur: !list.list<i32>):
    %rest = list.pop_front %li : !list.list<i32>
    %next_i = arith.addi %i, %c1 : i32
    scf.yield %next_i, %rest : i32, !list.list<i32>
  }
  return %result#1 : !list.list<i32>
}
