"""Transparent Wayland integration tests. Run: python3 tests/taskbar.test.py

Requires a Wayland session, Quickshell, and the native Caelestia QML modules.
Uses a transparent background-layer surface with no input region, no exclusive
zone, no Hyprland IPC connection, and isolated settings/state directories.
"""

import json
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


SHELL = Path(__file__).resolve().parents[1]


def run(config, env, expected, mode="load"):
    result = subprocess.run(
        ["qs", "--no-color", "--path", str(config)],
        env={**env, "TASKBAR_EXPECT_INITIAL": expected, "TASKBAR_TEST_MODE": mode},
        capture_output=True,
        text=True,
        timeout=40,
    )
    output = result.stdout + result.stderr
    assert result.returncode == 0 and "TASKBAR TEST PASS" in output, output
    for error in ("TypeError", "ReferenceError", "Binding loop", "Cannot anchor", "Cannot assign object", "is not a function"):
        assert error not in output, output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("layout", "background", "notifications", "hover", "nexus", "tint", "tint-load"))
    mode = parser.parse_args().mode
    assert shutil.which("qs"), "Quickshell (qs) must be installed"
    assert os.environ.get("WAYLAND_DISPLAY"), "Run these tests inside a Wayland session"
    temp_parent = "/tmp/opencode" if Path("/tmp/opencode").is_dir() else None
    with tempfile.TemporaryDirectory(prefix="taskbar-test-", dir=temp_parent) as temporary:
        base = Path(temporary)
        config = base / "shell"
        config.mkdir()
        for directory in ("modules", "components", "services", "utils"):
            (config / directory).symlink_to(SHELL / directory, target_is_directory=True)
        (config / "shell.qml").symlink_to(SHELL / "tests/taskbar.qml")

        env = os.environ.copy()
        for variable in ("HYPRLAND_INSTANCE_SIGNATURE", "DISPLAY", "DBUS_SESSION_BUS_ADDRESS"):
            env.pop(variable, None)
        for directory in ("config", "state", "cache", "data"):
            target = base / directory
            (target / "caelestia").mkdir(parents=True)
            env[f"XDG_{directory.upper()}_HOME"] = str(target)
        env.update(QT_QPA_PLATFORM="wayland", QT_QUICK_BACKEND="software", QS_NO_RELOAD_POPUP="1")

        (base / "config/caelestia/shell.json").write_text(json.dumps({
            "bar": {
                "persistent": True,
                "clock": {"showDate": True},
                "workspaces": {"perMonitorWorkspaces": False},
                "statusIcons": [
                    {"id": "audio", "enabled": True},
                    {"id": "network", "enabled": True},
                    {"id": "battery", "enabled": True},
                ],
            },
            "appearance": {"anim": {"durations": {"scale": 0}}},
        }))
        state = base / "state/caelestia/taskbar.json"

        if mode:
            run(config, env, "left", mode=mode)
            print(f"PASS: {mode}")
            return

        run(config, env, "left", mode="layout")
        assert json.loads(state.read_text()) == {"orientation": "top"}
        print("PASS: Left/Top layout, popouts, auto-hide, fullscreen, and saving")
        run(config, env, "top")
        print("PASS: orientation survives restarting the shell")
        run(config, env, "top", mode="background")
        print("PASS: calendar and system popout background sizing in Top and Left modes")
        run(config, env, "left", mode="notifications")
        print("PASS: taskbar notification shade, hover settings, drawer IPC, auto-hide, and unchanged banners")
        run(config, env, "top", mode="hover")
        print("PASS: icon-to-popout hover handoff, padding, persistence, and dismissal for Top and Left bars")
        run(config, env, "left", mode="nexus")
        print("PASS: Nexus nested navigation, Orange OS About/version, and removal of empty pages")
        run(config, env, "left", mode="tint")
        tint_state = base / "state/caelestia/shell-tint.json"
        assert json.loads(tint_state.read_text()) == {"enabled": True, "colour": "#173f3b", "strength": 0.72}
        run(config, env, "left", mode="tint-load")
        print("PASS: Nexus shell tint, live surfaces, unchanged accents, contrast, transparency, reset, and persistence")
        for contents, expected in (
            ("{", {"enabled": False, "colour": "#243447", "strength": 0.65}),
            ("null", {"enabled": False, "colour": "#243447", "strength": 0.65}),
            ('{"enabled":"yes","colour":"bad","strength":"bad"}', {"enabled": False, "colour": "#243447", "strength": 0.65}),
            ('{"enabled":true,"colour":"#abc","strength":9}', {"enabled": True, "colour": "#aabbcc", "strength": 1}),
        ):
            tint_state.write_text(contents)
            run(config, {**env, "TINT_EXPECT": json.dumps(expected)}, "left", mode="tint-load")
        print("PASS: malformed shell-tint settings, colour normalization, and strength limits")

        for contents, expected in (
            ('{"orientation":"left"}', "left"),
            ('{"orientation":"bottom"}', "left"),
            ('{"orientation":null}', "left"),
            ('{"orientation":42}', "left"),
            ('{"orientation":', "left"),
        ):
            state.write_text(contents)
            run(config, env, expected)
        print("PASS: saved Left and malformed/unsupported values")


if __name__ == "__main__":
    main()
