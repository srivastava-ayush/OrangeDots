return function(settings)
    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
    hl.config({
        dwindle = {
            preserve_split = true,
        },
    })

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
    hl.config({
        master = {
            new_status = "master",
        },
    })

    -- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-opayout/
    hl.config({
        scrolling = {
            fullscreen_on_one_column = true,
            explicit_column_widths   = "0.333, 0.5, 0.667, 1.0",
        },
    })

    -- Scrolling on workspaces 1–2, monocle on 3–4; others use the dwindle default.
    for _, ws in ipairs({ "1", "2" }) do
        hl.workspace_rule({ workspace = ws, layout = "scrolling" })
    end

end
