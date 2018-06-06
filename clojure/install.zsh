#!/usr/bin/env zsh

if [ -f "$HOME/.zsh_dotfiles_init" ]
then
    source "$HOME/.zsh_dotfiles_init"
else
    echo "Could not find '$HOME/.zsh_dotfiles_init'!"
    echo "Execute over-all install script!"
    exit 1
fi

CLOJURE_HOME="$HOME/.clojure"
mkdir -p $CLOJURE_HOME

if [ ! -e "$CLOJURE_HOME/deps.edn" ]
then
    ln -s "$DOTFILES_DIR/clojure/deps.edn" "$CLOJURE_HOME/deps.edn"
else
    echo "$CLOJURE_HOME/deps.edn exists"
fi


