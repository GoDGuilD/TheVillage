# File: gen_dungeon.py
# Description: Generates the dungeon sprites - locked, big-key and shutter doors (4 directions), floor switch, push block, big chest, heavy rock, the family-seal pickup, dungeon item icons (map, compass, big key, power glove) and the Grand Slime boss pack - plus a preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
#
# Run:  python -I tools/gen_dungeon.py
# Writes assets/sprites/dungeon/*.png, assets/ui/items/{map,compass,big_key,glove}.png,
# assets/sprites/enemies/grand_slime.json + strips, tmp/dungeon_preview.png.
# Doors are drawn once facing north (32x32: the doorway is 2 tiles wide and the wall 2 tiles deep) and rotated
# for the other sides: door_<type>_<n|s|e|w>.png.
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from palette import (BIGDOOR_RED, CHEST_BAND, CHEST_DARK, CHEST_INSIDE, CHEST_LIGHT, CHEST_MID, DFLOOR_DARK,
                     DFLOOR_MID, DOOR_IRON, DOOR_WOOD_D, DOOR_WOOD_M, DSTONE_DARK, DSTONE_LIGHT, DSTONE_MID, GLOVE_DARK,
                     GLOVE_LIGHT, GLOVE_MID, GOLD, GOLD_DARK, GSLIME_CORE, GSLIME_DARK, GSLIME_LIGHT, GSLIME_MID, INK,
                     KEY_DARK, KEY_LIGHT, KEY_MID, MAP_INK, MAP_PAPER, MOSS, OUTLINE, ROCK_DARK, ROCK_LIGHT, ROCK_MID,
                     SEAL_DARK, SEAL_LIGHT, SEAL_MID, SHADOW, SHUTTER_D, SHUTTER_M, STEEL_LIGHT, STEEL_MID,
                     SWITCH_DOWN, SWITCH_UP, WHITE, BIGDOOR_RED)
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites", "dungeon")
ICONS = os.path.join(ROOT, "assets", "ui", "items")
ENEMY_DIR = os.path.join(ROOT, "assets", "sprites", "enemies")
PREVIEW = os.path.join(ROOT, "tmp", "dungeon_preview.png")
DOOR = 32
BOSS_FRAME = (48, 56)
BOSS_FEET = (24, 52)
SHOWN = []


def save(img, folder, name):
    im = img.img if isinstance(img, Canvas) else img
    os.makedirs(folder, exist_ok=True)
    im.save(os.path.join(folder, name))
    SHOWN.append(im)
    return im


# --------------------------------------------------------------------------- doors

def door_north(kind):
    """32x32 door set in a north wall: stone frame (wall top above, arch), the door panel below."""
    c = Canvas(DOOR, DOOR)
    c.rect(0, 0, DOOR, DOOR, DSTONE_DARK)
    c.rect(0, 12, DOOR, 20, DSTONE_MID)
    c.rect(0, 12, DOOR, 1, DSTONE_LIGHT)
    c.rect(4, 8, 24, 24, DSTONE_LIGHT)                      # arch frame
    c.rect(6, 10, 20, 22, INK)
    if kind == "locked":
        c.rect(7, 12, 18, 20, DOOR_WOOD_M)
        for x in (11, 16, 21):
            c.rect(x, 12, 1, 20, DOOR_WOOD_D)
        c.rect(7, 16, 18, 2, DOOR_IRON)
        c.rect(7, 26, 18, 2, DOOR_IRON)
        c.rect(14, 19, 4, 5, GOLD)                          # lock plate with keyhole
        c.rect(15, 20, 2, 2, INK)
        c.set(15, 22, INK)
    elif kind == "big":
        c.rect(7, 12, 18, 20, BIGDOOR_RED)
        c.rect(7, 12, 18, 2, GOLD)
        c.rect(15, 12, 2, 20, GOLD_DARK)
        c.ellipse(15.5, 22, 5, 5, GOLD)                     # big round lock
        c.ellipse(15.5, 22, 3, 3, GOLD_DARK)
        c.rect(15, 21, 2, 4, INK)
    else:                                                    # shutter: iron bars
        c.rect(7, 12, 18, 20, SHUTTER_D)
        for x in range(8, 25, 4):
            c.rect(x, 12, 2, 20, SHUTTER_M)
        c.rect(7, 12, 18, 2, SHUTTER_M)
        c.rect(7, 22, 18, 2, SHUTTER_M)
    return c


def door_sides(kind):
    """The north drawing rotated for each side (the door's floor edge faces into the room)."""
    n = door_north(kind).img
    return {"n": n, "s": n.transpose(Image.ROTATE_180), "w": n.transpose(Image.ROTATE_90),
            "e": n.transpose(Image.ROTATE_270)}


# --------------------------------------------------------------------------- room props

def floor_switch(pressed):
    c = Canvas(16, 16)
    c.rect(1, 1, 14, 14, DFLOOR_DARK)
    c.rect(2, 2, 12, 12, DFLOOR_MID)
    if pressed:
        c.rect(4, 5, 8, 7, SWITCH_DOWN)
        c.rect(4, 5, 8, 1, INK)
    else:
        c.rect(4, 3, 8, 8, SWITCH_UP)
        c.rect(4, 3, 8, 1, GOLD)
        c.rect(4, 11, 8, 2, SWITCH_DOWN)
    return c


def push_block():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, DSTONE_MID)
    c.rect(0, 0, 16, 3, DSTONE_LIGHT)
    c.rect(0, 0, 2, 16, DSTONE_LIGHT)
    c.rect(0, 13, 16, 3, DSTONE_DARK)
    c.rect(14, 0, 2, 16, DSTONE_DARK)
    c.rect(5, 5, 6, 6, DSTONE_DARK)                         # carved square
    c.rect(6, 6, 4, 4, DSTONE_LIGHT)
    c.set(3, 11, MOSS)
    return c


def big_chest(opened):
    """32x24 big chest: dark wood, gold bands, a big lock."""
    c = Canvas(32, 24)
    c.rect(1, 9, 30, 13, CHEST_MID)
    c.rect(1, 19, 30, 3, CHEST_DARK)
    c.rect(1, 9, 2, 13, CHEST_LIGHT)
    if opened:
        c.rect(3, 4, 26, 6, CHEST_INSIDE)
        c.rect(1, 0, 30, 5, CHEST_DARK)
        c.rect(1, 0, 30, 1, CHEST_MID)
    else:
        c.rect(1, 1, 30, 9, CHEST_MID)
        c.rect(1, 1, 30, 2, CHEST_LIGHT)
        c.rect(1, 9, 30, 1, CHEST_DARK)
        c.rect(13, 6, 6, 7, GOLD)
        c.rect(15, 8, 2, 3, INK)
    for x in (5, 26):
        c.rect(x, 1 if not opened else 0, 2, 21 if not opened else 22, CHEST_BAND)
    c.outline(OUTLINE)
    out = Canvas(32, 24)
    out.paste(c)
    return out


def heavy_rock():
    """A big dark rock - only the power glove lifts it."""
    c = Canvas(16, 16)
    c.ellipse(7.5, 9, 7.5, 6.5, ROCK_DARK)
    c.ellipse(7, 8, 6.5, 5.5, ROCK_MID)
    c.ellipse(5, 6, 3, 2, ROCK_LIGHT)
    c.rect(9, 11, 4, 1, ROCK_DARK)
    c.set(3, 10, ROCK_DARK)
    c.outline(OUTLINE)
    out = Canvas(16, 16)
    out.ellipse(7.5, 14, 7, 1.5, SHADOW)
    out.paste(c)
    return out


def seal_pickup():
    """The family seal lying on the floor (16x16): violet stone in a gold ring, sparkling."""
    c = Canvas(16, 16)
    c.ellipse(7.5, 7.5, 7, 7, GOLD)
    c.ellipse(7.5, 7.5, 5, 5, SEAL_MID)
    c.ellipse(7.5, 8.5, 3.5, 3, SEAL_DARK)
    c.ellipse(6, 5.5, 1.8, 1.3, SEAL_LIGHT)
    c.set(11, 3, WHITE)
    c.outline(OUTLINE)
    return c


# --------------------------------------------------------------------------- icons (16x16)

def icon_map():
    c = Canvas(16, 16)
    c.poly([(1, 3), (6, 1), (10, 3), (15, 1), (15, 13), (10, 15), (6, 13), (1, 15)], MAP_PAPER)
    c.line((6, 1), (6, 13), MAP_INK)
    c.line((10, 3), (10, 15), MAP_INK)
    c.rect(3, 6, 2, 2, BIGDOOR_RED)
    c.line((4, 9), (12, 7), MAP_INK)
    c.outline(OUTLINE)
    return c


def icon_compass():
    c = Canvas(16, 16)
    c.ellipse(7.5, 7.5, 7, 7, GOLD)
    c.ellipse(7.5, 7.5, 5.5, 5.5, MAP_PAPER)
    c.poly([(7.5, 2.5), (9, 7.5), (6, 7.5)], BIGDOOR_RED)
    c.poly([(7.5, 12.5), (9, 7.5), (6, 7.5)], STEEL_MID)
    c.outline(OUTLINE)
    return c


def icon_big_key():
    c = Canvas(16, 16)
    c.ellipse(4.5, 4.5, 3.8, 3.8, KEY_MID)
    c.ellipse(4.5, 4.5, 1.6, 1.6, (0, 0, 0, 0))
    c.set(3, 2, KEY_LIGHT)
    c.line((7, 7), (14, 14), KEY_MID, 2)
    c.rect(10, 13, 2, 2, KEY_DARK)
    c.rect(12, 11, 2, 2, KEY_DARK)
    c.outline(OUTLINE)
    return c


def icon_glove():
    c = Canvas(16, 16)
    c.rect(4, 7, 9, 7, GLOVE_MID)                           # palm
    for i, x in enumerate((4, 6, 8, 10)):                   # fingers
        c.rect(x, 2 + (i % 2), 2, 6, GLOVE_MID)
        c.set(x, 2 + (i % 2), GLOVE_LIGHT)
    c.rect(12, 6, 3, 4, GLOVE_MID)                          # thumb
    c.rect(4, 13, 9, 2, GLOVE_DARK)                         # cuff
    c.rect(5, 9, 3, 2, GLOVE_LIGHT)
    c.outline(OUTLINE)
    return c


# --------------------------------------------------------------------------- boss

def grand_slime(squash, stretch, eyes="open", lift=0):
    """One Grand Slime frame: a big jelly dome with a golden core and two eyes."""
    w, h = BOSS_FRAME
    c = Canvas(w, h)
    fx, fy = BOSS_FEET
    rx, ry = 18 + squash, 14 + stretch
    cy = fy - ry - lift
    body = Canvas(w, h)
    body.ellipse(fx, cy, rx, ry, GSLIME_MID)
    body.rect(fx - rx, cy, rx * 2 + 1, ry, GSLIME_MID)     # flat base
    body.rect(fx - rx, cy + ry - 4, rx * 2 + 1, 4, GSLIME_DARK)          # darker jelly along the base
    body.ellipse(fx - 7, cy - ry // 2, 5, 3, GSLIME_LIGHT)               # shine
    body.ellipse(fx, cy + ry // 2 - 2, 3, 2.5, GSLIME_CORE)               # the core, deep in the jelly
    body.set(fx - 1, cy + ry // 2 - 3, WHITE)
    for ex in (fx - 7, fx + 5):
        if eyes == "open":
            body.rect(ex, cy - 3, 3, 4, INK)
            body.set(ex, cy - 3, WHITE)
        else:
            body.rect(ex, cy - 1, 3, 1, INK)
    body.outline(OUTLINE)
    if lift == 0:
        c.ellipse(fx, fy - 1, rx, 3, SHADOW)
    else:
        c.ellipse(fx, fy - 1, rx - lift // 2, 2, SHADOW)
    c.paste(body)
    return c


def boss_pack():
    idle = [grand_slime(0, 0), grand_slime(2, -2, "closed")]
    hop = [grand_slime(4, -4), grand_slime(-3, 4, lift=6), grand_slime(-2, 3, lift=10), grand_slime(5, -5)]
    save(pack_strip(idle), ENEMY_DIR, "grand_slime_idle.png")
    save(pack_strip(hop), ENEMY_DIR, "grand_slime_hop.png")
    meta = {"frame_size": list(BOSS_FRAME), "feet": list(BOSS_FEET),
            "anims": {"idle": {"fps": 3.0, "loop": True}, "hop": {"fps": 8.0, "loop": False}}}
    with open(os.path.join(ENEMY_DIR, "grand_slime.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(meta, f, indent=2)


def main():
    for kind in ("locked", "big", "shutter"):
        for side, im in door_sides(kind).items():
            save(im, OUT, "door_%s_%s.png" % (kind, side))
    save(pack_strip([floor_switch(False), floor_switch(True)]), OUT, "switch.png")
    save(push_block(), OUT, "push_block.png")
    save(pack_strip([big_chest(False), big_chest(True)]), OUT, "big_chest.png")
    save(heavy_rock(), OUT, "heavy_rock.png")
    save(seal_pickup(), OUT, "seal.png")
    save(icon_map(), ICONS, "map.png")
    save(icon_compass(), ICONS, "compass.png")
    save(icon_big_key(), ICONS, "big_key.png")
    save(icon_glove(), ICONS, "glove.png")
    boss_pack()
    pad = 4
    w = sum(im.width for im in SHOWN) + pad * (len(SHOWN) + 1)
    h = max(im.height for im in SHOWN) + 2 * pad
    sheet = Image.new("RGBA", (w, h), (90, 108, 98, 255))
    x = pad
    for im in SHOWN:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 3).save(PREVIEW)
    print("%d dungeon images written; preview %s" % (len(SHOWN), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
