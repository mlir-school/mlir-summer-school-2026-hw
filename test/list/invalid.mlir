// RUN: tutorial-opt %s -split-input-file -verify-diagnostics

// expected-error @+2 {{invalid kind of type specified: expected builtin.integer, but found 'f32'}}
// expected-error @+1 {{failed to parse List_ListType parameter 'elementType'}}
func.func @non_integer_element_type(%li: !list.list<f32>) {
  return
}

// -----

func.func @map_body_argument_type_mismatch(%li: !list.list<i32>) {
  // expected-error @below {{expects the body argument type ('i64') to match the element type of the operand list ('i32')}}
  %mapped = "list.map"(%li) ({
  ^bb0(%elem: i64):
    "list.yield"(%elem) : (i64) -> ()
  }) : (!list.list<i32>) -> !list.list<i64>
  return
}

// -----

func.func @map_body_too_many_arguments(%li: !list.list<i32>) {
  // expected-error @below {{expects the body to have exactly one argument}}
  %mapped = "list.map"(%li) ({
  ^bb0(%elem: i32, %extra: i32):
    "list.yield"(%elem) : (i32) -> ()
  }) : (!list.list<i32>) -> !list.list<i32>
  return
}

// -----

func.func @map_yielded_type_mismatch(%li: !list.list<i32>) {
  // expected-error @below {{expects the yielded type ('i32') to match the element type of the result list ('i64')}}
  %mapped = list.map %li with (%elem : i32) -> i64 {
    list.yield %elem : i32
  }
  return
}

// -----

// The terminator is an 'llvm.unreachable' rather than, say, a 'func.return':
// the operations in a region are verified before the enclosing operation, so a
// terminator that is invalid by itself would abort verification before the
// 'SingleBlockImplicitTerminator' trait of 'list.map' gets to complain.
func.func @map_missing_yield(%li: !list.list<i32>) {
  // expected-error @below {{expects regions to end with 'list.yield', found 'llvm.unreachable'}}
  // expected-note @below {{in custom textual format, the absence of terminator implies 'list.yield'}}
  %mapped = "list.map"(%li) ({
  ^bb0(%elem: i32):
    "llvm.unreachable"() : () -> ()
  }) : (!list.list<i32>) -> !list.list<i32>
  return
}

// -----

func.func @map_non_integer_body_argument(%li: !list.list<i32>) {
  // expected-error @below {{expected the body argument to have an integer type}}
  %mapped = list.map %li with (%elem : f32) -> i32 {
    list.yield %elem : f32
  }
  return
}

// -----

func.func @map_non_integer_result_element_type(%li: !list.list<i32>) {
  // expected-error @below {{expected an integer result element type}}
  %mapped = list.map %li with (%elem : i32) -> f32 {
    list.yield %elem : i32
  }
  return
}

// -----

func.func @push_back_item_type_mismatch(%li: !list.list<i32>, %item: i64) {
  // expected-error @below {{failed to verify that type of 'item' matches the element type of 'input'}}
  %longer = "list.push_back"(%li, %item) : (!list.list<i32>, i64)
      -> !list.list<i32>
  return
}

// -----

func.func @peek_front_item_type_mismatch(%li: !list.list<i32>) {
  // expected-error @below {{failed to verify that type of 'item' matches the element type of 'input'}}
  %front = "list.peek_front"(%li) : (!list.list<i32>) -> i64
  return
}

// -----

func.func @pop_front_result_type_mismatch(%li: !list.list<i32>) {
  // expected-error @below {{failed to verify that all of {input, result} have same type}}
  %shorter = "list.pop_front"(%li) : (!list.list<i32>) -> !list.list<i64>
  return
}

// -----

func.func @from_elements_type_mismatch(%a: i32, %b: i64) {
  // expected-error @below {{failed to verify that types of 'elements' match the element type of 'result'}}
  %li = "list.from_elements"(%a, %b) : (i32, i64) -> !list.list<i32>
  return
}

// -----

func.func @get_elements_type_mismatch(%li: !list.list<i32>) {
  // expected-error @below {{failed to verify that types of 'elements' match the element type of 'input'}}
  %elements:2 = "list.get_elements"(%li) : (!list.list<i32>) -> (i32, i64)
  return
}

// -----

func.func @yield_outside_of_map(%value: i32) {
  // expected-error @below {{'list.yield' op expects parent op 'list.map'}}
  list.yield %value : i32
}
