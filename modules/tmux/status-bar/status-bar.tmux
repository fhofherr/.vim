#!/usr/bin/env bash
# shellcheck disable=SC2034

set -Eeuo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function dracula() {
    ## Obtained form: https://github.com/dracula/base16-dracula-scheme/blob/master/dracula.yaml
    COLOR_BASE00="#282936"
    COLOR_BASE01="#3a3c4e"
    COLOR_BASE02="#4d4f68"
    COLOR_BASE03="#626483"
    COLOR_BASE04="#62d6e8"
    COLOR_BASE05="#e9e9f4"
    COLOR_BASE06="#f1f2f8"
    COLOR_BASE07="#f7f7fb"
    COLOR_BASE08="#ea51b2"
    COLOR_BASE09="#b45bcf"
    COLOR_BASE0A="#00f769"
    COLOR_BASE0B="#ebff87"
    COLOR_BASE0C="#a1efe4"
    COLOR_BASE0D="#62d6e8"
    COLOR_BASE0E="#b45bcf"
    COLOR_BASE0F="#00f769"
}

function gruvbox_dark() {
    # Obtained from: https://github.com/dawikur/base16-gruvbox-scheme/blob/master/gruvbox-dark-medium.yaml
    COLOR_BASE00="#282828"
    COLOR_BASE01="#3c3836"
    COLOR_BASE02="#504945"
    COLOR_BASE03="#665c54"
    COLOR_BASE04="#bdae93"
    COLOR_BASE05="#d5c4a1"
    COLOR_BASE06="#ebdbb2"
    COLOR_BASE07="#fbf1c7"
    COLOR_BASE08="#fb4934"
    COLOR_BASE09="#fe8019"
    COLOR_BASE0A="#fabd2f"
    COLOR_BASE0B="#b8bb26"
    COLOR_BASE0C="#8ec07c"
    COLOR_BASE0D="#83a598"
    COLOR_BASE0E="#d3869b"
    COLOR_BASE0F="#d65d0e"
}

function gruvbox_light() {
    ## Obtained from: https://github.com/dawikur/base16-gruvbox-scheme/blob/master/gruvbox-light-medium.yaml
    COLOR_BASE00="#fbf1c7"
    COLOR_BASE01="#ebdbb2"
    COLOR_BASE02="#d5c4a1"
    COLOR_BASE03="#bdae93"
    COLOR_BASE04="#665c54"
    COLOR_BASE05="#504945"
    COLOR_BASE06="#3c3836"
    COLOR_BASE07="#282828"
    COLOR_BASE08="#9d0006"
    COLOR_BASE09="#af3a03"
    COLOR_BASE0A="#b57614"
    COLOR_BASE0B="#79740e"
    COLOR_BASE0C="#427b58"
    COLOR_BASE0D="#076678"
    COLOR_BASE0E="#8f3f71"
    COLOR_BASE0F="#d65d0e"
}

function onehalf_dark() {
    # Obtained from: https://github.com/LalitMaganti/base16-onedark-scheme/blob/master/onedark.yaml
    COLOR_BASE00="#282c34"
    COLOR_BASE01="#353b45"
    COLOR_BASE02="#3e4451"
    COLOR_BASE03="#545862"
    COLOR_BASE04="#565c64"
    COLOR_BASE05="#abb2bf"
    COLOR_BASE06="#b6bdca"
    COLOR_BASE07="#c8ccd4"
    COLOR_BASE08="#e06c75"
    COLOR_BASE09="#d19a66"
    COLOR_BASE0A="#e5c07b"
    COLOR_BASE0B="#98c379"
    COLOR_BASE0C="#56b6c2"
    COLOR_BASE0D="#61afef"
    COLOR_BASE0E="#c678dd"
    COLOR_BASE0F="#be5046"
}

function onehalf_light() {
    # Obtained from: https://github.com/purpleKarrot/base16-one-light-scheme/blob/master/one-light.yaml
    COLOR_BASE00="#fafafa"
    COLOR_BASE01="#f0f0f1"
    COLOR_BASE02="#e5e5e6"
    COLOR_BASE03="#a0a1a7"
    COLOR_BASE04="#696c77"
    COLOR_BASE05="#383a42"
    COLOR_BASE06="#202227"
    COLOR_BASE07="#090a0b"
    COLOR_BASE08="#ca1243"
    COLOR_BASE09="#d75f00"
    COLOR_BASE0A="#c18401"
    COLOR_BASE0B="#50a14f"
    COLOR_BASE0C="#0184bc"
    COLOR_BASE0D="#4078f2"
    COLOR_BASE0E="#a626a4"
    COLOR_BASE0F="#986801"
}

function iceberg_light() {
    COLOR_BASE01="#e8e9ec"
    COLOR_BASE04="#33374c"
    COLOR_BASE06="#89b8c2"
}

function iceberg_dark() {
    COLOR_BASE01="#161821"
    COLOR_BASE04="#c6c8d1"
    COLOR_BASE06="#3f83a6"
}

function set_option() {
    command tmux set-option -g "$@"
}

function set_window_option() {
    command tmux set-window-option -g "$@"
}

function main() {
    case "${DOTFILES_COLOR_SCHEME:-}" in
    "dracula") dracula ;;
    "gruvbox-dark") gruvbox_dark ;;
    "gruvbox-light") gruvbox_light ;;
    "iceberg-light") iceberg_light ;;
    "iceberg-dark") iceberg_dark ;;
    "onehalf-dark") onehalf_dark ;;
    "onehalf-light") onehalf_light ;;
    *) gruvbox_dark ;;
    esac

    set_option status on
    set_option status-position top
    set_option status-justify centre
    set_option status-keys vi

    set_option status-left "#H"
    set_option status-left-length 100

    set_option status-right "up:#(uptime | cut -f 4-5 -d ' ' | cut -f 1 -d ',') %a %Y-%m-%d %H:%M "
    set_option status-right-length 100

    set_option status-bg "$COLOR_BASE01"
    set_option status-fg "$COLOR_BASE04"

    local window_flags=" #I #W "
    set_window_option window-status-format "#[fg=${COLOR_BASE04}]#[bg=${COLOR_BASE01}]${window_flags}"
    set_window_option window-status-current-format "#[fg=${COLOR_BASE04}]#[bg=${COLOR_BASE06}]${window_flags}"
    set_window_option window-status-activity-style "bold"
    set_window_option window-status-bell-style "bold"
}

main
