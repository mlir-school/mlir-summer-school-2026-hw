//===- SizeRangeOptimizationPass.cpp - Optimize using list size ranges ---===//

#include "analysis/size-range/SizeRangeAnalysisPass.h"

#include "analysis/size-range/SizeRangeAnalysis.h"
#include "list/IR/List.h"
#include "mlir/Analysis/DataFlow/Utils.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

using namespace mlir;

namespace mlir::tutorial::analysis {
namespace {

static const SizeRangeValue *getSizeRange(DataFlowSolver &solver, Value value) {
  const auto *lattice = solver.lookupState<SizeRangeLattice>(value);
  return lattice ? &lattice->getValue() : nullptr;
}

/// Replace uses of a list result with an empty list when its size is known to
/// be zero. Leave the defining operation in place so side effects are kept;
/// greedy cleanup can erase dead pure operations.
class MaterializeEmptyList final : public RewritePattern {
public:
  MaterializeEmptyList(MLIRContext *context, DataFlowSolver &solver)
      : RewritePattern(MatchAnyOpTypeTag(), /*benefit=*/1, context),
        solver(solver) {}

  LogicalResult matchAndRewrite(Operation *op,
                                PatternRewriter &rewriter) const override {
    // Do not attempt to rewrite a `list.empty` operation or an operation without results.
    if (isa<list::EmptyOp>(op) || op->getNumResults() != 1)
      return failure();

    // Only consider operations that have a list result that is used.
    Value result = op->getResult(0);
    if (!isa<list::ListType>(result.getType()) || result.use_empty())
      return failure();
    
    // Get the size range of the result.
    const SizeRangeValue *range = getSizeRange(solver, result);
    
    // range->getLower() to get the lower bound of the size range
    // range->getUpper() to get the upper bound of the size range
    
    // To create a new operation and replace the original operation:
    // auto empty = list::EmptyOp::create(rewriter, result.getLoc(), result.getType());
    // rewriter.replaceAllUsesWith(result, empty.getResult());

    if (!range || !range->isExact(0))
      return failure();

    auto empty =
        list::EmptyOp::create(rewriter, result.getLoc(), result.getType());
    rewriter.replaceAllUsesWith(result, empty.getResult());
    return success();
  }

private:
  DataFlowSolver &solver;
};

class OptimizeSizeRangePass
    : public PassWrapper<OptimizeSizeRangePass, OperationPass<>> {
public:
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(OptimizeSizeRangePass)

  StringRef getArgument() const final { return "optimize-list-size-ranges"; }
  StringRef getDescription() const final {
    return "Optimize list operations using list size range analysis";
  }

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<list::ListDialect>();
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

    RewritePatternSet patterns(&getContext());
    patterns.add<MaterializeEmptyList>(&getContext(), solver);
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns)))) {
      getOperation()->emitError("failed to apply list size range rewrites");
      signalPassFailure();
    }
  }
};

} // namespace

void registerSizeRangeOptimizationPass() {
  PassRegistration<OptimizeSizeRangePass>();
}

} // namespace mlir::tutorial::analysis
