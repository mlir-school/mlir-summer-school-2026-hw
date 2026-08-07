// RUN: mlir-opt %s --one-shot-bufferize="bufferize-function-boundaries" \
// RUN:   --convert-linalg-to-parallel-loops | FileCheck %s

//===----------------------------------------------------------------------===//
// EXERCISE 2a - read a generic
//
// Exercise 1 went from algorithm to linalg. This one goes the other way: work
// out what loop nest the generic below describes, and write that prediction
// down as CHECK lines. FileCheck then tells you whether you were right.
//
// Lowering to *parallel* loops makes the iterator types visible:
//   "parallel"  iterators become one combined scf.parallel
//   "reduction" iterators become an scf.for inside it
//
// Fill in every ??? at the bottom. Use these capture names:
//   %[[I]]  first parallel iterator
//   %[[J]]  second parallel iterator
//   %[[K]]  the reduction iterator
//===----------------------------------------------------------------------===//

#A = affine_map<(i, j, k) -> (i, k)>
#B = affine_map<(i, j, k) -> (k, j)>
#C = affine_map<(i, j, k) -> (i, j)>

func.func @matmul(%A: tensor<?x?xf32>, %B: tensor<?x?xf32>,
                  %C: tensor<?x?xf32>) -> tensor<?x?xf32> {
  %0 = linalg.generic {
    indexing_maps = [#A, #B, #C],
    iterator_types = ["parallel", "parallel", "reduction"]
  } ins(%A, %B : tensor<?x?xf32>, tensor<?x?xf32>)
    outs(%C : tensor<?x?xf32>) {
  ^bb0(%a: f32, %b: f32, %acc: f32):
    %product = arith.mulf %a, %b : f32
    %sum = arith.addf %acc, %product : f32
    linalg.yield %sum : f32
  } -> tensor<?x?xf32>
  return %0 : tensor<?x?xf32>
}

// CHECK-LABEL: func.func @matmul
// CHECK:         scf.parallel (%[[I:[a-zA-Z0-9_]+]], %[[J:[a-zA-Z0-9_]+]]) =
// CHECK:           scf.for %[[K:[a-zA-Z0-9_]+]] =
// CHECK:             memref.load %{{.*}}[%[[I]], %[[K]]]
// CHECK:             memref.load %{{.*}}[%[[K]], %[[J]]]
// CHECK:             memref.load %{{.*}}[%[[I]], %[[J]]]
// CHECK:             arith.mulf
// CHECK:             arith.addf
// CHECK:             memref.store %{{.*}}, %{{.*}}[%[[I]], %[[J]]]

//   for i, j in parallel:
//     for k:                       // reduction
//       C[i, j] += A[i, k] * B[k, j]
