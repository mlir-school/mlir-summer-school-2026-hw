//===- ListIntegerRangeAnalysis.cpp - Size-aware integer ranges ----------===//

#include "analysis/integer-range/ListIntegerRangeAnalysis.h"

#include "analysis/size-range/SizeRangeAnalysis.h"
#include "list/IR/List.h"

#include <algorithm>

using namespace mlir;

namespace mlir::tutorial::analysis {

LogicalResult ListIntegerRangeAnalysis::visitOperation(
    Operation *op,
    ArrayRef<const dataflow::IntegerValueRangeLattice *> operands,
    ArrayRef<dataflow::IntegerValueRangeLattice *> results) {
  auto length = dyn_cast<list::LengthOp>(op);
  if (!length)
    return IntegerRangeAnalysis::visitOperation(op, operands, results);

  // Register a dependency so this transfer function is revisited whenever the
  // size analysis learns more about the input list.
  const auto *size = getOrCreateFor<SizeRangeLattice>(getProgramPointAfter(op),
                                                      length.getInput());
  const SizeRangeValue &sizeRange = size->getValue();
  if (sizeRange.isUninitialized())
    return success();

  unsigned width = ConstantIntRanges::getStorageBitwidth(length.getType());
  APInt signedMaximum = APInt::getSignedMaxValue(width);
  uint64_t maximum = signedMaximum.getZExtValue();

  // list.length is non-negative and its i32 result is bounded by INT32_MAX.
  // If a size bound exceeds what the result type can represent, retain that
  // conservative type bound.
  uint64_t lower = sizeRange.getLower() <= maximum ? sizeRange.getLower() : 0;
  uint64_t upper = maximum;
  if (std::optional<uint64_t> sizeUpper = sizeRange.getUpper())
    upper = std::min(*sizeUpper, maximum);
  if (lower > upper)
    lower = 0;

  ConstantIntRanges range =
      ConstantIntRanges::fromSigned(APInt(width, lower), APInt(width, upper));
  propagateIfChanged(results.front(), results.front()->join(
                                          IntegerValueRange(std::move(range))));
  return success();
}

} // namespace mlir::tutorial::analysis
