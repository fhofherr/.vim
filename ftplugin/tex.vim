" Set some usefull settings for tex editing.
"
" Not as bloated as LatexSuite for vim.
"
" Author:      Ferdinand Hofherr <ferdinand.hofherr@gmail.com>
" Last Change: 2010-05-24
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal smartindent
setlocal softtabstop=2
setlocal shiftwidth=2
setlocal expandtab