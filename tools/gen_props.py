# File: gen_props.py
# Description: Generates liftable pots, pickups (heart, green/blue/red gems), HUD hearts + digits and one-shot effects (death puff, hit spark, sword glint, pot shards) with their manifest.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
#
# Run:  python -I tools/gen_props.py
# Writes assets/sprites/props/ (pot, heart, gem_*), assets/sprites/vfx/ (+ vfx_manifest.json read by the Juice
# autoload: {"<name>.png": {frame_size, fps, origin}}) and tmp/props_preview.png.
import json
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from palette import (GEM_B_DARK, GEM_B_LIGHT, GEM_B_MID, GEM_G_DARK, GEM_G_LIGHT, GEM_G_MID, GEM_R_DARK,
                     GEM_R_LIGHT, GEM_R_MID, HEART_LIGHT, HEART_RED, OUTLINE, POT_DARK, POT_LIGHT, POT_MID,
                     SHADOW, SMOKE_DARK, SMOKE_LIGHT, SMOKE_MID, SPARK_CORE, SPARK_EDGE, WHITE, INK)
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROP_DIR = os.path.join(ROOT, "assets", "sprites", "props")
VFX_DIR = os.path.join(ROOT, "assets", "sprites", "vfx")
PREVIEW = os.path.join(ROOT, "tmp", "props_preview.png")
SEED = 77
GEMS = {"green": (GEM_G_DARK, GEM_G_MID, GEM_G_LIGHT), "blue": (GEM_B_DARK, GEM_B_MID, GEM_B_LIGHT),
        "red": (GEM_R_DARK, GEM_R_MID, GEM_R_LIGHT)}


def pot():
    """16x16 clay pot standing on its tile (origin = tile centre), with a soft shadow."""
    c = Canvas(16, 16)
    c.ellipse(7.5, 9.5, 6, 5.5, POT_MID)
    c.ellipse(7.5, 12, 5, 2.5, POT_DARK)
    c.ellipse(5.5, 8, 2, 2.5, POT_LIGHT)
    c.rect(4, 2, 8, 3, POT_MID)                      # neck
    c.rect(3, 2, 10, 1, POT_LIGHT)                   # lip
    c.rect(5, 3, 6, 1, INK)                          # mouth opening
    c.outline(OUTLINE)
    out = Canvas(16, 16)
    out.ellipse(7.5, 14, 6, 1.6, SHADOW)
    out.paste(c)
    return out


def heart():
    """8x8 recovery heart."""
    c = Canvas(9, 8)
    for x, y in ((2, 1), (6, 1)):
        c.ellipse(x, y + 1, 2, 2, HEART_RED)
    c.poly([(0, 3), (8, 3), (4, 7)], HEART_RED)
    c.set(1, 2, HEART_LIGHT)
    c.set(2, 1, HEART_LIGHT)
    c.outline(OUTLINE)
    return c


def gem(colors, shine):
    """8x14 rupee-shaped gem; shine moves the highlight (2-frame twinkle)."""
    dark, mid, light = colors
    c = Canvas(10, 14)
    c.poly([(4.5, 0), (8, 3), (8, 9), (4.5, 12), (1, 9), (1, 3)], mid)
    c.poly([(4.5, 2), (6, 4), (6, 8), (4.5, 10), (3, 8), (3, 4)], light if shine else mid)
    c.rect(6, 4, 2, 5, dark)
    if shine:
        c.set(3, 3, WHITE)
    c.outline(OUTLINE)
    return c


def poof(i, n=5):
    """32x32 enemy death puff: white smoke balls that swell and thin out (ALttP style)."""
    c = Canvas(32, 32)
    t = i / (n - 1)
    r = 3 + t * 6
    for k in range(5):
        a = k * 2 * math.pi / 5 + 0.4
        d = 3 + t * 8
        x, y = 16 + math.cos(a) * d, 16 + math.sin(a) * d
        rr = r * (1.0 - 0.5 * t)
        c.ellipse(x, y, rr, rr, SMOKE_MID if t > 0.5 else SMOKE_LIGHT)
        c.ellipse(x - rr * 0.3, y - rr * 0.3, rr * 0.5, rr * 0.5, SMOKE_LIGHT)
    if i < 2:
        c.ellipse(16, 16, 5 - i * 2, 5 - i * 2, WHITE)
    c.outline(SMOKE_DARK)
    return c


def hit_spark(i):
    """16x16 star-shaped impact flash (3 frames)."""
    c = Canvas(16, 16)
    L = [7, 5, 3][i]
    for a in range(0, 360, 45):
        ln = L if a % 90 == 0 else L - 2
        for s in range(ln):
            c.set(8 + math.cos(math.radians(a)) * s, 8 + math.sin(math.radians(a)) * s, SPARK_EDGE if s > 1 else SPARK_CORE)
    c.ellipse(8, 8, 2 - i * 0.5, 2 - i * 0.5, SPARK_CORE)
    return c


def glint(i):
    """8x8 twinkle shown at the sword tip once a spin attack is charged."""
    c = Canvas(9, 9)
    L = [2, 4, 3][i]
    for s in range(-L, L + 1):
        c.set(4 + s, 4, SPARK_CORE if abs(s) < 2 else SPARK_EDGE)
        c.set(4, 4 + s, SPARK_CORE if abs(s) < 2 else SPARK_EDGE)
    return c


def shards(i, rng):
    """32x32 pot shards flying apart (4 frames)."""
    c = Canvas(32, 32)
    for k in range(7):
        a = k * 2 * math.pi / 7 + rng.uniform(-0.2, 0.2)
        d = 2 + i * 4
        x, y = 16 + math.cos(a) * d, 16 + math.sin(a) * d - i * 1.5 + i * i * 0.8
        col = (POT_MID, POT_LIGHT, POT_DARK)[k % 3]
        c.rect(x, y, 3 if i < 2 else 2, 2, col)
    c.outline(OUTLINE)
    return c


# 3x5 digit glyphs (rows top to bottom, 1 = ink) for the HUD counter.
DIGITS = ["111101101101111", "010110010010111", "111001111100111", "111001111001111", "101101111001001",
          "111100111001111", "111100111101111", "111001010010010", "111101111101111", "111101111001111"]


def hud_heart(fill):
    """9x8 HUD heart: fill 2 = full, 1 = left half, 0 = empty container."""
    c = Canvas(9, 8)
    for x, y in ((2, 1), (6, 1)):
        c.ellipse(x, y + 1, 2, 2, SMOKE_DARK)
    c.poly([(0, 3), (8, 3), (4, 7)], SMOKE_DARK)
    if fill:
        red = Canvas(9, 8)
        for x, y in ((2, 1), (6, 1)):
            red.ellipse(x, y + 1, 2, 2, HEART_RED)
        red.poly([(0, 3), (8, 3), (4, 7)], HEART_RED)
        red.set(1, 2, HEART_LIGHT)
        if fill == 1:
            red.rect(5, 0, 4, 8, (0, 0, 0, 0))
        c.paste(red)
    c.outline(OUTLINE)
    return c


def digit(d):
    """5x7 digit: a 3x5 white glyph with a dark outline, readable over any ground."""
    c = Canvas(5, 7)
    bits = DIGITS[d]
    for i, b in enumerate(bits):
        if b == "1":
            c.set(1 + i % 3, 1 + i // 3, WHITE)
    c.outline(OUTLINE)
    return c


def main():
    os.makedirs(PROP_DIR, exist_ok=True)
    os.makedirs(VFX_DIR, exist_ok=True)
    rows = []
    p = pot()
    p.img.save(os.path.join(PROP_DIR, "pot.png"))
    h = heart()
    h.img.save(os.path.join(PROP_DIR, "heart.png"))
    rows.append([p, h])
    for name, cols in GEMS.items():
        frames = [gem(cols, s) for s in (False, True)]
        pack_strip(frames).save(os.path.join(PROP_DIR, "gem_%s.png" % name))
        rows.append(frames)
    hearts = [hud_heart(f) for f in (2, 1, 0)]
    pack_strip(hearts).save(os.path.join(PROP_DIR, "hud_heart.png"))
    digits = [digit(d) for d in range(10)]
    pack_strip(digits).save(os.path.join(PROP_DIR, "digits.png"))
    rows.append(hearts)
    rows.append(digits)
    rng = random.Random(SEED)
    fx = {
        "poof": ([poof(i) for i in range(5)], (32, 32), 16.0),
        "hit_spark": ([hit_spark(i) for i in range(3)], (16, 16), 24.0),
        "glint": ([glint(i) for i in range(3)], (9, 9), 16.0),
        "shards": ([shards(i, rng) for i in range(4)], (32, 32), 14.0),
    }
    manifest = {}
    for name, (frames, size, fps) in fx.items():
        pack_strip(frames).save(os.path.join(VFX_DIR, name + ".png"))
        manifest[name + ".png"] = {"frame_size": list(size), "fps": fps, "origin": "center"}
        rows.append(frames)
    with open(os.path.join(VFX_DIR, "vfx_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    cell = 34
    sheet = Image.new("RGBA", (max(len(r) for r in rows) * cell, len(rows) * cell), (72, 160, 72, 255))
    for y, r in enumerate(rows):
        for x, fr in enumerate(r):
            sheet.alpha_composite(fr.img, (x * cell, y * cell))
    upscale(sheet, 4).save(PREVIEW)
    print("Props: pot, heart, 3 gems; vfx: %s" % ", ".join(fx))


if __name__ == "__main__":
    main()
