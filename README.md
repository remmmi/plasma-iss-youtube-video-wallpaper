# Live ISS video wallpaper for KDE Plasma 5

Shows the live YouTube feed of the ISS camera (Sen channel) as the desktop wallpaper on KDE Plasma 5.27, X11 session, on one or several screens.

## Components

- `relay/`: local relay. `yt-dlp` gets the live stream address, `ffmpeg` copies it without re-encoding to HLS in `$XDG_RUNTIME_DIR/iss-hls`, served at `http://127.0.0.1:8890/iss.m3u8`. Two `systemd --user` services, restarted automatically when the YouTube address expires.
- `plugin/`: Plasma wallpaper plugin `local.isslive.wallpaper` (QML). Whole picture on each screen, or one picture spanned across all screens taking their physical size into account. Optional deblocking filter run by the graphics card.
- `shared-player/`: C++ QML module (`local.isslive.shared`). A single player and a single decode for all screens, identical frames so the screens stay in sync. Roughly halves the CPU load with three screens.
- `align.py`, `test-pattern.py`, `apply-xorg-metamodes.sh`: screen alignment tools for the NVIDIA driver (specific to the original machine, to be adapted).

## Requirements

Debian 12 or equivalent, Plasma 5.27, Qt 5.15, `ffmpeg`, `node`, a recent `yt-dlp`, GStreamer with `gstreamer1.0-libav`. To build the module: `qtbase5-dev`, `qtdeclarative5-dev`, `qtmultimedia5-dev`.

## Installation

See `INSTALL.md`: step by step installation, how it works, CPU measurements, pitfalls and rollback. `NOTES.md` records the approaches that were studied.

## License

GPL-3.0 or later, see `LICENSE`. The video feed belongs to Sen; this project only plays it.
