<!--
File: LEVEL_DESIGN.md
Description: How areas are built, linted and previewed; the glyph table.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Level design

Areas are code: `tools/gen_areas.py` builds every area as ASCII rows, lints the world and writes
`src/world/areas/*.json`. Never edit the JSON by hand.

```
python -I tools/gen_areas.py        # must print "0 lint problems"
```
It also renders `tmp/world_preview.png` (the whole overworld from the real atlas, actors as coloured squares) and
`tmp/interiors_preview.png`.

## World grid
- A screen is 24x14 tiles (384x224 px; the 216-px view scrolls 8 px inside one screen).
- Each overworld area covers a rectangle of screens at an `origin` (in screens) - El Pueblo is 2x2 at (0,1).
- Edge openings must continue into a walkable cell of the neighbouring area (the lint checks both sides).
  Openings in use: columns 22-25 on north/south edges of 2-screen-wide areas, rows 12-15 on east/west edges of
  2-screen-tall areas.
- Interiors are 16x11 rooms placed far from the grid; `gen_areas.py` pairs each house door with its interior's
  exit mat automatically.

## Glyphs
| Glyph | Meaning | Glyph | Meaning |
|---|---|---|---|
| `.` `,` `*` | grass, tufts, flowers | `#` | dirt path (autotiled) |
| `~` | water (autotiled, solid) | `v` | ledge: hop down southward, solid otherwise |
| `^` | cliff (solid) | `f` | fence |
| `S` | sign | `R` | rock (solid) |
| `T` | 2x2 tree (anchor; `x` fillers) | `H` / `J` | 5x4 cottage, red / blue roof; door at (2,3) |
| `_` | floor | `W` / `w` | interior wall (face or top chosen automatically) / wall with a shelf |
| `M` | exit mat | `K` / `D` | 2x1 table / 1x2 bed |
| `B` `O` | bush, pot | `Z` `G` `Q` | slime, guard, rock-spitter |
| `P` | Joe's spawn (exactly one in the world) | `x` | filler of a multi-cell piece |

## Lint
Sizes, unknown glyphs, multi-cell pieces (fit, fillers covered exactly once), ledge landings, edge openings,
overlaps between areas, door/exit pairing and spawn cells, reachability from every entrance (ledges are one-way),
exactly one spawn. Adding an area: write a `build_<id>(rng)` function, add it to `OVERWORLD` (or `INTERIORS`), run
the script, look at the preview, then run `tests/test_world.gd` (update its area/door counts).
