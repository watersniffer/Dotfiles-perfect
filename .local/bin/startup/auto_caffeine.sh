#!/usr/bin/env bash

CAFFEINE="$HOME/.local/bin/caffeine"

# Already watching profile changes? Don't stack a second gdbus monitor loop.
# (^gdbus: anchored so arbitrary cmdlines merely *mentioning* this can't match)
if pgrep -f "^gdbus monitor --system --dest net\.hadess\.PowerProfiles" >/dev/null 2>&1; then
    exit 0
fi

# powerprofilesctl comes from power-profiles-daemon; without it just keep the
# screen awake instead of erroring on every startup.
if ! command -v powerprofilesctl >/dev/null 2>&1; then
    "$CAFFEINE" --on >/dev/null 2>&1 &
    exit 0
fi

if [[ $(powerprofilesctl get) != "power-saver" ]] ; then
    "$CAFFEINE" --on & 
fi

gdbus monitor \
    --system \
    --dest net.hadess.PowerProfiles \
    --object-path /net/hadess/PowerProfiles |
while IFS= read -r line; do
    case "$line" in
        *"PropertiesChanged"* )

        profile=$(printf "%s\n" "$line" | awk -F"<'|'>" '/ActiveProfile/{print $2}')
        
        if [[ "$profile" == "power-saver" ]]; then 
            "$CAFFEINE" --off &
        else
            "$CAFFEINE" --on &
        fi
        ;;
    esac
done
