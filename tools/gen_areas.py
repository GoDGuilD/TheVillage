# File: gen_areas.py
# Description: Builds every overworld area, house interior and dungeon room as ASCII rows with their villagers, signs, chests, torches, rocks, key blocks, heart pieces, wares, doors, switches, blocks and the two gates, lints them (sizes, pieces, openings, reachability, ledges, doors, dialogue keys, item kinds, keys vs locks, big keys) and writes src/world/areas/*.json plus previews.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-21
# Version: 6.1.0
#
# Run:  python -I tools/gen_areas.py      (must print "0 lint problems"; never hand-edit the JSON it writes)
#
# World model (A Link to the Past): the overworld is a grid of SCREEN-sized cells; each area covers a rectangle of
# screens and sits at a global position, so neighbouring areas share edges and Joe's coordinates stay continuous
# when the camera scrolls from one to the next. Interiors live far away from the grid and are reached through
# doors (house door cell -> interior spawn; exit mat -> back below the door).
# Glyphs are documented in src/world/AreaBuilder.gd.
import json
import os
import random
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "src", "world", "areas")
ATLAS_PNG = os.path.join(ROOT, "assets", "tiles", "overworld_light.png")
ATLAS_JSON = os.path.join(ROOT, "assets", "tiles", "overworld_light.json")
DIALOGUE_JSON = os.path.join(ROOT, "assets", "data", "dialogue.json")
NPC_MANIFEST = os.path.join(ROOT, "assets", "sprites", "npcs", "npcs.json")
PREVIEW = os.path.join(ROOT, "tmp", "world_preview.png")
PREVIEW_IN = os.path.join(ROOT, "tmp", "interiors_preview.png")
PREVIEW_DUNGEON = os.path.join(ROOT, "tmp", "dungeon_d1_preview.png")

SCREEN = (24, 14)                 # tiles per screen (384 x 224 px; the 216-px view scrolls 8 px inside one screen)
TILE = 16
INTERIOR_BASE = (1000, 1000)      # interiors are placed at this tile offset, far from the overworld grid
INTERIOR_STRIDE = 40
DUNGEON_BASE = (2000, 0)          # dungeons get their own room grid, far from everything else
SEED = 1987

MULTI = {"T": (2, 2), "H": (5, 4), "J": (5, 4), "K": (2, 1), "D": (1, 2), "E": (5, 3), "$": (2, 1)}
HOUSE_DOOR = (2, 3)
SHRINE_DOOR = (2, 2)
# Solid: N villager, C chest, L torch, k cracked rock, l key block, % dungeon wall, + pillar, o pit (Joe falls),
# [ door, & push block, r heavy rock (all solid bodies or impassable cells).
SOLID = set("R~v^fSTHJWwKDNCLkl%+o[&rb|!p")  # ... b rubble (dash boots), | hook post, ! lava, p peg (hammer)
ACTORS = set("BOZGQPhYAUFVXmcIztjey")  # h heart piece; A bat; X lurker; c cinder; z cogbug; j snapvine; bosses:
                                        # Y Grand Slime, U Iron Ram, F Frost Wraith, V Caver's shade, m Gloom Moth,
                                        # I Magma Wyrm, t Clock Warden, e Thornheart, y Caver (his tower)
OPENABLE = set("kl[&rbp")          # solid until a bomb / key / push / glove / dash / hammer opens them (reachability: open)
GROUND = set(".,*#_M=;@sanug")     # = ; dungeon floor, @ floor switch, s exit stairs, a ash (Ignis), u n tick blocks
                                   # (amber / teal: one colour is always down, so they count as ground), g jungle (Silva)
VALID = SOLID | ACTORS | GROUND | {"x"} | set(MULTI)
ENEMIES = set("ZGQYAUFVXmcIztjey")
LOW = set("o~!")                  # pits, water and lava: the grapple's chain flies over them
WATER = "~"                       # deep water: the flippers swim it (reachability: a step like any ground)
ICE_REACH = 8                     # tiles an ice bolt flies (IceBolt.MAX_DISTANCE): it freezes every lava cell on the way
GRAPPLE_REACH = 7                 # tiles from Joe to a hook post the grapple can still bite (Grapple.RANGE)
FACING_STEP = {"down": (0, 1), "up": (0, -1), "left": (-1, 0), "right": (1, 0)}
# Everything a chest, gift or ware may hand out - mirrors ItemDB.KINDS in src/items/ItemDB.gd (test_items.gd
# checks that every kind used by the areas exists there).
ITEM_KINDS = {"lantern", "boomerang", "bow", "bombs", "arrows", "small_key", "heart_piece", "heart_container", "gems",
              "map", "compass", "big_key", "glove", "boots", "fire_rod", "grapple", "magic", "ice_rod", "hammer",
              "flippers"}
WARE_IDS = {"bombs", "arrows", "heart_piece", "dw_bombs", "dw_arrows", "dw_magic"}   # ItemDB.WARES
OBJECT_GLYPHS = {"chest": "C", "torch": "L", "cracked_rock": "k", "key_block": "l", "heart_piece": "h", "door": "[",
                 "switch": "@", "push_block": "&", "big_chest": "$", "heavy_rock": "r", "rubble": "b",
                 "hook_post": "|"}
GLYPHLESS = {"seal_gate", "crystal_gate", "rift"}  # objects drawn over plain cells (no glyph of their own)
GATES = {"seal_gate", "crystal_gate"}                # 2x2 gates in a wall (the keep's, the tower's)
DOORWAYS = {"n": (11, 0), "s": (11, 12), "w": (0, 6), "e": (22, 6)}   # top-left cell of each 2x2 dungeon doorway
OPEN_LO, OPEN_HI = 10, 14         # edge openings are 4 tiles wide, centred on each side of a screen pair
# Openings: north/south at columns 22..25 of a 2-screen-wide area, east/west at rows 12..15 of a 2-screen-tall one.


MUSIC_TRACKS = {"title", "valley", "house", "shrine", "dark_world", "dimension", "tower", "boss", "caver", "ending"}
# ^ tools/gen_music.py; every dungeon names its "music" (and may name a "boss_music" instead of "boss")


# --------------------------------------------------------------------------- building helpers

class Grid:
    """A mutable ASCII area with drawing helpers; every placement checks it does not overwrite solid work."""

    def __init__(self, w, h, fill="."):
        self.w, self.h = w, h
        self.cells = [[fill] * w for _ in range(h)]

    def get(self, x, y):
        return self.cells[y][x] if 0 <= x < self.w and 0 <= y < self.h else None

    def set(self, x, y, g):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.cells[y][x] = g

    def rect(self, x0, y0, x1, y1, g):
        """Fill the inclusive rectangle with glyph g."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, g)

    def free(self, x0, y0, w, h):
        return all(0 <= x < self.w and 0 <= y < self.h and self.cells[y][x] in GROUND
                   for y in range(y0, y0 + h) for x in range(x0, x0 + w))

    def piece(self, x, y, g, force=False):
        """Place a multi-cell piece (tree, house, table, bed) with its anchor at (x, y)."""
        w, h = MULTI[g]
        if not force and not self.free(x, y, w, h):
            raise ValueError("piece %s at (%d,%d) overlaps something" % (g, x, y))
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.cells[yy][xx] = "x"
        self.cells[y][x] = g

    def tree_border(self, openings):
        """Ring of 2x2 trees, skipping the tiles listed in openings = {"n"|"s": (x0, x1), "w"|"e": (y0, y1)}."""
        def skip(side, a):
            r = openings.get(side)
            return r is not None and r[0] <= a <= r[1]
        for x in range(0, self.w, 2):
            if not (skip("n", x) or skip("n", x + 1)):
                self.piece(x, 0, "T", force=True)
            if not (skip("s", x) or skip("s", x + 1)):
                self.piece(x, self.h - 2, "T", force=True)
        for y in range(2, self.h - 2, 2):
            if not (skip("w", y) or skip("w", y + 1)):
                self.piece(0, y, "T", force=True)
            if not (skip("e", y) or skip("e", y + 1)):
                self.piece(self.w - 2, y, "T", force=True)

    def scatter(self, rng, glyphs, count):
        """Sprinkle decorative ground (tufts, flowers) on plain grass."""
        for _ in range(count):
            x, y = rng.randrange(self.w), rng.randrange(self.h)
            if self.cells[y][x] == ".":
                self.cells[y][x] = rng.choice(glyphs)

    def place(self, points, g):
        """Put glyph g on each (x, y); the cell must be plain ground."""
        for x, y in points:
            if self.cells[y][x] not in GROUND or self.cells[y][x] == "#":
                raise ValueError("cannot put %s at (%d,%d): %s" % (g, x, y, self.cells[y][x]))
            self.cells[y][x] = g

    def rows(self):
        return ["".join(r) for r in self.cells]


def size_of(screens):
    return screens[0] * SCREEN[0], screens[1] * SCREEN[1]


# --------------------------------------------------------------------------- the overworld

def build_el_pueblo(rng):
    """El Pueblo: the hub village. Four houses (Joe, Tato, Boni's shop, Janga), crossing roads, gardens."""
    g = Grid(*size_of((2, 2)))
    g.tree_border({"n": (22, 25), "s": (22, 25), "w": (12, 15), "e": (12, 15)})
    g.rect(22, 0, 25, g.h - 1, "#")                    # north-south road
    g.rect(0, 12, g.w - 1, 15, "#")                    # east-west road
    houses = [("H", 6, 3, "joe_house"), ("J", 34, 3, "tato_house"), ("H", 6, 19, "boni_shop"), ("J", 34, 19, "janga_house")]
    doors = []
    for glyph, x, y, target in houses:
        g.piece(x, y, glyph)
        dx, dy = x + HOUSE_DOOR[0], y + HOUSE_DOOR[1]
        if y < 12:
            g.rect(dx, dy + 1, dx, 11, "#")              # northern houses: footpath straight down to the road
        else:
            # Southern houses face south: footpath down two cells, then along to the north-south road.
            g.rect(dx, dy + 1, dx, dy + 2, "#")
            if dx < 22:
                g.rect(dx, dy + 2, 21, dy + 2, "#")
            else:
                g.rect(26, dy + 2, dx, dy + 2, "#")
        doors.append({"cell": [dx, dy], "to": target})
    # Gardens: fences and flower beds beside the houses.
    for x0, y0 in ((13, 4), (29, 4), (13, 20), (29, 20)):
        g.rect(x0, y0, x0 + 4, y0, "f")
        g.rect(x0, y0 + 1, x0 + 4, y0 + 3, "*")
    g.place([(5, 8), (12, 8), (33, 8), (40, 8), (5, 24), (12, 25), (33, 25), (40, 24)], "O")
    g.place([(3, 3), (3, 4), (44, 3), (44, 4), (3, 23), (44, 23)], "B")
    g.scatter(rng, [",", ",", "*"], 140)
    return g, doors


def build_meadow_north(rng):
    """North meadow: open field with a pond, bushes and slimes - the first place to fight."""
    g = Grid(*size_of((2, 1)))
    g.tree_border({"s": (22, 25)})
    g.rect(22, 6, 25, g.h - 1, "#")
    g.rect(8, 6, 39, 6, "#")
    g.rect(30, 2, 37, 4, "~")                          # pond
    g.rect(31, 5, 36, 5, "~")
    g.set(34, 3, ".")                                  # an island no one can swim to (the Moon Mirror can)
    for x, y in ((6, 3), (14, 9), (40, 9)):
        g.piece(x, y, "T")
    g.place([(10, 3), (11, 3), (12, 3), (18, 9), (19, 9), (28, 10), (29, 10), (43, 4), (43, 5)], "B")
    g.place([(9, 10), (38, 8)], "R")
    g.place([(16, 3), (27, 9), (41, 11)], "Z")
    g.scatter(rng, [",", ",", "*"], 70)
    return g, []


def build_west_woods(rng):
    """West woods: thick trees, a clearing with a guard and a spitter, a ledge to hop down."""
    g = Grid(*size_of((1, 2)))
    g.tree_border({"e": (12, 15)})
    g.rect(10, 12, g.w - 1, 15, "#")
    for x, y in ((4, 2), (8, 2), (12, 2), (16, 2), (4, 6), (16, 6), (4, 18), (8, 22), (14, 22), (18, 18)):
        g.piece(x, y, "T")
    g.rect(6, 9, 15, 9, "v")                           # ledge: hop down from the upper wood into the clearing
    g.piece(8, 4, "E")                                 # the Moss Shrine, up in the old wood
    g.place([(6, 8), (7, 8), (12, 18), (13, 18), (6, 15)], "B")
    g.place([(7, 13)], "G")
    g.place([(12, 20)], "Q")
    g.place([(18, 4)], "R")
    g.scatter(rng, [",", ","], 60)
    return g, [{"cell": [8 + SHRINE_DOOR[0], 4 + SHRINE_DOOR[1]], "to": "d1_entrance"}]


def build_east_lake(rng):
    """East lake: a big lake with a shore path, rock-spitters on the banks."""
    g = Grid(*size_of((1, 2)))
    g.tree_border({"w": (12, 15)})
    g.rect(0, 12, 12, 15, "#")
    g.rect(13, 3, 19, 10, "~")
    g.rect(14, 17, 20, 24, "~")
    for x, y in ((3, 3), (7, 19)):
        g.piece(x, y, "T")
    g.place([(9, 4), (16, 13)], "Q")
    g.place([(4, 9), (5, 9), (10, 22)], "B")
    g.place([(9, 17), (10, 17)], "O")
    g.scatter(rng, [",", "*"], 50)
    return g, []


def build_south_road(rng):
    """South road: a cliff band crossed by a one-way ledge (hop down) with a ramp back up, guards on patrol.
    The far south is closed by boulders - the road to Caver's keep opens later (power glove)."""
    g = Grid(*size_of((2, 1)))
    g.tree_border({"n": (22, 25), "s": (22, 25)})
    g.rect(2, 6, g.w - 3, 7, "^")                      # cliff band across the area
    g.rect(16, 6, 27, 6, "v")                          # where the road meets the band: a ledge you can hop down
    g.rect(16, 7, 27, 7, "#")                          # landing strip (the cliff's lower row becomes road)
    g.rect(40, 6, 41, 7, "#")                          # the ramp back up (a gap in the cliff)
    g.rect(22, 0, 25, 5, "#")
    g.rect(16, 8, 41, 9, "#")
    g.rect(40, 2, 41, 5, "#")
    g.rect(26, 2, 39, 3, "#")
    g.rect(26, 4, 26, 5, "#")
    g.place([(10, 11), (12, 11), (14, 11), (30, 11), (32, 11), (34, 11)], "R")   # boulders: the way south is shut
    g.place([(20, 10), (36, 10)], "G")
    g.place([(6, 3), (7, 3), (44, 10)], "B")
    g.scatter(rng, [",", ","], 50)
    return g, []


def build_south_fields(rng):
    """South Fields: the valley's far end. Caver's keep (a stone wall with the seal gate) in the north-west,
    Ram's Hollow in the west, the Frost Vault fenced off in the east behind rubble only a dash can break."""
    g = Grid(*size_of((2, 2)))
    g.tree_border({"n": (22, 25)})
    g.rect(22, 0, 25, 21, "#")                         # the road down from the South Road
    g.rect(4, 20, 43, 21, "#")                         # and across the fields
    # Caver's keep: a block of dark wall; the gate (2x2 at 15-16, 5-6) opens into it once the seals are home.
    g.rect(12, 2, 19, 6, "%")
    g.rect(15, 6, 16, 6, "=")                          # the gateway floor under the gate's lower half
    g.rect(15, 7, 21, 8, "#")
    # Ram's Hollow (west).
    g.piece(5, 13, "E")
    g.rect(7, 16, 7, 19, "#")
    # The Frost Vault (east), inside a fence; the only way in is through the rubble at (40, 17).
    g.piece(38, 12, "E")
    g.rect(36, 10, 44, 10, "f")
    g.rect(36, 17, 44, 17, "f")
    g.rect(36, 11, 36, 16, "f")
    g.rect(44, 11, 44, 16, "f")
    g.set(40, 17, ".")                                 # the gap in the fence (rubble goes here)
    g.rect(40, 15, 40, 16, "#")
    g.rect(40, 18, 40, 19, "#")
    g.place([(10, 23), (30, 24), (32, 12)], "G")
    g.place([(18, 14), (29, 9)], "A")
    g.place([(6, 24), (14, 11), (33, 23)], "Z")
    g.place([(3, 9), (4, 9), (27, 13), (28, 13), (45, 22), (45, 23)], "B")
    g.place([(10, 9), (31, 16), (20, 24)], "R")
    g.scatter(rng, [",", ",", "*"], 110)
    doors = [{"cell": [15, 6], "to": "keep_entrance"}, {"cell": [16, 6], "to": "keep_entrance"},
             {"cell": [5 + SHRINE_DOOR[0], 13 + SHRINE_DOOR[1]], "to": "d2_entrance"},
             {"cell": [38 + SHRINE_DOOR[0], 12 + SHRINE_DOOR[1]], "to": "d3_entrance"}]
    return g, doors


# --------------------------------------------------------------------------- interiors

def build_umbra_vale(rng):
    """The Umbral Vale (Umbra's land, Dark World only): a path north to the sanctum; east, a chasm with an island
    the grapple reaches by its hook posts (a piece of heart)."""
    g = Grid(*size_of((2, 1)))
    g.tree_border({"s": (22, 25)})
    g.piece(21, 2, "E")                                # the Umbra Sanctum
    g.rect(22, 5, 25, g.h - 1, "#")
    g.rect(30, 3, 43, 10, "o")                         # the chasm...
    g.rect(33, 5, 36, 7, ".")                          # ...and its island
    for x, y in ((6, 3), (12, 8), (16, 3)):
        g.piece(x, y, "T")
    g.place([(4, 9), (5, 9), (18, 10), (27, 3), (27, 11)], "B")
    g.place([(9, 5), (15, 10), (28, 9)], "X")
    g.place([(4, 6)], "A")
    g.scatter(rng, [",", ","], 50)
    return g, [{"cell": [21 + SHRINE_DOOR[0], 2 + SHRINE_DOOR[1]], "to": "d4_entrance"}]


def build_cinder_barrens(rng):
    """The Cinder Barrens (Ignis's land, Dark World only, east of Ash Lake): ash ground behind a lava river only the
    grapple crosses (by its hook posts); the Ignis Forge in the north; a lava pool in the south whose islet holds a
    piece of heart for the ice rod."""
    g = Grid(*size_of((1, 2)), fill="a")
    g.tree_border({"w": (12, 15)})
    g.rect(0, 12, 3, 15, "#")
    g.rect(4, 2, 8, 25, "!")                           # the lava river
    g.piece(14, 2, "E")                                # the Ignis Forge
    g.rect(15, 5, 17, 11, "#")
    g.rect(11, 17, 20, 24, "!")                        # the lava pool...
    g.rect(15, 20, 16, 21, "a")                        # ...and its islet
    g.place([(12, 8), (20, 6), (19, 14)], "R")
    g.place([(12, 11), (19, 9), (10, 22)], "c")
    g.place([(17, 14)], "A")
    return g, [{"cell": [14 + SHRINE_DOOR[0], 2 + SHRINE_DOOR[1]], "to": "d5_entrance"}]


def tick_row(g, x0, x1, y, start_amber=True):
    """A fence of tick blocks from (x0, y) to (x1, y), colours alternating (so half of it is always down)."""
    for x in range(x0, x1 + 1):
        g.set(x, y, "u" if ((x - x0) % 2 == 0) == start_amber else "n")


def tick_col(g, x, y0, y1, start_amber=True):
    for y in range(y0, y1 + 1):
        g.set(x, y, "u" if ((y - y0) % 2 == 0) == start_amber else "n")


def build_clockwork_wastes(rng):
    """The Clockwork Wastes (Tempus's land, Dark World only, west of the Broken Road): a band of molten time only the
    ice rod crosses (so Ignis comes first), a fence of tick blocks, the Tempus Clocktower in the north-west, and in
    the south-west a row of pegs (the hammer) and stones guarding a piece of heart."""
    g = Grid(*size_of((1, 2)))
    g.tree_border({"e": (8, 11)})
    g.rect(18, 8, 23, 11, "#")                         # the path in from the Broken Road
    g.rect(14, 2, 16, 25, "!")                         # molten time
    g.piece(4, 2, "E")                                 # the Tempus Clocktower
    g.rect(5, 5, 7, 7, "#")
    tick_row(g, 2, 13, 10)
    g.rect(13, 19, 13, 25, "R")                        # stones: no crossing straight into the south
    g.rect(2, 18, 12, 18, "p")                         # pegs: the hammer opens the way south
    g.place([(19, 4)], "G")
    g.place([(6, 14)], "G")
    g.place([(10, 12)], "A")
    g.place([(5, 21), (11, 22)], "z")
    g.place([(3, 13), (12, 15)], "B")
    g.scatter(rng, [",", ","], 30)
    return g, [{"cell": [4 + SHRINE_DOOR[0], 2 + SHRINE_DOOR[1]], "to": "d6_entrance"}]


def build_silva_tangle(rng):
    """The Silva Tangle (Silva's land, Dark World only, west of the Thorn Woods, whose pegs - the hammer - keep it
    shut, so Tempus comes first): jungle ground, snapvines, the Silva Grove in the north-east, and a river of deep
    water no one crosses without the flippers (they are in the Grove) with a piece of heart on its far bank."""
    g = Grid(*size_of((1, 2)), fill="g")
    g.tree_border({"e": (12, 15)})
    g.rect(15, 12, 23, 15, "#")                        # the path in from the Thorn Woods
    g.rect(8, 2, 10, 25, "~")                          # the river
    g.piece(14, 3, "E")                                # the Silva Grove
    g.rect(15, 6, 17, 11, "#")
    for x, y in ((12, 17), (18, 17), (14, 21), (19, 21), (3, 3), (4, 21)):
        g.piece(x, y, "T")
    g.place([(13, 14), (20, 9), (16, 19), (4, 8), (5, 17)], "j")
    g.place([(12, 9), (13, 9), (21, 18), (21, 19), (2, 12)], "B")
    g.place([(20, 23)], "A")
    return g, [{"cell": [14 + SHRINE_DOOR[0], 3 + SHRINE_DOOR[1]], "to": "d7_entrance"}]


def build_interior(kind, rng, spawn=False):
    """A 16x11 room: two-row north wall (top + face, with shelves), side walls, furniture, exit mat at the bottom."""
    g = Grid(16, 11, "_")
    g.rect(0, 0, 15, 1, "W")
    g.rect(0, 0, 0, 10, "W")
    g.rect(15, 0, 15, 10, "W")
    g.rect(0, 10, 15, 10, "W")
    g.set(3, 1, "w")
    g.set(11, 1, "w")
    g.set(7, 9, "M")
    g.set(8, 9, "M")
    if kind == "bedroom":
        g.piece(2, 3, "D")
        g.piece(6, 5, "K")
        g.place([(13, 3), (13, 4)], "O")
    elif kind == "elder":
        g.piece(7, 4, "K")
        g.piece(12, 3, "D")
        g.place([(2, 3), (2, 7)], "O")
    elif kind == "shop":
        for x in (4, 6, 8, 10):                        # one long counter; Boni stands behind it
            g.piece(x, 4, "K")
        g.place([(2, 2), (3, 2), (12, 2), (13, 2)], "O")
    else:
        g.piece(3, 3, "D")
        g.piece(9, 6, "K")
        g.place([(13, 7)], "O")
    if spawn:
        g.set(4, 6, "P")
    return g


# --------------------------------------------------------------------------- lint

def solid_map(rows):
    """Per-cell solidity: solid glyphs and every cell covered by a solid multi-cell piece, except house doors."""
    h, w = len(rows), len(rows[0])
    solid = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            g = rows[y][x]
            if g in MULTI:
                pw, ph = MULTI[g]
                for yy in range(y, y + ph):
                    for xx in range(x, x + pw):
                        solid[yy][xx] = True
                if g in "HJ":
                    solid[y + HOUSE_DOOR[1]][x + HOUSE_DOOR[0]] = False
                if g == "E":
                    solid[y + SHRINE_DOOR[1]][x + SHRINE_DOOR[0]] = False
            elif g in SOLID:
                solid[y][x] = True
    return solid


def lint_area(a, problems):
    rows = a["rows"]
    w, h = len(rows[0]), len(rows)
    if a["kind"] == "overworld":
        ew, eh = size_of(a["size_screens"])
        if (w, h) != (ew, eh):
            problems.append("%s: size %dx%d, expected %dx%d" % (a["id"], w, h, ew, eh))
    for y, r in enumerate(rows):
        if len(r) != w:
            problems.append("%s: row %d has length %d" % (a["id"], y, len(r)))
        for x, g in enumerate(r):
            if g not in VALID:
                problems.append("%s: unknown glyph %r at (%d,%d)" % (a["id"], g, x, y))
    # Every filler is covered by exactly one anchor and anchors fit.
    cover = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            g = rows[y][x]
            if g in MULTI:
                pw, ph = MULTI[g]
                if x + pw > w or y + ph > h:
                    problems.append("%s: %s at (%d,%d) runs off the area" % (a["id"], g, x, y))
                    continue
                for yy in range(y, y + ph):
                    for xx in range(x, x + pw):
                        if (xx, yy) != (x, y):
                            if rows[yy][xx] != "x":
                                problems.append("%s: %s at (%d,%d) covers %r at (%d,%d)" % (a["id"], g, x, y, rows[yy][xx], xx, yy))
                            cover[yy][xx] += 1
    for y in range(h):
        for x in range(w):
            if rows[y][x] == "x" and cover[y][x] != 1:
                problems.append("%s: filler at (%d,%d) covered %d times" % (a["id"], x, y, cover[y][x]))
    # Ledges need somewhere to land.
    solid = solid_map(rows)
    for y in range(h):
        for x in range(w):
            if rows[y][x] == "v":
                ly = y + 1
                while ly < h and rows[ly][x] == "v":
                    ly += 1
                if ly >= h or solid[ly][x]:
                    problems.append("%s: ledge at (%d,%d) has no landing" % (a["id"], x, y))
    return solid


def grapple_hops(rows, solid, x, y):
    """Cells the grapple pulls Joe to from (x, y): straight along a facing, over open ground, pits and water, to
    the cell in front of a hook post at most GRAPPLE_REACH tiles away."""
    h, w = len(rows), len(rows[0])
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        for k in range(1, GRAPPLE_REACH + 1):
            nx, ny = x + dx * k, y + dy * k
            if not (0 <= nx < w and 0 <= ny < h):
                break
            if rows[ny][nx] == "|":
                lx, ly = nx - dx, ny - dy
                if k >= 2 and not solid[ly][lx]:
                    yield lx, ly
                break
            if solid[ny][nx] and rows[ny][nx] not in LOW:
                break


def ice_hops(rows, solid, x, y):
    """Cells Joe walks to over frozen lava from (x, y): an ice bolt shot along a facing freezes the unbroken run of
    lava in front of him, and he crosses it to the first walkable cell past it (within ICE_REACH tiles)."""
    h, w = len(rows), len(rows[0])
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        for k in range(1, ICE_REACH + 1):
            nx, ny = x + dx * k, y + dy * k
            if not (0 <= nx < w and 0 <= ny < h):
                break
            if rows[ny][nx] == "!":
                continue
            if k >= 2 and not solid[ny][nx]:
                yield nx, ny
            break


def neighbours_walk(rows, solid, x, y):
    """Cells reachable in one step from (x, y); walking south onto a ledge lands on the first cell past it; deep
    water is a step too (the flippers)."""
    h, w = len(rows), len(rows[0])
    yield from grapple_hops(rows, solid, x, y)
    yield from ice_hops(rows, solid, x, y)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if not (0 <= nx < w and 0 <= ny < h):
            continue
        if rows[ny][nx] == "v" and dy == 1:
            while ny < h and rows[ny][nx] == "v":
                ny += 1
            if ny < h and not solid[ny][nx]:
                yield nx, ny
        elif not solid[ny][nx] or rows[ny][nx] == WATER:
            yield nx, ny


def group_of(a):
    """Areas that scroll into each other share a group: each world's overworld, or one dungeon's rooms."""
    if a["kind"] == "overworld":
        return "overworld_dark" if a.get("world") == "dark" else "overworld"
    return a.get("dungeon")


def lint_world(areas, problems):
    by_id = {a["id"]: a for a in areas}
    solids = {a["id"]: lint_area(a, problems) for a in areas}
    passable = {aid: [[sv and a_rows[y][x] not in OPENABLE for x, sv in enumerate(row)] for y, row in enumerate(sm)]
                for aid, sm, a_rows in ((a["id"], solids[a["id"]], a["rows"]) for a in areas)}
    # Global occupancy per group (tile -> area id).
    owner = {}
    for a in areas:
        grp = group_of(a)
        if grp is None:
            continue
        ox, oy = a["origin_tiles"]
        for y in range(len(a["rows"])):
            for x in range(len(a["rows"][0])):
                key = (grp, ox + x, oy + y)
                if key in owner:
                    problems.append("overlap: %s and %s at tile %s" % (owner[key], a["id"], key[1:]))
                owner[key] = a["id"]
    # Edge openings must continue into a walkable (or openable) cell of a neighbour of the same group.
    entries = {a["id"]: [] for a in areas}
    for a in areas:
        grp = group_of(a)
        if grp is None:
            continue
        rows, solid = a["rows"], passable[a["id"]]
        ox, oy = a["origin_tiles"]
        h, w = len(rows), len(rows[0])
        for y in range(h):
            for x in range(w):
                if solid[y][x] or not (x in (0, w - 1) or y in (0, h - 1)):
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        continue
                    other = owner.get((grp, ox + nx, oy + ny))
                    if other is None:
                        problems.append("%s: opening at (%d,%d) leads off the world" % (a["id"], x, y))
                        continue
                    b = by_id[other]
                    bx, by = ox + nx - b["origin_tiles"][0], oy + ny - b["origin_tiles"][1]
                    if passable[other][by][bx]:
                        problems.append("%s: opening at (%d,%d) runs into a wall of %s" % (a["id"], x, y, other))
                    entries[a["id"]].append((x, y))
    # Doors and exits pair up.
    for a in areas:
        for d in a.get("doors", []):
            t = by_id.get(d["to"])
            if t is None:
                problems.append("%s: door to unknown area %s" % (a["id"], d["to"]))
                continue
            if not any(e["to"] == a["id"] for e in t.get("exits", [])):
                problems.append("%s: %s has no exit back" % (a["id"], d["to"]))
            sx, sy = d["spawn_cell"]
            if solids[t["id"]][sy][sx]:
                problems.append("%s: door spawn in %s is solid" % (a["id"], t["id"]))
            entries[t["id"]].append((sx, sy))
        for e in a.get("exits", []):
            t = by_id.get(e["to"])
            if t is None:
                problems.append("%s: exit to unknown area %s" % (a["id"], e["to"]))
                continue
            sx, sy = e["spawn_cell"]
            if solids[t["id"]][sy][sx]:
                problems.append("%s: exit spawn in %s is solid" % (a["id"], t["id"]))
            entries[t["id"]].append((sx, sy))
    # Reachability: everything that matters must be reachable from some entry of its area.
    spawns = 0
    seen_by = {}
    for a in areas:
        rows = a["rows"]
        solid = [[solids[a["id"]][y][x] and rows[y][x] not in OPENABLE for x in range(len(rows[0]))]
                 for y in range(len(rows))]
        src = list(entries[a["id"]])
        for y, r in enumerate(rows):
            for x, g in enumerate(r):
                if g == "P":
                    spawns += 1
                    src.append((x, y))
        if not src:
            problems.append("%s: no way in" % a["id"])
            continue
        seen = set(src)
        q = deque(src)
        while q:
            x, y = q.popleft()
            for n in neighbours_walk(rows, solid, x, y):
                if n not in seen:
                    seen.add(n)
                    q.append(n)
        for y, r in enumerate(rows):
            for x, g in enumerate(r):
                if g in ENEMIES or g in "OBM" and (x, y) not in seen:
                    if (x, y) not in seen:
                        problems.append("%s: %s at (%d,%d) is unreachable" % (a["id"], g, x, y))
        for d in a.get("doors", []):
            if tuple(d["cell"]) not in seen:
                problems.append("%s: door at %s is unreachable" % (a["id"], d["cell"]))
        for (x, y) in entries[a["id"]]:
            pass
        # Villagers and signs: glyphs match the lists, the text exists, and Joe can stand next to each one.
        lint_talkers(a, solid, seen, problems)
        lint_objects(a, seen, problems)
        seen_by[a["id"]] = seen
    if spawns != 1:
        problems.append("world: %d 'P' spawns (need exactly 1)" % spawns)
    # Moon Mirror targets and rifts: the Dark World twin of the cell must be walkable ground Joe can reach there.
    for a in areas:
        if a["kind"] != "overworld" or a.get("world") == "dark":
            continue
        twin = by_id.get(DARK_PREFIX + a["id"])
        for o in a.get("objects", []):
            if not (o.get("via_mirror") or o["kind"] == "rift"):
                continue
            x, y = o["cell"]
            if twin is None or tuple(o["cell"]) not in seen_by.get(twin["id"], set()):
                problems.append("%s: %s at (%d,%d) - its Dark World twin cell is not reachable" % (a["id"], o["kind"], x, y))
            if o["kind"] == "rift" and (x, y) not in seen_by.get(a["id"], set()):
                problems.append("%s: rift at (%d,%d) is unreachable" % (a["id"], x, y))
    if ACT2_SPAWN[0] not in by_id or tuple(ACT2_SPAWN[1]) not in seen_by.get(ACT2_SPAWN[0], set()):
        problems.append("world: the Act 2 arrival cell is not reachable")
    if FINAL_SPAWN[0] not in by_id or tuple(FINAL_SPAWN[1]) not in seen_by.get(FINAL_SPAWN[0], set()):
        problems.append("world: the cell Joe is saved on after the final ending is not reachable")
    # Keys per pool (overworld = None, else the dungeon id): small keys >= key blocks + distinct locked doors;
    # a big key wherever there is a big door or a big chest; the glove somewhere if a heavy rock exists.
    pools = {}
    for a in areas:
        pool = a.get("dungeon")
        p = pools.setdefault(pool, {"keys": 0, "locks": set(), "big_key": False, "needs_big": False})
        for o in a.get("objects", []):
            p["keys"] += o.get("item") == "small_key"
            p["big_key"] |= o.get("item") == "big_key"
            if o["kind"] == "key_block":
                p["locks"].add((a["id"], tuple(o["cell"])))
            if o["kind"] == "door" and o["type"] == "locked":
                p["locks"].add(o["id"])
            p["needs_big"] |= o["kind"] == "big_chest" or (o["kind"] == "door" and o["type"] == "big")
    for pool, p in pools.items():
        name = pool or "overworld"
        if p["keys"] < len(p["locks"]):
            problems.append("%s: %d locks but only %d small keys" % (name, len(p["locks"]), p["keys"]))
        if p["needs_big"] and not p["big_key"]:
            problems.append("%s: a big door or big chest but no big key" % name)
    every = [o for a in areas for o in a.get("objects", [])]
    held = {o.get("item") for o in every}
    if any(o["kind"] == "heavy_rock" for o in every) and "glove" not in held:
        problems.append("world: heavy rocks but no power glove anywhere")
    if any(o["kind"] == "rubble" for o in every) and "boots" not in held:
        problems.append("world: rubble but no dash boots anywhere")
    if any("F" in r for a in areas for r in a["rows"]) and "fire_rod" not in held:
        problems.append("world: a Frost Wraith but no fire rod anywhere")
    for info, _ in DUNGEONS:
        for key in ("music", "boss_music"):
            if key == "music" and key not in info:
                problems.append("%s: no music" % info["id"])
            if key in info and info[key] not in MUSIC_TRACKS:
                problems.append("%s: unknown %s %r" % (info["id"], key, info[key]))
    seals = sorted(info["seal"] for info, _ in DUNGEONS if info.get("seal", -1) >= 0)
    crystals = sorted(info["crystal"] for info, _ in DUNGEONS if "crystal" in info)
    if crystals != list(range(len(crystals))):
        problems.append("world: the dungeons hold crystals %s (need 0, 1, ... in order)" % crystals)
    if any(o["kind"] == "hook_post" for o in every) and "grapple" not in held:
        problems.append("world: hook posts but no grapple anywhere")
    if any("m" in r for a in areas for r in a["rows"]) and "grapple" not in held:
        problems.append("world: a Gloom Moth but no grapple anywhere")
    if any("I" in r for a in areas for r in a["rows"]) and "ice_rod" not in held:
        problems.append("world: a Magma Wyrm but no ice rod anywhere")
    if any(("p" in r or "t" in r) for a in areas for r in a["rows"]) and "hammer" not in held:
        problems.append("world: pegs or a Clock Warden but no hammer anywhere")
    if any("e" in r for a in areas for r in a["rows"]) and ("flippers" not in held or "fire_rod" not in held):
        problems.append("world: a Thornheart but no flippers (its island) or no fire rod (its thorns) anywhere")
    if seals != [0, 1, 2]:
        problems.append("world: the dungeons hold seals %s (need 0, 1, 2)" % seals)
    if any(o["kind"] == "seal_gate" for o in every) and not any(info.get("ending") for info, _ in DUNGEONS):
        problems.append("world: a seal gate but no dungeon behind it ends the act")
    if any(o["kind"] == "crystal_gate" for o in every):
        if not any(info.get("ending") == "final" for info, _ in DUNGEONS):
            problems.append("world: a crystal gate but no dungeon behind it ends the game")
        if crystals != [0, 1, 2, 3]:
            problems.append("world: a crystal gate needs crystals 0-3, the dungeons hold %s" % crystals)
    if any("y" in r for a in areas for r in a["rows"]) and not any(info.get("ending") == "final" for info, _ in DUNGEONS):
        problems.append("world: Caver waits in a dungeon that does not end the game")


def lint_objects(a, seen, problems):
    """Objects and wares: glyphs agree with the lists, contents exist, and Joe can use each one."""
    rows = a["rows"]
    listed = {tuple(o["cell"]): o for o in a.get("objects", [])}
    covered = set(listed)
    for o in a.get("objects", []):
        if o["kind"] == "door":                                   # doors cover a 2x2 doorway
            x, y = o["cell"]
            covered |= {(x + dx, y + dy) for dx in (0, 1) for dy in (0, 1)}
    for o in a.get("objects", []):
        if o["kind"] in GATES:                                    # a gate covers a 2x2 gateway
            x, y = o["cell"]
            covered |= {(x + dx, y + dy) for dx in (0, 1) for dy in (0, 1)}
    for y, r in enumerate(rows):
        for x, g in enumerate(r):
            if g in OBJECT_GLYPHS.values() and (x, y) not in covered:
                problems.append("%s: %s at (%d,%d) has no object entry" % (a["id"], g, x, y))
    torches = [o for o in a.get("objects", []) if o["kind"] == "torch"]
    switch_flags = {o.get("flag") for o in a.get("objects", []) if o["kind"] == "switch"}
    for (x, y), o in listed.items():
        if o["kind"] in GLYPHLESS:
            continue
        if o["kind"] == "door":
            # A boss door starts open (floor) and shuts behind Joe; every other door fills its doorway with [.
            want = "=" if o["type"] == "boss" else "["
            cells = [(x + dx, y + dy) for dx in (0, 1) for dy in (0, 1)]
            if any(rows[cy][cx] != want for cx, cy in cells):
                problems.append("%s: door %s does not fill its doorway" % (a["id"], o["id"]))
            if (x, y) != DOORWAYS[o["dir"]]:
                problems.append("%s: door %s is not on the %s doorway" % (a["id"], o["id"], o["dir"]))
            continue
        if rows[y][x] != OBJECT_GLYPHS[o["kind"]]:
            problems.append("%s: %s entry at (%d,%d) sits on %r" % (a["id"], o["kind"], x, y, rows[y][x]))
        near = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        if o["kind"] == "big_chest":
            near = [(x, y + 1), (x + 1, y + 1)]
        if o["kind"] == "switch":
            near = [(x, y)]
        if o["kind"] == "chest":
            if o["item"] not in ITEM_KINDS:
                problems.append("%s: chest at (%d,%d) holds unknown %r" % (a["id"], x, y, o["item"]))
            reveal = o.get("reveal", "")
            if reveal == "torches" and not torches:
                problems.append("%s: hidden chest at (%d,%d) but no torches to reveal it" % (a["id"], x, y))
            if reveal == "switch" and o.get("flag") not in switch_flags:
                problems.append("%s: hidden chest at (%d,%d) but no switch for %s" % (a["id"], x, y, o.get("flag")))
            near = [(x, y + 1)]                                   # chests open from below (ALttP)
        if o["kind"] == "heart_piece":
            near = [(x, y)]
        if o.get("via_mirror"):
            continue                                              # reached through the Dark World (checked later)
        if not any(p in seen for p in near):
            problems.append("%s: nobody can reach the %s at (%d,%d)" % (a["id"], o["kind"], x, y))
    for w in a.get("wares", []):
        x, y = w["cell"]
        if w["ware"] not in WARE_IDS:
            problems.append("%s: unknown ware %r" % (a["id"], w["ware"]))
        if rows[y][x] not in "Kx":
            problems.append("%s: ware %s at (%d,%d) is not on a table" % (a["id"], w["ware"], x, y))
        if (x, y + 1) not in seen:
            problems.append("%s: nobody can reach the ware at (%d,%d)" % (a["id"], x, y))


def lint_talkers(a, solid, seen, problems):
    rows = a["rows"]
    with open(DIALOGUE_JSON, encoding="utf-8") as f:
        dialogue = json.load(f)
    with open(NPC_MANIFEST, encoding="utf-8") as f:
        sprites = set(json.load(f)["npcs"])
    listed = {}
    across = {}                                  # villager cell -> facing step, for those talked to over a counter
    for n in a.get("npcs", []):
        listed[tuple(n["cell"])] = ("N", n["id"])
        if n.get("across"):
            across[tuple(n["cell"])] = FACING_STEP[n["facing"]]
        if n["id"] not in sprites:
            problems.append("%s: villager %s has no sprite" % (a["id"], n["id"]))
    for s_ in a.get("signs", []):
        listed[tuple(s_["cell"])] = ("S", s_["text"])
    for y, r in enumerate(rows):
        for x, g in enumerate(r):
            if g in "NS" and (x, y) not in listed:
                problems.append("%s: %s at (%d,%d) has no entry (no text)" % (a["id"], g, x, y))
    for (x, y), (g, key) in listed.items():
        if rows[y][x] != g:
            problems.append("%s: %s entry at (%d,%d) sits on %r" % (a["id"], g, x, y, rows[y][x]))
        if key not in dialogue:
            problems.append("%s: text %r at (%d,%d) is missing from dialogue.json" % (a["id"], key, x, y))
        near = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        if (x, y) in across:                     # over the counter: Joe stands two tiles out, along the facing
            dx, dy = across[(x, y)]
            near = [(x + 2 * dx, y + 2 * dy)]
        if not any(p in seen for p in near):
            problems.append("%s: nobody can reach the %s at (%d,%d)" % (a["id"], g, x, y))


# --------------------------------------------------------------------------- assembly

OVERWORLD = [
    # id, name, origin (screens), size (screens), builder
    ("meadow_north", "North Meadow", (0, 0), (2, 1), build_meadow_north),
    ("el_pueblo", "El Pueblo", (0, 1), (2, 2), build_el_pueblo),
    ("west_woods", "West Woods", (-1, 1), (1, 2), build_west_woods),
    ("east_lake", "East Lake", (2, 1), (1, 2), build_east_lake),
    ("south_road", "South Road", (0, 3), (2, 1), build_south_road),
    ("south_fields", "South Fields", (0, 4), (2, 2), build_south_fields),
]
INTERIORS = [
    ("joe_house", "Joe's House", "bedroom", True),
    ("tato_house", "Tato's House", "elder", False),
    ("boni_shop", "Boni's Shop", "shop", False),
    ("janga_house", "Janga's House", "home", False),
]
START_AREA = "joe_house"

# Villagers: area -> [(x, y, dialogue/sprite id, facing, talk_across)]. talk_across = Joe talks over the tile in
# front of the villager (Boni behind her counter).
NPCS = {
    "el_pueblo": [(15, 9, "villager_woman", "down", False), (30, 17, "villager_boy", "left", False)],
    "tato_house": [(10, 4, "tato", "down", False)],
    "boni_shop": [(7, 3, "boni", "down", True)],
    "janga_house": [(11, 4, "janga", "down", False)],
}
# Objects: area -> [(kind, x, y, extra)]. kind "rock" just puts an R (walls for a nook); chests carry
# {"item", "amount"?, "hidden"?} - a hidden chest appears once every torch of its area burns.
OBJECTS = {
    "joe_house": [("chest", 10, 2, {"item": "lantern"})],
    "meadow_north": [("torch", 28, 4, {}), ("torch", 39, 4, {}),
                     ("chest", 34, 7, {"item": "heart_piece", "reveal": "torches"}),
                     ("heart_piece", 34, 3, {"via_mirror": True})],
    "el_pueblo": [("rift", 20, 17, {})],
    "west_woods": [("cracked_rock", 2, 24, {}), ("rock", 3, 25, {}), ("heart_piece", 2, 25, {})],
    "east_lake": [("chest", 10, 7, {"item": "small_key"}), ("heavy_rock", 21, 21, {}), ("heart_piece", 21, 22, {}),
                  ("heavy_rock", 21, 23, {})],
    "south_road": [("rock", 42, 8, {}), ("key_block", 42, 9, {}), ("rock", 42, 10, {}), ("rock", 42, 11, {}),
                   ("chest", 44, 8, {"item": "bow"}),
                   # The road south: heavy rocks across the gap in the trees (the power glove lifts them).
                   ("heavy_rock", 22, 12, {}), ("heavy_rock", 23, 12, {}), ("heavy_rock", 24, 12, {}),
                   ("heavy_rock", 25, 12, {})],
    "south_fields": [("seal_gate", 15, 5, {}), ("rubble", 40, 17, {}), ("rift", 12, 10, {})],
    # Umbra: the chasm's island (grapple there by the post on its west edge, back by the post on the mainland).
    "dw_umbra_vale": [("hook_post", 36, 6, {}), ("hook_post", 28, 7, {}), ("heart_piece", 34, 5, {})],
    # Ignis: the posts across the lava river (the way in needs Umbra's grapple) and the lava pool's heart piece.
    "dw_cinder_barrens": [("hook_post", 10, 13, {}), ("hook_post", 2, 10, {}), ("heart_piece", 15, 20, {})],
    "dw_clockwork_wastes": [("heart_piece", 7, 23, {})],
    "dw_silva_tangle": [("heart_piece", 4, 14, {})],             # across the river: the flippers
    # Caver's tower stands where the keep stands in the Light World; four crystals open its gate.
    "dw_south_fields": [("crystal_gate", 15, 5, {})],
}
# Boni's wares on her counter (table cells): area -> [(x, y, ware id)].
WARES = {"boni_shop": [(5, 4, "bombs"), (9, 4, "arrows"), (11, 4, "heart_piece")],
         # The Shade Market: a stall in Hollow Pueblo (tables placed by DARK_EDITS).
         "dw_el_pueblo": [(8, 17, "dw_bombs"), (9, 17, "dw_arrows"), (12, 17, "dw_magic")]}
# Signs: area -> [(x, y, dialogue id)].
SIGNS = {
    "el_pueblo": [(20, 10, "sign_pueblo_cross"), (27, 17, "sign_pueblo_south")],
    "meadow_north": [(20, 10, "sign_meadow")],
    "west_woods": [(18, 11, "sign_woods"), (13, 7, "sign_shrine")],
    "east_lake": [(4, 11, "sign_lake")],
    "south_road": [(21, 4, "sign_south_road")],
    "south_fields": [(21, 3, "sign_fields"), (9, 17, "sign_rams_hollow"), (41, 19, "sign_frost_vault"),
                     (14, 8, "sign_keep")],
}


# The Moss Shrine (dungeon 1). Rooms are one screen each on their own grid; walls are two tiles thick and the
# doorways sit in the middle of each side (DOORWAYS). Doors are listed per side as (type, id, when): types
# "open", "locked" (small key), "big" (big key), "shutter" (opens when the flag `when` is set), "boss" (closes
# behind Joe until the boss falls), "stairs" (the way out). A door shared by two rooms appears in both with the
# same id, so it blocks from either side.
D1 = {"id": "d1", "name": "Moss Shrine", "seal": 0, "entrance": "d1_entrance", "boss_room": "d1_boss",
      "boss_flag": "boss:d1", "music": "shrine"}


def room_grid(doors):
    """A 24x14 room: floor inside two-tile walls, with each side's doorway carved as floor / door / stairs."""
    g = Grid(SCREEN[0], SCREEN[1], "=")
    g.rect(0, 0, g.w - 1, 1, "%")
    g.rect(0, g.h - 2, g.w - 1, g.h - 1, "%")
    g.rect(0, 0, 1, g.h - 1, "%")
    g.rect(g.w - 2, 0, g.w - 1, g.h - 1, "%")
    objects = []
    for side, spec in doors.items():
        kind = spec[0]
        x, y = DOORWAYS[side]
        if kind == "stairs":
            g.rect(x, y, x + 1, y, "s")                          # steps in the inner wall row, wall below them
            continue
        g.rect(x, y, x + 1, y + 1, "=" if kind in ("open", "boss") else "[")
        if kind not in ("open",):
            obj = {"kind": "door", "cell": [x, y], "dir": side, "type": kind, "id": spec[1], "when": spec[2]}
            if kind == "boss":
                obj["type"] = "boss"
            objects.append(obj)
    return g, objects


def d1_rooms():
    """(id, grid x, grid y, grid, objects, extra area fields) for every room of the Moss Shrine."""
    rooms = []

    def add(aid, gx, gy, doors, fill, extra=None):
        g, objs = room_grid(doors)
        more = fill(g) or []
        for kind, x, y, data in more:
            if kind in ("Z", "G", "Q", "Y", "O", "B", "+", "o", ";"):
                g.set(x, y, kind)
                continue
            if kind == "big_chest":
                g.piece(x, y, "$")
            else:
                g.place([(x, y)], OBJECT_GLYPHS[kind])
            objs.append(dict({"kind": kind, "cell": [x, y]}, **data))
        rooms.append((aid, gx, gy, g, objs, extra or {}))

    def entrance(g):
        return [("+", 5, 4, {}), ("+", 18, 4, {}), ("+", 5, 9, {}), ("+", 18, 9, {}), ("O", 3, 3, {}),
                ("O", 20, 3, {}), ("Z", 8, 7, {}), ("Z", 15, 7, {}), (";", 9, 10, {}), (";", 14, 3, {})]
    add("d1_entrance", 1, 3, {"n": ("open",), "s": ("stairs",)}, entrance)

    def hub(g):
        for x0, y0 in ((3, 3), (17, 3), (3, 9), (17, 9)):
            g.rect(x0, y0, x0 + 3, y0 + 1, "o")
        return [("+", 9, 5, {}), ("+", 14, 5, {}), ("+", 9, 8, {}), ("+", 14, 8, {}), ("G", 16, 7, {})]
    add("d1_hub", 1, 2, {"n": ("big", "d1_hub_north", ""), "s": ("open",), "w": ("open",),
                         "e": ("locked", "d1_hub_east", "")}, hub)

    def west(g):
        return [("chest", 4, 3, {"item": "map", "amount": 1, "reveal": ""}), ("+", 17, 4, {}), ("+", 17, 9, {}),
                ("Z", 6, 5, {}), ("Z", 10, 8, {}), ("G", 14, 5, {}), ("Q", 5, 9, {})]
    add("d1_west", 0, 2, {"e": ("open",), "n": ("shutter", "d1_west_north", "cleared:d1_west")}, west,
        {"clear_flag": "cleared:d1_west"})

    def northwest(g):
        g.rect(4, 6, 7, 6, "o")                                   # pits beside the block's path
        g.rect(9, 6, 12, 6, "o")
        return [("push_block", 8, 8, {}), ("switch", 8, 5, {"flag": "switch:d1_northwest", "heavy": True}),
                ("chest", 15, 4, {"item": "small_key", "amount": 1, "reveal": "switch", "flag": "switch:d1_northwest"}),
                ("Z", 17, 9, {}), ("Z", 4, 10, {})]
    add("d1_northwest", 0, 1, {"s": ("shutter", "d1_west_north", "cleared:d1_west")}, northwest)

    def east(g):
        g.rect(14, 2, 21, 6, "o")                                 # a pit field crossed by a one-tile bridge
        g.rect(17, 2, 17, 6, "=")
        return [("switch", 17, 3, {"flag": "switch:d1_east", "heavy": False}),
                ("chest", 4, 3, {"item": "compass", "amount": 1, "reveal": ""}),
                ("big_chest", 9, 8, {"item": "glove"}), ("Q", 5, 9, {}), ("Q", 20, 10, {})]
    add("d1_east", 2, 2, {"w": ("locked", "d1_hub_east", ""), "n": ("shutter", "d1_east_north", "switch:d1_east")},
        east)

    def northeast(g):
        g.rect(4, 5, 9, 5, "o")
        g.rect(14, 5, 19, 5, "o")
        return [("chest", 12, 3, {"item": "big_key", "amount": 1, "reveal": ""}), ("G", 6, 8, {}), ("G", 17, 8, {}),
                ("Z", 12, 9, {})]
    add("d1_northeast", 2, 1, {"s": ("shutter", "d1_east_north", "switch:d1_east")}, northeast)

    def ante(g):
        return [("torch", 9, 3, {}), ("torch", 14, 3, {}),
                ("chest", 12, 6, {"item": "gems", "amount": 50, "reveal": "torches"}),
                ("+", 4, 4, {}), ("+", 19, 4, {}), ("+", 4, 9, {}), ("+", 19, 9, {}), ("Z", 7, 9, {}), ("Z", 16, 9, {}),
                ("G", 12, 10, {})]
    add("d1_ante", 1, 1, {"s": ("big", "d1_hub_north", ""), "n": ("open",)}, ante)

    def boss(g):
        return [("+", 4, 3, {}), ("+", 19, 3, {}), ("+", 4, 10, {}), ("+", 19, 10, {}), ("Y", 11, 6, {})]
    add("d1_boss", 1, 0, {"s": ("boss", "d1_boss_door", D1["boss_flag"])}, boss, {"boss_flag": D1["boss_flag"]})
    return rooms


ROOM_GLYPHS = ("Z", "G", "Q", "Y", "A", "U", "F", "V", "X", "m", "c", "I", "z", "t", "j", "e", "y", "O", "B", "+", "o",
               "!", ";", "u", "n", "p", "~")


def make_room(rooms, aid, gx, gy, doors, fill, extra=None):
    """Build one dungeon room (room_grid + its contents) and append it to `rooms` like d1_rooms does."""
    g, objs = room_grid(doors)
    for kind, x, y, data in fill(g) or []:
        if kind in ROOM_GLYPHS:
            g.set(x, y, kind)
            continue
        if kind == "big_chest":
            g.piece(x, y, "$")
        else:
            g.place([(x, y)], OBJECT_GLYPHS[kind])
        objs.append(dict({"kind": kind, "cell": [x, y]}, **data))
    rooms.append((aid, gx, gy, g, objs, extra or {}))


D2 = {"id": "d2", "name": "Ram's Hollow", "seal": 1, "entrance": "d2_entrance", "boss_room": "d2_boss",
      "boss_flag": "boss:d2", "music": "shrine"}
D3 = {"id": "d3", "name": "Frost Vault", "seal": 2, "entrance": "d3_entrance", "boss_room": "d3_boss",
      "boss_flag": "boss:d3", "music": "shrine"}
KEEP = {"id": "keep", "name": "Caver's Keep", "seal": -1, "entrance": "keep_entrance", "boss_room": "keep_throne",
        "boss_flag": "boss:keep", "ending": "act1", "music": "shrine"}


def d2_rooms():
    """Ram's Hollow: clear the east room for the map and the way north (big key, a small key), open the west
    room with the key (big chest: Dash Boots), then the big door to the Iron Ram."""
    rooms = []
    make_room(rooms, "d2_entrance", 1, 2, {"n": ("open",), "s": ("stairs",)}, lambda g: [
        ("chest", 4, 3, {"item": "compass", "amount": 1, "reveal": ""}), ("+", 7, 6, {}), ("+", 16, 6, {}),
        ("A", 9, 4, {}), ("A", 15, 9, {}), ("O", 20, 3, {}), ("O", 20, 10, {})])

    def hall(g):
        g.rect(4, 4, 8, 5, "o")
        g.rect(15, 8, 19, 9, "o")
        return [("+", 11, 4, {}), ("+", 12, 9, {}), ("G", 6, 9, {}), ("Z", 17, 4, {})]
    make_room(rooms, "d2_hall", 1, 1, {"s": ("open",), "e": ("open",), "w": ("locked", "d2_hall_west", ""),
                                       "n": ("big", "d2_hall_north", "")}, hall)
    make_room(rooms, "d2_east", 2, 1, {"w": ("open",), "n": ("shutter", "d2_east_north", "cleared:d2_east")},
              lambda g: [("chest", 19, 3, {"item": "map", "amount": 1, "reveal": ""}), ("G", 8, 5, {}),
                         ("G", 14, 8, {}), ("A", 11, 4, {}), ("Q", 18, 9, {})], {"clear_flag": "cleared:d2_east"})

    def northeast(g):
        g.rect(9, 6, 14, 7, "o")
        return [("chest", 5, 3, {"item": "small_key", "amount": 1, "reveal": ""}),
                ("chest", 18, 3, {"item": "big_key", "amount": 1, "reveal": ""}), ("Z", 6, 9, {}), ("Z", 17, 9, {}),
                ("A", 12, 3, {})]
    make_room(rooms, "d2_northeast", 2, 0, {"s": ("shutter", "d2_east_north", "cleared:d2_east")}, northeast)
    make_room(rooms, "d2_west", 0, 1, {"e": ("locked", "d2_hall_west", "")}, lambda g: [
        ("big_chest", 10, 4, {"item": "boots"}), ("+", 5, 8, {}), ("+", 16, 8, {}), ("G", 6, 4, {}),
        ("G", 15, 4, {})])
    make_room(rooms, "d2_boss", 1, 0, {"s": ("boss", "d2_boss_door", D2["boss_flag"])},
              lambda g: [("U", 11, 5, {})], {"boss_flag": D2["boss_flag"]})
    return rooms


def d3_rooms():
    """The Frost Vault: light the west room's torches for the small key, open the east room (dash through the
    rubble to the big chest: Fire Rod; its switch opens the way to the big key), then the Frost Wraith."""
    rooms = []
    make_room(rooms, "d3_entrance", 1, 2, {"n": ("open",), "s": ("stairs",)}, lambda g: [
        ("+", 6, 5, {}), ("+", 17, 5, {}), ("A", 8, 8, {}), ("A", 15, 4, {}), ("Z", 12, 9, {}), (";", 10, 3, {})])

    def hub(g):
        g.rect(9, 4, 14, 5, "o")
        return [("+", 4, 9, {}), ("+", 19, 9, {}), ("G", 6, 4, {}), ("Q", 17, 8, {})]
    make_room(rooms, "d3_hub", 1, 1, {"s": ("open",), "w": ("open",), "e": ("locked", "d3_hub_east", ""),
                                      "n": ("big", "d3_hub_north", "")}, hub)
    make_room(rooms, "d3_west", 0, 1, {"e": ("open",)}, lambda g: [
        ("torch", 6, 3, {}), ("torch", 15, 3, {}),
        ("chest", 10, 6, {"item": "small_key", "amount": 1, "reveal": "torches"}),
        ("chest", 4, 10, {"item": "map", "amount": 1, "reveal": ""}), ("A", 8, 9, {}), ("A", 16, 8, {})])

    def east(g):
        g.rect(2, 5, 21, 5, "+")                           # a pillar wall across the room...
        g.set(12, 5, "=")                                  # ...with one gap, choked with rubble
        return [("rubble", 12, 5, {}), ("big_chest", 8, 2, {"item": "fire_rod"}),
                ("switch", 17, 3, {"flag": "switch:d3_east", "heavy": False}),
                ("chest", 4, 9, {"item": "compass", "amount": 1, "reveal": ""}), ("G", 15, 9, {}), ("Z", 8, 8, {})]
    make_room(rooms, "d3_east", 2, 1, {"w": ("locked", "d3_hub_east", ""),
                                       "n": ("shutter", "d3_east_north", "switch:d3_east")}, east)
    make_room(rooms, "d3_northeast", 2, 0, {"s": ("shutter", "d3_east_north", "switch:d3_east")}, lambda g: [
        ("chest", 12, 3, {"item": "big_key", "amount": 1, "reveal": ""}), ("G", 6, 7, {}), ("G", 17, 7, {}),
        ("A", 12, 8, {})])
    make_room(rooms, "d3_boss", 1, 0, {"s": ("boss", "d3_boss_door", D3["boss_flag"])},
              lambda g: [("+", 4, 3, {}), ("+", 19, 3, {}), ("F", 11, 5, {})], {"boss_flag": D3["boss_flag"]})
    return rooms


def keep_rooms():
    """Caver's Keep: a guarded hall, then the throne room where Caver's shade waits (the end of Act 1)."""
    rooms = []
    make_room(rooms, "keep_entrance", 0, 1, {"s": ("stairs",), "e": ("open",)}, lambda g: [
        ("+", 6, 4, {}), ("+", 6, 9, {}), ("+", 17, 4, {}), ("+", 17, 9, {}), ("G", 12, 4, {}), ("A", 12, 9, {})])
    make_room(rooms, "keep_gallery", 1, 1, {"w": ("open",), "n": ("open",)}, lambda g: [
        ("+", 5, 4, {}), ("+", 18, 4, {}), ("+", 5, 9, {}), ("+", 18, 9, {}), ("G", 8, 6, {}), ("G", 16, 7, {}),
        ("A", 12, 9, {})])
    make_room(rooms, "keep_throne", 1, 0, {"s": ("boss", "keep_throne_door", KEEP["boss_flag"])},
              lambda g: [("+", 3, 3, {}), ("+", 20, 3, {}), ("V", 11, 5, {})], {"boss_flag": KEEP["boss_flag"]})
    return rooms


# The Umbra Sanctum (Dark World dungeon 1): the first dimension crystal. Dark rooms ("dark": True) are black but
# for Joe's light until their torches burn.
D4 = {"id": "d4", "name": "Umbra Sanctum", "crystal": 0, "entrance": "d4_entrance", "boss_room": "d4_boss",
      "boss_flag": "boss:d4", "music": "dimension"}


def d4_rooms():
    """The Umbra Sanctum: light the dark hall (map) and the dark west room (small key), open the east room (big key,
    big chest: the Grapple), grapple across its chasm to the switch that opens the hall's north shutter (and the
    compass), then the Gloom Moth."""
    rooms = []
    make_room(rooms, "d4_entrance", 1, 2, {"n": ("open",), "s": ("stairs",)}, lambda g: [
        ("+", 6, 5, {}), ("+", 17, 5, {}), ("X", 8, 8, {}), ("X", 15, 8, {}), ("O", 3, 3, {}), ("O", 20, 3, {}),
        (";", 11, 9, {})])

    def hall(g):
        g.rect(4, 9, 7, 10, "o")
        g.rect(16, 9, 19, 10, "o")
        return [("torch", 9, 3, {}), ("torch", 14, 3, {}),
                ("chest", 12, 6, {"item": "map", "amount": 1, "reveal": "torches"}),
                ("X", 5, 5, {}), ("X", 18, 5, {}), ("A", 12, 9, {})]
    make_room(rooms, "d4_hall", 1, 1, {"s": ("open",), "w": ("open",), "e": ("locked", "d4_hall_east", ""),
                                       "n": ("shutter", "d4_hall_north", "switch:d4_east")}, hall, {"dark": True})

    def west(g):
        g.rect(8, 4, 15, 4, "o")
        return [("torch", 5, 3, {}), ("torch", 18, 3, {}), ("torch", 11, 10, {}),
                ("chest", 11, 6, {"item": "small_key", "amount": 1, "reveal": "torches"}),
                ("X", 6, 8, {}), ("X", 16, 8, {}), ("A", 12, 2, {})]
    make_room(rooms, "d4_west", 0, 1, {"e": ("open",)}, west, {"dark": True})

    def east(g):
        g.rect(13, 2, 15, 11, "o")                     # the chasm splits the room
        return [("big_chest", 4, 3, {"item": "grapple"}),
                ("chest", 8, 3, {"item": "big_key", "amount": 1, "reveal": ""}),
                ("hook_post", 17, 6, {}), ("hook_post", 11, 9, {}),
                ("switch", 19, 3, {"flag": "switch:d4_east", "heavy": False}),
                ("chest", 19, 9, {"item": "compass", "amount": 1, "reveal": ""}),
                ("X", 18, 6, {}), ("A", 7, 9, {})]
    make_room(rooms, "d4_east", 2, 1, {"w": ("locked", "d4_hall_east", "")}, east)
    make_room(rooms, "d4_boss", 1, 0, {"s": ("boss", "d4_boss_door", D4["boss_flag"])},
              lambda g: [("+", 4, 3, {}), ("+", 19, 3, {}), ("+", 4, 10, {}), ("+", 19, 10, {}), ("m", 11, 6, {})],
              {"boss_flag": D4["boss_flag"]})
    return rooms


# The Ignis Forge (Dark World dungeon 2): the second dimension crystal.
D5 = {"id": "d5", "name": "Ignis Forge", "crystal": 1, "entrance": "d5_entrance", "boss_room": "d5_boss",
      "boss_flag": "boss:d5", "music": "dimension"}


def d5_rooms():
    """The Ignis Forge: the entrance's small key opens the east room; the big key waits on a lava islet in the west
    room (grapple there and back); the east room's big chest holds the Ice Rod, whose bolts freeze a path over the
    lava to the switch that opens the hall's north shutter; then the Magma Wyrm."""
    rooms = []

    def entrance(g):
        g.rect(3, 3, 6, 4, "!")
        g.rect(17, 3, 20, 4, "!")
        return [("chest", 11, 4, {"item": "small_key", "amount": 1, "reveal": ""}), ("c", 7, 8, {}), ("c", 16, 8, {}),
                (";", 9, 10, {})]
    make_room(rooms, "d5_entrance", 1, 2, {"n": ("open",), "s": ("stairs",)}, entrance)

    def hall(g):
        for x0, y0 in ((4, 3), (16, 3), (4, 9), (16, 9)):
            g.rect(x0, y0, x0 + 3, y0 + 1, "!")
        return [("chest", 8, 6, {"item": "map", "amount": 1, "reveal": ""}), ("c", 15, 7, {}), ("A", 10, 9, {})]
    make_room(rooms, "d5_hall", 1, 1, {"s": ("open",), "w": ("open",), "e": ("locked", "d5_hall_east", ""),
                                       "n": ("shutter", "d5_hall_north", "switch:d5_east")}, hall)

    def west(g):
        g.rect(4, 3, 15, 9, "!")                       # a lava lake...
        g.rect(9, 5, 11, 7, "=")                       # ...with an islet
        return [("hook_post", 9, 6, {}), ("chest", 10, 5, {"item": "big_key", "amount": 1, "reveal": ""}),
                ("hook_post", 17, 7, {}), ("chest", 19, 3, {"item": "compass", "amount": 1, "reveal": ""}),
                ("c", 18, 10, {}), ("c", 5, 11, {})]
    make_room(rooms, "d5_west", 0, 1, {"e": ("open",)}, west)

    def east(g):
        g.rect(13, 2, 15, 11, "!")                     # a lava channel splits the room
        return [("big_chest", 4, 3, {"item": "ice_rod"}),
                ("switch", 19, 3, {"flag": "switch:d5_east", "heavy": False}),
                ("chest", 19, 9, {"item": "gems", "amount": 50, "reveal": ""}), ("c", 18, 6, {}), ("A", 7, 9, {})]
    make_room(rooms, "d5_east", 2, 1, {"w": ("locked", "d5_hall_east", "")}, east)

    def boss(g):
        for x0, y0 in ((5, 3), (17, 3), (5, 8), (17, 8)):
            g.rect(x0, y0, x0 + 1, y0 + 1, "!")
        return [("I", 11, 7, {})]
    make_room(rooms, "d5_boss", 1, 0, {"s": ("boss", "d5_boss_door", D5["boss_flag"])}, boss,
              {"boss_flag": D5["boss_flag"]})
    return rooms


# The Tempus Clocktower (Dark World dungeon 3): the third dimension crystal.
D6 = {"id": "d6", "name": "Tempus Clocktower", "crystal": 2, "entrance": "d6_entrance", "boss_room": "d6_boss",
      "boss_flag": "boss:d6", "music": "dimension"}


def d6_rooms():
    """The Tempus Clocktower: tick blocks everywhere; the entrance's small key opens the east room, the big key
    sits inside a ring of tick blocks in the west room, the big chest's Hammer pounds the pegs in the east room and
    those barring the hall's north doorway; then the Clock Warden."""
    rooms = []

    def entrance(g):
        tick_row(g, 2, 21, 7)
        return [("chest", 4, 3, {"item": "small_key", "amount": 1, "reveal": ""}), ("G", 16, 3, {}),
                ("O", 3, 10, {}), ("O", 20, 10, {})]
    make_room(rooms, "d6_entrance", 1, 2, {"n": ("open",), "s": ("stairs",)}, entrance)

    def hall(g):
        tick_col(g, 6, 3, 10)
        tick_col(g, 17, 3, 10, False)
        return [("p", 11, 2, {}), ("p", 12, 2, {}),               # pegs bar the way north
                ("chest", 15, 4, {"item": "map", "amount": 1, "reveal": ""}), ("G", 9, 9, {}), ("A", 14, 7, {})]
    make_room(rooms, "d6_hall", 1, 1, {"s": ("open",), "w": ("open",), "e": ("locked", "d6_hall_east", ""),
                                       "n": ("open",)}, hall)

    def west(g):
        tick_row(g, 2, 7, 6)                                     # a ring of tick blocks around the big key
        tick_col(g, 7, 2, 5, False)
        return [("chest", 4, 3, {"item": "big_key", "amount": 1, "reveal": ""}),
                ("chest", 18, 9, {"item": "compass", "amount": 1, "reveal": ""}), ("G", 12, 8, {}), ("G", 17, 4, {})]
    make_room(rooms, "d6_west", 0, 1, {"e": ("open",)}, west)

    def east(g):
        g.rect(13, 2, 13, 11, "p")                               # a wall of pegs
        return [("big_chest", 4, 3, {"item": "hammer"}),
                ("chest", 19, 9, {"item": "gems", "amount": 50, "reveal": ""}), ("z", 18, 5, {}), ("z", 17, 9, {})]
    make_room(rooms, "d6_east", 2, 1, {"w": ("locked", "d6_hall_east", "")}, east)

    def boss(g):
        for x, y, amber in ((5, 4, True), (18, 4, False), (5, 9, False), (18, 9, True)):
            g.set(x, y, "u" if amber else "n")
        return [("t", 11, 5, {})]
    make_room(rooms, "d6_boss", 1, 0, {"s": ("boss", "d6_boss_door", D6["boss_flag"])}, boss,
              {"boss_flag": D6["boss_flag"]})
    return rooms


# The Silva Grove (Dark World dungeon 4): the fourth and last dimension crystal.
D7 = {"id": "d7", "name": "Silva Grove", "crystal": 3, "entrance": "d7_entrance", "boss_room": "d7_boss",
      "boss_flag": "boss:d7", "music": "dimension"}


def d7_rooms():
    """The Silva Grove: pools everywhere; the entrance's small key opens the east room, the big key waits behind a
    fence of pegs in the west room, the east room's big chest holds the Flippers, which swim the pool barring the
    hall's north doorway; then the Thornheart on its island (the fire rod burns its thorns back)."""
    rooms = []

    def entrance(g):
        g.rect(3, 3, 6, 4, "~")
        g.rect(17, 3, 20, 4, "~")
        return [("chest", 11, 4, {"item": "small_key", "amount": 1, "reveal": ""}), ("j", 7, 8, {}), ("j", 16, 8, {}),
                ("O", 3, 10, {}), ("O", 20, 10, {})]
    make_room(rooms, "d7_entrance", 1, 2, {"n": ("open",), "s": ("stairs",)}, entrance)

    def hall(g):
        g.rect(8, 2, 15, 4, "~")                                 # a pool in front of the north doorway
        return [("chest", 4, 9, {"item": "map", "amount": 1, "reveal": ""}), ("j", 18, 8, {}), ("A", 7, 7, {})]
    make_room(rooms, "d7_hall", 1, 1, {"s": ("open",), "w": ("open",), "e": ("locked", "d7_hall_east", ""),
                                       "n": ("open",)}, hall)

    def west(g):
        g.rect(2, 6, 7, 6, "p")                                  # pegs fence the big key's corner
        g.rect(7, 2, 7, 5, "p")
        g.rect(11, 4, 18, 9, "~")                                # a pool with an islet (the compass: swim there)
        g.rect(14, 6, 15, 7, "=")
        return [("chest", 4, 3, {"item": "big_key", "amount": 1, "reveal": ""}),
                ("chest", 14, 6, {"item": "compass", "amount": 1, "reveal": ""}), ("j", 9, 10, {}), ("A", 19, 3, {})]
    make_room(rooms, "d7_west", 0, 1, {"e": ("open",)}, west)

    def east(g):
        g.rect(13, 2, 15, 11, "~")                               # a channel splits the room
        return [("big_chest", 4, 3, {"item": "flippers"}),
                ("chest", 19, 9, {"item": "gems", "amount": 50, "reveal": ""}), ("j", 18, 5, {}), ("j", 8, 9, {})]
    make_room(rooms, "d7_east", 2, 1, {"w": ("locked", "d7_hall_east", "")}, east)

    def boss(g):
        g.rect(4, 3, 19, 10, "~")                                # a moat around the Thornheart's island
        g.rect(7, 5, 16, 8, "=")
        return [("e", 11, 7, {})]
    make_room(rooms, "d7_boss", 1, 0, {"s": ("boss", "d7_boss_door", D7["boss_flag"])}, boss,
              {"boss_flag": D7["boss_flag"]})
    return rooms


# Caver's tower (the final dungeon, Dark World): behind the crystal gate; one floor per dimension, each needing that
# dimension's item, then Caver himself. Beating him ends the game ("ending": "final"); like the keep, no reward.
D8 = {"id": "d8", "name": "Caver's Tower", "seal": -1, "entrance": "d8_entrance", "boss_room": "d8_boss",
      "boss_flag": "boss:d8", "ending": "final", "music": "tower", "boss_music": "caver"}


def d8_rooms():
    """Caver's tower, climbed floor by floor (north = up): the entrance (map); the Umbra floor, dark, its torches
    hiding the small key and a chasm only the grapple crosses to the locked door; the Ignis floor, a lava band the
    ice rod freezes; the Tempus floor, pegs (the hammer) before the big door and tick blocks, with the Silva floor
    to the west where the big key sits on an islet (the flippers); the antechamber's pots; then Caver."""
    rooms = []
    make_room(rooms, "d8_entrance", 1, 5, {"n": ("open",), "s": ("stairs",)}, lambda g: [
        ("chest", 4, 10, {"item": "map", "amount": 1, "reveal": ""}), ("+", 6, 4, {}), ("+", 17, 4, {}),
        ("+", 6, 9, {}), ("+", 17, 9, {}), ("G", 9, 6, {}), ("G", 14, 6, {}), ("A", 12, 9, {}), ("O", 3, 3, {}),
        ("O", 20, 3, {})])

    def umbra(g):
        g.rect(2, 5, 21, 7, "o")                                   # a chasm across the floor
        return [("hook_post", 8, 3, {}), ("hook_post", 15, 9, {}), ("torch", 5, 10, {}), ("torch", 18, 10, {}),
                ("chest", 11, 9, {"item": "small_key", "amount": 1, "reveal": "torches"}),
                ("X", 6, 9, {}), ("X", 17, 3, {}), ("A", 12, 3, {})]
    make_room(rooms, "d8_umbra", 1, 4, {"s": ("open",), "n": ("locked", "d8_umbra_north", "")}, umbra, {"dark": True})

    def ignis(g):
        g.rect(2, 4, 21, 8, "!")                                   # a band of lava
        return [("chest", 19, 10, {"item": "compass", "amount": 1, "reveal": ""}), ("c", 6, 3, {}), ("c", 17, 3, {}),
                ("c", 8, 10, {})]
    make_room(rooms, "d8_ignis", 1, 3, {"s": ("locked", "d8_umbra_north", ""), "n": ("open",)}, ignis)

    def tempus(g):
        g.rect(2, 3, 21, 3, "p")                                   # pegs before the big door
        tick_row(g, 2, 21, 9)                                      # and a fence of tick blocks
        return [("z", 6, 6, {}), ("z", 17, 6, {}), ("A", 12, 5, {})]
    make_room(rooms, "d8_tempus", 1, 2, {"s": ("open",), "w": ("open",), "n": ("big", "d8_tempus_north", "")}, tempus)

    def silva(g):
        g.rect(3, 3, 17, 10, "~")                                  # a deep pool...
        g.rect(9, 6, 11, 7, "=")                                   # ...and the big key's islet
        return [("chest", 10, 6, {"item": "big_key", "amount": 1, "reveal": ""}), ("j", 19, 3, {}), ("j", 19, 10, {})]
    make_room(rooms, "d8_silva", 0, 2, {"e": ("open",)}, silva)

    make_room(rooms, "d8_ante", 1, 1, {"s": ("big", "d8_tempus_north", ""), "n": ("open",)}, lambda g: [
        ("+", 5, 4, {}), ("+", 18, 4, {}), ("+", 5, 9, {}), ("+", 18, 9, {}), ("O", 3, 3, {}), ("O", 20, 3, {}),
        ("O", 3, 10, {}), ("O", 20, 10, {}), ("G", 8, 6, {}), ("G", 15, 6, {})])
    make_room(rooms, "d8_boss", 1, 0, {"s": ("boss", "d8_boss_door", D8["boss_flag"])}, lambda g: [
        ("+", 4, 3, {}), ("+", 19, 3, {}), ("+", 4, 10, {}), ("+", 19, 10, {}), ("y", 11, 5, {})],
        {"boss_flag": D8["boss_flag"], "intro": "caver_tower_intro"})
    return rooms


DUNGEONS = [(D1, d1_rooms), (D2, d2_rooms), (D3, d3_rooms), (KEEP, keep_rooms), (D4, d4_rooms), (D5, d5_rooms),
            (D6, d6_rooms), (D7, d7_rooms), (D8, d8_rooms)]
DUNGEON_STRIDE = 200                     # tiles between two dungeons' room grids


# The Dark World: every overworld area has a twin at the same coordinates (so the Moon Mirror maps a point to the
# same point), its own scroll group, a rotten palette and no doors. Its rows are the Light World's with villagers,
# signs and objects stripped, plus per-area changes (DARK_EDITS) and its own villagers, signs and enemies.
DARK_PREFIX = "dw_"
DARK_NAMES = {"el_pueblo": "Hollow Pueblo", "meadow_north": "Withered Meadow", "west_woods": "Thorn Woods",
              "east_lake": "Ash Lake", "south_road": "Broken Road", "south_fields": "Dead Fields"}
STRIP = set("NSClkhrbL")                  # Light World-only cells become plain ground in the Dark World
ACT2_SPAWN = ("dw_el_pueblo", (23, 14))   # where Caver's spell drops Joe
FINAL_SPAWN = ("dw_south_fields", (15, 8))  # where Joe is saved after the final ending: before the fallen tower
DARK_DOORS = {                            # Dark World doors (twins have none of the Light World's): Caver's tower
    "south_fields": [{"cell": [15, 6], "to": "d8_entrance"}, {"cell": [16, 6], "to": "d8_entrance"}],
}
DARK_EDITS = {
    # The meadow's pond is dry in the Dark World: walk to the island's twin and mirror back onto it.
    "meadow_north": lambda g: ([g.set(x, y, ",") for y in range(2, 6) for x in range(30, 38) if g.get(x, y) == "~"],
                               g.rect(22, 0, 25, 5, "#")),     # ...and the trees part north, toward Umbra
    "el_pueblo": lambda g: (g.piece(8, 17, "K"), g.piece(11, 17, "K")),   # the Shade Market's stall
    "east_lake": lambda g: g.rect(20, 12, 23, 15, "#"),                   # the shore path runs on east, to Ignis
    "south_road": lambda g: g.rect(0, 8, 1, 11, "#"),                     # the road's west end opens, to Tempus
    # The woods' west edge opens onto Silva, behind a row of pegs (the hammer).
    "west_woods": lambda g: (g.rect(0, 12, 5, 15, "#"), g.rect(3, 12, 3, 15, "p")),
}
# Dark World-only areas (the dimensions' lands): no Light World twin, so the Moon Mirror does nothing there.
DARK_ONLY = [
    ("dw_umbra_vale", "Umbral Vale", (0, -1), (2, 1), build_umbra_vale),
    ("dw_cinder_barrens", "Cinder Barrens", (3, 1), (1, 2), build_cinder_barrens),
    ("dw_clockwork_wastes", "Clockwork Wastes", (-1, 3), (1, 2), build_clockwork_wastes),
    ("dw_silva_tangle", "Silva Tangle", (-2, 1), (1, 2), build_silva_tangle),
]
DARK_EXTRA = {                            # Dark World enemies added on top of the Light World's
    "el_pueblo": [(10, 20, "A"), (36, 9, "Z"), (40, 21, "G")],
    "meadow_north": [(12, 9, "G"), (24, 4, "A"), (44, 7, "Z")],
    "west_woods": [(14, 11, "A"), (6, 21, "G")],
    "east_lake": [(6, 10, "A"), (8, 21, "G")],
    "south_road": [(30, 3, "A"), (12, 9, "G")],
    "south_fields": [(26, 16, "A"), (12, 24, "G"), (35, 22, "A")],
}
NPCS.update({"dw_el_pueblo": [(19, 11, "tato_echo", "down", False), (10, 16, "shade_merchant", "down", False)]})
SIGNS.update({
    "dw_el_pueblo": [(20, 10, "dw_sign_pueblo")],
    "dw_meadow_north": [(20, 10, "dw_sign_umbra")],
    "dw_west_woods": [(18, 11, "dw_sign_silva")],
    "dw_east_lake": [(4, 11, "dw_sign_ignis")],
    "dw_south_road": [(21, 4, "dw_sign_tempus")],
    "dw_south_fields": [(21, 3, "dw_sign_fields")],
    "dw_umbra_vale": [(20, 7, "dw_sign_sanctum")],
    "dw_cinder_barrens": [(13, 6, "dw_sign_forge")],
    "dw_clockwork_wastes": [(18, 13, "dw_sign_clockyard")],
    "dw_silva_tangle": [(18, 11, "dw_sign_grove")],
})


def place_near(g, x, y, glyph, reach=4):
    """Put `glyph` on the free grass cell nearest to (x, y) (rings of growing radius, scanned in a fixed order)."""
    for r in range(reach + 1):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if max(abs(dx), abs(dy)) == r and g.get(x + dx, y + dy) in (".", ","):
                    g.set(x + dx, y + dy, glyph)
                    return
    raise ValueError("no free cell near (%d,%d) for %s" % (x, y, glyph))


def dark_twin(a):
    """The Dark World twin of overworld area `a` (same origin and size, its own group)."""
    rows = [[("." if c in STRIP else c) for c in r] for r in a["rows"]]
    g = Grid(len(rows[0]), len(rows))
    g.cells = rows
    edit = DARK_EDITS.get(a["id"])
    if edit:
        edit(g)
    for x, y, glyph in DARK_EXTRA.get(a["id"], []):
        place_near(g, x, y, glyph)
    did = DARK_PREFIX + a["id"]
    extras = add_people_and_signs(g, did)
    return {"id": did, "name": DARK_NAMES[a["id"]], "kind": "overworld", "world": "dark",
            "size_screens": a["size_screens"], "origin_tiles": a["origin_tiles"], "rows": g.rows(),
            "doors": [dict(d) for d in DARK_DOORS.get(a["id"], [])], "exits": [], **extras}


def add_people_and_signs(g, aid):
    """Stand the area's villagers and signs on the grid (N / S glyphs) and return their JSON lists."""
    npcs, signs = [], []
    for x, y, nid, facing, across in NPCS.get(aid, []):
        g.place([(x, y)], "N")
        npcs.append({"id": nid, "cell": [x, y], "facing": facing, "across": across})
    for x, y, text in SIGNS.get(aid, []):
        g.place([(x, y)], "S")
        signs.append({"cell": [x, y], "text": text})
    objects = []
    for kind, x, y, extra in OBJECTS.get(aid, []):
        if kind == "rock":
            g.place([(x, y)], "R")
            continue
        if kind not in GLYPHLESS:
            g.place([(x, y)], OBJECT_GLYPHS[kind])
        obj = {"kind": kind, "cell": [x, y]}
        if extra.get("via_mirror"):
            obj["via_mirror"] = True
        if kind == "chest":
            obj.update({"item": extra["item"], "amount": extra.get("amount", 1), "reveal": extra.get("reveal", "")})
        objects.append(obj)
    wares = [{"ware": w, "cell": [x, y]} for x, y, w in WARES.get(aid, [])]
    return {"npcs": npcs, "signs": signs, "objects": objects, "wares": wares}


def assemble():
    rng = random.Random(SEED)
    areas = []
    for aid, name, origin, size, builder in OVERWORLD:
        g, doors = builder(rng)
        extras = add_people_and_signs(g, aid)
        areas.append({"id": aid, "name": name, "kind": "overworld", "size_screens": list(size),
                      "origin_tiles": [origin[0] * SCREEN[0], origin[1] * SCREEN[1]],
                      "rows": g.rows(), "doors": doors, "exits": [], **extras})
    by_id = {a["id"]: a for a in areas}
    for i, (aid, name, kind, spawn) in enumerate(INTERIORS):
        g = build_interior(kind, rng, spawn)
        extras = add_people_and_signs(g, aid)
        rows = g.rows()
        mats = [[x, y] for y, r in enumerate(rows) for x, c in enumerate(r) if c == "M"]
        areas.append({"id": aid, "name": name, "kind": "interior", "size_screens": [1, 1],
                      "origin_tiles": [INTERIOR_BASE[0] + i * INTERIOR_STRIDE, INTERIOR_BASE[1]],
                      "rows": rows, "doors": [], "exits": [], **extras})
    for a in [x for x in areas if x["kind"] == "overworld"]:
        areas.append(dark_twin(a))
    for aid, name, origin, size, builder in DARK_ONLY:
        g, doors = builder(rng)
        extras = add_people_and_signs(g, aid)
        areas.append({"id": aid, "name": name, "kind": "overworld", "world": "dark", "size_screens": list(size),
                      "origin_tiles": [origin[0] * SCREEN[0], origin[1] * SCREEN[1]],
                      "rows": g.rows(), "doors": doors, "exits": [], **extras})
    for i, (info, rooms_of) in enumerate(DUNGEONS):
        base = (DUNGEON_BASE[0] + i * DUNGEON_STRIDE, DUNGEON_BASE[1])
        for aid, gx, gy, g, objects, extra in rooms_of():
            extras = add_people_and_signs(g, aid)
            extras["objects"] = objects + extras["objects"]
            areas.append({"id": aid, "name": info["name"], "kind": "dungeon", "dungeon": info["id"],
                          "size_screens": [1, 1], "origin_tiles": [base[0] + gx * SCREEN[0], base[1] + gy * SCREEN[1]],
                          "grid": [gx, gy], "rows": g.rows(), "doors": [], "exits": [], **extras, **extra})
    # Pair doors with what they lead into: the door leads to the cell above the target's mat / stairs; the mat or
    # stairs lead back below the door.
    for a in list(areas):
        for d in a["doors"]:
            t = next(x for x in areas if x["id"] == d["to"])
            mats = [[x, y] for y, r in enumerate(t["rows"]) for x, c in enumerate(r) if c in "Ms"]
            d["spawn_cell"] = [mats[0][0], mats[0][1] - 1]
            d["facing"] = "up"
            t["exits"].append({"cells": mats, "to": a["id"], "spawn_cell": [d["cell"][0], d["cell"][1] + 1],
                               "facing": "down"})
    return areas


def write(areas):
    os.makedirs(OUT_DIR, exist_ok=True)
    for f in os.listdir(OUT_DIR):
        if f.endswith(".json"):
            os.remove(os.path.join(OUT_DIR, f))
    for a in areas:
        with open(os.path.join(OUT_DIR, a["id"] + ".json"), "w", encoding="utf-8", newline="\n") as fh:
            json.dump(a, fh, indent=1)
    index = {"screen": list(SCREEN), "start": START_AREA, "areas": [a["id"] for a in areas],
             "act2_spawn": {"area": ACT2_SPAWN[0], "cell": list(ACT2_SPAWN[1])},
             "final_spawn": {"area": FINAL_SPAWN[0], "cell": list(FINAL_SPAWN[1])},
             "dungeons": {info["id"]: {k: v for k, v in info.items() if k != "id"} for info, _ in DUNGEONS}}
    with open(os.path.join(OUT_DIR, "index.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(index, fh, indent=1)


# --------------------------------------------------------------------------- preview

def render(areas):
    """Compose the overworld (and the interiors) from the real atlas so the generator output can be eyeballed."""
    try:
        from PIL import Image
    except ImportError:
        return
    atlas = Image.open(ATLAS_PNG).convert("RGBA")
    manifest = json.load(open(ATLAS_JSON, encoding="utf-8"))["cells"]

    def tile(name):
        cx, cy = manifest[name]["cell"]
        return atlas.crop((cx * TILE, cy * TILE, cx * TILE + TILE, cy * TILE + TILE))

    def nine(rows, x, y, same, base):
        def gl(xx, yy):
            return rows[yy][xx] if 0 <= yy < len(rows) and 0 <= xx < len(rows[0]) else same   # off-area: seamless
        l, r, u, d = gl(x - 1, y) != same, gl(x + 1, y) != same, gl(x, y - 1) != same, gl(x, y + 1) != same
        dx = 0 if l == r else (-1 if l else 1)
        dy = 0 if u == d else (-1 if u else 1)
        return "%s_%d_%d" % (base, dx, dy)

    def paint(img, rows, ox, oy, indoor):
        simple = {".": "grass_a", ",": "grass_b", "*": "flowers", "R": "rock", "f": "fence", "S": "sign",
                  "_": "floor", "M": "mat", "=": "dfloor", ";": "dfloor_b", "+": "pillar", "s": "dstairs"}
        for y, r in enumerate(rows):
            for x, g in enumerate(r):
                px, py = ox + x * TILE, oy + y * TILE
                name = None
                if g == "x":
                    continue
                if g in simple:
                    name = simple[g]
                elif g == "#":
                    name = nine(rows, x, y, "#", "path")
                elif g == "~":
                    name = nine(rows, x, y, "~", "water")
                elif g == "v":
                    l = x == 0 or r[x - 1] != "v"
                    rr = x == len(r) - 1 or r[x + 1] != "v"
                    name = "ledge_s" if l and rr else ("ledge_l" if l else ("ledge_r" if rr else "ledge_m"))
                elif g == "^":
                    name = "cliff" if y > 0 and rows[y - 1][x] == "^" else "cliff_top"
                elif g in "Ww":
                    below = rows[y + 1][x] if y + 1 < len(rows) else ""
                    name = ("wall_shelf" if g == "w" else "wall_face") if below and below not in "Ww" else "wall_top"
                elif g == "o":
                    name = nine(rows, x, y, "o", "pit")
                elif g == "%":
                    below = rows[y + 1][x] if y + 1 < len(rows) else ""
                    name = "dwall_face" if below and below != "%" else "dwall_top"
                elif g == "$":
                    for tx in range(2):
                        img.alpha_composite(tile("dfloor"), (px + tx * TILE, py))
                    for yy in range(4, 12):
                        for xx in range(4, 28):
                            img.putpixel((px + xx, py + yy), (208, 136, 64, 255))
                    continue
                elif g == "E":
                    for ty in range(3):
                        for tx in range(5):
                            img.alpha_composite(tile("shrine_%d_%d" % (tx, ty)), (px + tx * TILE, py + ty * TILE))
                    continue
                elif g in MULTI:
                    pw, ph = MULTI[g]
                    for ty in range(ph):
                        for tx in range(pw):
                            if g == "T":
                                n = "tree_%d_%d" % (tx, ty)
                            elif g in "HJ":
                                n = "house_%s_%d_%d" % ("red" if g == "H" else "blue", tx, ty)
                            elif g == "K":
                                n = "table_l" if tx == 0 else "table_r"
                            else:
                                n = "bed_t" if ty == 0 else "bed_b"
                            img.alpha_composite(tile(n), (px + tx * TILE, py + ty * TILE))
                    continue
                else:
                    name = {"dungeon": "dfloor", True: "floor", False: "grass_a"}[indoor]
                img.alpha_composite(tile(name), (px, py))
                marks = {"B": (56, 144, 76), "O": (176, 104, 60), "Z": (60, 136, 200), "G": (144, 28, 68),
                         "Q": (224, 104, 56), "P": (255, 255, 255), "N": (248, 208, 64),
                         "C": (208, 136, 64), "L": (248, 112, 32), "k": (88, 88, 104), "l": (176, 176, 196),
                         "h": (232, 40, 64), "[": (124, 76, 36), "@": (200, 160, 48), "&": (124, 124, 140),
                         "$": (208, 136, 64), "r": (70, 70, 84), "Y": (76, 160, 60)}
                if g in marks:
                    for yy in range(4, 12):
                        for xx in range(4, 12):
                            img.putpixel((px + xx, py + yy), marks[g] + (255,))

    ow = [a for a in areas if a["kind"] == "overworld"]
    minx = min(a["origin_tiles"][0] for a in ow)
    miny = min(a["origin_tiles"][1] for a in ow)
    maxx = max(a["origin_tiles"][0] + len(a["rows"][0]) for a in ow)
    maxy = max(a["origin_tiles"][1] + len(a["rows"]) for a in ow)
    img = Image.new("RGBA", ((maxx - minx) * TILE, (maxy - miny) * TILE), (20, 16, 32, 255))
    for a in ow:
        paint(img, a["rows"], (a["origin_tiles"][0] - minx) * TILE, (a["origin_tiles"][1] - miny) * TILE, False)
    img.save(PREVIEW)
    ins = [a for a in areas if a["kind"] == "interior"]
    img2 = Image.new("RGBA", (len(ins) * 17 * TILE, 11 * TILE), (20, 16, 32, 255))
    for i, a in enumerate(ins):
        paint(img2, a["rows"], i * 17 * TILE, 0, True)
    img2.save(PREVIEW_IN)
    rooms = [a for a in areas if a["kind"] == "dungeon"]
    if rooms:
        gw = max(a["grid"][0] for a in rooms) + 1
        gh = max(a["grid"][1] for a in rooms) + 1
        img3 = Image.new("RGBA", (gw * SCREEN[0] * TILE, gh * SCREEN[1] * TILE), (20, 16, 32, 255))
        for a in rooms:
            paint(img3, a["rows"], a["grid"][0] * SCREEN[0] * TILE, a["grid"][1] * SCREEN[1] * TILE, "dungeon")
        img3.save(PREVIEW_DUNGEON)


def main():
    areas = assemble()
    problems = []
    lint_world(areas, problems)
    for p in problems:
        print("LINT:", p)
    write(areas)
    render(areas)
    print("%d areas (%d overworld, %d interiors, %d dungeon rooms); %d lint problems"
          % (len(areas), sum(a["kind"] == "overworld" for a in areas), sum(a["kind"] == "interior" for a in areas),
             sum(a["kind"] == "dungeon" for a in areas), len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
