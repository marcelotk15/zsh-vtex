vtex_project_root() {
  emulate -L zsh

  local start="${1:-$PWD}"
  local dir=""
  local parent=""
  local cached=""

  [[ -e $start ]] || return 1

  start="${start:a}"

  if [[ -n ${_VTEX_PROJECT_ROOT_CACHE[$start]+x} ]]; then
    cached="${_VTEX_PROJECT_ROOT_CACHE[$start]}"

    if [[ $cached == "__NONE__" ]]; then
      return 1
    fi

    if [[ -f "$cached/manifest.json" ]]; then
      print -r -- "$cached"
      return 0
    fi

    unset "_VTEX_PROJECT_ROOT_CACHE[$start]"
  fi

  if [[ -f $start ]]; then
    dir="${start:h}"
  else
    dir="$start"
  fi

  while true; do
    if [[ -f "$dir/manifest.json" ]]; then
      _VTEX_PROJECT_ROOT_CACHE[$start]="${dir:A}"
      print -r -- "${dir:A}"
      return 0
    fi

    [[ $dir == / ]] && break

    parent="${dir:h}"
    [[ $parent == "$dir" ]] && break

    dir="$parent"
  done

  _VTEX_PROJECT_ROOT_CACHE[$start]="__NONE__"
  return 1
}

# Gate used by prompt helpers and bin/vtex-context.
# When VTEX_REQUIRE_MANIFEST is disabled, always succeeds.
# Otherwise requires a manifest.json in $PWD or a parent directory.
vtex_in_project() {
  emulate -L zsh

  local root=""

  case "${VTEX_REQUIRE_MANIFEST:-true}" in
    false | False | FALSE | 0 | no | NO)
      return 0
      ;;
  esac

  root="$(vtex_project_root)" || return 1
  [[ -n $root ]] || return 1
  return 0
}
