# File: gen_areas.py
# Description: Builds every overworld area, house interior and dungeon room as ASCII rows with their villagers, signs, chests, torches, rocks, key blocks, heart pieces, wares, doors, switches and blocks, lints them (sizes, pieces, openings, reachability, ledges, doors, dialogue keys, item kinds, keys vs locks, big keys) and writes src/world/areas/*.json plus previews.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-16
# Version: 3.0.1
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
SOLID = set("R~v^fSTHJWwKDNCLkl%+o[&r")
ACTORS = set("BOZGQPhY")          # h = a heart piece lying on the ground, Y = a dungeon boss
OPENABLE = set("kl[&r")            # solid until a bomb / key / push / glove opens them (reachability: open)
GROUND = set(".,*#_M=;@s")         # = ; dungeon floor, @ floor switch, s exit stairs
VALID = SOLID | ACTORS | GROUND | {"x"} | set(MULTI)
ENEMIES = set("ZGQY")
FACING_STEP = {"down": (0, 1), "up": (0, -1), "left": (-1, 0), "right": (1, 0)}
# Everything a chest, gift or ware may hand out - mirrors ItemDB.KINDS in src/items/ItemDB.gd (test_items.gd
# checks that every kind used by the areas exists there).
ITEM_KINDS = {"lantern", "boomerang", "bow", "bombs", "arrows", "small_key", "heart_piece", "heart_container", "gems",
              "map", "compass", "big_key", "glove"}
WARE_IDS = {"bombs", "arrows", "heart_piece"}                       # ItemDB.WARES
OBJECT_GLYPHS = {"chest": "C", "torch": "L", "cracked_rock": "k", "key_block": "l", "heart_piece": "h", "door": "[",
                 "switch": "@", "push_block": "&", "big_chest": "$", "heavy_rock": "r"}
DOORWAYS = {"n": (11, 0), "s": (11, 12), "w": (0, 6), "e": (22, 6)}   # top-left cell of each 2x2 dungeon doorway
OPEN_LO, OPEN_HI = 10, 14         # edge openings are 4 tiles wide, centred on each side of a screen pair
# Openings: north/south at columns 22..25 of a 2-screen-wide area, east/west at rows 12..15 of a 2-screen-tall one.


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
    g.tree_border({"n": (22, 25)})
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


# --------------------------------------------------------------------------- interiors

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


def neighbours_walk(rows, solid, x, y):
    """Cells reachable in one step from (x, y); walking south onto a ledge lands on the first cell past it."""
    h, w = len(rows), len(rows[0])
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if not (0 <= nx < w and 0 <= ny < h):
            continue
        if rows[ny][nx] == "v" and dy == 1:
            while ny < h and rows[ny][nx] == "v":
                ny += 1
            if ny < h and not solid[ny][nx]:
                yield nx, ny
        elif not solid[ny][nx]:
            yield nx, ny


def group_of(a):
    """Areas that scroll into each other share a group: the overworld, or one dungeon's rooms."""
    return "overworld" if a["kind"] == "overworld" else a.get("dungeon")


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
    if spawns != 1:
        problems.append("world: %d 'P' spawns (need exactly 1)" % spawns)
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
    if any(o["kind"] == "heavy_rock" for o in every) and not any(o.get("item") == "glove" for o in every):
        problems.append("world: heavy rocks but no power glove anywhere")


def lint_objects(a, seen, problems):
    """Objects and wares: glyphs agree with the lists, contents exist, and Joe can use each one."""
    rows = a["rows"]
    listed = {tuple(o["cell"]): o for o in a.get("objects", [])}
    covered = set(listed)
    for o in a.get("objects", []):
        if o["kind"] == "door":                                   # doors cover a 2x2 doorway
            x, y = o["cell"]
            covered |= {(x + dx, y + dy) for dx in (0, 1) for dy in (0, 1)}
    for y, r in enumerate(rows):
        for x, g in enumerate(r):
            if g in OBJECT_GLYPHS.values() and (x, y) not in covered:
                problems.append("%s: %s at (%d,%d) has no object entry" % (a["id"], g, x, y))
    torches = [o for o in a.get("objects", []) if o["kind"] == "torch"]
    switch_flags = {o.get("flag") for o in a.get("objects", []) if o["kind"] == "switch"}
    for (x, y), o in listed.items():
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
                     ("chest", 34, 7, {"item": "heart_piece", "reveal": "torches"})],
    "west_woods": [("cracked_rock", 2, 24, {}), ("rock", 3, 25, {}), ("heart_piece", 2, 25, {})],
    "east_lake": [("chest", 10, 7, {"item": "small_key"}), ("heavy_rock", 21, 21, {}), ("heart_piece", 21, 22, {}),
                  ("heavy_rock", 21, 23, {})],
    "south_road": [("rock", 42, 8, {}), ("key_block", 42, 9, {}), ("rock", 42, 10, {}), ("rock", 42, 11, {}),
                   ("chest", 44, 8, {"item": "bow"})],
}
# Boni's wares on her counter (table cells): area -> [(x, y, ware id)].
WARES = {"boni_shop": [(5, 4, "bombs"), (9, 4, "arrows"), (11, 4, "heart_piece")]}
# Signs: area -> [(x, y, dialogue id)].
SIGNS = {
    "el_pueblo": [(20, 10, "sign_pueblo_cross"), (27, 17, "sign_pueblo_south")],
    "meadow_north": [(20, 10, "sign_meadow")],
    "west_woods": [(18, 11, "sign_woods"), (13, 7, "sign_shrine")],
    "east_lake": [(4, 11, "sign_lake")],
    "south_road": [(21, 4, "sign_south_road")],
}


# The Moss Shrine (dungeon 1). Rooms are one screen each on their own grid; walls are two tiles thick and the
# doorways sit in the middle of each side (DOORWAYS). Doors are listed per side as (type, id, when): types
# "open", "locked" (small key), "big" (big key), "shutter" (opens when the flag `when` is set), "boss" (closes
# behind Joe until the boss falls), "stairs" (the way out). A door shared by two rooms appears in both with the
# same id, so it blocks from either side.
D1 = {"id": "d1", "name": "Moss Shrine", "seal": 0, "entrance": "d1_entrance", "boss_room": "d1_boss",
      "boss_flag": "boss:d1"}


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
        g.place([(x, y)], OBJECT_GLYPHS[kind])
        obj = {"kind": kind, "cell": [x, y]}
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
    for aid, gx, gy, g, objects, extra in d1_rooms():
        extras = add_people_and_signs(g, aid)
        extras["objects"] = objects + extras["objects"]
        areas.append({"id": aid, "name": D1["name"], "kind": "dungeon", "dungeon": D1["id"], "size_screens": [1, 1],
                      "origin_tiles": [DUNGEON_BASE[0] + gx * SCREEN[0], DUNGEON_BASE[1] + gy * SCREEN[1]],
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
             "dungeons": {D1["id"]: {k: v for k, v in D1.items() if k != "id"}}}
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
