#include "dialect/TutorialDialect.h"

#include "mlir/IR/DialectImplementation.h"

using namespace mlir;
using namespace mlir::tutorial;

#include "dialect/TutorialOpsDialect.cpp.inc"

void TutorialDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "dialect/TutorialOps.cpp.inc"
      >();
}

#define GET_OP_CLASSES
#include "dialect/TutorialOps.cpp.inc"
