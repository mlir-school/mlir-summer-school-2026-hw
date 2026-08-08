// RUN: tutorial-opt --mem2reg --split-input-file %s | FileCheck %s

func.func @if_reference(%condition: i1, %initial: i32,
                        %updated: i32) -> i32 {
  %ref = list.alloca : !list.ref<i32>
  list.store %initial, %ref : !list.ref<i32>
  scf.if %condition {
    list.store %updated, %ref : !list.ref<i32>
  }
  %result = list.load %ref : !list.ref<i32>
  return %result : i32
}

// CHECK-LABEL: func.func @if_reference(
// CHECK-SAME:      %[[CONDITION:[a-zA-Z0-9_]+]]: i1,
// CHECK-SAME:      %[[INITIAL:[a-zA-Z0-9_]+]]: i32, %[[UPDATED:[a-zA-Z0-9_]+]]: i32) -> i32 {
// CHECK-NOT:       list.alloca
// CHECK-NOT:       list.store
// CHECK:           %[[RESULT:[a-zA-Z0-9_]+]] = scf.if %[[CONDITION]] -> (i32) {
// CHECK-NEXT:        scf.yield %[[UPDATED]] : i32
// CHECK-NEXT:      } else {
// CHECK-NEXT:        scf.yield %[[INITIAL]] : i32
// CHECK-NEXT:      }
// CHECK-NOT:       list.load
// CHECK-NEXT:      return %[[RESULT]] : i32

// -----

func.func @map_read_reference(%input: !list.list<i32>, %offset: i32)
    -> !list.list<i32> {
  %ref = list.alloca : !list.ref<i32>
  list.store %offset, %ref : !list.ref<i32>
  %mapped = list.map %input with (%element : i32) -> i32 {
    %current = list.load %ref : !list.ref<i32>
    %sum = arith.addi %element, %current : i32
    list.yield %sum : i32
  }
  return %mapped : !list.list<i32>
}

// CHECK-LABEL: func.func @map_read_reference(
// CHECK-SAME:      %[[INPUT:[a-zA-Z0-9_]+]]: !list.list<i32>, %[[OFFSET:[a-zA-Z0-9_]+]]: i32) -> !list.list<i32> {
// CHECK-NOT:       list.alloca
// CHECK-NOT:       list.store
// CHECK:           %[[MAPPED:[a-zA-Z0-9_]+]] = list.map %[[INPUT]] with (%[[ELEMENT:[a-zA-Z0-9_]+]]: i32) -> i32 {
// CHECK-NOT:         list.load
// CHECK-NEXT:        %[[SUM:[a-zA-Z0-9_]+]] = arith.addi %[[ELEMENT]], %[[OFFSET]] : i32
// CHECK-NEXT:        list.yield %[[SUM]] : i32
// CHECK-NEXT:      }
// CHECK-NEXT:      return %[[MAPPED]] : !list.list<i32>

// -----

func.func @map_store_bails(%input: !list.list<i32>, %initial: i32,
                           %updated: i32) -> i32 {
  %ref = list.alloca : !list.ref<i32>
  list.store %initial, %ref : !list.ref<i32>
  %mapped = list.map %input with (%element : i32) -> i32 {
    list.store %updated, %ref : !list.ref<i32>
    list.yield %element : i32
  }
  %result = list.load %ref : !list.ref<i32>
  return %result : i32
}

// CHECK-LABEL: func.func @map_store_bails(
// CHECK-SAME:      %[[INPUT:[a-zA-Z0-9_]+]]: !list.list<i32>, %[[INITIAL:[a-zA-Z0-9_]+]]: i32,
// CHECK-SAME:      %[[UPDATED:[a-zA-Z0-9_]+]]: i32) -> i32 {
// CHECK:           %[[REF:[a-zA-Z0-9_]+]] = list.alloca : !list.ref<i32>
// CHECK-NEXT:      list.store %[[INITIAL]], %[[REF]] : !list.ref<i32>
// CHECK-NEXT:      %{{[a-zA-Z0-9_]+}} = list.map %[[INPUT]] with (%[[ELEMENT:[a-zA-Z0-9_]+]]: i32) -> i32 {
// CHECK-NEXT:        list.store %[[UPDATED]], %[[REF]] : !list.ref<i32>
// CHECK-NEXT:        list.yield %[[ELEMENT]] : i32
// CHECK-NEXT:      }
// CHECK-NEXT:      %[[RESULT:[a-zA-Z0-9_]+]] = list.load %[[REF]] : !list.ref<i32>
// CHECK-NEXT:      return %[[RESULT]] : i32

// -----

func.func @uninitialized_reference() -> i32 {
  %ref = list.alloca : !list.ref<i32>
  %result = list.load %ref : !list.ref<i32>
  return %result : i32
}

// CHECK-LABEL: func.func @uninitialized_reference() -> i32 {
// CHECK-NOT:       list.alloca
// CHECK-NOT:       list.load
// CHECK:           %[[ZERO:[a-zA-Z0-9_]+]] = arith.constant 0 : i32
// CHECK-NEXT:      return %[[ZERO]] : i32

// -----

func.func @uninitialized_list_reference() -> !list.list<i32> {
  %ref = list.alloca : !list.ref<!list.list<i32>>
  %result = list.load %ref : !list.ref<!list.list<i32>>
  return %result : !list.list<i32>
}

// CHECK-LABEL: func.func @uninitialized_list_reference() -> !list.list<i32> {
// CHECK-NOT:       list.alloca
// CHECK-NOT:       list.load
// CHECK:           %[[EMPTY:[a-zA-Z0-9_]+]] = list.empty : !list.list<i32>
// CHECK-NEXT:      return %[[EMPTY]] : !list.list<i32>

// -----

func.func @for_reference(%lower: index, %upper: index, %step: index,
                         %initial: i32) -> i32 {
  %ref = list.alloca : !list.ref<i32>
  list.store %initial, %ref : !list.ref<i32>
  scf.for %iv = %lower to %upper step %step {
    %current = list.load %ref : !list.ref<i32>
    %next = arith.addi %current, %current : i32
    list.store %next, %ref : !list.ref<i32>
  }
  %result = list.load %ref : !list.ref<i32>
  return %result : i32
}

// CHECK-LABEL: func.func @for_reference(
// CHECK-SAME:      %[[LOWER:[a-zA-Z0-9_]+]]: index, %[[UPPER:[a-zA-Z0-9_]+]]: index,
// CHECK-SAME:      %[[STEP:[a-zA-Z0-9_]+]]: index, %[[INITIAL:[a-zA-Z0-9_]+]]: i32) -> i32 {
// CHECK-NOT:       list.alloca
// CHECK-NOT:       list.store
// CHECK:           %[[RESULT:[a-zA-Z0-9_]+]] = scf.for %{{[a-zA-Z0-9_]+}} = %[[LOWER]] to %[[UPPER]] step %[[STEP]] iter_args(%[[CURRENT:[a-zA-Z0-9_]+]] = %[[INITIAL]]) -> (i32) {
// CHECK-NOT:         list.load
// CHECK-NEXT:        %[[NEXT:[a-zA-Z0-9_]+]] = arith.addi %[[CURRENT]], %[[CURRENT]] : i32
// CHECK-NEXT:        scf.yield %[[NEXT]] : i32
// CHECK-NEXT:      }
// CHECK-NOT:       list.load
// CHECK-NEXT:      return %[[RESULT]] : i32
