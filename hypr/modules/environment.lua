return function(settings)
    -------------------------------
    ---- ENVIRONMENT VARIABLES ----
    -------------------------------


    local localBin = os.getenv("HOME") .. "/.local/bin"
    local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"

    if not (":" .. path .. ":"):find(":" .. localBin .. ":", 1, true) then
        hl.env("PATH", localBin .. ":" .. path)
    end

    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")
end
