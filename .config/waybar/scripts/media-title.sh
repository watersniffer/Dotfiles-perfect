#!/usr/bin/env bash

# Media title for the centre of the bar.
#
# This exists because waybar's mpris module always renders a label, even when
# nothing is playing. Styled as one of the bar's island pills, that empty label
# showed up as a stray capsule in the middle of the bar. A custom/ module with
# "hide-empty-text": true drops the module entirely instead, so the pill only
# exists while there is something to show.
#
# Prints "<artist> - <title>" and exits 0 while a player is playing or paused,
# and prints nothing (exit 0) when there is no player, so waybar hides it.

status=$(playerctl status 2>/dev/null) || exit 0

case "$status" in
    Playing) icon="" ;;
    Paused)  icon="󰐊" ;;
    *)       exit 0 ;;
esac

# A title of "artist - title" would read badly doubled up.
meta=$(playerctl metadata --format '{{artist}}	{{title}}' 2>/dev/null) || exit 0
artist=${meta%%$'\t'*}
title=${meta#*$'\t'}

[[ -z $title ]] && exit 0
[[ $artist == "$title" ]] && artist=""

if [[ -n $artist ]]; then
    printf ' %s %s - %s ' "$icon" "$artist" "$title"
else
    printf ' %s %s ' "$icon" "$title"
fi
