#ifndef TUTORIAL_TUTORIAL_DIALECT_H
#define TUTORIAL_TUTORIAL_DIALECT_H

#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "dialect/TutorialOpsDialect.h.inc"

#define GET_OP_CLASSES
#include "dialect/TutorialOps.h.inc"

#endif // TUTORIAL_TUTORIAL_DIALECT_H
