# File: gen_umbra.py
# Description: Generates the Phase 9 art - the grapple (icon, claw head, chain link), hook posts, the darkness masks (small light and lantern light), dimension crystals (pickup and menu sockets), and the enemy packs for the lurker and the Gloom Moth (with its dust shot) - plus a preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
#
# Run:  python -I tools/gen_umbra.py
# Writes assets/ui/items/grapple.png, assets/sprites/items/{grapple_head,chain,dust_shot}.png,
# assets/sprites/dungeon/{hook_post,crystal}.png, assets/ui/menu/crystal_{empty,full}.png,
# assets/sprites/world/darkness_{small,lantern}.png, the packs assets/sprites/enemies/{lurker,gloom_moth}.json +
# strips, and tmp/umbra_preview.png.
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
MENU = os.path.join(ROOT, "assets", "ui", "menu")
WORLD = os.path.join(ROOT, "assets", "sprites", "world")
ENEMIES = os.path.join(ROOT, "assets", "sprites", "enemies")
PREVIEW = os.path.join(ROOT, "tmp", "umbra_preview.png")
# Darkness masks: an opaque night with a soft round hole, drawn centred on Joe. Twice the view so the hole can sit
# anywhere on screen without the mask's edge showing.
MASK_SIZE = (768, 432)
LIGHT_SMALL = 30                  # px radius Joe sees without the lantern
LIGHT_LANTERN = 78                # px radius with the lantern
SOFT = 18                         # px of fade at the edge of the light
SHOWN = []


def save(img, folder, name):
    im = img.img if isinstance(img, Canvas) else img
    os.makedirs(folder, exist_ok=True)
    im.save(os.path.join(folder, name))
    if im.width <= 200:
        SHOWN.append(im)
    return im


def write_pack(name, frame, feet, anims):
    meta = {"frame_size": list(frame), "feet": list(feet), "anims": {}}
    for anim, (frames, fps, loop) in anims.items():
        save(pack_strip(frames), ENEMIES, "%s_%s.png" % (name, anim))
        meta["anims"][anim] = {"fps": fps, "loop": loop}
    with open(os.path.join(ENEMIES, name + ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(meta, f, indent=2)


def grapple_icon():
    c = Canvas(16, 16)
    for i in range(4):                                       # a coil of chain
        c.ellipse(4 + i * 2, 11 - i * 2, 2, 1.5, P.CHAIN_LIGHT)
        c.set(4 + i * 2, 11 - i * 2, P.CHAIN_DARK)
    c.poly([(11, 1), (15, 4), (12, 7), (10, 5)], P.CLAW_GOLD)    # the claw
    c.set(13, 3, P.WHITE)
    c.outline(P.OUTLINE)
    return c


def grapple_head():
    """Claw pointing right (the engine rotates it)."""
    c = Canvas(10, 10)
    c.rect(0, 4, 5, 2, P.CHAIN_LIGHT)
    c.poly([(4, 1), (9, 5), (4, 9), (6, 5)], P.CLAW_GOLD)
    c.set(7, 5, P.WHITE)
    c.outline(P.OUTLINE)
    return c


def chain_link():
    c = Canvas(4, 4)
    c.ellipse(1.5, 1.5, 1.6, 1.2, P.CHAIN_LIGHT)
    c.set(1, 1, P.CHAIN_DARK)
    return c


def hook_post():
    """A dark stake with an iron ring on top (solid, 16x16; the grapple latches onto it)."""
    c = Canvas(16, 16)
    c.rect(6, 6, 4, 10, P.POST_MID)
    c.rect(6, 6, 1, 10, P.POST_DARK)
    c.ellipse(7.5, 5, 4.5, 4, P.POST_RING)
    c.ellipse(7.5, 5, 2.5, 2, P.POST_DARK)
    c.rect(4, 14, 8, 2, P.POST_DARK)
    c.outline(P.OUTLINE)
    return c


def crystal(size=16, full=True):
    c = Canvas(size, size)
    m = size / 2 - 0.5
    if full:
        c.poly([(m, 0), (size - 3, m), (m, size - 1), (2, m)], P.CRYSTAL_MID)
        c.poly([(m, 1), (m + 3, m), (m, size - 3), (m - 3, m)], P.CRYSTAL_LIGHT)
        c.poly([(m, m), (size - 4, m), (m, size - 2)], P.CRYSTAL_DARK)
    else:
        c.poly([(m, 0), (size - 3, m), (m, size - 1), (2, m)], P.UI_RIM_DARK)
        c.poly([(m, 2), (size - 5, m), (m, size - 3), (4, m)], P.UI_WELL)
    c.outline(P.OUTLINE)
    return c


def darkness(radius):
    """The night with a soft hole of `radius` px in the middle."""
    w, h = MASK_SIZE
    img = Image.new("RGBA", (w, h), P.NIGHT)
    px = img.load()
    cx, cy = w / 2, h / 2
    reach = radius + SOFT
    for y in range(int(cy - reach - 1), int(cy + reach + 2)):
        for x in range(int(cx - reach - 1), int(cx + reach + 2)):
            d = math.hypot(x - cx, y - cy)
            if d <= radius:
                a = 0
            elif d >= reach:
                continue
            else:
                t = (d - radius) / SOFT                       # stepped fade keeps it pixel-art
                a = int(round(t * 4) / 4 * 255)
            px[x, y] = P.NIGHT[:3] + (a,)
    return img


def dust_shot():
    """One frame: EnemyShot draws a plain sprite."""
    c = Canvas(10, 10)
    c.ellipse(4.5, 4.5, 3.5, 3.5, P.MOTH_DUST)
    c.ellipse(4, 4, 1.5, 1.5, P.MOTH_LIGHT)
    c.set(6, 3, P.WHITE)
    return c


def lurker_frame(i, frozen=False):
    """A crouched shadow with two pale eyes (24x24, feet at (12,22))."""
    c = Canvas(24, 24)
    sway = (0, 1, 0, -1)[i % 4] if not frozen else 0
    body = Canvas(24, 24)
    body.ellipse(12 + sway, 14, 8, 8, P.LURKER_MID)
    body.ellipse(12 + sway, 17, 9, 5, P.LURKER_DARK)
    for x in (4, 8, 16, 20):                                 # wisps at the hem
        body.rect(x + sway, 20, 2, 2 + (x + i) % 3, P.LURKER_DARK)
    eye = P.LURKER_EYE if not frozen else P.UI_RIM_DARK
    body.rect(9 + sway, 11, 2, 2, eye)
    body.rect(14 + sway, 11, 2, 2, eye)
    body.outline(P.OUTLINE)
    c.ellipse(12, 22, 7, 1.5, P.SHADOW)
    c.paste(body)
    return c


def moth_frame(i, grounded=False):
    """The Gloom Moth: a fat body and four ragged wings (64x56, feet at (32,52)); grounded = wings folded."""
    c = Canvas(64, 56)
    cx = 32
    lift = 0 if grounded else 14 + (0, 2, 4, 2)[i % 4]
    cy = 52 - 12 - lift
    body = Canvas(64, 56)
    flap = (0, 4, 8, 4)[i % 4] if not grounded else 10
    for side in (-1, 1):
        top = [(cx, cy - 2), (cx + side * 28, cy - 16 + flap), (cx + side * 22, cy + 4)]
        low = [(cx, cy + 2), (cx + side * 20, cy + 14 - flap // 2), (cx + side * 8, cy + 12)]
        body.poly(top, P.MOTH_MID)
        body.poly(low, P.MOTH_DARK)
        body.ellipse(cx + side * 16, cy - 6 + flap // 2, 4, 3, P.MOTH_LIGHT)    # eye spots on the wings
        body.ellipse(cx + side * 16, cy - 6 + flap // 2, 2, 1.5, P.MOTH_EYE)
    body.ellipse(cx, cy + 3, 5, 10, P.MOTH_DARK)
    body.ellipse(cx, cy - 6, 4, 4, P.MOTH_MID)
    body.set(cx - 2, cy - 7, P.MOTH_EYE)
    body.set(cx + 2, cy - 7, P.MOTH_EYE)
    body.line((cx - 2, cy - 9), (cx - 6, cy - 15), P.MOTH_LIGHT)    # antennae
    body.line((cx + 2, cy - 9), (cx + 6, cy - 15), P.MOTH_LIGHT)
    body.outline(P.OUTLINE)
    c.ellipse(cx, 52, 14 - lift // 3, 3, P.SHADOW)
    c.paste(body)
    return c


def main():
    save(grapple_icon(), ICONS, "grapple.png")
    save(grapple_head(), ITEMS, "grapple_head.png")
    save(chain_link(), ITEMS, "chain.png")
    save(hook_post(), DUNGEON, "hook_post.png")
    save(crystal(), DUNGEON, "crystal.png")
    save(crystal(14, True), MENU, "crystal_full.png")
    save(crystal(14, False), MENU, "crystal_empty.png")
    save(dust_shot(), ITEMS, "dust_shot.png")
    save(darkness(LIGHT_SMALL), WORLD, "darkness_small.png")
    save(darkness(LIGHT_LANTERN), WORLD, "darkness_lantern.png")
    write_pack("lurker", (24, 24), (12, 22), {"creep": ([lurker_frame(i) for i in range(4)], 8.0, True),
                                             "frozen": ([lurker_frame(0, True)], 1.0, False)})
    write_pack("gloom_moth", (64, 56), (32, 52), {"fly": ([moth_frame(i) for i in range(4)], 10.0, True),
                                                 "grounded": ([moth_frame(0, True)], 1.0, False)})
    pad = 4
    w = sum(im.width for im in SHOWN) + pad * (len(SHOWN) + 1)
    h = max(im.height for im in SHOWN) + 2 * pad
    sheet = Image.new("RGBA", (w, h), (70, 60, 80, 255))
    x = pad
    for im in SHOWN:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 2).save(PREVIEW)
    print("umbra art written (%d previewed); preview %s" % (len(SHOWN), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
