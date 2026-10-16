# File: dungeon_art.py
# Description: Drawing routines for the dungeon tiles (stone floor, wall tops/faces, pillar, pit nine-slice, exit stairs) and the Moss Shrine's 5x3 entrance facade, used by gen_tiles.py.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
#
# Same contract as terrain_art.py: draw into an atlas Canvas at (ox, oy); gen_tiles.py names the cells and flags
# them (solid, pit, exit, door). The look is ALttP's first palace: green-grey stone with moss.
from palette import (DFLOOR_DARK, DFLOOR_LIGHT, DFLOOR_MID, DSTONE_DARK, DSTONE_LIGHT, DSTONE_MID, INK, MOSS,
                     MOSS_LIGHT, OUTLINE, PIT_DEEP, PIT_LIP, SHADOW)
from sprite_lib import Canvas
import terrain_art as ta

T = 16
LIP = 3                         # stone lip width (px) around a pit
SHRINE_W, SHRINE_H = 5, 3       # entrance facade in tiles; the doorway is the cell (2, 2)
SHRINE_DOOR = (2, 2)


def dfloor(c, ox, oy, rng, cracked=False):
    """Square stone floor tile with a bevel; `cracked` adds a crack and a tuft of moss."""
    c.rect(ox, oy, T, T, DFLOOR_MID)
    c.rect(ox, oy, T, 1, DFLOOR_LIGHT)
    c.rect(ox, oy, 1, T, DFLOOR_LIGHT)
    c.rect(ox, oy + T - 1, T, 1, DFLOOR_DARK)
    c.rect(ox + T - 1, oy, 1, T, DFLOOR_DARK)
    c.rect(ox + 7, oy + 1, 1, T - 2, DFLOOR_DARK)            # the tile is two slabs
    for _ in range(3):
        c.set(ox + rng.randrange(2, 14), oy + rng.randrange(2, 14), DFLOOR_LIGHT)
    if cracked:
        x, y = ox + 3, oy + 4
        for k in range(6):
            c.set(x + k, y + (k % 3), DFLOOR_DARK)
        c.rect(ox + 10, oy + 10, 3, 2, MOSS)
        c.set(ox + 11, oy + 10, MOSS_LIGHT)


def dwall_top(c, ox, oy, rng):
    """Top of a thick dungeon wall seen from above: dark stone with moss specks."""
    c.rect(ox, oy, T, T, DSTONE_DARK)
    for _ in range(4):
        c.set(ox + rng.randrange(T), oy + rng.randrange(T), DSTONE_MID)
    c.set(ox + rng.randrange(T), oy + rng.randrange(T), MOSS)


def dwall_face(c, ox, oy, rng):
    """Dungeon wall face (bricks) where the wall meets the floor below it."""
    c.rect(ox, oy, T, T, DSTONE_MID)
    for row, y in enumerate((0, 5, 10)):
        c.rect(ox, oy + y, T, 1, DSTONE_DARK)
        off = 0 if row % 2 == 0 else 4
        for x in range(off, T, 8):
            c.rect(ox + x, oy + y, 1, 5, DSTONE_DARK)
        c.rect(ox, oy + y + 1, T, 1, DSTONE_LIGHT)
    c.rect(ox, oy + 14, T, 2, DSTONE_DARK)                    # shadow line at the foot
    c.rect(ox + rng.randrange(1, 12), oy + 1, 3, 1, MOSS)


def pillar(c, ox, oy, rng):
    """A stone pillar standing on the floor (solid)."""
    dfloor(c, ox, oy, rng)
    p = Canvas(T, T)
    p.rect(3, 1, 10, 14, DSTONE_MID)
    p.rect(3, 1, 3, 14, DSTONE_LIGHT)
    p.rect(10, 1, 3, 14, DSTONE_DARK)
    p.rect(2, 0, 12, 2, DSTONE_LIGHT)
    p.rect(2, 13, 12, 3, DSTONE_DARK)
    p.rect(5, 6, 2, 3, MOSS)
    p.outline(OUTLINE)
    c.img.alpha_composite(p.img, (ox, oy))
    c.px = c.img.load()


def stairs(c, ox, oy, rng):
    """Steps leading down and out of the dungeon (walking onto them leaves)."""
    c.rect(ox, oy, T, T, PIT_LIP)
    for i, y in enumerate(range(1, T, 4)):
        shade = (DSTONE_LIGHT, DSTONE_MID, DFLOOR_MID, DFLOOR_DARK)[i]
        c.rect(ox + 1, oy + y, T - 2, 3, shade)
        c.rect(ox + 1, oy + y + 3, T - 2, 1, INK)


def pit(c, ox, oy, top, bottom, left, right):
    """Pit nine-slice piece: black depth with a stone lip on the sides that border floor."""
    c.rect(ox, oy, T, T, PIT_DEEP)
    if top:
        c.rect(ox, oy, T, LIP, DFLOOR_MID)
        c.rect(ox, oy + LIP, T, 2, PIT_LIP)
    if bottom:
        c.rect(ox, oy + T - LIP, T, LIP, DFLOOR_DARK)
    if left:
        c.rect(ox, oy, LIP, T, DFLOOR_MID)
        c.rect(ox + LIP, oy, 1, T, PIT_LIP)
    if right:
        c.rect(ox + T - LIP, oy, LIP, T, DFLOOR_MID)
        c.rect(ox + T - LIP - 1, oy, 1, T, PIT_LIP)


def shrine(c, ox, oy, rng):
    """The Moss Shrine's entrance: a stepped stone front with two columns, a mossy lintel and a dark doorway in
    cell (2, 2). Drawn over grass so it sits in the woods."""
    for ty in range(SHRINE_H):
        for tx in range(SHRINE_W):
            ta.grass_base(c, ox + tx * T, oy + ty * T, rng)
    W, H = SHRINE_W * T, SHRINE_H * T
    s = Canvas(W, H)
    s.rect(2, 8, W - 4, H - 8, DSTONE_MID)                    # main block
    s.rect(2, 8, W - 4, 2, DSTONE_LIGHT)
    for y in range(14, H - 2, 6):                             # brick courses
        s.rect(2, y, W - 4, 1, DSTONE_DARK)
    s.poly([(0, 10), (W - 1, 10), (W - 12, 0), (11, 0)], DSTONE_DARK)   # stepped roof
    s.rect(8, 2, W - 16, 2, DSTONE_LIGHT)
    for x in range(6, W - 6, 9):                              # moss hanging from the roof
        s.rect(x, 9, 4, 2 + (x % 3), MOSS)
        s.set(x + 1, 9, MOSS_LIGHT)
    for cx in (SHRINE_DOOR[0] * T - 6, (SHRINE_DOOR[0] + 1) * T + 2):   # columns beside the door
        s.rect(cx, 14, 4, H - 16, DSTONE_LIGHT)
        s.rect(cx + 3, 14, 1, H - 16, DSTONE_DARK)
    dx = SHRINE_DOOR[0] * T
    s.rect(dx + 1, 2 * T - 4, T - 2, T + 4, PIT_DEEP)          # doorway
    s.rect(dx + 1, 2 * T - 4, T - 2, 2, DSTONE_DARK)
    s.outline(OUTLINE)
    sh = Canvas(W, H)
    sh.rect(1, H - 2, W - 2, 2, SHADOW)
    c.img.alpha_composite(sh.img, (ox, oy))
    c.img.alpha_composite(s.img, (ox, oy))
    c.px = c.img.load()
