// RUN: tutorial-opt %s -split-input-file -canonicalize | FileCheck %s

// A `list.from_elements` without any element becomes a `list.empty`: both build
// the same list and `list.empty` is the simpler operation, whatever is done
// with the result afterwards.

// CHECK-LABEL: @from_no_elements(
// CHECK:         %[[EMPTY:.*]] = list.empty : !list.list<i64>
// CHECK-NEXT:    return %[[EMPTY]] : !list.list<i64>
// CHECK-NOT:     list.from_elements
func.func @from_no_elements() -> !list.list<i64> {
  %li = list.from_elements : () -> !list.list<i64>
  return %li : !list.list<i64>
}

// -----

// Two consecutive maps are merged into a single one that applies both
// computations to every element. The producer is left for DCE.

// CHECK-LABEL: @merge_maps(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>
// CHECK:         %[[MAPPED:.*]] = list.map %[[LI]] with (%[[ELEM:.*]]: i32) -> i64 {
// CHECK-NEXT:      %[[DOUBLED:.*]] = arith.addi %[[ELEM]], %[[ELEM]] : i32
// CHECK-NEXT:      %[[EXTENDED:.*]] = arith.extsi %[[DOUBLED]] : i32 to i64
// CHECK-NEXT:      list.yield %[[EXTENDED]] : i64
// CHECK-NEXT:    }
// CHECK-NEXT:    return %[[MAPPED]] : !list.list<i64>
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

// Merging is applied repeatedly: a chain of three maps becomes a single one.
// The two identity maps leave nothing behind in its body.

// CHECK-LABEL: @merge_three_maps(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>
// CHECK:         %[[MAPPED:.*]] = list.map %[[LI]] with (%[[ELEM:.*]]: i32) -> i32 {
// CHECK-NEXT:      %[[SQUARED:.*]] = arith.muli %[[ELEM]], %[[ELEM]] : i32
// CHECK-NEXT:      list.yield %[[SQUARED]] : i32
// CHECK-NEXT:    }
// CHECK-NEXT:    return %[[MAPPED]] : !list.list<i32>
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

// A producer with other users stays where it is: merging clones its body into
// the consumer, so the producer would be evaluated a second time. Trading
// operations for work is a decision for a pass, not for a canonicalization.

// CHECK-LABEL: @producer_has_other_users(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>
// CHECK:         %[[DOUBLED:.*]] = list.map %[[LI]] with (%{{.*}}: i32) -> i32 {
// CHECK:           arith.addi
// CHECK:         }
// CHECK:         %[[COPY:.*]] = list.map %[[DOUBLED]] with (%[[ELEM:.*]]: i32) -> i32 {
// CHECK-NEXT:      list.yield %[[ELEM]] : i32
// CHECK-NEXT:    }
// CHECK-NEXT:    return %[[DOUBLED]], %[[COPY]]
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

// A producer with side effects is not merged either: its effects would move to
// where the consumer is, past everything that happens in between.

// CHECK-LABEL: @merge_keeps_side_effects(
// CHECK-SAME:      %[[LI:[^:]*]]: !list.list<i32>, %[[OTHER:[^:]*]]: !list.list<i32>
// CHECK:         %[[PRINTED:.*]] = list.map %[[LI]] with (%[[ELEM:.*]]: i32) -> i32 {
// CHECK-NEXT:      list.print %[[OTHER]] : !list.list<i32>
// CHECK-NEXT:      list.yield %[[ELEM]] : i32
// CHECK-NEXT:    }
// CHECK:         %[[DOUBLED:.*]] = list.map %[[PRINTED]] with (%{{.*}}: i32) -> i32 {
// CHECK:           arith.addi
// CHECK:         }
// CHECK:         return %[[DOUBLED]] : !list.list<i32>
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
