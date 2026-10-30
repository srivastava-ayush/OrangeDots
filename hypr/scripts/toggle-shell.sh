#!/usr/bin/env bash
# Toggle the Caelestia shell without affecting other Quickshell instances.

if pgrep -f '(^|/)qs -c caelestia -n( -d)?$' >/dev/null; then
    caelestia shell -k
else
    caelestia shell -d
fi


