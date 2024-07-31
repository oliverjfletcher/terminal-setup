#!/bin/bash
 
#######################################################################
#Script Name	: install.sh                                                                                            
#Description    : Automated Initial Terminal & App bootstrap for Mac                                                                                                                                                                     
#Author       	: Oliver Fletcher                                           
#Email         	: helloworld@oliverfletcher.io                                      
#######################################################################
echo "Starting..."

# Install xcode CLI
xcode-select —-install

# Install Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

#Install Mac Apps
echo "Installing apps..."

CASKS=(
    iterm2
    slack
    telegram
    docker
    firefox
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

)
echo "Installing apps..."
brew cask install ${CASKS[@]}

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
    packer
    vault
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
    cfn-lint
    terraform
    eksctl
    kind
    kustomize
    go
    python3
    openssl
    netcat
    cilium-cli
)
echo "Installing packages..."
brew install ${PACKAGES[@]}

# Install lightline
git clone https://github.com/itchyny/lightline.vim ~/.vim/pack/plugins/start/lightline

# Get zsh syntax-highlighting and add to zsh path
echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc

# Get zsh history substring search, and add to zsh path
echo 'source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh' >> ~/.zshrc

# Add zsh auto-suggestions to .zshrc
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Install virtualenv
pip3 install virtualenv

# Configure virtualenv
mkdir virtualenv
virtualenv venv

# Activate virtualenv
source venv/bin/activate

# Install Python tools
pip3 install requirements.txt

# Dectivate virtualenv
deactivate

# Install Powerline fonts
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

# Add vscode terminal shortcut to zsh
code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;} >> ~/.zshrc

# Setup bash-completion
echo "[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion" >> ~/.bash_profile

# Update .zshrc conf file
cat << EOF >> ~/.zshrc
alias k=kubectl
THEME="robbyrussell"
THEME="fino-time"
eval "\$(starship init zsh)"
EOF
source ~/.zshrc

# Basic vim developer .conf setup
touch ~/.vimrc && cat << EOF > ~/.vimrc
syntax on
set nu
nnoremap H gT
nnoremap L gt
set tabstop=2
set expandtab
set shiftwidth=2
set statusline+=%#warningmsg#
set statusline+=%*
let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=1
let g:syntastic_check_on_open=1
let g:syntastic_check_on_wq=0
set laststatus=2
let g:lightline={'colorscheme': 'wombat'}
EOF
