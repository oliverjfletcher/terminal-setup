#!/bin/bash
 
#######################################################################
#Script Name	: install.sh                                                                                            
#Description    : Automated Initial Terminal & App bootstrap for Mac                                                                                                                                                                     
#Author       	: Oliver Fletcher                                           
#Email         	: engineering@oliverfletcher.io                                      
#######################################################################
echo "Starting..."

# Install xcode
install_xcode() {
    if ! command -v xcode-select &> /dev/null
    then
        echo "xcode is not installed. Installing now..."
        xcode-select --install
        
        # Wait for the installation to complete
        while ! command -v xcode-select &> /dev/null
        do
            echo "Waiting for xcode installation to complete..."
            sleep 5
        done
        
        echo "xcode has been successfully installed."
    else
        echo "xcode is already installed, continuing..."
    fi
}
install_xcode

# Install Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

#Install Mac Apps
echo "Installing apps..."
CASKS=(
    iterm2
    slack
    telegram
    docker
    arc
    microsoft-office
    little-snitch
    rancher
    spotify
    visual-studio-code
    keepassxc
    sublime-text
    vlc
    zoom
    flux
    google-cloud-sdk
    cameracontroller
    logitech-options
    claude
    claude-code
    hamed-elfayome/claude-usage/claude-usage-tracker
    gcloud-cli
    chromedriver
)
echo "Installing apps..."
brew install --cask ${CASKS[@]}

# Install zsh & terminal utilities
echo "Installing packages..."
PACKAGES=(
    zsh
    starship
    wget
    htop
    tree
    neovim
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
    watch
    thefuck
    ripgrep
    pwgen
    adr-tools
    argocd
    argoproj/tap/kubectl-argo-rollouts
    packer
    vault
    cmctl
    graphviz
    bash
    bash-completion
    tmux
    hub
    docker
    ansible
    awscli
    aws-cdk
    aws-sam-cli
    clusterawsadm
    cfn-lint
    terraform
    eksctl
    kind
    kustomize
    k9s
    go
    python3
    openssl
    netcat
    cilium-cli
    parallel
    gh
    git-filter-repo
    pre-commit
    shellcheck
    yamllint
    cmake
    ninja
    grpcurl
    cloudflared
    certbot
    pyenv
    python@3.11
    pipx
    yarn
    yt-dlp
    aqtinstall
    kubernetes-cli
    helm
    ingress2gateway
    fluxcd/tap/flux
    azure/kubelogin/kubelogin
    azure-cli
    mongodb-atlas-cli
    infisical/get-cli/infisical
)
echo "Installing packages..."
brew install ${PACKAGES[@]}

# Install lightline
git clone https://github.com/itchyny/lightline.vim ~/.vim/pack/plugins/start/lightline

# Install virtualenv
pip3 install virtualenv

# Configure virtualenv
mkdir $HOME/virtualenv
virtualenv venv

# Activate virtualenv
source venv/bin/activate

# Install Python tools
pip3 install requirements.txt

# Dectivate virtualenv
deactivate

# Install Powerline fonts
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts && ./install.sh && cd ..
rm -f -r fonts

# Apply dotfiles from the repo's dotfiles/ directory.
# The dotfiles/ directory is the source of truth for shell + editor config.
# To capture changes made on a live machine back into the repo, run:
#     ./backup-dotfiles.sh
echo "Applying dotfiles..."
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

if [ -d "$DOTFILES_DIR" ]; then
    for src in "$DOTFILES_DIR"/.[!.]*; do
        [ -e "$src" ] || continue
        name="$(basename "$src")"
        dest="$HOME/$name"
        if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
            cp "$dest" "$dest.bak.$TIMESTAMP"
            echo "backed up existing $name -> $name.bak.$TIMESTAMP"
        fi
        cp "$src" "$dest"
        echo "applied: $name"
    done
else
    echo "warning: $DOTFILES_DIR not found, skipping dotfile sync"
fi

# Reload shells that were updated
[ -f ~/.bash_profile ] && source ~/.bash_profile
[ -f ~/.zshrc ] && source ~/.zshrc
