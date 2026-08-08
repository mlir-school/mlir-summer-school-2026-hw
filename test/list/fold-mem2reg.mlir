// RUN: tutorial-opt --mem2reg --split-input-file %s | FileCheck %s

func.func @fold_reference(%input: !list.list<i32>, %sum_initial: i32,
                          %ref_initial: i32) -> (i32, i32) {
  %ref = list.alloca : !list.ref<i32>
  list.store %ref_initial, %ref : !list.ref<i32>
  %sum = list.fold %input with (%element : i32)
      iter_args(%acc = %sum_initial) -> (i32) {
    %current = list.load %ref : !list.ref<i32>
    %next_sum = arith.addi %acc, %element : i32
    %next_ref = arith.addi %current, %element : i32
    list.store %next_ref, %ref : !list.ref<i32>
    list.yield %next_sum : i32
  }
  %result = list.load %ref : !list.ref<i32>
  return %sum, %result : i32, i32
}

// CHECK-LABEL: func.func @fold_reference(
// CHECK-SAME:      %[[INPUT:[a-zA-Z0-9_]+]]: !list.list<i32>, %[[SUM_INITIAL:[a-zA-Z0-9_]+]]: i32,
// CHECK-SAME:      %[[REF_INITIAL:[a-zA-Z0-9_]+]]: i32) -> (i32, i32) {
// CHECK-NOT:       list.alloca
// CHECK-NOT:       list.store
// CHECK:           %[[RESULT:[a-zA-Z0-9_]+]]:2 = list.fold %[[INPUT]] with (%[[ELEMENT:[a-zA-Z0-9_]+]]: i32) iter_args(%[[ACC:[a-zA-Z0-9_]+]] = %[[SUM_INITIAL]], %[[CURRENT:[a-zA-Z0-9_]+]] = %[[REF_INITIAL]]) -> (i32, i32) {
// CHECK-NOT:         list.load
// CHECK-NEXT:        %[[NEXT_SUM:[a-zA-Z0-9_]+]] = arith.addi %[[ACC]], %[[ELEMENT]] : i32
// CHECK-NEXT:        %[[NEXT_REF:[a-zA-Z0-9_]+]] = arith.addi %[[CURRENT]], %[[ELEMENT]] : i32
// CHECK-NEXT:        list.yield %[[NEXT_SUM]], %[[NEXT_REF]] : i32, i32
// CHECK-NEXT:      }
// CHECK-NOT:       list.load
// CHECK-NEXT:      return %[[RESULT]]#0, %[[RESULT]]#1 : i32, i32

// -----

func.func @fold_reference_without_accumulator(
    %input: !list.list<i32>, %initial: i32) -> i32 {
  %ref = list.alloca : !list.ref<i32>
  list.store %initial, %ref : !list.ref<i32>
  list.fold %input with (%element : i32) {
    %current = list.load %ref : !list.ref<i32>
    %next = arith.addi %current, %element : i32
    list.store %next, %ref : !list.ref<i32>
    list.yield
  }
  %result = list.load %ref : !list.ref<i32>
  return %result : i32
}

// CHECK-LABEL: func.func @fold_reference_without_accumulator(
// CHECK-SAME:      %[[INPUT:[a-zA-Z0-9_]+]]: !list.list<i32>, %[[INITIAL:[a-zA-Z0-9_]+]]: i32) -> i32 {
// CHECK-NOT:       list.alloca
// CHECK-NOT:       list.store
// CHECK:           %[[RESULT:[a-zA-Z0-9_]+]] = list.fold %[[INPUT]] with (%[[ELEMENT:[a-zA-Z0-9_]+]]: i32) iter_args(%[[CURRENT:[a-zA-Z0-9_]+]] = %[[INITIAL]]) -> (i32) {
// CHECK-NOT:         list.load
// CHECK-NEXT:        %[[NEXT:[a-zA-Z0-9_]+]] = arith.addi %[[CURRENT]], %[[ELEMENT]] : i32
// CHECK-NEXT:        list.yield %[[NEXT]] : i32
// CHECK-NEXT:      }
// CHECK-NOT:       list.load
// CHECK-NEXT:      return %[[RESULT]] : i32
