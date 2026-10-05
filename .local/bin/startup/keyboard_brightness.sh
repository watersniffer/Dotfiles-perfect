#!/bin/bash

# Only run on machines that expose an ASUS keyboard backlight.
KEYBOARD_DEVICE="asus::kbd_backlight"
if ! brightnessctl -d "$KEYBOARD_DEVICE" g >/dev/null 2>&1; then
    exit 0
fi

BATTERY_STATUS=""
for status_file in /sys/class/power_supply/BAT*/status; do
    if [[ -r "$status_file" ]]; then
        BATTERY_STATUS="$(<"$status_file")"
        break
    fi
done

if [[ "$BATTERY_STATUS" == "Discharging" ]]; then
    brightnessctl -d "$KEYBOARD_DEVICE" -s set 0
else
    brightnessctl -d "$KEYBOARD_DEVICE" -r
    if [[ "$(brightnessctl -d "$KEYBOARD_DEVICE" g)" == "0" ]]; then
        brightnessctl -d "$KEYBOARD_DEVICE" set 1
    fi
fi
