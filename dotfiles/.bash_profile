# ~/.bash_profile - bash is the fallback shell here; zsh is the daily driver.

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# bash-completion@2 needs BASH_COMPLETION_COMPAT_DIR pointed at the same prefix
# as brew, not a hardcoded /usr/local.
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
    export BASH_COMPLETION_COMPAT_DIR="$HOMEBREW_PREFIX/etc/bash_completion.d"
    [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ] \
        && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
fi

alias k=kubectl
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k
fi

export PATH="$HOME/.local/bin:$PATH"
export EDITOR="${EDITOR:-nvim}"

[ -f "$HOME/.bash_profile.local" ] && . "$HOME/.bash_profile.local"
