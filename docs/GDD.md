<!--
File: GDD.md
Description: Game design document for The Village - the top-down, A Link to the Past-inspired first game of The Village trilogy.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-21
Version: 2.8.0
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
| Spin attack | hold after a slash: 0.8 s charge at half speed, then a 360 degree spin for 4 damage | `CHARGE_TIME`, `SPIN_*` |
| Shield | always carried; blocks projectiles hitting his front while idle, walking or charging | `SHIELD_*` |
| Lift and throw | interact on a pot or bush; throw 4 tiles for 2 damage; a hit makes him drop it | `LIFT_*`, `THROW_*` |
| Ledges | walking south into a ledge hops down it; ledges cannot be climbed | `HOP_*`, `LEDGE_PROBE` |

**Facing (ALttP rule):** while walking diagonally Joe keeps facing a direction that is still held; a new
direction is taken from the dominant axis (vertical wins a perfect diagonal).

### Controls
| Action | Keyboard | Gamepad (SNES layout) |
|---|---|---|
| Move | WASD / arrows | D-pad / left stick |
| Sword | J / Space | South (A / Cross) — SNES B |
| Interact / lift / talk | E / Enter | East (B / Circle) — SNES A |
| Use item (equipped Y-item) | K | West (X / Square) — SNES Y |
| Dash (with the Dash Boots) | L / Shift | Right stick click |
| Map (dungeon rooms / visited areas) | Tab | North (Y / Triangle) — SNES X |
| Inventory | I | Left shoulder |
| Pause | Esc | Start |

### HUD, menus, dialogue, saves (implemented in Phase 4)
- **HUD** (ALttP layout): magic meter and equipped-item box top-left, gems and small keys beside them (keys hide at
  zero), "- LIFE -" over up to 20 hearts top-right; the area's name appears in a small plate when Joe enters it.
- **Talking and reading**: interact facing a villager or a sign. Text boxes type out with a blip, show the speaker's
  name, and sit at the top of the screen when Joe is in its lower part. The world pauses while they are open.
  Villagers say different things the first time; Boni is talked to across her counter.
- **Villagers**: Tato (Tato's House), Boni (Boni's Shop), Janga (Janga's House), Marta and Pico (El Pueblo).
- **Menus**: title (CONTINUE / NEW GAME / QUIT), pause (CONTINUE / SAVE GAME / SAVE AND QUIT), item menu (Y-items
  grid, equipment, the three family seals), Game Over (CONTINUE / SAVE AND CONTINUE / SAVE AND QUIT).
- **Saves**: one slot; a save remembers the area and where Joe entered it, his hearts, gems, magic, keys, items,
  seals and story flags. Continuing after Game Over puts Joe back at the area's entrance with full hearts.

## 5. Enemies and drops (implemented in Phase 2)

| Enemy | HP | Touch | Behaviour |
|---|---|---|---|
| Slime | 2 (1 slash) | 1 heart | rests, then hops toward Joe within 80 px (randomly otherwise) |
| Caver's guard | 6 (3 slashes) | 1 heart | patrols in straight legs; within 96 px chases along the dominant axis; gives up beyond 160 px |
| Rock-spitter | 2 (1 slash) | 1 heart | wanders, stops, spits a rock straight ahead (1 heart, the shield blocks it) |

Defeated enemies and broken pots roll the drop table: nothing 50%, recovery heart 20%, green gem (1) 22%, blue gem
(5) 6%, red gem (20) 2%. Drops blink and vanish after 10 s. Gems are the money (ALttP's rupees).

## 6. World structure
- **Light World**: El Pueblo (hub village), its valley, forest, lake, hills and Caver's keep. Built from
  screen-sized areas (24x14 tiles) that scroll into each other the ALttP way. **Implemented in Phase 3:**
  El Pueblo (2x2 screens: Joe's, Tato's and Janga's houses, Boni's shop, gardens, crossing roads), North Meadow
  (pond, slimes), West Woods (ledge, guard, spitter), East Lake (shore, spitters), South Road (cliff band crossed by
  a one-way ledge with a ramp back up; boulders close the way south until the power glove). The game starts in
  Joe's house.
- **Dark World**: the same grid, re-skinned with the Dark World palette in `tools/palette.py` and re-populated.
  Umbra, Ignis, Tempus and Silva are its four regions. **Implemented in Phase 8:** the six twins (Hollow Pueblo,
  Withered Meadow, Thorn Woods, Ash Lake, Broken Road, Dead Fields) at the same coordinates as their Light World
  areas; tougher enemies, no villagers but Tato's echo, region signs for the four dimensions. Act 2 opens there.
  The **Moon Mirror** (from Tato's echo) steps Joe into the Light World at the same spot (thrown back if it is
  solid), leaving a shimmer to return through; **dream rifts** in the Light World lead back once Act 1 is over.
  First mirror puzzle: the meadow pond's island (dry in the Dark World) holds a piece of heart.
- **Dungeons**: 3 Light World (family seals) + 4 Dark World (dimension crystals) + Caver's tower.
  **Implemented in Phase 6: the Moss Shrine** (name is a placeholder), in the upper West Woods. Eight rooms:
  entrance -> hub (pits; locked east door, big-key north door) -> west (clear the enemies: map; the shutter opens) ->
  northwest (push the block onto the heavy switch: a small key appears) -> east (through the locked door; compass;
  cross the pit bridge to a switch that opens the north shutter; the big chest) -> northeast (big key) -> back to the
  big chest (Power Glove) -> hub north (big door) -> antechamber (two torches hide 50 gems) -> the boss room.
  Boss: the Grand Slime - 16 HP, hops at Joe, buds off up to three slimes when struck, faster at half health,
  immune to the boomerang. Reward: a heart container, then the first family seal, then Joe is outside again.
  Rules: small keys belong to their dungeon; falling into a pit costs a heart; the map shows every room once found,
  the compass marks the boss.
  **Implemented in Phase 7** (names are placeholders): the **South Fields** past the South Road's heavy rocks;
  **Ram's Hollow** (Dash Boots; boss the Iron Ram - dodge its charge into a wall, hit it while dazed; seal 2);
  **Frost Vault** behind rubble (Fire Rod; boss the Frost Wraith - only fire hurts it; seal 3); **Caver's Keep**
  behind the seal gate (all three seals): Caver's shade throws orbs Joe bats back with the sword; three hits end
  Act 1 (his last words, the end card; the game is saved outside the keep).
  **Implemented in Phase 9 - Umbra** (names are placeholders): the Withered Meadow opens north into the
  **Umbral Vale** (Dark World only - the mirror shows nothing there), whose chasm island holds a piece of heart for
  the grapple. The **Umbra Sanctum** (5 rooms): a dark hall and a dark west room (light is a small circle around
  Joe, wider with the lantern, until the torches burn) hold the map and the small key; the east room has the big
  key and the big chest (the **Grapple**) and a chasm crossed by hook posts to the switch that opens the way to the
  boss. Enemies: **lurkers**, shadows that move only while Joe looks away. Boss: the **Gloom Moth** - out of reach
  in the air, throwing dust; the grapple pulls it down for a few seconds of sword hits. Reward: a heart container,
  then the **Crystal of Umbra** (first of four dimension crystals).

## 7. Items (ALttP equivalents in brackets)

**Implemented in Phase 5:**
| Item | Where | Use |
|---|---|---|
| Lantern | chest in Joe's house | a flame in front (2 of 32 magic); lights torches |
| Boomerang | Janga's gift (second talk) | up to 6 tiles, straight or diagonal; stuns enemies 2 s; fetches pickups |
| Bow (+10 arrows) | chest behind the key block on the South Road | arrows do 4 damage, stick in walls |
| Bombs | Boni's shop, 5 for 20 gems | 1.6 s fuse; blast hurts enemies and Joe, cuts bushes, breaks cracked rocks |
| Small key | chest in East Lake | opens one key block |
| Pieces of heart | meadow torch chest, behind the woods' cracked rock, by East Lake (behind heavy rocks), Boni (100 gems) | four make a heart container |
| Power Glove | the Moss Shrine's big chest | lift and throw heavy rocks |
| Dash Boots | Ram's Hollow's big chest | dash (L / Shift): sword out, breaks rubble, bonks on walls |
| Fire Rod | the Frost Vault's big chest | fireballs for 4 magic; burn ice, light torches from afar |
| Magic jars | drops (8% of the table) | small +4, big +16 magic |
| Moon Mirror | Tato's echo (Hollow Pueblo) | Dark World only: step into the Light World at the same spot |
| Grapple | the Umbra Sanctum's big chest | 7-tile chain over pits and water: bites hook posts and pulls Joe across; stuns enemies |
| Magic refill | the Shade Market, 40 gems | fills the magic meter |

Bags: 10 bombs, 30 arrows. Arrows: Boni, 10 for 15 gems. The Shade Market (Hollow Pueblo): bombs 5 for 30,
arrows 10 for 25, magic refill 40.

**Planned:**
Sword and shield, boomerang, bow, bombs, lantern, hookshot-style grapple, dash boots [Pegasus Boots], power
glove (lift rocks), flippers, Moon Mirror [Magic Mirror], hammer, fire rod and ice rod, bottles. The lore's
original weapons (sword, shield, boomerang, staff, bow, explosives) are all on this list.

## 8. Art direction
- ALttP-style: bright, saturated Light World; desaturated purple/olive Dark World; 1-px dark outline on actors.
- Every sprite and tile is **generated** by Python scripts in `tools/` from the master palette
  (`tools/palette.py`) — change the script and regenerate; never hand-edit generated PNGs.
- Joe keeps his Chapel of Dreams costume (teal coat, red scarf, gold family pendant, green eyes).

## 9. Audio
SNES-style chiptune music (Phase 14) and short, distinct SFX; 15 effects are generated by `tools/gen_sfx.py` (Phase 2). The 2024 audio in `assets/audio/` is **not
cleared to ship** (licences unverified).

## 10. Scope for v1.0
**In:** Light + Dark World overworlds, 8 dungeons, the item list above, hearts and heart pieces, money, shops,
saves, map, NPC dialogue, English + Spanish.
**Out (for now):** multiplayer, mobile controls, voice acting.
