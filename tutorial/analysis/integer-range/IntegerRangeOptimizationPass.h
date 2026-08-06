//===- IntegerRangeOptimizationPass.h - Integer range pass ----*- C++ -*-===//
//
// Declares list optimizations driven by MLIR's integer range analysis.
//
//===----------------------------------------------------------------------===//

#ifndef TUTORIAL_ANALYSIS_INTEGER_RANGE_OPTIMIZATION_PASS_H
#define TUTORIAL_ANALYSIS_INTEGER_RANGE_OPTIMIZATION_PASS_H

namespace mlir::tutorial::analysis {

void registerIntegerRangeOptimizationPass();

} // namespace mlir::tutorial::analysis

#endif // TUTORIAL_ANALYSIS_INTEGER_RANGE_OPTIMIZATION_PASS_H
