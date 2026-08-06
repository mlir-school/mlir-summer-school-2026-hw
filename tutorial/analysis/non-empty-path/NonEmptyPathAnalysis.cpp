//===- NonEmptyPathAnalysis.cpp - Path-sensitive list analysis -----------===//

#include "analysis/non-empty-path/NonEmptyPathAnalysis.h"

#include "list/IR/List.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlowOps.h"
#include "mlir/IR/Matchers.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"

#include <cassert>
#include <utility>

using namespace mlir;

namespace mlir::tutorial::analysis {

NonEmptyPathValue NonEmptyPathValue::getEntryState() {
  return NonEmptyPathValue(/*initialized=*/true);
}

void NonEmptyPathValue::markNonEmpty(Value value) {
  assert(initialized && "cannot add a fact to an uninitialized state");
  nonEmptyValues.insert(value);
}

NonEmptyPathValue NonEmptyPathValue::join(const NonEmptyPathValue &lhs,
                                          const NonEmptyPathValue &rhs) {
  if (lhs.isUninitialized())
    return rhs;
  if (rhs.isUninitialized())
    return lhs;

  NonEmptyPathValue result = lhs;
  SmallVector<Value> toRemove;
  for (Value value : result.nonEmptyValues)
    if (!rhs.nonEmptyValues.contains(value))
      toRemove.push_back(value);
  for (Value value : toRemove)
    result.nonEmptyValues.erase(value);
  return result;
}

bool NonEmptyPathValue::operator==(const NonEmptyPathValue &rhs) const {
  if (initialized != rhs.initialized)
    return false;
  if (!initialized)
    return true;
  if (nonEmptyValues.size() != rhs.nonEmptyValues.size())
    return false;
  return llvm::all_of(nonEmptyValues, [&](Value value) {
    return rhs.nonEmptyValues.contains(value);
  });
}

void NonEmptyPathValue::print(llvm::raw_ostream &os) const {
  if (isUninitialized()) {
    os << "uninitialized";
    return;
  }
  os << nonEmptyValues.size() << " known non-empty value(s)";
}

ChangeResult
NonEmptyPathLattice::join(const dataflow::AbstractDenseLattice &rhs) {
  return join(static_cast<const NonEmptyPathLattice &>(rhs).getValue());
}

ChangeResult NonEmptyPathLattice::join(const NonEmptyPathValue &rhs) {
  NonEmptyPathValue joined = NonEmptyPathValue::join(value, rhs);
  if (joined == value)
    return ChangeResult::NoChange;
  value = std::move(joined);
  return ChangeResult::Change;
}

void ListNonEmptyPathAnalysis::set(NonEmptyPathLattice *lattice,
                                   const NonEmptyPathValue &value) {
  propagateIfChanged(lattice, lattice->join(value));
}

void ListNonEmptyPathAnalysis::setToEntryState(NonEmptyPathLattice *lattice) {
  set(lattice, NonEmptyPathValue::getEntryState());
}

LogicalResult
ListNonEmptyPathAnalysis::visitOperation(Operation *op,
                                         const NonEmptyPathLattice &before,
                                         NonEmptyPathLattice *after) {
  NonEmptyPathValue next = before.getValue();
  if (next.isUninitialized())
    return success();

  if (auto push = dyn_cast<list::PushBackOp>(op)) {
    next.markNonEmpty(push.getResult());
  } else if (auto concat = dyn_cast<list::ConcatOp>(op)) {
    if (next.contains(concat.getLhs()) || next.contains(concat.getRhs()))
      next.markNonEmpty(concat.getResult());
  }

  set(after, next);
  return success();
}

/// If `condition` compares list.length with zero, return the list when taking
/// the edge where the comparison proves it non-empty.
static Value getListProvenNonEmpty(Value condition, bool conditionIsTrue) {
  auto compare = condition.getDefiningOp<arith::CmpIOp>();
  if (!compare)
    return {};

  arith::CmpIPredicate predicate = compare.getPredicate();
  if (predicate != arith::CmpIPredicate::eq &&
      predicate != arith::CmpIPredicate::ne)
    return {};

  list::LengthOp length;
  if (matchPattern(compare.getRhs(), m_Zero()))
    length = compare.getLhs().getDefiningOp<list::LengthOp>();
  else if (matchPattern(compare.getLhs(), m_Zero()))
    length = compare.getRhs().getDefiningOp<list::LengthOp>();
  if (!length)
    return {};

  bool comparisonMeansNonEmpty = predicate == arith::CmpIPredicate::ne;
  return conditionIsTrue == comparisonMeansNonEmpty ? length.getInput()
                                                    : Value();
}

void ListNonEmptyPathAnalysis::visitBlockTransfer(
    Block *block, ProgramPoint *, Block *predecessor,
    const NonEmptyPathLattice &before, NonEmptyPathLattice *after) {
  NonEmptyPathValue next = before.getValue();
  if (next.isUninitialized())
    return;

  if (auto branch = dyn_cast<cf::CondBranchOp>(predecessor->getTerminator())) {
    bool isTrueEdge = branch.getTrueDest() == block;
    bool isFalseEdge = branch.getFalseDest() == block;

    // If both destinations are the same block, the predecessor relation does
    // not identify which edge was taken and no path fact may be assumed.
    if (isTrueEdge != isFalseEdge) {
      if (Value list = getListProvenNonEmpty(branch.getCondition(), isTrueEdge))
        next.markNonEmpty(list);
    }
  }

  set(after, next);
}

bool isKnownNonEmptyBefore(DataFlowSolver &solver, Operation *op, Value value) {
  ProgramPoint *point = solver.getProgramPointBefore(op);
  const auto *lattice = solver.lookupState<NonEmptyPathLattice>(point);
  return lattice && !lattice->getValue().isUninitialized() &&
         lattice->getValue().contains(value);
}

} // namespace mlir::tutorial::analysis
