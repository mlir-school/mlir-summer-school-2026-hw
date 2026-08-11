# Exercises: MLIR operation interfaces

## Exercise 1: defining and using an interface

Use `ListLengthOpInterface` to infer the length of a list statically and fold
`list.length` into an integer constant.

The interface definition and build setup are provided. `list.empty` is a
complete reference: the interface is attached to the operation in
`tutorial/list/IR/ListOps.td`, and `EmptyOp::getStaticLength()` is implemented
in `tutorial/list/IR/ListOps.cpp`.

Complete the Exercise 1 TODOs in those two files:

1. Attach `ListLengthOpInterface` to `list.from_elements`, `list.map`,
   `list.reverse`, and `list.push_back`.
2. Implement `getStaticLength()` for each operation. Mapping and reversing
   preserve the input length; pushing an element increases it by one.
3. Implement the `list.length` folder by querying the input's defining
   operation through `ListLengthOpInterface`. Do not fold when the input has no
   defining operation or its length is unknown.

## Exercise 2: external interface models

Extend the analysis to find the length of a constant `list.range`. The range is
half-open, `[lower, upper)`, and its length is `max(upper - lower, 0)`.

The `ConstantIntOpInterface`, external-model skeleton, registry extension, and
registration call are provided. Complete the Exercise 2 TODOs:

1. In `tutorial/list/IR/ListExternalModels.cpp`, implement
   `ArithConstantIntModel::getConstantIntValue()`. Cast the supplied operation
   to `arith::ConstantOp`; return its value when it holds an `IntegerAttr`, and
   return `std::nullopt` otherwise.
2. In the same file, attach `ArithConstantIntModel` to `arith::ConstantOp`
   inside the provided registry extension.
3. In `ListOps.td`, attach `ListLengthOpInterface` to `list.range`.
4. In `ListOps.cpp`, implement `RangeOp::getStaticLength()`. Query both bounds'
   defining operations through `ConstantIntOpInterface`. Return
   `std::nullopt` if either bound is unknown.

The direct, chained, and unknown cases in `test/list/interfaces.mlir` and
`test/list/external-models.mlir` are the completion criteria:

```bash
cmake --build build --target check-tutorial-list
```
