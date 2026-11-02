return function(settings)
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
end
