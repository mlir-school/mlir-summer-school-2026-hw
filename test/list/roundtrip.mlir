// RUN: tutorial-opt --split-input-file %s | FileCheck %s

func.func @empty() -> !list.list<i32> {
  %0 = list.empty : !list.list<i32>
  return %0 : !list.list<i32>
}

// CHECK-LABEL: func.func @empty
// CHECK: %[[LIST:.*]] = list.empty : !list.list<i32>
// CHECK: return %[[LIST]] : !list.list<i32>

// -----

func.func @push_back(%item: i32) -> !list.list<i32> {
  %empty = list.empty : !list.list<i32>
  %list = list.push_back %empty, %item : !list.list<i32>
  return %list : !list.list<i32>
}

// CHECK-LABEL: func.func @push_back
// CHECK: %[[EMPTY:.*]] = list.empty : !list.list<i32>
// CHECK: %[[LIST:.*]] = list.push_back %[[EMPTY]], %{{.*}} : !list.list<i32>
// CHECK: return %[[LIST]] : !list.list<i32>

// -----

func.func @length(%list: !list.list<i32>) -> i32 {
  %length = list.length %list : !list.list<i32> -> i32
  return %length : i32
}

// CHECK-LABEL: func.func @length
// CHECK: %[[LENGTH:.*]] = list.length %{{.*}} : !list.list<i32> -> i32
// CHECK: return %[[LENGTH]] : i32

// -----

func.func @range(%lb: i32, %ub: i32) -> !list.list<i32> {
  %list = list.range %lb to %ub : !list.list<i32>
  return %list : !list.list<i32>
}

// CHECK-LABEL: func.func @range
// CHECK: %[[LIST:.*]] = list.range %{{.*}} to %{{.*}} : !list.list<i32>
// CHECK: return %[[LIST]] : !list.list<i32>

// -----

func.func @is_empty(%list: !list.list<i32>) -> i1 {
  %is_empty = list.is_empty %list : !list.list<i32> -> i1
  return %is_empty : i1
}

// CHECK-LABEL: func.func @is_empty
// CHECK: %[[IS_EMPTY:.*]] = list.is_empty %{{.*}} : !list.list<i32> -> i1
// CHECK: return %[[IS_EMPTY]] : i1

// -----

func.func @reverse(%list: !list.list<i32>) -> !list.list<i32> {
  %reversed = list.reverse %list : !list.list<i32>
  return %reversed : !list.list<i32>
}

// CHECK-LABEL: func.func @reverse
// CHECK: %[[REVERSED:.*]] = list.reverse %{{.*}} : !list.list<i32>
// CHECK: return %[[REVERSED]] : !list.list<i32>

// -----

func.func @push_front(%list: !list.list<i32>, %item: i32) -> !list.list<i32> {
  %longer = list.push_front %list, %item : !list.list<i32>
  return %longer : !list.list<i32>
}

// CHECK-LABEL: func.func @push_front
// CHECK: %[[LONGER:.*]] = list.push_front %{{.*}}, %{{.*}} : !list.list<i32>
// CHECK: return %[[LONGER]] : !list.list<i32>

// -----

func.func @peek_front(%list: !list.list<i32>) -> i32 {
  %item = list.peek_front %list : !list.list<i32> -> i32
  return %item : i32
}

// CHECK-LABEL: func.func @peek_front
// CHECK: %[[ITEM:.*]] = list.peek_front %{{.*}} : !list.list<i32> -> i32
// CHECK: return %[[ITEM]] : i32

// -----

func.func @pop_front(%list: !list.list<i32>) -> !list.list<i32> {
  %shorter = list.pop_front %list : !list.list<i32>
  return %shorter : !list.list<i32>
}

// CHECK-LABEL: func.func @pop_front
// CHECK: %[[SHORTER:.*]] = list.pop_front %{{.*}} : !list.list<i32>
// CHECK: return %[[SHORTER]] : !list.list<i32>

// -----

func.func @print(%list: !list.list<i32>) {
  list.print %list : !list.list<i32>
  return
}

// CHECK-LABEL: func.func @print
// CHECK: list.print %{{.*}} : !list.list<i32>

// -----

func.func @elements(%a: i32, %b: i32, %c: i32) -> (i32, i32, i32) {
  %list = list.from_elements %a, %b, %c : (i32, i32, i32) -> !list.list<i32>
  %0, %1, %2 = list.get_elements %list : (!list.list<i32>) -> (i32, i32, i32)
  return %0, %1, %2 : i32, i32, i32
}

// CHECK-LABEL: func.func @elements
// CHECK: %[[LIST:.*]] = list.from_elements %{{.*}}, %{{.*}}, %{{.*}} : (i32, i32, i32) -> !list.list<i32>
// CHECK: %[[ELEMENTS:.*]]:3 = list.get_elements %[[LIST]] : (!list.list<i32>) -> (i32, i32, i32)
// CHECK: return %[[ELEMENTS]]#0, %[[ELEMENTS]]#1, %[[ELEMENTS]]#2 : i32, i32, i32

// -----

func.func @no_elements() -> !list.list<i64> {
  %list = list.from_elements : () -> !list.list<i64>
  list.get_elements %list : (!list.list<i64>) -> ()
  return %list : !list.list<i64>
}

// CHECK-LABEL: func.func @no_elements
// CHECK: %[[LIST:.*]] = list.from_elements : () -> !list.list<i64>
// CHECK: list.get_elements %[[LIST]] : (!list.list<i64>) -> ()
// CHECK: return %[[LIST]] : !list.list<i64>

// -----

func.func @map(%list: !list.list<i32>) -> !list.list<i64> {
  %mapped = list.map %list with (%elem : i32) -> i64 {
    %ext = arith.extsi %elem : i32 to i64
    list.yield %ext : i64
  }
  return %mapped : !list.list<i64>
}

// CHECK-LABEL: func.func @map
// CHECK:      %[[MAPPED:.*]] = list.map %{{.*}} with (%[[ELEM:.*]]: i32) -> i64 {
// CHECK-NEXT:   %[[EXT:.*]] = arith.extsi %[[ELEM]] : i32 to i64
// CHECK-NEXT:   list.yield %[[EXT]] : i64
// CHECK-NEXT: }
// CHECK: return %[[MAPPED]] : !list.list<i64>

// -----

func.func @fold_one_iter_arg(%input: !list.list<i32>, %initial: i32) -> i32 {
  %sum = list.fold %input with (%element : i32)
      iter_args(%acc = %initial) -> (i32) {
    %next = arith.addi %element, %acc : i32
    list.yield %next : i32
  }
  return %sum : i32
}

// CHECK-LABEL: func.func @fold_one_iter_arg
// CHECK:      %[[RESULT:.*]] = list.fold %{{.*}} with (%[[ELEMENT:.*]]: i32) iter_args(%[[ACC:.*]] = %{{.*}}) -> (i32) {
// CHECK-NEXT:   %[[NEXT:.*]] = arith.addi %[[ELEMENT]], %[[ACC]] : i32
// CHECK-NEXT:   list.yield %[[NEXT]] : i32
// CHECK-NEXT: }
// CHECK: return %[[RESULT]] : i32

// -----

func.func @fold(%input: !list.list<i32>, %zero: i32,
                %empty: !list.list<i32>) -> (i32, !list.list<i32>) {
  %sum, %copy = list.fold %input with (%element : i32)
      iter_args(%acc = %zero, %items = %empty)
      -> (i32, !list.list<i32>) {
    %next_sum = arith.addi %element, %acc : i32
    %next_list = list.push_back %items, %element : !list.list<i32>
    list.yield %next_sum, %next_list : i32, !list.list<i32>
  }
  return %sum, %copy : i32, !list.list<i32>
}

// CHECK-LABEL: func.func @fold
// CHECK:      %[[RESULTS:.*]]:2 = list.fold %{{.*}} with (%[[ELEMENT:.*]]: i32) iter_args(%[[ACC:.*]] = %{{.*}}, %[[ITEMS:.*]] = %{{.*}}) -> (i32, !list.list<i32>) {
// CHECK-NEXT:   %[[NEXT_SUM:.*]] = arith.addi %[[ELEMENT]], %[[ACC]] : i32
// CHECK-NEXT:   %[[NEXT_LIST:.*]] = list.push_back %[[ITEMS]], %[[ELEMENT]] : !list.list<i32>
// CHECK-NEXT:   list.yield %[[NEXT_SUM]], %[[NEXT_LIST]] : i32, !list.list<i32>
// CHECK-NEXT: }
// CHECK: return %[[RESULTS]]#0, %[[RESULTS]]#1 : i32, !list.list<i32>

// -----

func.func @fold_no_iter_args(%input: !list.list<i32>) {
  list.fold %input with (%element : i32) {
    list.yield
  }
  return
}

// CHECK-LABEL: func.func @fold_no_iter_args
// CHECK:      list.fold %{{.*}} with (%{{.*}}: i32) {
// CHECK-NEXT:   list.yield
// CHECK-NEXT: }
// CHECK: return

// -----

func.func @map_nested(%list: !list.list<i32>) -> !list.list<i32> {
  %mapped = list.map %list with (%outer : i32) -> i32 {
    %inner_list = list.map %list with (%inner : i32) -> i32 {
      list.yield %inner : i32
    }
    %length = list.length %inner_list : !list.list<i32> -> i32
    list.yield %length : i32
  }
  return %mapped : !list.list<i32>
}

// CHECK-LABEL: func.func @map_nested
// CHECK:      %[[MAPPED:.*]] = list.map %{{.*}} with (%[[OUTER:.*]]: i32) -> i32 {
// CHECK-NEXT:   %[[INNER_LIST:.*]] = list.map %{{.*}} with (%[[INNER:.*]]: i32) -> i32 {
// CHECK-NEXT:     list.yield %[[INNER]] : i32
// CHECK-NEXT:   }
// CHECK-NEXT:   %[[LENGTH:.*]] = list.length %[[INNER_LIST]] : !list.list<i32> -> i32
// CHECK-NEXT:   list.yield %[[LENGTH]] : i32
// CHECK-NEXT: }
// CHECK: return %[[MAPPED]] : !list.list<i32>
