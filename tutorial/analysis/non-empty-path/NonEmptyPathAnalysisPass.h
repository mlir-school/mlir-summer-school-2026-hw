//===- NonEmptyPathAnalysisPass.h - Dense list analysis passes -*- C++ -*-===//

#ifndef TUTORIAL_ANALYSIS_NON_EMPTY_PATH_ANALYSIS_PASS_H
#define TUTORIAL_ANALYSIS_NON_EMPTY_PATH_ANALYSIS_PASS_H

namespace mlir::tutorial::analysis {

void registerNonEmptyPathAnalysisPass();

/// Register rewrites driven by path-sensitive list non-emptiness facts.
void registerNonEmptyPathOptimizationPass();

} // namespace mlir::tutorial::analysis

#endif // TUTORIAL_ANALYSIS_NON_EMPTY_PATH_ANALYSIS_PASS_H
