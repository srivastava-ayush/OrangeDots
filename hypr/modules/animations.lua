
return function(settings)

    -----------------------------------------------------------------------
    -- BEZIER CURVES
    -----------------------------------------------------------------------

    hl.curve("ayuOpen", {
        type = "bezier",
        points = { { 0.22, 1.00 }, { 0.36, 1.00 } },
    })

    hl.curve("ayuClose", {
        type = "bezier",
        points = { { 0.25, 0.00 }, { 0.35, 1.00 } },
    })

    hl.curve("ayuMove", {
        type = "bezier",
        points = { { 0.25, 0.10 }, { 0.25, 1.00 } },
    })

    hl.curve("ayuLinear", {
        type = "bezier",
        points = { { 0.00, 0.00 }, { 1.00, 1.00 } },
    })

    -----------------------------------------------------------------------
    -- ANIMATIONS
    -----------------------------------------------------------------------

    -- Workspaces
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3.5, bezier = "ayuOpen", style = "slidefadevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.5, bezier = "ayuOpen", style = "slidefadevert" })

    -- Windows
    hl.animation({
        leaf = "windowsIn",
        enabled = true,
        speed = 3.2,
        bezier = "ayuOpen",
        style = "popin 10%"
    })

    hl.animation({
        leaf = "windowsOut",
        enabled = true,
        speed = 2.0,
        bezier = "ayuClose",
        style = "popin 60%"
    })

    hl.animation({
        leaf = "windowsMove",
        enabled = true,
        speed = 3.2,
        bezier = "ayuMove"
    })

    -- Window fading
    hl.animation({
        leaf = "fadeIn",
        enabled = true,
        speed = 2.4,
        bezier = "ayuOpen"
    })

    hl.animation({
        leaf = "fadeOut",
        enabled = true,
        speed = 2.0,
        bezier = "ayuClose"
    })

    -- Layer surfaces (Quickshell, Waybar, etc.)
    hl.animation({
        leaf = "layersIn",
        enabled = true,
        speed = 2.6,
        bezier = "ayuOpen",
        style = "slidefade"
    })

    hl.animation({
        leaf = "layersOut",
        enabled = true,
        speed = 1.8,
        bezier = "ayuClose",
        style = "slidefade"
    })

    -- Border
    hl.animation({
        leaf = "border",
        enabled = true,
        speed = 3.2,
        bezier = "ayuLinear"
    })

    -- Special workspace / scratchpad
    hl.animation({
        leaf = "specialWorkspace",
        enabled = true,
        speed = 3.6,
        bezier = "ayuOpen",
        style = "slidefadevert"
    })

    -----------------------------------------------------------------------

end
