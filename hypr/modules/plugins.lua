return function(settings)
    -------------------
    ---- PLUGINS ------
    -------------------

    -- Toggle Hypr3D's 3D view when the plugin is loaded.
    if hl.plugin.hypr3d then
        hl.bind("SUPER + T", hl.plugin.hypr3d.toggle)
    end

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

        -- HyprGlass state lives in a file so the SUPER+G toggle survives config
        -- reloads and layer glass applies deterministically at load time.
        local glassStateFile = "/tmp/hyprglass-state"

        local function isGlassOn()
            local f = io.open(glassStateFile, "r")
            if not f then return false end
            local v = f:read("*l")
            f:close()
            return v == "on"
        end

        local glass_on = isGlassOn()

        hg.config({
            enabled = glass_on,
            default_theme = "dark",
            default_preset = "glass",
            layers = { enabled = glass_on },
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
        hg.preset("shell-glass", {
            inherits = "apple",
            glass_opacity = 0.65,
        })
        hg.layer("caelestia-background", { exclude = true })
        hg.layer("caelestia-border-exclusion", { exclude = true })
        hg.layer("quickshell", { exclude = true })
        hg.layer("caelestia-drawers", {
            preset = "shell-glass",
            mask_mode = "alpha",
            mask_threshold = 0.25,
            live_resample = true,
        })

            -- Toggle HyprGlass
        hl.bind("SUPER + G", function()
            glass_on = not glass_on
            local val = glass_on and "on" or "off"
            hl.dispatch(hl.dsp.exec_cmd("sh -c 'echo " .. val .. " > /tmp/hyprglass-state'"))
            hl.dispatch(hl.dsp.exec_cmd("hyprctl reload"))
        end)
    end
end
