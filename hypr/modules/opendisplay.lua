return function(settings)
    -- OpenDisplay generates a new suffix on each run; never persist its name.
    -- Native Lua hooks replace a separate socket watcher. See
    -- https://wiki.hypr.land/Configuring/Using-Lua/
    local function findDisplay()
        local names = {}
        for _, monitor in ipairs(hl.get_monitors()) do
            if monitor.name:match("^OpenDisplay%-") then
                names[#names + 1] = monitor.name
            end
        end
        table.sort(names) -- Deterministic if more than one receiver is running.
        return names[1]
    end

    -- Keybinds query live outputs rather than a cached connection flag.
    settings.openDisplayConnected = function()
        return findDisplay() ~= nil
    end

    local currentOutput
    local rules = {}
    local function reconcile()
        local output = findDisplay()
        if output ~= currentOutput then
            for _, rule in ipairs(rules) do
                rule:set_enabled(false)
            end
            rules = {}
            currentOutput = output
            if output then
                for ws = 5, 9 do
                    rules[#rules + 1] = hl.workspace_rule({
                        workspace = tostring(ws), monitor = output, persistent = true,
                    })
                end
            end
        end

        -- Rules place future workspaces; explicitly recover existing ones too.
        -- On disconnect leave occupied workspaces/windows to Hyprland's safe
        -- fallback. They are restored to the iPad when its output returns.
        local laptop = hl.get_monitor("eDP-1")
        for _, workspace in ipairs(hl.get_workspaces()) do
            local id = workspace.id
            local target
            if id and ((id >= 1 and id <= 4) or id == 10) and laptop then
                target = "eDP-1"
            elseif id and id >= 5 and id <= 9 then
                target = output
            end
            if target and workspace.monitor and workspace.monitor.name ~= target then
                hl.dispatch(hl.dsp.workspace.move({ workspace = id, monitor = target }))
            end
        end
    end

    -- Defer until monitor setup/removal and config registration have finished.
    -- Keep the timer alive and coalesce bursts without continuously polling.
    local pending
    local function schedule()
        if pending then return end
        pending = hl.timer(function()
            pending = nil
            reconcile()
        end, { timeout = 150, type = "oneshot" })
    end
    for _, event in ipairs({ "hyprland.start", "config.reloaded", "monitor.added", "monitor.removed" }) do
        hl.on(event, schedule)
    end
end
