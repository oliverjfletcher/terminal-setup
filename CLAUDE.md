# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Single-shot bootstrap of a fresh macOS machine: installs Xcode CLT, Homebrew,
selected package groups, Python CLI tools, shell/editor plugins, and lays down
shell + editor config from `dotfiles/`. Not a dotfiles framework — there's no
uninstall and no per-host branching.

## Running

```bash
./install.sh                  # interactive group picker + progress display
./install.sh --yes            # non-interactive, default groups
./install.sh --dry-run        # change nothing, show what would happen
./install.sh --list           # show groups and defaults
./backup-dotfiles.sh          # capture $HOME dotfiles back into dotfiles/
./backup-dotfiles.sh --brew   # also dump installed packages for drift diffing
```

The README's clone + `./install.sh` is the canonical entry point. There are no
tests and no CI; `shellcheck` (installed by the `core` group) is the closest
thing to a linter — keep `shellcheck -S warning install.sh backup-dotfiles.sh`
clean.

## Structure

- `install.sh` — the entire bootstrap, as a group-driven interactive installer.
  Tooling changes happen by editing `brew/Brewfile.*`, not by editing this file.
- `brew/Brewfile.*` — one file per installable group (`core`, `dev`,
  `kubernetes`, `cloud`, `aws`, `security`, `apps`, `fonts`). Plain
  `brew`/`cask`/`tap` lines; `install.sh` parses them itself rather than
  shelling out to `brew bundle`, so it can show per-package progress and
  isolate failures.
- `dotfiles/` — source of truth for shell + editor config. Copied verbatim into
  `$HOME`, **including nested paths** (`dotfiles/.config/starship.toml` →
  `~/.config/starship.toml`).
- `backup-dotfiles.sh` — copies a curated allowlist of `$HOME` dotfiles into
  `dotfiles/`. The allowlist is intentional — `.claude.json`,
  `.k8s_*_cache.json`, history files, and other secrets/state are deliberately
  skipped. Add new files to the `FILES=(...)` array; do not switch to a glob
  without a denylist.
- `python-tools.txt` — Python *CLI tools*, installed with `uv tool install`.
  Libraries (boto3, requests, flask) do not belong here; they are per-project
  dependencies.
- `mcp-servers.json` — Claude Code MCP servers, in `.mcp.json` format. The
  `mcp` group adds each one with `claude mcp add-json -s user`, replacing an
  existing user-scope entry of the same name if it differs. Keep
  `${VAR:-default}` references unexpanded: Claude Code expands them when the
  server starts, so `AWS_PROFILE` / `DD_SITE` can change after install.
  `aws-mcp` passes `--region` explicitly, set to the endpoint's region:
  `mcp-proxy-for-aws` otherwise signs with `$AWS_REGION`, and a mismatch with
  the endpoint fails SigV4. The working region goes in `--metadata AWS_REGION=`.

## Things to know before editing

- **macOS ships bash 3.2.** `install.sh` runs under `#!/bin/bash`, so no
  associative arrays, no `mapfile`, no `${var,,}`, and no fractional `read -t`.
  Group tables are parallel indexed arrays for this reason.
- **`local a=$1 b=$a` does not work.** bash expands every word of a `local`
  statement before assigning any of them, so `b` sees the *global* `a` — an
  unbound-variable error under `set -u`. Split such assignments across lines.
- **BSD `seq 1 0` counts down** and prints `1 0`, so `printf 'x%.0s' $(seq 1 $n)`
  is wrong for `n=0`. Progress bars are built with an explicit loop.
- **Packages are installed one at a time, on purpose.** `brew install a b c`
  resolves every name first and aborts the whole batch if any one fails, which
  previously meant a single renamed formula silently installed nothing.
- **Third-party taps must be trusted.** Homebrew 6+ refuses to load formulae
  from untrusted taps; `install_group` runs `brew trust --tap` after tapping.
  This is what broke `vault` and `packer` under the old flat `PACKAGES` array.
- **Homebrew is not on PATH after it installs.** `ensure_homebrew` evaluates
  `brew shellenv` explicitly; without it every subsequent `brew install` fails
  on a fresh Apple Silicon machine.
- **`command -v xcode-select` is always true** — `/usr/bin/xcode-select` ships
  with macOS even when the CLT are absent. Use `xcode-select -p` instead.
- **Dotfile editing direction**: edit `dotfiles/*` in the repo for changes that
  should propagate to new machines; edit `~/.zshrc` etc. on a live machine and
  then run `backup-dotfiles.sh` to capture. Don't add `cat << EOF >> ~/.rc`
  heredocs to `install.sh` — that path was removed in favour of file copies.
- **Container runtime**: OrbStack only. Docker Desktop and Rancher Desktop are
  commented out in `brew/Brewfile.apps` because all three ship a `docker`
  binary and contend over `~/.docker/config.json` and the daemon socket.
