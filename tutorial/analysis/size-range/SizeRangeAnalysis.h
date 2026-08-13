//===- SizeRangeAnalysis.h - List size range analysis ---------*- C++ -*-===//
//
// Declares a sparse data-flow analysis that computes bounds on list sizes.
//
//===----------------------------------------------------------------------===//

#ifndef TUTORIAL_ANALYSIS_SIZE_RANGE_ANALYSIS_H
#define TUTORIAL_ANALYSIS_SIZE_RANGE_ANALYSIS_H

#include "mlir/Analysis/DataFlow/SparseAnalysis.h"

#include <cstdint>
#include <optional>

namespace mlir::tutorial::analysis {

/// An inclusive range of possible list sizes. A missing upper bound represents
/// positive infinity.
class SizeRangeValue {
public:
  SizeRangeValue() = default;

  static SizeRangeValue getUninitialized() { return SizeRangeValue(); }
  static SizeRangeValue getUnknown() { return getRange(0, std::nullopt); }
  static SizeRangeValue getExact(uint64_t size) { return getRange(size, size); }
  static SizeRangeValue getRange(uint64_t lower, std::optional<uint64_t> upper);

  bool isUninitialized() const { return !initialized; }
  bool hasUpperBound() const { return upper.has_value(); }
  bool isExact() const { return upper && lower == *upper; }
  bool isExact(uint64_t size) const { return isExact() && lower == size; }

  uint64_t getLower() const { return lower; }
  std::optional<uint64_t> getUpper() const { return upper; }
  uint64_t getExactValue() const;

  /// Join two control-flow paths by taking their interval hull.
  static SizeRangeValue join(const SizeRangeValue &lhs,
                             const SizeRangeValue &rhs);

  bool operator==(const SizeRangeValue &rhs) const {
    return initialized == rhs.initialized &&
           (!initialized || (lower == rhs.lower && upper == rhs.upper));
  }

  void print(llvm::raw_ostream &os) const;

private:
  SizeRangeValue(uint64_t lower, std::optional<uint64_t> upper)
      : initialized(true), lower(lower), upper(upper) {}

  bool initialized = false;
  uint64_t lower = 0;
  std::optional<uint64_t> upper;
};

/// A lattice that applies widening after repeated upper-bound growth. Without
/// widening, a loop that appends on every iteration would produce the infinite
/// ascending chain [0, 0], [0, 1], [0, 2], ... and never reach a fixed point.
class SizeRangeLattice : public dataflow::Lattice<SizeRangeValue> {
public:
  using dataflow::Lattice<SizeRangeValue>::Lattice;

  ChangeResult join(const dataflow::AbstractSparseLattice &rhs) override;
  ChangeResult join(const SizeRangeValue &rhs);

private:
  unsigned upperBoundGrowths = 0;
};

/// A sparse forward analysis for list sizes. List-producing operations carry
/// the possible size of their result.
class SizeRangeAnalysis
    : public dataflow::SparseForwardDataFlowAnalysis<SizeRangeLattice> {
public:
  using SparseForwardDataFlowAnalysis::SparseForwardDataFlowAnalysis;

  LogicalResult visitOperation(Operation *op,
                               ArrayRef<const SizeRangeLattice *> operands,
                               ArrayRef<SizeRangeLattice *> results) override;

  void setToEntryState(SizeRangeLattice *lattice) override;

private:
  void set(SizeRangeLattice *lattice, const SizeRangeValue &value);
};

} // namespace mlir::tutorial::analysis

#endif // TUTORIAL_ANALYSIS_SIZE_RANGE_ANALYSIS_H
