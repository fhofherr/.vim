#!/usr/bin/env zsh

if [ -f "$HOME/.zsh_dotfiles_init" ]
then
    source "$HOME/.zsh_dotfiles_init"
else
    echo "Could not find '$HOME/.zsh_dotfiles_init'!"
    echo "Execute over-all install script!"
    exit 1
fi

VIM=$(which nvim)
USE_NVIM=true
if [ -z "$VIM" ]
then
    VIM=$(which vim)
    USE_NVIM=false
    if [ -z "$VIM" ]
    then
        echo "Could not find nvim or vim"
        exit 1
    fi
fi

if [ -z "$XDG_CONFIG_HOME" ]
then
    XDG_CONFIG_HOME="$HOME/.config"
fi
mkdir -p $XDG_CONFIG_HOME

if [ -e "$HOME/.vim" ]
then
    echo "$HOME/.vim exists"
else
    ln -s "$DOTFILES_DIR/vim" "$HOME/.vim"
fi

if [ -e "$HOME/.vimrc" ]
then
    echo "$HOME/.vimrc exists"
else
    ln -s "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"
fi

if [ -e "$XDG_CONFIG_HOME/nvim" ];
then
    echo "$XDG_CONFIG_HOME/nvim exists"
else
    ln -s "$DOTFILES_DIR/vim/nvim" "$XDG_CONFIG_HOME/nvim"
fi

if $USE_NVIM
then
    py_provider_installed=false
    echo "Installing NeoVim python providers"
    if which pip2 > /dev/null
    then
        pip2 install --user --upgrade neovim > /dev/null
        echo "Installed NeoVim Python2 provider"
        py_provider_installed=true
    fi
    if which pip3 > /dev/null
    then
        pip3 install --user --upgrade neovim > /dev/null
        echo "Installed NeoVim Python3 provider"
        py_provider_installed=true
    fi
    if ! $py_provider_installed
    then
        if which pip > /dev/null
        then
            pip install --user --upgrade neovim > /dev/null
        else
            echo "Could not find pip. No python providers installed"
        fi
    fi
fi

echo "Installing vim plugins"
$VIM -E -c 'PlugUpdate' -c 'qall!' > /dev/null
