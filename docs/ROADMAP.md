<!--
File: ROADMAP.md
Description: Phased production roadmap for The Village, from the rebuild scaffolding to the v1.0 release.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-19
Version: 1.6.0
-->

# Roadmap

Each phase ends with something playable and verified by actually running it: headless scripted suites for
behaviour (`docs/TESTING.md`) and windowed screenshot captures for visuals. Same method as Chapel of Dreams.

| # | Phase | Deliverable | Status |
|---|---|---|---|
| 0 | Rebuild scaffolding | Godot 4.7.2 project at 384×216, full folder/doc structure, master palette, sprite toolkit, prototype code retired (kept in git history) | Done |
| 1 | Movement & sword | Generated Joe (idle/walk/slash/hurt in 4 facings), 8-way walking, ALttP facing rule, corner nudge, sword slash with hit window + chained slashes, hurt knockback + i-frames, generated Light World tiles, cuttable bushes, 2×2-screen test meadow | Done (36 checks pass) |
| 2 | Combat core & game feel | Spin attack (hold to charge), shield blocking, first enemies (Caver's guard, rock-spitter, slime), enemy knockback + hit flash + death puff, heart/gem drops, lift-and-throw pots and bushes, hit-stop and screen shake, `Audio` autoload with 15 generated SFX, minimal HUD (hearts + gems), respawn on death | Done (56 combat checks pass) |
| 3 | Overworld engine | Areas from `tools/gen_areas.py` + lint, autotiled paths/water/ledges/cliffs/walls, ALttP screen-edge scrolling, house doors and exit mats, ledge hops, El Pueblo + four neighbouring areas + four house interiors, `World` as the main scene | Done (30 world checks pass) |
| 4 | HUD, menus, saves, dialogue | Full HUD (item box, magic meter, keys), area-name captions, item menu, title + pause menus, save/load, NPCs with dialogue boxes (Tato, Boni, Janga), readable signs, Game Over screen | Done (61 UI checks pass) |
| 5 | Items I | Chests, small keys, boomerang, bow, bombs, lantern, heart pieces/containers, Boni's shop stock | Done (67 item checks pass) |
| 6 | Dungeon framework + Dungeon 1 | Dungeon rooms, locked/shutter doors, switches, push blocks, pits, dungeon map/compass/big key, first boss, first family seal (+ the power glove) | Done (62 dungeon checks pass) |
| 7 | Light World dungeons 2–3 | Two more dungeons, dash boots, the road south opened, Caver's keep, Act 1 ending (+ fire rod, magic jars) | Done (54 Act 1 checks pass) |
| 8 | Dark World + Moon Mirror | Dark World palette pass and transformation, the mirror warp between worlds, Dark World hub (Act 2 starts where Act 1's save left Joe) | Next |
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

## Phase 2 detail
- [x] Spin attack: hold the sword button after a slash; Joe shuffles at half speed with his facing locked; after 0.8 s the blade glints (`charge_ready` sound); releasing spins once around (8 frames, 4 damage, 24 px circle)
- [x] Shield on every Joe frame; blocks `blockable` hits (enemy rocks) arriving within ~53 degrees of his facing while idle/walking/charging; blocked rocks bounce off
- [x] `BaseEnemy`: sprite packs, feet collision, contact damage, knockback + stun, white hit flash, 0.3 s i-frames, hit-stop for both sides, death puff + small shake, drop roll
- [x] Slime (hops, 1 hit), Caver's guard (patrols, chases along the dominant axis, 3 hits), rock-spitter (wanders, spits blockable rocks, 1 hit)
- [x] `GameState` (gems, drop table), `Pickup` (heart heals one heart; green/blue/red gems worth 1/5/20; pop, blink, vanish after 10 s)
- [x] Lift/carry/throw (interact): pots and bushes; throws travel 4 tiles in an arc, hurt enemies, break on walls; pots can drop items; a hit makes Joe drop what he carries
- [x] `Juice` (shake, hit-stop, one-shot effects) and `Audio` (pooled SFX) autoloads; `tools/gen_sfx.py` (15 effects), `gen_enemies.py`, `gen_props.py`
- [x] Minimal HUD (hearts with halves, 3-digit gem counter); Joe respawns at the field spawn 1.5 s after dying
- [x] `tests/test_combat.gd`: 56 checks
- [ ] Owner playtest: enemy aggression, spin charge time, throw distance, sound mix (nothing auditioned by ear yet)

## Phase 3 detail
- [x] `tools/terrain_art.py` + `gen_tiles.py` v2: 83-cell atlas - water and path nine-slices, south ledges (4 pieces), cliffs, fence, sign, red and blue 5x4 cottages (walkable door cell), interior floor/walls/shelf/exit mat/table/bed; manifest flags `ledge`, `door`, `exit`
- [x] `AreaBuilder`: one painter for test arenas and real areas (glyph table in its header); TileSet custom-data flags; seamless terrain across area edges
- [x] `tools/gen_areas.py`: 5 overworld areas (El Pueblo 2x2 screens, North Meadow, West Woods, East Lake, South Road) and 4 interiors (Joe, Tato, Boni's shop, Janga); lint = sizes, glyphs, multi-cell coverage, ledge landings, edge openings that continue into a neighbour, door/exit pairing, reachability (one-way ledges understood), exactly one spawn; world/interior preview PNGs
- [x] `World`: global tile coordinates, clamped camera (small rooms centred), 0.6 s screen scroll with Joe stepping in, door/mat fades, enemies respawn on re-entry, death respawn at the area entry, HUD
- [x] Joe hops down south ledges (0.35 s arc, `ledge_hop`/`land` sounds); `door` sound
- [x] `tests/test_world.gd`: 30 checks; `tools/capture_world.gd`
- [ ] Owner playtest: scroll speed, village layout, how the double tree belts between areas read

## Phase 4 detail
- [x] `tools/gen_ui.py`: 5x7 and 3x5 bitmap fonts (glyphs shared with Chapel of Dreams), magic meter, item box, key icon, nine-slice dialogue/menu box and caption plate, cursor, "more" arrow, item slot, seals, sword/shield icons, title logo
- [x] `tools/gen_npcs.py`: Tato, Boni, Janga, Marta, Pico - 32x32 idle strips facing down/up/side
- [x] HUD: magic meter, item box, gems, keys (hidden at zero), "- LIFE -" hearts (10 per row); area-name captions
- [x] Dialogue box: wrapped pages, typewriter + blip, name plate, more arrow, top/bottom placement, pauses the world; `assets/data/dialogue.json` with first-meeting lines and story flags
- [x] Villagers turn to face Joe; Boni is talked to across her counter; signs in every overworld area are readable; talking wins over lifting
- [x] Title screen (village backdrop pan; CONTINUE only with a save), pause menu (continue / save / save and quit), item menu (grid, equip, equipment, seals), Game Over (continue / save and continue / save and quit)
- [x] `SaveGame`: one JSON save at `user://village_save.json`; Joe restarts where he entered the saved area
- [x] `gen_areas.py` lint for villagers and signs; 7 new sounds (25 total)
- [x] `tests/test_ui.gd`: 61 checks; `tools/capture_ui.gd`
- [ ] Owner review: dialogue lines (the story is still a draft), the title subtitle, text speed, menu layout

## Phase 5 detail
- [x] `tools/gen_items.py`: item icons, chest, boomerang, arrow, bomb, torches, cracked rock, key block, heart piece/container, small key, explosion and flame effects
- [x] `ItemDB` + `ItemUse`: lantern (lights torches, 2 magic), boomerang (stun, fetch, one at a time), bow (4-damage arrows), bombs (fuse, blast for enemies and Joe, cracked rocks, two at a time)
- [x] Item-get sequence (Joe holds it up, fanfare, text); chests open from below; hidden chests appear when every torch of the area burns
- [x] Small keys and key blocks; heart pieces (4 = a container) and heart containers; HUD bomb/arrow counters; item menu counts and heart quarters
- [x] Boni's shop: wares on the counter with prices, BUY / NO choice, not-enough-gems and full-bag answers, one-time piece of heart
- [x] World content: lantern (Joe's house), boomerang (Janga's gift), key (East Lake) -> key block -> bow (South Road), torch chest (North Meadow), cracked rock (West Woods), loose piece (East Lake)
- [x] `gen_areas.py` objects/wares + lint; 12 new sounds (37 total); `tests/test_items.gd`: 67 checks; `tools/capture_items.gd`
- [ ] Owner playtest: prices, fuse length, boomerang range, item placement

## Phase 6 detail
- [x] Dungeon tiles (`tools/dungeon_art.py`): stone floor, walls, pillar, exit stairs, pit nine-slice, the Moss Shrine facade; `tools/gen_dungeon.py`: doors, switch, push block, big chest, heavy rock, seal, dungeon item icons, the Grand Slime
- [x] Area groups: dungeon rooms scroll into each other; 40 px push past the thick walls; key pools per dungeon
- [x] Doors: locked / big / shutter (room cleared, switch) / boss; mirrored in both rooms; state from flags
- [x] Floor switches (heavy = block only), push block, pits (fall = one heart, back to the entry), hidden chests revealed by switches
- [x] Map, compass, big key, big chest; `MapScreen` for dungeons and the overworld
- [x] The Grand Slime, heart container, first family seal, the way out; the Power Glove and heavy rocks
- [x] `gen_areas.py` v3 dungeon rooms + lint; 5 new sounds (42); `tests/test_dungeon.gd`: 62 checks; `tools/capture_dungeon.gd`
- [ ] Owner playtest: dungeon layout and difficulty, boss tuning, the dungeon's name (Moss Shrine is a placeholder)

## Phase 7 detail
- [x] Road south (heavy rocks + the glove) into the South Fields; the keep wall and seal gate; two shrine entrances, rubble
- [x] Ram's Hollow (6 rooms, Dash Boots, Iron Ram, seal 2) and the Frost Vault (6 rooms, Fire Rod, Frost Wraith, seal 3) via `make_room` / `DUNGEONS`
- [x] Dash Boots (charge, dash, bonk, rubble, dash damage); Fire Rod (fireballs, torches, magic); magic jars
- [x] Bats; `BaseEnemy._resists`; `EnemyShot`; Caver's shade and the bat-back orb
- [x] Caver's Keep (3 rooms), the end of Act 1 (`EndCard`, save outside the keep, back to the title)
- [x] `tools/gen_act1.py`; 8 new sounds (50); `tests/test_act1.gd`: 54 checks; `tools/capture_act1.gd`
- [ ] Owner playtest: dungeon 2-3 layouts, boss difficulty, the end card's words, dungeon/boss names (placeholders)
