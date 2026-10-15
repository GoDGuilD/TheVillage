<!--
File: DATA_MODEL.md
Description: Data files and their shapes.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Data model

## Joe animation manifest (`assets/sprites/joe/joe_animations.json`)
`{frame_size: [48,48], feet: [24,34], anims: {<anim>_<facing>: {frames, fps, loop, hit_window?}}}` - facings `down`, `up`, `side` (left = mirrored side). Strips are `joe_<anim>_<facing>.png`.

## Tile manifest (`assets/tiles/overworld_light.json`)
`{tile_size: 16, cells: {name: {cell: [col,row], solid: bool}}}` - names: `grass_a`, `grass_b`, `flowers`, `rock`, `path_<dx>_<dy>` (nine-slice, dx/dy in -1..1), `tree_<x>_<y>` (2x2).

## Field layout (`TestField.layout`)
Array of equal-length strings; glyphs: `.` `,` `*` grass, `#` path, `R` rock, `T`+`x` tree, `B` bush, `P` spawn.

## Planned (Phase 4)
Save file: current area and position, health, inventory, flags, both worlds' explored screens.
