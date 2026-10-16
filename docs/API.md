<!--
File: API.md
Description: Internal scripting API of the main classes.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 2.0.0
-->

# API

The game has no network API; this is the internal API other scripts and tests rely on.

## Player (`src/player/Player.gd`)
- Signals: `health_changed(current, maximum)`, `died`, `talk_requested(target)`.
- Properties: `facing: Vector2i`, `health`, `sprite`, `sword: HitBox`, `spin_box: HitBox`, `hurt_box`, `fsm`
  (states `idle walk hop attack charge spin lift carry throw hurt dead`), `charged`, `carrying` (`""`, `"pot"`, `"bush"`),
  `_input_override` (tests).
- Calls: `is_invincible()`, `is_dead()`, `is_hopping()`, `freeze(seconds)`, `unfreeze()`, `blocks_from(source_position)`, `liftable_in_front()`, `talkable_in_front()`,
  `revive(at)`, `collect(kind)`.

## Enemies (`src/enemies/`)
- `BaseEnemy`: signal `defeated(at)`; `player` (set by the field), `health`, `facing`, `freeze()`, `is_dead()`;
  static `spawn_drop(parent, at)`.
- `Guard.chasing`, `Spitter.spit()` / `shots`, `EnemyRock.deflect()` / `deflected`.

## World (`src/world/World.gd`, main scene)
- Signal `area_entered(area_id)`. Properties: `areas` (id -> data), `start_area`, `current` (`{id, data, tiles,
  actors, rect, bushes, pots, enemies}`), `player`, `camera`, `hud`, `dialogue`, `pause_menu`, `item_menu`,
  `game_over`, `talking`, `transitioning`, `transitions`, `entry_point`, `entry_facing`, `deaths`.
- Calls: `start_at(area_id, feet)` (before entering the tree), `current_id()`, `origin_of(id)`, `rect_of(id)`,
  `cell_feet(id, [x, y])`, `overworld_at(point)`, `camera_target(point, rect)`; `_enter(id, feet, facing)` is the
  instant (test) move; `save_game() -> bool`, `quit_to_title()`, `can_open_menu()`, `box_at_top(screen_pos)`.

## AreaBuilder (`src/world/AreaBuilder.gd`, static)
- `tileset()`, `build(rows, actors, indoor, with_enemies, origin) -> {tiles, bushes, pots, enemies, spawn, doors,
  exits}`, `glyph(rows, x, y)`, `flag_at(tree, world_pos, flag)`.

## Other world nodes (`src/world/`)
- `TestField`: `layout`, `spawn_enemies`, `player`, `hud`, `bushes`, `pots`, `enemies`, `spawn_point`, `deaths`,
  `field_size()`.
- `Npc`: `setup(id, facing, across)`, `npc_id`, `facing`, `face(dir)`; talkable. `SignPost`: `setup(key)`; talkable.
  Talkable contract (group `talkable`): `talk_point()`, `talk(from) -> key`, `rest()`.
- `Bush`: signal `cut(at)`, `is_cut()`, liftable. `Pot`: liftable. Liftable contract: `can_lift()`, `lift()`.
- `Thrown`: signal `broke(at)`; `kind`, `direction`, `travel`, `damage`. `Pickup`: `kind`, signal `collected(kind)`.

## Autoloads
- `GameState`: signals `gems_changed`, `magic_changed(current, maximum)`, `keys_changed`, `equipped_changed(item)`;
  `gems`, `magic`, `keys`, `items`, `equipped`, `seals`, `flags`; `add_gems()`, `use_magic() -> bool`, `add_magic()`,
  `add_keys()`, `give_item()`, `has_item()`, `equip()`, `set_flag()`, `has_flag()`, `seal_count()`, `roll_drop()`,
  `snapshot()`, `restore(data)`, `reset()`; `MAX_MAGIC`, `ITEM_ORDER`, `SEAL_COUNT`, `GEM_VALUES`.
- `Audio`: `sfx(name, pitch, volume_db, jitter)`, `played_recently(name, n)`, `history`, `last_sfx`.
- `Juice`: `shake(px, seconds)`, `hit_stop(actors, seconds)`, `play_fx(name, pos, parent)`, `fx_count`,
  `last_hit_stop`.

## Combat
- `HitBox`: `damage`, `knockback`, `element`, `blockable`, `set_active(on)`, signal `landed(hurt_box)`.
- `HurtBox`: signal `hurt(damage, source_position, knockback)`, `recheck()`, `last_hit`.
- `HealthComponent`, `StateMachine`: as ported from Chapel of Dreams.

## UI
- `Hud`: `set_health(current, maximum)`, `set_gems()`, `set_magic()`, `set_keys()`, `set_item()`, `show_caption(text)`,
  `caption_visible()`; test read-outs `hearts_shown` (e.g. `"FHE"`), `gems_shown`, `magic_shown`, `keys_shown`,
  `caption_shown`.
- `DialogueBox`: signal `closed`; `open(pages, speaker, at_top)`, `advance()`, `close()`, `is_open`, `is_typing()`,
  `visible_text()`, `boxes`, `box_index`.
- `PauseMenu` (signals `save_requested`, `quit_requested`, `closed`; `open()`, `close()`, `show_saved(ok)`, `menu`,
  `note`), `ItemMenu` (`open()`, `close()`, `move_cursor(dir)`, `confirm()`, `selected`), `GameOver` (signal
  `picked(choice)`; `open()`, `is_ready_to_choose()`, `menu`; choices `CONTINUE`, `SAVE_CONTINUE`, `SAVE_QUIT`).
- `MenuList`: signals `chosen(index)`, `cancelled`, `moved(index)`; `set_items([{label, enabled}])`, `confirm()`,
  `selected`, `items`, `active`. `PixelText`: `make()`, `measure()`, `line_height()`, `wrap(text, max_px)`.
- `TitleScreen`: `menu`, `menu_items()`, `start_game(continue_save)`.

## Saves and text (`src/core/`)
- `SaveGame` (static): `path`, `pending`, `has_save()`, `read()`, `write(data)`, `delete()`,
  `capture(area, feet, facing, hp, max_hp, state)`, `VERSION`.
- `DialogueData` (static): `has(key)`, `speaker(key)`, `pages_for(key, state)`.
