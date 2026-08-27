#!/usr/bin/env zsh
# Native zsh test harness (no Bats required). Usage: zsh test/runner.zsh

emulate -L zsh
unsetopt xtrace 2>/dev/null || true

PLUGIN_ROOT="$(cd "${0:a:h}/.." && pwd)"

# Isolate from developer exports (e.g. VTEX_PROMPT_SYMBOL in ~/.zshrc).
unset \
  VTEX_CONFIG_FILE \
  VTEX_REQUIRE_MANIFEST \
  VTEX_PROMPT_FORMAT \
  VTEX_PROMPT_SYMBOL \
  VTEX_PROMPT_COLOR

integer _tests=0 _failures=0

_fail() {
  print -r -- "FAIL: $1"
  print -r -- "  expected: ${(q-)2}"
  print -r -- "  got:      ${(q-)3}"
  ((_failures++))
}

_assert_eq() {
  ((_tests++))
  if [[ $1 != "$2" ]]; then
    _fail "$3" "$2" "$1"
  fi
}

_assert_exit() {
  ((_tests++))
  if [[ $1 -ne $2 ]]; then
    _fail "$3" "exit $2" "exit $1"
  fi
}

print -r -- "zsh-vtex tests (plugin root: $PLUGIN_ROOT)"

# 1) Missing config
{
  local home
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  local out
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_prompt_info)x\$(vtex_account)x\"
  ")
  _assert_eq "$out" "xx" "prompt + account empty when config missing"
}

# 2) Account + workspace
{
  local home
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  local out
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_account)\"
    print -r -- \"\$(vtex_workspace)\"
    print -r -- \"\$(vtex_context)\"
  ")
  _assert_eq "$out" $'myaccount\nmyworkspace\nmyaccount@myworkspace' "account, workspace, context"
}

# 3) Missing workspace
{
  local home
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-no-workspace.json" "$home/.config/configstore/vtex.json"
  local out
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_prompt_info)\"
  ")
  _assert_eq "$out" "" "prompt empty without workspace"
}

# 4) jq available (valid JSON)
{
  local home
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  local out
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_account)\"
  ")
  _assert_eq "$out" "myaccount" "jq parses account when JSON is valid"
}

# 5) No jq on PATH (regex fallback, single-line JSON)
{
  local home emptypath out zsh_bin
  home=$(mktemp -d)
  emptypath=$(mktemp -d)
  zsh_bin=$(whence -p zsh)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-oneline-fallback.json" "$home/.config/configstore/vtex.json"
  out=$(PATH="$emptypath" HOME=$home "$zsh_bin" +o verbose +o xtrace -f -c "
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_account)\"
    print -r -- \"\$(vtex_workspace)\"
  ")
  local -a lines
  lines=(${(f)out})
  _assert_eq "${lines[1]-}" "fbacc" "fallback account without jq"
  _assert_eq "${lines[2]-}" "fbws" "fallback workspace without jq"
}

# 6) Invalid JSON — no abort; stderr quiet from the user's perspective
{
  local home errf out errsize
  home=$(mktemp -d)
  errf=$(mktemp)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-invalid.json" "$home/.config/configstore/vtex.json"
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\" 2>\"$errf\"
    print -r -- \"\$(vtex_account)\"
    print -r -- \"\$(vtex_prompt_info)\"
  ")
  errsize=$(wc -c <"$errf" | tr -d ' ')
  rm -f "$errf"
  local -a lines
  lines=(${(f)out})
  _assert_eq "${lines[1]-}" "" "invalid JSON yields empty account"
  _assert_eq "${lines[2]-}" "" "invalid JSON yields empty prompt"
  ((_tests++))
  if [[ $errsize != 0 ]]; then
    _fail "stderr from plugin on invalid JSON" "0 bytes" "${errsize} bytes"
  fi
}

# 7) Manifest ancestral — default format (no symbol)
{
  local home proj out
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  proj=$(mktemp -d)
  print -r -- '{}' >"$proj/manifest.json"
  mkdir -p "$proj/sub/deep"
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    cd \"$proj/sub/deep\"
    print -r -- \"\$(vtex_prompt_info)\"
  ")
  _assert_eq "$out" '[%F{205}myaccount@myworkspace%f]' "prompt with ancestor manifest"
}

# 8) Outside a VTEX project
{
  local home nowhere out
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  nowhere=$(mktemp -d)
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    cd \"$nowhere\"
    print -r -- \"\$(vtex_prompt_info)\"
  ")
  _assert_eq "$out" "" "prompt empty outside VTEX project (default require manifest)"
}

# 9) VTEX_REQUIRE_MANIFEST=false
{
  local home nowhere out
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  nowhere=$(mktemp -d)
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    export VTEX_REQUIRE_MANIFEST=false
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    cd \"$nowhere\"
    print -r -- \"\$(vtex_prompt_info)\"
  ")
  _assert_eq "$out" '[%F{205}myaccount@myworkspace%f]' "VTEX_REQUIRE_MANIFEST=false"
}

# 10) VTEX_PROMPT_COLOR
{
  local home out
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    export VTEX_REQUIRE_MANIFEST=false
    export VTEX_PROMPT_COLOR=cyan
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_prompt_info)\"
  ")
  _assert_eq "$out" '[%F{cyan}myaccount@myworkspace%f]' "VTEX_PROMPT_COLOR=cyan"
}

# 11) VTEX_PROMPT_FORMAT custom
{
  local home out
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    export VTEX_REQUIRE_MANIFEST=false
    export VTEX_PROMPT_FORMAT='{account}/{workspace}'
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_prompt_info)\"
  ")
  _assert_eq "$out" 'myaccount/myworkspace' "VTEX_PROMPT_FORMAT custom"
}

# 12) VTEX_PROMPT_SYMBOL
{
  local home out
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    export VTEX_REQUIRE_MANIFEST=false
    export VTEX_PROMPT_SYMBOL='X '
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_prompt_info)\"
  ")
  _assert_eq "$out" '[%F{205}X myaccount@myworkspace%f]' "VTEX_PROMPT_SYMBOL set"
}

# 13) vtex_prompt_plain — no color sequences
{
  local home out
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    export VTEX_REQUIRE_MANIFEST=false
    export VTEX_PROMPT_SYMBOL='* '
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    print -r -- \"\$(vtex_prompt_plain)\"
  ")
  _assert_eq "$out" '[* myaccount@myworkspace]' "vtex_prompt_plain without color"
  ((_tests++))
  if [[ $out == *'%F{'* || $out == *'%f'* ]]; then
    _fail "vtex_prompt_plain has no %F/%f" "no color sequences" "$out"
  fi
}

# 14) vtex_in_project inside / outside
{
  local home proj nowhere code_in code_out
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  proj=$(mktemp -d)
  print -r -- '{}' >"$proj/manifest.json"
  nowhere=$(mktemp -d)

  code_in=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    cd \"$proj\"
    vtex_in_project
    print -r -- \$?
  ")
  code_out=$(HOME=$home zsh +o verbose +o xtrace -f -c "
    export HOME=$home
    source \"$PLUGIN_ROOT/vtex.plugin.zsh\"
    cd \"$nowhere\"
    vtex_in_project
    print -r -- \$?
  ")
  _assert_eq "$code_in" "0" "vtex_in_project inside project"
  _assert_eq "$code_out" "1" "vtex_in_project outside project"
}

# 15) bin/vtex-context
{
  local home proj nowhere out code
  home=$(mktemp -d)
  mkdir -p "$home/.config/configstore"
  cp "$PLUGIN_ROOT/test/fixtures/vtex-valid.json" "$home/.config/configstore/vtex.json"
  proj=$(mktemp -d)
  print -r -- '{}' >"$proj/manifest.json"
  nowhere=$(mktemp -d)

  out=$(cd "$proj" && HOME=$home "$PLUGIN_ROOT/bin/vtex-context")
  code=$?
  _assert_eq "$out" "myaccount@myworkspace" "bin/vtex-context output inside project"
  _assert_exit "$code" 0 "bin/vtex-context exit 0 inside project"

  out=$(cd "$nowhere" && HOME=$home "$PLUGIN_ROOT/bin/vtex-context" 2>/dev/null)
  code=$?
  _assert_eq "$out" "" "bin/vtex-context empty outside project"
  _assert_exit "$code" 1 "bin/vtex-context exit 1 outside project"

  out=$(cd "$nowhere" && HOME=$home VTEX_REQUIRE_MANIFEST=false "$PLUGIN_ROOT/bin/vtex-context")
  code=$?
  _assert_eq "$out" "myaccount@myworkspace" "bin/vtex-context with REQUIRE_MANIFEST=false"
  _assert_exit "$code" 0 "bin/vtex-context exit 0 with REQUIRE_MANIFEST=false"
}

print -r -- ""
print -r -- "Ran $_tests assertions, $_failures failure(s)."
if ((_failures)); then
  exit 1
fi
