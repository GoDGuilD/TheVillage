<!--
File: ROADMAP.md
Description: Phased production roadmap for The Village, from the rebuild scaffolding to the v1.0 release.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Roadmap

Each phase ends with something playable and verified by actually running it: headless scripted suites for
behaviour (`docs/TESTING.md`) and windowed screenshot captures for visuals. Same method as Chapel of Dreams.

| # | Phase | Deliverable | Status |
|---|---|---|---|
| 0 | Rebuild scaffolding | Godot 4.7.2 project at 384×216, full folder/doc structure, master palette, sprite toolkit, prototype code retired (kept in git history) | Done |
| 1 | Movement & sword | Generated Joe (idle/walk/slash/hurt in 4 facings), 8-way walking, ALttP facing rule, corner nudge, sword slash with hit window + chained slashes, hurt knockback + i-frames, generated Light World tiles, cuttable bushes, 2×2-screen test meadow | Done (36 checks pass) |
| 2 | Combat core & game feel | Spin attack (hold to charge), shield blocking, first enemies (soldier, octorok-style spitter, slime), enemy knockback + hit flash + death puff, hearts/money drops, lift-and-throw pots and bushes, hit-stop and screen shake, `Audio` autoload with first SFX | Next |
| 3 | Overworld engine | Data-driven areas from a generator + lint (like Chapel's `gen_rooms.py`), autotiled terrain (paths, cliffs, water edges), ALttP screen-edge scrolling between areas, doors into interiors, El Pueblo first draft | Planned |
| 4 | HUD, menus, saves, dialogue | Hearts/money/item HUD, item menu, title + pause menus, save/load, NPC dialogue boxes (Tato, Boni, Janga), signs | Planned |
| 5 | Items I | Chests, small keys, boomerang, bow, bombs, lantern, heart pieces/containers | Planned |
| 6 | Dungeon framework + Dungeon 1 | Dungeon rooms, locked/shutter doors, switches, push blocks, pits, dungeon map/compass/big key, first boss, first family seal | Planned |
| 7 | Light World dungeons 2–3 | Two more dungeons, dash boots, power glove, Caver's keep, Act 1 ending | Planned |
| 8 | Dark World + Moon Mirror | Dark World palette pass and transformation, the mirror warp between worlds, Dark World hub | Planned |
| 9–12 | Umbra, Ignis, Tempus, Silva | One region + dungeon + boss each, with their key items (grapple, fire rod, etc.) | Planned |
| 13 | Caver's tower | Final dungeon, Caver fight, ending that leads into Chapel of Dreams | Planned |
| 14 | Polish, audio, localization | Music per area, SFX balance, Spanish, options, gamepad polish | Planned |
| 15 | Release | Credits, icon, export preset, performance baseline, store material | Planned |

## Phase 1 detail
- [x] `tools/gen_joe.py`: 12 strips (idle, walk, attack, hurt × down/up/side) on 48×48 frames + manifest with the slash hit window
- [x] `tools/gen_tiles.py`: grass, tufted grass, flowers, rock, 2×2 tree, 9-slice dirt path, bush, leaf burst
- [x] `Player`: instant 8-way walking, ALttP facing rule, corner nudge, slash (box live only on hit-window frames), buffered chained slashes, hurt knockback + blinking i-frames
- [x] `Bush`: solid until cut, leaf burst
- [x] `TestField`: ASCII-layout meadow (2×2 screens) with a runtime-built TileSet, camera limits
- [x] `tests/test_player.gd`: 36 checks
- [ ] Playtest feedback from the owner (walk speed, slash timing, nudge strength)
