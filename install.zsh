#!/usr/bin/env zsh

DOTFILES_MINIMAL=false

WITH_ZSH=true
WITH_PYENV=true
WITH_NVM=true
WITH_RVM=true
WITH_VIM=true
WITH_TMUX=true
WITH_CLJ=true
WITH_GO=true
WITH_GIT=true
WITH_VSCODE=true
while [ $# -gt 0 ]; do
    case "$1" in
        --no-zsh)
            WITH_ZSH=false
            ;;
        --no-pyenv)
            WITH_PYENV=false
            ;;
        --no-nvm)
            WITH_NVM=false
            ;;
        --no-rvm)
            WITH_RVM=false
            ;;
        --no-vim)
            WITH_VIM=false
            ;;
        --no-tmux)
            WITH_TMUX=false
            ;;
        --no-clj)
            WITH_CLJ=false
            ;;
        --no-go)
            WITH_GO=false
            ;;
        --no-git)
            WITH_GIT=false
            ;;
        --no-vscode)
            WITH_VSCODE=false
            ;;
        --minimal)
            DOTFILES_MINIMAL=true
            ;;
    esac
    shift
done

DOTFILES_DIR="$(dirname ${0:A})"

cat <<END > "$HOME/.zsh_dotfiles_init"
# Warning: This file is auto-generated by ${0:A}.
# It will be overwritten as soon as ${0:A} is run again.
export DOTFILES_DIR=$DOTFILES_DIR
export DOTFILES_MINIMAL=$DOTFILES_MINIMAL

export ZSH=${ZSH:="$HOME/.oh-my-zsh"}
END

if [ -e "$HOME/.editorconfig" ]
then
    echo "$HOME/.editorconfig exists"
else
    ln -s "$DOTFILES_DIR/.editorconfig" "$HOME/.editorconfig"
fi

$WITH_PYENV  && $DOTFILES_DIR/pyenv/install.zsh
$WITH_NVM  && $DOTFILES_DIR/nvm/install.zsh
$WITH_RVM  && $DOTFILES_DIR/rvm/install.zsh
$WITH_CLJ && $DOTFILES_DIR/leiningen/install.zsh
$WITH_CLJ && $DOTFILES_DIR/clojure/install.zsh
$WITH_GO && $DOTFILES_DIR/go/install.zsh
$WITH_GIT && $DOTFILES_DIR/git/install.zsh
$WITH_TMUX && $DOTFILES_DIR/tmux/install.zsh
$WITH_ZSH  && $DOTFILES_DIR/zsh/install.zsh
$WITH_VIM && $DOTFILES_DIR/vim/install.zsh
$WITH_VSCODE && $DOTFILES_DIR/vscode/install.zsh
