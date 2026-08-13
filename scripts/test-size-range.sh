#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${BUILD_DIR:-${repo_root}/build}"
test_root="${build_dir}/test"

if [[ ! -f "${test_root}/lit.site.cfg.py" ]]; then
  echo "error: ${test_root} is not a configured lit test directory" >&2
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

"${lit}" -v "${test_root}" --filter='analysis/size-range/main\.mlir$'
