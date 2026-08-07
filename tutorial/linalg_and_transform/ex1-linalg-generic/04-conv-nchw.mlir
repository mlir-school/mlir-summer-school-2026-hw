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

#in  = affine_map<(n, oc, oh, ow, ic, kh, kw) -> (n, ic, oh + kh, ow + kw)>
#flt = affine_map<(n, oc, oh, ow, ic, kh, kw) -> (oc, ic, kh, kw)>
#out = affine_map<(n, oc, oh, ow, ic, kh, kw) -> (n, oc, oh, ow)>

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
    indexing_maps = [#in, #flt, #out],
    iterator_types = ["parallel", "parallel", "parallel", "parallel",
                      "reduction", "reduction", "reduction"]
  } ins(%I, %F : tensor<1x4x8x8xf32>, tensor<16x4x3x3xf32>)
    outs(%O : tensor<1x16x6x6xf32>) {
  ^bb0(%i: f32, %f: f32, %acc: f32):
    %product = arith.mulf %i, %f : f32
    %sum = arith.addf %acc, %product : f32
    linalg.yield %sum : f32
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
