# MLIR Wheel Tutorial

This repository is a small showcase for building an out-of-tree MLIR dialect
against the packaged `mlir-wheel` release instead of a local LLVM/MLIR source
tree.

The tutorial dialect lives in `tutorial/list/IR`, split across the files that an in-tree MLIR dialect would also use:

| File              | Contents                                                                           |
|-------------------|------------------------------------------------------------------------------------|
| `ListDialect.td`  | the `list` dialect itself                                                          |
| `ListTypes.td`    | `!list.list<T>`, a list of integers of a fixed element type                        |
| `ListOps.td`      | one `def` per operation                                                            |
| `ListDialect.cpp` | dialect registration, `initialize()`                                               |
| `ListOps.cpp`     | the hand-written parts of operations: builders, verifiers, custom assembly formats |
| `List.h`          | includes the generated `.h.inc` files                                              |

Its TableGen file defines the entire dialect surface:

- `!list.list<T>`: a parameterized list type.
- `list.empty`: creates an empty list.
- `list.push_back`: appends one value to a list.
- `list.length`: returns a list length as `i32`.

## Setup

Create and activate a virtual environment:

```bash
python3 -m venv .env
source .env/bin/activate
```

Install the Python packages:

```bash
pip install -r requirements.txt
```

Check that the MLIR wheel is available:

```bash
python -m mlir_wheel --root-dir
```

## Build

Configure CMake against the MLIR wheel:

```bash
cmake -S . -B build \
  -DCMAKE_PREFIX_PATH=$(python -m mlir_wheel --root-dir) \
  -DLLVM_EXTERNAL_LIT=$(which lit)
```

Build `tutorial-opt`:

```bash
cmake --build build --target tutorial-opt
```

Run the list dialect roundtrip tests:

```bash
cmake --build build --target check-tutorial-list
```

Run all tutorial tests:

```bash
cmake --build build --target check-tutorial
```

## Try It

Roundtrip a list dialect example through `tutorial-opt`:

```bash
build/tutorial/tutorial-opt test/list/roundtrip.mlir
```

The test file uses `FileCheck` to verify that the custom list type and list
operations parse and print correctly.
