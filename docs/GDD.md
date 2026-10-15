<!--
File: GDD.md
Description: Game design document for The Village - the top-down, A Link to the Past-inspired first game of The Village trilogy.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-15
Version: 2.0.0
-->

# Game Design Document — The Village

Living document. Updated with every design decision. Phases and their status: `ROADMAP.md`.

## 1. Concept

| Field | Value |
|---|---|
| Genre | Top-down 2D action-adventure (overworld + dungeons) |
| Inspiration | *The Legend of Zelda: A Link to the Past* — same mechanics, framing and visual language |
| Trilogy position | **Game 1 (prequel).** Game 2 is *The Village — Chapel of Dreams* (`H:\DEV\TheVillage-ChapelOfDreams`, SotN-style) |
| Engine | Godot 4.7.2, GDScript |
| Render | 384×216 (16:9, same as Chapel of Dreams), integer scale, nearest filter, 16 px tiles |
| Platform | Windows first (Linux/macOS exports later) |

## 2. Story (draft — owner to confirm)

Joe, an orphan raised in El Pueblo and a scarred veteran, comes home after years away. The village's ruler,
**Caver**, has begun a pact with something under the old chapel: he is turning into a vampire-sorcerer, and his
curse has torn the land into a **Light World** (El Pueblo and its valley, still whole) and its **Dark World**
mirror (the same land as Caver dreams it — rotten, inverted, full of his creatures).

- **Act 1 — Light World.** Joe meets Tato (the wise old man), Boni (items, support) and Janga (his best friend,
  who brings weapons). Three Light World dungeons hold the **three family seals** (ALttP's pendants). With them
  Joe claims his family's blade and opens the way to Caver's keep.
- **Act 2 — Dark World.** Caver banishes Joe into the Dark World. Its four regions are the four dimensions of the
  lore — **Umbra** (darkness), **Ignis** (fire), **Tempus** (broken time), **Silva** (wild jungle) — each with a
  dungeon and a boss (ALttP's crystal dungeons, here four plus a final tower). The **Moon Mirror** (ALttP's
  Magic Mirror) takes Joe from the Dark World back to the same spot in the Light World.
- **Ending — the bridge to game 2.** Joe defeats Caver's mortal form at the top of his tower, but Caver does not
  die: he sinks beneath the old chapel, where the curse begins to grow the dream-castle of *Chapel of Dreams*.

## 3. Pillars
1. **Faithful ALttP feel** — instant 8-way movement, the sweeping sword, corner nudging, bushes and pots,
   screen-edge transitions, heart containers, dungeon keys/maps/compasses, item-gated exploration.
2. **Two worlds, one map** — every Dark World screen mirrors a Light World screen; the mirror is a puzzle tool.
3. **Readable combat** — the player always sees why they were hit.
4. **One trilogy** — Joe, the cast, the palette DNA and the four dimensions are shared with Chapel of Dreams.

## 4. Player (implemented in Phase 1)

| Stat | Value | Where |
|---|---|---|
| Walk speed | 90 px/s, no acceleration, diagonals normalised | `PlayerTuning.WALK_SPEED` |
| Health | 3 hearts = 6 half-heart units | `PlayerTuning.MAX_HP` |
| Sword | 2 damage, live on slash frames 1–3, 30×18 px box in front | `PlayerTuning.SWORD_*` |
| Hurt | 0.2 s knockback at 160 px/s, then 1.0 s blinking invincibility | `PlayerTuning.HURT_*`, `IFRAMES` |
| Corner nudge | a blocked straight step within 6 px of an obstacle's corner slides around it | `CORNER_NUDGE_PX` |

**Facing (ALttP rule):** while walking diagonally Joe keeps facing a direction that is still held; a new
direction is taken from the dominant axis (vertical wins a perfect diagonal).

### Controls
| Action | Keyboard | Gamepad (SNES layout) |
|---|---|---|
| Move | WASD / arrows | D-pad / left stick |
| Sword | J / Space | South (A / Cross) — SNES B |
| Interact / lift / talk | E / Enter | East (B / Circle) — SNES A |
| Use item | K | West (X / Square) — SNES Y |
| Dash (Pegasus-style boots, later) | L / Shift | Right stick click |
| Map | Tab | North (Y / Triangle) — SNES X |
| Inventory | I | Left shoulder |
| Pause | Esc | Start |

## 5. World structure
- **Light World**: El Pueblo (hub village), its valley, forest, lake, hills and Caver's keep. Built from
  screen-sized areas that scroll into each other the ALttP way (Phase 3).
- **Dark World**: the same grid, re-skinned with the Dark World palette in `tools/palette.py` and re-populated.
  Umbra, Ignis, Tempus and Silva are its four regions.
- **Dungeons**: 3 Light World (family seals) + 4 Dark World (dimension crystals) + Caver's tower.

## 6. Items (planned; ALttP equivalents in brackets)
Sword and shield, boomerang, bow, bombs, lantern, hookshot-style grapple, dash boots [Pegasus Boots], power
glove (lift rocks), flippers, Moon Mirror [Magic Mirror], hammer, fire rod and ice rod, bottles. The lore's
original weapons (sword, shield, boomerang, staff, bow, explosives) are all on this list.

## 7. Art direction
- ALttP-style: bright, saturated Light World; desaturated purple/olive Dark World; 1-px dark outline on actors.
- Every sprite and tile is **generated** by Python scripts in `tools/` from the master palette
  (`tools/palette.py`) — change the script and regenerate; never hand-edit generated PNGs.
- Joe keeps his Chapel of Dreams costume (teal coat, red scarf, gold family pendant, green eyes).

## 8. Audio
SNES-style chiptune music and short, distinct SFX (Phase 4+). The 2024 audio in `assets/audio/` is **not
cleared to ship** (licences unverified).

## 9. Scope for v1.0
**In:** Light + Dark World overworlds, 8 dungeons, the item list above, hearts and heart pieces, money, shops,
saves, map, NPC dialogue, English + Spanish.
**Out (for now):** multiplayer, mobile controls, voice acting.
