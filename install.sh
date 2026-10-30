#!/usr/bin/env bash
# Configuration installer only: dependency/native-module setup stays explicit.
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
exec python3 "$repo/scripts/install.py" "$@"
