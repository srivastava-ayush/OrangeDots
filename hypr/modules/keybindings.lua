return function(settings)
    local terminal = settings.terminal
    local fileManager = settings.fileManager
    local ide = settings.ide
    local browser = settings.browser
    local configHome = settings.configHome
    local hyprScript = settings.hyprScript

    ---------------------
    ---- KEYBINDINGS ----
    ---------------------

    local mainMod = "SUPER"

    -- Overview / shell toggles
    --hl.bind(mainMod .. " + Escape", hl.plugin.scrolloverview.overview("toggle all"))
    hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd(hyprScript("toggle-shell.sh")))
    hl.bind(mainMod .. " + L",       hl.dsp.exec_cmd("caelestia shell lock lock"))
    hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"), { release = true })
    hl.bind(mainMod .. " + D",       hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"), { release = true })
    hl.bind(mainMod .. " + P",       hl.dsp.exec_cmd("caelestia shell drawers setTab performance"), { release = false })
    hl.bind(mainMod .. " + I",       hl.dsp.exec_cmd("caelestia shell drawers toggle rightSidebar"))
    hl.bind(mainMod .. " + U",       hl.dsp.exec_cmd("caelestia shell drawers toggle leftSidebar"))
    hl.bind(mainMod .. " + space",   hl.dsp.exec_cmd("caelestia shell drawers toggle session"))
    -- Dashboard: tap SUPER+ALT to toggle it (either Alt key; release-triggered,
    -- same trick as the SUPER+SUPER_L launcher bind so it won't fire after a
    -- chord like SUPER+ALT+2). Held down, ALT acts as a chord mod, so
    -- SUPER+ALT+[1-4] jumps straight to a tab (opens the dashboard if closed).
    -- Tab order follows modules/dashboard/DashboardContent.qml, skipping disabled tabs:
    -- 1=Media 2=Dashboard 3=Performance 4=Phone
    local dashToggle = hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard")
    hl.bind(mainMod .. " + ALT_L", dashToggle, { release = true })
    hl.bind(mainMod .. " + ALT_R", dashToggle, { release = true })

    -- Tap SUPER+SHIFT to toggle the left-side taskbar's Always visible setting.
    local barToggle = hl.dsp.exec_cmd("caelestia shell drawers toggleBarPersistent")
    -- Cycle taskbar styles: Unified -> Three notches -> Center notch (saved by the shell).
    hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("caelestia shell drawers cycleBarStyle"), { release = true })
    -- Hold SUPER+SHIFT+T, then press O to switch Left <-> Top without cycling style.
    hl.bind(mainMod .. " + SHIFT + T + O", hl.dsp.exec_cmd("caelestia shell drawers toggleBarOrientation"))
    hl.bind(mainMod .. " + SHIFT_L", barToggle, { release = true })
    hl.bind(mainMod .. " + SHIFT_R", barToggle, { release = true })

    local dashTabs = { "media", "dashboard", "performance", "phone" }
    for i, tab in ipairs(dashTabs) do
        hl.bind(mainMod .. " + TAB + " .. i, hl.dsp.exec_cmd("caelestia shell drawers setTab " .. tab), { release = true })
    end

    -- Apps / window management
    --hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
    hl.bind(
        mainMod .. " + Q",
        hl.dsp.exec_cmd(
            terminal .. " " .. string.format("%q", configHome .. "/quickshell/caelestia/assets/wrap_term_launch.sh") .. " " .. os.getenv("SHELL")
        )
    )
    hl.bind(
        mainMod .. " + A",
        hl.dsp.exec_cmd(
            terminal .. " " .. string.format("%q", configHome .. "/quickshell/caelestia/assets/wrap_term_launch.sh") .. " yazi"
        )
    )
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(ide))
    hl.bind(mainMod .. " + C", hl.dsp.window.close())
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
    hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(hyprScript("toggle-refresh-rate.sh")))
    hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))

    -- OrangeShell's MRU window switcher. Compositor shortcuts keep working
    -- while the overlay owns keyboard focus; Alt release commits the selection.
    hl.bind("ALT + TAB", hl.dsp.global("caelestia:switcherNext"))
    hl.bind("ALT + SHIFT + TAB", hl.dsp.global("caelestia:switcherPrevious"))
    hl.bind("ALT_L", hl.dsp.global("caelestia:switcherAccept"), { release = true, ignore_mods = true, non_consuming = true })
    hl.bind("ALT_R", hl.dsp.global("caelestia:switcherAccept"), { release = true, ignore_mods = true, non_consuming = true })

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
        local function available()
            return i <= 4 or i == 10 or settings.openDisplayConnected()
        end
        hl.bind(mainMod .. " + " .. key, function()
            if available() then hl.dispatch(hl.dsp.focus({ workspace = i })) end
        end)
        hl.bind(mainMod .. " + SHIFT + " .. key, function()
            if available() then hl.dispatch(hl.dsp.window.move({ workspace = i })) end
        end)
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
    hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd(hyprScript("toggle-spotify.sh")))
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
    -- Screen recording alternative (same action as SUPER+ALT+CAPS_LOCK).
    hl.bind(mainMod .. " + R",               hl.dsp.exec_cmd("caelestia record -r -s"))

    -- Bluetooth / network / settings
    hl.bind(mainMod .. " + B",   hl.dsp.exec_cmd("blueman-manager"))
    hl.bind(mainMod .. " + M",   hl.dsp.exec_cmd("pavucontrol"))
    hl.bind(mainMod .. " + N",   hl.dsp.exec_cmd(terminal .. " --title nmtui -e nmtui"))
    hl.bind(mainMod .. " + X",   hl.dsp.exec_cmd("caelestia shell nexus open"))
    hl.bind(mainMod .. " + O",   hl.dsp.exec_cmd("obsidian"))
    hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("caelestia shell wallpapers pick"))

    -- media-audio-pipewire-restart script 
    hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(hyprScript("restart-pipewire.sh")))


    -- Wallpaper picker alternative (same action as SUPER+TAB).
    hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("caelestia shell wallpapers pick"))

    -- Clipboard / emoji
    hl.bind("CTRL + ALT + V",         hl.dsp.exec_cmd("caelestia clipboard"))
    hl.bind("CTRL + ALT + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"))
    hl.bind(mainMod .. " + period",   hl.dsp.exec_cmd("caelestia emoji -p"))

    -- Media keys (requires playerctl)
    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

    -- Toggle compositor shortcuts off/on; ordinary typing and app shortcuts still work.
    -- Only the restore chord is registered in this submap (including no media binds).
    -- See https://wiki.hypr.land/Configuring/Binds/#submaps
    hl.bind(mainMod .. " + ALT + L", hl.dsp.submap("keybinds-locked"))
    hl.define_submap("keybinds-locked", function()
        hl.bind(mainMod .. " + ALT + L", hl.dsp.submap("reset"))
    end)
end
