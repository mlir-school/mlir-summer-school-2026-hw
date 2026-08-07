// RUN: tutorial-opt %s --split-input-file --transform-interpreter \
// RUN:   --verify-diagnostics

// A handle is associated with a *set* of payload operations. Both matmuls below
// are matched by a single `transform.structured.match`, so a single
// `print_handle` has to report both of them.

module attributes {transform.with_named_sequence} {
  func.func @two_matmuls(%A: tensor<?x?xf32>, %B: tensor<?x?xf32>,
                         %C: tensor<?x?xf32>) -> tensor<?x?xf32> {
    // expected-remark @below {{before tiling (1 of 2): linalg.matmul}}
    %0 = linalg.matmul ins(%A, %B : tensor<?x?xf32>, tensor<?x?xf32>)
                       outs(%C : tensor<?x?xf32>) -> tensor<?x?xf32>
    // expected-remark @below {{before tiling (2 of 2): linalg.matmul}}
    %1 = linalg.matmul ins(%A, %B : tensor<?x?xf32>, tensor<?x?xf32>)
                       outs(%0 : tensor<?x?xf32>) -> tensor<?x?xf32>
    return %1 : tensor<?x?xf32>
  }

  transform.named_sequence @__transform_main(
      %arg0: !transform.any_op {transform.readonly}) {
    %matmuls = transform.structured.match ops{["linalg.matmul"]} in %arg0
      : (!transform.any_op) -> !transform.any_op

    transform.tutorial.print_handle %matmuls, "before tiling"
      : !transform.any_op

    transform.yield
  }
}

// -----

// The op only reads its operand, so the handle survives it and can still be
// used afterwards. If you forget NavigationTransformOpTrait in the TableGen
// definition, this is the test that catches it.

module attributes {transform.with_named_sequence} {
  func.func @handle_survives(%A: tensor<?x?xf32>, %B: tensor<?x?xf32>,
                             %C: tensor<?x?xf32>) -> tensor<?x?xf32> {
    // expected-remark @below {{first (1 of 1): linalg.matmul}}
    // expected-remark @below {{second (1 of 1): linalg.matmul}}
    %0 = linalg.matmul ins(%A, %B : tensor<?x?xf32>, tensor<?x?xf32>)
                       outs(%C : tensor<?x?xf32>) -> tensor<?x?xf32>
    return %0 : tensor<?x?xf32>
  }

  transform.named_sequence @__transform_main(
      %arg0: !transform.any_op {transform.readonly}) {
    %matmul = transform.structured.match ops{["linalg.matmul"]} in %arg0
      : (!transform.any_op) -> !transform.any_op

    transform.tutorial.print_handle %matmul, "first" : !transform.any_op
    transform.tutorial.print_handle %matmul, "second" : !transform.any_op

    transform.yield
  }
}

// -----

// An empty handle is not an error, it just reports nothing. This is the case
// that silently eats a schedule when a match is too specific.

module attributes {transform.with_named_sequence} {
  func.func @no_match(%A: tensor<?x?xf32>) -> tensor<?x?xf32> {
    return %A : tensor<?x?xf32>
  }

  transform.named_sequence @__transform_main(
      %arg0: !transform.any_op {transform.readonly}) {
    %none = transform.structured.match ops{["linalg.matmul"]} in %arg0
      : (!transform.any_op) -> !transform.any_op

    transform.tutorial.print_handle %none, "nothing here" : !transform.any_op

    transform.yield
  }
}
