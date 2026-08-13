//===- ListIntegerRangeAnalysis.h - Size-aware integer ranges -*- C++ -*-===//
//
// Connects list size ranges to MLIR's integer range analysis.
//
//===----------------------------------------------------------------------===//

#ifndef TUTORIAL_ANALYSIS_INTEGER_RANGE_LIST_INTEGER_RANGE_ANALYSIS_H
#define TUTORIAL_ANALYSIS_INTEGER_RANGE_LIST_INTEGER_RANGE_ANALYSIS_H

#include "mlir/Analysis/DataFlow/IntegerRangeAnalysis.h"

namespace mlir::tutorial::analysis {

/// MLIR's integer range analysis extended with a transfer function that maps
/// the size range of a list to the integer range of list.length.
class ListIntegerRangeAnalysis final : public dataflow::IntegerRangeAnalysis {
public:
  using IntegerRangeAnalysis::IntegerRangeAnalysis;

  LogicalResult visitOperation(
      Operation *op,
      ArrayRef<const dataflow::IntegerValueRangeLattice *> operands,
      ArrayRef<dataflow::IntegerValueRangeLattice *> results) override;
};

} // namespace mlir::tutorial::analysis

#endif // TUTORIAL_ANALYSIS_INTEGER_RANGE_LIST_INTEGER_RANGE_ANALYSIS_H
