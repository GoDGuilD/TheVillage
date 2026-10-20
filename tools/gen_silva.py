# File: gen_silva.py
# Description: Generates the Phase 12 sprites - the Flippers icon, the seed shot, the snapvine's root, the splash effect, and the snapvine and Thornheart enemy packs - plus a preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
#
# Run:  python -I tools/gen_silva.py
# Writes assets/ui/items/flippers.png, assets/sprites/items/{seed_shot,snapvine_root}.png,
# assets/sprites/vfx/splash.png + vfx_silva.json (read by the Juice next to vfx_manifest.json), the packs
# assets/sprites/enemies/{snapvine,thornheart}.json + strips, and tmp/silva_preview.png.
# Joe's swim strips are drawn by gen_joe.py; the jungle ground and the grove's pools by silva_art.py (gen_tiles.py).
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import palette as P
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "assets", "ui", "items")
ITEMS = os.path.join(ROOT, "assets", "sprites", "items")
VFX = os.path.join(ROOT, "assets", "sprites", "vfx")
ENEMIES = os.path.join(ROOT, "assets", "sprites", "enemies")
PREVIEW = os.path.join(ROOT, "tmp", "silva_preview.png")
SPLASH_FRAME = (24, 16)
SPLASH_FPS = 14.0
SHOWN = []


def save(img, folder, name):
    im = img.img if isinstance(img, Canvas) else img
    os.makedirs(folder, exist_ok=True)
    im.save(os.path.join(folder, name))
    SHOWN.append(im)
    return im


def write_pack(name, frame, feet, anims):
    meta = {"frame_size": list(frame), "feet": list(feet), "anims": {}}
    for anim, (frames, fps, loop) in anims.items():
        save(pack_strip(frames), ENEMIES, "%s_%s.png" % (name, anim))
        meta["anims"][anim] = {"fps": fps, "loop": loop}
    with open(os.path.join(ENEMIES, name + ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(meta, f, indent=2)


def flippers_icon():
    """Two webbed flippers side by side (16x16)."""
    c = Canvas(16, 16)
    for ox in (1, 8):
        c.poly([(ox + 1, 2), (ox + 5, 2), (ox + 7, 14), (ox, 14)], P.FLIPPER_MID)
        c.rect(ox + 2, 2, 2, 4, P.FLIPPER_DARK)                  # the heel strap
        for k in range(3):                                        # webbing ribs
            c.line((ox + 2 + k, 7), (ox + 1 + k * 2, 13), P.FLIPPER_LIGHT)
    c.outline(P.OUTLINE)
    return c


def seed_shot():
    c = Canvas(8, 8)
    c.ellipse(3.5, 3.5, 3, 2.5, P.SEED_MID)
    c.set(2, 2, P.THORN)
    c.set(5, 5, P.SEED_DARK)
    c.outline(P.OUTLINE)
    return c


def snapvine_root():
    """The leaves around a snapvine's root (16x12): stays put while the head lunges."""
    c = Canvas(16, 12)
    c.ellipse(7.5, 9, 7, 2.5, P.SHADOW)
    for x0, x1 in ((7, 1), (8, 14)):
        c.poly([(x0, 8), (x1, 4), (x1 + (2 if x1 < 8 else -2), 9)], P.VINE_MID)
    c.poly([(6, 9), (8, 2), (10, 9)], P.VINE_DARK)
    c.line((7, 8), (8, 4), P.VINE_LIGHT)
    c.outline(P.OUTLINE)
    return c


def splash_frames():
    """Joe hitting deep water: a ring of droplets thrown up and falling back (4 frames)."""
    frames = []
    for f in range(4):
        c = Canvas(*SPLASH_FRAME)
        cx, cy = 11.5, 12
        r = 3 + f * 2.5
        c.ellipse(cx, cy, r, r * 0.4, P.RIPPLE)
        c.ellipse(cx, cy, max(1.0, r - 1.5), max(0.5, r * 0.4 - 1), (0, 0, 0, 0))
        for k in range(6):
            a = math.pi + k * math.pi / 5
            h = (f + 1) * (2.5 - abs(k - 2.5) * 0.4) - f * f * 0.6
            x, y = cx + math.cos(a) * (2 + f * 2), cy - max(0.0, h) - 1
            c.rect(int(x), int(y), 1, 2 if f < 2 else 1, P.RIPPLE if k % 2 else P.FLIPPER_LIGHT)
        frames.append(c)
    return frames


def snapvine_frame(i, bite=False):
    """The snapvine's head (24x24, feet at (12,20)): a closed pod swaying, or jaws open with thorn teeth."""
    c = Canvas(24, 24)
    b = Canvas(24, 24)
    sway = (0, 1)[i % 2]
    if bite:
        gape = 5 if i == 0 else 2
        b.ellipse(12, 10 - gape / 2, 8, 4.5, P.PETAL_MID)              # upper jaw
        b.ellipse(12, 12 + gape / 2, 8, 4, P.PETAL_DARK)               # lower jaw
        b.rect(5, int(11 - gape / 2), 14, gape + 1, P.OUTLINE)         # the mouth
        for x in range(6, 19, 3):                                      # thorn teeth
            b.set(x, int(12 - gape / 2), P.THORN)
            b.set(x + 1, int(11 + gape / 2), P.THORN)
        b.ellipse(10, 7 - gape / 2, 2.5, 1.2, P.PETAL_LIGHT)
    else:
        b.ellipse(12 + sway, 11, 7, 7.5, P.PETAL_MID)                  # the closed pod
        b.ellipse(10 + sway, 8, 3, 3, P.PETAL_LIGHT)
        b.line((12 + sway, 4), (12 + sway, 18), P.PETAL_DARK)          # the seam it opens along
        for x, y in ((6, 10), (18, 12), (9, 16)):
            b.set(x + sway, y, P.THORN)
    b.poly([(8, 18), (12, 14), (16, 18), (12, 21)], P.VINE_MID)        # the sepals under the head
    b.outline(P.OUTLINE)
    c.paste(b)
    return c


def thornheart_frame(i, open_=False):
    """The Thornheart (64x64, feet at (32,58)): a huge bud bound in thorny vines; open = petals spread around a
    glowing heart (the fire rod's flame burnt its thorns back)."""
    c = Canvas(64, 64)
    c.ellipse(32, 58, 24, 4, P.SHADOW)
    b = Canvas(64, 64)
    pulse = (0, 1)[i % 2]
    for k in range(5):                                                 # roots spreading on the ground
        a = math.pi * (0.1 + 0.2 * k)
        b.line((32, 54), (int(32 + math.cos(a) * 26), int(56 + math.sin(a) * 4)), P.VINE_DARK, 2)
    if open_:
        for k in range(6):                                             # petals spread wide
            a = -math.pi / 2 + k * math.pi / 3
            px, py = 32 + math.cos(a) * 16, 32 + math.sin(a) * 13
            b.ellipse(px, py, 10, 8, P.PETAL_MID)
            b.ellipse(px - 2, py - 2, 4, 3, P.PETAL_LIGHT)
        b.ellipse(32, 32, 10 + pulse, 10 + pulse, P.PETAL_DARK)
        b.ellipse(32, 32, 6 + pulse, 6 + pulse, P.LAVA_LIGHT)          # the heart, glowing
        b.ellipse(31, 31, 3, 3, P.LAVA_GLOW)
    else:
        b.ellipse(32, 34, 18 + pulse, 21 + pulse, P.PETAL_MID)         # the bud
        b.ellipse(26, 26, 6, 8, P.PETAL_LIGHT)
        b.line((32, 14), (32, 54), P.PETAL_DARK)
        for k in range(4):                                             # the thorny vines binding it
            y = 20 + k * 9
            b.line((14, y + 4), (50, y - 2), P.VINE_DARK, 2)
            b.line((14, y + 3), (50, y - 3), P.VINE_MID)
            for x in range(17, 49, 6):
                b.set(x, int(y + 3 - (x - 14) * 6 / 36) - 2, P.THORN)
    b.poly([(18, 50), (32, 44), (46, 50), (32, 57)], P.VINE_MID)       # sepals
    b.outline(P.OUTLINE)
    c.paste(b)
    return c


def main():
    save(flippers_icon(), ICONS, "flippers.png")
    save(seed_shot(), ITEMS, "seed_shot.png")
    save(snapvine_root(), ITEMS, "snapvine_root.png")
    save(pack_strip(splash_frames()), VFX, "splash.png")
    with open(os.path.join(VFX, "vfx_silva.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"splash.png": {"frame_size": list(SPLASH_FRAME), "fps": SPLASH_FPS, "origin": "center"}}, f,
                  indent=2)
    write_pack("snapvine", (24, 24), (12, 20), {"idle": ([snapvine_frame(i) for i in range(2)], 3.0, True),
                                               "bite": ([snapvine_frame(i, True) for i in range(2)], 10.0, True)})
    write_pack("thornheart", (64, 64), (32, 58), {"closed": ([thornheart_frame(i) for i in range(2)], 2.0, True),
                                                 "open": ([thornheart_frame(i, True) for i in range(2)], 6.0, True)})
    pad = 4
    w = sum(im.width for im in SHOWN) + pad * (len(SHOWN) + 1)
    h = max(im.height for im in SHOWN) + 2 * pad
    sheet = Image.new("RGBA", (w, h), (60, 80, 70, 255))
    x = pad
    for im in SHOWN:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 3).save(PREVIEW)
    print("silva art written (%d images); preview %s" % (len(SHOWN), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
