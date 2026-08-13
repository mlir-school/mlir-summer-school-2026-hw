#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${BUILD_DIR:-${repo_root}/build}"
test_dir="${build_dir}/test/analysis/integer-range"

if [[ ! -d "${test_dir}" ]]; then
  echo "error: ${test_dir} is missing; configure the build directory first" >&2
  exit 1
fi

if [[ -n "${LIT:-}" ]]; then
  lit="${LIT}"
elif command -v lit >/dev/null 2>&1; then
  lit="$(command -v lit)"
elif [[ -x "${repo_root}/.venv/bin/lit" ]]; then
  lit="${repo_root}/.venv/bin/lit"
elif [[ -x "${repo_root}/.env/bin/lit" ]]; then
  lit="${repo_root}/.env/bin/lit"
else
  echo "error: lit was not found; activate the project virtual environment or set LIT" >&2
  exit 1
fi

"${lit}" -v "${test_dir}"
