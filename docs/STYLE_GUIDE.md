<!--
File: STYLE_GUIDE.md
Description: Code, art and doc style.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Style guide

## Code
- GDScript, typed where the type is known; tabs; `snake_case` functions, `PascalCase` classes, `UPPER_CASE` constants.
- No magic numbers in logic: feel numbers in `PlayerTuning`, colours in `tools/palette.py`, layer bit values as named constants.
- Comment every function and non-obvious line; English only.
- Every file opens with the branding header.

## Art
- 16 px tiles, 48x48 actor frames with the feet at (24,34), 1-px `OUTLINE` on actors, no anti-aliasing.
- Light World: bright, saturated. Dark World: the `DW_*` palette.

## Docs
- Markdown with the branding header; keep counts (checks, rooms) current.
