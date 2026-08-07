//===- TutorialTransformOps.h - Tutorial transform ops ----------*- C++ -*-===//
//
// Declares the tutorial transform dialect extension.
//
//===----------------------------------------------------------------------===//

#ifndef TUTORIAL_EX3_TRANSFORM_OP_TUTORIAL_TRANSFORM_OPS_H
#define TUTORIAL_EX3_TRANSFORM_OP_TUTORIAL_TRANSFORM_OPS_H

#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/Dialect/Transform/IR/TransformDialect.h"
#include "mlir/Dialect/Transform/Interfaces/MatchInterfaces.h"
#include "mlir/Dialect/Transform/Interfaces/TransformInterfaces.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#define GET_OP_CLASSES
#include "ex3-transform-op/TutorialTransformOps.h.inc"

namespace mlir {
class DialectRegistry;

namespace tutorial {
/// Registers the tutorial extension of the Transform dialect in the given
/// registry.
void registerTutorialTransformExtension(DialectRegistry &registry);
} // namespace tutorial
} // namespace mlir

#endif // TUTORIAL_EX3_TRANSFORM_OP_TUTORIAL_TRANSFORM_OPS_H
