#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${BUILD_DIR:-${repo_root}/build}"
tutorial_opt="${build_dir}/tutorial/tutorial-opt"
test_file="${repo_root}/test/analysis/size-range/main.mlir"

if [[ ! -x "${tutorial_opt}" ]]; then
  echo "error: ${tutorial_opt} is missing; build the tutorial-opt target first" >&2
  exit 1
fi

"${tutorial_opt}" --print-list-size-range-analysis "${test_file}"
