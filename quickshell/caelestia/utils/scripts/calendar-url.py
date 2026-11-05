#!/usr/bin/env python3
"""Store a calendar feed secret privately. Request arrives over stdin, never argv."""
import json
import os
from pathlib import Path
import sys
import tempfile
from urllib.parse import urlsplit


def main():
    request = json.loads(sys.stdin.readline())
    action = request.get("action")
    if action not in ("save", "clear"):
        raise ValueError("Unknown calendar setting action.")
    supplied = request.get("url", "")
    if action == "save" and not isinstance(supplied, str):
        raise ValueError("Invalid calendar URL.")
    url = supplied.strip() if action == "save" else ""
    if action == "save":
        if not isinstance(url, str) or not url or len(url) > 8192 or any(character.isspace() for character in url):
            raise ValueError("Paste a complete HTTP(S) iCal URL without spaces or line breaks.")
        try:
            parsed = urlsplit(url)
            valid = parsed.scheme in ("http", "https") and bool(parsed.hostname) and parsed.username is None and parsed.password is None
            parsed.port  # Validate the port without ever echoing the URL.
        except ValueError:
            valid = False
        if not valid:
            raise ValueError("Paste a valid HTTP(S) iCal URL. HTTPS is recommended.")

    base = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "caelestia"
    base.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = None
    try:
        descriptor, name = tempfile.mkstemp(prefix=".calendar-url-", dir=base)
        temporary = Path(name)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            os.fchmod(handle.fileno(), 0o600)
            handle.write(url + "\n" if url else "")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, base / "calendar-url")
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return {"ok": True}


if __name__ == "__main__":
    try:
        print(json.dumps(main()))
    except ValueError:
        print(json.dumps({"ok": False, "error": "Paste a valid HTTP(S) iCal URL without credentials, spaces or line breaks."}))
    except Exception:
        # Filesystem/subprocess errors must never expose the supplied secret.
        print(json.dumps({"ok": False, "error": "Could not save the calendar setting. Check permissions on your Caelestia config directory."}))
