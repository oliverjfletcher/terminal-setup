
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
alias k=kubectl
eval "$(starship init zsh)"
source <(kubectl completion zsh)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh
code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}
export PATH="$PATH:/Users/ofletcher/.local/bin"
source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh
