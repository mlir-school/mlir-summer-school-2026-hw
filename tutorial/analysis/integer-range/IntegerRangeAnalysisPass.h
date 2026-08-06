//===- IntegerRangeAnalysisPass.h - Integer range pass --------*- C++ -*-===//
//
// Declares a pass that annotates operations with MLIR integer range results.
//
//===----------------------------------------------------------------------===//

#ifndef TUTORIAL_ANALYSIS_INTEGER_RANGE_ANALYSIS_PASS_H
#define TUTORIAL_ANALYSIS_INTEGER_RANGE_ANALYSIS_PASS_H

namespace mlir::tutorial::analysis {

void registerIntegerRangeAnalysisPass();

} // namespace mlir::tutorial::analysis

#endif // TUTORIAL_ANALYSIS_INTEGER_RANGE_ANALYSIS_PASS_H
