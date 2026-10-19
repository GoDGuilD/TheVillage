# File: gen_npcs.py
# Description: Generates the villagers (Tato, Boni, Janga, a village woman and a village boy, and Tato's Dark World echo) as 32x32 idle strips facing down, up and side, plus their manifest and a preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-20
# Version: 1.1.0
#
# Run:  python -I tools/gen_npcs.py
# Writes assets/sprites/npcs/<id>_idle_<down|up|side>.png (2 frames each, side faces right - the engine flips it),
# assets/sprites/npcs/npcs.json and tmp/npcs_preview.png. Same build as Joe (big ALttP head, short body) so the
# cast reads as one world; every NPC is a parameter set for one figure painter.
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from palette import (APRON_DARK, APRON_MID, BANDANA_D, BANDANA_M, BARK_MID, BOOT_DARK, BOOT_MID, DRESS_DARK,
                     DRESS_LIGHT, DRESS_MID, HAIR_DARK, HAIR_GREY, HAIR_LIGHT, HAIR_MID, HAIR_ORANGE_D,
                     HAIR_ORANGE_M, HAIR_WHITE, OUTLINE, PANTS_DARK, PANTS_MID, ROBE_DARK, ROBE_LIGHT, ROBE_MID,
                     SHADOW, SHIRT_GREEN_D, SHIRT_GREEN_M, SKIN_DARK, SKIN_LIGHT, SKIN_MID, TUNIC_DARK, TUNIC_MID,
                     VEST_DARK, VEST_LIGHT, VEST_MID, BARK_DARK, GOLD, WHITE, RIFT_DARK, RIFT_MID, RIFT_LIGHT,
                     PORTAL_LIGHT)
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "npcs")
PREVIEW = os.path.join(ROOT, "tmp", "npcs_preview.png")
FRAME = 32
FEET = (16, 29)                     # pixel under the NPC's feet (the node origin in Godot)
FPS = 2.0                           # slow idle breathing
FACINGS = ("down", "up", "side")
EYE = OUTLINE                       # villagers have dark eyes (Joe's green eyes stay his own)

# Every villager: body style, colours, hair style, height offset (children stand lower), props.
NPCS = {
    "tato": {"body": "robe", "cloth": (ROBE_DARK, ROBE_MID, ROBE_LIGHT), "legs": (ROBE_DARK, ROBE_DARK),
             "hair": "bald", "hair_col": (HAIR_GREY, HAIR_WHITE, WHITE), "beard": True, "staff": True, "shrink": 1},
    # Tato's echo: the old man as the Dark World remembers him - a pale violet ghost (Phase 8).
    "tato_echo": {"body": "robe", "cloth": (RIFT_DARK, RIFT_MID, RIFT_LIGHT), "legs": (RIFT_DARK, RIFT_DARK),
                  "hair": "bald", "hair_col": (RIFT_MID, PORTAL_LIGHT, WHITE), "beard": True, "staff": True, "shrink": 1},
    "boni": {"body": "apron", "cloth": (SHIRT_GREEN_D, SHIRT_GREEN_M, APRON_MID), "legs": (PANTS_DARK, PANTS_MID),
             "hair": "bun", "hair_col": (HAIR_ORANGE_D, HAIR_ORANGE_M, HAIR_ORANGE_M), "beard": False,
             "staff": False, "shrink": 0},
    "janga": {"body": "vest", "cloth": (VEST_DARK, VEST_MID, VEST_LIGHT), "legs": (PANTS_DARK, PANTS_MID),
              "hair": "bandana", "hair_col": (HAIR_DARK, HAIR_MID, HAIR_LIGHT), "beard": False, "staff": False,
              "shrink": 0},
    "villager_woman": {"body": "dress", "cloth": (DRESS_DARK, DRESS_MID, DRESS_LIGHT), "legs": (DRESS_DARK, DRESS_MID),
                       "hair": "long", "hair_col": (HAIR_DARK, HAIR_MID, HAIR_LIGHT), "beard": False,
                       "staff": False, "shrink": 0},
    "villager_boy": {"body": "tunic", "cloth": (TUNIC_DARK, TUNIC_MID, TUNIC_MID), "legs": (PANTS_DARK, PANTS_MID),
                     "hair": "short", "hair_col": (HAIR_ORANGE_D, HAIR_ORANGE_M, HAIR_ORANGE_M), "beard": False,
                     "staff": False, "shrink": 2},
}


# --------------------------------------------------------------------------- body parts

def _legs(c, cx, fy, npc, side):
    """Legs and shoes (hidden under a robe or a long dress, which reach the ground)."""
    if npc["body"] in ("robe", "dress"):
        c.rect(cx - 4, fy - 2, 3, 2, BOOT_MID)
        c.rect(cx + 1, fy - 2, 3, 2, BOOT_MID)
        c.rect(cx - 4, fy - 1, 8, 1, BOOT_DARK)
        return
    dark, mid = npc["legs"]
    if side:
        c.rect(cx - 2, fy - 6, 3, 4, mid)
        c.rect(cx - 2, fy - 2, 4, 2, BOOT_MID)
        c.rect(cx - 2, fy - 1, 4, 1, BOOT_DARK)
        return
    for x0 in (cx - 4, cx + 1):
        c.rect(x0, fy - 6, 3, 4, mid)
        c.rect(x0 + 2, fy - 6, 1, 4, dark)
        c.rect(x0, fy - 2, 3, 2, BOOT_MID)
        c.rect(x0, fy - 1, 3, 1, BOOT_DARK)


def _torso(c, cx, fy, npc, view, shrink=0):
    """Clothing body for view 'down' / 'up' / 'side' (side faces right); shrink shortens it from the top (children)."""
    dark, mid, light = npc["cloth"]
    body = npc["body"]
    long_body = body in ("robe", "dress")
    bottom = fy - 2 if long_body else fy - 5
    half = 4 if view == "side" else 5
    top = fy - 12 + shrink
    c.rect(cx - half, top, half * 2, bottom - top, mid)
    if long_body:                                   # flared hem
        c.rect(cx - half - 1, bottom - 4, half * 2 + 2, 4, mid)
        c.rect(cx - half - 1, bottom - 1, half * 2 + 2, 1, dark)
    c.rect(cx - half, top, 1, bottom - top, light if view != "side" else dark)
    c.rect(cx + half - 1, top, 1, bottom - top, dark)
    if body == "apron" and view != "up":
        x0 = cx - 3 if view == "down" else cx
        c.rect(x0, fy - 10, 6 if view == "down" else 4, 6, APRON_MID)
        c.rect(x0, fy - 5, 6 if view == "down" else 4, 1, APRON_DARK)
    elif body == "vest" and view == "down":
        c.rect(cx - 1, top, 2, bottom - top, light)   # shirt showing between the vest panels
        c.set(cx - 3, fy - 9, GOLD)                    # a buckle on the strap
    elif body == "robe":
        c.rect(cx - half, fy - 8, half * 2, 1, GOLD)   # rope belt
    elif body == "tunic":
        c.rect(cx - half, fy - 7, half * 2, 1, BARK_DARK)          # belt


def _arms(c, cx, fy, npc, view, bob):
    dark, mid, light = npc["cloth"]
    sleeve = mid if npc["body"] != "vest" else npc["cloth"][2]
    if view == "side":
        c.rect(cx - 1, fy - 12 + bob, 2, 5, sleeve)
        c.rect(cx - 1, fy - 7 + bob, 2, 2, SKIN_MID)
        return
    for x in (cx - 7, cx + 5):
        c.rect(x, fy - 12 + bob, 2, 5, sleeve)
        c.rect(x, fy - 7 + bob, 2, 2, SKIN_MID)
        c.set(x, fy - 7 + bob, SKIN_LIGHT)


def _head(c, cx, fy, npc, view, blink):
    """Big head with the NPC's hair style; side view faces right."""
    hd, hm, hl = npc["hair_col"]
    hy = fy - 18
    style = npc["hair"]
    rx = 5.6 if view == "side" else 6.2
    hx = cx if view == "side" else cx - 0.5
    c.ellipse(hx, hy, rx, 5.6, SKIN_LIGHT)
    if view == "up":
        if style == "bald":
            c.rect(cx - 6, hy + 1, 12, 3, hm)            # white fringe around the back of the head
            c.ellipse(cx - 2, hy - 3, 2.0, 1.4, WHITE)    # shine on the crown
        else:
            c.ellipse(hx, hy, rx, 5.6, hm)
            c.ellipse(cx - 2, hy - 2, 2.6, 1.6, hl)
            c.rect(cx - 6, hy + 3, 12, 2, hd)
        if style == "long":
            c.rect(cx - 6, hy + 3, 12, 6, hm)
            c.rect(cx - 6, hy + 8, 12, 1, hd)
        if style == "bun":
            c.ellipse(cx - 0.5, hy - 6, 2.5, 2.0, hd)
        if style == "bandana":
            c.rect(cx - 6, hy - 3, 12, 2, BANDANA_M)
            c.rect(cx - 1, hy - 1, 3, 3, BANDANA_D)       # the knot
        return
    if view == "down":
        if style == "bald":
            c.rect(cx - 7, hy - 1, 2, 4, hm)              # white tufts over the ears
            c.rect(cx + 5, hy - 1, 2, 4, hm)
            c.ellipse(cx - 2.5, hy - 4, 2.0, 1.2, WHITE)  # shine
            c.rect(cx - 4, hy - 1, 3, 1, hm)              # bushy brows
            c.rect(cx + 1, hy - 1, 3, 1, hm)
        else:
            for y in range(hy - 6, hy - 1):
                for x in range(cx - 7, cx + 7):
                    if ((x - hx) / rx) ** 2 + ((y - hy) / 5.6) ** 2 <= 1.0:
                        c.set(x, y, hm)
            c.rect(cx - 7, hy - 2, 2, 5 if style != "long" else 10, hm)
            c.rect(cx + 5, hy - 2, 2, 5 if style != "long" else 10, hm)
            c.ellipse(cx - 2, hy - 4, 2.5, 1.2, hl)
            if style == "bun":
                c.ellipse(cx - 0.5, hy - 7, 2.5, 1.8, hd)
            if style == "bandana":
                c.rect(cx - 6, hy - 4, 12, 2, BANDANA_M)
                c.rect(cx - 6, hy - 3, 12, 1, BANDANA_D)
        for ex in (cx - 3, cx + 2):
            c.set(ex, hy + 1, EYE)
            if not blink:
                c.set(ex, hy, EYE)
        c.set(cx - 1, hy + 2, SKIN_DARK)
        if npc["beard"]:
            c.ellipse(cx - 0.5, hy + 5, 4.5, 3.5, hm)
            c.rect(cx - 2, hy + 3, 3, 1, hl)              # moustache
            c.ellipse(cx - 0.5, hy + 7, 2.5, 2, hd)
        else:
            c.rect(cx - 5, hy + 3, 10, 1, SKIN_MID)
        return
    # Side view (facing right): hair over the top and the back of the head.
    if style == "bald":
        c.rect(cx - 6, hy - 1, 4, 4, hm)
        c.ellipse(cx - 1, hy - 4, 2.0, 1.2, WHITE)
        c.rect(cx + 1, hy - 1, 3, 1, hm)
    else:
        for y in range(hy - 6, hy + 6):
            for x in range(cx - 6, cx + 7):
                inside = ((x - cx) / 5.6) ** 2 + ((y - hy) / 5.6) ** 2 <= 1.0
                if inside and (y < hy - 1 or x < cx - 1):
                    c.set(x, y, hm)
        c.ellipse(cx - 2, hy - 3, 2.2, 1.4, hl)
        if style == "long":
            c.rect(cx - 6, hy + 2, 5, 7, hm)
            c.rect(cx - 6, hy + 8, 5, 1, hd)
        if style == "bun":
            c.ellipse(cx - 5, hy - 5, 2.2, 2.0, hd)
        if style == "bandana":
            c.rect(cx - 5, hy - 4, 11, 2, BANDANA_M)
            c.rect(cx - 8, hy - 3, 3, 2, BANDANA_D)       # tails behind
    c.set(cx + 6, hy + 1, SKIN_MID)
    c.set(cx - 1, hy + 1, SKIN_DARK)
    c.set(cx + 3, hy + 1, EYE)
    if not blink:
        c.set(cx + 3, hy, EYE)
    if npc["beard"]:
        c.ellipse(cx + 3, hy + 5, 3.2, 3.0, hm)
        c.ellipse(cx + 3, hy + 7, 2, 1.6, hd)


def _staff(c, cx, fy, view, bob):
    """Tato's walking staff, held on his right."""
    x = cx + 8 if view == "down" else (cx - 8 if view == "up" else cx + 3)
    c.rect(x, fy - 24 + bob, 2, 23, BARK_MID)
    c.rect(x + 1, fy - 24 + bob, 1, 23, BARK_DARK)
    c.ellipse(x + 0.5, fy - 25 + bob, 2, 2, BARK_DARK)


def frame(npc, view, i):
    """One idle frame: frame 1 breathes (body 1 px lower) and blinks."""
    c = Canvas(FRAME, FRAME)
    cx, fy = FEET[0], FEET[1]
    bob = 1 if i == 1 else 0
    top = Canvas(FRAME, FRAME)
    s = npc["shrink"]
    _legs(c, cx, fy, npc, view == "side")
    if npc["staff"] and view == "up":
        _staff(top, cx, fy, view, 0)
    _torso(top, cx, fy, npc, view, s)
    _arms(top, cx, fy + s // 2, npc, view, 0)
    _head(top, cx, fy + s, npc, view, blink=(i == 1 and view != "up"))
    if npc["staff"] and view != "up":
        _staff(top, cx, fy, view, 0)
    c.paste(top, 0, bob)
    c.outline(OUTLINE)
    out = Canvas(FRAME, FRAME)
    out.ellipse(cx - 0.5, fy, 6, 1.6, SHADOW)
    out.paste(c)
    return out


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    manifest = {"frame": [FRAME, FRAME], "feet": list(FEET), "fps": FPS, "npcs": sorted(NPCS)}
    rows = []
    for nid, npc in NPCS.items():
        strips = []
        for view in FACINGS:
            strip = pack_strip([frame(npc, view, i) for i in range(2)])
            strip.save(os.path.join(OUT_DIR, "%s_idle_%s.png" % (nid, view)))
            strips.append(strip)
        rows.append(strips)
    with open(os.path.join(OUT_DIR, "npcs.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, indent=1)
    # Preview: one row per NPC, the three facings side by side, on grass green.
    w = FRAME * 2 * len(FACINGS)
    sheet = Image.new("RGBA", (w, FRAME * len(rows)), (72, 160, 72, 255))
    for r, strips in enumerate(rows):
        for k, s in enumerate(strips):
            sheet.alpha_composite(s, (k * FRAME * 2, r * FRAME))
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(sheet, 4).save(PREVIEW)
    print("%d villagers x %d facings written; preview %s" % (len(NPCS), len(FACINGS), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
