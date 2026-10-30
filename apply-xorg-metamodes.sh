#!/bin/bash
# Rend permanente la disposition d'ecrans calee le 2026-10-27 (voir INSTALL.md).
# A lancer avec sudo. Sauvegarde xorg.conf, remplace la valeur de l'option
# metamodes, affiche la difference. Prise en compte a la prochaine session.
set -euo pipefail

CONF=/etc/X11/xorg.conf
BACKUP="$CONF.avant-wallpaper-video.$(date +%Y%m%d-%H%M%S)"
NEW='HDMI-2: nvidia-auto-select +1920+0 {rotation=left}, HDMI-1: nvidia-auto-select +3000+866 {ViewPortIn=1472x828, ViewPortOut=1920x1080+0+0}, HDMI-3: nvidia-auto-select +0+653'

if [ "$(id -u)" -ne 0 ]; then
    echo "A lancer avec sudo" >&2
    exit 1
fi

count=$(grep -ciE '^[[:space:]]*Option[[:space:]]+"metamodes"' "$CONF" || true)
if [ "$count" != "1" ]; then
    echo "Attendu une seule ligne Option \"metamodes\" dans $CONF, trouve : $count. Rien n'est modifie." >&2
    grep -niE 'metamodes' "$CONF" >&2 || true
    exit 1
fi

cp -p "$CONF" "$BACKUP"
sed -i -E "s|^([[:space:]]*Option[[:space:]]+\"metamodes\"[[:space:]]+)\".*\"|\1\"$NEW\"|I" "$CONF"

echo "Sauvegarde : $BACKUP"
echo "Difference :"
diff "$BACKUP" "$CONF" || true
echo
echo "Retour arriere : sudo cp -p $BACKUP $CONF"
