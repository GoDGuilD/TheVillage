# File: gen_tiles.py
# Description: Generates the Light World tile atlas (grass, path, water, ledges, cliffs, trees, houses, fence, sign, interiors, dungeon stone, pits, stairs, the shrine facade) with a flag manifest, plus bush/leaf sprites.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-21
# Version: 3.0.1
#
# Run:  python -I tools/gen_tiles.py   (writes assets/tiles/overworld_light.png + .json, assets/sprites/world/, tmp/tiles_preview.png)
#
# The atlas is a grid of 16x16 cells. Its JSON manifest names every cell and flags it (solid, ledge, door, exit, pit, low = the grapple flies over it),
# so the game builds its TileSet from the manifest at runtime (no hand-made .tres to keep in sync).
# Multi-cell pieces (2x2 tree, 5x4 houses) are named <piece>_<x>_<y>; the area painter places them by anchor.
import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from palette import (BARK_DARK, BARK_LIGHT, BARK_MID, BUSH_DARK, BUSH_LIGHT, BUSH_MID, DIRT_DARK, DIRT_LIGHT,
                     DIRT_MID, FLOWER_RED, FLOWER_WHITE, FLOWER_YEL, GRASS_DARK, GRASS_HILITE, GRASS_LIGHT,
                     GRASS_MID, LEAF_DARK, LEAF_HILITE, LEAF_LIGHT, LEAF_MID, OUTLINE, ROCK_DARK, ROCK_LIGHT,
                     ROCK_MID, SHADOW)
from sprite_lib import Canvas, upscale
import terrain_art as ta
import dungeon_art as da

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILE_DIR = os.path.join(ROOT, "assets", "tiles")
SPRITE_DIR = os.path.join(ROOT, "assets", "sprites", "world")
PREVIEW = os.path.join(ROOT, "tmp", "tiles_preview.png")

T = 16                      # tile size in pixels
COLS, ROWS = 16, 13         # atlas grid
SEED = 1986                 # fixed seed so regenerating gives identical art
EDGE = 3                    # width (px) of the grassy lip around a dirt path


def _grass(c, ox, oy, rng, tufts=5):
    """Grass base with little ALttP-style 'v' tufts in light/dark green."""
    c.rect(ox, oy, T, T, GRASS_MID)
    for _ in range(tufts):
        x, y = ox + rng.randrange(1, T - 3), oy + rng.randrange(2, T - 1)
        c.set(x, y, GRASS_DARK)
        c.set(x + 2, y, GRASS_DARK)
        c.set(x + 1, y + 1, GRASS_DARK)
        c.set(x, y - 1, GRASS_LIGHT)
        c.set(x + 2, y - 1, GRASS_LIGHT)
    for _ in range(3):
        c.set(ox + rng.randrange(T), oy + rng.randrange(T), GRASS_HILITE)


def _flowers(c, ox, oy, rng):
    """Grass with a few four-petal flowers."""
    _grass(c, ox, oy, rng, tufts=2)
    for fx, fy, col in ((3, 4, FLOWER_RED), (11, 6, FLOWER_YEL), (6, 11, FLOWER_WHITE)):
        x, y = ox + fx, oy + fy
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            c.set(x + dx, y + dy, col)
        c.set(x, y, FLOWER_YEL if col != FLOWER_YEL else FLOWER_RED)


def _path(c, ox, oy, rng, top, bottom, left, right):
    """Dirt tile; the flagged sides get a grassy lip so paths blend into the meadow (nine-slice piece)."""
    c.rect(ox, oy, T, T, DIRT_MID)
    for _ in range(6):
        x, y = ox + rng.randrange(T), oy + rng.randrange(T)
        c.set(x, y, DIRT_DARK if rng.random() < 0.6 else DIRT_LIGHT)
    for y in range(T):
        for x in range(T):
            # Wobbly edge: the lip depth varies by a pixel along the side.
            wob = (x * 7 + y * 3) % 3 == 0
            lip = EDGE - (1 if wob else 0)
            g = (top and y < lip) or (bottom and y >= T - lip) or (left and x < lip) or (right and x >= T - lip)
            if g:
                c.set(ox + x, oy + y, GRASS_MID)
            elif (top and y == lip) or (left and x == lip):
                c.set(ox + x, oy + y, DIRT_DARK)          # shaded rim on the upper/left sides
            elif (bottom and y == T - lip - 1) or (right and x == T - lip - 1):
                c.set(ox + x, oy + y, DIRT_LIGHT)


def _rock(c, ox, oy):
    """Heavy grey boulder (solid; liftable later with the glove)."""
    _grass(c, ox, oy, random.Random(SEED + 7), tufts=2)
    rc = Canvas(T, T)
    rc.ellipse(7.5, 9, 7, 6, ROCK_MID)
    rc.ellipse(6, 7, 4, 3, ROCK_LIGHT)
    rc.ellipse(9.5, 12, 5, 2, ROCK_DARK)
    rc.set(10, 6, ROCK_DARK)
    rc.set(11, 7, ROCK_DARK)
    rc.outline(OUTLINE)
    c.img.alpha_composite(rc.img, (ox, oy))
    c.px = c.img.load()


def _tree(c, ox, oy, rng):
    """2x2-tile round tree: leafy canopy over a short trunk (all four cells solid)."""
    for ty in range(2):
        for tx in range(2):
            _grass(c, ox + tx * T, oy + ty * T, rng, tufts=2)
    sh = Canvas(2 * T, 2 * T)
    sh.ellipse(16, 28, 11, 3, SHADOW)              # soft shadow, blended under the tree (not outlined)
    c.img.alpha_composite(sh.img, (ox, oy))
    tc = Canvas(2 * T, 2 * T)
    tc.rect(13, 20, 6, 9, BARK_MID)
    tc.rect(13, 20, 2, 9, BARK_LIGHT)
    tc.rect(17, 20, 2, 9, BARK_DARK)
    tc.ellipse(15.5, 13, 14, 11, LEAF_DARK)
    tc.ellipse(15.5, 12, 13, 10, LEAF_MID)
    for cx, cy, r in ((9, 9, 5), (19, 7, 6), (13, 15, 5), (23, 14, 4)):
        tc.ellipse(cx, cy, r, r - 1, LEAF_LIGHT)
        tc.ellipse(cx - 1, cy - 2, r / 2.5, r / 3, LEAF_HILITE)
    for _ in range(18):
        x, y = rng.randrange(4, 28), rng.randrange(4, 22)
        if tc.px[x, y][3]:
            tc.set(x, y, LEAF_DARK)
    tc.outline(OUTLINE)
    c.img.alpha_composite(tc.img, (ox, oy))
    c.px = c.img.load()


def make_atlas():
    rng = random.Random(SEED)
    c = Canvas(COLS * T, ROWS * T)
    cells = {}

    def put(name, col, row, solid=False, **flags):
        cells[name] = {"cell": [col, row], "solid": solid}
        cells[name].update(flags)

    _grass(c, 0, 0, rng); put("grass_a", 0, 0)
    _grass(c, T, 0, rng, tufts=8); put("grass_b", 1, 0)
    _flowers(c, 2 * T, 0, rng); put("flowers", 2, 0)
    _rock(c, 3 * T, 0); put("rock", 3, 0, solid=True)
    # Path nine-slice in columns 0-2, rows 1-3: (dx, dy) in -1..1 says which sides border grass.
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            col, row = 1 + dx, 2 + dy
            _path(c, col * T, row * T, rng, dy == -1, dy == 1, dx == -1, dx == 1)
            put("path_%d_%d" % (dx, dy), col, row)
    _tree(c, 4 * T, 0, rng)
    for ty in range(2):
        for tx in range(2):
            put("tree_%d_%d" % (tx, ty), 4 + tx, ty, solid=True)
    # Houses: 5x4 cells each, red roof at column 6, blue roof at column 11; the door cell is walkable.
    for style, col0 in (("red", 6), ("blue", 11)):
        ta.house(c, col0 * T, 0, rng, style)
        for ty in range(ta.HOUSE_H):
            for tx in range(ta.HOUSE_W):
                is_door = (tx, ty) == ta.HOUSE_DOOR
                put("house_%s_%d_%d" % (style, tx, ty), col0 + tx, ty, solid=not is_door, door=is_door)
    # Water nine-slice in columns 0-2, rows 4-6 (same dx/dy naming as the path; all solid until flippers).
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            col, row = 1 + dx, 5 + dy
            ta.water(c, col * T, row * T, rng, dy == -1, dy == 1, dx == -1, dx == 1)
            put("water_%d_%d" % (dx, dy), col, row, solid=True, low=True)   # low: the grapple flies over it
    # Ledges (hop down southward): left end, middle, right end, single.
    for i, (name, cl, cr) in enumerate((("ledge_l", True, False), ("ledge_m", False, False),
                                        ("ledge_r", False, True), ("ledge_s", True, True))):
        ta.ledge(c, (3 + i) * T, 4 * T, rng, cl, cr)
        put(name, 3 + i, 4, solid=True, ledge=True)
    ta.cliff(c, 3 * T, 5 * T, rng, True); put("cliff_top", 3, 5, solid=True)
    ta.cliff(c, 4 * T, 5 * T, rng, False); put("cliff", 4, 5, solid=True)
    ta.fence(c, 5 * T, 5 * T, rng); put("fence", 5, 5, solid=True)
    ta.sign(c, 6 * T, 5 * T, rng); put("sign", 6, 5, solid=True)
    # Interiors (row 7-8).
    ta.floor(c, 0, 7 * T, rng); put("floor", 0, 7)
    ta.wall_face(c, 1 * T, 7 * T); put("wall_face", 1, 7, solid=True)
    ta.wall_face(c, 2 * T, 7 * T, shelf=True); put("wall_shelf", 2, 7, solid=True)
    ta.wall_top(c, 3 * T, 7 * T); put("wall_top", 3, 7, solid=True)
    ta.mat(c, 4 * T, 7 * T, rng); put("mat", 4, 7, exit=True)
    ta.table(c, 5 * T, 7 * T, rng, 0); put("table_l", 5, 7, solid=True)
    ta.table(c, 6 * T, 7 * T, rng, 1); put("table_r", 6, 7, solid=True)
    ta.bed(c, 7 * T, 7 * T, rng, 0); put("bed_t", 7, 7, solid=True)
    ta.bed(c, 7 * T, 8 * T, rng, 1); put("bed_b", 7, 8, solid=True)
    # Dungeon (rows 9-12): floor, cracked floor, wall top/face, pillar, exit stairs; pit nine-slice in columns 0-2,
    # rows 10-12 (dx/dy say which sides border floor; pits are not solid to Joe - he falls - but flagged `pit`).
    da.dfloor(c, 3 * T, 9 * T, rng); put("dfloor", 3, 9)
    da.dfloor(c, 4 * T, 9 * T, rng, cracked=True); put("dfloor_b", 4, 9)
    da.dwall_top(c, 5 * T, 9 * T, rng); put("dwall_top", 5, 9, solid=True)
    da.dwall_face(c, 6 * T, 9 * T, rng); put("dwall_face", 6, 9, solid=True)
    da.pillar(c, 7 * T, 9 * T, rng); put("pillar", 7, 9, solid=True)
    da.stairs(c, 8 * T, 9 * T, rng); put("dstairs", 8, 9, exit=True)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            col, row = 1 + dx, 11 + dy
            da.pit(c, col * T, row * T, dy == -1, dy == 1, dx == -1, dx == 1)
            put("pit_%d_%d" % (dx, dy), col, row, pit=True, low=True)
    # The Moss Shrine facade (5x3, door cell walkable) at columns 9-13, rows 9-11.
    da.shrine(c, 9 * T, 9 * T, rng)
    for ty in range(da.SHRINE_H):
        for tx in range(da.SHRINE_W):
            is_door = (tx, ty) == da.SHRINE_DOOR
            put("shrine_%d_%d" % (tx, ty), 9 + tx, 9 + ty, solid=not is_door, door=is_door)
    return c, cells


def make_bush():
    """Cuttable bush sprite (16x16) and its four-frame leaf burst."""
    b = Canvas(T, T)
    b.ellipse(7.5, 13, 7, 2.5, SHADOW)
    b.ellipse(7.5, 8.5, 7, 6, BUSH_DARK)
    b.ellipse(7.5, 8, 6.5, 5.5, BUSH_MID)
    for cx, cy in ((4, 6), (10, 6), (7, 10)):
        b.ellipse(cx, cy, 2.5, 2, BUSH_LIGHT)
    b.set(5, 9, BUSH_DARK)
    b.set(10, 10, BUSH_DARK)
    b.outline(OUTLINE)
    # Leaf burst: little leaves flung outward, fading out over 4 frames.
    frames = []
    dirs = [(-1, -1), (1, -1), (-1, 1), (1, 1), (0, -1), (0, 1)]
    for f in range(4):
        fc = Canvas(32, 32)
        for i, (dx, dy) in enumerate(dirs):
            r = 3 + f * 3
            x, y = 16 + dx * r + (i % 2), 16 + dy * r - f
            col = BUSH_LIGHT if (i + f) % 2 else BUSH_MID
            fc.rect(x, y, 2 if f < 3 else 1, 2 if f < 2 else 1, col)
            if f < 2:
                fc.set(x + 1, y + 1, BUSH_DARK)
        fc.outline(OUTLINE)                      # dark rim so the leaves read against the grass
        frames.append(fc)
    return b, frames


def main():
    os.makedirs(TILE_DIR, exist_ok=True)
    os.makedirs(SPRITE_DIR, exist_ok=True)
    atlas, cells = make_atlas()
    atlas.img.save(os.path.join(TILE_DIR, "overworld_light.png"))
    with open(os.path.join(TILE_DIR, "overworld_light.json"), "w", encoding="utf-8") as f:
        json.dump({"tile_size": T, "cells": cells}, f, indent=2)
    bush, leaves = make_bush()
    bush.img.save(os.path.join(SPRITE_DIR, "bush.png"))
    from sprite_lib import pack_strip
    pack_strip(leaves).save(os.path.join(SPRITE_DIR, "leaf_burst.png"))
    upscale(atlas.img, 4).save(PREVIEW)
    print("Tiles: %d cells, bush + leaf burst written" % len(cells))


if __name__ == "__main__":
    main()
