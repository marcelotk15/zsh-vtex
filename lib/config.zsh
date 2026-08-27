_vtex_resolve_config_path() {
  emulate -L zsh

  local path

  if (( ${+VTEX_CONFIG_FILE} )); then
    path="$VTEX_CONFIG_FILE"

    case "$path" in
      '~')
        [[ -n ${HOME-} ]] || {
          REPLY=""
          return 1
        }
        path="$HOME"
        ;;
      '~/'*)
        [[ -n ${HOME-} ]] || {
          REPLY=""
          return 1
        }
        path="${HOME}/${path#\~/}"
        ;;
    esac
  else
    [[ -n ${HOME-} ]] || {
      REPLY=""
      return 1
    }

    path="${HOME}/.config/configstore/vtex.json"
  fi

  REPLY="${path:a}"
}

_vtex_resolved_config_path() {
  emulate -L zsh

  _vtex_resolve_config_path || return 0
  print -r -- "$REPLY"
}

_vtex_regex_extract() {
  emulate -L zsh
  setopt local_options extended_glob

  local flat="$1"
  local key="$2"
  local pattern='"'${key}'"[[:space:]]*:[[:space:]]*"([^"]*)"'

  REPLY=""

  if [[ $flat =~ $pattern ]]; then
    REPLY="$match[1]"
    return 0
  fi

  return 1
}

_vtex_read_account_workspace_uncached() {
  emulate -L zsh

  local cfg="$1"
  local content=""
  local account=""
  local workspace=""

  reply=("" "")

  [[ -r $cfg ]] || return 0

  content="$(<"$cfg")" 2>/dev/null || return 0

  if command -v jq >/dev/null 2>&1; then
    local jq_output=""

    jq_output="$(
      jq -r '
        [
          (.account // .Account // ""),
          (.workspace // .Workspace // "")
        ] | @tsv
      ' "$cfg" 2>/dev/null
    )"

    if (( $? == 0 )); then
      local -a values
      values=("${(@ps:\t:)jq_output}")

      account="${values[1]-}"
      workspace="${values[2]-}"

      reply=("$account" "$workspace")
      return 0
    fi
  fi

  local flat="${content//$'\n'/}"

  _vtex_regex_extract "$flat" account
  account="$REPLY"

  _vtex_regex_extract "$flat" workspace
  workspace="$REPLY"

  reply=("$account" "$workspace")
}

_vtex_read_account_workspace() {
  emulate -L zsh

  local cfg=""
  local mtime=""

  reply=("" "")

  _vtex_resolve_config_path || return 0
  cfg="$REPLY"

  [[ -r $cfg ]] || {
    if [[ $_VTEX_CACHE_CONFIG_PATH != "$cfg" ]]; then
      _vtex_clear_config_cache
      _VTEX_CACHE_CONFIG_PATH="$cfg"
    fi
    return 0
  }

  if _vtex_file_mtime "$cfg"; then
    mtime="$REPLY"
  fi

  if [[
    $_VTEX_CACHE_CONFIG_PATH == "$cfg" &&
    -n $mtime &&
    $_VTEX_CACHE_CONFIG_MTIME == "$mtime"
  ]]; then
    reply=(
      "$_VTEX_CACHE_ACCOUNT"
      "$_VTEX_CACHE_WORKSPACE"
    )
    return 0
  fi

  _vtex_read_account_workspace_uncached "$cfg"

  _VTEX_CACHE_CONFIG_PATH="$cfg"
  _VTEX_CACHE_CONFIG_MTIME="$mtime"
  _VTEX_CACHE_ACCOUNT="${reply[1]-}"
  _VTEX_CACHE_WORKSPACE="${reply[2]-}"
}
