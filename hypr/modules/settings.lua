local terminal    = "kitty"
local fileManager = "yazi"
local ide         = "zed"
local browser     = "helium-browser"

-- Resolve helpers through the installed config, not a personal clone path.
local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local function hyprScript(name)
    return "bash " .. string.format("%q", configHome .. "/hypr/scripts/" .. name)
end

return {
    terminal = terminal,
    fileManager = fileManager,
    ide = ide,
    browser = browser,
    configHome = configHome,
    hyprScript = hyprScript,
}
