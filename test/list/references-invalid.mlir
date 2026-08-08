// RUN: tutorial-opt --verify-diagnostics --split-input-file %s

// expected-error @+1 {{}}
func.func @invalid_reference_element(%ref: !list.ref<f32>)

// -----

func.func @store_type_mismatch(%ref: !list.ref<i32>, %value: i64) {
  // expected-error @+1 {{}}
  "list.store"(%value, %ref) : (i64, !list.ref<i32>) -> ()
  return
}

// -----

func.func @load_type_mismatch(%ref: !list.ref<i32>) {
  // expected-error @+1 {{}}
  %value = "list.load"(%ref) : (!list.ref<i32>) -> i64
  return
}
