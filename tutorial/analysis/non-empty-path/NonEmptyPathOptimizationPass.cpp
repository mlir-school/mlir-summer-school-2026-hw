//===- NonEmptyPathOptimizationPass.cpp - Path-sensitive rewrites --------===//

#include "analysis/non-empty-path/NonEmptyPathAnalysisPass.h"

#include "analysis/non-empty-path/NonEmptyPathAnalysis.h"
#include "list/IR/List.h"
#include "mlir/Analysis/DataFlow/Utils.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/IR/Matchers.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

using namespace mlir;

namespace mlir::tutorial::analysis {
namespace {

/// Fold a comparison with zero when the incoming dense state proves the list
/// non-empty at the comparison's program point.
class SimplifyKnownNonEmptyComparison final
    : public OpRewritePattern<arith::CmpIOp> {
public:
  SimplifyKnownNonEmptyComparison(MLIRContext *context, DataFlowSolver &solver)
      : OpRewritePattern(context), solver(solver) {}

  LogicalResult matchAndRewrite(arith::CmpIOp compare,
                                PatternRewriter &rewriter) const override {
    arith::CmpIPredicate predicate = compare.getPredicate();
    if (predicate != arith::CmpIPredicate::eq &&
        predicate != arith::CmpIPredicate::ne)
      return failure();

    list::LengthOp length;
    if (matchPattern(compare.getRhs(), m_Zero()))
      length = compare.getLhs().getDefiningOp<list::LengthOp>();
    else if (matchPattern(compare.getLhs(), m_Zero()))
      length = compare.getRhs().getDefiningOp<list::LengthOp>();
    if (!length || !isKnownNonEmptyBefore(solver, compare, length.getInput()))
      return failure();

    bool result = predicate == arith::CmpIPredicate::ne;
    rewriter.replaceOpWithNewOp<arith::ConstantIntOp>(compare, result, 1);
    return success();
  }

private:
  DataFlowSolver &solver;
};

class OptimizeNonEmptyPathsPass
    : public PassWrapper<OptimizeNonEmptyPathsPass, OperationPass<>> {
public:
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(OptimizeNonEmptyPathsPass)

  StringRef getArgument() const final {
    return "optimize-list-non-empty-paths";
  }
  StringRef getDescription() const final {
    return "Fold list emptiness checks using path-sensitive facts";
  }

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<arith::ArithDialect>();
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

    RewritePatternSet patterns(&getContext());
    patterns.add<SimplifyKnownNonEmptyComparison>(&getContext(), solver);
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns)))) {
      getOperation()->emitError("failed to apply non-empty path rewrites");
      signalPassFailure();
    }
  }
};

} // namespace

void registerNonEmptyPathOptimizationPass() {
  PassRegistration<OptimizeNonEmptyPathsPass>();
}

} // namespace mlir::tutorial::analysis
