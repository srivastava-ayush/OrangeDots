------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1.2",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "thunar"
local ide = "code"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("caelestia shell -d")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
    hl.exec_cmd("kdeconnectd")
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
-- Note: permission changes here require a Hyprland restart; they are not
-- applied on-the-fly for security reasons.

-- hl.config({
--     ecosystem = {
--         enforce_permissions = true,
--     },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- See https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 1,

        -- col = {
        --     active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
        --     inactive_border = "rgba(595959aa)",
        -- },

        -- Resize windows by clicking and dragging on borders/gaps
        resize_on_border = false,

        -- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before enabling
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 20,
        rounding_power = 2,

        active_opacity   = 0.9,
        inactive_opacity = 0.9,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 4,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("Out", {
    type = "bezier",
    points = {
        { 0.16, 1.00 },
        { 0.30, 1.00 },
    },
})

hl.curve("Snap", {
    type = "bezier",
    points = {
        { 0.25, 0.90 },
        { 0.35, 1.00 },
    },
})

hl.curve("Spring", {
    type = "bezier",
    points = {
        { 0.25, 1.30 },
        { 0.35, 1.00 },
    },
})

hl.curve("Linear", {
    type = "bezier",
    points = {
        { 0.00, 0.00 },
        { 1.00, 1.00 },
    },
})

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4,   bezier = "Spring", style = "popin 85%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2,   bezier = "Out",    style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,   bezier = "Spring" })

hl.animation({ leaf = "layersIn",  enabled = true, speed = 3, bezier = "Spring", style = "slidefade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "Out",    style = "slidefade" })

hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "Linear" })

hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5, bezier = "Spring", style = "slidefadevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "Out",    style = "slidefadevert" })

hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.5, bezier = "Spring", style = "slidefadevert" })

-- "Smart gaps" / "no gaps when only" — see
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Uncomment all of the following if you want that behavior.
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

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split = true, -- you probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
    },
})

-- Use the scrolling layout on workspaces 1 and 2, dwindle everywhere else
for _, ws in ipairs({ "1", "2" }) do
    hl.workspace_rule({ workspace = ws, layout = "scrolling" })
end


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,    -- 0 or 1; disables the anime mascot wallpapers
        disable_hyprland_logo   = true, -- disables the random Hyprland logo / anime girl background
    },
})


---------------
---- INPUT ----- "Windows" key as the main modifier
--------------->

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 to 1.0, 0 means no modification

        touchpad = {
            natural_scroll = true,
            scroll_factor  = .5, -- lower = smaller scroll distance per swipe (default 1.0)
        },
    },
})

-- niri-style 3-finger swipe up/down to switch workspaces.
-- Follows your finger 1:1 and settles smoothly instead of jumping.
hl.gesture({
    fingers   = 3,
    direction = "vertical",
    action    = "workspace",
    scale     = 1.5, -- >1 = shorter swipe distance needed to trigger the switch
})
-- niri-style 3-finger swipe left/right to move focus between windows/columns.
-- Works great with the scrolling layout on workspace 1 (moves focus a column
-- at a time), and falls back to normal directional focus on other layouts.
hl.gesture({
    fingers   = 3,
    direction = "left",
    action    = function() hl.dispatch(hl.dsp.focus({ direction = "right" })) end,
})
hl.gesture({
    fingers   = 3,
    direction = "right",
    action    = function() hl.dispatch(hl.dsp.focus({ direction = "left" })) end,
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" 

-- Overview / shell toggles
hl.bind(mainMod .. " + Escape", hl.plugin.scrolloverview.overview("toggle all"))
hl.bind(
    mainMod .. " + Delete",
    hl.dsp.exec_cmd([[sh -c 'if pgrep -x qs >/dev/null; then pkill -x qs; else caelestia shell -d; fi']])
)

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("caelestia shell lock lock"))
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"), { release = true })
hl.bind(mainMod .. " + D",       hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"), { release = true })

-- Dashboard: tap SUPER+ALT to toggle it (either Alt key; release-triggered,
-- same trick as the SUPER+SUPER_L launcher bind so it won't fire after a
-- chord like SUPER+ALT+2). Held down, ALT acts as a chord mod, so
-- SUPER+ALT+[1-4] jumps straight to a tab (opens the dashboard if closed).
-- Tab order follows modules/dashboard/Content.qml, skipping disabled tabs:
-- 1=Dashboard 2=Media 3=Performance 4=Notifications
local dashToggle = hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard")
hl.bind(mainMod .. " + ALT_L", dashToggle, { release = true })
hl.bind(mainMod .. " + ALT_R", dashToggle, { release = true })

local dashTabs = { "dashboard", "media", "performance", "notifications" }
for i, tab in ipairs(dashTabs) do
    hl.bind(mainMod .. " + ALT + " .. i, hl.dsp.exec_cmd("caelestia shell drawers setTab " .. tab))
end

-- Apps / window management
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(ide))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + R", hl.dsp.layout("expel"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("brave"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Resize windows with mainMod + SHIFT + ALT + arrow keys (hold to resize)
hl.bind(mainMod .. " + SHIFT + ALT + left",  hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + ALT + right", hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + ALT + up",    hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + ALT + down",  hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { repeating = true })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Spotify scratchpad (special workspace)
hl.window_rule({
    name  = "spotify-special",
    match = { class = "^(Spotify|spotify)$" },

    workspace = "special:magic",
})

-- SUPER + S toggles the Spotify scratchpad (launches Spotify if not running).
-- SUPER + SHIFT + <key> tosses the focused window into that scratchpad
-- without following it (follow = false).
hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd("~/.config/hypr/spotify-toggle.sh"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

-- Miscellaneous scratchpad
hl.bind(mainMod .. " + Z",         hl.dsp.workspace.toggle_special("misc"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "special:misc", follow = false }))

-- Alternative: 3-finger swipe up/down to toggle the Spotify scratchpad
-- (launches it if not running / closes it if open). Disabled by default
-- in favor of the SUPER + S / Z binds above.
-- hl.gesture({
--     fingers   = 3,
--     direction = "up",
--     action    = function() hl.exec_cmd("~/.config/hypr/spotify-toggle.sh") end,
-- })
-- hl.gesture({
--     fingers   = 3,
--     direction = "down",
--     action    = function()
--         local ws = hl.get_active_special_workspace()
--         if ws ~= nil and ws.name == "special:magic" then
--             hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
--         end
--     end,
-- })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",          hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",       hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Volume/brightness via mainMod + PageUp/PageDown
hl.bind(mainMod .. " + page_up",         hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind(mainMod .. " + page_down",       hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind(mainMod .. " + ALT + page_up",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                 { locked = true, repeating = true })
hl.bind(mainMod .. " + ALT + page_down", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                 { locked = true, repeating = true })

-- Screenshot / screen recording
hl.bind(mainMod .. " + caps_lock",       hl.dsp.exec_cmd("caelestia screenshot -r"))
hl.bind(mainMod .. " + ALT + caps_lock", hl.dsp.exec_cmd("caelestia record -r -s"))

-- Bluetooth / network / settings
hl.bind(mainMod .. " + B",   hl.dsp.exec_cmd("blueman-manager"))
hl.bind(mainMod .. " + M",   hl.dsp.exec_cmd("pavucontrol"))
hl.bind(mainMod .. " + N",   hl.dsp.exec_cmd(terminal .. " --title nmtui -e nmtui"))
hl.bind(mainMod .. " + X",   hl.dsp.exec_cmd("caelestia shell nexus open"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("caelestia shell wallpapers pick"))

-- Clipboard / emoji
hl.bind("CTRL + ALT + V",         hl.dsp.exec_cmd("caelestia clipboard"))
hl.bind("CTRL + ALT + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"))
hl.bind(mainMod .. " + period",   hl.dsp.exec_cmd("caelestia emoji -p"))

-- Media keys (requires playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.gesture({
    fingers   = 4,
    direction = "vertical",
    action    = function() hl.dispatch(hl.plugin.scrolloverview.overview("toggle all")) end,
})
--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from all apps. You'll probably like this.
-- (rule is active; call suppressMaximizeRule:set_enabled(false) to disable it)
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    -- suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run window
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})


-------------------
---- PLUGINS ------
-------------------

plugin = {
    scrolloverview = {
        gesture_distance = 300,
        scale            = 0.5,
        workspace_gap    = 100,
        layout           = "vertical",
        wallpaper        = 0,
        blur             = false,
    },
}

-- Tide Island shortcuts: begin (managed by Tide Island Config App).
-- Empty shortcuts are disabled and intentionally omitted.
hl.bind("SUPER + ALT + TAB", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call overview toggle"))
hl.bind("SUPER + ALT + right", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide swipeRight"))
hl.bind("SUPER + ALT + left", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide swipeLeft"))
hl.bind("SUPER + ALT + down", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide showClock"))
hl.bind("SUPER + ALT + S", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide togglePlayer"))
hl.bind("SUPER + ALT + space", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide toggleControlCenter"))
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide toggleNotificationCenter"))
hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide toggleWallpaperPicker"))
hl.bind("SUPER + slash", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call tide toggleApplicationLauncher"))
-- hl.bind("SUPER + F", hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /usr/share/tide-island call island toggle"))
-- Tide Island shortcuts: end.
