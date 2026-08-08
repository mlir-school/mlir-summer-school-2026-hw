// RUN: tutorial-opt --verify-diagnostics --split-input-file %s

func.func @wrong_yield_count(%input: !list.list<i32>,
                             %initial: i32) -> i32 {
  // expected-error @+1 {{'list.fold' op expects 1 yielded values, but got 0}}
  %result = list.fold %input with (%element : i32)
      iter_args(%acc = %initial) -> (i32) {
    list.yield
  }
  return %result : i32
}

// -----

func.func @wrong_yield_type(%input: !list.list<i1>,
                            %initial: i32) -> i32 {
  // expected-error @+1 {{'list.fold' op expects yielded value #0 to have type 'i32', but got 'i1'}}
  %result = list.fold %input with (%element : i1)
      iter_args(%acc = %initial) -> (i32) {
    list.yield %element : i1
  }
  return %result : i32
}

// -----

func.func @map_must_yield_one_value(
    %input: !list.list<i32>) -> !list.list<i32> {
  // expected-error @+1 {{'list.map' op expects the body to yield exactly one value}}
  %result = list.map %input with (%element : i32) -> i32 {
    list.yield
  }
  return %result : !list.list<i32>
}
