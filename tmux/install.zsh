#!/usr/bin/env zsh

if [ -f "$HOME/.zsh_dotfiles_init" ]
then
    source "$HOME/.zsh_dotfiles_init"
else
    echo "Could not find '$HOME/.zsh_dotfiles_init'!"
    echo "Execute over-all install script!"
    exit 1
fi
source "$DOTFILES_DIR/lib/functions.zsh"

TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"
mkdir -p $TMUX_PLUGIN_DIR

TPM_REMOTE_REPO="https://github.com/tmux-plugins/tpm"
git_clone_or_pull $TPM_REMOTE_REPO "$TMUX_PLUGIN_DIR/tpm"

if [ ! -e "$HOME/.tmux.conf" ]
then
    ln -s "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
else
    echo "$HOME/.tmux.conf exists"
fi

if [ ! -e "$HOME/.tmuxline-snapshot.conf" ]
then
    ln -s "$DOTFILES_DIR/tmux/tmuxline-snapshot.conf" "$HOME/.tmuxline-snapshot.conf"
else
    echo "$HOME/tmuxline-snapshot.conf exists"
fi

if ! infocmp tmux-256color > /dev/null 2>&1
then
    echo "Creating tmux terminfo entries"
    tic -x $DOTFILES_DIR/tmux/tmux.terminfo
fi

tmux new-session -s tmux-install -d
tmux run-shell $HOME/.tmux/plugins/tpm/bindings/install_plugins
tmux kill-session -t tmux-install
