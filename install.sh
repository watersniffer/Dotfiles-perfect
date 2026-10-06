#!/usr/bin/env bash
# Install the dotfiles onto a fresh Arch + Hyprland machine.
#
#   ./install.sh              install config files, link nothing, back up what it replaces
#   ./install.sh --packages  also install the packages (needs sudo)
#   ./install.sh --force     overwrite existing files without asking
#   ./install.sh --dry-run   print what would happen, change nothing
#
# Files are copied to $HOME, not symlinked, so the repo stays the source of truth and
# you can edit in place and `git status` still means something. Anything replaced is
# copied into ~/.dotfiles-backup/<timestamp>/ first.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backup"
DO_PACKAGES=0
DO_FORCE=0
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --packages) DO_PACKAGES=1 ;;
        --force)    DO_FORCE=1 ;;
        --dry-run)  DRY_RUN=1 ;;
        -h|--help)  sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) printf 'install.sh: unknown option %s\n' "$arg" >&2; exit 1 ;;
    esac
done

say()  { printf '%s\n' "$*"; }
warn() { printf '  %s\n' "$*" >&2; }
die()  { printf 'install.sh: %s\n' "$*" >&2; exit 1; }

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '  would run: %s\n' "$*"
    else
        "$@"
    fi
}

# --- preflight --------------------------------------------------------------

[[ -d "$REPO_DIR/.config" ]] || die "$REPO_DIR does not look like the dotfiles repo"

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    warn "a Wayland session is running. Copying config will not reload anything that"
    warn "is already running; log out and back in afterwards to pick it all up."
fi

# --- packages ---------------------------------------------------------------

# Grouped by what they are for, so a failure is easy to place.
PACMAN_PKGS=(
    # compositor and its helpers
    hyprland hyprpaper hypridle hyprlock hyprpicker hyprcursor xwayland-videoscale
    # bar, notifications, dock
    waybar swaync nwg-dock-hyprland
    # terminal, editor, shell
    kitty neovim zsh oh-my-zsh
    # tools the config scripts actually call
    grim slurp jq playerctl libnotify brightnessctl wlr-randr
    # fonts referenced by the configs
    ttf-jetbrains-mono-nerd
)

AUR_PKGS=(
    dankcalendar-bin          # Dank Calendar, bound to Super+D
    visual-studio-code-bin     # only if you want the editor; drop otherwise
    opencode-desktop-bin       # only if you want the app; drop otherwise
    whatsie-git                # tray icon helper used by some bars
    yay                        # needed to build the AUR packages
)

install_packages() {
    command -v pacman >/dev/null 2>&1 || die "pacman not found -- this script targets Arch"

    local missing=() p
    for p in "${PACMAN_PKGS[@]}"; do
        pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        say "Installing ${#missing[@]} missing repo packages:"
        printf '  %s\n' "${missing[@]}"
        run sudo pacman -S --needed --noconfirm "${missing[@]}" \
            || die "pacman failed -- fix the error above and re-run"
    else
        say "All repo packages already present."
    fi

    # AUR packages need a helper. Reuse yay if it is there, otherwise offer to clone it.
    local helper=""
    for p in paru yay; do
        command -v "$p" >/dev/null 2>&1 && { helper="$p"; break; }
    done

    if [[ -z "$helper" ]]; then
        warn "No AUR helper found (paru/yay). Skipping: ${AUR_PKGS[*]}"
        warn "Install one, then re-run with --packages."
        return 0
    fi

    local amissing=() p
    for p in "${AUR_PKGS[@]}"; do
        pacman -Qq "$p" >/dev/null 2>&1 || amissing+=("$p")
    done

    if [[ ${#amissing[@]} -eq 0 ]]; then
        say "All AUR packages already present."
        return 0
    fi

    say "Installing ${#amissing[@]} AUR packages with $helper:"
    printf '  %s\n' "${amissing[@]}"
    # sudo is only needed if the helper is setuid; harmless otherwise.
    run sudo -v
    run "$helper" -S --needed --noconfirm "${amissing[@]}" \
        || warn "$helper failed -- install these manually if they matter to you"
}

# --- config copy ------------------------------------------------------------

# Files that are generated at runtime and must not be copied over.
GENERATED=(
    ".config/waybar/colors.css"
    ".config/hypr/theme.lua"
    ".config/nvim/lua/config/theme.lua"
    ".config/nvim/colors/monochrome.lua"
    ".config/theme-switcher/current"
)

is_generated() {
    local rel="$1" g
    for g in "${GENERATED[@]}"; do
        [[ "$rel" == "$g" ]] && return 0
    done
    return 1
}

install_config() {
    local stamp backup_made=0 replaced=0 copied=0 skipped=0
    stamp="$(date +%Y%m%d-%H%M%S)"

    while IFS= read -r -d '' src; do
        local rel="${src#$REPO_DIR/}"

        if is_generated "$rel"; then
            [[ "$DRY_RUN" -eq 1 ]] && say "  skip (generated): $rel"
            continue
        fi

        local dest="$HOME/$rel"

        # mkdir -p the parent, in dry-run too, so the path is printed honestly.
        local parent; parent="$(dirname "$dest")"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            say "  copy: $rel"
        else
            mkdir -p "$parent"
        fi

        if [[ -e "$dest" ]]; then
            if [[ -n "$(diff -q "$src" "$dest" 2>/dev/null)" ]]; then
                if [[ "$DO_FORCE" -eq 0 ]]; then
                    if [[ "$DRY_RUN" -eq 1 ]]; then
                        say "    (exists and differs -- would back up and replace)"
                        continue
                    fi
                    warn "replacing existing $rel"
                fi

                if [[ "$backup_made" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
                    mkdir -p "$BACKUP_ROOT/$stamp"
                    backup_made=1
                fi
                [[ "$DRY_RUN" -eq 0 ]] && cp -a "$dest" "$BACKUP_ROOT/$stamp/$(dirname "$rel")" 2>/dev/null || true
                replaced=$((replaced + 1))
            else
                skipped=$((skipped + 1))
                continue
            fi
        fi

        copied=$((copied + 1))
        run cp -a "$src" "$dest"
    done < <(find "$REPO_DIR" -type f \
        -not -path "$REPO_DIR/.git/*" \
        -not -name '.gitignore' \
        -not -name 'install.sh' \
        -not -name 'README.md' -print0)

    say ""
    say "Config: $copied written, $replaced replaced, $skipped already current."
    if [[ "$backup_made" -eq 1 ]]; then
        say "Backups of anything replaced: $BACKUP_ROOT/$stamp"
    fi
}

# --- post-install -----------------------------------------------------------

post_install() {
    say ""
    say "After logging back in:"

    if [[ ! -e "$HOME/.config/.bluetooth.pref" ]]; then
        say "  * Super+T opens the theme picker. The generated colour files are"
        say "    written on first switch, not copied in."
    fi

    cat <<'EOF'

  * Super+P toggles Planify and Super+D toggles Dank Calendar, each on its own
    special workspace. Neither needs a launcher script.

  * Bluetooth powers on at login via ~/.local/bin/startup/bluetooth.sh, which
    at_startup runs automatically. To pin a device, put its MAC in
    ~/.config/.bluetooth.pref -- otherwise the first paired device is used.

  * If the hosts blocklist is wanted:
        sudo ~/.local/bin/hosts-blocklist update     # fetch and apply
        sudo ~/.local/bin/hosts-blocklist disable    # park it temporarily
        sudo ~/.local/bin/hosts-blocklist enable     # put it back

  * Fonts matter: the bar and the theme use JetBrainsMono Nerd Font. Without it
    the icons render as boxes.

  * Wallpapers are read from ~/Pictures/Wallpapers by the theme switcher.
EOF
}

# --- main -------------------------------------------------------------------

say "Dotfiles install"
say "  repo:  $REPO_DIR"
say "  home:  $HOME"
say ""

if [[ "$DO_PACKAGES" -eq 1 ]]; then
    install_packages
else
    say "Skipping packages. Re-run with --packages to install them."
fi

install_config

if [[ "$DRY_RUN" -eq 1 ]]; then
    say ""
    say "Dry run -- nothing was changed."
    exit 0
fi

post_install