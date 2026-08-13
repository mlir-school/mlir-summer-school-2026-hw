# Exercise 1 — Writing `linalg.generic`

Map real computations onto `linalg.generic`. Every file has `???` placeholders
to replace.

| File | Computation | New idea |
| --- | --- | --- |
| `01-matmul.mlir` | `C[i,j] += A[i,k] * B[k,j]` | a reduction iterator |
| `02-matmul-add.mlir` | `D = A*B + C` | why this is **two** operations |
| `03-conv-nhwc.mlir` | NHWC convolution | maps that add induction variables |
| `04-conv-nchw.mlir` | NCHW convolution (bonus) | layout is just a change of maps |

## Running

```bash
lit build/test --filter=ex1 -v
```

All four start red. That is the exercise.

## How the checking works

There is no answer key to peek at during the exercise — an existing pass decides
whether you got it right.

- `01` and `02` use `--linalg-specialize-generic-ops`, which folds well-known
  computations back into named ops. A correct matmul becomes a bare
  `linalg.matmul`. A *nearly* correct one (say, with `B` transposed) still
  becomes a `linalg.matmul`, but one carrying an explicit `indexing_maps`
  attribute — which will not match.
- `03` and `04` use `--linalg-generalize-named-ops` on an upstream named op
  sitting in the same file. MLIR gives structurally identical affine maps the
  same `#map` alias, so if your maps match the reference exactly, both functions
  print the same aliases. The CHECK lines compare them.
