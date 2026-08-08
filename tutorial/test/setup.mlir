// RUN: tutorial-opt %s | FileCheck %s

func.func @setup_works() -> i32 {
  %value = tutorial.constant 42 : i32
  return %value : i32
}

// CHECK-LABEL: func.func @setup_works
// CHECK: %[[VALUE:.*]] = tutorial.constant 42 : i32
// CHECK: return %[[VALUE]] : i32
