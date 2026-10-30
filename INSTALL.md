# Current installation (2026-10-27)

Approach: yt-dlp gets the signed HLS URL of the YouTube live stream `fO9e9jnhYK8`, ffmpeg copies it without re-encoding to a local HLS playlist, and a QML wallpaper plugin (QtMultimedia) plays that local playlist.

## Components

| Item | Location |
|---|---|
| yt-dlp 2026.10.26 (official binary, SHA-256 checked) | `~/.local/bin/yt-dlp` |
| Relay script (source: `relay/iss-hls-relay`) | `~/.local/bin/iss-hls-relay` |
| Relay service | `~/.config/systemd/user/iss-hls-relay.service` |
| HTTP service (python3 http.server, 127.0.0.1:8890) | `~/.config/systemd/user/iss-hls-http.service` |
| HLS segments (tmpfs) | `/run/user/1000/iss-hls/` |
| Plugin `local.isslive.wallpaper` (source: `plugin/`) | `~/.local/share/plasma/wallpapers/local.isslive.wallpaper/` |
| Backup of the Plasma config before any change | `backup/plasma-org.kde.plasma.desktop-appletsrc.20261027-163436` |

Fixed local URL: `http://127.0.0.1:8890/iss.m3u8`

## How it works

- Selected format: itag 270, 1080p30 H.264, video only (`bv*[height<=1080][vcodec^=avc1]`). yt-dlp uses node as its JS engine.
- The relay stops 10 minutes before the signed URL expires (about 6 h); `Restart=always` starts it again with a fresh URL. `append_list` keeps the segment numbering, so the player goes on without error (tested with `systemctl --user restart iss-hls-relay`).
- Plugin: muted, reconnects 5 s after an error, watchdog that reloads when the position has not moved for 30 s. No automatic pause (removed on request: the screens must stay in sync).
- Physical spanned mode: each screen registers its rectangle in mm in `SyncBus.qml` (size from the EDID through Qt, automatic position = X11 layout x 0.3115 mm/px, or entered by hand). The video covers the enclosing rectangle, scaled for each screen: a mm stays a mm from one screen to the next.
- Options in Configure Desktop and Wallpaper, per screen: layout (whole picture / spanned), fill mode (black bars / cropped / stretched), physical position (automatic, or left and top edges in mm), deblocking filter and its strength.
- Screens: HDMI-3 HP V270 and HDMI-2 iiyama PLX2783H (27 inches, 598x336 mm), HDMI-1 BenQ G2250 (21.5 inches, 477x268 mm).

## Pitfalls

- plasmashell caches the QML: after `kpackagetool5 -u`, switching plugins is not enough, plasmashell has to be restarted. Do it detached from any terminal: `kquitapp5 plasmashell; QML2_IMPORT_PATH=$HOME/.local/lib/qml setsid -f plasmashell >/dev/null 2>&1`. When started from a terminal or a Claude Code session, it dies with it.
- The plugin's `console.warn` messages are only visible if the output of plasmashell is redirected to a file when it is started.
- Quality: the source is capped at 1080p (no 4K offered on 2026-10-27). In spanned mode across 1.41 m the picture is enlarged about 2.4 times, hence a pixelated look.

## Measurements

- Software decoding (gstreamer libav), plasmashell around 26 % of a core with a single visible screen (measured with the automatic pause).
- Three screens in spanned mode with three players: plasmashell around 128 % of a core (three software decodes).
- NVIDIA decoding tested on 2026-10-27 (standalone QML player, outside plasmashell): `GST_PLUGIN_FEATURE_RANK=nvh264dec:MAX` does select nvh264dec, but the load goes from 30 % to 58 % of a core per stream. The QtMultimedia 5 video renderer copies every frame from the card to system memory and then back to the card, which costs more than software decoding. Dropped.
- Second attempt the same day with `QT_GSTREAMER_USE_OPENGL_PLUGIN=1` (Qt Multimedia built with gstreamer-gl, GLMemory path) + nvh264dec: playback goes through glupload, 25 % of a core against 27-28 % in software, and one start out of two fails (no window). Negligible gain, unstable: dropped.

## Updates

- Plugin: `kpackagetool5 -t Plasma/Wallpaper -u plugin`, then restart plasmashell.
- yt-dlp: `~/.local/bin/yt-dlp -U`.
- Relay log: `journalctl --user -u iss-hls-relay -f`.

## Rollback

```sh
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var ds = desktops();
for (var i = 0; i < ds.length; i++) { ds[i].wallpaperPlugin = "online.knowmad.shaderwallpaper"; }'
systemctl --user disable --now iss-hls-relay iss-hls-http
```

The shader settings are kept in the Plasma config. As a last resort: stop plasmashell, copy the backup from `backup/` over `~/.config/plasma-org.kde.plasma.desktop-appletsrc`, start plasmashell again.

Full removal: `kpackagetool5 -t Plasma/Wallpaper -r local.isslive.wallpaper`, delete both .service files, `~/.local/bin/iss-hls-relay` and `~/.local/bin/yt-dlp`.

## Screen layout (2026-10-27)

Goal: a window stretched across two screens has the same physical size and height on both sides.

- The 21.5 inch BenQ has 0.248 mm pixels against 0.311 mm on the two 27 inch screens. It now works in 1536x864 logical pixels enlarged to 1920x1080 by the card (ViewPortIn), i.e. 0.31 mm per logical pixel.
- Vertical offsets aligned with the test pattern `test-pattern.py` (numbered lines at the same coordinates on all screens, photo of the joins): HP unchanged at +0+653, BenQ moved up to +3000+866.
- Final alignment by eye from the desk with `align.py` (test pattern + button window): BenQ at 1472x828 logical pixels, about 4 % bigger than the theoretical value (1536x864), to make up for its position further back on the desk. Result in `align-result.txt`.
- Applied MetaMode:
  `DPY-2: nvidia-auto-select @1080x1920 +1920+0 {ViewPortIn=1080x1920, ViewPortOut=1920x1080+0+0, Rotation=90}, DPY-1: nvidia-auto-select @1472x828 +3000+866 {ViewPortIn=1472x828, ViewPortOut=1920x1080+0+0}, DPY-3: nvidia-auto-select @1920x1080 +0+653 {ViewPortIn=1920x1080, ViewPortOut=1920x1080+0+0}`
- Backups before the change: `backup/display-*` (xrandr, kscreen, kwinrc, xorg.conf, nvidia-settings-rc, original MetaMode). Immediate rollback: `backup/rollback-affichage.sh`.
- On close-up photos the screen furthest from the lens looks smaller (perspective): only judge the scale on a photo taken from a distance and straight on.
- Permanent since 2026-10-27: `metamodes` line of `/etc/X11/xorg.conf` changed by `apply-xorg-metamodes.sh` (only HDMI-1 changes: +3000+866 and ViewPortIn=1472x828). Backup of the original file: `/etc/X11/xorg.conf.avant-wallpaper-video.20261027-171456` (the 17:20 backup holds the intermediate 1536x864 step). Rollback: `sudo cp -p` of that backup to `/etc/X11/xorg.conf`, then log in again.
- To watch: KScreen keeps its own copy of the layout (`~/.local/share/kscreen/335842e5...`, BenQ in 1920x1080 mode without scaling). An `xrandr --mode` on the BenQ fails (BadMatch) and adds a stray transform: if KScreen reapplies its copy when the session starts, the scaling may be lost. Immediate fix: run the `nvidia-settings --assign CurrentMetaMode=...` above again.

## Single decode (C++ module local.isslive.shared, 2026-10-27)

- Source: `shared-player/` (qmake). A single QMediaPlayer per plasmashell process; a `FanoutSurface` video surface forwards every frame (shared QVideoFrame, no copy) to the VideoOutput items of the three screens. Reconnection (5 s) and watchdog (30 s) live in `hub.cpp`. Built-in sync: the three screens show the same frame.
- QML: `SharedVideoSource { url: ... }` then `VideoOutput { source: ... }`. `SyncBus.qml` is now only used to compute the physical canvas of the spanned mode.
- Packages installed to build it: qtmultimedia5-dev, qtdeclarative5-dev, qtbase5-dev.
- Build and install: `cd shared-player && qmake sharedplayer.pro -o build.mk && make -f build.mk && make -f build.mk install` (goes to `~/.local/lib/qml/local/isslive/shared/`). To be redone after a Qt update. While plasmashell is running, remove the installed `.so` before installing the new one, so that the running process keeps the old file instead of seeing it overwritten.
- plasmashell must find that folder: `shared-player/isslive-qml.sh` copied into `~/.config/plasma-workspace/env/` (adds `~/.local/lib/qml` to `QML2_IMPORT_PATH` when the session starts). Without it, the wallpaper shows the error "module local.isslive.shared is not installed".
- Measurement (test window, three VideoOutput items): 31 % of a core for the three screens, against about 28 % per screen before.
- Real measurement in plasmashell, three screens in spanned mode: 58 % of a core in total, against 128 % with three players.
- perf profile of plasmashell (2026-10-27, 15 s, linux-perf installed then removed): total load 27-28 % of a core at that time (it varies with the stream bitrate, hence with the picture). Split of the samples:
  - 78 % decoding threads: libavcodec 55 % (the decoding itself), memcpy 12 % (copy of every decoded frame to a GStreamer buffer), the rest in page faults;
  - 11 % main thread: mostly the fork of plasmashell (about 900 MB) every 4 s by the org.kde.resourcesMonitor-fork widget, which runs awk to read /proc/net/dev. That fork also makes the pages copy-on-write, hence page faults in the decoder;
  - 9.5 % render thread: texture uploads to the NVIDIA driver.
  - The module code does not show up. A Rust rewrite using the same API would gain nothing.

## Deblocking filter (2026-10-30)

- `plugin/contents/ui/Deblock.qml` and `deblock.frag`: GLSL shader applied to the visible part of the VideoOutput through a ShaderEffectSource, so the work runs on the graphics card, not the CPU.
- Bilateral smoothing over 8 neighbours at about 0.75 of a video block (8 source pixels, i.e. about 19 screen pixels in spanned mode): only neighbours whose colour is close count, so blocks and banding are smoothed while real edges stay sharp. A dither of 1.5 levels breaks the remaining steps.
- Options `Deblock` (on by default) and `DeblockStrength` (0 to 100, default 70).
- Offscreen test (xvfb, unfiltered and filtered halves side by side): at strength 50 the difference is almost invisible (PSNR 53 dB between the halves); at 100 the blotchy cloud texture is smoothed while the water and cloud edges stay sharp (PSNR 43 dB).
- CPU cost not measured yet: to be measured with the filter switched on and off alternately during daylight on the stream.
- The CPU usage widget showing about 90 % on this machine is wrong: ksystemstats `cpu/all/usage` includes iowait, and on kernel 6.1 the idle io_uring threads of Ghostty are counted as iowait (12 threads, 66 % wait). Real load: about 12 % user + system.
