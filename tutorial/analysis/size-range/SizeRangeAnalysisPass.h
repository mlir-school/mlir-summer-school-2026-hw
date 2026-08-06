//===- SizeRangeAnalysisPass.h - List size range passes -------*- C++ -*-===//

#ifndef TUTORIAL_ANALYSIS_SIZE_RANGE_ANALYSIS_PASS_H
#define TUTORIAL_ANALYSIS_SIZE_RANGE_ANALYSIS_PASS_H

namespace mlir::tutorial::analysis {

void registerSizeRangeAnalysisPass();

/// Register rewrites driven by list size range information.
void registerSizeRangeOptimizationPass();

} // namespace mlir::tutorial::analysis

#endif // TUTORIAL_ANALYSIS_SIZE_RANGE_ANALYSIS_PASS_H
