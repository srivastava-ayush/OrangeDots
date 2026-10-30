#!/usr/bin/env bash
# Compatibility entry point for existing external shortcuts. New binds use the
# canonical helper under hypr/scripts/, independent of the clone's location.
exec bash "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/hypr/scripts/toggle-refresh-rate.sh" "$@"
