#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if command -v bats >/dev/null 2>&1; then
  exec bats test/vtex.bats
fi
exec zsh +o verbose +o xtrace -f "${ROOT}/test/runner.zsh"
