# zsh-vtex

<p align="center">
  <img src="docs/no-more-vtex-whoami.png" alt="NO MORE VTEX WHOAMI" width="420" />
  <br />
  <strong>NO MORE VTEX WHOAMI</strong>
</p>

A Zsh plugin that shows your current VTEX `account` and `workspace` in the terminal.

It reads the context state written by the [VTEX Toolbelt](https://github.com/vtex/toolbelt) (the same data updated on login or workspace switch) and exposes helpers you can wire into your own prompt or theme. The plugin **never** modifies `PROMPT`, `RPROMPT`, or your theme on its own, it stays agnostic so you can use it with Oh My Zsh, Powerlevel10k, Starship, Spaceship, Pure, tmux, or a plain `PROMPT`.

## Requirements

* Zsh
* VTEX Toolbelt configured and logged in (`vtex login`)
* `jq` optional (a regex fallback is used when it is missing)

## Installation

### 1. Install the plugin

Pick one method.

**Oh My Zsh**

```bash
git clone https://github.com/marcelotk15/zsh-vtex.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/vtex"
```

Add `vtex` to the plugins list in `~/.zshrc`:

```zsh
plugins=(
  ...
  vtex
)
```

**Plugin managers**

```zsh
# zinit
zinit light marcelotk15/zsh-vtex

# antidote
# add to ~/.zsh_plugins.txt:
# marcelotk15/zsh-vtex

# sheldon (plugins.toml)
# [plugins.vtex]
# github = "marcelotk15/zsh-vtex"
```

**Manual**

```bash
git clone https://github.com/marcelotk15/zsh-vtex.git \
  ~/.local/share/zsh-vtex
```

```zsh
source ~/.local/share/zsh-vtex/vtex.plugin.zsh
```

### 2. Show it in your prompt

The plugin only loads helpers. Add one of these to `~/.zshrc` (after the plugin is sourced), then `source ~/.zshrc`:

```zsh
setopt prompt_subst
RPROMPT='$(vtex_prompt_info)'
```

Or on the left:

```zsh
setopt prompt_subst
PROMPT='$(vtex_prompt_info) '$PROMPT
```

For Powerlevel10k, Starship, Spaceship, Pure, tmux, or bash, see [Prompt integrations](#prompt-integrations).

### Optional: `bin/` on `PATH`

Needed only for Starship, tmux, or bash (the standalone `vtex-context` binary). Adjust the path to match your install:

```zsh
# Manual install
path=("$HOME/.local/share/zsh-vtex/bin" $path)

# Oh My Zsh
# path=("${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/vtex/bin" $path)
```

## Usage

Inside a VTEX project (a directory tree that contains `manifest.json`), the default segment looks like:

```text
[store@dev]
```

Outside a VTEX project, nothing is shown. Set `VTEX_REQUIRE_MANIFEST=false` to always show the context when account and workspace are available.

Change account or workspace with the VTEX CLI (`vtex login`, `vtex use`), not by editing the config JSON by hand.

## Configuration

Set these in `~/.zshrc` before or after sourcing the plugin.

| Variable | Default | Description |
| --- | --- | --- |
| `VTEX_PROMPT_FORMAT` | `[{color}{symbol}{context}{reset}]` | Template for the prompt segment |
| `VTEX_PROMPT_SYMBOL` | _(empty)_ | Prefix inserted wherever `{symbol}` appears; include any trailing space yourself |
| `VTEX_PROMPT_COLOR` | `205` | Color used by `{color}` / `{reset}` in `vtex_prompt_info` (Zsh color name or 0–255) |
| `VTEX_REQUIRE_MANIFEST` | `true` | Only show the segment inside a VTEX project. Disabled by: `false`, `False`, `FALSE`, `0`, `no`, `NO` |
| `VTEX_CONFIG_FILE` | `~/.config/configstore/vtex.json` | Path to the Toolbelt context file (read-only for this plugin) |

### Format tokens

| Token | Meaning |
| --- | --- |
| `{account}` | VTEX account |
| `{workspace}` | VTEX workspace |
| `{context}` | `account@workspace` |
| `{symbol}` | value of `VTEX_PROMPT_SYMBOL` |
| `{color}` | start color (`%F{...}` in `vtex_prompt_info`, empty in plain) |
| `{reset}` | end color (`%f` in `vtex_prompt_info`, empty in plain) |

Examples:

```zsh
export VTEX_PROMPT_FORMAT='{symbol}{account}/{workspace}'
export VTEX_PROMPT_COLOR="cyan"
export VTEX_REQUIRE_MANIFEST=false

# Optional shopping-cart icon (Nerd Font); include the trailing space
export VTEX_PROMPT_SYMBOL=$'\uf07a '
```

## Prompt integrations

By default the segment is only shown inside a VTEX project. With two-line prompts (Starship, Pure, many Powerlevel10k layouts), `RPROMPT` sits on the **caret line**, not next to git/node on the first line — prefer a theme-native module in those cases.

### Native `PROMPT` / Oh My Zsh

See [Installation step 2](#2-show-it-in-your-prompt).

### Powerlevel10k

Use the plain helper (p10k applies its own colors):

```zsh
function prompt_vtex() {
  local text
  text="$(vtex_prompt_plain)" || return
  [[ -n $text ]] || return
  p10k segment -f 205 -t "$text"
}
```

Then include `vtex` in `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` or `POWERLEVEL9K_LEFT_PROMPT_ELEMENTS`.

### Starship

Put `bin/` on your `PATH` (see [Optional: bin/ on PATH](#optional-bin-on-path)), then add this block **once** to `~/.config/starship.toml`:

```toml
[custom.vtex]
description = "VTEX account@workspace"
command = "vtex-context"
when = "vtex-context"
symbol = " "
style = "fg:205"
format = '\[[$symbol$output]($style)\]'
```

If `vtex-context` is not on `PATH`, use absolute paths for `command` and `when`.

Do not run `starship preset ... --force -o ~/.config/starship.toml` from shell startup — that rewrites the TOML and removes `[custom.vtex]`. Apply a preset once interactively if you want, then add the module and leave the file alone.

Without the binary, you can still call the plugin:

```toml
[custom.vtex]
command = "zsh -fc 'source \"$HOME/.local/share/zsh-vtex/vtex.plugin.zsh\"; print -rn -- \"$(vtex_context)\"'"
when = "zsh -fc 'source \"$HOME/.local/share/zsh-vtex/vtex.plugin.zsh\"; vtex_in_project'"
symbol = " "
style = "fg:205"
format = '\[[$symbol$output]($style)\]'
```

Verify with:

```zsh
which vtex-context
starship module custom.vtex
```

### Spaceship

```zsh
spaceship_vtex() {
  local text
  text="$(vtex_prompt_plain)"
  [[ -n $text ]] || return
  spaceship::section "magenta" "$text"
}

SPACESHIP_PROMPT_ORDER=(vtex $SPACESHIP_PROMPT_ORDER)
```

### Pure

Pure has no section API; prepend via `prompt_pure_preprompt`, or use `RPROMPT` on a single-line layout:

```zsh
prompt_vtex_preprompt() {
  local text
  text="$(vtex_prompt_info)"
  [[ -n $text ]] && print -r -- "$text"
}
add-zsh-hook precmd prompt_vtex_preprompt
```

### tmux

```tmux
set -g status-right '#(vtex-context) | %H:%M'
```

### bash

```bash
PROMPT_COMMAND='__vtex=$(vtex-context 2>/dev/null); PS1="${__vtex:+[$__vtex] }\u@\h:\w\$ "'
```

## Functions

| Function / command | Description | Example |
| --- | --- | --- |
| `vtex_prompt_info` | Formatted segment with Zsh color sequences for `PROMPT` / `RPROMPT`. Prints nothing (and returns 0) when there is no context. | `[%F{205}store@dev%f]` |
| `vtex_prompt_plain` | Same template without color sequences. For Starship, Powerlevel10k, Spaceship, tmux. | `[store@dev]` |
| `vtex_context` | `account@workspace`, or empty when unavailable. | `store@dev` |
| `vtex_account` | Current account. | `store` |
| `vtex_workspace` | Current workspace. | `dev` |
| `vtex_in_project` | Exit status only: `0` when the prompt gate passes (manifest present, or `VTEX_REQUIRE_MANIFEST` disabled). | `vtex_in_project && echo inside` |
| `vtex_project_root [path]` | Nearest directory containing `manifest.json`, walking up from `$PWD` or `path`. | `/home/user/projects/my-vtex-app` |
| `vtex_cache_clear` | Clears config and project-detection caches (rarely needed). | — |
| `vtex-context` | Standalone binary: prints `account@workspace` and exits `0`, or exits `1` when there is nothing to show. Respects `VTEX_CONFIG_FILE` and `VTEX_REQUIRE_MANIFEST`. | `store@dev` |

## How it works

The plugin reads `~/.config/configstore/vtex.json` (or `VTEX_CONFIG_FILE`). That file is created and updated by the VTEX Toolbelt; this plugin only reads it.

Context is cached by the file's modification time, so `vtex_prompt_info` does not re-parse JSON on every prompt redraw. When the Toolbelt updates the file, the cache invalidates automatically. Project-root detection (walk up looking for `manifest.json`) is also cached.

JSON parsing uses `jq` when available; otherwise a small regex extracts the `account` and `workspace` fields.

## Development

```bash
./scripts/test.sh   # bats if available, else zsh test/runner.zsh
./scripts/lint.sh   # shellcheck when installed
```

## License

MIT
