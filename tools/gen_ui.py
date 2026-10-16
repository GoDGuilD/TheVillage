# File: gen_ui.py
# Description: Generates the UI art: the two bitmap fonts, the ALttP-style HUD pieces (magic meter, item box, key icon), dialogue/menu boxes, cursor, continue arrow, item-menu slots, seals, equipment icons and the title logo, plus a preview sheet.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
#
# Run:  python -I tools/gen_ui.py
# Writes assets/ui/ (font_5x7.png/.json, font_3x5.png/.json, hud/*, menu/*, title_logo.png, ui_manifest.json)
# and tmp/ui_preview.png. Every colour comes from tools/palette.py; never hand-edit the PNGs.
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from font_glyphs import G3_TEXT, G5_TEXT
from palette import (CLEAR, GOLD, GOLD_DARK, HILT_DARK, INK, KEY_DARK, KEY_LIGHT, KEY_MID, LOGO_LOW, LOGO_MID,
                     LOGO_SHADE, LOGO_TOP, MAGIC_DARK, MAGIC_LIGHT, MAGIC_MID, OUTLINE, SEAL_DARK, SEAL_LIGHT,
                     SEAL_MID, SHIELD_DARK, SHIELD_FACE, SHIELD_RIM, STEEL_DARK, STEEL_LIGHT, STEEL_MID, UI_BOX_EDGE,
                     UI_BOX_FILL, UI_GOLD, UI_GOLD_DARK, UI_RIM_DARK, UI_RIM_LIGHT, UI_RIM_MID, UI_WELL, WHITE)
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI_DIR = os.path.join(ROOT, "assets", "ui")
HUD_DIR = os.path.join(UI_DIR, "hud")
MENU_DIR = os.path.join(UI_DIR, "menu")
PREVIEW = os.path.join(ROOT, "tmp", "ui_preview.png")

MAGIC_UNITS = 32                    # the magic meter well is one pixel per unit (GameState.MAX_MAGIC)
BOX_BORDER = 8                      # nine-slice border of the dialogue / menu boxes
CAPTION_BORDER = 5
LOGO_TEXT = "THE VILLAGE"
LOGO_SCALE = 3                      # logo letters are the 5x7 glyphs drawn 3x

MANIFEST = {}


def save(img, folder, name, frames=1, notes=""):
    """Write a PNG (Canvas or PIL image) and record it in the manifest."""
    im = img.img if isinstance(img, Canvas) else img
    os.makedirs(folder, exist_ok=True)
    im.save(os.path.join(folder, name))
    rel = os.path.relpath(os.path.join(folder, name), UI_DIR).replace("\\", "/")
    MANIFEST[rel] = {"size": [im.width // frames, im.height], "frames": frames, "notes": notes}
    return im


# --------------------------------------------------------------------------- fonts

def parse_glyphs(text):
    """Parse the glyph source text into {char: (y_offset, [rows])}."""
    glyphs, cur = {}, None
    for line in text.split("\n"):
        if line.startswith("="):
            ch = line[1]
            yoff = int(line.rsplit("|", 1)[1])
            cur = glyphs[ch] = (yoff, [])
        elif line.strip() and cur is not None:
            cur[1].append(line.strip())
    return glyphs


def build_font(glyphs, cell, name, space_adv, lowercase_from_upper):
    """Lay glyphs out 16 per row in ASCII order (white, no outline; the engine tints them) and write PNG + JSON.
    Returns the sheet so the logo and preview can reuse it."""
    cw, ch = cell
    cols, first = 16, 32
    sheet = Canvas(cols * cw, ((128 - first) // cols) * ch)
    advance = {" ": space_adv}
    for code in range(first, 127):
        c = chr(code)
        src = c.upper() if (lowercase_from_upper and c.islower()) else c
        if src not in glyphs:
            continue
        yoff, rows = glyphs[src]
        width = max(len(r) for r in rows)
        assert width <= cw - 1 and yoff + len(rows) <= ch, "glyph %r does not fit its cell" % c
        ox, oy = ((code - first) % cols) * cw, ((code - first) // cols) * ch
        for y, row in enumerate(rows):
            for x, bit in enumerate(row):
                if bit == "#":
                    sheet.set(ox + x, oy + yoff + y, WHITE)
        if width + 1 != cw:                             # only variable-width glyphs are listed
            advance[c] = width + 1
    save(sheet, UI_DIR, "font_%s.png" % name, 1, "Bitmap font, white glyphs, 16 columns from ASCII 32.")
    with open(os.path.join(UI_DIR, "font_%s.json" % name), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"cell": [cw, ch], "columns": cols, "first_char": first, "advance": advance}, f, indent=1)
    return glyphs


def text_canvas(glyphs, text, color, cell_h=8, advance_default=6):
    """Render text with parsed glyphs into a tight canvas (used for the logo and the preview)."""
    widths = []
    for c in text:
        if c == " ":
            widths.append(4)
        else:
            widths.append(max(len(r) for r in glyphs[c][1]) + 1 if c in glyphs else advance_default)
    out = Canvas(max(1, sum(widths)), cell_h)
    x = 0
    for c, w in zip(text, widths):
        if c in glyphs:
            yoff, rows = glyphs[c]
            for y, row in enumerate(rows):
                for xx, bit in enumerate(row):
                    if bit == "#":
                        out.set(x + xx, yoff + y, color)
        x += w
    return out


# --------------------------------------------------------------------------- HUD

def magic_frame():
    """Vertical magic meter: a rounded rim around a dark well MAGIC_UNITS px tall (fill drawn by the engine at (3,3))."""
    w, h = 10, MAGIC_UNITS + 6
    c = Canvas(w, h)
    c.rect(1, 0, w - 2, h, UI_RIM_LIGHT)
    c.rect(0, 1, w, h - 2, UI_RIM_LIGHT)
    c.rect(1, 1, w - 2, h - 2, UI_RIM_MID)
    c.rect(2, 2, w - 4, h - 4, UI_RIM_DARK)
    c.rect(3, 3, w - 6, MAGIC_UNITS, UI_WELL)
    c.outline(OUTLINE)
    return c


def magic_fill():
    """The meter's fill column (4 x MAGIC_UNITS): the engine shows its bottom part in proportion to magic."""
    c = Canvas(4, MAGIC_UNITS)
    c.rect(0, 0, 4, MAGIC_UNITS, MAGIC_MID)
    c.rect(0, 0, 1, MAGIC_UNITS, MAGIC_LIGHT)
    c.rect(3, 0, 1, MAGIC_UNITS, MAGIC_DARK)
    return c


def item_box():
    """ALttP's equipped-item box: 22x22 pale rounded frame around a dark window (item icon centred inside)."""
    c = Canvas(22, 22)
    c.rect(2, 0, 18, 22, UI_RIM_LIGHT)
    c.rect(0, 2, 22, 18, UI_RIM_LIGHT)
    c.rect(1, 1, 20, 20, UI_RIM_LIGHT)
    c.rect(2, 2, 18, 18, UI_RIM_MID)
    c.rect(3, 3, 16, 16, UI_BOX_FILL)
    c.rect(3, 3, 16, 1, UI_BOX_EDGE)
    c.rect(3, 3, 1, 16, UI_BOX_EDGE)
    return c


def key_icon():
    """Small dungeon key (7x9): round bow on top, shaft and two teeth."""
    c = Canvas(7, 10)
    c.ellipse(3, 2.5, 2.6, 2.4, KEY_MID)
    c.set(3, 2, CLEAR)
    c.set(3, 3, CLEAR)
    c.set(2, 1, KEY_LIGHT)
    c.rect(3, 5, 1, 4, KEY_MID)
    c.rect(4, 7, 2, 1, KEY_DARK)
    c.rect(4, 9, 1, 1, KEY_DARK)
    c.outline(OUTLINE)
    return c


# --------------------------------------------------------------------------- boxes

def box(fill, edge, size=24, border=BOX_BORDER):
    """Nine-slice box: pale double rim with dark lines, rounded corners, a one-pixel bevel inside the fill."""
    c = Canvas(size, size)
    c.rect(1, 1, size - 2, size - 2, fill)
    for i, col in ((1, UI_RIM_LIGHT), (2, UI_RIM_MID), (3, UI_RIM_LIGHT)):
        c.rect(i, i, size - 2 * i, 1, col)
        c.rect(i, size - 1 - i, size - 2 * i, 1, col)
        c.rect(i, i, 1, size - 2 * i, col)
        c.rect(size - 1 - i, i, 1, size - 2 * i, col)
    c.rect(4, 4, size - 8, 1, edge)
    c.rect(4, 4, 1, size - 8, edge)
    c.rect(0, 2, 1, size - 4, OUTLINE)
    c.rect(size - 1, 2, 1, size - 4, OUTLINE)
    c.rect(2, 0, size - 4, 1, OUTLINE)
    c.rect(2, size - 1, size - 4, 1, OUTLINE)
    for x, y in ((1, 1), (size - 2, 1), (1, size - 2), (size - 2, size - 2)):
        c.set(x, y, OUTLINE)                            # rounded corners
    assert border * 2 < size
    return c


def caption_plate():
    """Small nine-slice plate for area names: dark fill, gold rim."""
    s = 16
    c = Canvas(s, s)
    c.rect(1, 1, s - 2, s - 2, UI_BOX_FILL)
    for i, col in ((1, UI_GOLD), (2, UI_GOLD_DARK)):
        c.rect(i, i, s - 2 * i, 1, col)
        c.rect(i, s - 1 - i, s - 2 * i, 1, col)
        c.rect(i, i, 1, s - 2 * i, col)
        c.rect(s - 1 - i, i, 1, s - 2 * i, col)
    c.rect(0, 2, 1, s - 4, OUTLINE)
    c.rect(s - 1, 2, 1, s - 4, OUTLINE)
    c.rect(2, 0, s - 4, 1, OUTLINE)
    c.rect(2, s - 1, s - 4, 1, OUTLINE)
    return c


def cursor_strip():
    """Menu cursor: a gold arrow pointing right that bobs 1 px (4 frames, 8x8)."""
    frames = []
    for dx in (0, 1, 1, 0):
        c = Canvas(8, 8)
        c.poly([(1 + dx, 1), (5 + dx, 4), (1 + dx, 7)], UI_GOLD)
        c.set(2 + dx, 3, WHITE)
        c.rect(1 + dx, 6, 2, 1, UI_GOLD_DARK)
        frames.append(c)
    return pack_strip(frames)


def more_arrow():
    """Dialogue 'more' indicator: a down-pointing gold triangle, 2 frames (bob)."""
    frames = []
    for dy in (0, 1):
        c = Canvas(7, 6)
        c.poly([(0, dy), (6, dy), (3, 3 + dy)], UI_GOLD)
        c.set(3, 1 + dy, WHITE)
        frames.append(c)
    return pack_strip(frames)


def slot():
    """Item-menu slot (20x20): a sunken square."""
    c = Canvas(20, 20)
    c.rect(0, 0, 20, 20, UI_RIM_DARK)
    c.rect(1, 1, 18, 18, UI_BOX_EDGE)
    c.rect(2, 2, 16, 16, UI_BOX_FILL)
    c.rect(2, 17, 16, 1, UI_RIM_DARK)
    c.rect(17, 2, 1, 16, UI_RIM_DARK)
    return c


def seal(full):
    """Family seal (14x14): a gold ring holding a violet stone; an empty socket while not yet found."""
    c = Canvas(14, 14)
    c.ellipse(6.5, 6.5, 6, 6, GOLD if full else UI_RIM_DARK)
    c.ellipse(6.5, 6.5, 4, 4, SEAL_MID if full else UI_WELL)
    if full:
        c.ellipse(6.5, 7.5, 3, 2.5, SEAL_DARK)
        c.ellipse(5.5, 5, 1.6, 1.2, SEAL_LIGHT)
        c.set(9, 2, GOLD_DARK)
        c.set(10, 3, GOLD_DARK)
    c.outline(OUTLINE)
    return c


def sword_icon():
    """Equipment icon: Joe's sword, point up (16x16)."""
    c = Canvas(16, 16)
    c.rect(7, 1, 2, 9, STEEL_MID)
    c.rect(7, 1, 1, 9, STEEL_LIGHT)
    c.rect(8, 2, 1, 8, STEEL_DARK)
    c.rect(4, 10, 8, 2, GOLD)
    c.rect(4, 11, 8, 1, GOLD_DARK)
    c.rect(7, 12, 2, 3, HILT_DARK)
    c.outline(OUTLINE)
    return c


def shield_icon():
    """Equipment icon: the family shield (16x16)."""
    c = Canvas(16, 16)
    c.poly([(2, 1), (13, 1), (13, 8), (7.5, 14), (2, 8)], SHIELD_RIM)
    c.poly([(4, 3), (11, 3), (11, 8), (7.5, 12), (4, 8)], SHIELD_FACE)
    c.rect(4, 9, 7, 1, SHIELD_DARK)
    c.rect(6, 5, 3, 4, GOLD)
    c.set(7, 8, GOLD_DARK)
    c.outline(OUTLINE)
    return c


# --------------------------------------------------------------------------- title logo

def logo(g5):
    """'THE VILLAGE' from the 5x7 glyphs at 3x, filled with a gold gradient, a dark extrusion and an outline."""
    base = text_canvas(g5, LOGO_TEXT, WHITE)
    big = upscale(base.img, LOGO_SCALE)
    w, h = big.width + 6, big.height + 6
    out = Canvas(w, h)
    src = big.load()
    # Extrusion: the letter shape shifted down-right twice in the shade colour.
    for off in (2, 1):
        for y in range(big.height):
            for x in range(big.width):
                if src[x, y][3]:
                    out.set(x + 2 + off, y + 2 + off, LOGO_SHADE)
    # Face: gradient by row band (top light -> bottom deep).
    for y in range(big.height):
        t = y / max(1, big.height - 1)
        col = LOGO_TOP if t < 0.3 else (LOGO_MID if t < 0.7 else LOGO_LOW)
        for x in range(big.width):
            if src[x, y][3]:
                out.set(x + 2, y + 2, col)
    out.outline(INK)
    return out


# --------------------------------------------------------------------------- preview

def preview(images, g5):
    """Contact sheet of every UI piece at 3x on a mid-grey ground."""
    pad = 6
    w = sum(im.width for im in images) + pad * (len(images) + 1)
    h = max(im.height for im in images) + pad * 2
    sheet = Image.new("RGBA", (w, h), (96, 104, 120, 255))
    x = pad
    for im in images:
        sheet.alpha_composite(im, (x, pad))
        x += im.width + pad
    sample = text_canvas(g5, "Welcome home, Joe. Press E to talk.", WHITE)
    full = Image.new("RGBA", (max(w, sample.w + 2 * pad), h + sample.h + pad), (96, 104, 120, 255))
    full.alpha_composite(sheet, (0, 0))
    full.alpha_composite(sample.img, (pad, h))
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    upscale(full, 3).save(PREVIEW)


def main():
    g5 = build_font(parse_glyphs(G5_TEXT), (6, 8), "5x7", 4, False)
    build_font(parse_glyphs(G3_TEXT), (4, 6), "3x5", 3, True)
    images = [
        save(magic_frame(), HUD_DIR, "magic_frame.png", 1, "Magic meter rim; fill at (3,3), %d px tall." % MAGIC_UNITS),
        save(magic_fill(), HUD_DIR, "magic_fill.png", 1, "Meter fill; show the bottom part in proportion."),
        save(item_box(), HUD_DIR, "item_box.png", 1, "Equipped item box; icon centred."),
        save(key_icon(), HUD_DIR, "key.png", 1, "Small key counter icon."),
        save(box(UI_BOX_FILL, UI_BOX_EDGE), MENU_DIR, "box.png", 1, "Nine-slice, border %d." % BOX_BORDER),
        save(caption_plate(), MENU_DIR, "caption.png", 1, "Nine-slice, border %d." % CAPTION_BORDER),
        save(cursor_strip(), MENU_DIR, "cursor.png", 4, "Menu cursor, 8 fps loop."),
        save(more_arrow(), MENU_DIR, "more.png", 2, "Dialogue continue arrow, 4 fps loop."),
        save(slot(), MENU_DIR, "slot.png", 1, "Item-menu slot."),
        save(seal(False), MENU_DIR, "seal_empty.png", 1, "Family seal socket."),
        save(seal(True), MENU_DIR, "seal_full.png", 1, "Family seal found."),
        save(sword_icon(), MENU_DIR, "icon_sword.png", 1, "Equipment icon."),
        save(shield_icon(), MENU_DIR, "icon_shield.png", 1, "Equipment icon."),
        save(logo(g5), UI_DIR, "title_logo.png", 1, "Title logo."),
    ]
    with open(os.path.join(UI_DIR, "ui_manifest.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(MANIFEST, f, indent=1)
    preview(images, g5)
    print("%d UI images + 2 fonts written; preview %s" % (len(images), os.path.relpath(PREVIEW, ROOT)))


if __name__ == "__main__":
    main()
