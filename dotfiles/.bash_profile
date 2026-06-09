source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi
export BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
