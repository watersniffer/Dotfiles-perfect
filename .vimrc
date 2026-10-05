" Gruvbox Dark — minimal vim config
" Sourced from ~/.vimrc (symlinked into Dotfiles-mine/home)

set nocompatible
filetype plugin indent syntax on

" --- Appearance ---
set background=dark          " Gruvbox dark palette (background=dark)
set termguicolors            " 24-bit colour (needs a truecolor terminal: kitty)
set cursorline
set number
set relativenumber
set showmatch
set matchtime=1
set scrolloff=8
set sidescrolloff=8
set signcolumn=yes
set laststatus=2
set showtabline=2
set ruler
set wildmenu
set lazyredraw
set ttyfast

" Colours (ships with vim 9.x)
silent! colorscheme monochrome

" Statusline
set statusline=%#TabLineSel#\ %{mode()}\ %\ %#TabLine#\ %f\ %h%m%r\ %=\
    \ %#TabLine#\ %{&filetype}\ %{&fileencoding?&fileencoding:&encoding}\ %l:%c\ %P\

" Selection / search with Mocha accents
set hlsearch
set incsearch
set ignorecase
set smartcase

" Tabs
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

" UI safety
set mouse=a
set clipboard=
set belloff=all
set fillchars=eob:\ 
set shortmess+=aoOTIcF
set report=9999
set noswapfile
set undofile
set undodir=~/.vim/undo//