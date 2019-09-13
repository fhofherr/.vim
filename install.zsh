#!/usr/bin/env zsh
DOTFILES_DIR="$(dirname ${0:A})"
ZPLUG_HOME="$HOME/.zplug"

cat <<END > "$HOME/.zsh_dotfiles_init"
# Warning: This file is auto-generated by ${0:A}.
# It will be overwritten as soon as ${0:A} is run again.
export DOTFILES_DIR="$DOTFILES_DIR"
export ZPLUG_HOME="$ZPLUG_HOME"
END
source "$HOME/.zsh_dotfiles_init"
source "$DOTFILES_DIR/lib/functions.zsh"

if [ -e "$HOME/.editorconfig" ]
then
    echo "$HOME/.editorconfig exists"
else
    ln -s "$DOTFILES_DIR/.editorconfig" "$HOME/.editorconfig"
fi

if [ ! -d "$ZPLUG_HOME" ]
then
    git_clone_or_pull "https://github.com/zplug/zplug" "$ZPLUG_HOME"
fi

"$DOTFILES_DIR/zsh/install.zsh"
