// RUN: mlir-opt %s --one-shot-bufferize="bufferize-function-boundaries" \
// RUN:   --convert-linalg-to-parallel-loops | FileCheck %s

//===----------------------------------------------------------------------===//
// EXERCISE 2b - four dimensions, and one operand is not indexed the way you
// might expect
//
// Same task as 2a: predict the loop nest and write it as CHECK lines.
//
// Read %B's indexing map carefully before you write anything down. This is the
// shape you meet in practice as a fully connected layer, and the operand order
// is the part people get wrong.
//
// This time you also have to decide how many loops of each kind there are, so
// the scf lines have ??? in them too.
//===----------------------------------------------------------------------===//

#A = affine_map<(b, m, n, k) -> (b, m, k)>
#B = affine_map<(b, m, n, k) -> (n, k)>
#C = affine_map<(b, m, n, k) -> (b, m, n)>

func.func @linear(%A: tensor<?x?x?xf32>, %B: tensor<?x?xf32>,
                  %C: tensor<?x?x?xf32>) -> tensor<?x?x?xf32> {
  %result = linalg.generic {
    indexing_maps = [#A, #B, #C],
    iterator_types = ["parallel", "parallel", "parallel", "reduction"]
  } ins(%A, %B : tensor<?x?x?xf32>, tensor<?x?xf32>)
    outs(%C : tensor<?x?x?xf32>) {
  ^bb0(%a: f32, %b: f32, %acc: f32):
    %product = arith.mulf %a, %b : f32
    %sum = arith.addf %acc, %product : f32
    linalg.yield %sum : f32
  } -> tensor<?x?x?xf32>
  return %result : tensor<?x?x?xf32>
}

// CHECK-LABEL: func.func @linear
// CHECK:         scf.parallel (%[[B:[a-zA-Z0-9_]+]], %[[M:[a-zA-Z0-9_]+]], %[[N:[a-zA-Z0-9_]+]]) =
// CHECK:           scf.for %[[K:[a-zA-Z0-9_]+]] =
// CHECK:             memref.load %{{.*}}[%[[B]], %[[M]], %[[K]]]
// CHECK:             memref.load %{{.*}}[%[[N]], %[[K]]]
// CHECK:             memref.load %{{.*}}[%[[B]], %[[M]], %[[N]]]
// CHECK:             arith.mulf
// CHECK:             arith.addf
// CHECK:             memref.store %{{.*}}, %{{.*}}[%[[B]], %[[M]], %[[N]]]

//   for b, m, n in parallel:
//     for k:                                  // reduction
//       C[b, m, n] += A[b, m, k] * B[n, k]
//
// Note B[n, k], not B[k, n]: the weight matrix is indexed with the reduction
// dimension last, which is the transposed layout a fully connected layer uses.
