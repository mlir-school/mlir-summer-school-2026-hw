//===- tutorial-opt.cpp - Tutorial MLIR Optimizer Driver ------------------===//
//
// A simple mlir-opt like tool for the tutorial.
//
//===----------------------------------------------------------------------===//

#include "mlir/IR/MLIRContext.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllExtensions.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "analysis/integer-range/IntegerRangeAnalysisPass.h"
#include "analysis/integer-range/IntegerRangeOptimizationPass.h"
#include "analysis/non-empty-path/NonEmptyPathAnalysisPass.h"
#include "analysis/size-range/SizeRangeAnalysisPass.h"
#include "list/IR/List.h"
#include "list/Transforms/ListPasses.h"

int main(int argc, char **argv) {
  mlir::DialectRegistry registry;

  // Register all MLIR dialects.
  mlir::registerAllDialects(registry);

  // Register all MLIR passes.
  mlir::registerAllPasses();

  // Register all extensions.
  mlir::registerAllExtensions(registry);

  // Register tutorial dialects.
  registry.insert<mlir::list::ListDialect>();

  // Register tutorial passes.
  mlir::list::registerListPasses();

  // Register tutorial analyses.
  mlir::tutorial::analysis::registerSizeRangeAnalysisPass();
  mlir::tutorial::analysis::registerSizeRangeOptimizationPass();
  mlir::tutorial::analysis::registerNonEmptyPathAnalysisPass();
  mlir::tutorial::analysis::registerNonEmptyPathOptimizationPass();
  mlir::tutorial::analysis::registerIntegerRangeAnalysisPass();
  mlir::tutorial::analysis::registerIntegerRangeOptimizationPass();

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Tutorial optimizer driver\n", registry));
}
