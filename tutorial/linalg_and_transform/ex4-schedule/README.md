# Exercise 4 — Writing a schedule

Take the matmul + add payload from exercise 1b and schedule it: tile the
consumer, fuse the producers into the tile loops, then tile again for registers.

## What you edit

Only `schedule.mlir`. `payload.mlir` is the algorithm and stays untouched — that
separation is the point. The schedule is loaded with
`--transform-preload-library`, so changing it needs no rebuild of anything.

## Running

```bash
lit build/test --filter=ex4 -v
```

## The steps

1. Match the `linalg.add` carrying `__root__`.
2. Match `linalg.fill` and `linalg.matmul`, both carrying `__producer__`.
3. Tile the root with `[8, 16]`.
4. Fuse the producers into the generated loop nest.
5. *(optional)* Print the payload with your exercise 3 operation.
6. Tile the root again with `[4, 4]`.

The result is an `[8, 16]` loop nest with `fill` and `matmul` computing just the
current tile, and a `[4, 4]` nest around the add. The CHECK lines pin the tile
sizes, so the test verifies the schedule rather than merely that some loops
appeared.

## Where people get stuck

- **Handle invalidation.** `tile_using_for` *consumes* the handle you give it.
  After step 3 the handle from step 1 is dead; step 6 has to start from the
  handle step 3 returned. Add `--transform-dialect-check-uses` to the RUN line
  to have this diagnosed properly instead of as a confusing downstream error.
- **Result arity.** `tile_using_for` with two tile sizes returns three values:
  the tiled op and two loops. Getting the `-> (...)` type list wrong is the most
  common parse error here.
- **Noise.** Without `--canonicalize --cse` the output is roughly sixty lines of
  `affine.apply` and duplicate `tensor.dim`. They are already in the RUN line;
  drop them once to see why.

## Going further

Lower the scheduled payload and check that your mental model still holds:

```bash
build/tutorial/tutorial-opt tutorial/linalg_and_transform/ex4-schedule/payload.mlir \
  --transform-preload-library=transform-library-paths=tutorial/linalg_and_transform/ex4-schedule/schedule.mlir \
  --transform-interpreter --canonicalize --cse \
  --linalg-generalize-named-ops \
  --one-shot-bufferize="bufferize-function-boundaries" \
  --convert-linalg-to-loops
```

That takes it all the way down to `memref.load` / `arith.mulf` / `memref.store`
inside the tile loops.

Then try editing only `schedule.mlir` — different tile sizes, fusing into
`%loops#1` instead of `%loops#0`, or skipping step 6 — and watch the generated
code change while the algorithm stays exactly as written.
