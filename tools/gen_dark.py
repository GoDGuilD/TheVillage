# File: gen_dark.py
# Description: Generates the Dark World art - the Dark World tile atlas (the Light World atlas recoloured through an explicit palette map plus a dusky fallback for every other colour), the dream rift and mirror portal animations, and the Moon Mirror icon - plus a side-by-side preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.2.0
#
# Run AFTER gen_tiles.py:  python -I tools/gen_dark.py
# Writes assets/tiles/overworld_dark.png (same cells and manifest as overworld_light.json), assets/sprites/world/
# rift.png, portal.png, assets/ui/items/moon_mirror.png and tmp/dark_preview.png.
# The Dark World is the same land as Caver dreams it: shapes stay, colours rot (ALttP's Dark World recolour).
import colorsys
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import palette as P
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIGHT = os.path.join(ROOT, "assets", "tiles", "overworld_light.png")
DARK = os.path.join(ROOT, "assets", "tiles", "overworld_dark.png")
WORLD = os.path.join(ROOT, "assets", "sprites", "world")
ICONS = os.path.join(ROOT, "assets", "ui", "items")
PREVIEW = os.path.join(ROOT, "tmp", "dark_preview.png")

# Exact recolours for the Light World's signature colours.
MAP = {
    P.GRASS_DARK: P.DW_GRASS_DARK, P.GRASS_MID: P.DW_GRASS_MID, P.GRASS_LIGHT: P.DW_GRASS_LIGHT,
    P.GRASS_HILITE: P.DW_GRASS_HILITE, P.DIRT_DARK: P.DW_DIRT_DARK, P.DIRT_MID: P.DW_DIRT_MID,
    P.DIRT_LIGHT: P.DW_DIRT_LIGHT, P.LEAF_DARK: P.DW_LEAF_DARK, P.LEAF_MID: P.DW_LEAF_MID,
    P.LEAF_LIGHT: P.DW_LEAF_LIGHT, P.LEAF_HILITE: P.DW_LEAF_LIGHT, P.WATER_DARK: P.DW_WATER_DARK,
    P.WATER_MID: P.DW_WATER_MID, P.WATER_LIGHT: P.DW_WATER_LIGHT, P.WATER_FOAM: P.DW_FOAM,
}
HUE_TARGET = 0.83                 # the purple every other colour drifts toward
HUE_PULL = 0.4                    # how far (0..1)
SAT_KEEP = 0.6
VALUE_KEEP = 0.78


def dusk(c):
    """Fallback recolour: pull the hue toward purple, wash out the saturation, darken."""
    r, g, b, a = c
    if a == 0:
        return c
    h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    d = ((HUE_TARGET - h + 0.5) % 1.0) - 0.5                 # shortest way round the hue circle
    h = (h + d * HUE_PULL) % 1.0
    r2, g2, b2 = colorsys.hsv_to_rgb(h, s * SAT_KEEP, v * VALUE_KEEP)
    return (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)


# Cells that keep their Light World colours in the Dark World (Ignis's lava, crust and ash, Silva's jungle and
# grove pools are already their own).
KEEP_PREFIXES = ("lava_", "crust", "ash", "jungle", "dwater_")


def kept_cells():
    """Atlas cells (col, row) listed in the manifest under a KEEP_PREFIXES name."""
    with open(LIGHT.replace(".png", ".json"), encoding="utf-8") as f:
        cells = json.load(f)["cells"]
    return {tuple(v["cell"]) for k, v in cells.items() if k.startswith(KEEP_PREFIXES)}


def dark_atlas():
    img = Image.open(LIGHT).convert("RGBA")
    px = img.load()
    cache = {}
    keep = kept_cells()
    for y in range(img.height):
        for x in range(img.width):
            if (x // 16, y // 16) in keep:
                continue
            c = px[x, y]
            if c not in cache:
                cache[c] = MAP.get(c, dusk(c))
            px[x, y] = cache[c]
    return img


def swirl(colours, frames=4, size=16):
    """A swirling oval of light (rift / portal): arms rotate a quarter turn over the strip."""
    import math
    dark, mid, light = colours
    out = []
    for f in range(frames):
        c = Canvas(size, size)
        cx, cy = size / 2 - 0.5, size / 2 + 1
        c.ellipse(cx, cy, 7, 4, dark)
        for k in range(3):
            a = f * (math.pi / 2) / frames * 2 + k * 2.094
            for t in range(6):
                r = 1.5 + t
                x = cx + math.cos(a + t * 0.45) * r
                y = cy + math.sin(a + t * 0.45) * r * 0.55
                c.set(x, y, mid if t > 2 else light)
        c.ellipse(cx, cy, 1.5, 1, light)
        out.append(c)
    return pack_strip(out)


def mirror_icon():
    c = Canvas(16, 16)
    c.ellipse(7.5, 6.5, 5.5, 6, P.MIRROR_FRAME)
    c.ellipse(7.5, 6.5, 4, 4.5, P.MIRROR_GLASS)
    c.ellipse(6, 4.5, 1.5, 2, P.MIRROR_SHINE)               # a crescent moon in the glass
    c.ellipse(6.8, 4.2, 1.2, 1.6, P.MIRROR_GLASS)
    c.rect(7, 12, 2, 3, P.MIRROR_FRAME)
    c.rect(5, 14, 6, 1, P.MIRROR_FRAME)
    c.outline(P.OUTLINE)
    return c


def main():
    dark = dark_atlas()
    dark.save(DARK)
    rift = swirl((P.RIFT_DARK, P.RIFT_MID, P.RIFT_LIGHT))
    portal = swirl((P.PORTAL_DARK, P.PORTAL_MID, P.PORTAL_LIGHT))
    os.makedirs(WORLD, exist_ok=True)
    rift.save(os.path.join(WORLD, "rift.png"))
    portal.save(os.path.join(WORLD, "portal.png"))
    mirror_icon().img.save(os.path.join(ICONS, "moon_mirror.png"))
    light = Image.open(LIGHT).convert("RGBA")
    crop = (0, 0, light.width, 9 * 16)
    sheet = Image.new("RGBA", (light.width * 2 + 8, 9 * 16 + 40), (20, 16, 32, 255))
    sheet.alpha_composite(light.crop(crop), (0, 0))
    sheet.alpha_composite(dark.crop(crop), (light.width + 8, 0))
    sheet.alpha_composite(rift, (0, 9 * 16 + 8))
    sheet.alpha_composite(portal, (80, 9 * 16 + 8))
    sheet.alpha_composite(mirror_icon().img, (160, 9 * 16 + 8))
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 2).save(PREVIEW)
    print("dark atlas %dx%d, rift, portal, mirror icon; preview %s" % (dark.width, dark.height,
                                                                        os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
