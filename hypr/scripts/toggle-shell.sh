#!/usr/bin/env bash
# Toggle the Orange OS shell without affecting other Quickshell instances.

if pgrep -f '(^|/)qs -c caelestia -n( -d)?$' >/dev/null; then
    orangeos shell -k
else
    orangeos shell -d
fi


