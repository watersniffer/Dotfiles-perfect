#!/usr/bin/env bash
# theme-switcher :: shared helpers
#
# Sourced by ~/.local/bin/theme-switcher. Not executable on its own.
#
# Colour handling convention used throughout:
#
#   * Palettes store opaque #rrggbb only. Nothing stores an rgba() literal.
#   * The handful of translucent surfaces (waybar islands, rofi window) are the
#     only place alpha appears, and it comes from the theme's "alpha" block so it
#     stays a per-theme decision rather than being baked into a colour value.
#   * Everything else is derived, never hand-copied per app. That is why adding
#     an app means adding a renderer in theme-switcher, not editing three files
#     by hand and hoping they stay in sync.

set -euo pipefail

THEME_DIR="${THEME_DIR:-$HOME/.config/theme-switcher}"

# ---------------------------------------------------------------- diagnostics

if [[ -t 2 ]]; then
	_c_dim=$'\033[2m'; _c_red=$'\033[31m'; _c_grn=$'\033[32m'
	_c_yel=$'\033[33m'; _c_blu=$'\033[34m'; _c_bld=$'\033[1m'; _c_off=$'\033[0m'
else
	_c_dim=''; _c_red=''; _c_grn=''; _c_yel=''; _c_blu=''; _c_bld=''; _c_off=''
fi

log()   { printf '%s[theme]%s %s\n' "$_c_blu" "$_c_off" "$*" >&2; }
warn()  { printf '%s[theme]%s %swarning:%s %s\n' "$_c_blu" "$_c_off" "$_c_yel" "$_c_off" "$*" >&2; }
error() { printf '%s[theme]%s %serror:%s %s\n' "$_c_blu" "$_c_off" "$_c_red" "$_c_off" "$*" >&2; }
die()   { error "$*"; exit 1; }
step()  { printf '%s[theme]%s %s->%s %s\n' "$_c_blu" "$_c_off" "$_c_dim" "$_c_off" "$*" >&2; }

# ------------------------------------------------------------------ colour math

# hex2rgb_parts <#rrggbb> -> "r g b"   (space separated, for rgba()/hyprlock)
hex2rgb_parts() {
	local h="${1#\#}"
	printf '%d %d %d' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}

# hex2rgb_commas <#rrggbb> -> "r,g,b"  (hyprctl rgba, kitty, Hyprland borders)
hex2rgb_commas() {
	local h="${1#\#}"
	printf '%d,%d,%d' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}

# hex2rgba <#rrggbb> <alpha> -> "rgba(r,g,b,a)"
#   For CSS/GTK/qt. Bare "rgba(40,40,40,0.85)" with no spaces, which is what
#   GTK's CSS parser and waybar's CSS both want.
hex2rgba() {
	local h="${1#\#}" a="$2"
	printf 'rgba(%d,%d,%d,%s)' \
		"$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))" "$a"
}

# alpha8 <hex> <alpha> -> "0xAARRGGBB" for Hyprland's shadow:color
hex2argb() {
	local h="${1#\#}" a="$2"
	printf '0x%02x%s' $(( (255 - $(printf '%s' "$a" | awk '{printf "%d", $1*255}') ) )) "$h"
}

# hex2ansi_zsh <#rrggbb> -> the literal text  $'\e[38;2;R;G;Bm'
#
# For embedding in a generated .zsh-theme.
#
# This must emit the *text* $'\e[...m', not a raw ESC byte. A raw ESC written
# straight into the file is not what zsh wants: the line becomes
#
#     c_fg=<ESC>[38;2;205;214;244m
#
# which zsh parses as an assignment followed by a nonsense command, producing
# "command not found: 205" for every channel and leaving the colour empty. The
# $'\e' form is zsh's ANSI-C quoting, so zsh builds the escape at runtime.
#
# It also cannot be a "#rrggbb" string: a prompt has no way to use one, and
# inside %{%...%} the %{% %} markers make the contents zero-width, so the hex
# digits are swallowed and the colour silently never appears.
hex2ansi_zsh() {
	local h="${1#\#}"
	printf "%s" "\$'\e[38;2;$((16#${h:0:2}));$((16#${h:2:2}));$((16#${h:4:2}))m'"
}

# hex2reset_zsh -> the literal text  $'\e[0m'
#   Companion to hex2ansi_zsh; kept beside it so the pair cannot drift.
hex2reset_zsh() {
	printf "%s" "\$'\e[0m'"
}

# hex_only <#rrggbb> -> rrggbb
#   Strips the leading '#'. Needed for Hyprland's rgba(), which is written
#   rgba(cba6f7ff): hex channel pairs and a hex alpha suffix, and *not* a '#'.
#   Passing "#cba6f7" through verbatim yields rgba(#cba6f7ff), which Hyprland
#   rejects as an invalid colour and then leaves the option unset.
hex_only() {
	local h="${1#\#}"
	printf '%s' "$h"
}

# hex2truecolor <#rrggbb> -> "38;2;r;g;b"
#   For LS_COLORS. Truecolour rather than a 16-colour index, so `ls` colours
#   are the palette's actual colours rather than the nearest of 16.
hex2truecolor() {
	local h="${1#\#}"
	printf '38;2;%d;%d;%d' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}

# shade <#rrggbb> <delta> -> #rrggbb, each channel clamped to 0..255
#   Positive delta lightens, negative darkens. Used for the few places that need
#   a neighbouring step of a ramp that the palette does not name explicitly.
shade() {
	local h="${1#\#}" d="$2" r g b out
	r=$(( (16#${h:0:2} + d) )); g=$(( (16#${h:2:2} + d) )); b=$(( (16#${h:4:2} + d) ))
	(( r < 0 )) && r=0; (( r > 255 )) && r=255
	(( g < 0 )) && g=0; (( g > 255 )) && g=255
	(( b < 0 )) && b=0; (( b > 255 )) && b=255
	printf '#%02x%02x%02x' "$r" "$g" "$b"
}

# mix <#rrggbb> <#rrggbb> <0-100 percent of second> -> #rrggbb
mix() {
	local a="${1#\#}" b="${2#\#}" p="$3" ar ag ab br bg bb
	ar=$((16#${a:0:2})); ag=$((16#${a:2:2})); ab=$((16#${a:4:2}))
	br=$((16#${b:0:2})); bg=$((16#${b:2:2})); bb=$((16#${b:4:2}))
	printf '#%02x%02x%02x' \
		$(( (ar*(100-p) + br*p) / 100 )) \
		$(( (ag*(100-p) + bg*p) / 100 )) \
		$(( (ab*(100-p) + bb*p) / 100 ))
}

# ------------------------------------------------------------------ file writes

# write_file <path> [mode]
#
# Reads the new content on stdin and writes it only if it differs from what is
# already on disk. Returns 0 when written, 1 when unchanged.
#
# This is the single most important helper in the file. Several renderers below
# feed configs to apps that reload themselves on file change (waybar watches its
# stylesheet, swaync watches its css, kitty reads on SIGUSR1). Rewriting an
# identical file would make every one of those apps restart for nothing, and
# waybar in particular is a visible flash. Skipping no-op writes means
# re-running the switcher is free and idempotent.
#
# Also writes through a temp file + mv so an interrupted run cannot leave a
# half-written config behind.
write_file() {
	local path="$1" mode="${2:-0644}" tmp dir
	dir="$(dirname "$path")"
	mkdir -p "$dir"
	tmp="$(mktemp "$dir/.theme.XXXXXX")"

	cat >"$tmp"
	chmod "$mode" "$tmp"

	if [[ -f "$path" ]] && cmp -s "$tmp" "$path"; then
		rm -f "$tmp"
		return 1
	fi
	mv -f "$tmp" "$path"
	return 0
}

# sed_file <path> <sed args...>
#
# Same idea as write_file but for the handful of configs that are hand-maintained
# and cannot be fully regenerated (hyprlock.conf, rofi's icon-theme line). Edits
# in place, and only reports a change if the result actually differs.
sed_file() {
	local path="$1"; shift
	local tmp
	tmp="$(mktemp)"
	if [[ ! -f "$path" ]]; then
		warn "sed_file: $path does not exist, skipping"
		return 1
	fi
	sed "$@" "$path" >"$tmp"
	if cmp -s "$tmp" "$path"; then
		rm -f "$tmp"
		return 1
	fi
	cat "$tmp" >"$path"   # preserve inode/owner rather than replacing the file
	rm -f "$tmp"
	return 0
}

# ---------------------------------------------------------------- palette access

declare -gA C=()      # colour role -> #rrggbb
declare -gA A=()      # alpha role -> 0..1
declare -gA APP=()    # app selection -> string

load_palette() {
	local file="$1"
	[[ -f "$file" ]] || die "palette not found: $file"

	local k v
	while IFS=$'\t' read -r k v; do
		[[ -n "$k" ]] && C["$k"]="$v"
	done < <(jq -r '.colors | to_entries[] | "\(.key)\t\(.value)"' "$file")

	while IFS=$'\t' read -r k v; do
		[[ -n "$k" ]] && A["$k"]="$v"
	done < <(jq -r '(.alpha // {}) | to_entries[] | "\(.key)\t\(.value)"' "$file")

	while IFS=$'\t' read -r k v; do
		[[ -n "$k" ]] && APP["$k"]="$v"
	done < <(jq -r '(.apps // {}) | to_entries[] | "\(.key)\t\(.value // "")"' "$file")

	# A missing role silently becomes an empty string and then an invalid
	# #rgb in whatever file it lands in. Fail loudly instead, once, here.
	local missing=()
	for k in base bg1 bg2 bg3 bg4 fg fg_bright fg1 fg2 overlay0 overlay2 \
		red green yellow blue magenta cyan orange accent accent2 on_accent \
		urgent destructive success warning error ws_active ws_inactive \
		border_active border_inactive border_soft battery_warn battery_crit \
		cpucat icon_term icon_file icon_edit; do
		[[ -n "${C[$k]:-}" ]] || missing+=("$k")
	done
	if ((${#missing[@]})); then
		die "palette $file is missing colour roles: ${missing[*]}"
	fi

	for k in island island_hover surface border_soft; do
		[[ -n "${A[$k]:-}" ]] || die "palette $file is missing alpha role: $k"
	done

	THEME_NAME="$(jq -r '.name' "$file")"
	THEME_LABEL="$(jq -r '.label' "$file")"
	CURRENT_PALETTE_FILE="$file"
}

# c <role> -> the hex for that role
c() { printf '%s' "${C[$1]}"; }

# a <role> -> the alpha for that role
a() { printf '%s' "${A[$1]}"; }

# rgba <role> <alpha-role> -> rgba() using that role's colour and alpha slot
rgba() { hex2rgba "${C[$1]}" "${A[$2]}"; }

# ------------------------------------------------------------------ theme index

list_themes() {
	local f
	for f in "$THEME_DIR"/themes/*.json; do
		[[ -e "$f" ]] || continue
		jq -r '"\(.name)\t\(.label)\t\(.description)"' "$f"
	done
}

theme_exists() { [[ -f "$THEME_DIR/themes/$1.json" ]]; }

palette_path() { printf '%s/themes/%s.json' "$THEME_DIR" "$1"; }

current_theme() {
	local state="$THEME_DIR/current"
	if [[ -f "$state" ]]; then
		cat "$state"
	else
		printf 'gruvbox'
	fi
}

# theme_label <name> -> the human label, falling back to the name
theme_label() {
	local f="$THEME_DIR/themes/$1.json"
	[[ -f "$f" ]] && jq -r '.label' "$f" || printf '%s' "$1"
}