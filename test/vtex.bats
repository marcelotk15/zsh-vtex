#!/usr/bin/env bats
# Requires bats-core. If missing, use: zsh test/runner.zsh or ./scripts/test.sh

setup() {
  export PLUGIN_ROOT
  PLUGIN_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
}

@test "native runner — full suite" {
  run zsh +o verbose +o xtrace -f "${PLUGIN_ROOT}/test/runner.zsh"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"0 failure"* ]]
}
