# File: extract_strings.py
# Description: Lists every in-game UI text candidate (all-caps GDScript string literals, area and dungeon names) and reports which ones localization/es.json lacks; also checks that the Spanish dialogue covers every dialogue key and that every character of both Spanish tables exists in the bitmap fonts.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
#
# Run:  python -I tools/extract_strings.py            (prints problems; must end "0 missing"; exit code 1 otherwise)
#       python -I tools/extract_strings.py --all      (prints every candidate)
# Adapted from Chapel of Dreams' tool of the same name (same table format, so the trilogy shares one method).
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TABLE = os.path.join(ROOT, "localization", "es.json")
DIALOGUE = os.path.join(ROOT, "assets", "data", "dialogue.json")
DIALOGUE_ES = os.path.join(ROOT, "localization", "dialogue_es.json")
AREAS = os.path.join(ROOT, "src", "world", "areas")
FONT_JSON = os.path.join(ROOT, "assets", "ui", "font_%s.json")
FONT_PNG = os.path.join(ROOT, "assets", "ui", "font_%s.png")
LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
MIN_LEN = 2
IGNORE_PREFIXES = ("res://", "user://")
# Shown to the player but the same in every language (language names, key and button names).
UNIVERSAL = {"ENGLISH", "ESPAÑOL", "ENTER", "ESC", "TAB", "START", "SELECT", "OK"}
# Literals that are all caps but never shown (identifiers the heuristics cannot tell apart from text).
NOT_TEXT = {"UP", "DOWN", "LEFT", "RIGHT", "SFX"}
FORMAT = re.compile(r"%[-+0-9.]*[sdf]")        # printf placeholders (not text)
DIGITS = re.compile(r"\d+")


def normalise(s):
    """Digit runs become %d, so 'KEYS 2' and 'KEYS 3' share one pattern key (format strings are kept as they are)."""
    return DIGITS.sub("%d", s) if not FORMAT.search(s) else s


def is_text(s):
    """True for an all-caps literal with two capitals in a row that is not an identifier or a path."""
    bare = FORMAT.sub("", s)
    if len(bare) < MIN_LEN or s.startswith(IGNORE_PREFIXES) or "/" in s or s in NOT_TEXT:
        return False
    if re.search(r"[a-z]", bare):
        return False
    if not re.search(r"[A-Z]{2}", bare):
        return False
    if re.fullmatch(r"[A-Z0-9_]+", bare) and "_" in bare:
        return False
    return True


def candidates():
    found = {}
    for path in glob.glob(os.path.join(ROOT, "src", "**", "*.gd"), recursive=True):
        with open(path, encoding="utf-8") as f:
            for line in f:
                if line.lstrip().startswith("#"):
                    continue
                code = line.split(" #", 1)[0]
                for m in LITERAL.finditer(code):
                    if is_text(m.group(1)):
                        found.setdefault(normalise(m.group(1)), set()).add(os.path.basename(path))
    for path in glob.glob(os.path.join(AREAS, "*.json")):
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
        if "name" in d:
            found.setdefault(d["name"].upper(), set()).add("areas")     # captions and map labels are upper case
    with open(os.path.join(AREAS, "index.json"), encoding="utf-8") as f:
        for info in json.load(f).get("dungeons", {}).values():
            found.setdefault(info["name"].upper(), set()).add("dungeons")
    return found


def font_chars(name):
    """Characters that have ink in the font atlas (plus the space)."""
    from PIL import Image
    meta = json.load(open(FONT_JSON % name, encoding="utf-8"))
    img = Image.open(FONT_PNG % name).convert("RGBA")
    cw, ch = meta["cell"]
    cols, first = meta["columns"], meta["first_char"]
    have = {" "}
    for idx in range((img.height // ch) * cols):
        box = ((idx % cols) * cw, (idx // cols) * ch, (idx % cols) * cw + cw, (idx // cols) * ch + ch)
        if img.crop(box).getbbox() is not None:
            have.add(chr(first + idx))
    return have


def dialogue_problems():
    en = {k: v for k, v in json.load(open(DIALOGUE, encoding="utf-8")).items() if not k.startswith("_")}
    es = {k: v for k, v in json.load(open(DIALOGUE_ES, encoding="utf-8")).items() if not k.startswith("_")}
    out = ["dialogue: %s has no Spanish text" % k for k in sorted(set(en) - set(es))]
    out += ["dialogue: %s is not an English key" % k for k in sorted(set(es) - set(en))]
    for k in sorted(set(en) & set(es)):
        for field in ("once", "pages"):
            if field in en[k] and len(en[k][field]) != len(es[k].get(field, [])):
                out.append("dialogue: %s.%s has %d pages in English" % (k, field, len(en[k][field])))
        if "gift" in en[k] and len(en[k]["gift"]["pages"]) != len(es[k].get("gift_pages", [])):
            out.append("dialogue: %s gift_pages differ from the English gift" % k)
    return out, es


def glyph_problems(table, dialogue_es):
    large, small = font_chars("5x7"), font_chars("3x5")
    out = []
    texts = [v for k, v in table.items() if not k.startswith("_")]
    for entry in dialogue_es.values():
        for field in ("name", "once", "pages", "gift_pages"):
            v = entry.get(field)
            texts += [v] if isinstance(v, str) else (v or [])
    for t in texts:
        for c in set(t.replace("\n", "")):
            if c not in large:
                out.append("font: %r (in %r) is not in the 5x7 font" % (c, t[:40]))
            elif c.upper() not in small and c not in small:
                out.append("font: %r (in %r) is not in the 3x5 font" % (c, t[:40]))
    return sorted(set(out))


def main():
    found = candidates()
    table = json.load(open(TABLE, encoding="utf-8")) if os.path.exists(TABLE) else {}
    if "--all" in sys.argv:
        for s in sorted(found):
            print(repr(s), sorted(found[s])[:2])
        print(len(found), "candidates")
        return 0
    missing = [s for s in sorted(found) if s not in table and s not in UNIVERSAL]
    for s in missing:
        print("MISSING", repr(s), sorted(found[s])[:2])
    unused = [k for k in sorted(table) if not k.startswith("_") and k not in found]
    for k in unused:
        print("note: %r is translated but not found in the code (composed at run time?)" % k)
    probs, dialogue_es = dialogue_problems()
    probs += glyph_problems(table, dialogue_es)
    for p in probs:
        print(p)
    print("%d candidates, %d translations, %d missing, %d other problems" % (len(found), len(table), len(missing),
                                                                             len(probs)))
    return 1 if missing or probs else 0


if __name__ == "__main__":
    sys.exit(main())
