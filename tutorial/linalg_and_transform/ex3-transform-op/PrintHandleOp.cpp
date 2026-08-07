//===- PrintHandleOp.cpp - Exercise 3 -------------------------*- C++ -*-===//
//
// EXERCISE 3 - reference solution
//
// `transform.tutorial.print_handle` lets you printf-debug a transform script
// while it runs.
//
// The operation is defined in TutorialTransformOps.td and registered with the
// transform dialect by TutorialTransformExtension.cpp. All that is left is the
// behaviour, in `apply` below.
//
// Build and test with:
//   lit build/test --filter=ex3 -v
//
//===----------------------------------------------------------------------===//

#include "ex3-transform-op/TutorialTransformOps.h"

using namespace mlir;

/// Called by the transform interpreter when it reaches this operation in a
/// schedule.
///
/// `state` is the interpreter's bookkeeping: it maps transform IR values
/// (handles) to the payload IR entities they currently stand for. Because this
/// operation produces no results it does not have to write anything into
/// `results`, and because it does not rewrite the payload it does not have to
/// use `rewriter`.
DiagnosedSilenceableFailure transform::PrintHandleOp::apply(
    transform::TransformRewriter &rewriter,
    transform::TransformResults &results, transform::TransformState &state) {

  // A handle stands for a set of payload operations, so materialize the range
  // before reporting on it: we want the total up front.
  SmallVector<Operation *> payload =
      llvm::to_vector(state.getPayloadOps(getTarget()));

  // Emitting the diagnostic *at the payload operation* is what attaches a
  // source location to it, and what lets the test check it with
  // -verify-diagnostics.
  for (auto [index, op] : llvm::enumerate(payload)) {
    op->emitRemark() << getMessage() << " (" << index + 1 << " of "
                     << payload.size() << "): " << op->getName();
  }

  // Nothing was rewritten and nothing can go wrong, so this always succeeds.
  // The alternatives are a silenceable failure, which an enclosing op may
  // recover from, and a definite failure, which aborts the interpreter because
  // the payload is left inconsistent.
  return DiagnosedSilenceableFailure::success();
}
