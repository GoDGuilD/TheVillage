# File: silva_art.py
# Description: Tile painters for Silva (Phase 12) used by gen_tiles.py - two jungle ground tiles and the Silva Grove's water nine-slice (murky pools with a stone lip, swimmable with the flippers).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
import palette as P

T = 16
LIP = 3                       # px of stone on a pool piece's sides that border the dungeon floor


def jungle(c, ox, oy, rng, roots=False):
    """Silva ground: deep moss with lighter leaf litter; the second variant has a root crossing it."""
    c.rect(ox, oy, T, T, P.JUNGLE_MID)
    for _ in range(12):
        c.set(ox + rng.randrange(T), oy + rng.randrange(T), P.JUNGLE_DARK)
    for _ in range(4):                                       # fallen leaves
        x, y = ox + rng.randrange(1, T - 3), oy + rng.randrange(1, T - 2)
        c.rect(x, y, 2, 1, P.JUNGLE_LIGHT)
        c.set(x + 1, y + 1, P.JUNGLE_DARK)
    if roots:
        y = oy + rng.randrange(5, T - 5)
        for x in range(T):
            wave = (x // 4) % 2
            c.set(ox + x, y + wave, P.JUNGLE_ROOT)
            c.set(ox + x, y + wave + 1, P.JUNGLE_DARK)


def grove_water(c, ox, oy, rng, top, bottom, left, right):
    """A pool of the Silva Grove: dark green water with pale ripples, a stone lip on the sides that touch floor."""
    c.rect(ox, oy, T, T, P.GROVE_MID)
    for _ in range(3):
        x, y = ox + rng.randrange(2, T - 5), oy + rng.randrange(3, T - 2)
        c.rect(x, y, 3, 1, P.GROVE_LIGHT)
        c.set(x + 1, y + 1, P.GROVE_DARK)
    if top:
        c.rect(ox, oy, T, LIP, P.STEEL_MID)
        c.rect(ox, oy + LIP, T, 1, P.GROVE_FOAM)
        c.rect(ox, oy + LIP + 1, T, 1, P.GROVE_DARK)          # the lip's shadow on the water
    if bottom:
        c.rect(ox, oy + T - LIP, T, LIP, P.STEEL_DARK)
        c.rect(ox, oy + T - LIP - 1, T, 1, P.GROVE_FOAM)
    if left:
        c.rect(ox, oy, LIP, T, P.STEEL_MID)
        c.rect(ox + LIP, oy, 1, T, P.GROVE_FOAM)
    if right:
        c.rect(ox + T - LIP, oy, LIP, T, P.STEEL_DARK)
        c.rect(ox + T - LIP - 1, oy, 1, T, P.GROVE_FOAM)
