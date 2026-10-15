<!--
File: DATA_MODEL.md
Description: Data files and their shapes.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.1.0
-->

# Data model

## Joe animation manifest (`assets/sprites/joe/joe_animations.json`)
`{frame_size: [48,48], feet: [24,34], anims: {<anim>_<facing>: {frames, fps, loop, hit_window?}, spin: {...}}}` - facings `down`, `up`, `side` (left = mirrored side). Strips are `joe_<anim>_<facing>.png`.

## Tile manifest (`assets/tiles/overworld_light.json`)
`{tile_size: 16, cells: {name: {cell: [col,row], solid: bool}}}` - names: `grass_a`, `grass_b`, `flowers`, `rock`, `path_<dx>_<dy>` (nine-slice, dx/dy in -1..1), `tree_<x>_<y>` (2x2).

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

## Planned (Phase 4)
Save file: current area and position, health, inventory, flags, both worlds' explored screens.
