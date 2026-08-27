# Internal caches used by the plugin.

typeset -g _VTEX_CACHE_CONFIG_PATH=""
typeset -g _VTEX_CACHE_CONFIG_MTIME=""
typeset -g _VTEX_CACHE_ACCOUNT=""
typeset -g _VTEX_CACHE_WORKSPACE=""

typeset -gA _VTEX_PROJECT_ROOT_CACHE

_vtex_file_mtime() {
  emulate -L zsh

  local path="$1"
  [[ -e $path ]] || return 1

  if zmodload -F zsh/stat b:zstat 2>/dev/null; then
    local -A stat_info
    zstat -H stat_info -- "$path" 2>/dev/null || return 1
    REPLY="${stat_info[mtime]-}"
    return 0
  fi

  if command -v stat >/dev/null 2>&1; then
    REPLY="$(command stat -c '%Y' -- "$path" 2>/dev/null)" || return 1
    return 0
  fi

  return 1
}

_vtex_clear_config_cache() {
  emulate -L zsh

  _VTEX_CACHE_CONFIG_PATH=""
  _VTEX_CACHE_CONFIG_MTIME=""
  _VTEX_CACHE_ACCOUNT=""
  _VTEX_CACHE_WORKSPACE=""
}

_vtex_clear_project_cache() {
  emulate -L zsh
  _VTEX_PROJECT_ROOT_CACHE=()
}

vtex_cache_clear() {
  emulate -L zsh

  _vtex_clear_config_cache
  _vtex_clear_project_cache
}
