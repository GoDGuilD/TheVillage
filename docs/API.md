<!--
File: API.md
Description: Internal scripting API of the main classes.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-19
Version: 2.3.0
-->

# API

The game has no network API; this is the internal API other scripts and tests rely on.

## Player (`src/player/Player.gd`)
- Signals: `health_changed(current, maximum)`, `died`, `talk_requested(target)`, `item_collected(kind)`, `fell`.
- Properties: `facing: Vector2i`, `health`, `sprite`, `sword: HitBox`, `spin_box: HitBox`, `hurt_box`, `fsm`
  (states `idle walk hop attack charge spin lift carry throw use hold fall dash_charge dash bonk hurt dead`), `held_sprite`, `used_item`, `charged`, `carrying` (`""`, `"pot"`, `"bush"`),
  `_input_override` (tests).
- Calls: `is_invincible()`, `is_dead()`, `is_hopping()`, `freeze(seconds)`, `unfreeze()`, `blocks_from(source_position)`, `liftable_in_front()`, `talkable_in_front()`,
  `revive(at)`, `collect(kind)`, `hold_up(texture)`, `end_hold()`, `is_falling()`, `respawn_after_fall(at, facing)`, `is_dashing()`.

## Enemies (`src/enemies/`)
- `GrandSlime` (boss): `is_boss`, `minions`, `angry()`. `IronRam`: `state`, `charges`, `is_dazed()`. `FrostWraith`:
  `casts`, `cast()`. `CaverShade`: `throws`, `throw_orb()`, `phase`. `Bat`. `CaverOrb`: `bat_back()`, `batted`,
  `caster` (group `orb`). `EnemyShot`: `direction`, `texture`, `deflect()` (group `enemy_shot`).
- `BaseEnemy._resists(hit) -> bool` (override; resisted hits clank).
- `BaseEnemy`: `stun_immune`; signal `defeated(at)`; `player` (set by the field), `health`, `facing`, `freeze()`, `is_dead()`;
  static `spawn_drop(parent, at)`.
- `Guard.chasing`, `Spitter.spit()` / `shots`, `EnemyRock.deflect()` / `deflected`.

## World (`src/world/World.gd`, main scene)
- Signal `area_entered(area_id)`. Properties: `areas` (id -> data), `start_area`, `current` (`{id, data, tiles,
  actors, rect, bushes, pots, enemies}`), `player`, `camera`, `hud`, `dialogue`, `pause_menu`, `item_menu`,
  `game_over`, `talking`, `transitioning`, `transitions`, `entry_point`, `entry_facing`, `deaths`.
- Calls: `start_at(area_id, feet)` (before entering the tree), `current_id()`, `origin_of(id)`, `rect_of(id)`,
  `cell_feet(id, [x, y])`, `overworld_at(point)`, `camera_target(point, rect)`; `_enter(id, feet, facing)` is the
  instant (test) move; `save_game() -> bool`, `quit_to_title()`, `can_open_menu()`, `box_at_top(screen_pos)`,
  `say(key)`, `item_get(kind, amount)`, `grant(kind, amount) -> bool` (true = new heart container), `buy(ware_node)`,
  static `object_flag(kind, area, cell)`, `item_gets` (tests); dungeons: `dungeons`, `map_screen`, `group_of(id)`,
  `area_at(point, group)`, `dungeon_of(id)`, `leave_dungeon()`, `falls` (tests); Act 1: `end_card`, `play_ending(act)`,
  `endings` (tests), `GATE_FLAG`, `ACT1_FLAG`.

## AreaBuilder (`src/world/AreaBuilder.gd`, static)
- `tileset()`, `build(rows, actors, indoor, with_enemies, origin) -> {tiles, bushes, pots, enemies, spawn, doors,
  exits}`, `glyph(rows, x, y)`, `flag_at(tree, world_pos, flag)`.

## Other world nodes (`src/world/`)
- `TestField`: `layout`, `spawn_enemies`, `player`, `hud`, `bushes`, `pots`, `enemies`, `spawn_point`, `deaths`,
  `field_size()`.
- `Npc`: `setup(id, facing, across)`, `npc_id`, `facing`, `face(dir)`; talkable. `SignPost`: `setup(key)`; talkable.
  Talkable contract (group `talkable`): `talk_point()`, `talk(from) -> key`, `rest()`.
- `Chest` (`setup(kind, amount, flag, opened, concealed)`, `reveal()`, `open()`, `can_open()`, `kind`, `opened`,
  `concealed`), `Torch` (signal `lit_up`; `light()`, `lit`, `flame_point()`), `CrackedRock` (signal `broken`;
  `blast()`, group `bombable`), `KeyBlock` (`unlock()`), `ShopItem` (`setup(ware)`, `price()`, `sold_out()`).
- `Door` (`setup(id, type, dir, when, open)`, `open_door()`, `close_door()`, `flag()`, `door_id`, `type`, `when`,
  `is_open`), `FloorSwitch` (signal `pressed_down(flag)`; `press()`, `pressed`, `heavy`; group `floor_switch`),
  `PushBlock` (signal `moved`; `push(dir, delta)`, `try_move(dir)`, `pushes`), `BigChest` (a Chest with
  `needs_big_key`), `HeavyRock` (liftable with the glove), `Rubble` (signal `broken`; `dash_break()`, group
  `dashable`), `SealGate` (`setup(flag, open)`, `refresh(seals)`, `open_gate()`, `is_open`). `Chest` adds `reveal_by`, `reveal_flag`.
- `Bush`: signal `cut(at)`, `is_cut()`, liftable. `Pot`: liftable. Liftable contract: `can_lift()`, `lift()`.
- `Thrown`: signal `broke(at)`; `kind`, `direction`, `travel`, `damage`. `Pickup`: `kind`, signal `collected(kind)`.

## Autoloads
- `GameState`: signals `gems_changed`, `magic_changed(current, maximum)`, `keys_changed`, `equipped_changed(item)`;
  `gems`, `magic`, `keys`, `items`, `equipped`, `seals`, `flags`; `add_gems()`, `use_magic() -> bool`, `add_magic()`,
  `add_keys()`, `add_ammo(kind, n) -> int`, `use_ammo(kind) -> bool`, `ammo_full()`, `add_heart_piece() -> bool`,
  `bombs`, `arrows`, `heart_pieces`, signal `ammo_changed`, `key_pool`, `key_pools`, `set_key_pool()`,
  `dungeon_items`, `has_dungeon_item()`, `give_dungeon_item()`, `visited`, `give_item()`, `has_item()`, `equip()`, `set_flag()`, `has_flag()`, `seal_count()`, `roll_drop()`,
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
- `DialogueBox`: signals `closed`, `answered(index)`; `open(pages, speaker, at_top, choices)`, `advance()`, `close()`,
  `is_open`, `is_typing()`, `is_asking()`, `choice_menu`, `visible_text()`, `boxes`, `box_index`.
- `PauseMenu` (signals `save_requested`, `quit_requested`, `closed`; `open()`, `close()`, `show_saved(ok)`, `menu`,
  `note`), `ItemMenu` (`open()`, `close()`, `move_cursor(dir)`, `confirm()`, `selected`), `GameOver` (signal
  `picked(choice)`; `open()`, `is_ready_to_choose()`, `menu`; choices `CONTINUE`, `SAVE_CONTINUE`, `SAVE_QUIT`).
- `MenuList`: signals `chosen(index)`, `cancelled`, `moved(index)`; `set_items([{label, enabled}])`, `confirm()`,
  `selected`, `items`, `active`. `PixelText`: `make()`, `measure()`, `line_height()`, `wrap(text, max_px)`.
- `EndCard`: signal `finished`; `open(title, lines)`, `close()`, `is_open`, `ready_to_close`, `lines_shown`.
- `MapScreen`: signal `closed`; `open(areas, current, dungeons)`, `close()`, `is_open`, `shown_rooms`, `here`,
  `boss_marked`. `Hud.show_zero_keys`.
- `TitleScreen`: `menu`, `menu_items()`, `start_game(continue_save)`.

## Items (`src/items/`)
- `ItemDB` (static): `KINDS`, `DUNGEON_ITEMS`, `USES`, `WARES`, `LANTERN_MAGIC`, `has()`, `display_name()`, `icon()`, `text_key()`.
- `ItemUse` (static): `use(player, item, aim) -> bool`, `torch_near(tree, at)`.
- `Fireball` (`direction`, `burst()`; group `fireball`; element "fire").
- `Boomerang` (signal `returned`; `direction`, `owner_node`, `coming_back`, `carried`, `turn_back()`; group
  `boomerang`), `Arrow` (`direction`, `stuck`; group `arrow`), `Bomb` (signal `exploded`; `fuse_left`, `explode()`;
  group `bomb`).

## Saves and text (`src/core/`)
- `SaveGame` (static): `path`, `pending`, `has_save()`, `read()`, `write(data)`, `delete()`,
  `capture(area, feet, facing, hp, max_hp, state)`, `VERSION`.
- `DialogueData` (static): `has(key)`, `speaker(key)`, `pages_for(key, state)`, `conversation(key, state)`.
