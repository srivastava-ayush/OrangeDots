#!/usr/bin/env python3
"""Local sidebar adapter for the same cliphist/wl-copy backend as caelestia clipboard.

Only JSON summaries go to stdout. Decoded clipboard contents never enter shell
commands, logs or process arguments. Pins/previews are private local files.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

BASE = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "caelestia/clipboard-sidebar"
PINS = BASE / "pins"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "caelestia/clipboard-sidebar"


def run(args, data=None):
    result = subprocess.run(args, input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    if result.returncode:
        raise RuntimeError(f"{args[0]} failed. Check that clipboard history and Wayland clipboard tools are available.")
    return result.stdout


def private_dir(path):
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    path.chmod(0o700)


def write_private(path, data):
    # Atomic replacement, including when a previous operation was interrupted.
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("wb") as handle:
        os.chmod(temporary, 0o600)
        handle.write(data)
    temporary.replace(path)


def mime(data):
    if data.startswith(b"\x89PNG\r\n\x1a\n"): return "image/png"
    if data.startswith(b"\xff\xd8\xff"): return "image/jpeg"
    if data.startswith((b"GIF87a", b"GIF89a")): return "image/gif"
    if data.startswith(b"RIFF") and data[8:12] == b"WEBP": return "image/webp"
    if data.startswith(b"BM"): return "image/bmp"
    try:
        data.decode("utf-8")
        if b"\0" not in data: return "text/plain;charset=utf-8"
    except UnicodeDecodeError:
        pass
    return "application/octet-stream"


def history():
    rows = []
    for line in run(["cliphist", "list"]).decode("utf-8", "replace").splitlines():
        identity, separator, label = line.partition("\t")
        if separator and identity.isdecimal():
            rows.append({"id": "history:" + identity, "label": label, "image": "[[ binary data" in label and bool(re.search(r"\b(png|jpeg|jpg|gif|webp|bmp)\b", label, re.I)), "pinned": False})
    return rows


def pin_path(identity):
    if not re.fullmatch(r"pin:[0-9a-f]{64}", identity):
        raise ValueError("Invalid pinned entry")
    return PINS / identity[4:]


def decode(identity):
    if identity.startswith("pin:"):
        return pin_path(identity).read_bytes()
    if not re.fullmatch(r"history:[0-9]+", identity):
        raise ValueError("Invalid clipboard entry")
    return run(["cliphist", "decode"], identity[8:].encode() + b"\n")


def pins():
    result = []
    if not PINS.exists(): return result
    for metadata in sorted(PINS.glob("*.json"), key=lambda file: file.stat().st_mtime, reverse=True):
        try:
            row = json.loads(metadata.read_text())
            path = pin_path(row["id"])
            if path.is_file():
                row["preview"] = path.as_uri() if row["image"] else ""
                result.append(row)
        except (ValueError, OSError, KeyError):
            continue
    return result


def listing():
    private_dir(CACHE)
    rows = history()[:200]
    live = set()
    previews = 0
    for row in rows:
        row["preview"] = ""
        if row["image"] and previews < 24:
            previews += 1
            try:
                # Hash the bytes, not a reused cliphist ID: avoid stale previews
                # after the history database has been wiped/recreated.
                data = decode(row["id"])
                if len(data) <= 20 * 1024 * 1024 and mime(data).startswith("image/"):
                    path = CACHE / hashlib.sha256(data).hexdigest()
                    live.add(path.name)
                    if not path.exists(): write_private(path, data)
                    row["preview"] = path.as_uri()
            except (RuntimeError, OSError):
                pass
    for path in CACHE.iterdir():
        if path.is_file() and path.name not in live:
            path.unlink()
    return {"entries": pins() + rows, "error": ""}


def main():
    os.umask(0o077)
    request = json.loads(sys.stdin.readline())
    action = request.get("action", "list")
    identity = request.get("id", "")
    if action in ("copy", "paste"):
        data = decode(identity)
        run(["wl-copy", "--type", mime(data)], data)
        if action == "paste":
            if not shutil.which("wtype"):
                raise RuntimeError("Copied. Install wtype for direct paste, or press Ctrl+V.")
            time.sleep(0.3)  # Let the sidebar close and return focus first.
            try:
                run(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"])
            except RuntimeError:
                raise RuntimeError("Copied. Direct paste is unavailable in this compositor; press Ctrl+V.") from None
        return {"ok": True, "message": "Pasted" if action == "paste" else "Copied"}
    if action == "pin":
        data = decode(identity)
        if len(data) > 20 * 1024 * 1024:
            raise ValueError("This item is too large to pin (20 MiB limit).")
        private_dir(PINS)
        digest = hashlib.sha256(data).hexdigest()
        image = mime(data).startswith("image/")
        label = "Pinned image" if image else data.decode("utf-8", "replace")[:4096]
        row = {"id": "pin:" + digest, "label": label, "image": image, "pinned": True}
        write_private(PINS / digest, data)
        write_private(PINS / (digest + ".json"), json.dumps(row).encode())
    elif action == "delete":
        if identity.startswith("pin:"):
            path = pin_path(identity)
            path.unlink(missing_ok=True)
            path.with_suffix(".json").unlink(missing_ok=True)
        elif re.fullmatch(r"history:[0-9]+", identity):
            run(["cliphist", "delete"], identity[8:].encode() + b"\n")
        else:
            raise ValueError("Invalid clipboard entry")
    elif action in ("clear", "clear-all"):
        run(["cliphist", "wipe"])
        run(["wl-copy", "--clear"])
        if action == "clear-all":
            for row in pins():
                path = pin_path(row["id"])
                path.unlink(missing_ok=True)
                path.with_suffix(".json").unlink(missing_ok=True)
    elif action != "list":
        raise ValueError("Unknown clipboard action")
    return listing()


if __name__ == "__main__":
    try:
        print(json.dumps(main()))
    except Exception as error:
        # Never return subprocess stderr: tools may include private clip contents.
        message = str(error) if isinstance(error, (RuntimeError, ValueError)) else "Clipboard operation failed. Check cliphist, wl-copy and local file permissions."
        print(json.dumps({"error": message}))
