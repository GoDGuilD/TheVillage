# Game Design Document — The Village

Documento vivo. Se actualiza con cada decisión de diseño relevante.

---

## Concepto

| Campo | Valor |
|-------|-------|
| Género | Action-RPG top-down 2D |
| Inspiración | Zelda: A Link to the Past, Hyper Light Drifter |
| Perspectiva | Cenital (top-down) |
| Escala | Prototipo / demo jugable |
| Plataforma objetivo | PC (Windows/Linux/Mac) |
| Engine | Godot 4.6 |

### Premisa
El jugador explora una pequeña aldea y sus alrededores, lucha contra criaturas que la amenazan y busca resolver el misterio detrás de su origen.

---

## Pilares de diseño

1. **Exploración recompensada** — el mapa invita a salirse del camino obvio.
2. **Combate legible** — el jugador siempre sabe por qué murió.
3. **Progresión satisfactoria** — incluso el prototipo debe dar sensación de avance.

---

## Jugador

### Stats base (prototipo)
| Stat | Valor | Notas |
|------|-------|-------|
| Vida máxima | 6 corazones | Representados como medios corazones |
| Velocidad | 80 px/s | Top-down, 8 direcciones |
| Daño espada | 1 corazón | Sin variaciones por ahora |
| Duración ataque | 0.3 s | Tiempo del `AttackTimer` |
| iFrames tras daño | 1.0 s | Tiempo del `InvincibilityTimer` |

### Controles
| Acción | Teclado | Gamepad |
|--------|---------|---------|
| Mover | WASD / Flechas | Stick izquierdo / D-pad |
| Atacar | Espacio | Botón Sur (A / Cruz) |
| *Futuro: interactuar* | E | Botón Este (B / Círculo) |
| *Futuro: inventario* | I / Tab | Botón Oeste (X / Cuadrado) |

### Animaciones requeridas
12 animaciones = 3 estados × 4 direcciones

```
idle_down   walk_down   attack_down
idle_up     walk_up     attack_up
idle_left   walk_left   attack_left
idle_right  walk_right  attack_right
```

---

## Enemigos

### Slime (Fase 0)
| Stat | Valor |
|------|-------|
| Vida | 2 golpes |
| Velocidad | 35 px/s |
| Daño contacto | 1 corazón |
| Radio de detección | 80 px |
| Radio de persecución | 120 px (1.5× detección) |
| Comportamiento idle | Patrulla aleatoria (cambio de dir cada 1.5–3 s) |

### Bat (Fase 6 — planificado)
| Stat | Valor |
|------|-------|
| Vida | 1 golpe |
| Velocidad | 55 px/s |
| Daño contacto | 1 corazón |
| Comportamiento | Movimiento sinusoidal, ignora colisiones con TileMap |

### Arquero (Fase 6 — planificado)
| Stat | Valor |
|------|-------|
| Vida | 3 golpes |
| Daño proyectil | 1 corazón |
| Rango de disparo | 100 px |
| Cooldown disparo | 2 s |

---

## Estructura de salas

```
[Sala 1 — Tutorial implícito]
  • 2–3 Slimes
  • Sin obstáculos complejos
  • Puerta norte → Sala 2

[Sala 2 — Primer desafío]
  • 4–5 Slimes + 1 Bat (fase 6)
  • Obstáculos que requieren rodear
  • Puerta sur → Sala 1
```

### Diseño de salas (principios)
- Cada sala cabe en **una pantalla** (aprox. 320×180 px a escala 1×)
- Los enemigos aparecen en posiciones que enseñan sus mecánicas
- Las salidas son visibles desde el punto de entrada

---

## Economía de items (prototipo)

| Item | Fuente | Efecto |
|------|--------|--------|
| Medio corazón | Drop de Slime (30% probabilidad) | `HealthComponent.heal(1)` |
| *Futuro: llave* | Cofre | Abre puertas cerradas |

---

## Estética

### Paleta de referencia (Zelda: A Link to the Past)
- Tonos cálidos para exteriores (verde, marrón, beige)
- Tonos fríos para interiores (gris piedra, azul oscuro)
- Contraste alto en enemigos para legibilidad

### Tamaño de tile objetivo
**16×16 px** por tile. Escala de renderizado: 2× o 3× para pantallas modernas.  
En Godot: `Window > Stretch Mode = canvas_items`, `Aspect = keep`.

### Audio (referencias de estilo)
- Música: chiptune SNES-style con melodías reconocibles
- SFX: cortos, distintos entre sí, no fatigantes en loop

---

## Métricas de éxito del prototipo

El prototipo se considera completo cuando:

- [ ] Un nuevo jugador puede mover al personaje en menos de 5 segundos
- [ ] Un nuevo jugador entiende cómo atacar sin leer instrucciones
- [ ] Es posible morir y saber por qué
- [ ] Hay al menos 2 salas conectadas
- [ ] El juego no crashea en una sesión de 5 minutos

---

## Fuera de alcance (prototipo)

Los siguientes elementos se excluyen explícitamente para mantener el foco:

- Historia y diálogos
- Sistema de inventario complejo
- Más de 2 tipos de enemigo
- Guardado de progreso entre sesiones
- Efectos de iluminación dinámica
- Multijugador
