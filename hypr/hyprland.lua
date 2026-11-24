-- OrangeDots Hyprland configuration (Lua, not .conf syntax).
-- Edit modules/settings.lua for apps and modules/ for individual features.
-- Hyprland resolves these modules relative to this configuration directory.
-- See https://wiki.hypr.land/configuring/

-- Hyprland already puts this directory on the module search path. Tools that
-- load the config outside Hyprland (a plain `lua hypr/hyprland.lua` from the
-- repo root, editors, linters) start somewhere else and fail with
-- "module 'modules.settings' not found". Adding this file's own directory makes
-- those runs behave like the real one; the guard keeps the sandboxed case safe.
local source = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
local configDir = source:match("^@(.+)[/\\]")
if configDir and not package.path:find(configDir, 1, true) then
    package.path = configDir .. "/?.lua;" .. package.path
end

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
    "opendisplay",
    "misc",
    "input",
    "keybindings",
    "rules",
    "plugins",
}) do
    loadModule(name)(settings)
end
