#!/usr/bin/env bash
# ~/.local/bin/startup/awww.sh
#
# Starts the awww wallpaper daemon. awww-daemon re-applies the wallpaper that was
# showing when it was last alive all by itself -- verified by killing it, starting
# it bare, and querying: the same image comes back. There is no --restore flag on
# `awww img` in 0.12.1 (it errors out), so nothing extra is needed here.
#
# Run by ~/.local/bin/at_startup, which executes every executable *.sh in this
# directory exactly once (it holds a flock, so reloads can't stack duplicates).

set -uo pipefail

# already up (a config reload re-running startup, or the user started it)
if pgrep -x awww-daemon >/dev/null 2>&1; then
    exit 0
fi

# awww warns loudly if this is missing
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/awww"

setsid awww-daemon >/dev/null 2>&1 &