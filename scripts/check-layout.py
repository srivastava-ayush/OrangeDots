#!/usr/bin/env python3
"""Check source imports and the install/runtime naming contract without a GUI."""

import argparse
import json
from pathlib import Path
import re
import sys

REPO = Path(__file__).resolve().parents[1]
SHELL = REPO / "quickshell/caelestia"
ENTRYPOINTS = (
    "modules/taskbar/TaskbarLayout.qml",
    "modules/taskbar/TaskbarWrapper.qml",
    "modules/desktop/Desktop.qml",
    "modules/desktop/DesktopWindow.qml",
    "modules/settings/SettingsView.qml",
    "modules/settings/SettingsWindows.qml",
    "modules/dashboard/DashboardContent.qml",
    "modules/dashboard/DashboardWrapper.qml",
    "modules/dashboard/Calendar.qml",
    "modules/launcher/LauncherWrapper.qml",
    "modules/lockscreen/LockScreen.qml",
    "modules/notifications/banners/BannerWrapper.qml",
    "modules/notifications/shade/NotificationShade.qml",
    "modules/screencapture/ScreenCapture.qml",
    "modules/onscreendisplay/OsdWrapper.qml",
    "modules/sessionmenu/SessionMenuWrapper.qml",
)
OLD_ROOTS = ("bar", "drawers", "nexus", "lock", "notifshade", "areapicker", "osd", "session")


def check_shell(shell):
    errors = []
    for name in ("shell.qml", "LICENSE", *ENTRYPOINTS):
        if not (shell / name).is_file():
            errors.append(f"Missing shell entry point: {name}")
    files = [shell / "shell.qml"]
    for directory in ("modules", "components", "services", "utils"):
        files.extend((shell / directory).rglob("*.qml"))
    for file in files:
        if not file.is_file():
            continue
        for number, line in enumerate(file.read_text().splitlines(), 1):
            match = re.match(r'\s*import\s+(?:"([^"]+)"|(qs(?:\.[A-Za-z_]\w*)+))', line)
            if not match:
                continue
            local, uri = match.groups()
            target = file.parent / local if local else shell.joinpath(*uri.split(".")[1:])
            if not target.exists():
                errors.append(f"{file.relative_to(shell)}:{number}: unresolved import {local or uri}")
            if uri and any(uri == f"qs.modules.{old}" or uri.startswith(f"qs.modules.{old}.") for old in OLD_ROOTS):
                errors.append(f"{file.relative_to(shell)}:{number}: obsolete module URI {uri}")
        if "/home/ayush/" in file.read_text():
            errors.append(f"Personal home path in runtime source: {file.relative_to(shell)}")
    for name in OLD_ROOTS:
        if any((shell / "modules" / name).rglob("*.qml")):
            errors.append(f"Obsolete module tree still contains QML: modules/{name}")
    return errors, len(files)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--shell-root", type=Path, help="Validate a staged/installed QML tree instead of the checkout")
    args = parser.parse_args()
    shell = (args.shell_root or SHELL).resolve()
    errors, count = check_shell(shell)
    if args.shell_root is None:
        for name in ("shell.json", "shell-tokens.json", "cli.json"):
            try:
                json.loads((REPO / "caelestia" / name).read_text())
            except (OSError, ValueError) as error:
                errors.append(f"Invalid installation preset {name}: {error}")
        cmake = (SHELL / "CMakeLists.txt").read_text()
        for contract in ("project(caelestia-shell", "quickshell/caelestia", "foreach(dir assets components modules services utils)"):
            if contract not in cmake:
                errors.append(f"CMake compatibility contract changed: {contract}")
        for file in (REPO / "hypr").rglob("*"):
            if file.is_file() and file.suffix in (".lua", ".sh") and "/home/ayush/" in file.read_text():
                errors.append(f"Non-portable Hyprland path: {file.relative_to(REPO)}")
        for name in ("toggle-shell.sh", "toggle-spotify.sh", "toggle-refresh-rate.sh"):
            if not (REPO / "hypr/scripts" / name).is_file():
                errors.append(f"Missing installed Hyprland helper: {name}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"PASS: {count} QML sources, local imports, module entry points, and runtime/install naming contract")
    return 0


if __name__ == "__main__":
    sys.exit(main())
