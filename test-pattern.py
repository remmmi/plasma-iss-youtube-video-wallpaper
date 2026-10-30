#!/usr/bin/env python3
# Alignment test pattern: one borderless window per screen, horizontal lines
# at the same virtual desktop coordinates on every screen.
# Closes on Escape, on a click, or after 5 minutes.
import re
import subprocess
import tkinter as tk

STEP = 20
TIMEOUT_MS = 5 * 60 * 1000

out = subprocess.run(["xrandr", "--query"], capture_output=True, text=True).stdout
screens = []
for m in re.finditer(r"^(\S+) connected (?:primary )?(\d+)x(\d+)\+(\d+)\+(\d+)", out, re.M):
    name, w, h, x, y = m.group(1), *map(int, m.groups()[1:])
    screens.append((name, w, h, x, y))

root = tk.Tk()
root.withdraw()
colors = {0: "#ff4040", 1: "#40ff40", 2: "#4080ff", 3: "#ffff40", 4: "#ff40ff"}

def close(_event=None):
    root.destroy()

for name, w, h, x, y in screens:
    win = tk.Toplevel(root)
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
    c.create_text(w // 2, h // 2, text=f"{name}  {w}x{h}+{x}+{y}", fill="white",
                  font=("DejaVu Sans", 28, "bold"))
    win.bind("<Escape>", close)
    win.bind("<Button-1>", close)

root.after(TIMEOUT_MS, close)
root.mainloop()
