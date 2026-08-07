// RUN: mlir-opt %s --linalg-generalize-named-ops | FileCheck %s

//===----------------------------------------------------------------------===//
// EXERCISE 1d (bonus) - NCHW convolution
//
//   O[n, oc, oh, ow] += I[n, ic, oh + kh, ow + kw] * F[oc, ic, kh, kw]
//
// Use the iteration order (n, oc, oh, ow, ic, kh, kw).
//
// Same computation as 03, different data layout. Only the indexing maps change,
// the body and the iterator types are identical. That is the point of the
// exercise: in linalg, a layout change is a change of maps, not a change of
// algorithm.
//===----------------------------------------------------------------------===//

// Reference implementation. Do not edit.
func.func @reference(%I: tensor<1x4x8x8xf32>, %F: tensor<16x4x3x3xf32>,
                     %O: tensor<1x16x6x6xf32>) -> tensor<1x16x6x6xf32> {
  %0 = linalg.conv_2d_nchw_fchw
      ins(%I, %F : tensor<1x4x8x8xf32>, tensor<16x4x3x3xf32>)
      outs(%O : tensor<1x16x6x6xf32>) -> tensor<1x16x6x6xf32>
  return %0 : tensor<1x16x6x6xf32>
}

// Your version.
func.func @student(%I: tensor<1x4x8x8xf32>, %F: tensor<16x4x3x3xf32>,
                   %O: tensor<1x16x6x6xf32>) -> tensor<1x16x6x6xf32> {
  %0 = linalg.generic {
    indexing_maps = [???],
    iterator_types = [???]
  } ins(??? : tensor<1x4x8x8xf32>, tensor<16x4x3x3xf32>)
    outs(??? : tensor<1x16x6x6xf32>) {
  ^bb0(???):
    ???
  } -> tensor<1x16x6x6xf32>
  return %0 : tensor<1x16x6x6xf32>
}

// CHECK-LABEL: func.func @reference
// CHECK:         linalg.generic
// CHECK-SAME:      indexing_maps = [#[[$IN:[a-zA-Z0-9_]+]], #[[$FLT:[a-zA-Z0-9_]+]], #[[$OUT:[a-zA-Z0-9_]+]]]
// CHECK-SAME:      iterator_types = ["parallel", "parallel", "parallel", "parallel", "reduction", "reduction", "reduction"]

// CHECK-LABEL: func.func @student
// CHECK:         linalg.generic
// CHECK-SAME:      indexing_maps = [#[[$IN]], #[[$FLT]], #[[$OUT]]]
// CHECK-SAME:      iterator_types = ["parallel", "parallel", "parallel", "parallel", "reduction", "reduction", "reduction"]
