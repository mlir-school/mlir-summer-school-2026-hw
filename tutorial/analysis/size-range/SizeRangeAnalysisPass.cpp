//===- SizeRangeAnalysisPass.cpp - List size range analysis pass --------===//

#include "analysis/size-range/SizeRangeAnalysisPass.h"

#include "analysis/size-range/SizeRangeAnalysis.h"
#include "list/IR/List.h"
#include "mlir/Analysis/DataFlow/Utils.h"
#include "mlir/IR/Operation.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "llvm/Support/raw_ostream.h"

#include <string>

using namespace mlir;

namespace mlir::tutorial::analysis {
namespace {

class AnnotateSizeRangeAnalysisPass
    : public PassWrapper<AnnotateSizeRangeAnalysisPass, OperationPass<>> {
public:
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(AnnotateSizeRangeAnalysisPass)

  StringRef getArgument() const final {
    return "print-list-size-range-analysis";
  }
  StringRef getDescription() const final {
    return "Attach list size range analysis results to operations";
  }

  void runOnOperation() override {
    DataFlowSolver solver;
    dataflow::loadBaselineAnalyses(solver);
    solver.load<SizeRangeAnalysis>();

    if (failed(solver.initializeAndRun(getOperation()))) {
      getOperation()->emitError("failed to run list size range analysis");
      signalPassFailure();
      return;
    }

    getOperation()->walk([&](Operation *op) {
      if (op->getNumResults() != 1)
        return;

      Value result = op->getResult(0);
      bool isList = isa<list::ListType>(result.getType());
      if (!isList && !isa<list::LengthOp>(op))
        return;

      const auto *lattice = solver.lookupState<SizeRangeLattice>(result);
      SizeRangeValue range =
          lattice ? lattice->getValue() : SizeRangeValue::getUninitialized();

      std::string value;
      llvm::raw_string_ostream stream(value);
      range.print(stream);
      op->setAttr("list.size_range",
                  StringAttr::get(op->getContext(), stream.str()));
    });
  }
};

} // namespace

void registerSizeRangeAnalysisPass() {
  PassRegistration<AnnotateSizeRangeAnalysisPass>();
}

} // namespace mlir::tutorial::analysis
