class_name Constants
## Fuente única de verdad para todos los valores configurables del juego.
## Se usa como Constants.PLAYER_SPEED — sin instanciar, sin autoload.

# ─── Jugador ──────────────────────────────────────────────────────────────────
const PLAYER_SPEED           := 80.0
const PLAYER_ACCELERATION    := 700.0   # px/s² — qué tan rápido alcanza la velocidad máx
const PLAYER_FRICTION        := 600.0   # px/s² — qué tan rápido frena al soltar el stick
const PLAYER_MAX_HEALTH      := 6
const PLAYER_ATTACK_DURATION  := 0.3   # segundos que dura el swing
const PLAYER_IFRAMES_DURATION := 1.0   # segundos de invencibilidad tras daño
const PLAYER_SWORD_REACH     := 12.0   # pixels desde el centro al hitbox

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
