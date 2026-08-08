# MLIR Summer School 2026 Homework

The `main` branch is a small smoke test for the course toolchain. Building it
and running its test verifies that the MLIR wheel, CMake, the C++ compiler,
TableGen, lit, and FileCheck are all working together correctly.

The actual homework is on branches named `exercises/day-X-session-Y`, with
completed versions on the corresponding `solutions/day-X-session-Y` branches.
For example:

```bash
git switch exercises/day-2-session-1
git switch solutions/day-2-session-1
```

## Download

Clone the repository and enter it:

```bash
git clone https://github.com/mlir-school/mlir-summer-school-2026-hw.git
cd mlir-summer-school-2026-hw
```

## Setup

Install [`uv`](https://docs.astral.sh/uv/getting-started/installation/) if it is
not already available:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Use uv to install Python 3.12, create an isolated environment, and install the
required packages. Do not use the system Python for this project.

```bash
uv python install 3.12
uv venv --python 3.12
uv pip install -r requirements.txt
```

Check that the MLIR wheel is available:

```bash
.venv/bin/python -m mlir_wheel --root-dir
```

## Build

Configure CMake against the MLIR wheel:

```bash
cmake -S . -B build \
  -DCMAKE_PREFIX_PATH=$(.venv/bin/python -m mlir_wheel --root-dir) \
  -DLLVM_EXTERNAL_LIT=$(pwd)/.venv/bin/lit
```

Build the minimal `tutorial-opt` tool:

```bash
cmake --build build --target tutorial-opt
```

## Check your installation

Run the lit and FileCheck smoke test:

```bash
cmake --build build --target check-tutorial
```

A successful run reports `Passed: 1 (100.00%)`. The test parses and prints a
single `tutorial.constant` operation using the custom `tutorial-opt` binary and
checks its output with FileCheck.
