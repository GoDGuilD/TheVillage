# File: terrain_art.py
# Description: Drawing routines for the Phase 3 terrain and building tiles (water, ledges, cliffs, fence, sign, houses, interiors), used by gen_tiles.py.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
#
# Every function draws into an atlas Canvas at (ox, oy) in pixels; gen_tiles.py decides where each piece goes
# and what the manifest says about it (solid, ledge, door, exit). Colours come only from palette.py.
import random

from palette import (BARK_DARK, BARK_LIGHT, BARK_MID, BED_BLUE, BED_LIGHT, CLIFF_DARK, CLIFF_LIGHT, CLIFF_MID,
                     FLOOR_DARK, FLOOR_LIGHT, FLOOR_MID, GLASS_DARK, GLASS_LIGHT, GOLD, GRASS_DARK, GRASS_LIGHT,
                     GRASS_MID, INK, INWALL_DARK, INWALL_LIGHT, INWALL_MID, LINEN, MAT_LIGHT, MAT_RED, OUTLINE,
                     ROOF_BLUE_DARK, ROOF_BLUE_LIGHT, ROOF_BLUE_MID, ROOF_RED_DARK, ROOF_RED_LIGHT, ROOF_RED_MID,
                     SHADOW, WALL_DARK, WALL_LIGHT, WALL_MID, WATER_DARK, WATER_FOAM, WATER_LIGHT, WATER_MID)
from sprite_lib import Canvas

T = 16
SHORE = 3                       # grassy lip width (px) around water
ROOFS = {"red": (ROOF_RED_DARK, ROOF_RED_MID, ROOF_RED_LIGHT), "blue": (ROOF_BLUE_DARK, ROOF_BLUE_MID, ROOF_BLUE_LIGHT)}
HOUSE_W, HOUSE_H = 5, 4         # houses are 5x4 tiles; the door is the cell (2, 3)
HOUSE_DOOR = (2, 3)


def water(c, ox, oy, rng, top, bottom, left, right):
    """Water nine-slice piece: ripples in the middle, a grassy shore with a foam line on the flagged sides."""
    c.rect(ox, oy, T, T, WATER_MID)
    for _ in range(3):
        x, y = ox + rng.randrange(2, T - 5), oy + rng.randrange(3, T - 2)
        c.rect(x, y, 3, 1, WATER_LIGHT)
        c.set(x + 1, y + 1, WATER_DARK)
    for y in range(T):
        for x in range(T):
            wob = (x * 5 + y * 3) % 4 == 0
            lip = SHORE - (1 if wob else 0)
            land = (top and y < lip) or (bottom and y >= T - lip) or (left and x < lip) or (right and x >= T - lip)
            foam = ((top and y == lip) or (bottom and y == T - lip - 1) or (left and x == lip)
                    or (right and x == T - lip - 1))
            if land:
                c.set(ox + x, oy + y, GRASS_MID)
            elif foam:
                c.set(ox + x, oy + y, WATER_FOAM)
            elif (top and y == lip + 1) or (left and x == lip + 1):
                c.set(ox + x, oy + y, WATER_DARK)       # the bank's shadow on the water


def grass_base(c, ox, oy, rng):
    """Plain grass with a few tufts (background under props drawn on top)."""
    c.rect(ox, oy, T, T, GRASS_MID)
    for _ in range(3):
        x, y = ox + rng.randrange(1, T - 3), oy + rng.randrange(2, T - 1)
        c.set(x, y, GRASS_DARK)
        c.set(x + 2, y, GRASS_DARK)
        c.set(x + 1, y + 1, GRASS_DARK)


def ledge(c, ox, oy, rng, cap_left, cap_right):
    """South-facing ledge: grass on top, an earthen lip, and a shadow on the lower grass (ALttP hop-down ledge)."""
    grass_base(c, ox, oy, rng)
    lip_y = 8
    c.rect(ox, oy + lip_y, T, 2, GRASS_DARK)
    c.rect(ox, oy + lip_y + 2, T, 3, CLIFF_MID)
    c.rect(ox, oy + lip_y + 2, T, 1, CLIFF_LIGHT)
    c.rect(ox, oy + lip_y + 5, T, 1, CLIFF_DARK)
    for x in range(0, T, 4):
        c.set(ox + x + 1, oy + lip_y + 3, CLIFF_DARK)
    sh = Canvas(T, 2)
    sh.rect(0, 0, T, 2, SHADOW)
    c.img.alpha_composite(sh.img, (ox, oy + lip_y + 6))
    c.px = c.img.load()
    if cap_left:
        c.rect(ox, oy + lip_y, 2, 6, GRASS_DARK)
    if cap_right:
        c.rect(ox + T - 2, oy + lip_y, 2, 6, GRASS_DARK)


def cliff(c, ox, oy, rng, cap):
    """Earthen cliff face (solid); `cap` adds the grassy brow on its top row."""
    c.rect(ox, oy, T, T, CLIFF_MID)
    for _ in range(5):
        x, y = ox + rng.randrange(1, T - 4), oy + rng.randrange(1, T - 2)
        c.rect(x, y, 3, 1, CLIFF_DARK)
        c.set(x, y - 1, CLIFF_LIGHT)
    c.rect(ox, oy, 1, T, CLIFF_LIGHT)
    if cap:
        c.rect(ox, oy, T, 4, GRASS_MID)
        c.rect(ox, oy + 4, T, 1, GRASS_DARK)


def fence(c, ox, oy, rng):
    """Wooden fence segment over grass: two posts and two rails (solid)."""
    grass_base(c, ox, oy, rng)
    f = Canvas(T, T)
    f.rect(0, 5, T, 2, BARK_LIGHT)
    f.rect(0, 10, T, 2, BARK_MID)
    for x in (2, 12):
        f.rect(x, 3, 3, 11, BARK_MID)
        f.rect(x, 3, 1, 11, BARK_LIGHT)
        f.rect(x, 13, 3, 1, BARK_DARK)
    f.outline(OUTLINE)
    c.img.alpha_composite(f.img, (ox, oy))
    c.px = c.img.load()


def sign(c, ox, oy, rng):
    """Wooden signpost over grass (solid; readable from Phase 4)."""
    grass_base(c, ox, oy, rng)
    s = Canvas(T, T)
    s.rect(7, 9, 2, 6, BARK_MID)
    s.rect(2, 3, 12, 7, BARK_LIGHT)
    s.rect(2, 9, 12, 1, BARK_DARK)
    for y in (5, 7):
        s.rect(4, y, 8, 1, BARK_DARK)
    s.outline(OUTLINE)
    c.img.alpha_composite(s.img, (ox, oy))
    c.px = c.img.load()


def house(c, ox, oy, rng, style):
    """5x4-tile cottage: pitched roof with tiles, plaster wall, two windows, a door in cell (2, 3)."""
    dark, mid, light = ROOFS[style]
    for ty in range(HOUSE_H):
        for tx in range(HOUSE_W):
            grass_base(c, ox + tx * T, oy + ty * T, rng)
    W, H = HOUSE_W * T, HOUSE_H * T
    h = Canvas(W, H)
    h.rect(4, 30, W - 8, H - 31, WALL_MID)                     # wall
    h.rect(4, 30, 2, H - 31, WALL_LIGHT)
    h.rect(W - 6, 30, 2, H - 31, WALL_DARK)
    h.rect(4, H - 3, W - 8, 2, WALL_DARK)                      # plinth
    for wx in (12, W - 24):                                    # windows
        h.rect(wx, 38, 12, 10, BARK_DARK)
        h.rect(wx + 1, 39, 10, 8, GLASS_DARK)
        h.rect(wx + 2, 40, 4, 3, GLASS_LIGHT)
        h.rect(wx + 5, 39, 1, 8, BARK_MID)
    dx = HOUSE_DOOR[0] * T                                     # door fills the door cell's width
    h.rect(dx + 1, 42, T - 2, H - 43, BARK_DARK)
    h.rect(dx + 3, 44, T - 6, H - 46, BARK_MID)
    h.rect(dx + 3, 44, 1, H - 46, BARK_LIGHT)
    h.set(dx + T - 5, 53, GOLD)                                # door knob
    # Roof: a big trapezoid with tile rows, overhanging the wall.
    h.poly([(0, 32), (W - 1, 32), (W - 10, 2), (9, 2)], mid)
    for y in range(6, 32, 5):
        h.rect(2, y, W - 4, 1, dark)
        for x in range(4 + (y % 10), W - 4, 10):
            h.set(x, y - 2, light)
    h.rect(8, 2, W - 16, 2, light)                             # ridge
    h.rect(0, 30, W, 3, dark)                                  # eave
    h.rect(W - 26, 0, 8, 10, WALL_DARK)                        # chimney
    h.rect(W - 25, 0, 6, 2, INK)
    h.outline(OUTLINE)
    sh = Canvas(W, H)
    sh.rect(2, H - 2, W - 4, 2, SHADOW)
    c.img.alpha_composite(sh.img, (ox, oy))
    c.img.alpha_composite(h.img, (ox, oy))
    c.px = c.img.load()


def floor(c, ox, oy, rng):
    """Wooden plank floor."""
    c.rect(ox, oy, T, T, FLOOR_MID)
    for y in (0, 8):
        c.rect(ox, oy + y, T, 1, FLOOR_DARK)
        c.rect(ox, oy + y + 1, T, 1, FLOOR_LIGHT)
    c.rect(ox + (rng.randrange(2, 14)), oy + 1, 1, 7, FLOOR_DARK)
    c.rect(ox + (rng.randrange(2, 14)), oy + 9, 1, 7, FLOOR_DARK)


def wall_face(c, ox, oy, shelf=False):
    """Interior wall seen face-on (the north wall), with a baseboard; `shelf` adds a little shelf with jars."""
    c.rect(ox, oy, T, T, INWALL_MID)
    c.rect(ox, oy, T, 2, INWALL_DARK)
    for x in range(0, T, 8):
        c.rect(ox + x, oy + 2, 1, 11, INWALL_LIGHT)
    c.rect(ox, oy + 13, T, 3, BARK_DARK)
    if shelf:
        c.rect(ox + 1, oy + 8, T - 2, 2, BARK_MID)
        c.rect(ox + 3, oy + 4, 3, 4, GLASS_LIGHT)
        c.rect(ox + 9, oy + 5, 4, 3, MAT_RED)


def wall_top(c, ox, oy):
    """Top of an interior wall seen from above (dark band)."""
    c.rect(ox, oy, T, T, INWALL_DARK)
    c.rect(ox, oy, T, 1, INWALL_MID)


def mat(c, ox, oy, rng):
    """Exit mat on the floor (walking onto it leaves the house)."""
    floor(c, ox, oy, rng)
    c.rect(ox + 1, oy + 3, T - 2, 10, MAT_RED)
    c.rect(ox + 2, oy + 4, T - 4, 8, MAT_LIGHT)
    c.rect(ox + 4, oy + 6, T - 8, 4, MAT_RED)


def table(c, ox, oy, rng, half):
    """Two-cell wooden table (half 0 = left, 1 = right) over the floor."""
    floor(c, ox, oy, rng)
    t = Canvas(T, T)
    x0 = 2 if half == 0 else 0
    w = T - 2
    t.rect(x0, 3, w, 8, BARK_LIGHT)
    t.rect(x0, 9, w, 2, BARK_MID)
    leg_x = x0 + 1 if half == 0 else w - 3
    t.rect(leg_x, 11, 2, 4, BARK_DARK)
    if half == 0:
        t.rect(8, 4, 4, 3, LINEN)                              # a bowl on the table
    t.outline(OUTLINE)
    c.img.alpha_composite(t.img, (ox, oy))
    c.px = c.img.load()


def bed(c, ox, oy, rng, half):
    """Two-cell bed (half 0 = head with pillow, 1 = foot) over the floor."""
    floor(c, ox, oy, rng)
    b = Canvas(T, T)
    if half == 0:
        b.rect(1, 1, T - 2, T - 1, BARK_MID)
        b.rect(2, 3, T - 4, 5, LINEN)
        b.rect(2, 8, T - 4, T - 8, BED_BLUE)
        b.rect(3, 9, T - 6, 1, BED_LIGHT)
    else:
        b.rect(1, 0, T - 2, T - 2, BARK_MID)
        b.rect(2, 0, T - 4, T - 4, BED_BLUE)
        b.rect(3, 4, T - 6, 1, BED_LIGHT)
    b.outline(OUTLINE)
    c.img.alpha_composite(b.img, (ox, oy))
    c.px = c.img.load()
