// RUN: mlir-opt %s --one-shot-bufferize="bufferize-function-boundaries" \
// RUN:   --convert-linalg-to-parallel-loops | FileCheck %s

//===----------------------------------------------------------------------===//
// EXERCISE 2c - an output map that drops a dimension
//
// The iteration space is two dimensional but the output is a 1-D tensor. The
// output map is what makes that work, and it is also what turns this into a
// reduction: every point of the iteration space that shares an output index
// writes to the same place.
//
// Predict the loop nest and fill in the CHECK lines. Watch the operand order of
// the arith.addf, it follows the block argument order and not the source order.
//===----------------------------------------------------------------------===//

#in  = affine_map<(i, j) -> (i, j)>
#out = affine_map<(i, j) -> (i)>

func.func @row_sum(%in: tensor<?x?xf32>, %out: tensor<?xf32>) -> tensor<?xf32> {
  %0 = linalg.generic {
    indexing_maps = [#in, #out],
    iterator_types = ["parallel", "reduction"]
  } ins(%in : tensor<?x?xf32>)
    outs(%out : tensor<?xf32>) {
  ^bb0(%v: f32, %acc: f32):
    %sum = arith.addf %acc, %v : f32
    linalg.yield %sum : f32
  } -> tensor<?xf32>
  return %0 : tensor<?xf32>
}

// CHECK-LABEL: func.func @row_sum
// CHECK:         scf.parallel (%[[I:[a-zA-Z0-9_]+]]) =
// CHECK:           scf.for %[[J:[a-zA-Z0-9_]+]] =
// CHECK:             memref.load %{{.*}}[%[[I]], %[[J]]]
// CHECK:             memref.load %{{.*}}[%[[I]]]
// CHECK:             arith.addf
// CHECK:             memref.store %{{.*}}, %{{.*}}[%[[I]]]

//   for i in parallel:
//     for j:                    // reduction, because out drops j
//       out[i] += in[i, j]
