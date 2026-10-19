# File: gen_ignis.py
# Description: Generates the Phase 10 sprites - the Ice Rod icon, its ice bolt, the ember shot, the ground flame a cinder leaves, the cinder and magma wyrm enemy packs - plus a preview. (Lava, crust and ash tiles come from ignis_art.py via gen_tiles.py.)
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-22
# Last edit date: 2026-10-22
# Version: 1.0.0
#
# Run:  python -I tools/gen_ignis.py
# Writes assets/ui/items/ice_rod.png, assets/sprites/items/{ice_bolt,ember_shot,ground_flame}.png, the packs
# assets/sprites/enemies/{cinder,magma_wyrm}.json + strips, and tmp/ignis_preview.png.
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import palette as P
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "assets", "ui", "items")
ITEMS = os.path.join(ROOT, "assets", "sprites", "items")
ENEMIES = os.path.join(ROOT, "assets", "sprites", "enemies")
PREVIEW = os.path.join(ROOT, "tmp", "ignis_preview.png")
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


def ice_rod_icon():
    c = Canvas(16, 16)
    c.line((3, 14), (11, 6), P.ICE_DARK, 2)
    c.line((4, 14), (11, 7), P.ICE_MID)
    c.poly([(12, 1), (15, 4), (12, 7), (9, 4)], P.ICE_MID)            # an ice crystal head
    c.set(12, 3, P.ICE_LIGHT)
    c.rect(10, 6, 3, 1, P.GOLD)
    c.outline(P.OUTLINE)
    return c


def ice_bolt():
    """Three frames (12x12) of a spinning shard of ice, like the fireball."""
    frames = []
    for i in range(3):
        c = Canvas(12, 12)
        if i == 1:
            c.poly([(1, 6), (6, 2), (11, 6), (6, 10)], P.ICE_DARK)
        else:
            c.poly([(6, 1), (10, 6), (6, 11), (2, 6)], P.ICE_DARK)
        c.ellipse(6, 6, 2.5, 2.5, P.ICE_MID)
        c.set(5 + (i % 2), 5, P.ICE_LIGHT)
        c.set(6, 6, P.ICE_LIGHT)
        frames.append(c)
    return pack_strip(frames)


def ember_shot():
    """One frame: EnemyShot draws a plain sprite."""
    c = Canvas(10, 10)
    c.ellipse(4.5, 4.5, 3.6, 3.6, P.LAVA_MID)
    c.ellipse(4.5, 4.5, 2, 2, P.LAVA_LIGHT)
    c.set(4, 3, P.LAVA_GLOW)
    c.outline(P.OUTLINE)
    return c


def ground_flame():
    """Four frames (16x16) of a small fire licking up from the ground (a cinder's landing)."""
    frames = []
    for i in range(4):
        c = Canvas(16, 16)
        h = (8, 11, 9, 6)[i]
        c.ellipse(8, 14, 6, 1.5, P.LAVA_DEEP)
        c.poly([(3, 15), (8, 15 - h), (13, 15)], P.LAVA_MID)
        c.poly([(5, 15), (8 + (i % 2), 15 - h + 3), (11, 15)], P.LAVA_LIGHT)
        c.set(8, 13, P.LAVA_GLOW)
        frames.append(c)
    return frames


def cinder_frame(i, hop=False):
    """A lump of glowing coal with eyes (24x24, feet at (12,20)); `hop` lifts and stretches it."""
    c = Canvas(24, 24)
    lift = (0, 4, 6, 3)[i] if hop else 0
    squash = 1 if (not hop and i % 2) else 0
    c.ellipse(12, 20, 6, 1.5, P.SHADOW)
    b = Canvas(24, 24)
    b.ellipse(12, 15 - lift + squash, 7, 5 - squash + (1 if hop else 0), P.CINDER_DARK)
    b.ellipse(12, 14 - lift + squash, 5, 3, P.CINDER_MID)
    for x, y in ((8, 13), (15, 15), (11, 17)):                         # glowing cracks
        b.set(x, y - lift + squash, P.LAVA_LIGHT)
    b.rect(9, 12 - lift + squash, 2, 2, P.CINDER_EYE)
    b.rect(14, 12 - lift + squash, 2, 2, P.CINDER_EYE)
    b.poly([(10, 10 - lift), (12, 5 - lift - (i % 2)), (14, 10 - lift)], P.LAVA_MID)   # a flame on top
    b.outline(P.OUTLINE)
    c.paste(b)
    return c


def wyrm_frame(stage, i=0, frozen=False):
    """The magma wyrm's head and neck out of the lava (48x48, feet at (24,44)). stage 0..3 = how far it is up."""
    c = Canvas(48, 48)
    dark, mid, light = (P.ICE_DARK, P.ICE_MID, P.ICE_LIGHT) if frozen else (P.WYRM_DARK, P.WYRM_MID, P.WYRM_LIGHT)
    belly = P.ICE_LIGHT if frozen else P.WYRM_BELLY
    rise = (8, 18, 28, 32)[stage]
    sway = (0, 1, 0, -1)[i % 4] if not frozen else 0
    c.ellipse(24, 44, 14, 4, P.LAVA_DEEP)                               # the ripple it comes out of
    c.ellipse(24, 44, 11, 2.5, P.LAVA_LIGHT)
    b = Canvas(48, 48)
    top = 44 - rise
    b.rect(18 + sway, top + 6, 12, rise - 6, mid)                        # neck
    b.rect(21 + sway, top + 8, 6, rise - 8, belly)
    b.ellipse(24 + sway, top + 4, 10, 7, mid)                            # head
    b.ellipse(24 + sway, top + 2, 9, 4, dark)
    b.rect(16 + sway, top + 6, 16, 2, light)                             # jaw line
    b.rect(18 + sway, top + 1, 3, 2, P.LAVA_GLOW if not frozen else P.ICE_LIGHT)   # eyes
    b.rect(27 + sway, top + 1, 3, 2, P.LAVA_GLOW if not frozen else P.ICE_LIGHT)
    b.poly([(15 + sway, top), (11 + sway, top - 6), (19 + sway, top - 2)], dark)  # horns
    b.poly([(33 + sway, top), (37 + sway, top - 6), (29 + sway, top - 2)], dark)
    b.outline(P.OUTLINE)
    c.paste(b)
    return c


def main():
    save(ice_rod_icon(), ICONS, "ice_rod.png")
    save(ice_bolt(), ITEMS, "ice_bolt.png")
    save(ember_shot(), ITEMS, "ember_shot.png")
    save(pack_strip(ground_flame()), ITEMS, "ground_flame.png")
    write_pack("cinder", (24, 24), (12, 20), {"idle": ([cinder_frame(i) for i in range(2)], 3.0, True),
                                             "hop": ([cinder_frame(i, True) for i in range(4)], 10.0, False)})
    write_pack("magma_wyrm", (48, 48), (24, 44), {
        "rise": ([wyrm_frame(s) for s in range(4)], 8.0, False),
        "up": ([wyrm_frame(3, i) for i in range(4)], 6.0, True),
        "sink": ([wyrm_frame(s) for s in (3, 2, 1, 0)], 8.0, False),
        "frozen": ([wyrm_frame(3, 0, True)], 1.0, False)})
    pad = 4
    w = sum(im.width for im in SHOWN) + pad * (len(SHOWN) + 1)
    h = max(im.height for im in SHOWN) + 2 * pad
    sheet = Image.new("RGBA", (w, h), (70, 60, 60, 255))
    x = pad
    for im in SHOWN:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 2).save(PREVIEW)
    print("ignis art written (%d images); preview %s" % (len(SHOWN), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
