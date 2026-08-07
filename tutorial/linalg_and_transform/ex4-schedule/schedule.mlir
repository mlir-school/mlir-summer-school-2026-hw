//===----------------------------------------------------------------------===//
// EXERCISE 4 - write the schedule
//
// This file is transform IR. It is loaded separately from payload.mlir with
// --transform-preload-library, so you can change the schedule without touching
// the algorithm and without rebuilding anything.
//
// Run it with:
//   lit build/test --filter=ex4 -v
//
// The steps, in order:
//   1. match the linalg.add with the __root__ attribute
//   2. match linalg.fill and linalg.matmul with the __producer__ attribute
//   3. tile the root with [8, 16]
//   4. fuse the producers into the generated loop nest
//   5. (optional) print the payload with the op from exercise 3
//   6. tile the root again with [4, 4]
//
// Useful operations, with their result and type signatures:
//
//   %h = transform.structured.match attributes {__some_attr__} in %arg0
//     : (!transform.any_op) -> !transform.any_op
//
//   %tiled, %loops:2 = transform.structured.tile_using_for %h tile_sizes [a, b]
//     : (!transform.any_op)
//       -> (!transform.any_op, !transform.any_op, !transform.any_op)
//
//   %fused, %new_containing =
//     transform.structured.fuse_into_containing_op %producers into %loop
//     : (!transform.any_op, !transform.any_op)
//       -> (!transform.any_op, !transform.any_op)
//
// WATCH OUT
// tile_using_for *consumes* the handle you give it. After step 3 the handle
// from step 1 is dead and using it again is an error, which is what
// --transform-dialect-check-uses reports. Step 6 has to start from the handle
// step 3 returned.
//===----------------------------------------------------------------------===//

module attributes {transform.with_named_sequence} {
  transform.named_sequence @__transform_main(
      %arg0: !transform.any_op {transform.readonly}) {

    // 1. Match the root.
    ???

    // 2. Match the producers.
    ???

    // 3. Tile the root with [8, 16].
    ???

    // 4. Fuse the producers into the loop nest.
    ???

    // 5. Optional: once exercise 3 works, print the payload here.
    // transform.tutorial.print_handle %???, "after fusion" : !transform.any_op

    // 6. Tile the root again with [4, 4].
    ???

    transform.yield
  }
}
