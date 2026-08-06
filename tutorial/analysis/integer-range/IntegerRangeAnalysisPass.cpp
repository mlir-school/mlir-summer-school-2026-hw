//===- IntegerRangeAnalysisPass.cpp - Integer range analysis pass -------===//

#include "analysis/integer-range/IntegerRangeAnalysisPass.h"

#include "list/IR/List.h"
#include "mlir/Analysis/DataFlow/IntegerRangeAnalysis.h"
#include "mlir/Analysis/DataFlow/Utils.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/Operation.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "llvm/Support/raw_ostream.h"

#include <string>

using namespace mlir;

namespace mlir::tutorial::analysis {
namespace {

class AnnotateIntegerRangeAnalysisPass
    : public PassWrapper<AnnotateIntegerRangeAnalysisPass, OperationPass<>> {
public:
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(AnnotateIntegerRangeAnalysisPass)

  StringRef getArgument() const final {
    return "print-list-integer-range-analysis";
  }
  StringRef getDescription() const final {
    return "Attach IntegerRangeAnalysis results to operations";
  }

  void runOnOperation() override {
    DataFlowSolver solver;
    dataflow::loadBaselineAnalyses(solver);
    solver.load<dataflow::IntegerRangeAnalysis>();

    if (failed(solver.initializeAndRun(getOperation()))) {
      getOperation()->emitError("failed to run integer range analysis");
      signalPassFailure();
      return;
    }

    getOperation()->walk([&](Operation *op) {
      SmallVector<NamedAttribute> resultRanges;
      Builder builder(op->getContext());

      for (OpResult result : op->getResults()) {
        auto listType = dyn_cast<list::ListType>(result.getType());
        if (!result.getType().isIntOrIndex() && !listType)
          continue;

        const auto *lattice =
            solver.lookupState<dataflow::IntegerValueRangeLattice>(result);
        if (!lattice || lattice->getValue().isUninitialized())
          continue;

        // A list value carries a summary of its element ranges. A zero-width
        // lattice is the generic state for non-integer values and does not
        // contain a usable list-element range.
        if (listType) {
          unsigned elementWidth =
              ConstantIntRanges::getStorageBitwidth(listType.getElementType());
          if (lattice->getValue().getValue().umin().getBitWidth() !=
              elementWidth)
            continue;
        }

        const ConstantIntRanges &range = lattice->getValue().getValue();
        std::string rangeText;
        llvm::raw_string_ostream stream(rangeText);
        stream << "signed : [";
        range.smin().print(stream, /*isSigned=*/true);
        stream << ", ";
        range.smax().print(stream, /*isSigned=*/true);
        stream << "]";

        std::string resultName =
            "result" + std::to_string(result.getResultNumber());
        resultRanges.push_back(builder.getNamedAttr(
            resultName, builder.getStringAttr(stream.str())));
      }

      if (!resultRanges.empty())
        op->setAttr("list.integer_ranges",
                    builder.getDictionaryAttr(resultRanges));
    });
  }
};

} // namespace

void registerIntegerRangeAnalysisPass() {
  PassRegistration<AnnotateIntegerRangeAnalysisPass>();
}

} // namespace mlir::tutorial::analysis
