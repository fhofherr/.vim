" Vim plugin that generates new Scala source file when you type
"    vim nonexistent.scala.
" Scripts tries to detect package name from the directory path, e. g.
" .../src/main/scala/com/mycompany/myapp/app.scala gets header
" package com.mycompany.myapp
"
" Author     :   Stepan Koltsov <yozh@mx1.ru>
" Revision   : $Id: 31-create-scala.vim 17312 2009-03-16 04:02:05Z stepancheg $
"        $URL: https://lampsvn.epfl.ch/svn-repos/scala/scala-tool-support/trunk/src/vim/plugin/31-create-scala.vim $
"
" Modified by: Ferdinand Hofherr 
"   * Added support for packages that start with de.
"   * Modified the vim modeline added to the created files.

function! MakeScalaFile()
    if exists("b:template_used") && b:template_used
        return
    endif
    
    let b:template_used = 1
    
    let filename = expand("<afile>:p")
    let x = substitute(filename, "\.scala$", "", "")
    
    let p = substitute(x, "/[^/]*$", "", "")
    let p = substitute(p, "/", ".", "g")
    let p = substitute(p, ".*\.src$", "@", "") " unnamed package
    let p = substitute(p, ".*\.src\.", "!", "")  
    let p = substitute(p, "^!main\.scala\.", "!", "")
    let p = substitute(p, "^!.*\.ru\.", "!ru.", "")
    let p = substitute(p, "^!.*\.de\.", "!de.", "")
    let p = substitute(p, "^!.*\.org\.", "!org.", "")
    let p = substitute(p, "^!.*\.com\.", "!com.", "")
    
    " ! marks that we found package name.
    if match(p, "^!") == 0
        let p = substitute(p, "^!", "", "")
    else
        " Don't know package name.
        let p = "@"
    endif
    
    if p != "@"
        call append("0", "package " . p)
    endif
    
    call append(".", "/* vim: set ts=2 sw=2 et sts=2: */")
    call append(".", "")
    
endfunction

au BufNewFile *.scala call MakeScalaFile()

" vim: set ts=4 sw=4 et:
