" ---------------------------------------------------------------------------
" Set vimhome according to OS
" ---------------------------------------------------------------------------
if has('win32') || has ('win64')
    let $VIMHOME = $VIM."/vimfiles"
else
    let $VIMHOME = $HOME."/.vim"
endif
" ---------------------------------------------------------------------------
"
" Vundle
"
" ---------------------------------------------------------------------------
set nocompatible
filetype off

if has('win32') || has ('win64')
    set rtp+=~/vimfiles/bundle/Vundle.vim/
    call vundle#begin('~/vimfiles/bundle')
else
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()
endif


" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

Plugin 'mileszs/ack.vim'
Plugin 'tpope/vim-git'
Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdtree'
Plugin 'Raimondi/delimitMate'
Plugin 'kien/rainbow_parentheses.vim'
Plugin 'tpope/vim-surround'
Plugin 'scrooloose/syntastic'
Plugin 'tomtom/tlib_vim'
Plugin 'sirver/ultisnips'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tpope/vim-classpath'
Plugin 'guns/vim-clojure-static'
Plugin 'altercation/vim-colors-solarized'
Plugin 'kien/ctrlp.vim'
Plugin 'tpope/vim-cucumber'
Plugin 'tpope/vim-fireplace'
Plugin 'nanotech/jellybeans.vim'
Plugin 'groenewege/vim-less'
Plugin 'mustache/vim-mustache-handlebars'
Plugin 'nelstrom/vim-visual-star-search'
Plugin 'tpope/vim-vividchalk'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

"  ---------------------------------------------------------------------------
"
" General settings
"
" ---------------------------------------------------------------------------
set encoding=utf-8
set fileencoding=utf-8
" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
  set nobackup          " do not keep a backup file, use versions instead
else
  set backup            " keep a backup file
endif
set history=50          " keep 50 lines of command line history
set ruler               " show the cursor position all the time
set showcmd             " display incomplete commands
set incsearch           " do incremental searching

set shiftwidth=4        " Set default indentation width
set expandtab           " Use spaces for indenting only

"" Set the number of spaces a tab counts while editing. When expandtab is 
"" enabled, vim will only insert spaces. Else it will insert a combination 
"" of tabs and spaces in order to reduce the size of a file.
set softtabstop=4

" Set the characters that listmode should highlight 
set lcs=eol:$,tab:>-,trail:·

" Set a nice statusline
"set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set statusline=%{fugitive#statusline()}\ %f\ %m\ %r\ Line:\ %l/%L[%p%%]\ Col:\ %c\ Buf:\ #%n\ [%b][0x%B]
set laststatus=2

" When spliting horizontaly always split below the current window,
" when spliting verticaly always open the window on the right.
set splitbelow 
set splitright

set background=dark
" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

" Enhance Tab completion of vim commands.
set wildmenu wildmode=list:longest

" ---------------------------------------------------------------------------
"
" Colors
"
" ---------------------------------------------------------------------------
" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

" ---------------------------------------------------------------------------
"
" Shortcuts
"
" ---------------------------------------------------------------------------

let mapleader = ' '

" Toggle list mode
nmap <Leader>ls :set invlist<cr>:set list?<cr>

" Toggle paste mode
nmap <Leader>p :set invpaste<cr>:set paste?<cr>

" Turn off that stupid highlight search
nmap <Leader>nh :set invhls<cr>:set hls?<cr>

" Set text wrapping toggles
nmap <Leader>w :set invwrap<cr>:set wrap?<cr>

" Set up retabbing on a source file
nmap <Leader>rr :1,$retab<cr>

" cd to the directory containing the file in the buffer
nmap <Leader>cd :lcd %:p:h<cr>

" cd to the directory containing the file in the buffer and toggle a NERTTree
nmap <Leader>nt :NERDTreeToggle<cr>

" Make the directory that contains the file in the current buffer.
" This is useful when you edit a file in a directory that doesn't
" (yet) exist
nmap <Leader>md :!mkdir -p %:p:h<cr>

" Toggle spell checking on and off
nmap <silent> <leader>s :set spell!<CR>
set spelllang=en_us


" Identify active highlight group.
" Source: http://vim.wikia.com/wiki/Identify_the_syntax_highlighting_group_used_at_the_cursor
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" Move between windows using CTRL+{hjkl}
map <c-h> <c-w>h
map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l

" Disable anoying insert mode commands
imap <c-a> <Nop>
imap <c-c> <Nop>
imap <c-h> <Nop>
imap <c-u> <Nop>
imap <c-w> <Nop>
" ---------------------------------------------------------------------------
"
" Autocommands
"
" ---------------------------------------------------------------------------
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!
   
  " Set textwidth for some file types.
  autocmd FileType mail setlocal textwidth=72
  autocmd FileType rst setlocal textwidth=78
  autocmd FileType tex setlocal textwidth=78
  autocmd FileType text setlocal textwidth=78

  autocmd FileType html setlocal shiftwidth=2

  " Use smartindet for those file types
  autocmd FileType haskell setlocal smartindent

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
  augroup END
else
  set autoindent                " always set autoindenting on
endif " has("autocmd")

" ---------------------------------------------------------------------------
"
" Ack
"
" ---------------------------------------------------------------------------
nmap \a <Esc>:Ack!

" ---------------------------------------------------------------------------
"
" Rainbow Parentheses
"
" ---------------------------------------------------------------------------

" Enable rainbow parentheses for all buffers
augroup rainbow_parentheses
  au!
  au VimEnter * RainbowParenthesesActivate
  au BufEnter * RainbowParenthesesLoadRound
  au BufEnter * RainbowParenthesesLoadSquare
  au BufEnter * RainbowParenthesesLoadBraces
augroup END

" ---------------------------------------------------------------------------
"
" UltiSnips
"
" ---------------------------------------------------------------------------
let g:UltiSnipsEditSplit="horizontal"

" ---------------------------------------------------------------------------
"
" HTML
"
" ---------------------------------------------------------------------------

let g:html_indent_script1 = "inc"
let g:html_indent_style1 = "inc"
let g:html_indent_inctags = "html,body,head,tbody,main,section"

" ---------------------------------------------------------------------------
"
" Syntastic
"
" ---------------------------------------------------------------------------

" Use W3 online validation service. Requires curl
let g:syntastic_html_checkers = ['']

" ---------------------------------------------------------------------------
"
" Vim Pandoc
"
" ---------------------------------------------------------------------------

" Enable the following vim-pandoc-after plugins
let g:pandoc#after#modules#enabled = ["ultisnips"]

" ---------------------------------------------------------------------------
"
" Delimitmate
"
" ---------------------------------------------------------------------------

au FileType sql let b:delimitMate_expand_cr = 1
au FileType json let b:delimitMate_expand_cr = 1
au FileType javascript let b:delimitMate_expand_cr = 1

" ---------------------------------------------------------------------------
"
" Read .vimrc file in cwd.
"
" ---------------------------------------------------------------------------
set exrc			" enable per-directory .vimrc files
set secure			" disable unsafe commands in local .vimrc files
