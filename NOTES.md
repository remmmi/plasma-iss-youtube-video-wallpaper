# Sen live stream as desktop wallpaper or screensaver

Status on 2026-10-27: **in service**, HLS relay + custom QML plugin approach (see INSTALL.md). The HTMLWallpaper approach described below was not implemented.

## Goal

Show the stream of https://www.sen.com/live (or a page offering the same experience) as the desktop wallpaper, below the icons. Variant considered along the way, not decided: use it as a screensaver.

## Guidelines

- Look for an existing tool first (GitHub or elsewhere): the goal is not to rewrite everything.
- If the live stream stutters, the stream delayed by one hour is fine.

## Machine

- Debian 12, KDE Plasma 5.27.5, X11 session, Qt 5.15.8.
- Three screens: HDMI-3 1920x1080 (primary), HDMI-2 1080x1920 (portrait), HDMI-1 1920x1080.
- NVIDIA GT 730 card (driver 470), i7-3770 CPU, 15 GB of RAM.
- Previous wallpaper on the three screens: `online.knowmad.shaderwallpaper`.
- Already installed: `qml-module-qtwebengine`, `qml-module-qtmultimedia`, gstreamer (good, bad, libav), vlc, ffmpeg, google-chrome, firefox, xvfb-run, kpackagetool5.
- Missing: mpv, yt-dlp, streamlink, xwinwrap, qmlscene. The yt-dlp of Debian 12 dates from 2023.03, too old for YouTube.

## The stream

- The Sen page embeds a YouTube live stream: id `fO9e9jnhYK8` (4K camera of the ISS).
- The id comes from `https://api.sen.com/content/public/live?clientId=WEB&cursor=&timezone=Europe%2FParis&clientVersion=2.8.0`, field `youtubeId`. To be checked again when resuming.
- Live stream in DVR mode: it is possible to go back in the stream. Qualities offered up to 2160p on the web page; yt-dlp only gets 1080p at most.

## Plugin first considered: HTMLWallpaper

- Repository: https://github.com/MarcelRichter-GitHub/HTMLWallpaper (LGPL-2.1), plugin id `de.unkn0wn.htmlwallpaper`.
- `master` and tags v2.3 to v2.5 target Plasma 6. Tag **v2.2** is the last one for Plasma 5.
- The plugin shows a URL in a `WebEngineView`. With the "Folder View" layout the icons stay on top and keep the focus.

## Test performed

Throwaway offscreen test with `xvfb-run` and `kpackagelauncherqml` (package of type `KPackage/GenericQML`), QtWebEngine 5.15.13 engine (Chromium 87), option `--disable-gpu`.

| Loading mode | Result |
|---|---|
| URL `youtube-nocookie.com/embed/<id>` given directly | Failure: "Error 153", YouTube refuses an embedded player without a host page |
| Player in a small page loaded with `loadHtml(html, "https://www.sen.com/")` | Plays correctly, muted, starts automatically |

Conclusion: the plugin as is does not work, `url:` has to be replaced by a `loadHtml` in `main.qml` (about ten lines).

Small page used for the test:

```html
<html><body style="margin:0;background:#000">
<iframe id="p" style="border:0;width:100vw;height:100vh" allow="autoplay"
  src="https://www.youtube-nocookie.com/embed/fO9e9jnhYK8?enablejsapi=1&autoplay=1&mute=1&controls=0"></iframe>
</body></html>
```

QML side: `settings.playbackRequiresUserGesture: false` and `Component.onCompleted: loadHtml(page, "https://www.sen.com/")`.

With `enablejsapi=1` the player can be driven with `postMessage` (state tracking, and going back in the DVR for the one hour delay). Going back itself was not tested.

## Not checked

- Real rendering in plasmashell and CPU load of the web approach: the web engine runs there without graphics acceleration, so with software decoding. 1080p should work, 4K should not.
- Plugin on the lock screen. Can be tested safely with `kscreenlocker_greet --testing`.

## Screensaver option

No ready made screensaver for a live stream. Options:

1. **Plasma lock screen with the same plugin** (recommended first). No new dependency, but it is a lock: password required after the grace period, and the screen power off has to be delayed.
2. **XScreenSaver + mpv + recent yt-dlp** (fallback). Hardware decoding possible, works without a password, but needs sudo, replaces the KDE lock, and yt-dlp has to be kept up to date.
3. XSecureLock and its `saver_mpv`: meant for local files, URL playback not confirmed.

Rejected: Smart Video Wallpaper (local files), Smart Video Wallpaper Reborn (Plasma 6), Wallpaper Engine plugin (requires Steam).

## Pending decisions

1. Screensaver: still open (the wallpaper is done).
