# File: PlayerTuning.gd
# Description: Single home for every movement/combat feel constant of top-down Joe (walk, nudge, sword, spin, shield, lift/throw, hurt).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 2.1.0
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

# --- Ledge hop (walk south into a ledge to jump down it) -------------------------------------------
const LEDGE_PROBE := 4.0              # px below the feet where a ledge cell is looked for
const HOP_MAX_SIDEWAYS := 0.3         # the stick must point (almost) straight down to hop
const HOP_TIME := 0.35
const HOP_HEIGHT := 10.0              # arc of the sprite during the hop (px)
const HOP_LAND_INSET := 12.0          # feet land this far into the first cell past the ledge
const HOP_MAX_CELLS := 6              # safety cap on how many ledge cells a hop may cross

# --- Spin attack (hold the sword button after a slash, release when the blade glints) -----------
const CHARGE_TIME := 0.8              # seconds of holding before the spin is ready
const CHARGE_WALK_SPEED := 45.0       # shuffling speed with the sword held out (facing is locked)
const GLINT_EVERY := 0.3              # a charged blade twinkles this often
const SPIN_TIME := 0.34               # 8 frames at 24 fps
const SPIN_DAMAGE := 4                # twice a slash
const SPIN_KNOCKBACK := 180.0
const SPIN_RADIUS := 24.0             # circle around the chest, matched to the drawn trail

# --- Shield (always on Joe's arm, ALttP style: it blocks projectiles hitting his front) ---------
const SHIELD_DOT := 0.6               # cos of the half-angle in front of Joe that the shield covers
const SHIELD_STATES := ["idle", "walk", "charge"]   # busy states (slash, spin, carrying...) leave him open
const SHIELD_FX_OUT := 8.0            # px in front of the chest where the block spark appears

# --- Lift, carry and throw (interact button) -------------------------------------------------------
const LIFT_REACH := 12.0              # px in front of the feet where Joe grabs
const LIFT_GRAB_OFFSET := Vector2(0, 2)   # grab point nudged to the prop's tile centre
const LIFT_RADIUS := 10.0             # how close a prop must be to the grab point
const LIFT_TIME := 0.2
const CARRY_HEIGHT := 26.0            # carried object above the feet (px)
const THROW_TIME := 0.15
const THROW_SPEED := 180.0
const THROW_RANGE := 64.0             # four tiles, like ALttP
const THROW_DAMAGE := 2

# --- Health and being hurt ------------------------------------------------------
const MAX_HP := 6                     # half-heart units: 6 = three hearts, like ALttP's start
const HURT_TIME := 0.2                # control lost after a hit (seconds)
const HURT_KNOCKBACK_SPEED := 160.0   # px/s pushed away from the attacker during HURT_TIME
const IFRAMES := 1.0                  # invincibility (with blinking) after taking a hit
const BLINK_HZ := 15.0                # blink rate while invincible
const HURT_SHAKE := Vector2(2.0, 0.2) # (pixels, seconds) of camera shake when Joe is hit
const HEART_HEAL := 2                 # a recovery heart restores one full heart
