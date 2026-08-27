# Prompt segment formatting.
#
# Tokens in VTEX_PROMPT_FORMAT:
#   {account} {workspace} {context} {symbol} {color} {reset}
#
# Defaults:
#   VTEX_PROMPT_FORMAT='[{color}{symbol}{context}{reset}]'
#   VTEX_PROMPT_SYMBOL=''   (opt-in, e.g. $'\uf07a ')
#   VTEX_PROMPT_COLOR='205'

# Safe substring replace (zsh ${//} breaks when replacement contains '}').
_vtex_replace_all() {
  emulate -L zsh

  local hay="$1"
  local needle="$2"
  local repl="$3"
  local result=""

  if [[ -z $needle ]]; then
    REPLY="$hay"
    return 0
  fi

  while [[ $hay == *"$needle"* ]]; do
    result+="${hay%%"${needle}"*}${repl}"
    hay="${hay#*"${needle}"}"
  done

  REPLY="${result}${hay}"
}

_vtex_format_segment() {
  emulate -L zsh

  # $1 = 1 to emit zsh color sequences, 0 for plain text
  local use_color="${1:-1}"
  local account="${2-}"
  local workspace="${3-}"

  # Quote the default: an unquoted '}' inside ${var:-...} ends the expansion early.
  local fmt="${VTEX_PROMPT_FORMAT:-"[{color}{symbol}{context}{reset}]"}"
  local symbol="${VTEX_PROMPT_SYMBOL-}"
  local color="${VTEX_PROMPT_COLOR:-205}"
  local color_seq=""
  local reset_seq=""
  local context=""
  local out=""

  [[ -n $fmt ]] || fmt='[{color}{symbol}{context}{reset}]'
  [[ -n $color ]] || color="205"

  if (( use_color )); then
    color_seq="%F{${color}}"
    reset_seq="%f"
  fi

  context="${account}@${workspace}"
  out="$fmt"

  # Expand structural tokens first so account/workspace cannot inject them.
  _vtex_replace_all "$out" '{color}' "$color_seq"
  out="$REPLY"
  _vtex_replace_all "$out" '{reset}' "$reset_seq"
  out="$REPLY"
  _vtex_replace_all "$out" '{symbol}' "$symbol"
  out="$REPLY"

  # Data tokens last.
  _vtex_replace_all "$out" '{context}' "$context"
  out="$REPLY"
  _vtex_replace_all "$out" '{account}' "$account"
  out="$REPLY"
  _vtex_replace_all "$out" '{workspace}' "$workspace"
  out="$REPLY"

  REPLY="$out"
}

_vtex_prompt_segment() {
  emulate -L zsh

  # $1 = 1 colored (zsh prompt), 0 plain
  local use_color="${1:-1}"
  local account=""
  local workspace=""

  REPLY=""

  _vtex_read_account_workspace

  account="${reply[1]-}"
  workspace="${reply[2]-}"

  [[ -n $account && -n $workspace ]] || return 1

  vtex_in_project || return 1

  _vtex_format_segment "$use_color" "$account" "$workspace"
  return 0
}

vtex_prompt_info() {
  emulate -L zsh

  _vtex_prompt_segment 1 || return 0
  print -r -- "$REPLY"
}

vtex_prompt_plain() {
  emulate -L zsh

  _vtex_prompt_segment 0 || return 0
  print -r -- "$REPLY"
}
