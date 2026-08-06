// RUN: tutorial-opt --print-list-integer-range-analysis %s | FileCheck %s
// RUN: tutorial-opt --optimize-list-integer-ranges %s | FileCheck %s --check-prefix=OPT

// CHECK-LABEL: func.func @loop_stack
// CHECK: %{{.*}} = arith.cmpi ult, %{{.*}}, %{{.*}} {list.integer_ranges = {result0 = "signed : [-1, -1]"}} : i32

// OPT-LABEL: func.func @loop_stack
// OPT: %[[TRUE:.*]] = arith.constant true
// OPT-NOT: arith.cmpi
// OPT: return %[[TRUE]],

func.func @loop_stack() -> (i1, i32, !list.list<i32>) {
  %c0 = arith.constant 0 : i32
  %c1 = arith.constant 1 : i32
  %c10 = arith.constant 10 : i32

  %init = list.from_elements %c0 : (i32) -> !list.list<i32>
  %list = scf.for %i = %c0 to %c10 step %c1
      iter_args(%current = %init) -> !list.list<i32> : i32 {
    %new_list = list.push_front %current, %i : !list.list<i32>
    scf.yield %new_list : !list.list<i32>
  }

  %rest = list.pop_front %list : !list.list<i32>
  %next = list.peek_front %rest : !list.list<i32> -> i32
  %check = arith.cmpi ult, %next, %c10 : i32
  return %check, %next, %rest : i1, i32, !list.list<i32>
}
