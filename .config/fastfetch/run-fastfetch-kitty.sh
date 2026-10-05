#!/usr/bin/env bash
# Run fastfetch with this machine's config.
#
# Called from ~/.bashrc when an interactive kitty shell starts (once per kitty
# instance -- see the hook there). Kept as a separate script because that is the
# name the dotfiles shipped, so anything else that expects to call it still works.
#
# The config path is passed explicitly: fastfetch picks up config.jsonc from
# ~/.config/fastfetch on its own, but being explicit means this keeps working if
# that lookup ever changes, and it documents which file holds the logo.

set -uo pipefail

exec fastfetch --config "$HOME/.config/fastfetch/config.jsonc" "$@"