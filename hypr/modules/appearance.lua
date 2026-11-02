return function(settings)
    -----------------------
    ---- LOOK AND FEEL ----
    -----------------------

    hl.config({
        general = {
            gaps_in  = 4,
            gaps_out = 8,

            border_size = 1,

            resize_on_border = false,
            allow_tearing    = false,

            layout = "dwindle",
        },

        decoration = {
            rounding       = 22,
            rounding_power = 4,

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
end
