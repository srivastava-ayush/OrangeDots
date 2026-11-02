return function(settings)
    -- Previous preset retained for easy rollback. Only the preset below is active.
    --[[
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
    ]]

    -- macOS-inspired: subtle scale, soft deceleration, and no spring overshoot.
    -- This approximates the feel; Hyprland does not implement macOS's Genie effect.
    -- Hyprland speed values are durations in 100ms units: larger means slower.
    hl.curve("MacOpen", {
        type = "bezier",
        points = { { 0.22, 1.00 }, { 0.36, 1.00 } },
    })

    hl.curve("MacClose", {
        type = "bezier",
        points = { { 0.40, 0.00 }, { 1.00, 1.00 } },
    })

    hl.curve("MacMove", {
        type = "bezier",
        points = { { 0.25, 0.10 }, { 0.25, 1.00 } },
    })

    hl.curve("MacWorkspace", {
        type = "bezier",
        points = { { 0.32, 0.00 }, { 0.15, 1.00 } },
    })

    hl.curve("MacLinear", {
        type = "bezier",
        points = { { 0.00, 0.00 }, { 1.00, 1.00 } },
    })

    -- Small scale change avoids a dramatic zoom; movement settles without wobble.
    hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3.2, bezier = "MacOpen",  style = "popin 96%" })
    hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.0, bezier = "MacClose", style = "popin 96%" })
    hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.2, bezier = "MacMove" })

    -- Opacity follows the scale transition instead of snapping on/off.
    hl.animation({ leaf = "fadeIn",  enabled = true, speed = 2.4, bezier = "MacOpen" })
    hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.0, bezier = "MacClose" })

    -- Shell surfaces retain their own QML animations; keep compositor motion light.
    hl.animation({ leaf = "layersIn",  enabled = true, speed = 2.6, bezier = "MacOpen",  style = "slidefade" })
    hl.animation({ leaf = "layersOut", enabled = true, speed = 1.8, bezier = "MacClose", style = "slidefade" })
    hl.animation({ leaf = "border", enabled = true, speed = 3.2, bezier = "MacLinear" })

    -- A longer, continuous slide evokes Spaces while matching vertical gestures.
    hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 4.0, bezier = "MacWorkspace", style = "slidefadevert" })
    hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4.0, bezier = "MacWorkspace", style = "slidefadevert" })
    hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.6, bezier = "MacOpen", style = "slidefadevert" })
end
