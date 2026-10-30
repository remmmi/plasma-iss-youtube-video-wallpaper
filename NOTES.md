# Flux live Sen en fond de bureau ou économiseur d'écran

Etat au 2026-10-27 : **en service**, approche relais HLS + plugin QML maison (voir INSTALL.md). L'approche HTMLWallpaper décrite plus bas n'a pas été mise en oeuvre.

## Objectif

Afficher le flux de https://www.sen.com/live (ou une page offrant la même expérience) en fond de bureau, sous les icônes. Variante envisagée en cours de route, non tranchée : l'utiliser comme économiseur d'écran.

## Consignes

- Chercher d'abord un outil existant (GitHub ou autre) : le but n'est pas de tout recoder.
- Si le direct saccade, le flux décalé d'une heure convient.

## Machine

- Debian 12, KDE Plasma 5.27.5, session X11, Qt 5.15.8.
- Trois écrans : HDMI-3 1920x1080 (principal), HDMI-2 1080x1920 (portrait), HDMI-1 1920x1080.
- Carte NVIDIA GT 730 (pilote 470), processeur i7-3770, 15 Go de RAM.
- Fond actuel sur les trois écrans : `online.knowmad.shaderwallpaper`.
- Déjà installés : `qml-module-qtwebengine`, `qml-module-qtmultimedia`, gstreamer (good, bad, libav), vlc, ffmpeg, google-chrome, firefox, xvfb-run, kpackagetool5.
- Absents : mpv, yt-dlp, streamlink, xwinwrap, qmlscene. Le yt-dlp de Debian 12 date de 2023.03, trop ancien pour YouTube.

## Le flux

- La page Sen embarque un direct YouTube : id `fO9e9jnhYK8` (caméra 4K de l'ISS).
- L'id est fourni par `https://api.sen.com/content/public/live?clientId=WEB&cursor=&timezone=Europe%2FParis&clientVersion=2.8.0`, champ `youtubeId`. A revérifier à la reprise.
- Direct en mode DVR : on peut reculer dans le flux. Qualités proposées jusqu'en 2160p.

## Plugin retenu : HTMLWallpaper

- Dépôt : https://github.com/MarcelRichter-GitHub/HTMLWallpaper (LGPL-2.1), id du plugin `de.unkn0wn.htmlwallpaper`.
- `master` et les tags v2.3 à v2.5 visent Plasma 6. Le tag **v2.2** est le dernier pour Plasma 5.
- Le plugin affiche une URL dans un `WebEngineView`. Avec la disposition "Vue de dossiers", les icônes restent au-dessus et gardent le focus.

## Essai réalisé

Essai jetable hors écran avec `xvfb-run` et `kpackagelauncherqml` (paquet de type `KPackage/GenericQML`), moteur QtWebEngine 5.15.13 (Chromium 87), option `--disable-gpu`.

| Mode de chargement | Résultat |
|---|---|
| URL `youtube-nocookie.com/embed/<id>` donnée directement | Echec : "Erreur 153", YouTube refuse un lecteur embarqué sans page hôte |
| Lecteur dans une mini-page chargée par `loadHtml(html, "https://www.sen.com/")` | Lecture correcte, muette, démarrage automatique |

Conclusion : le plugin tel quel ne suffit pas, il faut remplacer `url:` par un `loadHtml` dans `main.qml` (une dizaine de lignes).

Mini-page utilisée pour l'essai :

```html
<html><body style="margin:0;background:#000">
<iframe id="p" style="border:0;width:100vw;height:100vh" allow="autoplay"
  src="https://www.youtube-nocookie.com/embed/fO9e9jnhYK8?enablejsapi=1&autoplay=1&mute=1&controls=0"></iframe>
</body></html>
```

Côté QML : `settings.playbackRequiresUserGesture: false` et `Component.onCompleted: loadHtml(page, "https://www.sen.com/")`.

Avec `enablejsapi=1`, le lecteur se pilote par `postMessage` (suivi de l'état, et recul dans le DVR pour le décalage d'une heure). Le recul lui-même n'a pas été testé.

## Points non vérifiés

- Rendu réel dans plasmashell et charge processeur : le moteur web y tourne sans accélération graphique, donc décodage logiciel. Le 1080p devrait passer, la 4K non.
- Fonctionnement du plugin sur l'écran de verrouillage. A tester sans risque avec `kscreenlocker_greet --testing`.

## Piste économiseur d'écran

Aucun économiseur clé en main pour un flux en direct. Options :

1. **Ecran de verrouillage Plasma avec le même plugin** (recommandé en premier). Pas de dépendance nouvelle, mais c'est un verrouillage : mot de passe requis après le délai de grâce, et il faut repousser l'extinction des écrans.
2. **XScreenSaver + mpv + yt-dlp récent** (repli). Décodage matériel possible, fonctionne sans mot de passe, mais demande sudo, remplace le verrouillage KDE, et yt-dlp est à tenir à jour.
3. XSecureLock et son `saver_mpv` : prévu pour des fichiers locaux, lecture d'URL non confirmée.

Ecartés : Smart Video Wallpaper (fichiers locaux), Smart Video Wallpaper Reborn (Plasma 6), plugin Wallpaper Engine (exige Steam).

## Décisions en attente

1. Fond de bureau, économiseur, ou les deux.
2. Quels écrans ; pour l'écran portrait, vidéo rognée ou en bandeau avec du noir.
3. Feu vert sur l'approche : HTMLWallpaper v2.2 corrigé, option "retard en minutes", installation par `kpackagetool5` dans le dossier utilisateur, sans sudo.

## Etapes prévues une fois validé

1. Récupérer HTMLWallpaper v2.2 dans ce dossier.
2. Corriger `main.qml` (mini-page, lecteur muet plein cadre) et ajouter les options id du direct et retard.
3. Installer avec `kpackagetool5 -t Plasma/Wallpaper -i package`.
4. Appliquer aux écrans choisis, vérifier par capture d'écran, mesurer la charge processeur.
5. Retour arrière : remettre `online.knowmad.shaderwallpaper` dans les réglages du fond d'écran.
