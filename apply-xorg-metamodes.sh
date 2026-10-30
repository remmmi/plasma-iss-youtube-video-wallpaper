#!/bin/bash
# Makes the screen layout aligned on 2026-10-27 permanent (see INSTALL.md).
# Run with sudo. Backs up xorg.conf, replaces the value of the metamodes
# option and shows the diff. Takes effect at the next session.
set -euo pipefail

CONF=/etc/X11/xorg.conf
BACKUP="$CONF.before-wallpaper-video.$(date +%Y%m%d-%H%M%S)"
NEW='HDMI-2: nvidia-auto-select +1920+0 {rotation=left}, HDMI-1: nvidia-auto-select +3000+866 {ViewPortIn=1472x828, ViewPortOut=1920x1080+0+0}, HDMI-3: nvidia-auto-select +0+653'

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo" >&2
    exit 1
fi

count=$(grep -ciE '^[[:space:]]*Option[[:space:]]+"metamodes"' "$CONF" || true)
if [ "$count" != "1" ]; then
    echo "Expected a single Option \"metamodes\" line in $CONF, found: $count. Nothing changed." >&2
    grep -niE 'metamodes' "$CONF" >&2 || true
    exit 1
fi

cp -p "$CONF" "$BACKUP"
sed -i -E "s|^([[:space:]]*Option[[:space:]]+\"metamodes\"[[:space:]]+)\".*\"|\1\"$NEW\"|I" "$CONF"

echo "Backup: $BACKUP"
echo "Diff:"
diff "$BACKUP" "$CONF" || true
echo
echo "Rollback: sudo cp -p $BACKUP $CONF"
