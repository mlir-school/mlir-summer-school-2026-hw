// RUN: tutorial-opt --split-input-file %s | FileCheck %s

func.func @integer_reference(%first: i32, %second: i32) -> (i32, i32) {
  %ref = list.alloca : !list.ref<i32>
  list.store %first, %ref : !list.ref<i32>
  %old = list.load %ref : !list.ref<i32>
  list.store %second, %ref : !list.ref<i32>
  %new = list.load %ref : !list.ref<i32>
  return %old, %new : i32, i32
}

// CHECK-LABEL: func.func @integer_reference
// CHECK: %[[REF:.*]] = list.alloca : !list.ref<i32>
// CHECK: list.store %{{.*}}, %[[REF]] : !list.ref<i32>
// CHECK: %[[OLD:.*]] = list.load %[[REF]] : !list.ref<i32>
// CHECK: list.store %{{.*}}, %[[REF]] : !list.ref<i32>
// CHECK: %[[NEW:.*]] = list.load %[[REF]] : !list.ref<i32>
// CHECK: return %[[OLD]], %[[NEW]] : i32, i32

// -----

func.func @list_reference(%value: !list.list<i1>) -> !list.list<i1> {
  %ref = list.alloca : !list.ref<!list.list<i1>>
  list.store %value, %ref : !list.ref<!list.list<i1>>
  %loaded = list.load %ref : !list.ref<!list.list<i1>>
  return %loaded : !list.list<i1>
}

// CHECK-LABEL: func.func @list_reference
// CHECK: %[[REF:.*]] = list.alloca : !list.ref<!list.list<i1>>
// CHECK: list.store %{{.*}}, %[[REF]] : !list.ref<!list.list<i1>>
// CHECK: %[[LOADED:.*]] = list.load %[[REF]] : !list.ref<!list.list<i1>>
// CHECK: return %[[LOADED]] : !list.list<i1>
