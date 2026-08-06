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

SizeRangeValue SizeRangeValue::add(const SizeRangeValue &lhs,
                                   const SizeRangeValue &rhs) {
  if (lhs.isUninitialized() || rhs.isUninitialized())
    return getUninitialized();

  // Saturating the lower bound remains conservative: the saturated value is
  // still no greater than the true mathematical result.
  uint64_t lower = llvm::SaturatingAdd(lhs.lower, rhs.lower);
  std::optional<uint64_t> upper;
  if (lhs.upper && rhs.upper) {
    bool overflowed = false;
    uint64_t sum = llvm::SaturatingAdd(*lhs.upper, *rhs.upper, &overflowed);
    if (!overflowed)
      upper = sum;
  }
  return getRange(lower, upper);
}

SizeRangeValue SizeRangeValue::join(const SizeRangeValue &lhs,
                                    const SizeRangeValue &rhs) {
  if (lhs.isUninitialized())
    return rhs;
  if (rhs.isUninitialized())
    return lhs;

  uint64_t lower = std::min(lhs.lower, rhs.lower);
  std::optional<uint64_t> upper;
  if (lhs.upper && rhs.upper)
    upper = std::max(*lhs.upper, *rhs.upper);
  return getRange(lower, upper);
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
  set(lattice, SizeRangeValue::getUnknown());
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
    set(results.front(), SizeRangeValue::add(operands.front()->getValue(),
                                             SizeRangeValue::getExact(1)));
    return success();
  }

  if (isa<list::ConcatOp>(op)) {
    set(results.front(),
        SizeRangeValue::add(operands[0]->getValue(), operands[1]->getValue()));
    return success();
  }

  if (isa<list::PopFrontOp>(op)) {
    const SizeRangeValue &input = operands.front()->getValue();
    if (input.isUninitialized()) {
      set(results.front(), SizeRangeValue::getUninitialized());
      return success();
    }

    uint64_t lower = input.getLower() == 0 ? 0 : input.getLower() - 1;
    std::optional<uint64_t> upper = input.getUpper();
    if (upper)
      *upper = *upper == 0 ? 0 : *upper - 1;
    set(results.front(), SizeRangeValue::getRange(lower, upper));
    return success();
  }

  if (isa<list::LengthOp>(op)) {
    // The length result has exactly the same numeric range as the size of the
    // input list. Modeling it makes the range directly available to rewrites.
    set(results.front(), operands.front()->getValue());
    return success();
  }

  // Unknown producers, including region arguments, may hold a list of any
  // size. Non-list values also use the entry state, but their lattice values
  // are never consumed except as ignored operands (such as list.push_back's
  // element operand).
  setAllToEntryStates(results);
  return success();
}

} // namespace mlir::tutorial::analysis
