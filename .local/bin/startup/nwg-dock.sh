#!/usr/bin/env bash

# Start nwg-dock-hyprland on the right edge, hidden until the pointer reaches it.
#
# Run from ~/.local/bin/at_startup, which holds a flock and execs each executable
# *.sh once, so this does not need its own reload guard -- but it does check anyway,
# because nwg-dock is meant to be re-run to toggle it and a stray second instance
# would fight the first over the layer surface.
#
# Notes on the flags, all of which matter:
#
#   -d   auto-hide: a hotspot on the right edge reveals the dock, and leaving it hides
#        the dock again. This is what "the dock hides" means here. The hotspot is a
#        real GTK layer-shell hotspot rather than a pointer poll, so it cannot drift
#        out of sync with the pointer the way a poll-based one did.
#   -hd 20  hotspot delay in ms; the smaller, the faster the pointer has to arrive for
#        the dock to appear. 20 is also the tool's default, named explicitly so the
#        reveal does not feel sluggish if that default ever changes.
#   -r   would be "resident without hotspot", i.e. always visible and toggled only by a
#        keybind. That was the previous behaviour and is NOT what is wanted now. Do not
#        pass both -d and -r: -d creates the hotspot, and a permanently visible dock
#        with a hotspot on top of it means the last few pixels of the screen toggle it.
#
#   -p right      the dock lives on the right edge.
#   -i 24         icon size. The waybar is 33px tall, so 24px icons sit in a matching
#                 strip rather than the 48px default, which would be a full-width bar.
#   -w 10         10 workspaces, matching the persistent workspaces in hyprland.lua.
#   -l overlay    layer-shell layer. NOT -x, which sets an exclusive zone and would push
#                 every window sideways to make room for the dock.
#   -lp start     launcher button at the top of the column rather than the bottom.
#
# The dock draws no exclusive zone, so it overlays whatever is under it and does not
# appear in `hyprctl clients`.

# `pgrep -f`, not -x: the process name is 17 characters and pgrep matches at most 15,
# so -x finds nothing and this guard never fires -- meaning a second dock could start
# on every autostart. Verified: `pgrep -f` matches, `pgrep -x` does not.
if pgrep -f 'nwg-dock-hyprland' >/dev/null 2>&1; then
    exit 0
fi

# -s is a bare FILENAME resolved inside ~/.config/nwg-dock-hyprland, not a path.
# Passing a path makes it look for the file under that directory and die with
# "Failed to import: Error opening file .../tmp/style.css: No such file".
setsid nwg-dock-hyprland \
    -d \
    -hd 20 \
    -p right \
    -i 24 \
    -w 10 \
    -l overlay \
    -lp start \
    -s style.css \
    >/dev/null 2>&1 &
