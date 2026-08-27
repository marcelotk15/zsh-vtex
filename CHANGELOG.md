# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Zsh plugin that reads VTEX Toolbelt context (`~/.config/configstore/vtex.json`) without modifying `PROMPT` / `RPROMPT`
- Helpers: `vtex_prompt_info`, `vtex_prompt_plain`, `vtex_context`, `vtex_account`, `vtex_workspace`, `vtex_project_root`, `vtex_in_project`, `vtex_cache_clear`
- Config path override via `VTEX_CONFIG_FILE`
- Optional `jq` parsing with regex fallback for `account` / `workspace`
- Config cache invalidated by file mtime; project-root cache for `manifest.json` walk-up
- Prompt gate via `VTEX_REQUIRE_MANIFEST` (default: only show inside a VTEX project)
- Colored segment via `VTEX_PROMPT_COLOR` (default `205`)
- Prompt template via `VTEX_PROMPT_FORMAT` with tokens `{account}`, `{workspace}`, `{context}`, `{symbol}`, `{color}`, `{reset}`
- Optional prefix via `VTEX_PROMPT_SYMBOL` (empty by default)
- Standalone `bin/vtex-context` for Starship, tmux, bash, and other non-zsh consumers
- Test suite (`scripts/test.sh`: bats or `test/runner.zsh`) and lint script (`scripts/lint.sh`)
- README with install and prompt integration docs (Oh My Zsh, Powerlevel10k, Starship, Spaceship, Pure, tmux, bash)
- MIT license
