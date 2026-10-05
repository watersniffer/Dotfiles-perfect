#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# user-local scripts (wallpaper-switcher, the awww transition shim, etc.)
export PATH="$HOME/.local/bin:$PATH"

# Run fastfetch once when a kitty window opens.
#
# kitty has no startup-exec option: `startup_session` takes a *session file*
# path, not a command, and there is no `exec`-style option in its config. So the
# hook goes in the shell rc instead, which every kitty window starts anyway.
#
# Guarded three ways so it never misfires:
#   KITTY_WINDOW_ID  only kitty sets this, so fish/zellij/ssh sessions skip it
#   -t 1             a real terminal, not a piped or backgrounded shell
#   $- contains i    interactive, so `kitty -e somecommand` never triggers it
#
# KITTY_LISTEN_ON is identical for every window of one kitty instance, so marking
# it in XDG_RUNTIME_DIR (cleared at logout) means fastfetch runs on the FIRST
# window only. Open more tabs/windows and you get a plain prompt, which is what
# you want -- a 14-line logo every time is noise.
if [ -n "${KITTY_WINDOW_ID:-}" ] && [ -t 1 ] && [[ $- == *i* ]]; then
    # KITTY_LISTEN_ON is the right key (identical for every window of one kitty
    # instance) but it is not always exported -- a login shell started by kitty
    # does not necessarily inherit it. Falling back to $$ gave every shell its own
    # marker, so fastfetch ran on every single command instead of once per kitty.
    # Fall back to the kitty ancestor's PID instead: stable for the whole instance.
    if [ -n "${KITTY_LISTEN_ON:-}" ]; then
        __ff_id=$(printf '%s' "$KITTY_LISTEN_ON" | tr -c 'A-Za-z0-9' '_')
    else
        __ff_pid=$$
        for _i in 1 2 3 4 5 6 7 8; do
            __ff_ppid=$(awk '{print $4}' "/proc/$__ff_pid/stat" 2>/dev/null) || break
            [ -r "/proc/$__ff_ppid/comm" ] || break
            [ "$(cat "/proc/$__ff_ppid/comm" 2>/dev/null)" = "kitty" ] && { __ff_pid=$__ff_ppid; break; }
            __ff_pid=$__ff_ppid
        done
        __ff_id="_kitty${__ff_pid}"
    fi
    __ff_marker="${XDG_RUNTIME_DIR:-/tmp}/.fastfetch-${__ff_id}"
    if [ ! -e "$__ff_marker" ]; then
        : > "$__ff_marker"
        "$HOME/.config/fastfetch/run-fastfetch-kitty.sh" 2>/dev/null || true
    fi
    unset __ff_id __ff_marker __ff_pid __ff_ppid _i
fi
