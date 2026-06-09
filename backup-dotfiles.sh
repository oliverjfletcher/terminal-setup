#!/bin/bash
#######################################################################
# Script Name : backup-dotfiles.sh
# Description : Copies a curated set of dotfiles from $HOME into the
#               repo's dotfiles/ directory so they can be committed.
# Author      : Oliver Fletcher
# Email       : engineering@oliverfletcher.io
#######################################################################
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$REPO_DIR/dotfiles"

# Explicit allowlist. Add new files here; do NOT switch to a wildcard
# unless you also add a denylist for history/cache/credential files
# (.zsh_history, .claude.json, .k8s_*_cache.json, .viminfo, etc.).
FILES=(
    .bash_profile
    .gitconfig
    .tmux.conf
    .vimrc
    .zprofile
    .zshrc
)

mkdir -p "$DEST"

for f in "${FILES[@]}"; do
    src="$HOME/$f"
    if [ -f "$src" ]; then
        cp "$src" "$DEST/$f"
        echo "backed up: $f"
    else
        echo "skipped (not found): $f"
    fi
done

echo "Done. Review with: git -C \"$REPO_DIR\" status dotfiles/"
