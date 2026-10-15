# File: gen_enemies.py
# Description: Generates the Phase 2 enemy sprite packs (jelly slime, Caver's cursed guard, rock-spitter) and the spitter's rock.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
#
# Run:  python -I tools/gen_enemies.py   (writes assets/sprites/enemies/ and tmp/enemies_preview.png)
#
# Each pack is `<pack>.json` ({frame_size, feet, anims: {name: {fps, loop}}}) plus `<pack>_<anim>.png` strips,
# the format SpriteStrips.load_pack() reads. Directional packs use `<anim>_down|up|side` (left = mirrored side).
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from palette import (CAVER_DARK, CAVER_LIGHT, CAVER_RED, OUTLINE, ROCK_DARK, ROCK_LIGHT, ROCK_MID, SHADOW,
                     SKIN_DARK, SKIN_MID, SLIME_DARK, SLIME_LIGHT, SLIME_MID, SPIT_DARK, SPIT_LIGHT, SPIT_MID,
                     STEEL_DARK, STEEL_LIGHT, STEEL_MID, WHITE, BOOT_DARK, PANTS_DARK, HILT_DARK, INK)
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "enemies")
PREVIEW = os.path.join(ROOT, "tmp", "enemies_preview.png")
DIRS = ("down", "up", "side")


# --------------------------------------------------------------------------- slime

SLIME_FRAME = 24
SLIME_FEET = (12, 20)
# (body width radius, body height radius, lift off the ground) per frame.
SLIME_IDLE = [(6.5, 5.0, 0), (7.0, 4.5, 0)]
SLIME_HOP = [(7.5, 3.8, 0), (5.5, 6.5, 3), (6.0, 5.8, 6), (7.5, 4.0, 0)]


def slime_frame(rx, ry, lift):
    """Blue gel blob with a shine and two dark eyes; the shadow stays on the ground when it hops."""
    c = Canvas(SLIME_FRAME, SLIME_FRAME)
    fx, fy = SLIME_FEET
    cy = fy - ry - lift
    c.ellipse(fx, cy, rx, ry, SLIME_MID)
    c.ellipse(fx, cy + ry * 0.45, rx * 0.9, ry * 0.45, SLIME_DARK)
    c.ellipse(fx - rx * 0.35, cy - ry * 0.4, rx * 0.3, ry * 0.25, SLIME_LIGHT)
    c.set(fx - 2, cy, INK)
    c.set(fx + 2, cy, INK)
    c.set(fx - 2, cy - 1, INK)
    c.set(fx + 2, cy - 1, INK)
    c.outline(OUTLINE)
    sh = Canvas(SLIME_FRAME, SLIME_FRAME)
    sh.ellipse(fx, fy - 1, rx - lift * 0.3, 1.8, SHADOW)
    sh.paste(c)
    return sh


# --------------------------------------------------------------------------- guard

GUARD_FRAME = 32
GUARD_FEET = (16, 28)
GUARD_WALK = [(0, 0, 0), (2, 0, -1), (0, 0, 0), (0, 2, -1)]       # (left lift, right lift, bob)


def guard_frame(facing, lift_l, lift_r, bob):
    """Caver's cursed village guard: steel helmet with a red plume, Caver-red tabard, spear held upright."""
    c = Canvas(GUARD_FRAME, GUARD_FRAME)
    cx, fy = GUARD_FEET
    fb = fy + bob
    # Legs.
    if facing == "side":
        for dx, lft, col in ((-2, lift_l, PANTS_DARK), (1, lift_r, STEEL_DARK)):
            c.rect(cx + dx - 1, fy - 6, 3, 4 - lft, col)
            c.rect(cx + dx - 1, fy - 2 - lft, 4, 2, BOOT_DARK)
    else:
        for x0, lft in ((cx - 4, lift_l), (cx + 1, lift_r)):
            c.rect(x0, fy - 6, 3, 4 - lft, STEEL_DARK)
            c.rect(x0, fy - 2 - lft, 3, 2, BOOT_DARK)
    # Spear (behind the body when facing up).
    sx = cx + 7 if facing != "up" else cx - 8
    if facing == "side":
        sx = cx + 5
    spear = Canvas(GUARD_FRAME, GUARD_FRAME)
    spear.rect(sx, fb - 24, 1, 22, HILT_DARK)
    spear.rect(sx - 1, fb - 27, 3, 3, STEEL_LIGHT)
    spear.set(sx, fb - 28, STEEL_LIGHT)
    if facing == "up":
        c.paste(spear)
    # Body: mail shirt with a Caver-red tabard (front) or plain mail (back).
    w = 10 if facing != "side" else 8
    c.rect(cx - w // 2, fb - 14, w, 9, STEEL_MID)
    c.rect(cx - w // 2, fb - 14, 1, 9, STEEL_LIGHT)
    if facing != "up":
        tx = cx - 3 if facing == "down" else cx - 2
        c.rect(tx, fb - 13, 6, 9, CAVER_RED)
        c.rect(tx, fb - 13, 6, 1, CAVER_LIGHT)
        c.rect(tx + 2, fb - 11, 2, 2, CAVER_DARK)            # Caver's sigil
    else:
        c.rect(cx - 4, fb - 13, 8, 2, CAVER_RED)             # tabard straps seen from behind
    # Arms.
    if facing == "side":
        c.rect(cx + 2, fb - 13, 2, 6, STEEL_DARK)
        c.rect(cx + 3, fb - 8, 2, 2, SKIN_MID)
    else:
        c.rect(cx - 7, fb - 13, 2, 6, STEEL_DARK)
        c.rect(cx + 5, fb - 13, 2, 6, STEEL_DARK)
        c.rect(cx - 7, fb - 8, 2, 2, SKIN_MID)
        c.rect(cx + 5, fb - 8, 2, 2, SKIN_MID)
    # Head: round steel helmet with a dark visor slit and a red plume.
    hy = fb - 19
    c.ellipse(cx - 0.5, hy, 5.8, 5.2, STEEL_MID)
    c.ellipse(cx - 2, hy - 2, 2.2, 1.6, STEEL_LIGHT)
    if facing == "down":
        c.rect(cx - 4, hy + 1, 8, 2, INK)
        c.set(cx - 2, hy + 1, CAVER_LIGHT)                   # glowing cursed eyes
        c.set(cx + 1, hy + 1, CAVER_LIGHT)
        c.rect(cx - 3, hy + 3, 6, 1, SKIN_DARK)
    elif facing == "side":
        c.rect(cx + 1, hy + 1, 5, 2, INK)
        c.set(cx + 3, hy + 1, CAVER_LIGHT)
    c.rect(cx - 1, hy - 8, 2, 3, CAVER_RED)
    c.rect(cx - 2 if facing != "side" else cx - 3, hy - 9, 3, 2, CAVER_LIGHT)
    if facing != "up":
        c.paste(spear)
    c.outline(OUTLINE)
    sh = Canvas(GUARD_FRAME, GUARD_FRAME)
    sh.ellipse(cx, fy - 1, 7, 2.2, SHADOW)
    sh.paste(c)
    return sh


# --------------------------------------------------------------------------- spitter

SPIT_FRAME = 24
SPIT_FEET = (12, 21)


def spitter_frame(facing, step, spitting):
    """Round shelled critter with a snout pointing where it faces; `spitting` stretches the snout."""
    c = Canvas(SPIT_FRAME, SPIT_FRAME)
    fx, fy = SPIT_FEET
    cy = fy - 7 - (1 if step else 0)
    # Little legs (alternate on step).
    for dx in (-5, -2, 2, 5):
        down = 1 if ((dx < 0) == bool(step)) else 0
        c.rect(fx + dx - 1, fy - 3 + down, 2, 2, SPIT_DARK)
    c.ellipse(fx, cy, 7, 6.2, SPIT_MID)
    c.ellipse(fx, cy + 3, 6.5, 2.8, SPIT_DARK)
    c.ellipse(fx - 2.5, cy - 3, 2.4, 1.6, SPIT_LIGHT)
    snout = 4 if spitting else 2
    if facing == "down":
        c.rect(fx - 2, cy + 3, 4, snout + 1, SPIT_LIGHT)
        c.rect(fx - 1, cy + 3 + snout, 2, 1, INK)
        for ex in (fx - 4, fx + 3):
            c.rect(ex, cy - 1, 2, 2, WHITE)
            c.set(ex + (1 if ex > fx else 0), cy, INK)
    elif facing == "up":
        c.rect(fx - 2, cy - 7 - snout + 2, 4, snout + 1, SPIT_LIGHT)
        c.ellipse(fx, cy - 1, 4, 3, SPIT_DARK)                 # shell ridge from behind
    else:
        c.rect(fx + 6, cy - 1, snout + 1, 4, SPIT_LIGHT)
        c.rect(fx + 6 + snout, cy, 1, 2, INK)
        c.rect(fx + 2, cy - 3, 2, 2, WHITE)
        c.set(fx + 3, cy - 2, INK)
    c.outline(OUTLINE)
    sh = Canvas(SPIT_FRAME, SPIT_FRAME)
    sh.ellipse(fx, fy - 1, 7, 2, SHADOW)
    sh.paste(c)
    return sh


def rock_frame(i):
    """The spitter's rock: a small grey stone that tumbles (2 frames)."""
    c = Canvas(10, 10)
    c.ellipse(4.5, 4.5, 3.6, 3.2, ROCK_MID)
    hx, hy = (3, 3) if i == 0 else (5, 3)
    c.ellipse(hx, hy, 1.2, 1.0, ROCK_LIGHT)
    c.set(6 - hx + 2, 6, ROCK_DARK)
    c.outline(OUTLINE)
    return c


# --------------------------------------------------------------------------- packs

def write_pack(name, frame, feet, anims):
    """anims: {anim: (frames list, fps, loop)} -> strips + manifest."""
    manifest = {"frame_size": [frame, frame], "feet": list(feet), "anims": {}}
    for anim, (frames, fps, loop) in anims.items():
        pack_strip(frames).save(os.path.join(OUT_DIR, "%s_%s.png" % (name, anim)))
        manifest["anims"][anim] = {"fps": fps, "loop": loop}
    with open(os.path.join(OUT_DIR, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    return [frames for frames, _, _ in anims.values()]


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    rows = []
    rows += write_pack("slime", SLIME_FRAME, SLIME_FEET, {
        "idle": ([slime_frame(*p) for p in SLIME_IDLE], 3.0, True),
        "hop": ([slime_frame(*p) for p in SLIME_HOP], 10.0, False),
    })
    guard = {}
    for d in DIRS:
        guard["walk_" + d] = ([guard_frame(d, *w) for w in GUARD_WALK], 6.0, True)
    rows += write_pack("guard", GUARD_FRAME, GUARD_FEET, guard)
    spit = {}
    for d in DIRS:
        spit["walk_" + d] = ([spitter_frame(d, s, False) for s in (0, 1)], 6.0, True)
        spit["spit_" + d] = ([spitter_frame(d, 0, True)], 1.0, False)
    rows += write_pack("spitter", SPIT_FRAME, SPIT_FEET, spit)
    rocks = [rock_frame(i) for i in range(2)]
    pack_strip(rocks).save(os.path.join(OUT_DIR, "rock.png"))
    rows.append(rocks)
    # Preview sheet.
    cell = 32
    width = max(len(r) for r in rows) * cell
    sheet = Image.new("RGBA", (width, len(rows) * cell), (72, 160, 72, 255))
    for y, r in enumerate(rows):
        for x, fr in enumerate(r):
            sheet.alpha_composite(fr.img, (x * cell, y * cell))
    upscale(sheet, 4).save(PREVIEW)
    print("Enemies: slime, guard, spitter packs + rock written")


if __name__ == "__main__":
    main()
