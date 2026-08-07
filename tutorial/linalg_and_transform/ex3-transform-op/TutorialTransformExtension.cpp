//===- TutorialTransformExtension.cpp - Extension registration --*- C++ -*-===//
//
// Boilerplate that injects the tutorial operations into the transform dialect.
// You do not need to change anything in this file for the exercise; the code
// you have to write lives in PrintHandleOp.cpp.
//
//===----------------------------------------------------------------------===//

#include "ex3-transform-op/TutorialTransformOps.h"

#include "mlir/IR/DialectRegistry.h"

using namespace mlir;

#define GET_OP_CLASSES
#include "ex3-transform-op/TutorialTransformOps.cpp.inc"

namespace {
/// Extensions are how a project adds operations to the transform dialect
/// without forking it. Registering the extension makes the ops available to the
/// transform interpreter.
class TutorialTransformExtension
    : public transform::TransformDialectExtension<TutorialTransformExtension> {
public:
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(TutorialTransformExtension)

  using Base::Base;

  void init() {
    registerTransformOps<
#define GET_OP_LIST
#include "ex3-transform-op/TutorialTransformOps.cpp.inc"
        >();
  }
};
} // namespace

void mlir::tutorial::registerTutorialTransformExtension(
    DialectRegistry &registry) {
  registry.addExtensions<TutorialTransformExtension>();
}
