-- OrangeDots Hyprland configuration (Lua, not .conf syntax).
-- Edit modules/settings.lua for apps and modules/ for individual features.
-- Hyprland resolves these modules relative to this configuration directory.
-- See https://wiki.hypr.land/configuring/

local function loadModule(name)
    local module = "modules." .. name
    -- require caches modules; discard only our own entries so edits are read
    -- again on every reload, including the callbacks registered by each file.
    package.loaded[module] = nil
    return require(module)
end

local settings = loadModule("settings")

-- Keep registration order explicit: curves precede animations, layout defaults
-- precede workspace rules, and plugin setup follows the ordinary bindings.
for _, name in ipairs({
    "monitors",
    "autostart",
    "environment",
    "appearance",
    "animations",
    "layouts",
    "misc",
    "input",
    "keybindings",
    "rules",
    "plugins",
}) do
    loadModule(name)(settings)
end
