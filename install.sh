#!/bin/bash
 
###################################################################
#Script Name	: install.sh                                                                                            
#Description    : Automated Initial Terminal mac bootstrap                                                                                                                                                                     
#Author       	: Oliver Fletcher                                           
#Email         	: helloworld@oliverfletcher.io                                      
###################################################################

# Install Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install zsh & terminal utilities
brew install iterm2
brew install zsh
brew install starship
brew install tree
brew install ripgrep
brew install pwgen
brew install bash-completion
brew install tmux
brew install hub
brew install docker
brew install awscli
brew install terraform
brew install kustomize
brew install go
brew install python3
brew install icecream
brew install telnet
brew install hping


# Install lightline
git clone https://github.com/itchyny/lightline.vim ~/.vim/pack/plugins/start/lightline

# Get a zsh-[autosuggestions & syntax-highlighting.git] and add to zsh path
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install taskcat
pip3 install taskcat

# Install tldr
pip3 install tldr

# Install virtualenv
pip3 install virtualenv

# Install net-tools
pip3 install net-tools

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
execute pathogen#infect()
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