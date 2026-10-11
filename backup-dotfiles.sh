#!/bin/bash
#######################################################################
# Script Name : backup-dotfiles.sh
# Description : Copies a curated set of dotfiles from $HOME into the
#               repo's dotfiles/ directory so they can be committed.
# Author      : Oliver Fletcher
# Email       : engineering@oliverfletcher.io
#
# Usage:
#   ./backup-dotfiles.sh            capture dotfiles
#   ./backup-dotfiles.sh --brew     also snapshot installed packages to
#                                   brew/Brewfile.dump (gitignored, for diffing
#                                   against the curated brew/Brewfile.* groups)
#######################################################################
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$REPO_DIR/dotfiles"
DUMP_BREW=0
[ "${1:-}" = "--brew" ] && DUMP_BREW=1

# Explicit allowlist. Paths are relative to $HOME and may be nested.
# Do NOT switch to a wildcard unless you also add a denylist for
# history/cache/credential files (.zsh_history, .claude.json,
# .k8s_*_cache.json, .viminfo, .config/gh/hosts.yml, etc.).
FILES=(
    .bash_profile
    .gitconfig
    .tmux.conf
    .vimrc
    .zprofile
    .zshrc
    .config/starship.toml
    .config/git/ignore
    .config/git/profiles/personal
    .config/ghostty/config.ghostty
)

copied=0
skipped=0
for f in "${FILES[@]}"; do
    src="$HOME/$f"
    if [ -f "$src" ]; then
        mkdir -p "$DEST/$(dirname "$f")"
        cp "$src" "$DEST/$f"
        echo "backed up: $f"
        copied=$((copied + 1))
    else
        echo "skipped (not found): $f"
        skipped=$((skipped + 1))
    fi
done

if [ "$DUMP_BREW" -eq 1 ]; then
    if command -v brew >/dev/null 2>&1; then
        brew bundle dump --force --describe --file="$REPO_DIR/brew/Brewfile.dump"
        echo "snapshot: brew/Brewfile.dump (gitignored)"
        echo "  diff it against the curated groups to spot drift, e.g.:"
        echo "    grep -h '^brew ' brew/Brewfile.dump | sort > /tmp/have"
        echo "    grep -h '^brew ' brew/Brewfile.[a-z]* | sort > /tmp/want"
        echo "    comm -23 /tmp/have /tmp/want   # installed but not tracked"
    else
        echo "brew not found, skipping package snapshot" >&2
    fi
fi

echo
echo "Done: $copied copied, $skipped missing."
echo "Review with: git -C \"$REPO_DIR\" status dotfiles/"
