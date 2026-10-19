# File: ignis_art.py
# Description: Tile painters for Ignis (Phase 10) used by gen_tiles.py - lava nine-slice pieces with a basalt rim, the ice crust the ice rod leaves on lava, and two ash ground tiles.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-22
# Last edit date: 2026-10-22
# Version: 1.0.0
import palette as P

T = 16
RIM = 3                       # px of basalt on a lava piece's sides that border solid ground


def lava(c, ox, oy, rng, top, bottom, left, right):
    """Lava nine-slice piece: glowing molten rock with bubbles, a basalt rim on the sides that touch ground."""
    c.rect(ox, oy, T, T, P.LAVA_MID)
    for _ in range(5):                                       # darker crust swirls
        x, y = ox + rng.randrange(T - 3), oy + rng.randrange(T - 2)
        c.rect(x, y, 3, 1, P.LAVA_DEEP)
    for _ in range(4):                                       # bright bubbles
        x, y = ox + rng.randrange(1, T - 2), oy + rng.randrange(1, T - 2)
        c.rect(x, y, 2, 2, P.LAVA_LIGHT)
        c.set(x, y, P.LAVA_GLOW)
    if top:
        c.rect(ox, oy, T, RIM, P.BASALT_MID)
        c.rect(ox, oy + RIM, T, 1, P.BASALT_DARK)
    if bottom:
        c.rect(ox, oy + T - RIM, T, RIM, P.BASALT_DARK)
    if left:
        c.rect(ox, oy, RIM, T, P.BASALT_MID)
        c.rect(ox + RIM, oy, 1, T, P.BASALT_DARK)
    if right:
        c.rect(ox + T - RIM, oy, RIM, T, P.BASALT_MID)
        c.rect(ox + T - RIM - 1, oy, 1, T, P.BASALT_DARK)


def crust(c, ox, oy, rng):
    """Lava frozen solid by the ice rod: pale blue ice plates with dark cracks (walkable until it melts)."""
    c.rect(ox, oy, T, T, P.CRUST_MID)
    for _ in range(6):
        x, y = ox + rng.randrange(T - 4), oy + rng.randrange(T - 2)
        c.rect(x, y, 4, 1, P.CRUST_LIGHT)
    for i in range(3):                                       # cracks
        x, y = ox + rng.randrange(2, T - 2), oy + rng.randrange(2, T - 2)
        c.line((x, y), (x + rng.choice((-3, 3)), y + 3), P.CRUST_DARK)
    c.rect(ox, oy, T, 1, P.CRUST_LIGHT)


def ash(c, ox, oy, rng, embers=0):
    """Ignis ground: grey ash with darker grit and, on the second variant, a few glowing embers."""
    c.rect(ox, oy, T, T, P.ASH_MID)
    for _ in range(14):
        c.set(ox + rng.randrange(T), oy + rng.randrange(T), P.ASH_DARK)
    for _ in range(6):
        c.set(ox + rng.randrange(T), oy + rng.randrange(T), P.ASH_LIGHT)
    for _ in range(embers):
        x, y = ox + rng.randrange(1, T - 1), oy + rng.randrange(1, T - 1)
        c.set(x, y, P.EMBER)
