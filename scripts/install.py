#!/usr/bin/env python3
"""Install config links/presets without installing packages or touching a session."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import sys

REPO = Path(__file__).resolve().parents[1]
PRESETS = ("shell.json", "shell-tokens.json", "cli.json")


def exists(path):
    return path.exists() or path.is_symlink()


def check_parents(path):
    for parent in (path, *path.parents):
        if exists(parent) and not parent.is_dir():
            raise ValueError(f"Not a directory (or broken directory link): {parent}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--full", action="store_true", help="Also link the personal Hyprland config; review its monitor/app settings first")
    parser.add_argument("--dry-run", action="store_true", help="Print the plan without creating or changing anything")
    parser.add_argument("--config-home", type=Path, help="Defaults to XDG_CONFIG_HOME or ~/.config")
    parser.add_argument("--backup-dir", type=Path, help="An unused backup location; defaults beneath XDG_STATE_HOME/orangedots/backups")
    args = parser.parse_args()

    home = Path.home()
    config = (args.config_home or Path(os.environ.get("XDG_CONFIG_HOME") or home / ".config")).expanduser().absolute()
    state = Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    backup = (args.backup_dir or state / "orangedots/backups" / stamp).expanduser().absolute()
    if os.geteuid() == 0 and args.config_home is None and not args.dry_run:
        raise ValueError("Run as your normal user, not with sudo. Use --config-home only for an explicit staging target.")

    shell = REPO / "quickshell/caelestia"
    for required in (shell / "shell.qml", shell / "LICENSE", REPO / "hypr/hyprland.lua"):
        if not required.is_file():
            raise ValueError(f"Incomplete checkout: {required}")
    for name in PRESETS:
        with (REPO / "caelestia" / name).open() as source:
            json.load(source)

    links = [(shell, config / "quickshell/caelestia")]
    if args.full:
        links.append((REPO / "hypr", config / "hypr"))
    copies = [(REPO / "caelestia" / name, config / "caelestia" / name) for name in PRESETS]

    # A legacy whole-directory symlink may point into an older checkout. Never
    # move its real caelestia directory out of that checkout or create links
    # inside it. Detach only the config symlink and preserve other configs via
    # individual links to their original locations.
    quickshell = config / "quickshell"
    shell_target = quickshell / "caelestia"
    detach_parent = quickshell.is_symlink() and quickshell.is_dir() and shell_target.resolve() != shell.resolve()
    preserved_configs = []
    if detach_parent:
        preserved_configs = [(child.name, child) for child in quickshell.resolve().iterdir() if child.name != "caelestia"]

    # Validate the entire plan before moving an existing config. Never replace
    # a parent directory, follow a broken config link, or overwrite a backup.
    check_parents(config)
    for _, target in links + copies:
        check_parents(target.parent)
    conflicts = [target for source, target in links if exists(target) and target.resolve() != source.resolve() and not (detach_parent and target == shell_target)]
    backup_targets = ([quickshell] if detach_parent else []) + conflicts
    for target in backup_targets:
        saved = backup / target.relative_to(config)
        check_parents(saved.parent)
        if exists(saved):
            raise ValueError(f"Refusing to overwrite an existing backup: {saved}")
        if backup.resolve().is_relative_to(target.resolve()):
            raise ValueError(f"Backup must not be inside the config being replaced: {target}")

    print(f"Source: {REPO}")
    print(f"Config: {config}")
    if args.full:
        print("FULL DOTFILES: the bundled monitor, app, rule, and gesture preferences will be linked.")
    if detach_parent:
        saved = backup / "quickshell"
        print(f"BACKUP directory link: {quickshell} -> {saved}")
        if not args.dry_run:
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(quickshell), str(saved))
            quickshell.mkdir()
        for name, original in preserved_configs:
            print(f"PRESERVE other config: {quickshell / name}")
            if not args.dry_run:
                (quickshell / name).symlink_to(original, target_is_directory=original.is_dir())
    for source, target in links:
        detached_target = detach_parent and target == shell_target
        if not detached_target and exists(target) and target.resolve() == source.resolve():
            print(f"KEEP link: {target}")
            continue
        if not detached_target and exists(target):
            saved = backup / target.relative_to(config)
            print(f"BACKUP: {target} -> {saved}")
            if not args.dry_run:
                saved.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(target), str(saved))
        print(f"LINK: {target} -> {source}")
        if not args.dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(source, target_is_directory=True)

    for source, target in copies:
        # Existing preferences and all other private files (calendar-url, etc.)
        # are deliberately left alone, including dangling preference symlinks.
        if exists(target):
            print(f"KEEP preference: {target}")
        else:
            print(f"SEED: {target}")
            if not args.dry_run:
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)

    print("Dry run: nothing changed." if args.dry_run else "Configuration installed; the desktop session was not restarted.")
    print("Dependencies and native modules still require the README installation steps; this installer never invokes sudo, CMake, or package managers.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Installation stopped: {error}", file=sys.stderr)
        sys.exit(1)
