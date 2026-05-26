# The Village

Un prototipo de action-RPG top-down inspirado en *Zelda: A Link to the Past*, construido con Godot 4.6 y GDScript como proyecto de aprendizaje de vibe coding.

---

## Descripción

The Village es un videojuego 2D de perspectiva cenital con combate en tiempo real. El jugador explora mapas interconectados, lucha contra enemigos con una espada y gestiona su vida a través de un sistema de corazones. El objetivo a corto plazo es un prototipo jugable con un mapa, un tipo de enemigo y mecánicas core funcionando.

---

## Objetivos del prototipo

- [x] Movimiento top-down en 8 direcciones con soporte teclado y gamepad
- [x] Sistema de colisión HitBox / HurtBox desacoplado
- [x] Enemigo tipo Slime con IA de patrulla y persecución
- [x] Sistema de vida con componente reutilizable
- [x] HUD de corazones reactivo via bus de señales
- [ ] Sprites y animaciones del jugador (idle / walk / attack × 4 dirs)
- [ ] TileMap jugable con colisiones
- [ ] Audio: SFX y música de fondo
- [ ] Transición entre salas
- [ ] Pantalla de Game Over / Menú principal

---

## Stack técnico

| Herramienta | Versión | Rol |
|-------------|---------|-----|
| [Godot Engine](https://godotengine.org/) | 4.6 | Motor de juego |
| GDScript | 2.0 | Lenguaje de scripting |
| [Cursor AI](https://cursor.sh/) | latest | Editor con asistencia IA |
| GitHub | — | Control de versiones |

---

## Controles

| Acción | Teclado | Gamepad |
|--------|---------|---------|
| Mover | `WASD` / Flechas | Stick izquierdo / D-pad |
| Atacar | `Space` | Botón Sur (A / Cruz) |

---

## Arquitectura

El proyecto aplica principios de bajo acoplamiento mediante tres patrones clave:

**Signal Bus (`EventBus`)** — Singleton que retransmite eventos globales. Ningún sistema habla directamente con otro; emiten señales que cualquier oyente puede escuchar sin conocer al emisor.

**Composición via nodos (`HealthComponent`, `HitBox`, `HurtBox`)** — La lógica de vida y daño vive en nodos hijo reutilizables, no en scripts monolíticos. Cualquier entidad (jugador, enemigo, barril) puede tener vida simplemente añadiendo un `HealthComponent`.

**Herencia ligera para enemigos (`BaseEnemy → Slime`)** — La clase base define la máquina de estados. Las subclases solo sobreescriben `_update_idle()` y `_update_chase()`.

### Capas de colisión 2D

| Layer | Nombre | Bitmask |
|-------|--------|---------|
| 1 | World (TileMap) | 1 |
| 2 | Player | 2 |
| 3 | Enemies | 4 |
| 4 | PlayerHitBox (espada) | 8 |
| 5 | EnemyHitBox (contacto) | 16 |
| 6 | PlayerHurtBox | 32 |
| 7 | EnemyHurtBox | 64 |

---

## Estructura del proyecto

```
TheVillage/
├── scenes/
│   ├── world/          # Escena raíz del juego
│   ├── player/         # CharacterBody2D + scripts de jugador
│   ├── enemies/        # BaseEnemy + subclases (Slime, ...)
│   └── ui/             # HUD y pantallas
├── scripts/
│   ├── autoloads/      # EventBus, GameManager (singletons)
│   └── combat/         # HealthComponent, HitBox, HurtBox
└── assets/
    ├── sprites/        # player/, enemies/, world/
    └── audio/          # sfx/, music/
```

---

## Roadmap

### Fase 0 — Fundación ✅
Estructura de carpetas, arquitectura de scripts, sistema HitBox/HurtBox, lógica de movimiento, IA del Slime, HUD de vida.

### Fase 1 — Visibilidad (siguiente)
Sprites placeholder de 16×16px para el jugador y el Slime. TileMap básico con un tileset de colores. Cámara ajustada al mapa.

### Fase 2 — Arte e Integración
Importar spritesheet real (Kenney.nl o itch.io). Configurar animaciones en `AnimatedSprite2D`. Tileset con colisiones de forma correcta.

### Fase 3 — Audio
`AudioManager` singleton. SFX para ataque, daño, muerte. Música ambiente en loop con `AudioStreamPlayer`.

### Fase 4 — Level Design
Sala 1 (tutorial implícito). Sala 2 con enemigos adicionales. Transición de escena con fade.

### Fase 5 — Combate ampliado
Knockback al recibir daño. Flash visual con shader simple. Drops de corazón al matar enemigos. Segundo tipo de enemigo.

### Fase 6 — Sistemas de juego
Menú principal. Pantalla de Game Over. Sistema de guardado básico (`ConfigFile` o `FileAccess`).

### Fase 7 — Polish
Tweens de *juice* (squash & stretch). Partículas de muerte. Sprites de corazones en el HUD. Shake de cámara al recibir daño.

---

## Primeros pasos

1. Abrir Godot 4.6 → **Import** → seleccionar `project.godot`
2. Verificar que los autoloads `EventBus` y `GameManager` aparecen en **Project → Project Settings → Autoload**
3. Abrir `scenes/world/World.tscn` y presionar **F5**
4. Activar **Debug → Visible Collision Shapes** para ver hitboxes mientras no hay sprites

---

## Recursos de arte gratuitos recomendados

- **Kenney.nl** — `kenney.nl/assets` — Dungeon Tileset, RPG characters (CC0)
- **itch.io** — filtrar por `free + top-down + pixel art`
- Tamaño objetivo: **16×16px** por tile y sprite de personaje

---

## Licencia

Proyecto de aprendizaje personal. Sin licencia definida.
