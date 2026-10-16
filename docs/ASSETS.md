<!--
File: ASSETS.md
Description: Asset inventory.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-16
Version: 1.5.0
-->

# Assets

| Folder | Content | Source |
|---|---|---|
| `assets/sprites/joe/` | 28 strips: idle/walk/attack/hurt/charge/lift/carry/carry_walk/throw x down/up/side, `spin` (8 frames, all facings), shadow, manifest | `tools/gen_joe.py` |
| `assets/sprites/enemies/` | `slime` (idle, hop), `guard` (walk x 3 facings), `spitter` (walk + spit x 3 facings) packs + `rock.png` | `tools/gen_enemies.py` |
| `assets/sprites/props/` | `pot`, `heart`, `gem_green/blue/red` (2-frame shine), `hud_heart` (full/half/empty), `digits` | `tools/gen_props.py` |
| `assets/sprites/vfx/` | `poof`, `hit_spark`, `glint`, `shards` + `vfx_manifest.json` | `tools/gen_props.py` |
| `assets/sprites/world/` | `bush.png`, `leaf_burst.png` | `tools/gen_tiles.py` |
| `assets/tiles/` | `overworld_light.png` + `.json` (113 cells, incl. dungeon floor/walls/pillar/stairs/pits and the shrine facade; grass, path, water, ledges, cliffs, fence, sign, trees, two cottages, interiors; flags solid/ledge/door/exit) | `tools/gen_tiles.py` + `tools/terrain_art.py` |
| `assets/sprites/npcs/` | Tato, Boni, Janga, villager_woman (Marta), villager_boy (Pico): idle x down/up/side + `npcs.json` | `tools/gen_npcs.py` |
| `assets/ui/` | fonts `font_5x7` / `font_3x5` (+ metrics), `hud/` (magic frame + fill, item box, key), `menu/` (box, caption, cursor, more arrow, slot, seals, sword/shield icons), `title_logo.png`, `ui_manifest.json` | `tools/gen_ui.py` (glyphs: `tools/font_glyphs.py`, shared with Chapel of Dreams) |
| `assets/sprites/items/` | chest (closed/open), boomerang spin, arrow, bomb (normal/flash), torch unlit/lit, cracked rock, key block, heart piece, heart container, small key | `tools/gen_items.py` |
| `assets/ui/items/` + `hud/bomb_small`, `hud/arrow_small`, `menu/heart_pieces` | 16x16 item icons (lantern, boomerang, bow, bombs), ammo counter icons, heart quarters | `tools/gen_items.py` |
| `assets/sprites/vfx/explosion.png`, `flame.png` + `vfx_items.json` | bomb blast, lantern flame | `tools/gen_items.py` |
| `assets/sprites/dungeon/` | doors (locked/big/shutter x n/s/e/w), floor switch, push block, big chest, heavy rock, family seal | `tools/gen_dungeon.py` |
| `assets/sprites/enemies/grand_slime*` | the Moss Shrine's boss (idle, hop; 48x56) | `tools/gen_dungeon.py` |
| `assets/ui/items/map,compass,big_key,glove.png` | dungeon item and glove icons | `tools/gen_dungeon.py` |
| `assets/data/dialogue.json` | every villager line and sign text | hand-written (story lines are a draft) |
| `src/world/areas/` | `index.json` + 9 area files (5 overworld, 4 interiors) with villagers and signs | `tools/gen_areas.py` |
| `assets/audio/sfx/` | 42 effects: sword_slash, sword_spin, charge_ready, enemy_hit, enemy_die, hurt, player_die, bush_cut, lift, throw, shatter, pickup_heart, pickup_gem, shield_block, spit, ledge_hop, land, door, menu_move, menu_select, menu_back, text_blip, pause, save_done, game_over, item_get, heart_piece, chest_open, boomerang, arrow_shot, arrow_hit, bomb_place, explode, unlock, lantern, shop_buy, error, fall, shutter, switch_click, block_push, boss_die | `tools/gen_sfx.py` |
| `assets/shaders/` | `flash.gdshader` (white hit flash) | ported from Chapel |
| `assets/branding/` | icon and splash from the 2024 UE5 prototype | recovered |
| `assets/reference/joe/` | 2024 character sheet and pixel frames | recovered, reference only |
| `assets/audio/*.wav/.mp3` (root) | 2024 music/SFX clips | recovered, **licences unverified - do not ship** |
