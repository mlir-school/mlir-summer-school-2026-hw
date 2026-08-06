// RUN: tutorial-opt %s --verify-roundtrip | FileCheck %s

// CHECK-LABEL: @types
// CHECK-SAME: (%{{.*}}: !list.list<i1>, %{{.*}}: !list.list<i32>, %{{.*}}: !list.list<si8>)
func.func @types(%arg0: !list.list<i1>, %arg1: !list.list<i32>,
                 %arg2: !list.list<si8>) {
  return
}

// CHECK-LABEL: @range
// CHECK-SAME: %[[LB:.*]]: i32, %[[UB:.*]]: i32
func.func @range(%lb: i32, %ub: i32) -> !list.list<i32> {
  // CHECK: list.range %[[LB]] to %[[UB]] : !list.list<i32>
  %li = list.range %lb to %ub : !list.list<i32>
  return %li : !list.list<i32>
}

// CHECK-LABEL: @length
// CHECK-SAME: %[[LI:.*]]: !list.list<i32>
func.func @length(%li: !list.list<i32>) -> i32 {
  // CHECK: list.length %[[LI]] : !list.list<i32> -> i32
  %len = list.length %li : !list.list<i32> -> i32
  return %len : i32
}

// CHECK-LABEL: @push_peek_pop
// CHECK-SAME: %[[LI:[^:]*]]: !list.list<i32>, %[[ITEM:[^:]*]]: i32
func.func @push_peek_pop(%li: !list.list<i32>, %item: i32)
    -> (!list.list<i32>, i32) {
  // CHECK: %[[LONGER:.*]] = list.push_back %[[LI]], %[[ITEM]] : !list.list<i32>
  %longer = list.push_back %li, %item : !list.list<i32>
  // CHECK: %[[EVEN_LONGER:.*]] = list.push_front %[[LONGER]], %[[ITEM]] : !list.list<i32>
  %even_longer = list.push_front %longer, %item : !list.list<i32>
  // CHECK: %[[FRONT:.*]] = list.peek_front %[[EVEN_LONGER]] : !list.list<i32> -> i32
  %front = list.peek_front %even_longer : !list.list<i32> -> i32
  // CHECK: %[[SHORTER:.*]] = list.pop_front %[[EVEN_LONGER]] : !list.list<i32>
  %shorter = list.pop_front %even_longer : !list.list<i32>
  return %shorter, %front : !list.list<i32>, i32
}

// CHECK-LABEL: @is_empty
// CHECK-SAME: %[[LI:.*]]: !list.list<i32>
func.func @is_empty(%li: !list.list<i32>) -> i1 {
  // CHECK: list.is_empty %[[LI]] : !list.list<i32> -> i1
  %is_empty = list.is_empty %li : !list.list<i32> -> i1
  return %is_empty : i1
}

// CHECK-LABEL: @reverse
// CHECK-SAME: %[[LI:.*]]: !list.list<i32>
func.func @reverse(%li: !list.list<i32>) -> !list.list<i32> {
  // CHECK: list.reverse %[[LI]] : !list.list<i32>
  %reversed = list.reverse %li : !list.list<i32>
  return %reversed : !list.list<i32>
}

// CHECK-LABEL: @elements
// CHECK-SAME: %[[A:.*]]: i32, %[[B:.*]]: i32, %[[C:.*]]: i32
func.func @elements(%a: i32, %b: i32, %c: i32) -> (i32, i32, i32) {
  // CHECK: %[[LI:.*]] = list.from_elements %[[A]], %[[B]], %[[C]] : (i32, i32, i32) -> !list.list<i32>
  %li = list.from_elements %a, %b, %c : (i32, i32, i32) -> !list.list<i32>
  // CHECK: %[[ELEMS:.*]]:3 = list.get_elements %[[LI]] : (!list.list<i32>) -> (i32, i32, i32)
  %0, %1, %2 = list.get_elements %li : (!list.list<i32>) -> (i32, i32, i32)
  return %0, %1, %2 : i32, i32, i32
}

// CHECK-LABEL: @empty
func.func @empty() -> !list.list<i32> {
  // CHECK: %[[LI:.*]] = list.empty : !list.list<i32>
  %li = list.empty : !list.list<i32>
  return %li : !list.list<i32>
}

// CHECK-LABEL: @constant
func.func @constant() -> (!list.list<i32>, !list.list<i64>) {
  // CHECK: %[[LI:.*]] = list.constant #list.list<[1, -2, 3]> : !list.list<i32>
  %li = list.constant #list.list<[1, -2, 3]> : !list.list<i32>
  // CHECK: %[[EMPTY:.*]] = list.constant #list.list<[]> : !list.list<i64>
  %empty = list.constant #list.list<[]> : !list.list<i64>
  return %li, %empty : !list.list<i32>, !list.list<i64>
}

// CHECK-LABEL: @no_elements
func.func @no_elements() -> !list.list<i64> {
  // CHECK: %[[LI:.*]] = list.from_elements : () -> !list.list<i64>
  %li = list.from_elements : () -> !list.list<i64>
  // CHECK: list.get_elements %[[LI]] : (!list.list<i64>) -> ()
  list.get_elements %li : (!list.list<i64>) -> ()
  return %li : !list.list<i64>
}

// CHECK-LABEL: @print
// CHECK-SAME: %[[LI:.*]]: !list.list<i1>
func.func @print(%li: !list.list<i1>) {
  // CHECK: list.print %[[LI]] : !list.list<i1>
  list.print %li : !list.list<i1>
  return
}

// CHECK-LABEL: @map
// CHECK-SAME: %[[LI:.*]]: !list.list<i32>
func.func @map(%li: !list.list<i32>) -> !list.list<i64> {
  // CHECK:      list.map %[[LI]] with (%[[ELEM:.*]]: i32) -> i64 {
  // CHECK-NEXT:   %[[EXT:.*]] = arith.extsi %[[ELEM]] : i32 to i64
  // CHECK-NEXT:   list.yield %[[EXT]] : i64
  // CHECK-NEXT: }
  %mapped = list.map %li with (%elem : i32) -> i64 {
    %ext = arith.extsi %elem : i32 to i64
    list.yield %ext : i64
  }
  return %mapped : !list.list<i64>
}

// CHECK-LABEL: @map_same_element_type
// CHECK-SAME: %[[LI:.*]]: !list.list<i32>
func.func @map_same_element_type(%li: !list.list<i32>) -> !list.list<i32> {
  // CHECK:      list.map %[[LI]] with (%[[ELEM:.*]]: i32) -> i32 {
  // CHECK-NEXT:   list.yield %[[ELEM]] : i32
  // CHECK-NEXT: }
  %mapped = list.map %li with (%elem : i32) -> i32 {
    list.yield %elem : i32
  }
  return %mapped : !list.list<i32>
}

// CHECK-LABEL: @map_nested
// CHECK-SAME: %[[LI:.*]]: !list.list<i32>
func.func @map_nested(%li: !list.list<i32>) -> !list.list<i32> {
  // CHECK:      list.map %[[LI]] with (%[[OUTER:.*]]: i32) -> i32 {
  // CHECK-NEXT:   %[[INNER_LIST:.*]] = list.map %[[LI]] with (%[[INNER:.*]]: i32) -> i32 {
  // CHECK-NEXT:     list.yield %[[INNER]] : i32
  // CHECK-NEXT:   }
  // CHECK-NEXT:   %[[LEN:.*]] = list.length %[[INNER_LIST]] : !list.list<i32> -> i32
  // CHECK-NEXT:   list.yield %[[LEN]] : i32
  // CHECK-NEXT: }
  %mapped = list.map %li with (%outer : i32) -> i32 {
    %inner_list = list.map %li with (%inner : i32) -> i32 {
      list.yield %inner : i32
    }
    %len = list.length %inner_list : !list.list<i32> -> i32
    list.yield %len : i32
  }
  return %mapped : !list.list<i32>
}

// CHECK-LABEL: @attributes
// CHECK-SAME: %[[LI:[^:]*]]: !list.list<i32>
func.func @attributes(%li: !list.list<i32>, %lb: i32, %ub: i32) {
  // CHECK: list.range %{{.*}} to %{{.*}} {tag = "range"} : !list.list<i32>
  %range = list.range %lb to %ub {tag = "range"} : !list.list<i32>
  // CHECK: list.length %[[LI]] {tag = "length"} : !list.list<i32> -> i32
  %len = list.length %li {tag = "length"} : !list.list<i32> -> i32
  // CHECK: list.print %[[LI]] {tag = "print"} : !list.list<i32>
  list.print %li {tag = "print"} : !list.list<i32>
  // CHECK:      list.map %[[LI]] with (%[[ELEM:.*]]: i32) -> i32 {
  // CHECK-NEXT:   list.yield %[[ELEM]] {tag = "yield"} : i32
  // CHECK-NEXT: } {tag = "map"}
  %mapped = list.map %li with (%elem : i32) -> i32 {
    list.yield %elem {tag = "yield"} : i32
  } {tag = "map"}
  return
}
