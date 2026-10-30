# Fond d'écran vidéo ISS en direct pour KDE Plasma 5

Affiche le direct YouTube de la caméra de l'ISS (chaîne Sen) en fond de bureau sous KDE Plasma 5.27, session X11, sur un ou plusieurs écrans.

## Composants

- `relay/` : relais local. `yt-dlp` récupère l'adresse du direct, `ffmpeg` la recopie sans réencodage en HLS dans `$XDG_RUNTIME_DIR/iss-hls`, servi sur `http://127.0.0.1:8890/iss.m3u8`. Deux services `systemd --user`, relance automatique à l'expiration de l'adresse YouTube.
- `plugin/` : plugin de fond d'écran Plasma `local.isslive.wallpaper` (QML). Mode image entière par écran, ou mode étalé sur tous les écrans en tenant compte de leur taille physique.
- `shared-player/` : module QML en C++ (`local.isslive.shared`). Un seul lecteur et un seul décodage pour tous les écrans, images identiques donc synchronisées. Divise par deux environ la charge du processeur avec trois écrans.
- `calage.py`, `mire.py`, `apply-xorg-metamodes.sh` : outils de calage des écrans avec le pilote NVIDIA (propres à la machine d'origine, à adapter).

## Prérequis

Debian 12 ou équivalent, Plasma 5.27, Qt 5.15, `ffmpeg`, `node`, un `yt-dlp` récent, GStreamer avec `gstreamer1.0-libav`. Pour compiler le module : `qtbase5-dev`, `qtdeclarative5-dev`, `qtmultimedia5-dev`.

## Installation

Voir `INSTALL.md` : installation pas à pas, fonctionnement, mesures de charge, pièges rencontrés et retour arrière. `NOTES.md` retrace les pistes étudiées.

## Licence

GPL-3.0 ou ultérieure, voir `LICENSE`. Le flux vidéo appartient à Sen ; ce projet ne fait que le lire.
