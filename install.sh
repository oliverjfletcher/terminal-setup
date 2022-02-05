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
    authy
    spotify
    visual-studio-code
    keepassxc
    sublime-text
    vlc
    zoom
    flux
    google-cloud-sdk
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
    watch
    thefuck
    ripgrep
    pwgen
    adr-tools
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
    minikube
    kustomize
    go
    python3
    openssl
    netcat
)
echo "Installing packages..."
brew install ${PACKAGES[@]}

# Install lightline
git clone https://github.com/itchyny/lightline.vim ~/.vim/pack/plugins/start/lightline

# Get a zsh-[autosuggestions & syntax-highlighting.git] and add to zsh path
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

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
sed -i '.zshrc' 's/_THEME="robbyrussell"/_THEME="fino-time"/g' ~/.zshrc 
sed -i '.zshrc' 's/plugins=(/plugins=(zsh-autosuggestions zsh-syntax-highlighting /g' ~/.zshrc 
source ~/.zshrc
touch ~/.vimrc && cat << EOF > ~/.vimrc
#starship
eval "$(starship init zsh)" 
EOF

# Basic vim developer .conf setup
touch ~/.vimrc && cat << EOF > ~/.vimrc
syntax on
set nu sw=2 ts=2 softtabstop=2 expandtab autoindent pastetoggle=&lt;f5&gt;
set nu
syntax on
nnoremap H gT
nnoremap L gt
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
set laststatus=2
let g:lightline = {'colorscheme': 'wombat'}
EOF
