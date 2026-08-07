// RUN: tutorial-opt %s \
// RUN:   --transform-preload-library=transform-library-paths=%p/schedule.mlir \
// RUN:   --transform-interpreter --canonicalize --cse | FileCheck %s

// Payload for exercise 4: a matmul followed by an elementwise add, exactly the
// two-operation shape you built in exercise 1b. The attributes are only there
// to give the schedule something stable to match on.

func.func @matmul_add(%A: tensor<?x?xf32>, %B: tensor<?x?xf32>,
                      %C: tensor<?x?xf32>) -> tensor<?x?xf32> {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %zero = arith.constant 0.0 : f32

  %m = tensor.dim %A, %c0 : tensor<?x?xf32>
  %n = tensor.dim %B, %c1 : tensor<?x?xf32>

  %acc = tensor.empty(%m, %n) : tensor<?x?xf32>
  %filled = linalg.fill {__producer__} ins(%zero : f32)
      outs(%acc : tensor<?x?xf32>) -> tensor<?x?xf32>
  %mm = linalg.matmul {__producer__}
      ins(%A, %B : tensor<?x?xf32>, tensor<?x?xf32>)
      outs(%filled : tensor<?x?xf32>) -> tensor<?x?xf32>

  %out = tensor.empty(%m, %n) : tensor<?x?xf32>
  %d = linalg.add {__root__} ins(%mm, %C : tensor<?x?xf32>, tensor<?x?xf32>)
      outs(%out : tensor<?x?xf32>) -> tensor<?x?xf32>

  return %d : tensor<?x?xf32>
}

// The tile sizes are pinned, so this checks the schedule and not just that
// some loops appeared: an [8, 16] nest, both producers fused inside it, and a
// second [4, 4] nest around the root.

// CHECK-LABEL: func.func @matmul_add
// CHECK-DAG:     %[[C4:.*]] = arith.constant 4 : index
// CHECK-DAG:     %[[C8:.*]] = arith.constant 8 : index
// CHECK-DAG:     %[[C16:.*]] = arith.constant 16 : index
// CHECK:         scf.for {{.*}} step %[[C8]]
// CHECK:           scf.for {{.*}} step %[[C16]]
// CHECK:             linalg.fill
// CHECK:             linalg.matmul
// CHECK:             scf.for {{.*}} step %[[C4]]
// CHECK:               scf.for {{.*}} step %[[C4]]
// CHECK:                 linalg.add
