# File: gen_items.py
# Description: Generates the Phase 5 item art - menu/HUD icons (boomerang, bow, bombs, lantern, ammo counters, heart-piece quarters), world sprites (chest, boomerang, arrow, bomb, torch, cracked rock, key block, heart piece, heart container, small key) and effects (explosion, flame) with their manifests.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
#
# Run:  python -I tools/gen_items.py
# Writes assets/ui/items/<item>.png (16x16 icons, read by the HUD box and the item menu), assets/ui/hud/bomb_small.png,
# arrow_small.png, assets/ui/menu/heart_pieces.png, assets/sprites/items/*.png, assets/sprites/vfx/explosion.png,
# flame.png + vfx_items.json (read by Juice next to vfx_manifest.json) and tmp/items_preview.png.
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from palette import (ARROW_FLETCH, ARROW_SHAFT, BLAST_CORE, BLAST_DARK, BLAST_HOT, BLAST_MID, BOMB_DARK, BOMB_LIGHT,
                     BOMB_MID, BOOM_DARK, BOOM_FLASH, BOOM_LIGHT, BOOM_MID, BOOM_TIP, BOW_DARK, BOW_MID, BOW_STRING,
                     CHEST_BAND, CHEST_DARK, CHEST_INSIDE, CHEST_LIGHT, CHEST_MID, CRACK, FLAME_CORE, FLAME_EDGE,
                     FLAME_MID, FUSE, HEART_LIGHT, HEART_RED, KEY_DARK, KEY_LIGHT, KEY_MID, LANTERN_BRASS,
                     LANTERN_DARK, LANTERN_GLASS, OUTLINE, ROCK_DARK, ROCK_LIGHT, ROCK_MID, SHADOW, STEEL_LIGHT,
                     STEEL_MID, STONE_DARK, STONE_LIGHT, STONE_MID, UI_WELL, WHITE, INK)
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = os.path.join(ROOT, "assets", "ui", "items")
HUD_DIR = os.path.join(ROOT, "assets", "ui", "hud")
MENU_DIR = os.path.join(ROOT, "assets", "ui", "menu")
ITEM_DIR = os.path.join(ROOT, "assets", "sprites", "items")
VFX_DIR = os.path.join(ROOT, "assets", "sprites", "vfx")
PREVIEW = os.path.join(ROOT, "tmp", "items_preview.png")
EXPLOSION_FRAME = 48
EXPLOSION_FRAMES = 7
FLAME_FRAMES = 4

IMAGES = []                         # (label, PIL image) for the preview


def save(img, folder, name):
    im = img.img if isinstance(img, Canvas) else img
    os.makedirs(folder, exist_ok=True)
    im.save(os.path.join(folder, name))
    IMAGES.append(im)
    return im


# --------------------------------------------------------------------------- shapes

def boomerang(c, cx, cy, angle):
    """An L-shaped boomerang (the elbow at the lower left, arms to the right and up) centred on (cx, cy),
    rotated by `angle` degrees; red tips, a highlight along the upper edges."""
    a = math.radians(angle - 45)

    def rot(px, py):
        return (cx + px * math.cos(a) - py * math.sin(a), cy + px * math.sin(a) + py * math.cos(a))
    elbow, right, up = rot(-2, 2), rot(5, 2), rot(-2, -5)
    c.line(elbow, right, BOOM_MID, 3)
    c.line(elbow, up, BOOM_MID, 3)
    c.line(rot(-1, 1), rot(4, 1), BOOM_LIGHT)
    c.set(*elbow, BOOM_DARK)
    for tip in (right, up):
        c.rect(tip[0] - 1, tip[1] - 1, 2, 2, BOOM_TIP)


def bomb(c, cx, cy, flash=False):
    body = BOOM_FLASH if flash else BOMB_MID
    c.ellipse(cx, cy, 5, 5, body)
    c.ellipse(cx + 1, cy + 1, 3.5, 3.5, BOMB_DARK if not flash else BLAST_DARK)
    c.ellipse(cx - 2, cy - 2, 1.5, 1.2, BOMB_LIGHT if not flash else BLAST_HOT)
    c.rect(cx - 1, cy - 7, 3, 2, STONE_MID)                 # cap
    c.line((cx, cy - 7), (cx + 2, cy - 9), FUSE)
    c.set(cx + 3, cy - 10, FLAME_CORE)


def bow(c):
    """Bow icon: a thick curved limb from lower-left to upper-right bulging away from a taut string."""
    p0, p1 = (3, 13), (13, 3)
    pts = []
    for i in range(13):
        t = i / 12
        bx, by = p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t
        k = 4.5 * math.sin(t * math.pi)                      # bulge toward the upper-left
        pts.append((bx - k * 0.7, by - k * 0.7))
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        c.line((x0, y0), (x1, y1), BOW_MID, 2)
    c.line(p0, p1, BOW_STRING)
    mid = pts[6]
    c.rect(mid[0] - 1, mid[1] - 1, 3, 3, BOW_DARK)            # leather grip
    c.set(p0[0], p0[1], BOW_DARK)
    c.set(p1[0], p1[1], BOW_DARK)


def lantern(c, cx, cy):
    c.rect(cx - 4, cy - 3, 8, 8, LANTERN_BRASS)
    c.rect(cx - 3, cy - 2, 6, 6, LANTERN_GLASS)
    c.rect(cx - 1, cy - 1, 2, 3, FLAME_MID)
    c.set(cx - 1, cy - 1, FLAME_CORE)
    c.rect(cx - 5, cy + 5, 10, 2, LANTERN_DARK)
    c.rect(cx - 3, cy - 5, 6, 2, LANTERN_DARK)
    c.line((cx - 3, cy - 6), (cx, cy - 8), LANTERN_DARK)
    c.line((cx, cy - 8), (cx + 3, cy - 6), LANTERN_DARK)


def heart_shape(c, ox, oy, fill_quarters=4, w=12, h=11):
    """Heart; with fill_quarters < 4 only those quarters are red (the others are an empty well)."""
    tmp = Canvas(w, h)
    tmp.ellipse(3, 3, 3, 3, HEART_RED)
    tmp.ellipse(w - 4, 3, 3, 3, HEART_RED)
    tmp.poly([(0, 4), (w - 1, 4), (w // 2, h - 1)], HEART_RED)
    for y in range(h):
        for x in range(w):
            if tmp.px[x, y][3]:
                q = (0 if y < h / 2 else 2) + (0 if x < w / 2 else 1)
                order = [0, 1, 3, 2]                         # quarters fill clockwise from top-left
                if order.index(q) >= fill_quarters:
                    tmp.px[x, y] = UI_WELL
    tmp.set(2, 2, HEART_LIGHT if fill_quarters > 0 else UI_WELL)
    tmp.set(3, 1, HEART_LIGHT if fill_quarters > 0 else UI_WELL)
    tmp.outline(OUTLINE)
    c.paste(tmp, ox, oy)


# --------------------------------------------------------------------------- icons

def icon(draw):
    c = Canvas(16, 16)
    draw(c)
    c.outline(OUTLINE)
    return c


def icons():
    save(icon(lambda c: boomerang(c, 8, 8, 0)), ICON_DIR, "boomerang.png")
    save(icon(bow), ICON_DIR, "bow.png")
    save(icon(lambda c: bomb(c, 7, 9)), ICON_DIR, "bombs.png")
    save(icon(lambda c: lantern(c, 8, 8)), ICON_DIR, "lantern.png")
    small_bomb = Canvas(8, 9)
    small_bomb.ellipse(3.5, 5, 3, 3, BOMB_MID)
    small_bomb.set(2, 4, BOMB_LIGHT)
    small_bomb.rect(3, 1, 2, 1, FUSE)
    small_bomb.outline(OUTLINE)
    save(small_bomb, HUD_DIR, "bomb_small.png")
    small_arrow = Canvas(9, 9)
    small_arrow.line((1, 7), (7, 1), ARROW_SHAFT)
    small_arrow.poly([(5, 1), (7, 1), (7, 3)], STEEL_LIGHT)
    small_arrow.set(1, 6, ARROW_FLETCH)
    small_arrow.set(2, 7, ARROW_FLETCH)
    small_arrow.outline(OUTLINE)
    save(small_arrow, HUD_DIR, "arrow_small.png")
    frames = []
    for q in range(4):
        c = Canvas(14, 13)
        heart_shape(c, 1, 1, q)
        frames.append(c)
    save(pack_strip(frames), MENU_DIR, "heart_pieces.png")


# --------------------------------------------------------------------------- world sprites

def chest(open_):
    c = Canvas(16, 16)
    c.rect(1, 6, 14, 9, CHEST_MID)                          # box
    c.rect(1, 13, 14, 2, CHEST_DARK)
    c.rect(1, 6, 1, 9, CHEST_LIGHT)
    if open_:
        c.rect(2, 3, 12, 4, CHEST_INSIDE)                    # open mouth, lid tipped back
        c.rect(1, 1, 14, 3, CHEST_DARK)
        c.rect(1, 1, 14, 1, CHEST_MID)
    else:
        c.rect(1, 2, 14, 5, CHEST_MID)                       # lid
        c.rect(1, 2, 14, 1, CHEST_LIGHT)
        c.rect(1, 6, 14, 1, CHEST_DARK)
        c.rect(7, 5, 2, 3, CHEST_BAND)                       # lock
        c.set(7, 7, INK)
    for x in (3, 12):
        c.rect(x, 2 if not open_ else 1, 1, 13 if not open_ else 14, CHEST_BAND)
    c.outline(OUTLINE)
    return c


def boomerang_spin():
    frames = []
    for i in range(4):
        c = Canvas(14, 14)
        boomerang(c, 7, 7, i * 90)
        c.outline(OUTLINE)
        frames.append(c)
    return pack_strip(frames)


def arrow():
    """Arrow flying right (the engine rotates it)."""
    c = Canvas(16, 7)
    c.rect(2, 3, 10, 1, ARROW_SHAFT)
    c.poly([(11, 1), (15, 3), (11, 5)], STEEL_MID)
    c.set(12, 3, STEEL_LIGHT)
    c.rect(0, 2, 3, 1, ARROW_FLETCH)
    c.rect(0, 4, 3, 1, ARROW_FLETCH)
    c.outline(OUTLINE)
    return c


def bomb_strip():
    frames = []
    for flash in (False, True):
        c = Canvas(16, 18)
        bomb(c, 8, 11, flash)
        c.outline(OUTLINE)
        out = Canvas(16, 18)
        out.ellipse(8, 16, 5, 1.5, SHADOW)
        out.paste(c)
        frames.append(out)
    return pack_strip(frames)


def torch(lit_frame):
    """Stone torch post with an iron bowl; lit_frame None = unlit, else 0..2 flame frames."""
    c = Canvas(16, 24)
    c.rect(4, 12, 8, 11, STONE_MID)
    c.rect(4, 12, 2, 11, STONE_LIGHT)
    c.rect(10, 12, 2, 11, STONE_DARK)
    c.rect(3, 20, 10, 3, STONE_DARK)
    c.rect(2, 9, 12, 3, STONE_DARK)                          # bowl
    c.rect(3, 9, 10, 1, STONE_MID)
    if lit_frame is not None:
        sway = (-1, 0, 1)[lit_frame]
        c.poly([(4, 9), (12, 9), (8 + sway, 0)], FLAME_EDGE)
        c.poly([(5, 9), (11, 9), (8 + sway, 2)], FLAME_MID)
        c.poly([(6, 9), (10, 9), (8 - sway, 5)], FLAME_CORE)
    c.outline(OUTLINE)
    return c


def cracked_rock():
    c = Canvas(16, 16)
    c.ellipse(7.5, 8.5, 7, 6.5, ROCK_MID)
    c.ellipse(6, 6.5, 4, 3, ROCK_LIGHT)
    c.ellipse(9, 11.5, 5, 2.5, ROCK_DARK)
    for p0, p1 in (((4, 3), (7, 8)), ((7, 8), (5, 13)), ((7, 8), (12, 6)), ((12, 6), (13, 10))):
        c.line(p0, p1, CRACK)
    c.outline(OUTLINE)
    return c


def key_block():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, STONE_MID)
    c.rect(0, 0, 16, 2, STONE_LIGHT)
    c.rect(0, 0, 2, 16, STONE_LIGHT)
    c.rect(0, 14, 16, 2, STONE_DARK)
    c.rect(14, 0, 2, 16, STONE_DARK)
    c.ellipse(7.5, 6, 2.2, 2.2, INK)                         # keyhole
    c.poly([(6, 7), (9, 7), (10, 11), (5, 11)], INK)
    c.set(7, 5, KEY_MID)
    return c


def heart_piece():
    c = Canvas(14, 13)
    heart_shape(c, 1, 1, 1)
    return c


def heart_container():
    c = Canvas(16, 15)
    heart_shape(c, 1, 1, 4, 14, 13)
    c.set(4, 3, WHITE)
    return c


def small_key():
    c = Canvas(9, 14)
    c.ellipse(4, 3.5, 3.4, 3.2, KEY_MID)
    c.ellipse(4, 3.5, 1.4, 1.2, (0, 0, 0, 0))
    c.set(3, 1, KEY_LIGHT)
    c.rect(4, 6, 1, 7, KEY_MID)
    c.rect(5, 10, 2, 1, KEY_DARK)
    c.rect(5, 12, 2, 1, KEY_DARK)
    c.outline(OUTLINE)
    return c


# --------------------------------------------------------------------------- effects

def explosion():
    frames = []
    r_out = [6, 13, 19, 22, 23, 23, 22]
    for i in range(EXPLOSION_FRAMES):
        c = Canvas(EXPLOSION_FRAME, EXPLOSION_FRAME)
        m = EXPLOSION_FRAME / 2 - 0.5
        r = r_out[i]
        fade = i >= 4
        c.ellipse(m, m, r, r, BLAST_DARK if fade else BLAST_MID)
        if i < 6:
            c.ellipse(m, m, r * 0.75, r * 0.75, BLAST_MID if fade else BLAST_HOT)
        if i < 4:
            c.ellipse(m, m, r * 0.45, r * 0.45, BLAST_CORE)
        if fade:                                             # smoke breaking up: punch holes
            for k in range(10 + i * 4):
                a = k * 2.399
                rr = (k % 7) / 7 * r
                c.ellipse(m + math.cos(a) * rr, m + math.sin(a) * rr, 2 + i - 4, 2 + i - 4, (0, 0, 0, 0))
        frames.append(c)
    return pack_strip(frames)


def flame():
    frames = []
    for i in range(FLAME_FRAMES):
        c = Canvas(16, 16)
        h = (12, 14, 12, 8)[i]
        c.poly([(3, 15), (13, 15), (8, 15 - h)], FLAME_EDGE)
        c.poly([(5, 15), (11, 15), (8, 17 - h)], FLAME_MID)
        c.poly([(6, 15), (10, 15), (8, 19 - h)], FLAME_CORE)
        frames.append(c)
    return pack_strip(frames)


def main():
    icons()
    save(pack_strip([chest(False), chest(True)]), ITEM_DIR, "chest.png")
    save(boomerang_spin(), ITEM_DIR, "boomerang_spin.png")
    save(arrow(), ITEM_DIR, "arrow.png")
    save(bomb_strip(), ITEM_DIR, "bomb.png")
    save(torch(None), ITEM_DIR, "torch_unlit.png")
    save(pack_strip([torch(i) for i in range(3)]), ITEM_DIR, "torch_lit.png")
    save(cracked_rock(), ITEM_DIR, "cracked_rock.png")
    save(key_block(), ITEM_DIR, "key_block.png")
    save(heart_piece(), ITEM_DIR, "heart_piece.png")
    save(heart_container(), ITEM_DIR, "heart_container.png")
    save(small_key(), ITEM_DIR, "small_key.png")
    save(explosion(), VFX_DIR, "explosion.png")
    save(flame(), VFX_DIR, "flame.png")
    manifest = {
        "explosion.png": {"frame_size": [EXPLOSION_FRAME, EXPLOSION_FRAME], "fps": 18.0, "origin": "center"},
        "flame.png": {"frame_size": [16, 16], "fps": 12.0, "origin": "center"},
    }
    with open(os.path.join(VFX_DIR, "vfx_items.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, indent=1)
    # Preview: everything in a row on grass green, 3x.
    pad = 4
    w = sum(im.width for im in IMAGES) + pad * (len(IMAGES) + 1)
    h = max(im.height for im in IMAGES) + 2 * pad
    sheet = Image.new("RGBA", (w, h), (72, 160, 72, 255))
    x = pad
    for im in IMAGES:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 3).save(PREVIEW)
    print("%d item images written; preview %s" % (len(IMAGES), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
