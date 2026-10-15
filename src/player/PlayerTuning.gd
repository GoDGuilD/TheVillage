# File: PlayerTuning.gd
# Description: Single home for every movement/combat feel constant of top-down Joe (walk speed, corner nudge, sword, hurt).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name PlayerTuning
extends RefCounted

# --- Walking (A Link to the Past has no acceleration: full speed on the first frame) -----------
const WALK_SPEED := 90.0              # px/s in any of the 8 directions (diagonals are normalised)

# --- Corner nudge: walking into the edge of an obstacle slides Joe around it --------------------
const CORNER_NUDGE_PX := 6            # how far off-centre (px) a blocked step may be and still slide
const NUDGE_SPEED := 90.0             # sideways slide speed while being nudged

# --- Sword ------------------------------------------------------------------
const SWORD_DAMAGE := 2               # enemy hit points per slash (enemies count in half-heart units too)
const SWORD_KNOCKBACK := 140.0        # push given to whatever the slash hits
const ATTACK_BUFFER := 0.12           # an attack pressed this close to the end of a slash chains into the next
# Slash hit area per facing: centre offset from Joe's feet and size, matched to the drawn arc.
const SWORD_BOX_FRONT := 9.0          # px from the body centre to the box centre, toward the facing
const SWORD_BOX_DEPTH := 18.0         # box size along the facing
const SWORD_BOX_WIDTH := 30.0         # box size across the facing
const BODY_CENTER := Vector2(0, -9)   # Joe's chest relative to his feet (the node origin)

# --- Health and being hurt ------------------------------------------------------
const MAX_HP := 6                     # half-heart units: 6 = three hearts, like ALttP's start
const HURT_TIME := 0.2                # control lost after a hit (seconds)
const HURT_KNOCKBACK_SPEED := 160.0   # px/s pushed away from the attacker during HURT_TIME
const IFRAMES := 1.0                  # invincibility (with blinking) after taking a hit
const BLINK_HZ := 15.0                # blink rate while invincible
