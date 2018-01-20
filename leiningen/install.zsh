#!/usr/bin/env zsh

if [ -f "$HOME/.zsh_dotfiles_init" ]
then
    source "$HOME/.zsh_dotfiles_init"
else
    echo "Could not find '$HOME/.zsh_dotfiles_init'!"
    echo "Execute over-all install script!"
    exit 1
fi

LEIN_HOME="$HOME/.lein"
mkdir -p $LEIN_HOME

if [ ! -e "$LEIN_HOME/profiles.clj" ]
then
    ln -s "$DOTFILES_DIR/leiningen/profiles.clj" "$LEIN_HOME/profiles.clj"
else
    echo "$LEIN_HOME/profiles.clj exists"
fi


