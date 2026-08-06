// RUN: tutorial-opt %s -split-input-file -list-simplify | FileCheck %s

// CHECK-LABEL: @map(
// CHECK-SAME:      %[[INPUT:.*]]: !list.list<i32>
//       CHECK:   %[[TRUE:.*]] = arith.constant true
//       CHECK:   %[[EMPTY:.*]] = list.empty : !list.list<i64>
//       CHECK:   %[[LOOP:.*]]:2 = scf.while (%[[ARG:.*]] = %[[INPUT]], %[[ACC:.*]] = %[[EMPTY]]) : (!list.list<i32>, !list.list<i64>) -> (!list.list<i32>, !list.list<i64>) {
//       CHECK:     %[[IS_EMPTY:.*]] = list.is_empty %[[ARG]] : !list.list<i32> -> i1
//       CHECK:     %[[COND:.*]] = arith.xori %[[IS_EMPTY]], %[[TRUE]] : i1
//       CHECK:     scf.condition(%[[COND]]) %[[ARG]], %[[ACC]] : !list.list<i32>, !list.list<i64>
//       CHECK:   } do {
//       CHECK:   ^bb0(%[[ARG:.*]]: !list.list<i32>, %[[ACC:.*]]: !list.list<i64>):
//       CHECK:     %[[ELEM:.*]] = list.peek_front %[[ARG]] : !list.list<i32> -> i32
//       CHECK:     %[[REST:.*]] = list.pop_front %[[ARG]] : !list.list<i32>
//       CHECK:     %[[EXT:.*]] = arith.extsi %[[ELEM]] : i32 to i64
//       CHECK:     %[[LONGER:.*]] = list.push_back %[[ACC]], %[[EXT]] : !list.list<i64>
//       CHECK:     scf.yield %[[REST]], %[[LONGER]] : !list.list<i32>, !list.list<i64>
//       CHECK:   }
//       CHECK:   return %[[LOOP]]#1 : !list.list<i64>
func.func @map(%input: !list.list<i32>) -> !list.list<i64> {
  %mapped = list.map %input with (%element : i32) -> i64 {
    %ext = arith.extsi %element : i32 to i64
    list.yield %ext : i64
  }
  return %mapped : !list.list<i64>
}

// -----

// The body of the map may yield the mapped element itself.

// CHECK-LABEL: @identity(
//       CHECK:   scf.while
//       CHECK:   } do {
//       CHECK:   ^bb0(%[[ARG:.*]]: !list.list<i32>, %[[ACC:.*]]: !list.list<i32>):
//       CHECK:     %[[ELEM:.*]] = list.peek_front %[[ARG]] : !list.list<i32> -> i32
//       CHECK:     %[[REST:.*]] = list.pop_front %[[ARG]] : !list.list<i32>
//       CHECK:     %[[LONGER:.*]] = list.push_back %[[ACC]], %[[ELEM]] : !list.list<i32>
//       CHECK:     scf.yield %[[REST]], %[[LONGER]] : !list.list<i32>, !list.list<i32>
func.func @identity(%input: !list.list<i32>) -> !list.list<i32> {
  %mapped = list.map %input with (%element : i32) -> i32 {
    list.yield %element : i32
  }
  return %mapped : !list.list<i32>
}

// -----

// The body of the map may use values defined outside of it.

// CHECK-LABEL: @outer_value(
// CHECK-SAME:      %[[INPUT:[^:]*]]: !list.list<i32>, %[[FACTOR:[^:]*]]: i32
//       CHECK:   scf.while (%{{.*}} = %[[INPUT]],
//       CHECK:   } do {
//       CHECK:   ^bb0(%[[ARG:.*]]: !list.list<i32>, %[[ACC:.*]]: !list.list<i32>):
//       CHECK:     %[[ELEM:.*]] = list.peek_front %[[ARG]]
//       CHECK:     %[[REST:.*]] = list.pop_front %[[ARG]]
//       CHECK:     %[[SCALED:.*]] = arith.muli %[[ELEM]], %[[FACTOR]] : i32
//       CHECK:     %[[LONGER:.*]] = list.push_back %[[ACC]], %[[SCALED]]
//       CHECK:     scf.yield %[[REST]], %[[LONGER]]
func.func @outer_value(%input: !list.list<i32>, %factor: i32)
    -> !list.list<i32> {
  %mapped = list.map %input with (%element : i32) -> i32 {
    %scaled = arith.muli %element, %factor : i32
    list.yield %scaled : i32
  }
  return %mapped : !list.list<i32>
}

// -----

// Independent maps over different lists each become a loop of their own.

// CHECK-LABEL: @two_maps(
// CHECK-SAME:      %[[FIRST:[^:]*]]: !list.list<i32>, %[[SECOND:[^:]*]]: !list.list<i32>
//       CHECK:   %[[DOUBLED:.*]]:2 = scf.while (%{{.*}} = %[[FIRST]],
//       CHECK:   } do {
//       CHECK:     arith.addi
//       CHECK:   }
//       CHECK:   %[[SQUARED:.*]]:2 = scf.while (%{{.*}} = %[[SECOND]],
//       CHECK:   } do {
//       CHECK:     arith.muli
//       CHECK:   }
//       CHECK:   return %[[DOUBLED]]#1, %[[SQUARED]]#1
func.func @two_maps(%first: !list.list<i32>, %second: !list.list<i32>)
    -> (!list.list<i32>, !list.list<i32>) {
  %doubled = list.map %first with (%a : i32) -> i32 {
    %0 = arith.addi %a, %a : i32
    list.yield %0 : i32
  }
  %squared = list.map %second with (%b : i32) -> i32 {
    %1 = arith.muli %b, %b : i32
    list.yield %1 : i32
  }
  return %doubled, %squared : !list.list<i32>, !list.list<i32>
}
