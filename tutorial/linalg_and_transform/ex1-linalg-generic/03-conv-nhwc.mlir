// RUN: mlir-opt %s --linalg-generalize-named-ops | FileCheck %s

//===----------------------------------------------------------------------===//
// EXERCISE 1c - NHWC convolution
//
//   O[n, oh, ow, oc] += I[n, oh + kh, ow + kw, ic] * F[kh, kw, ic, oc]
//
// Use the iteration order (n, oh, ow, oc, kh, kw, ic).
//
// This one is different from a matmul in a way that matters later: the input
// map adds two induction variables together. It is not a projected permutation,
// which is why a convolution cannot be folded back into a named op the way a
// matmul can, and why tiling it behaves differently.
//
// HOW THIS IS CHECKED
// @reference is the upstream named op, do not edit it. Running
// --linalg-generalize-named-ops turns it into a generic, and MLIR gives
// structurally identical affine maps the same #map alias. So if your maps match
// the reference exactly, both functions end up printing the *same* aliases,
// which is what the CHECK lines below compare.
//===----------------------------------------------------------------------===//

#in  = affine_map<(n, oh, ow, oc, kh, kw, ic) -> (n, oh + kh, ow + kw, ic)>
#flt = affine_map<(n, oh, ow, oc, kh, kw, ic) -> (kh, kw, ic, oc)>
#out = affine_map<(n, oh, ow, oc, kh, kw, ic) -> (n, oh, ow, oc)>

// Reference implementation. Do not edit.
func.func @reference(%I: tensor<1x8x8x4xf32>, %F: tensor<3x3x4x16xf32>,
                     %O: tensor<1x6x6x16xf32>) -> tensor<1x6x6x16xf32> {
  %0 = linalg.conv_2d_nhwc_hwcf
      ins(%I, %F : tensor<1x8x8x4xf32>, tensor<3x3x4x16xf32>)
      outs(%O : tensor<1x6x6x16xf32>) -> tensor<1x6x6x16xf32>
  return %0 : tensor<1x6x6x16xf32>
}

// Your version.
func.func @student(%I: tensor<1x8x8x4xf32>, %F: tensor<3x3x4x16xf32>,
                   %O: tensor<1x6x6x16xf32>) -> tensor<1x6x6x16xf32> {
  %0 = linalg.generic {
    indexing_maps = [#in, #flt, #out],
    iterator_types = ["parallel", "parallel", "parallel", "parallel",
                      "reduction", "reduction", "reduction"]
  } ins(%I, %F : tensor<1x8x8x4xf32>, tensor<3x3x4x16xf32>)
    outs(%O : tensor<1x6x6x16xf32>) {
  ^bb0(%i: f32, %f: f32, %acc: f32):
    %product = arith.mulf %i, %f : f32
    %sum = arith.addf %acc, %product : f32
    linalg.yield %sum : f32
  } -> tensor<1x6x6x16xf32>
  return %0 : tensor<1x6x6x16xf32>
}

// CHECK-LABEL: func.func @reference
// CHECK:         linalg.generic
// CHECK-SAME:      indexing_maps = [#[[$IN:[a-zA-Z0-9_]+]], #[[$FLT:[a-zA-Z0-9_]+]], #[[$OUT:[a-zA-Z0-9_]+]]]
// CHECK-SAME:      iterator_types = ["parallel", "parallel", "parallel", "parallel", "reduction", "reduction", "reduction"]

// CHECK-LABEL: func.func @student
// CHECK:         linalg.generic
// CHECK-SAME:      indexing_maps = [#[[$IN]], #[[$FLT]], #[[$OUT]]]
// CHECK-SAME:      iterator_types = ["parallel", "parallel", "parallel", "parallel", "reduction", "reduction", "reduction"]
