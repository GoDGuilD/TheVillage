<!--
File: DATA_MODEL.md
Description: Data files and their shapes.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-23
Version: 1.10.0
-->

# Data model

## Joe animation manifest (`assets/sprites/joe/joe_animations.json`)
`{frame_size: [48,48], feet: [24,34], anims: {<anim>_<facing>: {frames, fps, loop, hit_window?}, spin: {...}}}` - facings `down`, `up`, `side` (left = mirrored side). Strips are `joe_<anim>_<facing>.png`.

## Tile manifest (`assets/tiles/overworld_light.json`)
`{tile_size: 16, cells: {name: {cell: [col,row], solid: bool, ledge?, door?, exit?}}}` - names include `path_<dx>_<dy>` / `water_<dx>_<dy>` (nine-slices), `ledge_l|m|r|s`, `cliff`, `cliff_top`, `tree_<x>_<y>`, `house_<red|blue>_<x>_<y>` (5x4, door at 2,3), `floor`, `wall_face`, `wall_shelf`, `wall_top`, `mat`, `table_l|r`, `bed_t|b`.

## Areas (`src/world/areas/`)
`index.json`: `{screen: [24, 14], start: "joe_house", areas: [ids]}`. Each `<id>.json`:
`{id, name, kind: "overworld"|"interior", size_screens, origin_tiles: [x, y], rows: [...],
doors: [{cell, to, spawn_cell, facing}], exits: [{cells: [[x, y]...], to, spawn_cell, facing}],
npcs: [{id, cell, facing, across}], signs: [{cell, text}],
objects: [{kind: chest|big_chest|torch|cracked_rock|key_block|heart_piece|door|switch|push_block|heavy_rock, cell,
item?, amount?, reveal? ("" | "torches" | "switch"), flag? (switch flag), heavy?, dir?, type?, id?, when?}],
wares: [{ware, cell}]}`; dungeon rooms add `dungeon`, `grid`, `clear_flag?`, `boss_flag?`.
`index.json` adds `dungeons: {<id>: {name, seal | crystal, entrance, boss_room, boss_flag, ending?}}` (d1, d2, d3,
keep; d4, d5 and d6 hold crystals 0, 1 and 2) and `act2_spawn: {area, cell}`. Dark World areas carry `world: "dark"` (the Umbral Vale
has no Light World twin); objects may carry `via_mirror`; dungeon rooms may carry `dark: true`.

## World flags (`GameState.flags`)
Story: `met_tato`, `met_boni`, `met_janga`, `got_boomerang`. Dungeons: `door:<id>` (opened locked/big door),
`cleared:<room>`, `switch:<room>`, `boss:<dungeon>`, `heart_container:<boss room>`. Act 1: `rubble:...` (broken),
`keep:gate` (the seal gate opened), `act1:done`. Act 2: `act2:started` (intro shown), `got_moon_mirror`; `switch:d4_east`, `boss:d4`, `switch:d5_east`, `boss:d5`, `boss:d6`. Pegs and tick blocks have no saved state. Objects: `chest:<area>:<x>,<y>` (opened),
`cracked_rock:...` (broken), `key_block:...` (opened), `heart_piece:...` (taken), `ware:<id>` (sold out).
Glyphs are listed in `src/world/AreaBuilder.gd` and `docs/LEVEL_DESIGN.md`.

## Field layout (`TestField.layout`)
Array of equal-length strings; glyphs: `.` `,` `*` grass, `#` path, `R` rock, `T`+`x` tree, `B` bush, `O` pot, `Z` slime, `G` guard, `Q` rock-spitter, `P` spawn.

## Enemy packs (`assets/sprites/enemies/<pack>.json`)
`{frame_size, feet, anims: {name: {fps, loop}}}` with strips `<pack>_<name>.png`; directional anims are `<name>_down|up|side`.

## Effects (`assets/sprites/vfx/vfx_manifest.json`)
`{"<name>.png": {frame_size, fps, origin}}` - read by `Juice.play_fx`.

## Spin entry in Joe's manifest
`spin: {frames: 8, fps: 24, loop: true, start: {right: 0, down: 2, left: 4, up: 6}}` - frame i holds the sword at i*45 degrees.

## Drop table (`GameState.DROP_TABLE`)
Weights: nothing 50, heart 20, green gem 22, blue gem 6, red gem 2. Gem values 1 / 5 / 20.

## Dialogue (`assets/data/dialogue.json`)
`{"_header": {...}, "<key>": {name?, pages: [..], once?: [..], flag?, gift?: {item, amount?, flag, pages}}}` -
keys are villager ids, sign keys, `get_<kind>` item texts, `shop_*` offers/answers and `locked`.
`DialogueData.conversation(key, GameState)` returns `{pages, gift, amount}`: `once` the first time (sets `flag`),
then the gift's pages once (sets the gift's flag; the World runs the item-get), then `pages`.

## Villager sprites (`assets/sprites/npcs/npcs.json`)
`{frame: [32, 32], feet: [16, 29], fps: 2, npcs: [ids]}` with strips `<id>_idle_<down|up|side>.png` (2 frames;
side faces right, mirrored for left).

## UI art (`assets/ui/ui_manifest.json`, fonts)
Manifest: `{"<path>": {size, frames, notes}}`. Fonts: `font_5x7.png/.json`, `font_3x5.png/.json` -
`{cell, columns: 16, first_char: 32, advance: {char: px}}`.

## Save file (`user://village_save.json`)
`{version: 1, area, pos: [x, y] (the entry point of that area), facing: [x, y], hp, max_hp, saved_at,
state: {gems, magic, key_pools: {"": n, <dungeon>: n}, dungeon_items: {<dungeon>: {map, compass, big_key}},
visited: [area ids], bombs, arrows, heart_pieces, items: {id: level}, equipped, seals: [bool x3], crystals: [bool x4],
flags: {name: bool}}}` (an old save's `keys` becomes the overworld pool).
A file with another `version` is ignored (treated as no save).

## Item catalogue (`src/items/ItemDB.gd`)
`KINDS = {kind: {name, icon, text}}` for lantern, boomerang, bow, bombs, arrows, small_key, heart_piece,
heart_container, gems; `USES` (what an item spends); `WARES = {id: {kind, amount, price, text, once}}`.
Item effects: `assets/sprites/vfx/vfx_items.json` (same format as `vfx_manifest.json`).

## Planned
Both worlds' explored screens (map, Phase 8); settings (volume, language) in Phase 14.
