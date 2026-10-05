# Dotfiles-perfect

My Hyprland desktop: compositor config, Waybar, swaync, the dock, Neovim, Kitty, and the
theme switcher that ties their colours together.

Arch Linux, Wayland, Hyprland. No install script — this is the config as it actually runs,
kept readable rather than made portable.

## Layout

Files mirror the paths they live at, so `.config/hypr/hyprland.lua` is
`~/.config/hypr/hyprland.lua`.

    .config/
      hypr/            compositor: config, lock, idle, wallpaper, theme colours
      waybar/          bar config, stylesheet, module scripts
      swaync/          notification centre
      nwg-dock-hyprland/   right-edge dock, auto-hiding
      nvim/            Neovim (lazy.nvim)
      kitty/           terminal
      theme-switcher/  palettes (JSON) + shared shell helpers
      btop/ cava/ fastfetch/ qt6ct/ gtk-3.0-style bits
    .local/bin/        scripts on PATH, and startup/ for the session ones
    .zshrc .bashrc .tmux.conf .vimrc

## Themes

Three palettes, switched with **Super+T**:

- **Gruvbox Dark**
- **Catppuccin Mocha**
- **Monochrome** — AMOLED true black

`theme-switcher` reads a palette from `.config/theme-switcher/themes/<name>.json` and renders
it into every config that can be coloured — Hyprland borders, Waybar, swaync, the dock,
Kitty, Neovim, Kvantum, zsh prompt, and Firefox via `user.js`.

The files it writes are generated and gitignored: `waybar/colors.css`, `hypr/theme.lua`,
`nvim/lua/config/theme.lua`, `nvim/colors/monochrome.lua`.

## Things worth knowing before editing

These are the traps that cost real time, not style preferences.

**Waybar.** `color` and `font-size` set on `#workspaces button` are silently dropped — a
GtkButton does not draw its own text. They must go on `#workspaces button label`.
`background` and `border-bottom` on the same selector do work.

**Waybar.** `format-icons` values are text drawn by Pango; there is no icon-theme lookup in
that path. So "filled vs hollow diamond" has to be a different character, not a CSS fill.
`workspace-taskbar` is compiled into 0.15.0-3 but inert, and `wlr/taskbar` needs
`zwlr_foreign_toplevel_manager_v1`, which Hyprland does not implement.

**Waybar.** An unknown CSS property is a fatal parse error and waybar refuses to start.
GTK3 has no custom properties, so theming goes through `@define-color`; swaync is the
exception because it uses GTK4.

**Waybar geometry.** The inset and background live on `window#waybar > box`, not on
`window#waybar`. A layer-shell surface always spans the full output width, so margin on the
window itself is ignored. Horizontal margins must be in px — a percentage is a parse error.

**Hyprland config is Lua**, not the usual `key = value` syntax. `hyprctl dispatch focuswindow
<addr>` fails to parse; use `hl.dsp.*` with a table. `dofile()` works for including another
file, since there is no `source =` equivalent in Lua.

**Hyprland binds.** `hl.dsp.window.resize` needs `relative = true` for deltas; without it
x/y are an absolute size and a negative delta is rejected as invalid.

**Hyprland reloads.** `hyprctl reload` re-executes the config. `hyprctl reload config-only`
does not touch windows. Never loop a reload.

**Hyprland paths.** Scripts are on `PATH` via `~/.local/bin`, added in the config.

**nwg-dock-hyprland.** `-s` takes a bare filename resolved inside
`~/.config/nwg-dock-hyprland/`, not a path. `pgrep -x` fails on this name — it is longer
than 15 characters — so use `pgrep -f`.

**Not committed.** SSH keys, `/etc/hosts`, browser profiles, caches. `hosts-blocklist` is
included as a script only; its managed block lives in `/etc/hosts` and is toggled with
`hosts-blocklist disable` / `enable`.
