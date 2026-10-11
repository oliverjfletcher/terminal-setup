# ~/.zshrc - interactive zsh configuration
# Source of truth lives in the terminal-setup repo. Edit it there, or edit
# here and run ./backup-dotfiles.sh to capture the change.

# source ~/scripts/proxy_config.sh

#-----------------------------------------------------------------------
# History
# zsh defaults to a tiny history that is not even shared between panes.
#-----------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY         # don't clobber history from parallel shells
setopt INC_APPEND_HISTORY     # write as you go, not only on exit
setopt SHARE_HISTORY          # new commands visible in other open shells
setopt HIST_IGNORE_ALL_DUPS   # keep only the most recent copy of a command
setopt HIST_IGNORE_SPACE      # leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # expand !! before running, don't just fire it
setopt EXTENDED_HISTORY       # record timestamp + duration

#-----------------------------------------------------------------------
# Navigation & misc options
#-----------------------------------------------------------------------
setopt AUTO_CD                # `repo` instead of `cd repo`
setopt AUTO_PUSHD             # every cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS   # allow # comments at the prompt
setopt NO_BEEP

#-----------------------------------------------------------------------
# Completion
#-----------------------------------------------------------------------
fpath=("$HOME/.zsh/completions" $fpath)

autoload -Uz bashcompinit && bashcompinit
autoload -Uz compinit
# Rebuild the completion cache at most once a day; an unguarded `compinit`
# rescans fpath and adds noticeable latency to every single shell start.
# (BSD stat, so this is macOS-specific.)
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' "${ZDOTDIR:-$HOME}/.zcompdump" 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

#-----------------------------------------------------------------------
# Plugins
# Order matters: syntax-highlighting wants to be near the end, and
# history-substring-search must come after it.
#-----------------------------------------------------------------------
BREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
if [ -n "$BREW_PREFIX" ]; then
    source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
    source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null
    source "$BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh" 2>/dev/null
fi

# history-substring-search does nothing until its widgets are bound.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down

#-----------------------------------------------------------------------
# Tools
#-----------------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v direnv   >/dev/null && eval "$(direnv hook zsh)"

# fzf key bindings (ctrl-r history, ctrl-t files, alt-c cd).
# install.sh writes this file; see `plugins` group.
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
command -v fd >/dev/null && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'

#-----------------------------------------------------------------------
# Aliases
#-----------------------------------------------------------------------
alias k=kubectl
# kubectl completions are cached into ~/.zsh/completions by install.sh rather
# than regenerated on every prompt, which used to cost ~200ms per shell.
compdef k=kubectl 2>/dev/null

if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --group-directories-first --git'
    alias lt='eza --tree --level=2'
else
    alias ll='ls -lah'
fi
command -v bat  >/dev/null && alias cat='bat --paging=never'
command -v btop >/dev/null && alias top='btop'

alias g=git
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias ..='cd ..'
alias ...='cd ../..'
alias reload='exec zsh'
alias path='echo $PATH | tr ":" "\n"'

# Switch the global git identity: `gitprofile work|personal`, or no argument to
# show the current one. Profiles live in ~/.config/git/profiles/; work is the
# default [user] in ~/.gitconfig, so it has no profile file.
gitprofile() {
    local link="$HOME/.config/git/active-profile"
    case "$1" in
        "") ;;
        work) rm -f "$link" ;;
        *)
            if [ ! -f "$HOME/.config/git/profiles/$1" ]; then
                echo "usage: gitprofile [work|$(ls "$HOME/.config/git/profiles" | tr '\n' '|' | sed 's/|$//')]" >&2
                return 1
            fi
            ln -sfn "profiles/$1" "$link"
            ;;
    esac
    echo "git: $(git config --global --includes user.name) <$(git config --global --includes user.email)>"
}

# Use VS Code's own `code` CLI rather than a shell wrapper - the wrapper broke
# `code --wait` (and therefore git's editor integration) and `code --diff`.
VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
[ -d "$VSCODE_BIN" ] && export PATH="$PATH:$VSCODE_BIN"

#-----------------------------------------------------------------------
# PATH
# typeset -U keeps $path unique, so re-sourcing (or .zprofile adding the same
# entry) cannot pile up duplicates.
#-----------------------------------------------------------------------
typeset -U path PATH
export PATH="$HOME/.local/bin:$PATH"          # pipx / uv tool shims
export PATH="$HOME/go/bin:$PATH"
[ -d "$HOME/.krew/bin" ] && export PATH="$HOME/.krew/bin:$PATH"

export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"

#-----------------------------------------------------------------------
# brew upgrade once per Ghostty launch
# Keyed on Ghostty's PID so it runs in the first shell after Ghostty starts,
# not in every new tab, split or tmux pane. Ctrl-C skips it.
#-----------------------------------------------------------------------
if [ "$TERM_PROGRAM" = ghostty ] && [ -z "$TMUX" ] && command -v brew >/dev/null; then
    _ghostty_pid=$(pgrep -nx ghostty 2>/dev/null)
    _brew_stamp="${XDG_CACHE_HOME:-$HOME/.cache}/brew-upgrade.ghostty"
    if [ -n "$_ghostty_pid" ] && [ "$(cat "$_brew_stamp" 2>/dev/null)" != "$_ghostty_pid" ]; then
        mkdir -p "${_brew_stamp:h}" && echo "$_ghostty_pid" > "$_brew_stamp"
        echo "==> brew upgrade (once per Ghostty launch, Ctrl-C to skip)"
        brew upgrade
    fi
    unset _ghostty_pid _brew_stamp
fi

# Local, machine-specific overrides that should never be committed.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
