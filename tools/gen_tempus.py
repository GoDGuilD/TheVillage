# File: gen_tempus.py
# Description: Generates the Phase 11 sprites - the Hammer icon and its swing, pegs (up and pounded), amber and teal tick blocks (raised and sunk), the gear shot, the cogbug and clock warden enemy packs - plus a preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-23
# Last edit date: 2026-10-23
# Version: 1.0.0
#
# Run:  python -I tools/gen_tempus.py
# Writes assets/ui/items/hammer.png, assets/sprites/items/{hammer_swing,gear_shot}.png,
# assets/sprites/dungeon/{peg,peg_down,tick_a_up,tick_a_down,tick_b_up,tick_b_down}.png, the packs
# assets/sprites/enemies/{cogbug,clock_warden}.json + strips, and tmp/tempus_preview.png.
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
DUNGEON = os.path.join(ROOT, "assets", "sprites", "dungeon")
ENEMIES = os.path.join(ROOT, "assets", "sprites", "enemies")
PREVIEW = os.path.join(ROOT, "tmp", "tempus_preview.png")
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


def gear(c, cx, cy, r, teeth, dark, mid, light, turn=0.0):
    """A cog: a ring of square teeth around a disc with a hole."""
    for i in range(teeth):
        a = turn + i * 2 * math.pi / teeth
        x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
        c.rect(int(round(x - 1)), int(round(y - 1)), 2, 2, dark)
    c.ellipse(cx, cy, r - 0.5, r - 0.5, mid)
    c.ellipse(cx - 0.5, cy - 0.5, r - 2, r - 2, light)
    c.ellipse(cx, cy, max(1.0, r / 3), max(1.0, r / 3), dark)


def hammer_icon():
    c = Canvas(16, 16)
    c.line((3, 14), (10, 7), P.HAMMER_WOOD, 2)
    c.poly([(7, 2), (12, 7), (14, 5), (9, 0)], P.HAMMER_HEAD)       # the head, tilted
    c.line((9, 1), (13, 5), P.STEEL_LIGHT)
    c.rect(11, 6, 2, 2, P.HAMMER_DARK)
    c.outline(P.OUTLINE)
    return c


def hammer_swing():
    """Three frames (24x24): the hammer coming down in front of Joe (the engine rotates it to his facing)."""
    frames = []
    for i in range(3):
        c = Canvas(24, 24)
        a = (-1.2, -0.4, 0.4)[i]
        hx, hy = 12 + math.cos(a) * 10, 12 + math.sin(a) * 10
        c.line((12, 12), (int(hx), int(hy)), P.HAMMER_WOOD, 2)
        c.ellipse(hx, hy, 4, 3, P.HAMMER_HEAD)
        c.ellipse(hx - 1, hy - 1, 2, 1.5, P.STEEL_LIGHT)
        if i == 2:
            for dx in (-6, 6):                               # the impact
                c.set(int(hx) + dx, int(hy) + 2, P.WHITE)
        c.outline(P.OUTLINE)
        frames.append(c)
    return pack_strip(frames)


def peg(down=False):
    c = Canvas(16, 16)
    if down:
        c.ellipse(7.5, 11, 5, 2.5, P.PEG_DARK)
        c.ellipse(7.5, 10.5, 4, 1.8, P.PEG_MID)
        c.set(6, 10, P.PEG_LIGHT)
    else:
        c.ellipse(7.5, 14, 5, 1.5, P.SHADOW)
        c.rect(5, 4, 6, 10, P.PEG_MID)
        c.rect(5, 4, 2, 10, P.PEG_LIGHT)
        c.rect(9, 4, 2, 10, P.PEG_DARK)
        c.ellipse(7.5, 4, 3, 1.6, P.PEG_LIGHT)
    c.outline(P.OUTLINE)
    return c


def tick_block(a, up):
    """A 16x16 clockwork block: raised (solid, a gear face) or sunk into the floor (a flat plate)."""
    dark, mid, light = (P.TICK_A_DARK, P.TICK_A_MID, P.TICK_A_LIGHT) if a else (P.TICK_B_DARK, P.TICK_B_MID, P.TICK_B_LIGHT)
    c = Canvas(16, 16)
    if up:
        c.rect(0, 2, 16, 14, dark)
        c.rect(0, 0, 16, 12, mid)
        c.rect(1, 1, 14, 1, light)
        gear(c, 7.5, 6, 3.5, 8, dark, light, mid)
    else:
        c.rect(1, 6, 14, 9, dark)
        c.rect(2, 7, 12, 7, mid)
        c.rect(2, 7, 12, 1, light)
    return c


def gear_shot():
    c = Canvas(10, 10)
    gear(c, 4.5, 4.5, 3.5, 6, P.BRASS_DARK, P.BRASS_MID, P.BRASS_LIGHT)
    c.outline(P.OUTLINE)
    return c


def cogbug_frame(i, flipped=False):
    """A brass beetle with a cog for a shell (24x24, feet at (12,20)); flipped = on its back, legs kicking."""
    c = Canvas(24, 24)
    c.ellipse(12, 20, 7, 1.5, P.SHADOW)
    b = Canvas(24, 24)
    if flipped:
        b.ellipse(12, 16, 8, 4, P.STEEL_DARK)
        b.ellipse(12, 15, 6, 2.5, P.STEEL_MID)
        for k, x in enumerate((6, 9, 15, 18)):
            b.line((x, 13), (x + (1 if (k + i) % 2 else -1), 9), P.STEEL_DARK)
    else:
        for k, x in enumerate((6, 9, 15, 18)):                # legs
            b.line((x, 17), (x + (1 if (k + i) % 2 else -1), 20), P.STEEL_DARK)
        gear(b, 12, 13, 6.5, 10, P.BRASS_DARK, P.BRASS_MID, P.BRASS_LIGHT, turn=i * 0.3)
        b.rect(10, 5, 4, 3, P.STEEL_MID)                     # head
        b.set(10, 5, P.LAVA_GLOW)
        b.set(13, 5, P.LAVA_GLOW)
    b.outline(P.OUTLINE)
    c.paste(b)
    return c


def warden_frame(i, cracked=False):
    """The clock warden: an armoured knight with a clock face for a chest and a pendulum blade (40x48, feet at
    (20,44)); cracked = its face split, kneeling."""
    c = Canvas(40, 48)
    c.ellipse(20, 44, 12, 2.5, P.SHADOW)
    b = Canvas(40, 48)
    sink = 4 if cracked else 0
    step = (0, 1, 0, -1)[i % 4] if not cracked else 0
    b.rect(13 + step, 34 + sink, 5, 10 - sink, P.STEEL_DARK)          # legs
    b.rect(22 - step, 34 + sink, 5, 10 - sink, P.STEEL_DARK)
    b.rect(10, 14 + sink, 20, 22, P.STEEL_MID)                         # body armour
    b.rect(10, 14 + sink, 20, 2, P.STEEL_LIGHT)
    b.ellipse(20, 24 + sink, 7, 7, P.BRASS_MID)                        # the clock face
    b.ellipse(20, 24 + sink, 5.5, 5.5, P.WHITE if not cracked else P.STEEL_LIGHT)
    hand = i * 0.9
    b.line((20, 24 + sink), (int(20 + math.cos(hand) * 4), int(24 + sink + math.sin(hand) * 4)), P.OUTLINE)
    b.line((20, 24 + sink), (20, 20 + sink), P.OUTLINE)
    if cracked:
        b.line((15, 19 + sink), (25, 30 + sink), P.OUTLINE)
        b.line((24, 19 + sink), (18, 29 + sink), P.OUTLINE)
    b.rect(13, 4 + sink, 14, 11, P.STEEL_MID)                          # helm
    b.rect(13, 4 + sink, 14, 2, P.STEEL_LIGHT)
    b.rect(15, 9 + sink, 10, 2, P.LAVA_GLOW if not cracked else P.STEEL_DARK)   # visor slit
    swing = (-5, 0, 5, 0)[i % 4] if not cracked else 0
    b.line((32, 16 + sink), (33 + swing, 34 + sink), P.STEEL_DARK, 2)  # the pendulum
    b.ellipse(33 + swing, 36 + sink, 4, 4, P.BRASS_MID)
    b.ellipse(33 + swing, 36 + sink, 2, 2, P.BRASS_LIGHT)
    b.outline(P.OUTLINE)
    c.paste(b)
    return c


def main():
    save(hammer_icon(), ICONS, "hammer.png")
    save(hammer_swing(), ITEMS, "hammer_swing.png")
    save(gear_shot(), ITEMS, "gear_shot.png")
    save(peg(), DUNGEON, "peg.png")
    save(peg(True), DUNGEON, "peg_down.png")
    for a, tag in ((True, "a"), (False, "b")):
        save(tick_block(a, True), DUNGEON, "tick_%s_up.png" % tag)
        save(tick_block(a, False), DUNGEON, "tick_%s_down.png" % tag)
    write_pack("cogbug", (24, 24), (12, 20), {"walk": ([cogbug_frame(i) for i in range(4)], 8.0, True),
                                             "flipped": ([cogbug_frame(i, True) for i in range(2)], 6.0, True)})
    write_pack("clock_warden", (40, 48), (20, 44), {"walk": ([warden_frame(i) for i in range(4)], 6.0, True),
                                                   "cracked": ([warden_frame(0, True)], 1.0, False)})
    pad = 4
    w = sum(im.width for im in SHOWN) + pad * (len(SHOWN) + 1)
    h = max(im.height for im in SHOWN) + 2 * pad
    sheet = Image.new("RGBA", (w, h), (80, 70, 90, 255))
    x = pad
    for im in SHOWN:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 2).save(PREVIEW)
    print("tempus art written (%d images); preview %s" % (len(SHOWN), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
