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
            explicit_column_widths   = "0.33,0.5,0.67,1",
        },
    })

    for _, ws in ipairs({ "1", "2" }) do
        hl.workspace_rule({ workspace = ws, layout = "scrolling" })
    end

end
