return function(settings)
    ---- MONITORS ----
    ------------------

    -- Hyprland can reapply fallback monitor rules even on config-only reloads.
    -- Snapshot live OpenDisplay settings before that happens; names are queried
    -- afresh, never stored in the config. New outputs are configured by OpenDisplay.
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name:match("^OpenDisplay%-") then
            hl.monitor({
                output = monitor.name,
                mode = string.format("%dx%d@%.5f", monitor.width, monitor.height, monitor.refresh_rate),
                position = string.format("%dx%d", monitor.x, monitor.y),
                scale = monitor.scale,
                transform = monitor.transform,
            })
        end
    end

    -- Only the laptop gets this hardware-specific mode. OpenDisplay owns its
    -- virtual output's mode, position and scale (including across reloads).
    hl.monitor({
        output   = "eDP-1",
        mode     = "1920x1080@144",
        position = "auto",
        scale    = "1",
    })

    for _, ws in ipairs({ 1, 2, 3, 4, 10 }) do
        hl.workspace_rule({ workspace = tostring(ws), monitor = "eDP-1", persistent = true })
    end
end
