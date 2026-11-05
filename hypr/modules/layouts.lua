return function(settings)

    hl.config({
        dwindle = {
            preserve_split = true,
        },
    })

 
    hl.config({
        master = {
            new_status = "master",
        },
    })

    hl.config({
        scrolling = {
            fullscreen_on_one_column = true,
            explicit_column_widths   = "0.333,0.667, 0.5, 1.0",
        },
    })


    for _, ws in ipairs({ "1", "2" }) do
        hl.workspace_rule({ workspace = ws, layout = "scrolling" })
    end

end
