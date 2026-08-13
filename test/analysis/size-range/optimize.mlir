// RUN: tutorial-opt --optimize-list-size-ranges %s | FileCheck %s

// Both control-flow paths produce an empty list, but in structurally different
// ways. In the first path, the analysis must track the dependent size changes
// through push_front, concat, and pop_front. It then joins that path with a
// directly empty path and propagates the exact zero through another concat.
// The optimizer can replace the whole computation with list.empty.

// CHECK-LABEL: func.func @optimize_empty_control_flow
// CHECK-NOT: scf.if
// CHECK-NOT: list.concat
// CHECK: %[[EMPTY:.*]] = list.empty : !list.list<i32>
// CHECK: return %[[EMPTY]] : !list.list<i32>
func.func @optimize_empty_control_flow(
    %condition: i1, %value: i32
) -> !list.list<i32> {
  %joined = scf.if %condition -> (!list.list<i32>) {
    %head = list.empty : !list.list<i32>
    %one = list.push_front %head, %value : !list.list<i32>
    %tail = list.empty : !list.list<i32>
    %combined = list.concat %one, %tail : !list.list<i32>

    // %combined has exactly one element, so this pop_front is safe.
    %popped = list.pop_front %combined : !list.list<i32>
    scf.yield %popped : !list.list<i32>
  } else {
    %empty = list.empty : !list.list<i32>
    scf.yield %empty : !list.list<i32>
  }

  %tail = list.empty : !list.list<i32>
  %result = list.concat %joined, %tail : !list.list<i32>
  return %result : !list.list<i32>
}
