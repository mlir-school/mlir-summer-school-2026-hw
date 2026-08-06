//===- NonEmptyPathAnalysis.h - Path-sensitive list analysis ---*- C++ -*-===//
//
// Declares a dense forward analysis that tracks which list SSA values are
// definitely non-empty at each program point.
//
//===----------------------------------------------------------------------===//

#ifndef TUTORIAL_ANALYSIS_NON_EMPTY_PATH_ANALYSIS_H
#define TUTORIAL_ANALYSIS_NON_EMPTY_PATH_ANALYSIS_H

#include "mlir/Analysis/DataFlow/DenseAnalysis.h"
#include "llvm/ADT/DenseSet.h"

namespace mlir::tutorial::analysis {

/// The abstract program state used by ListNonEmptyPathAnalysis. The set
/// contains list values that are known to be non-empty at one particular
/// program point. An uninitialized value is the lattice bottom; an initialized
/// empty set means that no list is known to be non-empty.
class NonEmptyPathValue {
public:
  NonEmptyPathValue() = default;

  static NonEmptyPathValue getUninitialized() { return NonEmptyPathValue(); }
  static NonEmptyPathValue getEntryState();

  bool isUninitialized() const { return !initialized; }
  bool contains(Value value) const { return nonEmptyValues.contains(value); }
  void markNonEmpty(Value value);

  /// Join control-flow paths. A fact remains known only if it holds on every
  /// incoming path, so initialized states are joined by set intersection.
  static NonEmptyPathValue join(const NonEmptyPathValue &lhs,
                                const NonEmptyPathValue &rhs);

  bool operator==(const NonEmptyPathValue &rhs) const;
  void print(llvm::raw_ostream &os) const;

private:
  explicit NonEmptyPathValue(bool initialized) : initialized(initialized) {}

  bool initialized = false;
  llvm::SmallDenseSet<Value, 8> nonEmptyValues;
};

/// A dense lattice is attached to a program point rather than an SSA value.
class NonEmptyPathLattice : public dataflow::AbstractDenseLattice {
public:
  using AbstractDenseLattice::AbstractDenseLattice;

  const NonEmptyPathValue &getValue() const { return value; }

  ChangeResult join(const dataflow::AbstractDenseLattice &rhs) override;
  ChangeResult join(const NonEmptyPathValue &rhs);
  void print(llvm::raw_ostream &os) const override { value.print(os); }

private:
  NonEmptyPathValue value;
};

/// A dense forward analysis that records definition-derived non-emptiness facts
/// and refines them on CFG edges selected by comparisons with list.length.
class ListNonEmptyPathAnalysis
    : public dataflow::DenseForwardDataFlowAnalysis<NonEmptyPathLattice> {
public:
  using DenseForwardDataFlowAnalysis::DenseForwardDataFlowAnalysis;

  LogicalResult visitOperation(Operation *op, const NonEmptyPathLattice &before,
                               NonEmptyPathLattice *after) override;

  void visitBlockTransfer(Block *block, ProgramPoint *, Block *predecessor,
                          const NonEmptyPathLattice &before,
                          NonEmptyPathLattice *after) override;

  void setToEntryState(NonEmptyPathLattice *lattice) override;

private:
  void set(NonEmptyPathLattice *lattice, const NonEmptyPathValue &value);
};

/// Query whether `value` is definitely non-empty immediately before `op`.
bool isKnownNonEmptyBefore(DataFlowSolver &solver, Operation *op, Value value);

} // namespace mlir::tutorial::analysis

#endif // TUTORIAL_ANALYSIS_NON_EMPTY_PATH_ANALYSIS_H
