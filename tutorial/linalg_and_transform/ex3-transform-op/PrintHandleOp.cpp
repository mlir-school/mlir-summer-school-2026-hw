//===- PrintHandleOp.cpp - Exercise 3 -------------------------*- C++ -*-===//
//
// EXERCISE 3
//
// Implement `transform.tutorial.print_handle` so that you can printf-debug a
// transform script while it runs.
//
// The operation is already defined in TutorialTransformOps.td and already
// registered with the transform dialect. The only thing missing is the
// behaviour, which lives in `apply` below.
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

  //===--------------------------------------------------------------------===//
  // TODO(exercise 3): replace the failure below with the implementation.
  //
  // 1. Ask the state which payload operations `getTarget()` is associated with.
  //    `state.getPayloadOps(Value)` returns a lazy range, so wrap it:
  //
  //      SmallVector<Operation *> payload =
  //          llvm::to_vector(state.getPayloadOps(getTarget()));
  //
  // 2. Emit a remark at each one. `Operation::emitRemark()` returns a stream
  //    you can append to, and `getMessage()` gives you the string attribute:
  //
  //      op->emitRemark() << getMessage() << " (" << i + 1 << " of "
  //                       << payload.size() << "): " << op->getName();
  //
  //    Emitting *at the payload operation* rather than dumping to stdout is
  //    what makes the output point at a source location, and what lets the
  //    test check it with `-verify-diagnostics`.
  //
  // 3. Return `DiagnosedSilenceableFailure::success()`.
  //
  // Note the three ways a transform op can end, they are not interchangeable:
  //   - success()              the transformation applied
  //   - silenceableFailure()   it did not apply, but an enclosing op may
  //                            recover from it
  //   - definiteFailure()      the payload is now inconsistent, abort the
  //                            whole interpreter run
  //===--------------------------------------------------------------------===//

  return emitDefiniteFailure()
         << "transform.tutorial.print_handle is not implemented yet - see "
            "tutorial/linalg_and_transform/ex3-transform-op/PrintHandleOp.cpp";
}
