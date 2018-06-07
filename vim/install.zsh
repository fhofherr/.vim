#!/usr/bin/env zsh

if [ -f "$HOME/.zsh_dotfiles_init" ]
then
    source "$HOME/.zsh_dotfiles_init"
else
    echo "Could not find '$HOME/.zsh_dotfiles_init'!"
    echo "Execute over-all install script!"
    exit 1
fi

MINIMAL=false
while [ $# -gt 0 ]; do
    case "$1" in
        --minimal)
            MINIMAL=true
            ;;
    esac
    shift
done

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
    ln -s "$DOTFILES_DIR/vim/init.vim" "$HOME/.vimrc"
fi

if [ -e "$XDG_CONFIG_HOME/nvim" ];
then
    echo "$XDG_CONFIG_HOME/nvim exists"
else
    ln -s "$DOTFILES_DIR/vim" "$XDG_CONFIG_HOME/nvim"
fi

if which /usr/local/bin/pip2 > /dev/null
then
    PIP2="/usr/local/bin/pip2"
elif which /usr/bin/pip2 > /dev/null
then
    PIP2="/usr/bin/pip2"
fi

if which /usr/local/bin/pip3 > /dev/null
then
    PIP3="/usr/local/bin/pip3"
elif which /usr/bin/pip3 > /dev/null
then
    PIP3="/usr/bin/pip3"
fi

if which /usr/local/bin/pip > /dev/null
then
    PIP="/usr/local/bin/pip"
elif which /usr/bin/pip > /dev/null
then
    PIP="/usr/bin/pip"
fi



if $USE_NVIM
then
    py_provider_installed=false
    echo "Installing NeoVim python providers"
    if [ -n "$PIP2" ]
    then
        $PIP2 install --user --upgrade neovim > /dev/null
        echo "Installed NeoVim Python2 provider"
        py_provider_installed=true
    fi
    if [ -n "$PIP3" ]
    then
        $PIP3 install --user --upgrade neovim > /dev/null
        echo "Installed NeoVim Python3 provider"
        py_provider_installed=true
    fi
    if ! $py_provider_installed
    then
        if [ -n "$PIP" ]
        then
            $PIP install --user --upgrade neovim > /dev/null
        else
            echo "Could not find pip. No python providers installed"
        fi
    fi
fi

if [ ! -e "$DOTFILES_DIR/vim/local.vim" ]; then
    cp "$DOTFILES_DIR/vim/local.vim.template" "$DOTFILES_DIR/vim/local.vim"
fi

if $MINIMAL; then
    sed -i .bak -e 's/local_vim_minimal=.*/local_vim_minimal=1/g' "$DOTFILES_DIR/vim/local.vim"
else
    sed -i .bak -e 's/local_vim_minimal=.*/local_vim_minimal=0/g' "$DOTFILES_DIR/vim/local.vim"
fi

echo "Installing vim plugins"
$VIM -E -c 'PlugUpdate' -c 'qall!' > /dev/null
