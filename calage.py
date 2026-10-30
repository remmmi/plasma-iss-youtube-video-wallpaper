#!/usr/bin/env python3
# Calage du BenQ (HDMI-1 / DPY-1) a l'oeil, mire affichee sur les trois ecrans.
#   Haut / Bas      : decale le BenQ de 10 pixels
#   + / -           : agrandit / reduit le contenu du BenQ
#   Entree          : garde le reglage et l'ecrit dans calage-resultat.txt
#   Echap           : remet le reglage de depart et quitte
import re
import subprocess
import tkinter as tk
from pathlib import Path

STEP = 20
PANEL_BAND = 220
RESULT = Path(__file__).with_name("calage-resultat.txt")


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


class Calage:
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
                # Bande libre en bas du HP pour la fenetre de commande
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
                        "Reglage dans la fenetre Calage BenQ")
                c.create_text(w // 2, h // 2, text=text, fill="white", justify="center",
                              font=("DejaVu Sans", 20, "bold"))
            self.windows.append(win)
        self.control()

    def control(self):
        # Fenetre normale (decoree) : seule a pouvoir recevoir le clavier
        if getattr(self, "panel", None) is not None:
            self.panel.destroy()
        p = tk.Toplevel(self.root)
        self.panel = p
        p.title("Calage BenQ")
        p.geometry(f"+700+{653 + 1080 - PANEL_BAND + 20}")
        p.attributes("-topmost", True)
        tk.Label(p, text=f"BenQ {self.width}x{round(self.width * 9 / 16)} +3000+{self.y}",
                 font=("DejaVu Sans", 14, "bold")).grid(row=0, column=0, columnspan=4, pady=6)
        buttons = (("Monter", self.up), ("Descendre", self.down),
                   ("Agrandir", self.bigger), ("Reduire", self.smaller))
        for i, (label, handler) in enumerate(buttons):
            tk.Button(p, text=label, width=10, command=handler).grid(row=1, column=i, padx=4, pady=4)
        tk.Button(p, text="Garder", width=10, command=self.keep).grid(row=2, column=1, pady=6)
        tk.Button(p, text="Annuler", width=10, command=self.cancel).grid(row=2, column=2, pady=6)
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

    # Fleche haut : le contenu du BenQ monte (y augmente)
    def up(self, _e=None):
        self.change(self.width, self.y + 10)

    def down(self, _e=None):
        self.change(self.width, self.y - 10)

    # Agrandir le contenu = moins de pixels logiques sur le meme ecran
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


Calage().root.mainloop()
