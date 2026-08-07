# Linalg and the Transform dialect

Day 4, session 4. The thread running through all four exercises is the
separation of **algorithm** from **schedule**: what is computed versus how it is
executed.

| | Exercise | Builds C++ |
| --- | --- | --- |
| 1 | [Writing `linalg.generic`](ex1-linalg-generic) — matmul, matmul+add, convolution | no |
| 2 | [Reading `linalg.generic`](ex2-read-linalg) — predict the loop nest | no |
| 3 | [A transform operation](ex3-transform-op) — printf-debug a schedule | **yes** |
| 4 | [Writing a schedule](ex4-schedule) — tile and fuse matmul+add | no |

## Running

```bash
cmake --build build --target check-linalg-and-transform   # all four
lit build/test --filter=ex1 -v                            # just one
```

Everything starts red. Solving an exercise turns it green; that is the whole
feedback loop. No exercise is graded by eye — each one is checked by an existing
MLIR pass, so the tooling tells you whether you are right.

The reference answers live on the `solutions/day-4-session-4` branch, as the
same files filled in:

```bash
git diff exercises/day-4-session-4 solutions/day-4-session-4
```

## How they connect

Exercise 1b asks for `D = A*B + C` and the answer turns out to be *two* linalg
operations, because the elementwise add cannot live inside the matmul's
reduction. That pair is exactly the payload you schedule in exercise 4, where
tiling and fusion recover the locality of a single fused loop nest without ever
touching the algorithm.

Exercise 2 is exercise 1 read backwards, and it is what makes the indexing maps
in exercise 4's output legible.

Exercise 3 builds the instrument for exercise 4: once
`transform.tutorial.print_handle` works, step 5 of the schedule can print what
the payload looks like mid-flight. Step 5 is commented out by default, so
exercise 4 stands on its own if you skip exercise 3.

## What you need

Exercises 1, 2 and 4 are plain `.mlir` files run by `mlir-opt` and `FileCheck`
from the MLIR wheel — no compilation. Only exercise 3 builds C++, and there the
skeleton compiles as given; a single function body is missing.
