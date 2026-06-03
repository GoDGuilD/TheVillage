class_name Constants
## Fuente única de verdad para todos los valores configurables del juego.
## Se usa como Constants.PLAYER_SPEED — sin instanciar, sin autoload.

# ─── Jugador ──────────────────────────────────────────────────────────────────
const PLAYER_SPEED           := 80.0
const PLAYER_ACCELERATION    := 700.0
const PLAYER_FRICTION        := 600.0
const PLAYER_MAX_HEALTH      := 6
const PLAYER_ATTACK_DURATION  := 0.3
const PLAYER_IFRAMES_DURATION := 1.0
const PLAYER_SWORD_REACH     := 12.0

# ─── Enemigos ─────────────────────────────────────────────────────────────────
const SLIME_SPEED           := 35.0
const SLIME_MAX_HEALTH      := 2
const SLIME_DETECTION_RADIUS := 80.0
const SLIME_CONTACT_DAMAGE  := 1

const BAT_SPEED             := 55.0
const BAT_MAX_HEALTH        := 1
const BAT_DETECTION_RADIUS  := 100.0

# ─── Combate ──────────────────────────────────────────────────────────────────
const SWORD_DAMAGE          := 1
const KNOCKBACK_FORCE       := 120.0
const KNOCKBACK_DURATION    := 0.15

# ─── Capas de colisión (bitmasks) ────────────────────────────────────────────
const LAYER_WORLD           := 1
const LAYER_PLAYER          := 2
const LAYER_ENEMIES         := 4
const LAYER_PLAYER_HITBOX   := 8
const LAYER_ENEMY_HITBOX    := 16
const LAYER_PLAYER_HURTBOX  := 32
const LAYER_ENEMY_HURTBOX   := 64

# ─── Animaciones ──────────────────────────────────────────────────────────────
const ANIM_IDLE_FPS         := 5.0
const ANIM_WALK_FPS         := 8.0
const ANIM_ATTACK_FPS       := 12.0

# ─── Transiciones ─────────────────────────────────────────────────────────────
const FADE_DURATION         := 0.3

# ─── Tile y mundo (escena World.tscn legacy) ──────────────────────────────────
const TILE_SIZE             := 16
const WORLD_HALF_TILES_X    := 12
const WORLD_HALF_TILES_Y    := 8

# ─── Sala (una pantalla = 320×180 px) ────────────────────────────────────────
## Cada sala ocupa exactamente el viewport. La cámara se fija con límites.
## Ancho: 10×2×16 = 320 px = viewport exacto.
## Alto:  6×2×16 = 192 px (12 px de margen extra, ocultos por los límites de cámara).
const ROOM_HALF_TILES_X     := 10
const ROOM_HALF_TILES_Y     := 6
const VIEWPORT_HALF_W       := 160   # 320 / 2
const VIEWPORT_HALF_H       := 90    # 180 / 2

# ─── Objetos recogibles ───────────────────────────────────────────────────────
## Probabilidad de que un slime suelte un medio corazón al morir.
const HEART_DROP_CHANCE := 0.30

# ─── Rutas de escenas ─────────────────────────────────────────────────────────
const SCENE_SALA1       := "res://scenes/world/rooms/Sala1_Tutorial.tscn"
const SCENE_SALA2       := "res://scenes/world/rooms/Sala2_Desafio.tscn"
const SCENE_HEART_PICKUP := "res://scenes/items/HeartPickup.tscn"
const SCENE_MAIN_MENU   := "res://scenes/ui/MainMenu.tscn"
