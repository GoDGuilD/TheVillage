# Arquitectura técnica — The Village

Documento de referencia para decisiones de diseño. Se actualiza cuando se introduce un patrón nuevo o se cambia uno existente.

---

## Principios guía

1. **Bajo acoplamiento** — los sistemas no se conocen entre sí directamente; se comunican via señales.
2. **Composición sobre herencia** — la lógica reutilizable va en nodos hijo, no en clases base largas.
3. **Una responsabilidad por script** — cada `.gd` hace una cosa y la hace bien.
4. **Fuente única de verdad** — valores numéricos viven en `Constants.gd`, nunca dispersos.
5. **Sin código monolítico** — si un script supera ~150 líneas, dividirlo.

---

## Estructura de carpetas

```
TheVillage/
│
├── autoloads/              ← singletons al nivel raíz, visibilidad inmediata
│   ├── EventBus.gd
│   ├── GameManager.gd
│   ├── SceneManager.gd
│   └── AudioManager.gd    (Fase 3)
│
├── scenes/
│   ├── world/
│   │   ├── rooms/          ← una .tscn por sala (Fase 4)
│   │   │   ├── Room_Forest_01.tscn
│   │   │   └── Room_Forest_02.tscn
│   │   └── World.tscn      ← orquestador, no contiene geometría
│   ├── player/
│   │   └── Player.tscn
│   ├── enemies/
│   │   ├── Slime.tscn
│   │   └── Bat.tscn        (Fase 6)
│   ├── ui/
│   │   ├── HUD.tscn        ← renombrar HealthUI → HUD (Fase 4)
│   │   └── menus/
│   │       ├── MainMenu.tscn
│   │       └── GameOver.tscn
│   └── shared/             ← escenas reutilizables (puertas, items)
│       ├── Door.tscn
│       ├── HeartDrop.tscn
│       └── Projectile.tscn (Fase 6)
│
├── scripts/
│   ├── combat/
│   │   ├── HitBox.gd
│   │   ├── HurtBox.gd
│   │   └── HealthComponent.gd
│   ├── components/         ← Node scripts reutilizables
│   │   ├── StateMachine.gd
│   │   ├── KnockbackComponent.gd  (Fase 5)
│   │   └── FlashComponent.gd      (Fase 5)
│   └── data/
│       └── Constants.gd    ← fuente única de valores configurables
│
├── resources/              ← Godot .tres: datos sin código
│   └── enemies/
│       └── slime_data.tres
│
└── assets/
	├── sprites/
	├── audio/
	└── fonts/
```

---

## Autoloads — responsabilidades

| Autoload | Responsabilidad | Estado |
|----------|-----------------|--------|
| `EventBus` | Bus de señales. Solo señales, cero lógica. | ✅ |
| `GameManager` | Estado global (enum GameState) + referencias globales | ✅ |
| `SceneManager` | Transiciones de sala con fade | ✅ |
| `AudioManager` | Pool de AudioStreamPlayer, SFX y música | Fase 3 |
| `SaveManager` | Persistencia con FileAccess | Fase 7 |

**Regla de oro:** ningún autoload llama a otro autoload directamente.
Si necesitan comunicarse, lo hacen a través de `EventBus`.

---

## Sistema de daño: HitBox / HurtBox

Dos tipos de `Area2D` con responsabilidades opuestas:

- **`HitBox`** — área que *inflige* daño. Solo tiene `damage: int`. No detecta nada.
- **`HurtBox`** — área que *recibe* daño. Monitorea HitBoxes y emite `hurt(damage)`.

### Capas de colisión 2D

```
Layer 1  (bitmask  1)  — World:         TileMapLayer y estáticos
Layer 2  (bitmask  2)  — Player:        CharacterBody2D del jugador
Layer 3  (bitmask  4)  — Enemies:       CharacterBody2D de enemigos
Layer 4  (bitmask  8)  — PlayerHitBox:  Espada del jugador
Layer 5  (bitmask 16)  — EnemyHitBox:   Contacto de enemigos
Layer 6  (bitmask 32)  — PlayerHurtBox: Zona de daño del jugador
Layer 7  (bitmask 64)  — EnemyHurtBox:  Zona de daño de enemigos
```

Regla: el `HurtBox` tiene `monitoring=true` y su mask apunta al layer del `HitBox` que debe detectar.

---

## StateMachine — componente reutilizable

`StateMachine.gd` es un `Node` hijo que descubre automáticamente los estados del padre por convención de nombres:

```gdscript
func state_idle_enter() -> void:   # llamado al entrar
func state_idle_update(delta) -> void:  # llamado cada frame
func state_idle_exit() -> void:    # llamado al salir
```

`_fsm.transition_to("walk")` maneja el ciclo enter/exit/update automáticamente.
Se usará en Player y en todos los enemigos para eliminar los `match` manuales.

---

## Estrategia de señales — dos niveles

```
NIVEL 1 — Señales locales (misma escena)
────────────────────────────────────────
HurtBox.hurt          → entidad._on_hurt()
HealthComponent.died  → entidad._on_died()
Timer.timeout         → entidad._on_attack_finished()

NIVEL 2 — EventBus (entre escenas distintas)
────────────────────────────────────────
Player      → EventBus.player_health_changed → HUD
Player      → EventBus.player_died           → GameManager → GameOver
Slime       → EventBus.enemy_died            → GameManager
SceneManager → EventBus.room_entered         → HUD

Regla: usa señal local si el emisor sabe exactamente quién escucha
	   y ambos viven en la misma escena raíz.
	   Usa EventBus si el emisor no sabe (ni le importa) quién escucha.
```

---

## HealthComponent

`Node` hijo que encapsula vida. Emite señales, no toca al padre directamente.

```
entidad/
└── HealthComponent   ← max_health configurable por @export
```

Señales: `health_changed(current, max)` y `died()`.
Compatible con cualquier nodo — jugador, enemigo, barril, boss.

---

## BaseEnemy / Herencia de enemigos

```
BaseEnemy (CharacterBody2D)  ← define estructura y ciclo de vida
└── Slime extends BaseEnemy  ← sobreescribe _update_idle/_update_chase
└── Bat   extends BaseEnemy  ← sobreescribe con movimiento sinusoidal
```

Agregar enemigo = nuevo `.gd` + `.tscn`. Sin tocar archivos existentes.

---

## GameManager — estados del juego

```
MENU ──play──→ PLAYING ──pause──→ PAUSED
				  │                  │
				  │←──────resume─────┘
				  │
			  player_died
				  │
			  GAME_OVER ──restart──→ PLAYING
```

---

## Convenciones de nombres

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Clases / escenas | PascalCase | `Player`, `HealthComponent` |
| Variables privadas | `_snake_case` | `_state`, `_facing` |
| Variables exportadas | `snake_case` | `move_speed`, `max_health` |
| Constantes | `SCREAMING_SNAKE` | `PLAYER_SPEED`, `SWORD_DAMAGE` |
| Señales | snake_case, pasado | `player_died`, `health_changed` |
| Métodos públicos | `verb_noun()` | `take_damage()`, `register_player()` |
| Métodos privados | `_verb_noun()` | `_handle_movement()` |
| Callbacks de señal | `_on_source_event()` | `_on_hurt()`, `_on_attack_finished()` |
| Salas | `Room_Bioma_NN.tscn` | `Room_Forest_01.tscn` |
| Recursos | `snake_case.tres` | `slime_data.tres` |

---

## Flujo de señales de vida (referencia)

```
Player recibe golpe
  → HurtBox.hurt(1)
	→ Player._on_hurt(1)
	  → HealthComponent.take_damage(1)
		→ HealthComponent.health_changed(5, 6)
		  → Player._on_health_changed(5, 6)
			→ EventBus.player_health_changed(5, 6)
			  → HUD._on_health_changed(5, 6)
				→ actualiza corazones en pantalla
```
