# Exercise: MLIR operation interfaces

In this exercise, you will use an operation interface to infer the length of a
list statically and fold `list.length` into an integer constant.

The list dialect provides `ListLengthOpInterface` in
`tutorial/list/IR/ListInterfaces.td`. An operation implementing this interface
can report the statically known length of the list it produces.

`list.empty` shows the complete setup: the interface is attached to the
operation in `ListOps.td`, and `EmptyOp::getStaticLength()` is implemented in
`ListOps.cpp`.

Complete the TODOs in those two files:

1. Attach `ListLengthOpInterface` to `list.from_elements`, `list.map`,
   `list.reverse`, and `list.push_back`.
2. Implement `getStaticLength()` for each operation. Mapping and reversing
   preserve the input length; pushing an element increases it by one.
3. Implement the `list.length` folder by querying the input's defining
   operation through `ListLengthOpInterface`. Do not fold when the input has no
   defining operation or its length is unknown.

The direct, chained, and unknown-length cases in `test/list/interfaces.mlir`
are the completion criteria:

```bash
cmake --build build --target check-tutorial-list
```
