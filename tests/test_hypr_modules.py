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
