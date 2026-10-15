<!--
File: ASSETS.md
Description: Asset inventory.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.2.0
-->

# Assets

| Folder | Content | Source |
|---|---|---|
| `assets/sprites/joe/` | 28 strips: idle/walk/attack/hurt/charge/lift/carry/carry_walk/throw x down/up/side, `spin` (8 frames, all facings), shadow, manifest | `tools/gen_joe.py` |
| `assets/sprites/enemies/` | `slime` (idle, hop), `guard` (walk x 3 facings), `spitter` (walk + spit x 3 facings) packs + `rock.png` | `tools/gen_enemies.py` |
| `assets/sprites/props/` | `pot`, `heart`, `gem_green/blue/red` (2-frame shine), `hud_heart` (full/half/empty), `digits` | `tools/gen_props.py` |
| `assets/sprites/vfx/` | `poof`, `hit_spark`, `glint`, `shards` + `vfx_manifest.json` | `tools/gen_props.py` |
| `assets/sprites/world/` | `bush.png`, `leaf_burst.png` | `tools/gen_tiles.py` |
| `assets/tiles/` | `overworld_light.png` + `.json` (83 cells: grass, path, water, ledges, cliffs, fence, sign, trees, two cottages, interiors; flags solid/ledge/door/exit) | `tools/gen_tiles.py` + `tools/terrain_art.py` |
| `src/world/areas/` | `index.json` + 9 area files (5 overworld, 4 interiors) | `tools/gen_areas.py` |
| `assets/audio/sfx/` | 18 effects: sword_slash, sword_spin, charge_ready, enemy_hit, enemy_die, hurt, player_die, bush_cut, lift, throw, shatter, pickup_heart, pickup_gem, shield_block, spit, ledge_hop, land, door | `tools/gen_sfx.py` |
| `assets/shaders/` | `flash.gdshader` (white hit flash) | ported from Chapel |
| `assets/branding/` | icon and splash from the 2024 UE5 prototype | recovered |
| `assets/reference/joe/` | 2024 character sheet and pixel frames | recovered, reference only |
| `assets/audio/*.wav/.mp3` (root) | 2024 music/SFX clips | recovered, **licences unverified - do not ship** |
