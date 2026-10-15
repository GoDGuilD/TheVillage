<!--
File: LORE.md
Description: The original narrative concept for The Village, recovered from 2024 UVM coursework; now the canon source for the trilogy's story.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-09-07
Last edit date: 2026-10-15
Version: 1.1.0
-->

# Lore — The Village (original concept)

> **Status: active canon (since the 2026-10-15 rebuild).** The game is now the
> first chapter of The Village trilogy; its story draft in `GDD.md` §2 is built
> on this concept (Joe, Caver, Tato, Boni, Janga, El Pueblo and the four
> dimensions, which become the Dark World's regions). Game 2, *Chapel of
> Dreams*, uses the same canon. The control scheme and tech-stack sections
> below are historical (2024 UE5 prototype).
>
> Recovered from school coursework at UVM: narrative design (Feb 2024),
> character design (Jun 2024), scene/level design (Aug 2024), and the
> "Motor de Videojuegos" course's Unreal Engine 5 prototype (Nov–Dec 2024).
> Full source timeline: `technical_memory/technical_memory.ipynb`.

---

## Premise

Joe, an ancient villager, returns to free his home from a curse cast by its
ruler — who has become a powerful vampire. The village itself — called "El
Pueblo" ("The Village"/"The Town") in the original Spanish materials — is
the central hub; the surrounding land is fractured into four distinct
dimensions the player travels between via ritual portals / teleport
crystals.

Original genre framing: suspense / mystery / psychological horror, with
references to *Resident Evil*, *Silent Hill*, and *The Last of Us*.

---

## Cast

### Joe — protagonist ("The Hero" archetype)

| Field | Value |
|---|---|
| Age | 35 |
| Height | 1.85 m |
| Build | Athletic |
| Hair | Dark brown |
| Eyes | Green |
| Background | Orphan, raised in the village; scarred veteran |
| Iconic item | Family-emblem pendant |
| Weapons | Sword, shield, boomerang, staff, bow, explosives |

### Caver — antagonist

Vampire and sorcerer. Commands creatures of darkness and wields elemental
magic. The curse over the village and its ruler's transformation are his
doing.

### Allies

- **Tato** — a wise old man; provides guidance.
- **Boni** — a young woman; provides items and emotional support.
- **Janga** — Joe's best friend; comes and goes from the village, bringing
  weapons and artifacts.

---

## World structure

- **El Pueblo** ("The Village"/"The Town") — the central hub village.
- **Umbra** — darkness, dense forest.
- **Ignis** — fire, volcanoes.
- **Tempus** — a distorted-time ancient city.
- **Silva** — nature, jungle.

Earlier moodboards (Aug 2024, before the dimension names were finalized)
used working titles that map roughly onto the four above: *bosque*
(forest), *ciudad perdida* (lost city), *cumbres heladas* (frozen peaks),
*desierto oscuro* (dark desert) — kept here for traceability, not as a
second canon.

---

## Mechanics (original vision)

- Dialogue choices with consequences that affect the ending.
- Leveling and gear progression.
- Sound and lighting cues used deliberately for tension (per the
  horror-adjacent genre framing).
- Item/HUD concepts explored in the Aug 2024 coursework: `MagicKey`,
  `MagicOrb`, `MagicTicket`.

### Original control scheme (Unreal Engine 5 prototype)

| Action | Key |
|---|---|
| Move | WASD |
| Interact | E |
| Attack | Left click |
| Use item | Q |
| Inventory | I |

---

## Original tech stack (2024 Unreal Engine 5 prototype)

| Tool | Role |
|---|---|
| Unreal Engine 5 | Game engine |
| C++ / Blueprints | Scripting |
| Adobe Animate | Character animation |
| Blender | 3D modeling |
| Audacity | Audio editing |

The Nov–Dec 2024 prototype (course: Motor de Videojuegos) implemented, in
UE5: a third-person Spring-Arm camera, Blueprint-driven player movement, a
Behavior-Tree/Blackboard patrolling enemy AI, Niagara particle FX, a
save/load system via Blueprint structs, a main menu (UMG), and sound
integration (SFX + ambient loop) — tested on Windows.

---

## Production plan (original)

Four phases: preproduction → production → testing → launch/marketing,
including an orchestral score and dubbed key-scene dialogue.

---

## Recovered reference assets

- Character art: `assets/reference/joe/` (character sheet PDF + 8-frame
  pixel sprite).
- Branding art: `assets/branding/` (icon, splash — from the UE5 prototype).
- Level/item concept art (map, moodboards, HUD/item icons) was **not**
  copied into this repo — it's stylistically tied to the horror/gothic UE5
  vision rather than the current lighter prototype. It remains at
  `H:\OneDrive\Office\School\UVM\Diseño de Escena y Componentes\` if needed
  later.
