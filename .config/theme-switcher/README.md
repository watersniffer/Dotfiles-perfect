# theme-switcher

One palette, applied across the whole session. Press **Super+T**, pick a theme,
and every colourable thing on the machine follows.

```
theme-switcher                  # rofi picker (bound to Super+T)
theme-switcher --list           # what's installed
theme-switcher --current        # what's active
theme-switcher --preview <name> # show a palette without applying it
theme-switcher catppuccin-mocha # apply directly
theme-switcher --dry-run mono   # show what would change, change nothing
```

## Layout

```
~/.config/theme-switcher/
├── themes/
│   ├── gruvbox.json            # the palette that was already active
│   ├── catppuccin-mocha.json
│   └── monochrome.json
├── lib/common.sh               # colour maths + file writers
├── current                     # name of the active theme
├── zsh/
│   ├── themes/<name>.zsh-theme # generated oh-my-zsh prompt
│   └── lscolors.zsh            # generated LS_COLORS
└── README.md

~/.local/bin/theme-switcher     # the script
~/.local/bin/kitty              # wrapper, see "kitty" below
```

Palettes are **data**; the apps it reaches are **code**. Adding a fourth theme
means dropping a JSON file in `themes/`. Adding a fifth app means adding a
`render_*` function to the script. The two are independent, and neither needs
the other edited.

## Adding a theme

Copy an existing palette, edit the colours, add it to `apps`:

```jsonc
{
  "name": "my-theme",
  "label": "My Theme",
  "apps": {
    "gtk_theme":      "Adwaita-dark",     // must exist under ~/.themes or /usr/share/themes
    "icon_theme":     "Papirus-Dark",     // must exist in an icon dir
    "kvantum_theme":  "KvDark",           // must exist under ~/.config/Kvantum or /usr/share/Kvantum
    "nvim_colorscheme": "gruvbox",        // gruvbox | catppuccin | monochrome
    "wallpaper": null                     // optional path; only applied if the file exists
  },
  "alpha": { "island": 0.85, "island_hover": 0.9, "surface": 0.85, "border_soft": 0.80 },
  "colors": { /* ... the 38 roles ... */ },
  "hyprlock": { /* nine rgba() literals, see "hyprlock" below */ }
}
```

`load_palette()` in `lib/common.sh` validates that all 38 colour roles and all 4
alpha roles are present and fails loudly if any is missing, so a typo in a new
palette is caught before anything is written rather than turning up as an
invalid colour in one app.

The role names are deliberately generic (`base`, `bg1`..`bg4`, `fg`, `fg0`..`fg2`,
the eight hues, `accent`, `urgent`, and so on) rather than theme-specific
(`bg1` is #1d2021 on gruvbox, #181825 on catppuccin, #0e0e0e on monochrome).
That is what lets one renderer serve all themes.

### Why `hyprlock` and `mako` are special

`mako/config` is fully regenerated, geometry and font included, because the
renderer owns the whole file.

`hyprlock.conf` is the opposite: it is a 180-line hand-written layout that is not
worth regenerating, and hyprlock 0.9.6 has no `source=`. So its nine colour
literals are patched **in place, by position** — the first `color`/`outer_color`/
`inner_color`/`font_color` line in the file is the clock, the second the date, and
so on. Matching by position rather than by value is what makes repeated
switching work: a value-based sed only knows how to replace the colours that
happened to be there originally, so the second switch in any direction would
silently do nothing. The clock colour in particular is a per-theme design
decision, so those nine values live in the palette rather than being derived.

## What it actually changes

| Target | Mechanism | Picks up changes |
|---|---|---|
| Hyprland borders, shadow | `~/.config/hypr/theme.lua`, `dofile`d by `hyprland.lua` | `hyprctl reload config-only` |
| Waybar | `colors.css`, which `style.css` `@import`s | live (SIGUSR2) |
| rofi | `colors.rasi`, which `config.rasi` already imports | next launch |
| kitty | `current-theme.conf`, already `include`d by `kitty.conf` | live (remote control) |
| GTK 3 / GTK 4 / libadwaita | `gtk-{3,4}.0/colors.css` + gsettings | new windows |
| Qt 6 / Qt 5 | `qt6ct/qt6ct.conf`, `qt5ct/qt5ct.conf`, Kvantum theme | restart the app |
| mako | full config rewrite | live (SIGHUP) |
| swaync / wlogout | appended CSS block | live / restart |
| btop | generated `.theme` + `color_theme` in `btop.conf` | next launch |
| mpv | `mpv.conf` | next launch |
| Neovim | generated `theme.lua` + a generated `monochrome` scheme | new instance |
| zsh prompt + `LS_COLORS` | generated prompt theme + `lscolors.zsh` | new shell |
| hyprlock | nine literals patched by position | next lock |
| Firefox | `userChrome.css` + `user.js` in the active profile | restart Firefox |
| VS Code | `workbench.colorTheme` + `colorCustomizations` | new window |
| Wallpaper picker | `apps.wallpaper_dir` per palette | Super+W |
| Wallpaper | random image from `apps.wallpaper_dir`, via `awww` | immediately |

Switching theme applies a **random** wallpaper from that theme's folder, with a
1.5 s fade. This is the one part of a switch that is deliberately *not*
idempotent — everything else skips unchanged work, and a second run picking a
second picture is the point. `--no-wallpaper` turns it off. Setting
`apps.wallpaper` to a specific file pins a theme to one picture instead of
picking at random.

Folders, as they are on disk:

| theme | folder | images |
|---|---|---|
| `gruvbox` | `~/Pictures/Wallpapers/Gruvbox` | 253 |
| `monochrome` | `~/Pictures/Wallpapers/Monochrome` | 161 |
| `catppuccin-mocha` | `~/Pictures/Wallpapers/Catppucin` | 333 (sic, misspelled on disk) |

`wallpaper-switcher` asks `theme-switcher --wallpaper-dir` which folder to open
rather than reading a palette itself, so the theme → folder mapping exists in
exactly one place. An argument still overrides it (`wallpaper-switcher Gruvbox`,
or an absolute path), and it falls back to the wallpapers root if the active
theme has no folder.

## Monochrome is AMOLED

`base` and `bg1` are `#000000` — true black, so an OLED panel switches those
pixels off rather than showing a very dark grey that still burns power. The ramp
climbs steeply from there (`#080808`, `#121212`, `#1c1c1c`) and the text ramp is
finer than a plain grey scale (`#ededed` / `#c4c4c4` / `#9a9a9a`) so
grey-on-black stays legible. Its alpha values are higher than the other two
themes' (0.90–0.92 instead of 0.85), because a translucent near-grey surface
defeats the point of a black one. Only `blue` (`#8ab4f8`) carries chroma, as the
single accent.

### Details that are easy to get wrong

**Nothing is written unless it changed.** `write_file()` compares and skips.
Several targets watch their own config file and restart on change, so rewriting
an identical file makes Waybar flicker for nothing. Re-running the switcher for
the theme that is already active is free and idempotent — except the wallpaper,
which rolls a new picture on purpose.

**awww's flags are not swww's.** The wallpaper is set with
`awww img --transition-type fade --transition-duration 1.5`. `--transition-fade`,
the swww spelling, is rejected outright: `error: unexpected argument
'--transition-fade' found`. Note that `simple` — awww's default — ignores
`--transition-duration` entirely, which is why `fade` is named explicitly.

**Wallpaper selection is NUL-delimited.** A folder with 333 curated wallpapers is
exactly where you find `my holiday (2).jpg` and the occasional stray newline, so
the candidates come from `find -print0 | sort -z` into `mapfile -d ''` rather
than from a word-split pipeline.

**Hand-written files are never regenerated.** `hyprlock.conf` is patched in place.
`swaync/style.css` and `wlogout/style.css` get a delimited block appended; the
CSS cascade does the overriding because those rules come last. The block is
matched on its `/* marker:begin` prefix and stripped before being rewritten, so
repeated switches do not accumulate copies.

**oh-my-zsh will not take a path.** It appends `.zsh-theme` itself and looks for
`<name>.zsh-theme` in exactly three places: `$ZSH_CUSTOM`, `$ZSH_CUSTOM/themes`,
`$ZSH/themes`. So an absolute path is not "a path to a theme", it is a theme
*name*, and OMZ reports it as not found. The switcher symlinks
`~/.oh-my-zsh/custom/themes/theme-<name>.zsh-theme` at the generated file and
`.zshrc` sets `ZSH_THEME=theme-<name>`. The prefix is load-bearing: there is
already a `custom/themes/gruvbox.zsh-theme` belonging to OMZ, and the gruvbox
palette generates a file of the same name. `ZSH_CUSTOM` cannot be repurposed
either — `custom/plugins/` holds `zsh-autosuggestions` and
`zsh-syntax-highlighting`. `.zshrc` also checks the symlink is readable before
using it, so a missing link degrades to OMZ's gruvbox instead of printing a
"theme not found" error into every new shell.

**A generated zsh theme needs `$'\e[38;2;R;G;Bm'`, not a raw ESC byte.** Writing
the escape directly into the file produces `c_fg=<ESC>[38;2;205;214;244m`, which
zsh parses as an assignment followed by a nonsense command — one
`command not found: N` per colour channel, and an empty colour. And it cannot
be a `#rrggbb` string either: inside `%{%...%}` the markers make the contents
zero-width, so the hex digits are swallowed and the colour silently never
appears. `hex2ansi_zsh()` emits the `$'\e[...]'` text form for exactly this
reason.

**Backticks inside a heredoc are command substitution.** A generated comment
reading ``not `local` here`` ran `local` at generation time and injected the
result into the file. Worth grepping for before adding any generated text.

**Qt apps are listed, not killed.** Qt reads its palette once at startup, so a
restart is the only way to recolour a running Qt process — but killing Krita with
unsaved work is not the switcher's decision. It lists what is running; pass
`--restart-qt` when you have nothing open.

**The picker feeds rofi one line per theme with `printf`.** `"${lines[*]}"`
joins the array with spaces, so rofi gets a single row with all the themes glued
together and exactly one selectable entry appears. And the active-theme marker
has to be stripped explicitly before taking the first field:
`"${v#"${v%%[![:space:]]*}"}"` looks like an ltrim but only removes the
contiguous non-space run at the front, so `● gruvbox` keeps its marker and parses
out as the theme name `●`.

**Kitty needs a wrapper, and one socket per process.** `theme-switcher` recolours
open terminals with `kitty @ --to <addr> set-colors --configured --all`. Two things
are needed for that to work at all, and one of them is a trap:

1. kitty 0.49.2 will only listen on a socket from the `--listen-on` **command
   line** flag. `listen_on` is an accepted config key — it is not reported as
   unknown — but never opens a socket from a config file; verified against that
   build with an abstract socket, a `/tmp` path, and the prefixless form. So
   `~/.local/bin/kitty` adds the flag and execs `/usr/bin/kitty`.
2. **The socket name must include the PID.** A single fixed name is a trap: only
   the first kitty process binds it, and every subsequent launch fails with
   `Invalid listen_on=..., ignoring` plus an `Errors parsing configuration`
   dialog on every new terminal. Every launch here is a separate process. The
   name is abstract (`unix:@kitty-<user>-<pid>`), so there is no file on disk to
   pre-create or symlink, and because `exec` preserves the PID the name also
   identifies its owner. The switcher discovers every matching socket in
   `/proc/net/unix` and addresses each one, so all terminals recolour.

Windows that predate the wrapper have no discoverable socket; the switcher says
so instead of silently skipping them.

**`~/.local/bin` is already first on `PATH`**, set by `hl.env("PATH", ...)` in
`hyprland.lua`, so Super+Return and rofi both resolve the wrapper.

**Hyprland config is Lua, so there is no `source =`.** `hyprland.lua` `dofile`s a
generated table. `dofile()` is wrapped in `pcall` with the old gruvbox values as
a fallback, because a Hyprland config that will not load is much worse than
hardcoded greys.

**The reload is `config-only`.** A plain `hyprctl reload` also re-initialises the
monitors, which is the risky part — outputs are torn down and recreated, and a
failure there takes the display with it. A theme change only alters colours and
never touches the monitor block, so there is no reason to pay that risk.

**Waybar's signals are the opposite of what they look like.** This build defaults
to `SIGUSR1 = "toggle"` and `SIGUSR2 = "reload"` — confirmed in the binary
(`on-sigusr1` / `on-sigusr2` strings). Sending SIGUSR1 does not reload the bar,
it *hides* it, which presents as the theme switcher deleting the bar. Hence
SIGUSR2. `reload_style_on_change` in the waybar config is deliberately left at
the existing `false`.

**Hyprland's `rgba()` is unlike every other format here.** It takes hex channel
pairs with a hex alpha suffix and **no leading `#`**: `rgba(cba6f7ff)`. Both
`rgba(203,166,247ff)` (decimal) and `rgba(#cba6f7ff)` are rejected, and rejected
silently — Hyprland logs a config error and carries on with the option unset.
`render_hypr` validates the string against `^[0-9a-f]{8}$` before writing it.

**Waybar's workspace icons are real desktop icons now, not a glyph map.** It used
to resolve `{icon}` against the workspace *name* — `workspace-app-icons` renames
each workspace after the app on it — which needed a 62-entry `format-icons` map
saying which Nerd Font glyph and accent to draw. Anything not in that list fell
through to a bare diamond, so most apps looked broken. It now uses
`workspace-taskbar.enable` with `{windows}` in the format, so each window
contributes its own `.desktop` icon and there is no list to maintain. Empty
workspaces fall back to the old hollow diamond via `workspace-icons`. Both keys
are required; with only one, no icons appear at all.

The three roles that existed solely for those glyph colours (`icon_term`,
`icon_file`, `icon_edit`) are still in the palettes but nothing reads them. The
renderer and `waybar-icons.json` that consumed them have been removed; the old
config is recoverable from the comment block describing it.

**`settings.json` and `user.js` are patched, never rewritten.** Both belong to
the user. VS Code's `settings.json` is JSON *with comments*, so the managed keys
live between `// theme-switcher:vscode:begin/end` markers and only that block is
spliced — comments and unrelated settings survive, and re-running does not
duplicate the block. Firefox's `user.js` already held hand-set prefs (the 92% UI
scale, the Nerd Font families) that a full rewrite would have silently
destroyed, so the same marker approach is used there.

**Firefox needs both halves.** `ui.useCustomColors` has to be true or Firefox
ignores every custom colour in `userChrome.css`, so the pref is written
alongside the CSS rather than assumed. The profile is discovered from
`profiles.ini` by finding `Default=<path>` inside an `[Install...]` section —
not `Default=1`, which is the unrelated boolean in a `[ProfileN]` section — with
a fallback to whichever profile actually has a `prefs.js`.

**GTK3 rejects unknown CSS properties fatally.** `-gtk-icon-size` is a
GTK4/libadwaita property, and putting it in waybar's stylesheet does not warn,
it exits: `[error] style.css:292:18 '-gtk-icon-size' is not a valid property
name`, and the bar disappears. Size icons with `min-width`/`min-height`.

**Neovim has no greyscale scheme upstream**, so `monochrome` is generated as a
self-contained scheme in `nvim/colors/monochrome.lua`, including treesitter
groups. It is not derived from another scheme, which would leave that scheme's
hues showing through.

**Two cosmetic differences from the old hand-written files**, both with identical
rendering: `rgba()` in the generated waybar/rofi CSS uses commas rather than the
CSS Color 4 `rgba(r g b / a)` form (both parse; rofi was tested with both), and
kitty's `color8` moved out of the "Bright" section, where it was oddly filed, to
its conventional place beside `color0`..`color7`. The values are unchanged.

## gruvbox is byte-for-byte preserved

Every colour value in the pre-existing configs was transcribed into
`themes/gruvbox.json` and each renderer was checked against the originals. The
GTK palettes, Waybar palette, rofi palette, kitty palette, mako colours and
hyprlock literals are all value-identical to what was there before, and
`hyprlock.conf`, `rofi/config.rasi` and `mako/config` are untouched files apart
from the two normalisations above. Kitty's colour mapping is uniform across all
themes — `c0`/`c8` are two steps of the neutral ramp, `c1`..`c7` the seven hue
roles, `c9`..`c15` the same seven with the brightest text — and it reproduces the
existing kitty file exactly.

Qt is the one place with no "previous look" to preserve: `qt6ct` was not
installed, so the existing `qt6ct/qt6ct.conf` never took effect and its 21-slot
vector was not a working palette to copy. The 21 slots are derived from the theme
roles for all three themes, in the order qt6ct's own shipped schemes in
`/usr/share/qt{5,6}ct/colors/` use.

## Qt6

`qt6-base` was already installed as a dependency, but `qt6ct` and `kvantum` were
not, so the existing `QT_QPA_PLATFORMTHEME=qt6ct` and `QT_STYLE_OVERRIDE=kvantum`
were both no-ops. Installed: `qt6ct`, `qt5ct`, `kvantum`, `kvantum-qt5`.

Krita is Qt5 and whatsie is Qt6, so both configs are written. The compositor sets
`QT_QPA_PLATFORMTHEME=qt6ct`; Kvantum carries the widget chrome for both, and the
`qt5ct` config is there for Qt5 apps. To favour Qt5 instead, change that one env
line to `qt5ct`.

Kvantum themes installed under `~/.config/Kvantum/`:
`Gruvbox-Kvantum` (TheSerphh), `Catppuccin-Mocha-Mauve` (catppuccin), and
`KvDark` from the `kvantum` package for monochrome.

## GTK themes installed

`~/.themes/catppuccin-mocha-mauve-standard+default` (released archive from
catppuccin/gtk — the repo is source-only and needs Inkscape to build),
`adw-gtk3-dark` (from the `adw-gtk-theme` package, a GTK3 port of libadwaita that
is designed to be driven entirely by `colors.css`), plus your existing
`Gruvbox-Material-Hard`.

## Adding a new app

Add `render_<app>` to the script, call it from `main()`, and use `emit` to write
the file. `emit` is the only thing that should write config; it enforces an
absolute path and an octal mode, which is worth keeping — an unquoted two-word
label once shifted the arguments and wrote files into `$HOME` instead of the
config tree.