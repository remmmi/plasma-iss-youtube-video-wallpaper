#!/usr/bin/env python3
# Aligns the BenQ screen (HDMI-1 / DPY-1) by eye, test pattern on all three screens.
#   Up / Down       : moves the BenQ by 10 pixels
#   + / -           : enlarges / shrinks the BenQ content
#   Enter           : keeps the setting and writes it to align-result.txt
#   Escape          : restores the initial setting and quits
import re
import subprocess
import tkinter as tk
from pathlib import Path

STEP = 20
PANEL_BAND = 220
RESULT = Path(__file__).with_name("align-result.txt")


def metamode(width, y):
    height = round(width * 9 / 16)
    return ("DPY-2: nvidia-auto-select @1080x1920 +1920+0 {ViewPortIn=1080x1920, "
            "ViewPortOut=1920x1080+0+0, Rotation=90}, "
            f"DPY-1: nvidia-auto-select @{width}x{height} +3000+{y} "
            f"{{ViewPortIn={width}x{height}, ViewPortOut=1920x1080+0+0}}, "
            "DPY-3: nvidia-auto-select @1920x1080 +0+653 {ViewPortIn=1920x1080, "
            "ViewPortOut=1920x1080+0+0}")


def apply(width, y):
    subprocess.run(["nvidia-settings", "--assign", f"CurrentMetaMode={metamode(width, y)}"],
                   capture_output=True)


def screens():
    out = subprocess.run(["xrandr", "--query"], capture_output=True, text=True).stdout
    found = []
    for m in re.finditer(r"^(\S+) connected (?:primary )?(\d+)x(\d+)\+(\d+)\+(\d+)", out, re.M):
        found.append((m.group(1), *map(int, m.groups()[1:])))
    return found


def current():
    for name, w, h, x, y in screens():
        if name == "HDMI-1":
            return w, y
    return 1536, 866


class Aligner:
    def __init__(self):
        self.start = current()
        self.width, self.y = self.start
        self.root = tk.Tk()
        self.root.withdraw()
        self.windows = []
        self.draw()

    def draw(self):
        for win in self.windows:
            win.destroy()
        self.windows = []
        colors = ["#ff4040", "#40ff40", "#4080ff", "#ffff40", "#ff40ff"]
        for name, w, h, x, y in screens():
            if name == "HDMI-3":
                # Free band at the bottom of the HP screen for the control window
                h -= PANEL_BAND
            win = tk.Toplevel(self.root)
            win.overrideredirect(True)
            win.geometry(f"{w}x{h}+{x}+{y}")
            win.attributes("-topmost", True)
            c = tk.Canvas(win, width=w, height=h, bg="black", highlightthickness=0)
            c.pack()
            first = ((y + STEP - 1) // STEP) * STEP
            for gy in range(first, y + h, STEP):
                ly = gy - y
                if gy % 100 == 0:
                    col = colors[(gy // 100) % 5]
                    c.create_line(0, ly, w, ly, fill=col, width=3)
                    for lx in range(40, w, 400):
                        c.create_text(lx, ly - 4, text=str(gy), fill=col, anchor="sw",
                                      font=("DejaVu Sans", 22, "bold"))
                else:
                    c.create_line(0, ly, w, ly, fill="#808080", width=1)
            if name == "HDMI-1":
                text = (f"BenQ  {self.width}x{round(self.width * 9 / 16)}  +3000+{self.y}\n"
                        "Adjust in the BenQ alignment window")
                c.create_text(w // 2, h // 2, text=text, fill="white", justify="center",
                              font=("DejaVu Sans", 20, "bold"))
            self.windows.append(win)
        self.control()

    def control(self):
        # Regular (decorated) window: the only one that can get keyboard input
        if getattr(self, "panel", None) is not None:
            self.panel.destroy()
        p = tk.Toplevel(self.root)
        self.panel = p
        p.title("BenQ alignment")
        p.geometry(f"+700+{653 + 1080 - PANEL_BAND + 20}")
        p.attributes("-topmost", True)
        tk.Label(p, text=f"BenQ {self.width}x{round(self.width * 9 / 16)} +3000+{self.y}",
                 font=("DejaVu Sans", 14, "bold")).grid(row=0, column=0, columnspan=4, pady=6)
        buttons = (("Up", self.up), ("Down", self.down),
                   ("Bigger", self.bigger), ("Smaller", self.smaller))
        for i, (label, handler) in enumerate(buttons):
            tk.Button(p, text=label, width=10, command=handler).grid(row=1, column=i, padx=4, pady=4)
        tk.Button(p, text="Keep", width=10, command=self.keep).grid(row=2, column=1, pady=6)
        tk.Button(p, text="Cancel", width=10, command=self.cancel).grid(row=2, column=2, pady=6)
        for key, handler in (("<Up>", self.up), ("<Down>", self.down),
                             ("<plus>", self.bigger), ("<KP_Add>", self.bigger),
                             ("<minus>", self.smaller), ("<KP_Subtract>", self.smaller),
                             ("<Return>", self.keep), ("<KP_Enter>", self.keep),
                             ("<Escape>", self.cancel)):
            p.bind(key, lambda e, h=handler: h())
        p.after(300, p.focus_force)

    def change(self, width, y):
        self.width, self.y = width, y
        apply(width, y)
        self.root.after(1500, self.draw)

    # Up arrow: the BenQ content moves up (y increases)
    def up(self, _e=None):
        self.change(self.width, self.y + 10)

    def down(self, _e=None):
        self.change(self.width, self.y - 10)

    # Bigger content means fewer logical pixels on the same screen
    def bigger(self, _e=None):
        self.change(self.width - 32, self.y)

    def smaller(self, _e=None):
        self.change(min(1920, self.width + 32), self.y)

    def keep(self, _e=None):
        RESULT.write_text(metamode(self.width, self.y) + "\n")
        self.root.destroy()

    def cancel(self, _e=None):
        apply(*self.start)
        self.root.destroy()


Aligner().root.mainloop()
