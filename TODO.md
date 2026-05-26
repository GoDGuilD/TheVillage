# TODO — The Village

> Prioridad: 🔴 Crítica · 🟠 Alta · 🟡 Media · 🟢 Baja  
> Dificultad: ⬛ 1–5 estrellas

---

## Fase 0 — Fundación ✅

- [x] 🔴 Estructura de carpetas y `project.godot`
- [x] 🔴 `EventBus` + `GameManager` (autoloads)
- [x] 🔴 `HealthComponent` reutilizable
- [x] 🔴 `HitBox` / `HurtBox` con capas de colisión
- [x] 🔴 Player: movimiento 8 dirs + teclado/gamepad
- [x] 🔴 Player: ataque espada + iFrames (invencibilidad)
- [x] 🔴 Player: máquina de estados (IDLE / WALK / ATTACK)
- [x] 🔴 `BaseEnemy` + `Slime` con IA básica (patrulla + persecución)
- [x] 🔴 `HealthUI` con ColorRect placeholders
- [x] 🔴 `Camera2D` siguiendo al jugador

---

## Fase 1 — Visibilidad ⬛⬛⬛⬜⬜

> Desbloquea todo lo demás. Prioridad máxima.

- [x] 🔴 Sprite placeholder 16×16 para Player (`PlaceholderSprite.gd`, azul 12×14)
- [x] 🔴 Sprite placeholder 12×12 para Slime (`PlaceholderSprite.gd`, verde 10×10)
- [x] 🔴 TileMap con tileset de colores sólidos (`World.gd → _generate_floor()`)
- [ ] 🔴 Verificar que Player y Slimes son visibles en runtime
- [ ] 🟠 Ajustar límites de `Camera2D` al tamaño del mapa
- [ ] 🟠 Confirmar que HitBox/HurtBox funcionan (Debug > Visible Collision Shapes)

---

## Fase 2 — Arte e integración ⬛⬛⬜⬜⬜

- [ ] 🟠 Importar spritesheet de jugador (Kenney.nl o itch.io, 16×16)
- [ ] 🟠 Configurar las 12 animaciones en `AnimatedSprite2D` del Player
  - idle_down / idle_up / idle_left / idle_right
  - walk_down / walk_up / walk_left / walk_right
  - attack_down / attack_up / attack_left / attack_right
- [ ] 🟠 Importar spritesheet de Slime (idle + walk)
- [ ] 🟠 Importar tileset con colisiones correctas (TileMapLayer)
- [ ] 🟡 Sprites de corazón para reemplazar ColorRect en el HUD
- [ ] 🟠 Ajustar `CollisionShape2D` al tamaño real de los sprites

---

## Fase 3 — Audio ⬛⬛⬜⬜⬜

- [ ] 🟡 Crear `AudioManager` autoload (`scripts/autoloads/AudioManager.gd`)
- [ ] 🟠 SFX: ataque de espada
- [ ] 🟠 SFX: jugador recibe daño
- [ ] 🟡 SFX: muerte de Slime
- [ ] 🟢 SFX: pasos del jugador (según tipo de suelo)
- [ ] 🟡 Música ambiente en loop (`AudioStreamPlayer`)

---

## Fase 4 — Level Design ⬛⬛⬛⬜⬜

- [ ] 🟠 Sala 1: diseño completo con obstáculos y enemigos
- [ ] 🟡 Sala 2: layout diferente, más enemigos
- [ ] 🟠 Puertas como `Area2D` que triggean transición
- [ ] 🟠 Sistema de transición de escena (fade + `change_scene_to_file`)
- [ ] 🟠 Spawn de enemigos correctamente posicionado por sala

---

## Fase 5 — Combate ampliado ⬛⬛⬜⬜⬜

- [ ] 🟠 Knockback al recibir daño (jugador y enemigo)
- [ ] 🟡 Flash rojo en sprite al recibir daño (`modulate` + tween)
- [ ] 🟡 Drop de corazón al matar Slime (probabilidad configurable)
- [ ] 🟡 Item corazón recolectable que llama `HealthComponent.heal()`
- [ ] 🟢 Efecto de muerte del Slime (partículas o tween de escala)

---

## Fase 6 — Segundo enemigo ⬛⬛⬛⬜⬜

- [ ] 🟡 `Bat.gd` — extiende `BaseEnemy`, vuela (sin colisión con TileMap)
- [ ] 🟡 Movimiento sinusoidal para Bat
- [ ] 🟢 `Archer.gd` — dispara `Projectile.tscn` hacia el jugador
- [ ] 🟢 `Projectile.gd` — se mueve en dirección fija, tiene HitBox, se destruye al chocar

---

## Fase 7 — Sistemas de juego ⬛⬛⬜⬜⬜

- [ ] 🟠 Pantalla Game Over con botón Reiniciar
- [ ] 🟡 Menú principal (Play, Quit)
- [ ] 🟢 Persistencia con `FileAccess` (mejor sala alcanzada)

---

## Fase 8 — Polish ⬛⬛⬜⬜⬜

- [ ] 🟢 Camera shake al recibir daño
- [ ] 🟢 Squash & stretch en Slime (tween de escala)
- [ ] 🟡 Fade negro en transición entre salas
- [ ] 🟢 Sombra circular bajo jugador y enemigos (`Sprite2D` semitransparente)
- [ ] 🟢 Corazones animados en el HUD

---

## Backlog — ideas para versiones futuras

- [ ] Segundo tipo de arma (arco con flechas)
- [ ] Sistema de llaves y puertas cerradas
- [ ] Minimapa
- [ ] Diálogos con NPC usando `RichTextLabel`
- [ ] Boss con múltiples fases
- [ ] Sistema de guardado completo
- [ ] Mobile build con controles táctiles
