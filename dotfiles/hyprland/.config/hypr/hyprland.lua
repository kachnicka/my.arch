-- Hyprland Lua config (converted from hyprland.conf)
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/
--
-- You can (and should!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal = "ghostty"
local fileManager = "dolphin"
local menu = "tofi-drun | xargs -I{} hyprctl dispatch \"hl.dsp.exec_cmd('{}')\""

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Each entry: { proc = "pgrep -x name", cmd = "launch command",
--   wayland_bound = true|false (default false) }
-- `proc` is the basename pgrep matches; `cmd` is what we exec when absent.
-- wayland_bound marks daemons tied to the LIVE Hyprland compositor
-- (idle/paper/bar/clipboard/ctemp). A survivor from a PREVIOUS Hyprland
-- instance still holds fds to the dead compositor and silently never fires
-- again -- a stale hypridle is exactly how idle actions stop triggering while
-- `pgrep` happily reports "already running". For those we must kill pids whose
-- HYPRLAND_INSTANCE_SIGNATURE differs from the current one and relaunch,
-- instead of trusting a bare `pgrep`.
local autostart = {
	{ proc = "hyprpaper",       cmd = "hyprpaper",                                  wayland_bound = true },
	{ proc = "hypridle",        cmd = "hypridle",                                   wayland_bound = true },
	{ proc = "waybar",          cmd = "waybar",                                     wayland_bound = true },
	{ proc = "dunst",           cmd = "dunst",                                      wayland_bound = true },
	{ proc = "udiskie",         cmd = "udiskie --no-menu-update-workaround" },
	{ proc = "wl-clip-persist", cmd = "wl-clip-persist --clipboard regular",        wayland_bound = true },
	{ proc = "gammastep",       cmd = "gammastep -l 49.195:16.608 -t6500:4500 -m wayland", wayland_bound = true }, -- HACK: hardcoded to Brno -- edit for your location
}

-- For a wayland_bound daemon: kill any pid bound to a DIFFERENT Hyprland
-- instance (orphan from a dead session), then launch only if no pid bound to
-- THIS session remains. Without this, a stale daemon survives a compositor
-- restart and `pgrep` treats it as "already running" forever.
local function launch_bound(entry)
	local sh = "sig=$HYPRLAND_INSTANCE_SIGNATURE\n"
		.. "found=0\n"
		.. "for p in $(pgrep -x " .. entry.proc .. "); do\n"
		.. "  psig=$(tr '\\0' '\\n' < /proc/$p/environ 2>/dev/null | sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p')\n"
		.. "  if [ \"$psig\" != \"$sig\" ]; then\n"
		.. "    kill \"$p\" 2>/dev/null\n"
		.. "  else\n"
		.. "    found=1\n"
		.. "  fi\n"
		.. "done\n"
		.. "[ \"$found\" = 1 ] || " .. entry.cmd
	hl.exec_cmd(sh)
end

-- Launch logic, used at session start and after a config reload (recovery from
-- a GPU hang / Hyprland crash that restarted the compositor).
-- * Plain entries: start only if no pid matches `proc` (dedup).
-- * wayland_bound entries: kill stale, then start if none bound to this session.
local function launch_autostart()
	for _, entry in ipairs(autostart) do
		if entry.wayland_bound then
			launch_bound(entry)
		else
			hl.exec_cmd(("pgrep -x %s >/dev/null 2>&1 || %s"):format(entry.proc, entry.cmd))
		end
	end
end

hl.on("hyprland.start", launch_autostart)

-- Recovery path: after a GPU hang -> Hyprland crash -> config reload, some
-- daemons may have died. Re-run the same guarded launches so anything missing
-- comes back, without duplicating what survived.
hl.on("config.reloaded", launch_autostart)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Env vars: see uwsm env.d drop-ins (hl.env only reaches direct children).

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not
-- applied on-the-fly for security reasons

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

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 2,

		border_size = 2,

		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(ff8c00ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 6,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a,
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

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

hl.config({
	binds = {
		workspace_back_and_forth = true,
	},
})

----------------
----  MISC  ----
----------------

-- https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	misc = {
		-- force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
	},
})

-- dark mode (run once at session start; gsettings is idempotent so reloads are harmless,
-- but grouping under hyprland.start avoids re-spawning on every config reload)
hl.on("hyprland.start", function()
	hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"')
	hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')
end)

---------------
---- INPUT ----
---------------

-- https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	input = {
		kb_layout = "us,sk",
		kb_variant = ",qwerty",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = false,
		},
	},
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
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

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd('loginctl terminate-user ""'))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
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
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Keyboard layout switch
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

-- Screenshot
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'))

-- Close keymapp/pavucontrol via Escape (non-consuming bind, formerly `bindn`).
-- Native Lua implementation replaces the old ~/.config/hypr/script/close.sh
-- (which shelled out to `hyprctl -j activewindow | jq`); no subprocess needed.
hl.bind("Escape", function()
	local win = hl.get_active_window()
	if win and (win.class == "keymapp" or win.class == "org.pulseaudio.pavucontrol") then
		hl.dispatch(hl.dsp.window.close())
	end
end, { non_consuming = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

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

hl.window_rule({
	name = "keymapp-overlay",
	match = { class = "keymapp" },

	float = true,
	pin = true,
	size = { 730, 380 },
	-- center horizontally on any monitor; bottom-anchored (resolution-independent)
	move = { "monitor_w/2-window_w/2", "monitor_h-window_h-1" },
	no_blur = true,
	no_initial_focus = true,
	opacity = "0.8 override 0.25 override",
})

hl.window_rule({
	name = "pavucontrol",
	match = { class = "org.pulseaudio.pavucontrol" },

	float = true,
	size = { 1280, 720 },
})

hl.window_rule({
	name = "satty",
	match = { class = "com.gabm.satty", title = "satty" },

	float = true,
	pin = true,
	move = { "cursor_x", "cursor_y" },
	no_anim = true,
	no_blur = true,
	fullscreen_state = "0 0",
	content = "photo",
})

hl.window_rule({
	name = "terminal-opacity-ghostty",
	match = { class = "com.mitchellh.ghostty" },

	opacity = "0.95 override 0.85 override",
})

hl.window_rule({
	name = "orchard",
	match = { title = "Orchard" },

	float = true,
	rounding = 0,
})

hl.window_rule({
	name = "my.settlers",
	match = { title = "my.settlers" },

	float = true,
	rounding = 0,
})
