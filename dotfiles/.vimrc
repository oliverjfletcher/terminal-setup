" ~/.vimrc - vim is the quick-edit fallback; nvim is $EDITOR.

syntax on
filetype plugin indent on

set number
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set incsearch
set ignorecase
set smartcase
set hlsearch
set scrolloff=3
set mouse=a
set clipboard=unnamed          " yank straight to the macOS pasteboard
set undofile
set undodir=~/.vim/undo
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//

" Tab navigation
nnoremap H gT
nnoremap L gt
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Statusline. lightline is cloned into ~/.vim/pack/plugins/start by install.sh.
set laststatus=2
set noshowmode                 " lightline already shows the mode
let g:lightline = {'colorscheme': 'wombat'}

" The old g:syntastic_* settings were removed: syntastic was never installed,
" so they did nothing. If you want linting in vim, install ALE or use nvim.
