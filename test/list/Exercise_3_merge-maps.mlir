// RUN: tutorial-opt %s -split-input-file -list-simplify | FileCheck %s

// The two maps are merged into a single one, then the merged map becomes a
// single while loop that applies both computations to every element.

// CHECK-LABEL: @merge_maps(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>
// CHECK:         %[[LOOP:.*]]:2 = scf.while (%{{.*}} = %[[LI]],
// CHECK:         } do {
// CHECK-NEXT:    ^bb0(%[[ARG:.*]]: !list.list<i32>, %[[ACC:.*]]: !list.list<i64>):
// CHECK-NEXT:      %[[ELEM:.*]] = list.peek_front %[[ARG]] : !list.list<i32> -> i32
// CHECK-NEXT:      %[[REST:.*]] = list.pop_front %[[ARG]] : !list.list<i32>
// CHECK-NEXT:      %[[DOUBLED:.*]] = arith.addi %[[ELEM]], %[[ELEM]] : i32
// CHECK-NEXT:      %[[EXTENDED:.*]] = arith.extsi %[[DOUBLED]] : i32 to i64
// CHECK-NEXT:      %[[LONGER:.*]] = list.push_back %[[ACC]], %[[EXTENDED]] : !list.list<i64>
// CHECK-NEXT:      scf.yield %[[REST]], %[[LONGER]] : !list.list<i32>, !list.list<i64>
// CHECK-NEXT:    }
// CHECK-NEXT:    return %[[LOOP]]#1 : !list.list<i64>
func.func @merge_maps(%li: !list.list<i32>) -> !list.list<i64> {
  %doubled = list.map %li with (%a : i32) -> i32 {
    %0 = arith.addi %a, %a : i32
    list.yield %0 : i32
  }
  %extended = list.map %doubled with (%b : i32) -> i64 {
    %1 = arith.extsi %b : i32 to i64
    list.yield %1 : i64
  }
  return %extended : !list.list<i64>
}

// -----

// Merging is applied repeatedly: a chain of three maps becomes one loop. The
// two identity maps leave nothing behind in its body.

// CHECK-LABEL: @merge_three_maps(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>
// CHECK:         %[[LOOP:.*]]:2 = scf.while (%{{.*}} = %[[LI]],
// CHECK:         } do {
// CHECK-NEXT:    ^bb0(%[[ARG:.*]]: !list.list<i32>, %[[ACC:.*]]: !list.list<i32>):
// CHECK-NEXT:      %[[ELEM:.*]] = list.peek_front %[[ARG]] : !list.list<i32> -> i32
// CHECK-NEXT:      %[[REST:.*]] = list.pop_front %[[ARG]] : !list.list<i32>
// CHECK-NEXT:      %[[SQUARED:.*]] = arith.muli %[[ELEM]], %[[ELEM]] : i32
// CHECK-NEXT:      %[[LONGER:.*]] = list.push_back %[[ACC]], %[[SQUARED]] : !list.list<i32>
// CHECK-NEXT:      scf.yield %[[REST]], %[[LONGER]] : !list.list<i32>, !list.list<i32>
// CHECK-NEXT:    }
// CHECK-NEXT:    return %[[LOOP]]#1 : !list.list<i32>
func.func @merge_three_maps(%li: !list.list<i32>) -> !list.list<i32> {
  %identity = list.map %li with (%a : i32) -> i32 {
    list.yield %a : i32
  }
  %squared = list.map %identity with (%b : i32) -> i32 {
    %0 = arith.muli %b, %b : i32
    list.yield %0 : i32
  }
  %again = list.map %squared with (%c : i32) -> i32 {
    list.yield %c : i32
  }
  return %again : !list.list<i32>
}

// -----

// When the producer map has other users, merging still applies and duplicates
// its body into the consumer. Both maps become loops over the original list.

// CHECK-LABEL: @producer_has_other_users(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>
// CHECK:         %[[FIRST:.*]]:2 = scf.while (%{{.*}} = %[[LI]],
// CHECK:         } do {
// CHECK:           arith.addi
// CHECK:         }
// CHECK:         %[[SECOND:.*]]:2 = scf.while (%{{.*}} = %[[LI]],
// CHECK:         } do {
// CHECK:           arith.addi
// CHECK:         }
// CHECK:         return %[[FIRST]]#1, %[[SECOND]]#1
func.func @producer_has_other_users(%li: !list.list<i32>)
    -> (!list.list<i32>, !list.list<i32>) {
  %doubled = list.map %li with (%a : i32) -> i32 {
    %0 = arith.addi %a, %a : i32
    list.yield %0 : i32
  }
  %copy = list.map %doubled with (%b : i32) -> i32 {
    list.yield %b : i32
  }
  return %doubled, %copy : !list.list<i32>, !list.list<i32>
}

// -----

// A producer with side effects is not merged because cloning its body would
// duplicate the effects. Both maps become loops, and the second consumes the
// result of the first.

// CHECK-LABEL: @merge_keeps_side_effects(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>, %[[OTHER:[^:]*]]: !list.list<i32>
// CHECK:         %[[FIRST:.*]]:2 = scf.while (%{{.*}} = %[[LI]],
// CHECK:         } do {
// CHECK:           list.print %[[OTHER]] : !list.list<i32>
// CHECK:         }
// CHECK:         %[[SECOND:.*]]:2 = scf.while (%{{.*}} = %[[FIRST]]#1,
// CHECK:         } do {
// CHECK:           arith.addi
// CHECK:         }
// CHECK:         return %[[SECOND]]#1 : !list.list<i32>
func.func @merge_keeps_side_effects(%li: !list.list<i32>,
                                    %other: !list.list<i32>)
    -> !list.list<i32> {
  %printed = list.map %li with (%a : i32) -> i32 {
    list.print %other : !list.list<i32>
    list.yield %a : i32
  }
  %doubled = list.map %printed with (%b : i32) -> i32 {
    %0 = arith.addi %b, %b : i32
    list.yield %0 : i32
  }
  return %doubled : !list.list<i32>
}
