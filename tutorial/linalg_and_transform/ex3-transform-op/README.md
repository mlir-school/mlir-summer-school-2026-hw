# Exercise 3 — A transform operation

Everyone makes mistakes in a schedule. This exercise builds the tool for seeing
what a schedule is actually doing: a transform operation that reports which
payload operations a handle is currently associated with.

This is the only exercise that compiles C++.

## What you edit

Just one function: `PrintHandleOp::apply` in `PrintHandleOp.cpp`. Everything
else is already wired up:

| File | Role |
| --- | --- |
| `TutorialTransformOps.td` | the op definition — read it, you do not need to change it |
| `TutorialTransformExtension.cpp` | registers the op with the transform dialect |
| `PrintHandleOp.cpp` | **your work goes here** |
| `test/print-handle.mlir` | the tests |

## Running

```bash
lit build/test --filter=ex3 -v
```

Before you start, this fails with a definite failure pointing at the file to
edit. When you are done, three test cases pass.

## What the op should do

For each payload operation associated with `target`, emit a remark of the form

```
<message> (<i> of <n>): <op name>
```

Emitting a *remark at the payload operation* rather than printing to stdout is
what attaches a source location to the output, and it is what lets the tests
check the result with `-verify-diagnostics`.

## Things worth noticing

- **A handle is a set.** The first test matches two `linalg.matmul` ops with a
  single `transform.structured.match`, so one `print_handle` has to report both.
  This is the part of the transform model that most often explains a schedule
  behaving unexpectedly.
- **`NavigationTransformOpTrait`** in the TableGen definition is what makes this
  op read-only, so it can be dropped anywhere into a schedule without killing
  the handle. Remove it and the second test fails. It also supplies
  `getEffects()` for free, which is why there is nothing to implement but
  `apply`.
- **Three ways to fail.** `success`, silenceable failure (recoverable by an
  enclosing op) and definite failure (payload is now inconsistent, abort). They
  are not interchangeable; the comment in `PrintHandleOp.cpp` spells out when to
  use which.
- Upstream has `transform.print` and `transform.debug.emit_remark_at`, which do
  related things. Read `DebugExtensionOps.td` in the MLIR include directory
  afterwards to compare.

## Reference solution

On the `solutions/day-4-session-4` branch, in this same file.
