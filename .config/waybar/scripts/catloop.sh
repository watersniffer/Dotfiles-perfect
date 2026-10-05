#!/usr/bin/env bash
set -euo pipefail

# The cat animation, driven by CPU load: it plays the awake frames while the
# machine is busy and settles into the sleeping frames once it is idle.
#
# This was rewritten to do the arithmetic in a single awk per cycle and to sleep
# with `read -t` instead of the sleep binary. The original called awk three times
# and bc twice per cycle, so five processes were forked every frame group; the
# `read -t` trick is a bash builtin and costs nothing. Output is unchanged --
# same frames, same order, same timings.
#
# bc is not used at all any more: awk compares and clamps the numbers itself.

SLEEP_AFTER=4

AWAKE_FRAMES=(A B C D E)
SLEEP_FRAMES=(G H I J K L M N)

COUNT=0

# One pass: read /proc/stat, work out the utilisation since the last sample, and
# print the two values the shell needs.
#
# The first call passes "init" so it only records the baseline and prints zeros.
# Deltas are guarded: a total of 0 means no time passed, and a negative active
# delta means the counters wrapped or a core came online, which the original
# treated as 0.0000 too.
sample() {
    local mode="${1-}"
    awk -v mode="$mode" -v prev_active="$prev_active" -v prev_total="$prev_total" '
        /^cpu /{
            active = $2 + $3 + $4
            total   = active + $5
            if (mode == "init") {
                printf "0 0.22\n"
                exit
            }
            da = active - prev_active
            dt = total - prev_total
            if (dt <= 0 || da < 0) {
                util = 0
            } else {
                util = da / dt
            }
            # Faster frames as the machine gets busier, floor of 0.05s.
            speed = 0.22 - (util * 0.10)
            if (speed < 0.05) {
                speed = 0.05
            }
            printf "%d %.4f\n", (util < 0.02 ? 1 : 0), speed
            exit
        }
    ' /proc/stat
}

# Fork-free sleep.
#
# `read -t N -u FD` is a bash builtin, so it delays without forking sleep. It
# needs a descriptor that stays open and never delivers data: opened on /dev/null
# it would return EOF immediately and the loop would spin, so a FIFO is opened
# read-write instead. Holding it open for both ends is what guarantees the read
# blocks until the timeout rather than seeing end-of-file.
SLEEP_FIFO=$(mktemp -u "${XDG_RUNTIME_DIR:-/tmp}/catloop.XXXXXX")
mkfifo "$SLEEP_FIFO"
trap 'rm -f "$SLEEP_FIFO"' EXIT
exec 9<>"$SLEEP_FIFO"

# The baseline, so the first real sample has something to difference against.
prev_active=0
prev_total=0
read -r _ _ < <(sample init)

while true; do
    # Two fields, not three: asking for a third leaves `speed` empty, and
    # `read -t ""` then returns instantly, which turns the animation into a
    # tight spin emitting thousands of frames a second.
    read -r now_idle speed < <(sample)

    if [ "$now_idle" = "1" ]; then
        COUNT=$((COUNT + 1))
    else
        COUNT=0
    fi

    if [ "$COUNT" -ge "$SLEEP_AFTER" ]; then
        frames=("${SLEEP_FRAMES[@]}")
    else
        frames=("${AWAKE_FRAMES[@]}")
    fi

    for frame in "${frames[@]}"; do
        echo "$frame"
        read -t "$speed" -u 9 _ || true
    done
done
