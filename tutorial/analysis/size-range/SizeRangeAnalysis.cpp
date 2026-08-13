//===- SizeRangeAnalysis.cpp - List size range analysis ------------------===//
//
// Implements a sparse data-flow analysis that computes bounds on list sizes.
//
//===----------------------------------------------------------------------===//

#include "analysis/size-range/SizeRangeAnalysis.h"

#include "list/IR/List.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <cassert>

using namespace mlir;

namespace mlir::tutorial::analysis {

SizeRangeValue SizeRangeValue::getRange(uint64_t lower,
                                        std::optional<uint64_t> upper) {
  assert((!upper || lower <= *upper) && "invalid size range");
  return SizeRangeValue(lower, upper);
}

uint64_t SizeRangeValue::getExactValue() const {
  assert(isExact() && "expected an exact size");
  return lower;
}

SizeRangeValue SizeRangeValue::join(const SizeRangeValue &lhs,
                                    const SizeRangeValue &rhs) {
  // EXERCISE: complete here
  return SizeRangeValue::getUnknown();
}

void SizeRangeValue::print(llvm::raw_ostream &os) const {
  if (isUninitialized()) {
    os << "uninitialized";
    return;
  }

  os << '[' << lower << ", ";
  if (upper)
    os << *upper;
  else
    os << "+inf";
  os << ']';
}

ChangeResult
SizeRangeLattice::join(const dataflow::AbstractSparseLattice &rhs) {
  return join(static_cast<const SizeRangeLattice &>(rhs).getValue());
}

ChangeResult SizeRangeLattice::join(const SizeRangeValue &rhs) {
  const SizeRangeValue &current = getValue();
  SizeRangeValue joined = SizeRangeValue::join(current, rhs);

  // Preserve precise bounds for ordinary joins, but guarantee convergence for
  // loop-carried lists by widening an upper bound that repeatedly increases.
  // Four growth steps retain useful precision for small tutorial examples.
  if (!current.isUninitialized() && current.hasUpperBound() &&
      (!joined.hasUpperBound() || *joined.getUpper() > *current.getUpper())) {
    ++upperBoundGrowths;
    if (upperBoundGrowths >= 4)
      joined = SizeRangeValue::getRange(joined.getLower(), std::nullopt);
  }

  return dataflow::Lattice<SizeRangeValue>::join(joined);
}

void SizeRangeAnalysis::set(SizeRangeLattice *lattice,
                            const SizeRangeValue &value) {
  propagateIfChanged(lattice, lattice->join(value));
}

void SizeRangeAnalysis::setToEntryState(SizeRangeLattice *lattice) {
  // EXERCISE: complete here
}

LogicalResult
SizeRangeAnalysis::visitOperation(Operation *op,
                                  ArrayRef<const SizeRangeLattice *> operands,
                                  ArrayRef<SizeRangeLattice *> results) {
  if (isa<list::EmptyOp>(op)) {
    set(results.front(), SizeRangeValue::getExact(0));
    return success();
  }

  if (isa<list::PushBackOp>(op)) {
    // EXERCISE: complete here
  }

  if (isa<list::PushFrontOp>(op)) {
    // EXERCISE: complete here
  }

  if (isa<list::PopFrontOp>(op)) {
    // EXERCISE: complete here
  }

  if (isa<list::ConcatOp>(op)) {
    // EXERCISE: complete here.
    // This exercise is a bit harder than the others.
  }

  // Unknown producers, including region arguments, may hold a list of any
  // size. Non-list values also use the entry state, but their lattice values
  // are never consumed except as ignored operands (such as list.push_back's
  // element operand).
  setAllToEntryStates(results);
  return success();
}

} // namespace mlir::tutorial::analysis
