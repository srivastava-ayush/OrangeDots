return function(settings)
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

    hl.window_rule({
        name  = "pav-control",
        match = { class = "org.pulseaudio.pavucontrol" },
        float = true,
        center = true
    })

    hl.window_rule({
        name  = "kde-share",
        match = { class = "org.kde.kdeconnect.handler" },
        float = true,
        center = true
    })

    hl.window_rule({
        name  = "blueman",
        match = { class = "blueman-manager" },
        float = true,
        center = true
    })

    hl.window_rule({
        name  = "nmtui",
        match = { title = "nmtui" },
        float = true,
        center = true
    })

end
