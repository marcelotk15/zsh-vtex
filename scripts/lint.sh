#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ShellCheck is not a full Zsh parser; exclusions below cover valid Zsh
# idioms that the analyzer flags as errors (nested expansions, $fpath,
# $match[n], assoc keys, literal ~/ patterns, etc.).

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck not found; skipping lint." >&2
  exit 0
fi

shellcheck scripts/*.sh

# SC1091: sibling sources (libs); SC2034/SC2154: zsh vars ($match, ${( )} uses);
# SC2181: $? style; SC2206: intentional $fpath splice;
# SC2296/SC2298: ${${(%):-%N}:A:h} and friends; SC1087: zsh $arr[i];
# SC2088: literal ~/ match; SC2004: assoc keys with $var.
shellcheck -s bash \
  -e SC1091,SC2034,SC2154,SC2181,SC2206,SC2296,SC2298,SC1087,SC2088,SC2004 \
  vtex.plugin.zsh \
  lib/*.zsh \
  bin/vtex-context \
  functions/*
