#!/usr/bin/env bash
# Install only this fork's rebuilt core QML module, never Qt or Quickshell.
# Run as your normal desktop user so sudo can prompt on your own terminal.
set -euo pipefail

die() { printf '%s\n' "$*" >&2; exit 1; }
source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build="$source_dir/build"
install_script="$build/plugin/src/Caelestia/cmake_install.cmake"
system_module=/usr/lib/qt6/qml/Caelestia
files=(lib/libcaelestia-core.so libcaelestia-coreplugin.so qmldir caelestia-core.qmltypes)

[[ $EUID != 0 ]] || die 'Run this script as your normal desktop user, not with sudo.'
[[ $# == 0 || ( $# == 1 && $1 == --check ) ]] || die "Usage: $0 [--check]"
for command in cmake caelestia qs python3 sudo pkg-config install; do
    command -v "$command" >/dev/null || die "Missing command: $command"
done
[[ -n ${WAYLAND_DISPLAY:-} ]] || die 'Run inside your Wayland desktop session.'
[[ -f "$build/CMakeCache.txt" && -f "$install_script" ]] || die 'Configure/build the native plugin first; see README.md.'
prefix="$(sed -n 's/^CMAKE_INSTALL_PREFIX:PATH=//p' "$build/CMakeCache.txt")"
home_dir="$(sed -n 's/^CMAKE_HOME_DIRECTORY:INTERNAL=//p' "$build/CMakeCache.txt")"
[[ $prefix == /usr && $home_dir == "$source_dir" ]] || die 'This installer requires this checkout configured with CMAKE_INSTALL_PREFIX=/usr.'
[[ $(pkg-config --modversion Qt6Core) == 6.12.* ]] || die 'The private-API recovery is currently reviewed only for Qt 6.12.'

unlocked() {
    local state
    state="$(caelestia shell lock isLocked 2>/dev/null)" || return 1
    [[ $state == false ]]
}
instance_count() {
    qs -c caelestia list -j | python3 -c '
import json, sys
text = sys.stdin.read().strip()
instances = [] if text.startswith("No running instances") else json.loads(text)
if not isinstance(instances, list):
    sys.exit("Invalid shell instance list")
print(len(instances))'
}
stop_unlocked_shell() {
    local count
    count="$(instance_count)" || return 1
    if [[ $count != 0 ]]; then
        [[ $count == 1 ]] && unlocked || return 1
        caelestia shell -k || return 1
    fi
    [[ $(instance_count) == 0 ]]
}
unlocked || die 'The shell must be running and confirmed unlocked. Do not install while locked.'
count="$(instance_count)"
[[ $count == 1 ]] || die 'Expected exactly one running Caelestia instance on this display.'
for file in "${files[@]}"; do
    [[ -f "$system_module/$file" && ! -L "$system_module/$file" ]] || die "Expected a regular installed module file: $system_module/$file"
    if command -v pacman >/dev/null && pacman -Qqo "$system_module/$file" >/dev/null 2>&1; then
        die "Refusing to overwrite package-owned file: $system_module/$file"
    fi
done

if [[ ${1:-} == --check ]]; then
    printf 'Preflight passed. Only these manually installed files will change:\n'
    printf '  %s\n' "${files[@]/#/$system_module/}"
    exit 0
fi

cmake --build "$build" --target caelestia-coreplugin --parallel 2
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/native-backups"
mkdir -p -- "$backup_root"
backup="$(mktemp -d "$backup_root/lock-render-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
for file in "${files[@]}"; do
    mkdir -p -- "$backup/$(dirname -- "$file")"
    cp --preserve=mode,timestamps -- "$system_module/$file" "$backup/$file"
done
printf 'Original module backup: %s\n' "$backup"

# Apply CMake's install RPATH changes without root privileges. Only explicitly
# allowlisted staged files will be copied to /usr; no submodules or packages.
stage="$backup/staged"
DESTDIR="$stage" cmake -DCMAKE_INSTALL_LOCAL_ONLY=ON -P "$install_script"
python3 -c '
from pathlib import Path
import sys
stage = Path(sys.argv[1])
expected = {Path(sys.argv[2].lstrip("/")) / name for name in sys.argv[3:]}
actual = {p.relative_to(stage) for p in stage.rglob("*") if not p.is_dir()}
if actual != expected or any((stage / p).is_symlink() for p in actual):
    sys.exit("Refusing an unexpected staged install file list")
' "$stage" "$system_module" "${files[@]}"

# Authenticate before stopping anything. This prompts on the user's terminal;
# no password is passed to the agent, a script variable, or a log.
sudo -v
unlocked || die 'The session locked during preparation. Unlock it and rerun.'

restart_needed=false
install_started=false
cleanup() {
    local status=$?
    trap - EXIT INT TERM
    if $restart_needed; then
        if (( status != 0 )) && $install_started; then
            printf 'Installation/verification failed; restoring the backed-up module.\n' >&2
            # An unknown state is not an empty instance list. Never overwrite
            # libraries unless every named shell is confirmed stopped.
            stop_unlocked_shell || {
                printf 'Cannot safely stop the shell (locked or state unavailable). Rollback deferred. Backup: %s\n' "$backup" >&2
                exit "$status"
            }
            for file in "${files[@]}"; do
                sudo -n install -m "$(stat -c %a "$backup/$file")" -- "$backup/$file" "$system_module/$file" || {
                    printf 'Rollback requires manual attention. Backup: %s\n' "$backup" >&2
                    exit 1
                }
            done
        fi
        caelestia shell -d || printf 'Could not relaunch the shell; run: caelestia shell -d\n' >&2
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Do not overwrite a shared library mapped by a running process.
unlocked || die 'The session is no longer unlocked; refusing to stop the shell.'
restart_needed=true
stop_unlocked_shell || die 'Could not confirm the unlocked shell stopped; no module files were changed.'
install_started=true
for file in "${files[@]}"; do
    sudo -n install -m "$(stat -c %a "$backup/$file")" -- "$stage$system_module/$file" "$system_module/$file"
done
caelestia shell -d

status=""
for ((attempt = 0; attempt < 50; attempt++)); do
    if status="$(caelestia shell lock renderRecoveryStatus 2>/dev/null)"; then
        break
    fi
    sleep 0.2
done
python3 -c 'import json,sys; s=json.loads(sys.argv[1]); sys.exit(0 if s.get("supported") and s.get("qtBuild")==s.get("qtRuntime") else 1)' "$status"
restart_needed=false
install_started=false
printf 'Native recovery loaded: %s\n' "$status"
if caelestia shell lock traceWake; then
    printf 'Wake tracing is armed. The next real sleep/wake test is still required.\n'
else
    printf 'Could not arm tracing. Before the next sleep test, run: caelestia shell lock traceWake\n' >&2
fi
