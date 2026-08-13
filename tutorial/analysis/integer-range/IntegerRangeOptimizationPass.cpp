//===- IntegerRangeOptimizationPass.cpp - Integer range optimizations ----===//
//
// Runs MLIR's IntegerRangeAnalysis and materializes integer results that it
// proves constant. The List dialect participates through
// InferIntRangeInterface.
//
//===----------------------------------------------------------------------===//

#include "analysis/integer-range/IntegerRangeOptimizationPass.h"

#include "analysis/integer-range/ListIntegerRangeAnalysis.h"
#include "analysis/size-range/SizeRangeAnalysis.h"
#include "mlir/Analysis/DataFlow/IntegerRangeAnalysis.h"
#include "mlir/Analysis/DataFlow/Utils.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

using namespace mlir;

namespace mlir::tutorial::analysis {
namespace {

/// Replace uses of an integer result when IntegerRangeAnalysis proves that it
/// has exactly one possible value. The defining operation is left in place so
/// side-effecting operations remain intact; greedy cleanup erases pure dead
/// operations.
class MaterializeIntegerRangeConstant final : public RewritePattern {
public:
  MaterializeIntegerRangeConstant(MLIRContext *context, DataFlowSolver &solver)
      : RewritePattern(MatchAnyOpTypeTag(), /*benefit=*/1, context),
        solver(solver) {}

  LogicalResult matchAndRewrite(Operation *op,
                                PatternRewriter &rewriter) const override {
    // Constants are already in the desired form. Restricting this pattern to
    // one-result operations also avoids partially rewriting multi-result ops.
    if (op->hasTrait<OpTrait::ConstantLike>() || op->getNumResults() != 1)
      return failure();

    Value result = op->getResult(0);
    if (!result.getType().isIntOrIndex() || result.use_empty())
      return failure();

    const auto *lattice =
        solver.lookupState<dataflow::IntegerValueRangeLattice>(result);
    if (!lattice || lattice->getValue().isUninitialized())
      return failure();

    std::optional<APInt> constantValue =
        lattice->getValue().getValue().getConstantValue();
    if (!constantValue)
      return failure();

    auto constant = arith::ConstantOp::create(
        rewriter, result.getLoc(), result.getType(),
        rewriter.getIntegerAttr(result.getType(), *constantValue));
    rewriter.replaceAllUsesWith(result, constant.getResult());
    return success();
  }

private:
  DataFlowSolver &solver;
};

class OptimizeIntegerRangesPass
    : public PassWrapper<OptimizeIntegerRangesPass, OperationPass<>> {
public:
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(OptimizeIntegerRangesPass)

  StringRef getArgument() const final { return "optimize-list-integer-ranges"; }
  StringRef getDescription() const final {
    return "Optimize list-related integer values using IntegerRangeAnalysis";
  }

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<arith::ArithDialect>();
  }

  void runOnOperation() override {
    DataFlowSolver solver;
    dataflow::loadBaselineAnalyses(solver);
    solver.load<SizeRangeAnalysis>();
    solver.load<ListIntegerRangeAnalysis>();

    if (failed(solver.initializeAndRun(getOperation()))) {
      getOperation()->emitError("failed to run integer range analysis");
      signalPassFailure();
      return;
    }

    RewritePatternSet patterns(&getContext());
    patterns.add<MaterializeIntegerRangeConstant>(&getContext(), solver);
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns)))) {
      getOperation()->emitError("failed to apply integer range rewrites");
      signalPassFailure();
    }
  }
};

} // namespace

void registerIntegerRangeOptimizationPass() {
  PassRegistration<OptimizeIntegerRangesPass>();
}

} // namespace mlir::tutorial::analysis
