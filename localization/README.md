<!--
File: README.md
Description: How The Village's translations work (the UI table, the dialogue table, the fonts) and how to check or add a language.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-21
Last edit date: 2026-10-21
Version: 1.0.0
-->

# Localization

The game is written in English; Spanish is the first translation (Phase 14). Two tables per language:

| File | What it translates | Read by |
|---|---|---|
| `es.json` | UI text as it is drawn: menus, HUD, item names, area and dungeon names, hints. A flat object, English -> Spanish. | `src/core/Loc.gd` (through `PixelText`) |
| `dialogue_es.json` | Every entry of `assets/data/dialogue.json`: the same keys, text only (`name`, `once`, `pages`, `gift_pages`). | `src/core/DialogueData.gd` |

- **Patterns.** A UI key with printf placeholders (`KEYS %d`, `PRESS %s`) is a pattern: the translation must keep the
  same placeholders in the same order. Text captured by `%s` is translated too (`PRESS CIRCLE` -> `PULSA CÍRCULO`).
- **Composed labels.** Translate the parts, not the whole: the item menu translates an item's name, then adds its
  count (`BOMBAS x8`).
- **Dialogue logic stays English.** Flags, gifts and items always come from `dialogue.json`; a translation can only
  change words. A missing key stays English. Page counts must match the English entry.
- **Letters.** The bitmap fonts carry ASCII plus Á É Í Ó Ú Ñ Ü (both cases), ¡ and ¿ (`tools/gen_ui.py`). Accented
  capitals sit one pixel lower than the others (the mark needs a free row). The small 3x5 font has capitals only.
- **Fit.** UI text must fit its box: the pause panel is 150 px wide, the item menu's section titles share a row,
  and the world map wraps an area name onto two lines inside its box.
- **Language at run time.** The options screen switches the language and every open screen follows at once
  (`Loc.refresh`); the choice is saved in the settings file.

## Checks

```
python -I tools/extract_strings.py
```

It must end `0 missing, 0 other problems`: every all-caps literal in the code and every area or dungeon name has a
Spanish entry, the Spanish dialogue covers every key with the right page counts, and every character of both tables
exists in the fonts. `tests/test_polish.gd` checks the tables in the game.

## Adding a language

Create `<code>.json` and `dialogue_<code>.json`, add the code to `Loc.LANGUAGES` and its name to `Loc.LABELS`, add
any missing letters to the fonts, and teach `extract_strings.py` the new table paths.

**Status:** the Spanish text is a draft (neutral Latin American Spanish), like the English story. Place names are
placeholders.
