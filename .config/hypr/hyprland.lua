------------------
---- MONITORS ----
------------------

hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local home = os.getenv("HOME") or "/home/water"
local terminal = "kitty"
local fileManager = "nemo"
local menu = "hyprlauncher"

-------------------
---- AUTOSTART ----
-------------------

-- at_startup holds a flock and only runs executable *.sh files in
-- ~/.local/bin/startup, so this one call cannot stack duplicates across reloads.
hl.on("hyprland.start", function()
	hl.exec_cmd(home .. "/.local/bin/at_startup")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Theme colours, generated into theme.lua by the theme switcher. Do not edit that file
-- by hand.
--
-- dofile() rather than an hl.* call because a Hyprland .conf has `source =` for pulling in
-- another config and this config is Lua, which has no equivalent. Hyprland embeds a full
-- Lua state, so plain dofile() works.
--
-- The pcall matters: dofile() raises if the file is missing, and a Hyprland config that
-- will not load is a far worse outcome than hardcoded greys. A missing or malformed
-- theme.lua degrades to the fallback below rather than leaving the session with no
-- compositor. `hyprctl reload` re-executes this file, so a theme change recolours the
-- borders live.
local theme = {
	name = "gruvbox",
	label = "Gruvbox Dark",
	active_border = "rgba(7c6f64ff)",
	inactive_border = "rgba(665c54ff)",
	shadow_color = "0xee1a1a1a",
}

do
	local loaded = { pcall(dofile, home .. "/.config/hypr/theme.lua") }
	if loaded[1] and type(loaded[2]) == "table" then
		theme = loaded[2]
	end
end

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 5,

		border_size = 1,

		-- Borders follow the theme, and are tuned to sit a couple of steps up
		-- the background ramp so the active window reads as a soft outline
		-- rather than a hard frame. On gruvbox that is #7c6f64 active and
		-- #665c54 inactive; the bar's islands are drawn from the same palette.
		col = {
			active_border = theme.active_border,
			inactive_border = theme.inactive_border,
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 0,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 0.95,
		inactive_opacity = 0.95,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = theme.shadow_color,
		},

		blur = {
			enabled = false,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.curve("quick", { type = "bezier", points = { { 0.2, 0 }, { 0.1, 1 } } })
hl.curve("snap", { type = "bezier", points = { { 0.3, 1 }, { 0.4, 1 } } })
hl.curve("bounce", { type = "bezier", points = { { 0.4, 1.2 }, { 0.6, 1 } } })

hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.52, 0.03 }, { 0.72, 0.08 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "bounce" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "bounce" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "bounce" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "bounce", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 0.25, bezier = "quick" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 0.2, bezier = "quick" })
hl.animation({ leaf = "fade", enabled = true, speed = 0.6, bezier = "quick" })

-- Layer-surface animations OFF. layersIn was style = "slide", so the bar visibly slid
-- down into place on every start. The only layer surfaces here are the bar, the nwg-dock
-- and its hotspot, and the wallpaper daemon; none of them should animate. If one ever
-- needs to, scope it with a `match:` rule rather than re-enabling the global leaf --
-- that is what drags the bar back in.
hl.animation({ leaf = "layers", enabled = false })
hl.animation({ leaf = "layersIn", enabled = false })
hl.animation({ leaf = "layersOut", enabled = false })
hl.animation({ leaf = "fadeLayersIn", enabled = false })
hl.animation({ leaf = "fadeLayersOut", enabled = false })
-- The original workspace slide. These animate the workspace-switcher overlay and the
-- background, not the bar (that is a layer surface, disabled above).
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "bounce", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 4, bezier = "bounce", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "quick", style = "slide" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 6, bezier = "quick" })

-- Special workspaces: nothing currently opens one (no togglespecialworkspace
-- bind), so these two are inert until something does.
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2.5, bezier = "bounce", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2.5, bezier = "quick", style = "slidevert" })

-- Workspaces are NOT persistent, on purpose.
--
-- Waybar's hyprland/workspaces module draws the workspaces Hyprland *reports*, and
-- Hyprland drops a workspace when you leave it unless a workspace_rule marks it
-- persistent. Without these the bar grows and shrinks with what is actually in use:
-- SUPER+5 creates workspace 5 and it appears, leaving it destroys it and the button
-- goes away. Pinning 1-10 instead just means a permanently full row of dead buttons.
--
-- The SUPER+1..0 binds below still work either way -- they create the workspace on
-- demand.
--
-- If you would rather have all ten always available, put this back:
--   for ws = 1, 10 do
--     hl.workspace_rule({ workspace = tostring(ws), persistent = true })
--   end
-- Ten separate rules rather than workspace = "1..10": Hyprland's own config language
-- expands that range, hl.workspace_rule does not.

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

----------------
----  MISC  ----
----------------

hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(

		-- The splash/error overlay is drawn with this font. Left empty it draws
		-- one solid rectangle per glyph instead of text, which makes a config
		-- error unreadable exactly when you need to read it. Any installed font
		-- with real coverage works; this one is already on the system.
		splash_font_family = "JetBrainsMono Nerd Font",
	},
})

---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
			scroll_factor = 1.0,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

hl.env("PATH", home .. "/.local/bin:" .. (os.getenv("PATH") or ""))
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QT_SCALE_FACTOR", "0.92")
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
hl.env("TERMINAL", "kitty")

------------------------
---- KEYBINDINGS --------
------------------------

local mainMod = "SUPER" -- the stock declaration lived in the block replaced above

local stepW = 136 -- 10% of this 1366x768 panel, rounded
local stepH = 76

-- --- launchers; the app launcher is Super+Space, as in niri ---
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nemo"))
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd("kitty --class yazi -e yazi"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("theme-switcher"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(home .. "/.local/bin/wallpaper-switcher"))

-- Super+N opens the animated-wallpaper picker: the video/gif files in
-- ~/Pictures/Wallpapers/Animated, played as a looping wallpaper by mpvpaper.
-- Separate from Super+W above because that one is the static-pictures picker and
-- works through awww, which cannot play video. Playback is always silent and the
-- first entry in the picker stops the video and restores the awww wallpaper, so
-- this one bind both sets and clears it.
--
-- Super+Shift+N is the same script with --toggle-sound: no picker, it flips the
-- wallpaper's sound and restarts mpvpaper so the change is audible at once. A
-- restart rather than a live mute because the silent launch passes no-audio=yes,
-- which means mpv never opened an audio output for one to control. The choice is
-- stored in ~/.local/state/animated-wallpaper/sound, so it survives restarts and
-- is remembered by later picks; the picker shows the current state on its
-- message line.
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(home .. "/.local/bin/animated-wallpaper"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(home .. "/.local/bin/animated-wallpaper --toggle-sound"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(home .. "/.local/bin/toggle-waybar"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("smile"))

-- Super+R shows/hides Planify's special workspace. The window is hidden, not
-- closed, so it keeps running and reappears instantly. This was Super+P until it
-- was moved here to free P up.
--
-- The argument is a POSITIONAL string, not a table: toggle_special("planify").
-- The table form { name = "planify" } is accepted silently and does nothing at
-- all, which is what made this look broken. Hyprland's own default config
-- (/usr/share/hypr/hyprland.lua) uses the positional form for the same reason.
hl.bind(mainMod .. " + R", hl.dsp.workspace.toggle_special("planify"))

-- Super+D shows/hides Dank Calendar's special workspace, the same way Super+R
-- does for Planify. Positional string argument, not a table -- see the note on
-- the Planify bind above.
hl.bind(mainMod .. " + D", hl.dsp.workspace.toggle_special("dank"))

-- Theme switcher: Super+T opens the picker. The bind only launches the script;
-- theme-switcher ends with `hyprctl reload` itself, which re-executes this file and picks
-- up the new border colours. The bind must NOT also reload, or the switcher races its
-- own reload and the borders come from the previous palette.

-- --- window management ---
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
-- --- focus: Left/Right walk columns, Up/Down walk windows inside one ---
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- --- move, as niri's Mod+Ctrl+Arrow ---
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "down" }))

-- --- resize, as niri's Mod+Shift+Arrow. Niri resizes by percentage;
-- hl.dsp.window.resize takes pixels in x/y instead. ---
--
-- relative = true is REQUIRED. Without it x/y are the ABSOLUTE target size and both
-- must be >= 1, so a delta like { x = -136, y = 0 } is rejected with "Invalid size".
-- Each of these four binds zeroes one axis, so all four trip that check.
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -stepW, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = stepW, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -stepH, relative = true }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = stepH, relative = true }))

-- --- workspaces 1-10, and move the focused window to one ---
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + c", hl.dsp.exec_cmd(home .. "/.local/bin/clipboard-history"))

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- --- drag and resize with the mouse ---
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local winRegion =
	[==[hyprctl -j activewindow | jq -r 'if .size then "\(.size[0])x\(.size[1])+\(.at[0])+\(.at[1])" else "" end']==]
hl.bind("ALT + Print", hl.dsp.exec_cmd('grim -g "$(echo ' .. winRegion .. ')" - | wl-copy'))

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightness-step up"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightness-step down"), { repeating = true })

-- power-mode sits on Super+Shift+P. It used to hold Super+P, back when that was
-- Planify's key; Planify has since moved to Super+R, so plain Super+P is free
-- again and this could go back to it if you prefer.
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(home .. "/.local/bin/power-mode"))

------------------------
---- AUTOSTART ---------
------------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("pkill -x dunst 2>/dev/null; true")
	hl.exec_cmd("systemctl --user restart xdg-desktop-portal.service")

	hl.exec_cmd("waybar -c " .. home .. "/.config/waybar/config-hypr.jsonc -s " .. home .. "/.config/waybar/style.css")

	hl.exec_cmd("awww-daemon")
	hl.exec_cmd(
		"sleep 1; awww restore || awww img -- " .. home .. "/Pictures/Wallpapers/a_river_running_through_a_small_town.jpg"
	)

	hl.exec_cmd(home .. "/.local/bin/clipboard-watcher")

	-- Session services.
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
	hl.exec_cmd("kitty")

	hl.exec_cmd("hypridle")
end)

---- WINDOWS AND WORKSPACES ----
--------------------------------

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-- Planify lives on its own special workspace, so it never occupies a numbered
-- workspace and is hidden rather than closed when toggled away. Hiding is what
-- makes the toggle feel instant: the window is still mapped, so showing it again
-- does not rebuild it.
--
-- This is a separate rule from planify-floating below rather than another `move`
-- in the same one, because a Lua table cannot hold two `move` keys -- the second
-- would silently replace the first. Rules apply in definition order, so the window
-- is put on special:planify first and given its geometry there afterwards.
hl.window_rule({
	name = "planify-special-workspace",
	match = { class = "^(io.github.alainm23.planify)$" },

	workspace = "special:planify",
})

-- Planify opens floating at a fixed size and position. All three matter, not just float:
-- Planify restores its own geometry from gsettings on launch, so without size/move it
-- comes back at whatever it last saved. float comes first because size and move are
-- applied in listed order and only stick once the window is already floating.
hl.window_rule({
	name = "planify-floating",
	match = { class = "^(io.github.alainm23.planify)$" },

	float = true,
	size = "812 568",
	move = "276 44",
})

-- Dank Calendar gets the same treatment as Planify: its own special workspace,
-- opened and hidden with Super+D, and the geometry it had on workspace 3
-- (1143x567 at 97,38) so it looks the same wherever it appears.
--
-- Split into two rules for the same reason as Planify above: one Lua table
-- cannot hold two `move` keys. Order is definition order -- onto the special
-- workspace first, geometry second.
hl.window_rule({
	name = "dankcalendar-special-workspace",
	match = { class = "^com[.]danklinux[.]dankcalendar$" },

	workspace = "special:dank",
})

hl.window_rule({
	name = "dankcalendar-floating",
	match = { class = "^com[.]danklinux[.]dankcalendar$" },

	float = true,
	size = "1143 567",
	move = "97 38",
})

hl.window_rule({
	name = "kitty-no-blur",
	match = { class = "^(kitty|kitty-wayland)$" },
	no_blur = true,
	no_shadow = true,
})
-- No `hl.config({ plugin = ... })` block: there is no overview plugin installed, and a
-- config block for an absent plugin is a config error.
