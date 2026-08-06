//===- NonEmptyPathAnalysisPass.cpp - Dense list analysis pass -----------===//

#include "analysis/non-empty-path/NonEmptyPathAnalysisPass.h"

#include "analysis/non-empty-path/NonEmptyPathAnalysis.h"
#include "list/IR/List.h"
#include "mlir/Analysis/DataFlow/Utils.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"

using namespace mlir;

namespace mlir::tutorial::analysis {
namespace {

class AnnotateNonEmptyPathAnalysisPass
    : public PassWrapper<AnnotateNonEmptyPathAnalysisPass, OperationPass<>> {
public:
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(AnnotateNonEmptyPathAnalysisPass)

  StringRef getArgument() const final {
    return "print-list-non-empty-path-analysis";
  }
  StringRef getDescription() const final {
    return "Attach path-sensitive list non-emptiness analysis results";
  }

  void runOnOperation() override {
    DataFlowConfig config;
    config.setInterprocedural(false);
    DataFlowSolver solver(config);
    dataflow::loadBaselineAnalyses(solver);
    solver.load<ListNonEmptyPathAnalysis>();

    if (failed(solver.initializeAndRun(getOperation()))) {
      getOperation()->emitError(
          "failed to run list non-emptiness path analysis");
      signalPassFailure();
      return;
    }

    getOperation()->walk([&](Operation *op) {
      Value input;
      if (auto length = dyn_cast<list::LengthOp>(op))
        input = length.getInput();
      else if (auto pop = dyn_cast<list::PopFrontOp>(op))
        input = pop.getInput();
      else
        return;

      op->setAttr("list.input_non_empty",
                  BoolAttr::get(op->getContext(),
                                isKnownNonEmptyBefore(solver, op, input)));
    });
  }
};

} // namespace

void registerNonEmptyPathAnalysisPass() {
  PassRegistration<AnnotateNonEmptyPathAnalysisPass>();
}

} // namespace mlir::tutorial::analysis
