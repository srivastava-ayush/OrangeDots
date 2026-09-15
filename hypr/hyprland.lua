
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "1920x1080@144",
    position = "auto",
    scale    = "1",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "thunar"
local ide         = "code"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("caelestia shell -d")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
    hl.exec_cmd("kdeconnectd")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 1,

        resize_on_border = false,
        allow_tearing    = false,

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
            vibrancy = 0.15,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("Out", {
    type = "bezier",
    points = { { 0.16, 1.00 }, { 0.30, 1.00 } },
})

hl.curve("Snap", {
    type = "bezier",
    points = { { 0.20, 0.95 }, { 0.10, 1.00 } },
})

hl.curve("Spring", {
    type = "bezier",
    points = { { 0.15, 1.10 }, { 0.30, 1.00 } }, -- overshoot toned down from 1.30 -> 1.10
})

hl.curve("Overshot", {
    type = "bezier",
    points = { { 0.05, 0.90 }, { 0.10, 1.05 } }, -- gentle premium "settle" curve, great for windowsIn
})

hl.curve("Linear", {
    type = "bezier",
    points = { { 0.00, 0.00 }, { 1.00, 1.00 } },
})

-- Windows: faster in/out reads as more "responsive", move stays smooth
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3,   bezier = "Overshot", style = "popin 90%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.2, bezier = "Out",      style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "Spring" })

-- Layers (rofi/wlogout/notifications) — quick in, slightly quicker out
hl.animation({ leaf = "layersIn",  enabled = true, speed = 2.8, bezier = "Overshot", style = "slidefade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.8, bezier = "Out",      style = "slidefade" })

-- Border: keep linear for hue/color interpolation, it avoids weird color "pulsing"
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "Linear" })

-- Workspaces: this is where "premium" is most felt — keep it fast and directional
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3.5, bezier = "Overshot", style = "slidefadevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.2, bezier = "Out",      style = "slidefadevert" })

hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "Overshot", style = "slidefadevert" })
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-opayout/
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        explicit_column_widths   = "0.333, 0.5, 0.667, 1.0",
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
        force_default_wallpaper = 0,    -- disables the anime mascot wallpapers
        disable_hyprland_logo   = true, -- disables the random Hyprland logo / anime girl background
    },
})


--------------------
---- INPUT ----------- "Windows" key as the main modifier
--------------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0, -- -1.0 to 1.0, 0 means no modification

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

hl.gesture({
    fingers   = 4,
    direction = "vertical",
    action    = function() hl.dispatch(hl.plugin.scrolloverview.overview("toggle all")) end,
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
-- hl.bind(
--     mainMod .. " + Delete",
--     hl.dsp.exec_cmd([[sh -c 'if pgrep -x qs >/dev/null; then pkill -x qs; else caelestia shell -d; fi']])
-- )
hl.bind(
    mainMod .. " + Delete",
    hl.dsp.exec_cmd([[sh -c '/home/ayush/OrangeDots/toggle-shells.sh']])
)
hl.bind(mainMod .. " + L",       hl.dsp.exec_cmd("caelestia shell lock lock"))
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"), { release = true })
hl.bind(mainMod .. " + D",       hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"), { release = true })
hl.bind(mainMod .. " + P",       hl.dsp.exec_cmd("caelestia shell drawers setTab performance"), { release = false })
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
    hl.bind(mainMod .. " + ALT + " .. i, hl.dsp.exec_cmd("caelestia shell drawers setTab" .. tab),{ release = true})
end

-- Apps / window management
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(ide))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
local swapDirection = "right"

hl.bind(
    mainMod .. " + J",
    function()
        hl.dispatch(hl.dsp.window.swap({ direction = swapDirection }))

        if swapDirection == "right" then
            swapDirection = "left"
        else
            swapDirection = "right"
        end
    end
)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("/home/ayush/OrangeDots/refresh-rate-toggle.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("brave"))

-- Move focus with mainMod + arrow keys (hold to repeat)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }),  { repeating = true })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { repeating = true })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }),    { repeating = true })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }),  { repeating = true })

-- Move windows with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }),{ repeating = true})
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }),{ repeating = true})
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }),{ repeating = true})
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }),{ repeating = true})

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

    opacity   = .765,
    workspace = "special:magic",
})

-- SUPER + S toggles the Spotify scratchpad (launches Spotify if not running).
-- SUPER + SHIFT + S tosses the focused window into that scratchpad
-- without following it (follow = false).
hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd("~/.config/hypr/spotify-toggle.sh"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

-- Miscellaneous scratchpad
hl.bind(mainMod .. " + Z",         hl.dsp.workspace.toggle_special("misc"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "special:misc", follow = false }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

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


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Ignore maximize requests from all apps.
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
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


if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        enabled = false,
        default_theme = "dark",
        default_preset = "glass",
        layers = { enabled = true },
    })

    hg.preset("apple", {
        blur_strength        = 2.2,
        blur_iterations      = 3,
        refraction_strength  = 0.55,
        chromatic_aberration = 0.3,
        fresnel_strength     = 0.5,
        specular_strength    = 0.75,
        edge_thickness       = 0.05,
        lens_distortion      = 0.3,

        dark = {
            brightness   = 0.82,
            contrast     = 0.90,
            saturation   = 0.80,
            vibrancy     = 0.15,
            adaptive_dim = 0.4
        },

        light = {
            brightness     = 1.12,
            contrast       = 0.92,
            saturation     = 0.85,
            vibrancy      = 0.12,
            adaptive_boost = 0.4
        }
    })
    hg.layer("caelestia-background", { exclude = true })
    hg.layer("caelestia-border-exclusion", { exclude = true })
    hg.layer("quickshell", { exclude = true })
    hg.layer("caelestia-drawers", { exclude = true })

        -- Toggle HyprGlass
    local glass_enabled = false

    hl.bind("SUPER + G", function()
        glass_enabled = not glass_enabled
        hg.config({
            enabled = glass_enabled,
        })
    end)
end
