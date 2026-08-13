// RUN: tutorial-opt --print-list-size-range-analysis %s | FileCheck %s

// This test is ordered as a progress checklist for the size-range analysis.
// Keep list.concat last: its transfer function is the hardest exercise.

// CHECK-LABEL: func.func @size_range_progress
func.func @size_range_progress(
    %condition: i1, %input: !list.list<i32>, %value: i32
) -> (!list.list<i32>, !list.list<i32>, !list.list<i32>, i32,
      !list.list<i32>) {
  // CHECK: %[[EMPTY:.*]] = list.empty {list.size_range = "[0, 0]"}
  %empty = list.empty : !list.list<i32>

  // A function argument has an unknown, non-negative size.
  // CHECK: %[[ONE_OR_MORE:.*]] = list.push_back %{{.*}}, %{{.*}} {list.size_range = "[1, +inf]"}
  %one_or_more = list.push_back %input, %value : !list.list<i32>

  // CHECK: %[[ONE:.*]] = list.push_back %[[EMPTY]], %{{.*}} {list.size_range = "[1, 1]"}
  %one = list.push_back %empty, %value : !list.list<i32>

  // Joining the zero- and one-element paths produces their interval hull.
  %joined = scf.if %condition -> (!list.list<i32>) {
    scf.yield %empty : !list.list<i32>
  } else {
    scf.yield %one : !list.list<i32>
  }
  // CHECK: {list.size_range = "[0, 1]"}

  // list.length is integer-valued, so the size-range pass does not annotate it.
  // CHECK: %[[LENGTH:.*]] = list.length %[[ONE]] : !list.list<i32> -> i32
  %length = list.length %one : !list.list<i32> -> i32

  // Keep concat at the end of this progress test.
  // CHECK: %[[CONCAT:.*]] = list.concat %[[ONE]], %[[ONE_OR_MORE]] {list.size_range = "[2, +inf]"}
  %concat = list.concat %one, %one_or_more : !list.list<i32>

  // Leave an empty list as the final result.
  return %one_or_more, %joined, %concat, %length, %empty
      : !list.list<i32>, !list.list<i32>, !list.list<i32>, i32,
        !list.list<i32>
}
