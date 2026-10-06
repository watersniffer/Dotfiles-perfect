#!/bin/bash
# Power bluetooth on at startup and reconnect the preferred/last paired device.
#
# The previous version of this script turned bluetooth OFF when the connect failed
# (a cleanup() that ran `bluetoothctl power off` + `rfkill block bluetooth`). That is
# backwards for the point of the script: a device that is out of range or still
# reconnecting at boot is the common case, and it left the adapter off for the whole
# session. Nothing here powers bluetooth off.
#
# Run by ~/.local/bin/at_startup, which executes every executable *.sh in this
# directory. Bluetooth is often not ready this early, so this waits for the adapter
# rather than assuming it.

# --- wait for the adapter to exist -----------------------------------------
# bluetooth.service is enabled, but at session start hci0 may not be registered yet
# and `bluetoothctl show` fails until it is. Bounded so a missing adapter cannot
# leave this retrying forever.
ADAPTER_READY=0
for _ in {1..20}; do
    if bluetoothctl show >/dev/null 2>&1; then
        ADAPTER_READY=1
        break
    fi
    sleep 0.5
done

if [[ "$ADAPTER_READY" -eq 0 ]]; then
    exit 0
fi

# --- unblock, then power on ------------------------------------------------
# rfkill is separate from the BlueZ power state: a soft block survives reboot state
# and makes `power on` appear to succeed while doing nothing.
rfkill unblock bluetooth 2>/dev/null
sleep 0.5
bluetoothctl power on >/dev/null 2>&1

if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    exit 0
fi

# --- pick a device ----------------------------------------------------------
# Preference order: $BLUETOOTH_PREFERRED_DEV, then ~/.config/.bluetooth.pref, then
# the first paired device. None of these is required -- if there is nothing to
# connect to, bluetooth simply stays powered on and idle.
MAC=""
if [[ -n "${BLUETOOTH_PREFERRED_DEV:-}" ]]; then
    MAC="$BLUETOOTH_PREFERRED_DEV"
elif [[ -r "$HOME/.config/.bluetooth.pref" ]]; then
    MAC="$(<"$HOME/.config/.bluetooth.pref")"
else
    # "Device <MAC> <alias>" -- the MAC starts at offset 7 and is 17 characters.
    LAST_DEVICE="$(bluetoothctl devices Paired 2>/dev/null | grep "Device" | head -n 1)"
    MAC="${LAST_DEVICE:7:17}"
fi

# Trim whitespace; a pref file written with a trailing newline yields an invalid MAC.
MAC="$(printf '%s' "$MAC" | tr -d '[:space:]')"

if [[ -z "$MAC" || ${#MAC} -ne 17 ]]; then
    exit 0
fi

# --- connect ---------------------------------------------------------------
# A failure here is normal and is ignored: the device may be out of range or asleep.
# Retried a few times because at boot the adapter has usually not finished
# enumerating. The adapter stays powered on regardless.
for attempt in 1 2 3; do
    if bluetoothctl connect "$MAC" >/dev/null 2>&1; then
        DEVICE_NAME="$(bluetoothctl info "$MAC" 2>/dev/null \
            | sed -n 's/^[[:space:]]*Alias:[[:space:]]*//p')"
        notify-send --icon=bluetooth \
                    --app-name=bluetooth \
                    "Connection successful" "Connected to \"${DEVICE_NAME:-$MAC}\"" 2>/dev/null
        exit 0
    fi
    sleep 3
done

exit 0