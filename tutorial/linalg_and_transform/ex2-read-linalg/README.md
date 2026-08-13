# Exercise 2 — Reading `linalg.generic`

The reverse of exercise 1: given a generic, work out the loop nest it stands
for.

Instead of writing the loop nest in prose, you write it as `CHECK` lines and let
FileCheck grade the prediction.

| File | Shape | New idea |
| --- | --- | --- |
| `01-matmul.mlir` | matmul | loop structure given, predict the subscripts |
| `02-linear.mlir` | batched matmul, transposed weights | predict the loop counts too |
| `03-row-sum.mlir` | row reduction | an output map that drops a dimension |

## Running

```bash
lit build/test --filter=ex2 -v
```

## Reading the lowering

The RUN lines bufferize and then use `--convert-linalg-to-parallel-loops`, which
makes `iterator_types` visible in the output:

- all `"parallel"` iterators become a single combined `scf.parallel`
- each `"reduction"` iterator becomes an `scf.for` nested inside it

The subscripts on the `memref.load` operations are exactly what the indexing
maps said: map dimension *n* becomes induction variable *n*.

If you want the plainer version without the parallel/reduction distinction, swap
in `--convert-linalg-to-affine-loops`.
