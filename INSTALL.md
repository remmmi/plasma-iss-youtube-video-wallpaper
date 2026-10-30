# Installation en place (2026-10-27)

Approche : yt-dlp récupère l'URL HLS signée du direct YouTube `fO9e9jnhYK8`, ffmpeg la recopie sans réencodage vers un HLS local, un plugin de fond d'écran QML (QtMultimedia) lit ce HLS local.

## Composants

| Elément | Emplacement |
|---|---|
| yt-dlp 2026.10.26 (binaire officiel, somme SHA-256 vérifiée) | `~/.local/bin/yt-dlp` |
| Script de relais (source : `relay/iss-hls-relay`) | `~/.local/bin/iss-hls-relay` |
| Service relais | `~/.config/systemd/user/iss-hls-relay.service` |
| Service HTTP (python3 http.server, 127.0.0.1:8890) | `~/.config/systemd/user/iss-hls-http.service` |
| Segments HLS (tmpfs) | `/run/user/1000/iss-hls/` |
| Plugin `local.isslive.wallpaper` (source : `plugin/`) | `~/.local/share/plasma/wallpapers/local.isslive.wallpaper/` |
| Sauvegarde de la config Plasma avant modification | `backup/plasma-org.kde.plasma.desktop-appletsrc.20261027-163436` |

URL locale fixe : `http://127.0.0.1:8890/iss.m3u8`

## Fonctionnement

- Format choisi : itag 270, 1080p30 H.264, vidéo seule (`bv*[height<=1080][vcodec^=avc1]`). yt-dlp utilise node comme moteur JS.
- Le relais s'arrête 10 minutes avant l'expiration de l'URL signée (environ 6 h) ; `Restart=always` le relance avec une URL neuve. `append_list` conserve la numérotation des segments, le lecteur enchaîne sans erreur (testé par `systemctl --user restart iss-hls-relay`).
- Plugin : muet, reconnexion 5 s après erreur, chien de garde qui relance si la position ne bouge plus pendant 30 s. Pas de pause automatique (retirée à la demande : les écrans doivent rester synchronisés).
- Synchronisation : `SyncBus.qml` est un singleton QML partagé par les trois fonds dans plasmashell. Toute relance (démarrage, erreur, flux figé) est regroupée et appliquée à tous les lecteurs au même instant, qui repartent donc sur le même segment.
- Mode étalé physique : chaque écran inscrit dans SyncBus son rectangle en mm (taille issue de l'EDID via Qt, position automatique = disposition X11 x 0,3115 mm/px, ou saisie à la main). La vidéo couvre le rectangle englobant, mise à l'échelle de chaque écran : un mm reste un mm d'un écran à l'autre.
- Options dans Configurer le bureau et le fond d'écran, par écran : disposition (image entière / étalée), cadrage (bandes noires / rogné / étiré), position physique (automatique ou bord gauche et bord haut en mm).
- Ecrans : HDMI-3 HP V270 et HDMI-2 iiyama PLX2783H (27 pouces, 598x336 mm), HDMI-1 BenQ G2250 (21,5 pouces, 477x268 mm).

## Pièges

- plasmashell garde le QML en cache : après `kpackagetool5 -u`, basculer de plugin ne suffit pas, il faut redémarrer plasmashell. Le faire détaché de tout terminal : `kquitapp5 plasmashell; setsid -f plasmashell >/dev/null 2>&1`. Lancé depuis un terminal ou une session Claude Code, il meurt avec elle.
- Les `console.warn` du plugin ne sont visibles que si la sortie de plasmashell est redirigée vers un fichier au lancement.
- Qualité : la source plafonne à 1080p (pas de 4K proposée le 2026-10-27). En mode étalé sur 1,41 m, l'image est agrandie environ 2,4 fois, d'où un aspect pixellisé.

## Mesures

- Décodage logiciel (gstreamer libav), plasmashell autour de 26 % d'un coeur avec un seul écran visible (mesure faite avec la pause automatique, à refaire avec trois décodages).
- Trois écrans en mode étalé : plasmashell autour de 128 % d'un coeur (trois décodages logiciels).
- Décodage NVIDIA testé le 2026-10-27 (lecteur QML seul, hors plasmashell) : `GST_PLUGIN_FEATURE_RANK=nvh264dec:MAX` fait bien choisir nvh264dec, mais la charge passe de 30 % à 58 % d'un coeur par flux. Le rendu vidéo de QtMultimedia 5 recopie chaque image de la carte vers la mémoire puis la renvoie à la carte, ce qui coûte plus que le décodage logiciel. Abandonné.
- Deuxième essai le même jour avec `QT_GSTREAMER_USE_OPENGL_PLUGIN=1` (Qt Multimedia compilé avec gstreamer-gl, chemin GLMemory) + nvh264dec : la lecture passe par glupload, 25 % d'un coeur contre 27-28 % en logiciel, et un lancement sur deux échoue (pas de fenêtre). Gain négligeable, instable : abandonné.

## Mise à jour

- Plugin : `kpackagetool5 -t Plasma/Wallpaper -u plugin`, puis réappliquer le fond ou redémarrer plasmashell.
- yt-dlp : `~/.local/bin/yt-dlp -U`.
- Journal du relais : `journalctl --user -u iss-hls-relay -f`.

## Retour arrière

```sh
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var ds = desktops();
for (var i = 0; i < ds.length; i++) { ds[i].wallpaperPlugin = "online.knowmad.shaderwallpaper"; }'
systemctl --user disable --now iss-hls-relay iss-hls-http
```

Les réglages du shader sont conservés dans la config Plasma. En dernier recours : arrêter plasmashell, recopier la sauvegarde de `backup/` sur `~/.config/plasma-org.kde.plasma.desktop-appletsrc`, relancer plasmashell.

Désinstallation complète : `kpackagetool5 -t Plasma/Wallpaper -r local.isslive.wallpaper`, supprimer les deux fichiers .service, `~/.local/bin/iss-hls-relay` et `~/.local/bin/yt-dlp`.

## Disposition des écrans (2026-10-27)

Objectif : une fenêtre étirée sur deux écrans a la même taille et la même hauteur physiques des deux côtés.

- Le BenQ 21,5 pouces a des pixels de 0,248 mm contre 0,311 mm sur les deux 27 pouces. Il travaille désormais en 1536x864 logiques agrandis en 1920x1080 par la carte (ViewPortIn), soit 0,31 mm par pixel logique.
- Décalages verticaux calés avec la mire `mire.py` (lignes numérotées aux mêmes coordonnées sur tous les écrans, photo des jonctions) : HP inchangé à +0+653, BenQ remonté à +3000+866.
- Calage final à l'oeil depuis le poste avec `calage.py` (mire + fenêtre de boutons) : BenQ en 1472x828 logiques, soit environ 4 % plus grand que le calcul théorique (1536x864), pour compenser son retrait sur le bureau. Résultat dans `calage-resultat.txt`.
- MetaMode appliqué :
  `DPY-2: nvidia-auto-select @1080x1920 +1920+0 {ViewPortIn=1080x1920, ViewPortOut=1920x1080+0+0, Rotation=90}, DPY-1: nvidia-auto-select @1472x828 +3000+866 {ViewPortIn=1472x828, ViewPortOut=1920x1080+0+0}, DPY-3: nvidia-auto-select @1920x1080 +0+653 {ViewPortIn=1920x1080, ViewPortOut=1920x1080+0+0}`
- Sauvegardes avant modification : `backup/display-*` (xrandr, kscreen, kwinrc, xorg.conf, nvidia-settings-rc, MetaMode d'origine). Retour arrière immédiat : `backup/rollback-affichage.sh`.
- Sur les photos rapprochées, l'écran le plus éloigné de l'objectif paraît plus petit (perspective) : ne juger l'échelle que sur une photo prise de loin et de face.
- Permanent depuis le 2026-10-27 : ligne `metamodes` de `/etc/X11/xorg.conf` modifiée par `apply-xorg-metamodes.sh` (seul HDMI-1 change : +3000+866 et ViewPortIn=1472x828). Sauvegarde du fichier d'origine : `/etc/X11/xorg.conf.avant-wallpaper-video.20261027-171456` (la sauvegarde de 17:20 contient l'étape intermédiaire 1536x864). Retour arrière : `sudo cp -p` de cette sauvegarde vers `/etc/X11/xorg.conf`, puis reconnexion.
- Point à surveiller : KScreen garde sa propre copie de la disposition (`~/.local/share/kscreen/335842e5...`, BenQ en mode 1920x1080 sans mise à l'échelle). Un `xrandr --mode` sur le BenQ échoue (BadMatch) et ajoute une transformation parasite : si KScreen réapplique sa copie à l'ouverture de session, la mise à l'échelle peut sauter. Correctif immédiat : relancer le `nvidia-settings --assign CurrentMetaMode=...` ci-dessus.

## Décodage unique (module C++ local.isslive.shared, 2026-10-27)

- Source : `shared-player/` (qmake). Un seul QMediaPlayer par processus plasmashell ; une surface vidéo `FanoutSurface` redistribue chaque image (QVideoFrame partagée, sans copie) aux VideoOutput des trois écrans. La reconnexion (5 s) et le chien de garde (30 s) sont dans `hub.cpp`. Synchro intrinsèque : les trois écrans affichent la même image.
- QML : `SharedVideoSource { url: ... }` puis `VideoOutput { source: ... }`. `SyncBus.qml` ne sert plus qu'au calcul de la toile physique du mode étalé.
- Paquets installés pour compiler : qtmultimedia5-dev, qtdeclarative5-dev, qtbase5-dev.
- Compilation et installation : `cd shared-player && qmake sharedplayer.pro -o build.mk && make -f build.mk && make -f build.mk install` (va dans `~/.local/lib/qml/local/isslive/shared/`). A refaire après une mise à jour de Qt.
- plasmashell doit trouver ce dossier : `shared-player/isslive-qml.sh` copié dans `~/.config/plasma-workspace/env/` (ajoute `~/.local/lib/qml` à `QML2_IMPORT_PATH` à l'ouverture de session). Sans lui, le fond affiche une erreur "module local.isslive.shared is not installed".
- Mesure (fenêtre de test, trois VideoOutput) : 31 % d'un coeur pour les trois écrans, contre environ 28 % par écran avant.
- Mesure réelle dans plasmashell, trois écrans en mode étalé : 58 % d'un coeur au total, contre 128 % avec trois lecteurs (le reste est le rendu agrandi sur 3 écrans et le bureau lui-même).
- Profil perf de plasmashell (2026-10-27, 15 s, linux-perf installé) : charge totale 27-28 % d'un coeur à ce moment (elle varie avec le débit du flux, donc avec l'image). Répartition des échantillons :
  - 78 % threads de décodage : libavcodec 55 % (décodage proprement dit), memcpy 12 % (copie de chaque image décodée vers un tampon GStreamer), le reste en défauts de page ;
  - 11 % thread principal : surtout le fork de plasmashell (environ 900 Mo) toutes les 4 s par le widget org.kde.resourcesMonitor-fork, qui lance awk pour lire /proc/net/dev. Ce fork rend aussi les pages copy-on-write, d'où des défauts de page dans le décodeur ;
  - 9,5 % thread de rendu : envoi des textures au pilote NVIDIA.
  - Le code du module n'apparaît pas. Une réécriture en Rust avec la même API ne ferait rien gagner.
- La note précédente (29 % dans le thread principal, d'après top -H) était fausse : perf ne la confirme pas.
