class_name Constants
## Single source of truth for all configurable game values.
## Used as Constants.PLAYER_SPEED — no instantiation, no autoload.

# ─── Player ───────────────────────────────────────────────────────────────────
const PLAYER_SPEED           := 80.0
const PLAYER_ACCELERATION    := 700.0
const PLAYER_FRICTION        := 600.0
const PLAYER_MAX_HEALTH      := 6
const PLAYER_ATTACK_DURATION  := 0.3
const PLAYER_IFRAMES_DURATION := 1.0
const PLAYER_SWORD_REACH     := 12.0

# ─── Enemies ──────────────────────────────────────────────────────────────────
const SLIME_SPEED           := 35.0
const SLIME_MAX_HEALTH      := 2
const SLIME_DETECTION_RADIUS := 80.0
const SLIME_CONTACT_DAMAGE  := 1

const BAT_SPEED             := 55.0
const BAT_MAX_HEALTH        := 1
const BAT_DETECTION_RADIUS  := 100.0

# ─── Combat ───────────────────────────────────────────────────────────────────
const SWORD_DAMAGE          := 1
const KNOCKBACK_FORCE       := 120.0
const KNOCKBACK_DURATION    := 0.15

# ─── Collision layers (bitmasks) ─────────────────────────────────────────────
const LAYER_WORLD           := 1
const LAYER_PLAYER          := 2
const LAYER_ENEMIES         := 4
const LAYER_PLAYER_HITBOX   := 8
const LAYER_ENEMY_HITBOX    := 16
const LAYER_PLAYER_HURTBOX  := 32
const LAYER_ENEMY_HURTBOX   := 64

# ─── Animations ───────────────────────────────────────────────────────────────
const ANIM_IDLE_FPS         := 5.0
const ANIM_WALK_FPS         := 8.0
const ANIM_ATTACK_FPS       := 12.0

# ─── Transitions ──────────────────────────────────────────────────────────────
const FADE_DURATION         := 0.3

# ─── Tile and world (legacy World.tscn scene) ────────────────────────────────
const TILE_SIZE             := 16
const WORLD_HALF_TILES_X    := 12
const WORLD_HALF_TILES_Y    := 8

# ─── Room (one screen = 320×180 px) ──────────────────────────────────────────
## Each room occupies exactly the viewport. The camera is fixed with limits.
## Width: 10×2×16 = 320 px = exact viewport.
## Height: 6×2×16 = 192 px (12 px extra margin, hidden by camera limits).
const ROOM_HALF_TILES_X     := 10
const ROOM_HALF_TILES_Y     := 6
const VIEWPORT_HALF_W       := 160   # 320 / 2
const VIEWPORT_HALF_H       := 90    # 180 / 2

# ─── Collectible items ────────────────────────────────────────────────────────
## Probability that a slime drops a half heart on death.
const HEART_DROP_CHANCE := 0.30

# ─── Scene paths ──────────────────────────────────────────────────────────────
const SCENE_SALA1       := "res://scenes/world/rooms/Sala1_Tutorial.tscn"
const SCENE_SALA2       := "res://scenes/world/rooms/Sala2_Desafio.tscn"
const SCENE_HEART_PICKUP := "res://scenes/items/HeartPickup.tscn"
const SCENE_MAIN_MENU   := "res://scenes/ui/MainMenu.tscn"
