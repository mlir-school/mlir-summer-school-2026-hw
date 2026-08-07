//===- TutorialTransformOps.td - Tutorial transform ops ----*- tablegen -*-===//
//
// Exercise 3: a transform operation for printf-style debugging of schedules.
//
// Transform extensions inject their operations into the existing `transform`
// dialect rather than defining a dialect of their own, which is why the ops
// below use `TransformDialectOp` instead of a locally defined `Op` class. By
// convention the mnemonic is prefixed with the name of the extension, so
// `tutorial.print_handle` becomes `transform.tutorial.print_handle`.
//
//===----------------------------------------------------------------------===//

#ifndef TUTORIAL_EX3_TRANSFORM_OPS
#define TUTORIAL_EX3_TRANSFORM_OPS

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Dialect/Transform/IR/TransformDialect.td"
include "mlir/Dialect/Transform/Interfaces/MatchInterfaces.td"
include "mlir/Dialect/Transform/Interfaces/TransformInterfaces.td"

def PrintHandleOp : TransformDialectOp<"tutorial.print_handle",
    [MatchOpInterface,
     DeclareOpInterfaceMethods<TransformOpInterface>,
     MemoryEffectsOpInterface,
     NavigationTransformOpTrait]> {
  let summary = "Report which payload operations a handle is associated with";
  let description = [{
    Emits a diagnostic remark at every payload operation currently associated
    with `target`. The remark carries the user-provided `message`, the position
    of the operation within the handle, and the name of the operation.

    A handle is associated with a *set* of payload operations, not with a single
    one. Printing the position and the total makes that visible, which is the
    part of the transform model that is easiest to get wrong when a schedule
    does not do what you expected.

    This operation reads its operand and the payload but modifies neither, so it
    can be dropped anywhere into a schedule without invalidating handles.

    This operation always succeeds.
  }];

  let arguments = (ins TransformHandleTypeInterface:$target, StrAttr:$message);
  let results = (outs);
  let assemblyFormat = "$target `,` $message attr-dict `:` type($target)";
}

#endif // TUTORIAL_EX3_TRANSFORM_OPS
