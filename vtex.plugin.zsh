# Zsh plugin: VTEX context helpers
# Does not modify PROMPT or RPROMPT automatically.

typeset -g VTEX_PLUGIN_DIR="${${(%):-%N}:A:h}"

source "$VTEX_PLUGIN_DIR/lib/cache.zsh"
source "$VTEX_PLUGIN_DIR/lib/config.zsh"
source "$VTEX_PLUGIN_DIR/lib/project.zsh"
source "$VTEX_PLUGIN_DIR/lib/prompt.zsh"

fpath=(
  "$VTEX_PLUGIN_DIR/functions"
  $fpath
)

autoload -Uz \
  vtex_account \
  vtex_workspace \
  vtex_context
