# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Single-shot bootstrap of a fresh macOS machine: installs Xcode CLT, Homebrew, GUI casks, CLI packages, a Python virtualenv, Powerline fonts, and lays down shell + editor config from `dotfiles/`. Not a dotfiles framework — there's no uninstall and no per-host branching.

## Running

```bash
./install.sh               # full bootstrap (apps + packages + dotfiles)
./backup-dotfiles.sh       # capture current $HOME dotfiles back into dotfiles/
```

The README's one-liner is the canonical entry point. There are no tests, no linter, and no CI.

## Structure

- `install.sh` — the entire bootstrap. Tooling changes happen by editing the `CASKS` or `PACKAGES` bash arrays. The dotfile-application section just copies everything from `dotfiles/` into `$HOME` (with a timestamped `.bak` of anything overwritten that differs).
- `dotfiles/` — source of truth for shell + editor config. Files here are copied verbatim into `$HOME` by `install.sh`. Edit them directly, or edit on a live machine and run `backup-dotfiles.sh` to pull changes back.
- `backup-dotfiles.sh` — copies a curated allowlist of `$HOME` dotfiles into `dotfiles/`. The allowlist is intentional — `.claude.json`, `.k8s_*_cache.json`, history files, and other secrets/state are deliberately skipped. Add new files to the `FILES=(...)` array; do not switch to a glob without a denylist.
- `requirements.txt` — Python packages installed into the `venv` virtualenv created under the repo directory. Note: `install.sh` invokes `pip3 install requirements.txt` (missing `-r`), so the file is currently not actually consumed — preserve or fix deliberately, don't "clean up" silently.

## Things to know before editing

- **Dotfile editing direction**: edit `dotfiles/*` in the repo for changes that should propagate to new machines; edit `~/.zshrc` etc. on a live machine and then run `backup-dotfiles.sh` to capture. Don't add new `cat << EOF >> ~/.rc` heredocs to `install.sh` — that path was removed in favor of file copies.
- **Brew cask syntax**: the script uses `brew install --cask`. The older `brew cask install` no longer works on modern Homebrew.
- Order matters in `install.sh`: Homebrew must install before any `brew install` line; the virtualenv is created in the repo's working directory (`virtualenv venv`) and `source venv/bin/activate` depends on cwd.
