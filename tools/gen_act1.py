# File: gen_act1.py
# Description: Generates the Phase 7 art - dash boots and fire rod icons, the fireball, magic jars, rubble, the seal gate, dash dust, and the enemy packs for the bat, the Iron Ram, the Frost Wraith (with its ice shard) and Caver's shade (with its orb) - plus a preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
#
# Run:  python -I tools/gen_act1.py
# Writes assets/ui/items/{boots,fire_rod}.png, assets/sprites/items/{fireball,magic_small,magic_big,rubble,ice_shard,
# orb}.png, assets/sprites/dungeon/seal_gate.png, assets/sprites/vfx/dust.png (+ vfx_act1.json), the enemy packs
# assets/sprites/enemies/{bat,iron_ram,frost_wraith,caver}.json + strips, and tmp/act1_preview.png.
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from palette import (BAT_DARK, BAT_EYE, BAT_MID, BOOT_LEATHER_D, BOOT_LEATHER_M, BOOT_WING, CAVER_CLOAK_D,
                     CAVER_CLOAK_M, CAVER_EYE, CAVER_SKIN, FIRE_CORE, FIRE_EDGE, FIRE_MID, GATE_STONE_D, GATE_STONE_L,
                     GATE_STONE_M, GOLD, GOLD_DARK, ICE_CORE, ICE_EDGE, INK, JAR_CORK, JAR_GLASS, JAR_POTION, ORB_BACK,
                     ORB_CORE, ORB_EDGE, OUTLINE, RAM_DARK, RAM_EYE, RAM_HORN, RAM_LIGHT, RAM_MID, ROD_GEM, ROD_WOOD_D,
                     ROD_WOOD_M, RUBBLE_DARK, RUBBLE_LIGHT, RUBBLE_MID, SEAL_DARK, SEAL_MID, SHADOW, SMOKE_LIGHT,
                     SMOKE_MID, UI_WELL, WHITE, WRAITH_DARK, WRAITH_LIGHT, WRAITH_MID)
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "assets", "ui", "items")
ITEMS = os.path.join(ROOT, "assets", "sprites", "items")
DUNGEON = os.path.join(ROOT, "assets", "sprites", "dungeon")
ENEMIES = os.path.join(ROOT, "assets", "sprites", "enemies")
VFX = os.path.join(ROOT, "assets", "sprites", "vfx")
PREVIEW = os.path.join(ROOT, "tmp", "act1_preview.png")
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


# --------------------------------------------------------------------------- items and props

def boots_icon():
    c = Canvas(16, 16)
    c.rect(4, 2, 5, 9, BOOT_LEATHER_M)                    # shaft
    c.rect(4, 10, 10, 4, BOOT_LEATHER_M)                  # foot
    c.rect(4, 13, 10, 1, BOOT_LEATHER_D)
    c.rect(4, 2, 5, 2, BOOT_LEATHER_D)                    # cuff
    c.poly([(9, 3), (14, 1), (12, 5), (9, 6)], BOOT_WING)  # the little wing
    c.set(5, 6, BOOT_LEATHER_D)
    c.outline(OUTLINE)
    return c


def fire_rod_icon():
    c = Canvas(16, 16)
    c.line((3, 14), (11, 6), ROD_WOOD_M, 2)
    c.line((4, 14), (11, 7), ROD_WOOD_D)
    c.ellipse(12, 4, 2.6, 2.6, ROD_GEM)
    c.set(11, 3, FIRE_CORE)
    c.rect(10, 6, 3, 1, GOLD)
    c.outline(OUTLINE)
    return c


def fireball():
    frames = []
    for i in range(3):
        c = Canvas(12, 12)
        r = 4.5 + (i % 2) * 0.5
        c.ellipse(6, 6, r, r, FIRE_EDGE)
        c.ellipse(6 + (i - 1) * 0.5, 6, r - 1.5, r - 1.5, FIRE_MID)
        c.ellipse(6, 6, 1.8, 1.8, FIRE_CORE)
        frames.append(c)
    return pack_strip(frames)


def magic_jar(big):
    w, h = (10, 13) if big else (8, 10)
    c = Canvas(w, h)
    c.rect(1, 3, w - 2, h - 4, JAR_GLASS)
    c.rect(2, 5 if big else 4, w - 4, h - 7 if big else h - 6, JAR_POTION)
    c.rect(2, 0, w - 4, 3, JAR_CORK)
    c.set(2, 4, WHITE)
    c.outline(OUTLINE)
    return c


def rubble():
    """A pile of loose rocks the dash boots break (16x16)."""
    c = Canvas(16, 16)
    for cx, cy, r in ((5, 10, 4), (11, 10, 4), (8, 6, 4), (3, 6, 2.5), (13, 5, 2.5)):
        c.ellipse(cx, cy, r, r * 0.8, RUBBLE_MID)
        c.ellipse(cx - 1, cy - 1, r * 0.4, r * 0.3, RUBBLE_LIGHT)
    c.rect(2, 13, 12, 1, RUBBLE_DARK)
    c.outline(OUTLINE)
    return c


def ice_shard():
    c = Canvas(10, 10)
    c.poly([(5, 0), (9, 5), (5, 9), (1, 5)], ICE_EDGE)
    c.poly([(5, 2), (7, 5), (5, 7), (3, 5)], ICE_CORE)
    c.outline(OUTLINE)
    return c


def orb(batted):
    """Caver's magic orb: 2 frames; batted back by Joe it turns blue."""
    frames = []
    for i in range(2):
        c = Canvas(14, 14)
        edge = ORB_BACK if batted else ORB_EDGE
        c.ellipse(7, 7, 6 - i * 0.5, 6 - i * 0.5, edge)
        c.ellipse(7, 7, 3.5, 3.5, ORB_CORE)
        c.set(5, 5, WHITE)
        frames.append(c)
    return pack_strip(frames)


def seal_gate():
    """32x32 gate in the keep wall with three seal sockets above the bars (sockets light in the engine)."""
    c = Canvas(32, 32)
    c.rect(0, 0, 32, 32, GATE_STONE_D)
    c.rect(0, 0, 32, 2, GATE_STONE_L)
    c.rect(3, 9, 26, 23, GATE_STONE_M)
    c.rect(5, 11, 22, 21, INK)
    for x in range(6, 27, 4):
        c.rect(x, 11, 2, 21, GATE_STONE_L)
    c.rect(5, 18, 22, 2, GATE_STONE_L)
    for i, x in enumerate((8, 16, 24)):
        c.ellipse(x - 0.5, 5, 2.6, 2.6, GOLD_DARK)
        c.ellipse(x - 0.5, 5, 1.6, 1.6, UI_WELL)
    return c


def seal_socket_lit():
    c = Canvas(6, 6)
    c.ellipse(2.5, 2.5, 2.6, 2.6, GOLD)
    c.ellipse(2.5, 2.5, 1.6, 1.6, SEAL_MID)
    c.set(2, 2, SEAL_DARK)
    return c


def dust():
    """Dash dust: a puff that grows and fades (4 frames, 12x12)."""
    frames = []
    for i in range(4):
        c = Canvas(12, 12)
        r = 2 + i
        c.ellipse(6, 7, r, r * 0.7, SMOKE_MID if i < 2 else SMOKE_LIGHT)
        if i < 3:
            c.ellipse(5, 6, r * 0.5, r * 0.4, SMOKE_LIGHT)
        frames.append(c)
    return pack_strip(frames)


# --------------------------------------------------------------------------- enemies

def bat_frame(wing_up):
    c = Canvas(20, 20)
    c.ellipse(10, 9, 3, 3, BAT_MID)
    if wing_up:
        c.poly([(8, 9), (1, 3), (3, 9)], BAT_DARK)
        c.poly([(12, 9), (19, 3), (17, 9)], BAT_DARK)
    else:
        c.poly([(8, 9), (1, 13), (4, 9)], BAT_DARK)
        c.poly([(12, 9), (19, 13), (16, 9)], BAT_DARK)
    c.set(9, 8, BAT_EYE)
    c.set(11, 8, BAT_EYE)
    c.outline(OUTLINE)
    out = Canvas(20, 20)
    out.ellipse(10, 18, 3, 1, SHADOW)
    out.paste(c)
    return out


def ram_frame(facing, step, dazed=False):
    """The Iron Ram: a squat armoured beast with curled horns (48x40, feet at (24,36))."""
    c = Canvas(48, 40)
    fx, fy = 24, 36
    bob = (0, -1, 0, 1)[step % 4]
    body = Canvas(48, 40)
    body.ellipse(fx, fy - 12 + bob, 15, 10, RAM_MID)
    body.ellipse(fx - 3, fy - 15 + bob, 9, 5, RAM_LIGHT)
    body.rect(fx - 15, fy - 8 + bob, 30, 3, RAM_DARK)
    for lx in (-10, -4, 4, 10):                            # legs
        lift = 2 if (lx > 0) == (step % 2 == 0) else 0
        body.rect(fx + lx - 2, fy - 6 - lift, 4, 6, RAM_DARK)
    hx = fx + (11 if facing == "side" else 0)
    hy = fy - 18 + bob + (4 if facing == "down" else 0)
    if facing != "up":
        for side in (-1, 1):                               # curled horns, behind the head and sweeping out
            body.ellipse(hx + side * 8, hy + 1, 4.5, 4, RAM_HORN)
            body.ellipse(hx + side * 9, hy + 2, 2, 1.8, RAM_DARK)
        body.ellipse(hx, hy, 6, 6, RAM_LIGHT)               # head
        body.rect(hx - 3, hy + 3, 6, 3, RAM_MID)            # snout
        eye = RAM_EYE if not dazed else WHITE
        body.set(hx - 2, hy, eye)
        body.set(hx + 2, hy, eye)
    if dazed:                                              # stars circling
        for k in range(3):
            a = k * 2.1 + step
            body.set(fx + math.cos(a) * 10, fy - 30 + math.sin(a) * 3, GOLD)
    body.outline(OUTLINE)
    c.ellipse(fx, fy - 1, 15, 3, SHADOW)
    c.paste(body)
    return c


def wraith_frame(i, cast=False):
    """The Frost Wraith: a hooded drift of ice with a long frayed tail (40x48, floats)."""
    c = Canvas(40, 48)
    cx = 20
    top = 6 + (0, 1, 2, 1)[i % 4]
    body = Canvas(40, 48)
    body.ellipse(cx, top + 10, 11, 10, WRAITH_MID)
    body.poly([(cx - 11, top + 10), (cx + 11, top + 10), (cx + 6, top + 34), (cx, top + 30), (cx - 6, top + 34)],
              WRAITH_MID)
    body.ellipse(cx - 3, top + 6, 4, 3, WRAITH_LIGHT)
    body.ellipse(cx, top + 12, 6, 5, WRAITH_DARK)          # the hood's shadow
    eye = ICE_CORE if not cast else WHITE
    body.set(cx - 2, top + 12, eye)
    body.set(cx + 2, top + 12, eye)
    if cast:
        body.ellipse(cx, top + 22, 4, 4, ICE_CORE)
    body.outline(OUTLINE)
    c.ellipse(cx, 45, 8, 2, SHADOW)
    c.paste(body)
    return c


def caver_frame(i, cast=False):
    """Caver's shade: a tall cloaked figure, pale face, burning eyes (32x48, feet at (16,46))."""
    c = Canvas(32, 48)
    cx = 16
    sway = (0, 1, 0, -1)[i % 4]
    body = Canvas(32, 48)
    body.poly([(cx - 9 + sway, 46), (cx + 9 + sway, 46), (cx + 5, 14), (cx - 5, 14)], CAVER_CLOAK_M)
    body.poly([(cx - 3, 46), (cx + 3, 46), (cx + 1, 18), (cx - 1, 18)], CAVER_CLOAK_D)
    body.ellipse(cx, 11, 5, 6, CAVER_CLOAK_D)               # hood
    body.ellipse(cx, 12, 3, 4, CAVER_SKIN)
    body.set(cx - 1, 11, CAVER_EYE)
    body.set(cx + 1, 11, CAVER_EYE)
    if cast:
        for side in (-1, 1):
            body.line((cx + side * 5, 20), (cx + side * 12, 10), CAVER_CLOAK_M, 2)
        body.ellipse(cx, 4, 3, 3, ORB_EDGE)
    body.outline(OUTLINE)
    c.ellipse(cx, 46, 7, 2, SHADOW)
    c.paste(body)
    return c


def main():
    save(boots_icon(), ICONS, "boots.png")
    save(fire_rod_icon(), ICONS, "fire_rod.png")
    save(fireball(), ITEMS, "fireball.png")
    save(magic_jar(False), ITEMS, "magic_small.png")
    save(magic_jar(True), ITEMS, "magic_big.png")
    save(rubble(), ITEMS, "rubble.png")
    save(ice_shard(), ITEMS, "ice_shard.png")
    save(orb(False), ITEMS, "orb.png")
    save(orb(True), ITEMS, "orb_back.png")
    save(seal_gate(), DUNGEON, "seal_gate.png")
    save(seal_socket_lit(), DUNGEON, "seal_socket.png")
    save(dust(), VFX, "dust.png")
    with open(os.path.join(VFX, "vfx_act1.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"dust.png": {"frame_size": [12, 12], "fps": 14.0, "origin": "center"}}, f, indent=1)
    write_pack("bat", (20, 20), (10, 18), {"fly": ([bat_frame(True), bat_frame(False)], 10.0, True)})
    ram = {}
    for facing in ("down", "up", "side"):
        ram["walk_" + facing] = ([ram_frame(facing, s) for s in range(4)], 8.0, True)
        ram["charge_" + facing] = ([ram_frame(facing, s) for s in range(4)], 16.0, True)
    ram["dazed"] = ([ram_frame("down", s, dazed=True) for s in range(4)], 8.0, True)
    write_pack("iron_ram", (48, 40), (24, 36), ram)
    write_pack("frost_wraith", (40, 48), (20, 45), {"float": ([wraith_frame(i) for i in range(4)], 6.0, True),
                                                   "cast": ([wraith_frame(i, True) for i in range(2)], 6.0, True)})
    write_pack("caver", (32, 48), (16, 46), {"float": ([caver_frame(i) for i in range(4)], 6.0, True),
                                            "cast": ([caver_frame(i, True) for i in range(2)], 6.0, True)})
    pad = 4
    w = sum(im.width for im in SHOWN) + pad * (len(SHOWN) + 1)
    h = max(im.height for im in SHOWN) + 2 * pad
    sheet = Image.new("RGBA", (w, h), (90, 108, 98, 255))
    x = pad
    for im in SHOWN:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 2).save(PREVIEW)
    print("%d act-1 images written; preview %s" % (len(SHOWN), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
