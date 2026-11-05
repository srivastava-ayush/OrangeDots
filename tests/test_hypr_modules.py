"""Exercise Lua config registration without touching the running compositor."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]

# Stub the Hyprland API, retaining dispatcher arguments in a deterministic trace.
TRACE = r'''
local function repr(value)
    if type(value) == "function" then return "<callback>" end
    if type(value) ~= "table" then return tostring(value) end
    if rawget(value, "_path") then return value._path end
    local keys, values = {}, {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
        values[#values + 1] = tostring(key) .. "=" .. repr(value[key])
    end
    return "{" .. table.concat(values, ",") .. "}"
end
local function api(path)
    return setmetatable({_path = path}, {
        __index = function(_, key) return api(path .. "." .. key) end,
        __call = function(_, ...)
            local args = {...}
            print(path .. repr(args))
            if path == "hl.define_submap" or path == "hl.on" then args[2]() end
            return {call = path, args = args}
        end,
    })
end
hl = api("hl")
package.path = arg[1] .. "/?.lua;" .. package.path
dofile(arg[2])
if arg[3] then
    print("--RELOAD--")
    dofile(arg[2])
end
'''


@unittest.skipUnless(shutil.which("lua") and shutil.which("luac"), "Lua tools required")
class HyprModuleTests(unittest.TestCase):
    def run_config(self, root, reload=False):
        return subprocess.run(
            ["lua", "-", str(root), str(root / "hyprland.lua"), *(["reload"] if reload else [])],
            input=TRACE, text=True, capture_output=True, check=True,
            env={**os.environ, "SHELL": "/bin/zsh"},
        ).stdout

    def test_all_modules_parse(self):
        for path in [REPO / "hypr/hyprland.lua", *sorted((REPO / "hypr/modules").glob("*.lua"))]:
            with self.subTest(path=path.name):
                subprocess.run(["luac", "-p", str(path)], check=True, capture_output=True)

    def test_reload_registers_the_same_configuration(self):
        first, second = self.run_config(REPO / "hypr", reload=True).split("--RELOAD--\n")
        self.assertEqual(first, second)
        for expected in (
            "caelestia shell -d", "toggle-shell.sh", "toggle-spotify.sh",
            "layout=scrolling,workspace=1",
            "caelestia:switcherNext", "caelestia:switcherPrevious", "caelestia:switcherAccept",
            "keybinds-locked", "hyprglass", "spotify-special",
        ):
            self.assertIn(expected, first)

    def test_compositor_motion_matches_shell_animation_families(self):
        harness = r'''
local curves, animations = {}, {}
hl = {
    curve = function(name, curve) curves[name] = curve end,
    animation = function(animation) animations[animation.leaf] = animation end,
}
dofile(arg[1])({})
-- Every animation must resolve to a curve declared in this file. Hyprland
-- otherwise rejects the animation and silently falls back to its default.
for leaf, animation in pairs(animations) do
    assert(curves[animation.bezier], leaf .. " references undefined bezier " .. tostring(animation.bezier))
end
assert(curves.ayuOpen.points[1][1] == 0.22 and curves.ayuOpen.points[1][2] == 1)
assert(curves.ayuOpen.points[2][1] == 0.36 and curves.ayuOpen.points[2][2] == 1)
assert(curves.ayuClose.points[1][1] == 0.25 and curves.ayuClose.points[1][2] == 0)
assert(curves.ayuClose.points[2][1] == 0.35 and curves.ayuClose.points[2][2] == 1)
assert(curves.ayuMove.points[1][1] == 0.25 and curves.ayuMove.points[1][2] == 0.10)
assert(curves.ayuMove.points[2][1] == 0.25 and curves.ayuMove.points[2][2] == 1)
assert(curves.ayuLinear.points[1][1] == 0 and curves.ayuLinear.points[1][2] == 0)
assert(curves.ayuLinear.points[2][1] == 1 and curves.ayuLinear.points[2][2] == 1)
for _, leaf in ipairs({"workspacesIn", "workspacesOut"}) do
    assert(animations[leaf].bezier == "ayuOpen" and animations[leaf].speed == 3.5)
    assert(animations[leaf].style == "slidefadevert")
end
assert(animations.windowsIn.bezier == "ayuOpen" and animations.windowsIn.speed == 3.2)
assert(animations.windowsIn.style == "popin 10%")
assert(animations.windowsOut.bezier == "ayuClose" and animations.windowsOut.speed == 2.0)
assert(animations.windowsOut.style == "popin 60%")
assert(animations.windowsMove.bezier == "ayuMove" and animations.windowsMove.speed == 3.2)
for _, leaf in ipairs({"fadeIn", "fadeOut"}) do
    assert(animations[leaf].bezier == (leaf == "fadeIn" and "ayuOpen" or "ayuClose"))
    assert(animations[leaf].speed == (leaf == "fadeIn" and 2.4 or 2.0))
end
for _, leaf in ipairs({"layersIn", "layersOut"}) do
    assert(animations[leaf].bezier == (leaf == "layersIn" and "ayuOpen" or "ayuClose"))
    assert(animations[leaf].speed == (leaf == "layersIn" and 2.6 or 1.8))
    assert(animations[leaf].style == "slidefade")
end
assert(animations.border.bezier == "ayuLinear" and animations.border.speed == 3.2)
assert(animations.specialWorkspace.bezier == "ayuOpen" and animations.specialWorkspace.speed == 3.6)
assert(animations.specialWorkspace.style == "slidefadevert")
'''
        subprocess.run(
            ["lua", "-", str(REPO / "hypr/modules/animations.lua")],
            input=harness, text=True, capture_output=True, check=True,
        )

    def test_opendisplay_hotplug_and_workspace_guards(self):
        harness = r'''
local events, timers, rules, moves, binds = {}, {}, {}, {}, {}
local laptop = {name = "eDP-1"}
local ipad = {name = "OpenDisplay-1655"}
local monitors = {laptop, ipad}
local workspaces = {{id = 4, monitor = ipad}, {id = 8, monitor = laptop}, {id = 10, monitor = ipad}}
hl = {
    on = function(event, callback) events[event] = callback end,
    timer = function(callback, options)
        assert(options.type == "oneshot")
        timers[#timers + 1] = callback
        return {}
    end,
    get_monitors = function() return monitors end,
    get_monitor = function(name) if name == laptop.name then return laptop end end,
    get_workspaces = function() return workspaces end,
    workspace_rule = function(spec)
        spec.enabled = true
        function spec:set_enabled(enabled) self.enabled = enabled end
        rules[#rules + 1] = spec
        return spec
    end,
    dispatch = function(spec) moves[#moves + 1] = spec end,
    bind = function(key, callback) binds[key] = callback end,
    window_rule = function() end,
    define_submap = function() end,
}
local function dispatcher(spec) return spec end
local namespace = setmetatable({}, {__index = function() return dispatcher end})
hl.dsp = setmetatable({window = namespace, workspace = namespace}, {__index = function() return dispatcher end})
local settings = {
    configHome = "/config", terminal = "kitty", fileManager = "yazi",
    ide = "zed", browser = "browser", hyprScript = function(name) return name end,
}
dofile(arg[1])(settings)
dofile(arg[2])(settings)
local function flush(event)
    events[event]()
    local callbacks = timers
    timers = {}
    for _, callback in ipairs(callbacks) do callback() end
end
flush("config.reloaded")
assert(#rules == 5 and rules[1].monitor == ipad.name and rules[1].workspace == "5" and rules[5].workspace == "9")
assert(#moves == 3 and moves[1].monitor == "eDP-1" and moves[2].monitor == ipad.name and moves[3].monitor == "eDP-1")
flush("monitor.added")
assert(#rules == 5, "unchanged output must not duplicate rules")
moves = {}
binds["SUPER + 5"]()
binds["SUPER + SHIFT + 9"]()
assert(#moves == 2 and moves[1].workspace == 5 and moves[2].workspace == 9)
monitors = {laptop}
flush("monitor.removed")
for _, rule in ipairs(rules) do assert(not rule.enabled) end
moves = {}
binds["SUPER + 5"]()
binds["SUPER + SHIFT + 9"]()
assert(#moves == 0, "disconnected iPad shortcuts must not dispatch")
binds["SUPER + 1"]()
assert(#moves == 1 and moves[1].workspace == 1)
binds["SUPER + 0"]()
assert(#moves == 2 and moves[2].workspace == 10)
ipad = {name = "OpenDisplay-9999"}
monitors = {laptop, ipad}
moves = {}
flush("monitor.added")
assert(#rules == 10 and rules[6].monitor == ipad.name)
assert(#moves == 3 and moves[2].monitor == ipad.name)
-- Monitor bursts are coalesced into one deferred reconciliation.
events["monitor.added"]()
events["monitor.removed"]()
assert(#timers == 1)
'''
        subprocess.run(
            ["lua", "-", str(REPO / "hypr/modules/opendisplay.lua"),
             str(REPO / "hypr/modules/keybindings.lua")],
            input=harness, text=True, capture_output=True, check=True,
            env={**os.environ, "SHELL": "/bin/zsh"},
        )

    def test_monitor_reload_preserves_live_opendisplay_geometry(self):
        harness = r'''
local specs, rules = {}, {}
hl = {
    get_monitors = function() return {
        {name = "eDP-1"},
        {name = "OpenDisplay-9876", width = 2048, height = 1536,
         refresh_rate = 30, x = 1920, y = 312, scale = 2, transform = 0},
    } end,
    monitor = function(spec) specs[#specs + 1] = spec end,
    workspace_rule = function(spec) rules[#rules + 1] = spec end,
}
dofile(arg[1])({})
assert(#specs == 2)
assert(specs[1].output == "OpenDisplay-9876")
assert(specs[1].mode == "2048x1536@30.00000")
assert(specs[1].position == "1920x312" and specs[1].scale == 2)
assert(specs[2].output == "eDP-1" and specs[2].mode == "1920x1080@144")
assert(#rules == 5 and rules[5].monitor == "eDP-1")
assert(rules[4].workspace == "4" and rules[5].workspace == "10")
'''
        subprocess.run(
            ["lua", "-", str(REPO / "hypr/modules/monitors.lua")],
            input=harness, text=True, capture_output=True, check=True,
        )

    def test_relocated_config_and_module_edits_on_reload(self):
        with tempfile.TemporaryDirectory(dir="/tmp/opencode" if Path("/tmp/opencode").is_dir() else None) as temp:
            root = Path(temp) / "config with spaces"
            shutil.copytree(REPO / "hypr", root)
            entry = root / "hyprland.lua"
            # Edit a loaded module in the same Lua process: the second load
            # must read the changed file rather than reuse require's cache.
            harness = TRACE + r'''
local file = assert(io.open(arg[1] .. "/modules/environment.lua", "w"))
file:write('return function() hl.env("ORANGEDOTS_RELOAD_TEST", "updated") end\n')
file:close()
print("--EDITED--")
dofile(arg[2])
'''
            result = subprocess.run(
                ["lua", "-", str(root), str(entry)], input=harness,
                text=True, capture_output=True, check=True,
                env={**os.environ, "SHELL": "/bin/zsh"},
            ).stdout
            first, second = result.split("--EDITED--\n")
            self.assertNotIn("ORANGEDOTS_RELOAD_TEST", first)
            self.assertIn("ORANGEDOTS_RELOAD_TEST", second)
