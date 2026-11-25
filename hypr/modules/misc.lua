return function(settings)
    ----------------
    ----  MISC  ----
    ----------------

    hl.config({
        misc = {
            force_default_wallpaper = 0,    -- disables the anime mascot wallpapers
            disable_hyprland_logo   = true, -- disables the random Hyprland logo / anime girl background
            -- Blackout turns the panels off with the DPMS dispatcher. Hyprland
            -- keeps them off until told otherwise, so without these the first
            -- key press or mouse move would never bring the screen back.
            mouse_move_enables_dpms = true,
            key_press_enables_dpms  = true,
        },
    })
end
