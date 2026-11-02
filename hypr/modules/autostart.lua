return function(settings)
    -------------------
    ---- AUTOSTART ----
    -------------------

    hl.on("hyprland.start", function()
        hl.exec_cmd("caelestia shell -d")
        hl.exec_cmd("hyprpm reload -n")
        hl.exec_cmd("kdeconnectd")
        hl.exec_cmd("wl-paste --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
    end)
end
