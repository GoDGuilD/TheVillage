# File: gen_tower.py
# Description: Generates the Phase 13 sprites - Caver's mortal form (the final boss), the crystal gate of his tower with its four dimension sockets, and the four dimension bolts he casts - plus a preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
#
# Run:  python -I tools/gen_tower.py
# Writes assets/sprites/dungeon/crystal_gate.png + crystal_socket_{0..3}.png, assets/sprites/items/
# caver_bolt_{0..3}.png, the pack assets/sprites/enemies/caver_lord.json + strips, and tmp/tower_preview.png.
# The order 0..3 is always Umbra, Ignis, Tempus, Silva (GameState.crystals).
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import palette as P
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ITEMS = os.path.join(ROOT, "assets", "sprites", "items")
DUNGEON = os.path.join(ROOT, "assets", "sprites", "dungeon")
ENEMIES = os.path.join(ROOT, "assets", "sprites", "enemies")
PREVIEW = os.path.join(ROOT, "tmp", "tower_preview.png")
GEMS = [(P.UMBRA_GEM, P.UMBRA_GEM_L), (P.IGNIS_GEM, P.IGNIS_GEM_L), (P.TEMPUS_GEM, P.TEMPUS_GEM_L),
        (P.SILVA_GEM, P.SILVA_GEM_L)]
GATE_SOCKETS_X = (7, 13, 19, 25)         # socket centres on the gate (CrystalGate sockets in SealGate.gd match)
GATE_SOCKET_Y = 5
LORD_FRAME = (40, 56)
LORD_FEET = (20, 54)
SHOWN = []


def save(img, folder, name):
    im = img.img if isinstance(img, Canvas) else img
    os.makedirs(folder, exist_ok=True)
    im.save(os.path.join(folder, name))
    SHOWN.append(im)
    return im


def write_pack(name, frame, feet, anims):
    """anims = {anim: (frames: [Canvas], fps, loop)} -> <name>_<anim>.png strips + <name>.json manifest."""
    meta = {"frame_size": list(frame), "feet": list(feet), "anims": {}}
    for anim, (frames, fps, loop) in anims.items():
        save(pack_strip(frames), ENEMIES, "%s_%s.png" % (name, anim))
        meta["anims"][anim] = {"fps": fps, "loop": loop}
    with open(os.path.join(ENEMIES, name + ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(meta, f, indent=2)


# --------------------------------------------------------------------------- the gate

def crystal_gate():
    """32x32 barrier in the tower wall: four empty diamond sockets above a sealed arch of glowing bars."""
    c = Canvas(32, 32)
    c.rect(0, 0, 32, 32, P.GATE_STONE_D)
    c.rect(0, 0, 32, 2, P.GATE_STONE_L)
    c.rect(3, 10, 26, 22, P.GATE_STONE_M)
    c.ellipse(15.5, 13, 10, 5, P.GATE_STONE_M)              # the arch's round top
    c.rect(5, 13, 22, 19, P.INK)
    c.ellipse(15.5, 13.5, 8, 3.5, P.INK)
    for x in range(7, 26, 3):                                # bars of Caver's will, faintly lit
        c.rect(x, 11, 1, 21, P.ORB_EDGE)
    c.rect(5, 21, 22, 1, P.ORB_EDGE)
    for x in GATE_SOCKETS_X:
        c.poly([(x, GATE_SOCKET_Y - 3), (x + 3, GATE_SOCKET_Y), (x, GATE_SOCKET_Y + 3), (x - 3, GATE_SOCKET_Y)],
               P.GOLD_DARK)
        c.poly([(x, GATE_SOCKET_Y - 2), (x + 2, GATE_SOCKET_Y), (x, GATE_SOCKET_Y + 2), (x - 2, GATE_SOCKET_Y)],
               P.UI_WELL)
    return c


def crystal_socket(i):
    """7x7 lit diamond for dimension i, laid over its socket once Joe holds that crystal."""
    mid, light = GEMS[i]
    c = Canvas(7, 7)
    c.poly([(3, 0), (6, 3), (3, 6), (0, 3)], P.GOLD)
    c.poly([(3, 1), (5, 3), (3, 5), (1, 3)], mid)
    c.set(3, 2, light)
    c.set(2, 3, light)
    return c


def caver_bolt(i):
    """8x8 dimension bolt: a spinning diamond core in its dimension's colours."""
    mid, light = GEMS[i]
    c = Canvas(8, 8)
    c.ellipse(3.5, 3.5, 3.6, 3.6, P.OUTLINE)
    c.ellipse(3.5, 3.5, 2.8, 2.8, mid)
    c.poly([(3.5, 1), (6, 3.5), (3.5, 6), (1, 3.5)], light)
    c.set(3, 3, P.WHITE)
    return c


# --------------------------------------------------------------------------- Caver

def lord_frame(i, pose="float", rage=False):
    """Caver's mortal form (40x56, feet at (20,54)): a tall gaunt lord in a high-collared cape with a red lining,
    a pale face, slick black hair and burning eyes. pose: float | cast (arms up, an orb forming) | dazed (knelt,
    head down). rage: the cape spreads into bat wings."""
    c = Canvas(*LORD_FRAME)
    cx = LORD_FEET[0]
    bob = (0, -1, -1, 0)[i % 4] if pose != "dazed" else 0
    body = Canvas(*LORD_FRAME)
    top = 6 + bob if pose != "dazed" else 18                # the dazed lord kneels: everything drops
    if rage:                                                  # wings behind everything
        flap = (0, 2, 3, 1)[i % 4]
        for side in (-1, 1):
            tip = (cx + side * 19, top + 6 - flap)
            pts = [(cx + side * 3, top + 12), tip, (cx + side * 17, top + 22), (cx + side * 13, top + 18),
                   (cx + side * 11, top + 28), (cx + side * 7, top + 22), (cx + side * 4, top + 30)]
            body.poly(pts, P.CAVER_WING_M)
            body.line((cx + side * 3, top + 12), tip, P.CAVER_WING_D, 1)
            body.line(tip, (cx + side * 11, top + 28), P.CAVER_WING_D, 1)
    hem = 54 if pose != "dazed" else 54
    body.poly([(cx - 11, hem), (cx + 11, hem), (cx + 6, top + 14), (cx - 6, top + 14)], P.CAVER_CLOAK_D)
    body.poly([(cx - 7, hem), (cx + 7, hem), (cx + 4, top + 16), (cx - 4, top + 16)], P.CAVER_LINING)
    body.poly([(cx - 4, hem), (cx + 4, hem), (cx + 3, top + 15), (cx - 3, top + 15)], P.CAVER_CLOAK_M)
    body.rect(cx - 1, top + 17, 2, 10, P.GOLD_DARK)          # the clasp chain
    body.poly([(cx - 8, top + 15), (cx - 3, top + 4), (cx - 1, top + 13)], P.CAVER_LINING)   # the high collar
    body.poly([(cx + 8, top + 15), (cx + 3, top + 4), (cx + 1, top + 13)], P.CAVER_LINING)
    head_y = top + 8 + (2 if pose == "dazed" else 0)         # head bowed when dazed
    body.ellipse(cx, head_y, 4, 5, P.CAVER_SKIN)
    body.ellipse(cx, head_y - 3, 4.5, 2.5, P.CAVER_HAIR)     # slicked hair with a widow's peak
    body.set(cx, head_y - 1, P.CAVER_HAIR)
    if pose == "dazed":
        body.set(cx - 2, head_y + 1, P.CAVER_CLOAK_D)          # eyes shut
        body.set(cx + 2, head_y + 1, P.CAVER_CLOAK_D)
    else:
        body.set(cx - 2, head_y, P.CAVER_EYE)
        body.set(cx + 2, head_y, P.CAVER_EYE)
        body.set(cx, head_y + 3, P.CAVER_CLOAK_D)              # thin mouth
    if pose == "cast":
        for side in (-1, 1):
            body.line((cx + side * 5, top + 18), (cx + side * 12, top + 4), P.CAVER_CLOAK_M, 2)
            body.set(cx + side * 12, top + 3, P.CAVER_SKIN)
        r = 3.0 + (i % 2)
        body.ellipse(cx, top - 1, r, r, P.ORB_EDGE)
        body.ellipse(cx, top - 1, r - 1.5, r - 1.5, P.ORB_CORE)
    elif pose == "dazed":
        for side in (-1, 1):                                  # hands on the floor
            body.line((cx + side * 5, top + 18), (cx + side * 9, 52), P.CAVER_CLOAK_M, 2)
            body.set(cx + side * 9, 53, P.CAVER_SKIN)
    else:
        for side in (-1, 1):                                  # long fingers folded in front
            body.line((cx + side * 5, top + 18), (cx + side * 2, top + 26), P.CAVER_CLOAK_M, 2)
        body.set(cx - 1, top + 27, P.CAVER_SKIN)
        body.set(cx + 1, top + 27, P.CAVER_SKIN)
    body.outline(P.OUTLINE)
    c.ellipse(cx, 54, 9, 2, P.SHADOW)
    c.paste(body)
    if pose == "dazed":                                       # three stars circling his head
        for k in range(3):
            a = (i * 0.9) + k * 2 * math.pi / 3
            sx, sy = cx + 7 * math.cos(a), head_y - 7 + 2 * math.sin(a)
            c.set(int(round(sx)), int(round(sy)), P.GOLD)
            c.set(int(round(sx)) + 1, int(round(sy)), P.TEMPUS_GEM_L)
    return c


def main():
    save(crystal_gate(), DUNGEON, "crystal_gate.png")
    for i in range(len(GEMS)):
        save(crystal_socket(i), DUNGEON, "crystal_socket_%d.png" % i)
        save(caver_bolt(i), ITEMS, "caver_bolt_%d.png" % i)
    write_pack("caver_lord", LORD_FRAME, LORD_FEET, {
        "float": ([lord_frame(i) for i in range(4)], 6.0, True),
        "cast": ([lord_frame(i, "cast") for i in range(2)], 6.0, True),
        "dazed": ([lord_frame(i, "dazed") for i in range(4)], 6.0, True),
        "rage": ([lord_frame(i, rage=True) for i in range(4)], 8.0, True),
        "rage_cast": ([lord_frame(i, "cast", rage=True) for i in range(2)], 8.0, True),
    })
    pad = 4
    w = sum(im.width for im in SHOWN) + pad * (len(SHOWN) + 1)
    h = max(im.height for im in SHOWN) + 2 * pad
    sheet = Image.new("RGBA", (w, h), (70, 62, 84, 255))
    x = pad
    for im in SHOWN:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 3).save(PREVIEW)
    print("%d tower images written; preview %s" % (len(SHOWN), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
