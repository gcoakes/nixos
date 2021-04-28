set shell=sh
set nobackup nowritebackup noswapfile
set noshowmode
set expandtab shiftwidth=4 smartindent tabstop=4
set completeopt=menuone,noinsert,noselect
set ignorecase smartcase
set scrolloff=4
set sidescrolloff=8
set termguicolors
set mouse=a
set list
set number
set nowrap
set hidden
set splitbelow nosplitright
set signcolumn=yes

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

packadd! dracula-vim
colorscheme dracula

inoremap jj <Esc>

vnoremap <Tab> >
vnoremap <S-Tab> <
nnoremap <Tab> gv>
nnoremap <S-Tab> gv<
noremap <C-w>- <cmd>vert resize -10<CR>
noremap <C-w>+ <cmd>vert resize +10<CR>
noremap <C-w>< <cmd>vert resize -10<CR>
noremap <C-w>> <cmd>vert resize +10<CR>
nnoremap gb :Buffers<CR>

let g:lightline = {
\   'colorscheme': 'dracula',
\ }

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

let mapleader = ' '
nnoremap <silent> <leader>q :bd<CR>
noremap <C-p> <cmd>Files<CR>

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

noremap <C-f> <cmd>RG<CR>

autocmd FileType json syntax match Comment +\/\/.\+$+
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2
autocmd FileType nix setlocal shiftwidth=2 tabstop=2
autocmd FileType vim setlocal shiftwidth=2 tabstop=2
autocmd FileType json setlocal shiftwidth=2 tabstop=2
autocmd FileType tex setlocal formatoptions=tca textwidth=80 spell spelllang=en_us

