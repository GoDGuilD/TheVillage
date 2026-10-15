# File: gen_joe.py
# Description: Generates Joe's top-down sprite strips (idle, walk, slash, hurt, charge, spin, lift, carry, throw; shield on) plus his shadow and an animation manifest.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 2.0.0
#
# Run:  python -I tools/gen_joe.py   (from the project root; writes assets/sprites/joe/ and tmp/joe_preview.png)
#
# Joe is drawn the way A Link to the Past draws Link: a big head, a short body, a 1-px dark outline
# and a separate sword that sweeps a ~150 degree arc in front of him. Every frame is a 48x48 canvas
# with Joe's feet at FEET (24, 34) so the sword has room to swing in any direction; Godot offsets the
# sprite so that point sits on the node origin. The "side" strips face right; Godot mirrors them for left.
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from palette import (BOOT_DARK, BOOT_MID, CLEAR, COAT_DARK, COAT_LIGHT, COAT_MID, EYE_GREEN, GOLD, GOLD_DARK,
                     HAIR_DARK, HAIR_LIGHT, HAIR_MID, HILT_DARK, OUTLINE, PANTS_DARK, PANTS_MID, SCARF_DARK,
                     SCARF_RED, SHADOW, SHIELD_DARK, SHIELD_FACE, SHIELD_RIM, SKIN_DARK, SKIN_LIGHT, SKIN_MID,
                     SLASH_A, SLASH_B, SPIN_A, SPIN_B, STEEL_DARK, STEEL_LIGHT, STEEL_MID)
from sprite_lib import Canvas, pack_strip, upscale
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "joe")
PREVIEW = os.path.join(ROOT, "tmp", "joe_preview.png")

FRAME = 48                 # every frame is FRAME x FRAME pixels
FEET = (24, 34)            # pixel under Joe's feet (the node origin in Godot)
DIRS = ("down", "up", "side")
FACING_ANGLE = {"down": 90.0, "up": 270.0, "side": 0.0}   # screen angles in degrees (y grows downward)

# Sword geometry (pixels from the body centre / from the hand).
HAND_RADIUS = 5            # hand sits this far from the body centre, in the sword's direction
HILT_BACK = 2              # grip pixels behind the hand
BLADE_FROM = 2             # blade starts this far past the hand (crossguard in between)
BLADE_TO = 13              # blade tip distance from the hand
TRAIL_INNER = 11           # slash trail ring, measured from the body centre
TRAIL_OUTER = 17
TRAIL_CORE = (14, 15)      # brightest ring inside the trail

# Attack timeline: (sword angle offset from facing, trail start offset, trail end offset or None, lean px).
# Offsets sweep clockwise on screen; frames 1-3 are the active hit window (see the manifest).
ATTACK_FRAMES = [
    (-100, None, None, 0),
    (-55, -100, -55, 1),
    (-10, -100, -10, 2),
    (35, -45, 35, 2),
    (55, None, None, 1),
]
ATTACK_HIT_WINDOW = [1, 3]

# Walk cycle: (left leg lift, right leg lift, body bob, left arm swing, right arm swing) for down/up.
WALK_VERT = [(0, 0, 0, 0, 0), (2, 0, -1, 1, -1), (1, 0, 0, 1, -1),
             (0, 0, 0, 0, 0), (0, 2, -1, -1, 1), (0, 1, 0, -1, 1)]
# Walk cycle for the side view: (front-leg stride, lift of the passing leg, body bob, arm swing).
WALK_SIDE = [(0, 0, 0, 0), (2, 1, -1, 2), (3, 0, 0, 2), (0, 0, 0, 0), (-2, 1, -1, -2), (-3, 0, 0, -2)]

# Charge shuffle reuses these walk-cycle frames (legs only; the sword is held forward).
CHARGE_WALK_FRAMES = [0, 1, 3, 4]
# Spin attack: 8 frames, the sword advancing 45 degrees per frame (clockwise on screen) with a trail behind it.
SPIN_FRAMES = 8
SPIN_STEP = 45
SPIN_TRAIL = 100
# Frame the spin starts on for each facing (frame i has the sword at i*45 degrees: 0 = right, 90 = down).
SPIN_START = {"right": 0, "down": 2, "left": 4, "up": 6}
LIFT_HEIGHTS = [0.0, 1.0]        # arm height per lift frame (0 = chest, 1 = over the head)
THROW_HEIGHTS = [0.6, 0.0]       # arm height per throw frame

# Animation table written to the manifest: name -> (frames per facing, fps, loop).
ANIMS = {"idle": (2, 2.0, True), "walk": (6, 12.0, True), "attack": (len(ATTACK_FRAMES), 22.0, False),
         "hurt": (1, 1.0, False), "charge": (len(CHARGE_WALK_FRAMES), 8.0, True), "lift": (2, 10.0, False),
         "carry": (1, 1.0, True), "carry_walk": (6, 12.0, True), "throw": (2, 12.0, False)}
SPIN_FPS = 24.0


# --------------------------------------------------------------------------- body parts

def _legs_vertical(c, cx, fy, lift_l, lift_r):
    """Two legs seen from the front/back; a lifted leg is drawn shorter (the foot rises toward the body)."""
    for x0, lift in ((cx - 4, lift_l), (cx + 1, lift_r)):
        c.rect(x0, fy - 6, 3, 4 - lift, PANTS_MID)
        c.rect(x0 + 2, fy - 6, 1, 4 - lift, PANTS_DARK)
        c.rect(x0, fy - 2 - lift, 3, 2, BOOT_MID)
        c.rect(x0, fy - 1 - lift, 3, 1, BOOT_DARK)


def _torso_vertical(c, cx, fy, back):
    """Coat body, belt and scarf for the front (back=False) or back (back=True) view."""
    top = fy - 12
    c.rect(cx - 5, top, 10, 7, COAT_MID)
    c.rect(cx - 6, fy - 6, 12, 2, COAT_MID)            # coat skirt flares over the hips
    c.rect(cx - 5, top, 1, 7, COAT_LIGHT)
    c.rect(cx + 4, top, 1, 7, COAT_DARK)
    c.rect(cx - 6, fy - 5, 12, 1, COAT_DARK)
    c.rect(cx - 5, fy - 8, 10, 1, PANTS_DARK)          # belt
    if not back:
        c.rect(cx - 1, fy - 12, 2, 4, COAT_DARK)        # coat opening down the chest
        c.rect(cx - 1, fy - 8, 2, 1, GOLD)              # buckle
        c.set(cx - 1, fy - 11, GOLD)                    # family pendant
        c.set(cx - 1, fy - 10, GOLD_DARK)
    # Scarf around the neck; from behind its tail hangs down the back.
    c.rect(cx - 5, fy - 13, 10, 2, SCARF_RED)
    c.rect(cx - 5, fy - 12, 10, 1, SCARF_DARK)
    if back:
        c.rect(cx + 1, fy - 12, 2, 4, SCARF_RED)
        c.rect(cx + 2, fy - 9, 1, 1, SCARF_DARK)


def _arm_vertical(c, x, fy, swing):
    """A sleeve with a hand at its end; swing moves the hand up/down by a pixel or two."""
    c.rect(x, fy - 12 + min(swing, 0), 2, 5 + abs(swing), COAT_MID)
    c.rect(x, fy - 12, 1, 2, COAT_LIGHT)
    c.rect(x, fy - 7 + swing, 2, 2, SKIN_MID)
    c.set(x, fy - 7 + swing, SKIN_LIGHT)


def _arm_raised(c, x, fy, height):
    """A sleeve raised beside the head (lifting/carrying); height 0 = hands at the chest, 1 = over the head."""
    top = fy - 13 - height * 9
    c.rect(x, top, 2, fy - 9 - top, COAT_MID)
    c.rect(x, top, 1, fy - 9 - top, COAT_LIGHT)
    c.rect(x, top - 2, 2, 2, SKIN_MID)
    c.set(x, top - 2, SKIN_LIGHT)


def _shield_front(c, cx, fy):
    """Family shield on Joe's left arm, seen from the front (screen right when he faces down)."""
    c.rect(cx + 4, fy - 12, 6, 8, SHIELD_RIM)
    c.rect(cx + 5, fy - 11, 4, 6, SHIELD_FACE)
    c.rect(cx + 5, fy - 6, 4, 1, SHIELD_DARK)
    c.rect(cx + 6, fy - 10, 2, 3, GOLD)
    c.set(cx + 7, fy - 8, GOLD_DARK)


def _shield_back(c, cx, fy):
    """The shield's back (leather straps) on the left arm, seen from behind (screen left)."""
    c.rect(cx - 10, fy - 12, 6, 8, SHIELD_RIM)
    c.rect(cx - 9, fy - 11, 4, 6, SHIELD_DARK)
    c.rect(cx - 9, fy - 9, 4, 1, HILT_DARK)


def _shield_side(c, cx, fy):
    """Shield held out in front while facing right (a narrow slab, emblem edge-on)."""
    c.rect(cx + 4, fy - 13, 3, 9, SHIELD_RIM)
    c.rect(cx + 5, fy - 12, 2, 7, SHIELD_FACE)
    c.set(cx + 6, fy - 9, GOLD)


def _head_vertical(c, cx, fy, back, eyes_closed=False):
    """Big ALttP-style head: hair cap + face (front) or full hair (back)."""
    hy = fy - 18
    c.ellipse(cx - 0.5, hy, 6.2, 5.6, SKIN_LIGHT)
    if back:
        c.ellipse(cx - 0.5, hy, 6.2, 5.6, HAIR_MID)
        c.ellipse(cx - 1.5, hy - 2, 3.0, 2.0, HAIR_LIGHT)
        c.rect(cx - 6, hy + 3, 12, 2, HAIR_DARK)        # nape
        return
    # Hair cap over the top and down both sides, ragged bangs on the forehead.
    for y in range(hy - 6, hy - 1):
        for x in range(cx - 7, cx + 7):
            if ((x - (cx - 0.5)) / 6.2) ** 2 + ((y - hy) / 5.6) ** 2 <= 1.0:
                c.set(x, y, HAIR_MID)
    c.rect(cx - 7, hy - 2, 2, 5, HAIR_MID)
    c.rect(cx + 5, hy - 2, 2, 5, HAIR_MID)
    for x, d in ((cx - 4, 1), (cx - 2, 2), (cx + 1, 1), (cx + 3, 2)):
        c.rect(x, hy - 2, 1, d, HAIR_MID)
    c.ellipse(cx - 2, hy - 4, 2.5, 1.2, HAIR_LIGHT)
    # Face shading and eyes (green, per the lore).
    c.rect(cx - 5, hy + 3, 10, 1, SKIN_MID)
    c.set(cx - 5, hy + 2, SKIN_MID)
    c.set(cx + 4, hy + 2, SKIN_MID)
    for ex in (cx - 3, cx + 2):
        if eyes_closed:
            c.set(ex, hy + 1, OUTLINE)
        else:
            c.set(ex, hy, EYE_GREEN)
            c.set(ex, hy + 1, OUTLINE)
    c.set(cx - 1, hy + 2, SKIN_DARK)                    # nose shadow


def _figure_vertical(c, cx, fy, back, pose):
    """Whole front/back figure. pose: lift_l, lift_r, bob, arm_l, arm_r, eyes_closed, hide_right_arm."""
    fy_b = fy + pose.get("bob", 0)
    raised = pose.get("raised")                       # None, or 0..1 arm height when lifting/carrying
    _legs_vertical(c, cx, fy, pose.get("lift_l", 0), pose.get("lift_r", 0))
    _torso_vertical(c, cx, fy_b, back)
    if raised is None:
        if not pose.get("hide_left_arm"):
            _arm_vertical(c, cx - 7, fy_b, pose.get("arm_l", 0))
        if not pose.get("hide_right_arm"):
            _arm_vertical(c, cx + 5, fy_b, pose.get("arm_r", 0))
    _head_vertical(c, cx, fy_b, back, pose.get("eyes_closed", False))
    if raised is not None:
        _arm_raised(c, cx - 7, fy_b, raised)
        _arm_raised(c, cx + 5, fy_b, raised)
    elif pose.get("shield", True):
        if back:
            _shield_back(c, cx, fy_b)
        else:
            _shield_front(c, cx, fy_b)


def _figure_side(c, cx, fy, pose):
    """Side figure facing right. pose: stride, lift, bob, arm, eyes_closed, hide_arm."""
    s = pose.get("stride", 0)
    lift = pose.get("lift", 0)
    fy_b = fy + pose.get("bob", 0)
    # Back leg first (darker), then the front leg.
    for dx, col, col_d, lft in ((-s, PANTS_DARK, BOOT_DARK, lift if s < 0 else 0),
                                (s, PANTS_MID, BOOT_MID, lift if s > 0 else 0)):
        x0 = cx - 2 + dx
        c.rect(x0, fy - 6, 3, 4 - lft, col)
        c.rect(x0, fy - 2 - lft, 4, 2, col_d)
        c.rect(x0, fy - 1 - lft, 4, 1, BOOT_DARK)
    # Scarf tail streaming behind, coat body.
    c.rect(cx - 7, fy_b - 12, 3, 2, SCARF_RED)
    c.set(cx - 8, fy_b - 11, SCARF_DARK)
    c.rect(cx - 4, fy_b - 12, 8, 7, COAT_MID)
    c.rect(cx - 5, fy_b - 6, 10, 2, COAT_MID)
    c.rect(cx - 4, fy_b - 12, 1, 7, COAT_DARK)
    c.rect(cx - 5, fy_b - 5, 10, 1, COAT_DARK)
    c.rect(cx - 4, fy_b - 8, 8, 1, PANTS_DARK)
    c.set(cx + 2, fy_b - 8, GOLD)
    c.rect(cx - 4, fy_b - 13, 8, 2, SCARF_RED)
    c.rect(cx - 4, fy_b - 12, 8, 1, SCARF_DARK)
    # Head: face on the right, hair over the top and back.
    hy = fy_b - 18
    c.ellipse(cx, hy, 5.6, 5.6, SKIN_LIGHT)
    for y in range(hy - 6, hy + 6):
        for x in range(cx - 6, cx + 7):
            inside = ((x - cx) / 5.6) ** 2 + ((y - hy) / 5.6) ** 2 <= 1.0
            if inside and (y < hy - 1 or x < cx - 1):
                c.set(x, y, HAIR_MID)
    c.rect(cx + 1, hy - 2, 1, 2, HAIR_MID)              # bang over the brow
    c.rect(cx + 3, hy - 2, 2, 1, HAIR_MID)
    c.ellipse(cx - 2, hy - 3, 2.2, 1.4, HAIR_LIGHT)
    c.rect(cx - 6, hy + 2, 3, 3, HAIR_DARK)
    c.set(cx + 6, hy + 1, SKIN_MID)                      # nose
    c.rect(cx, hy + 3, 5, 1, SKIN_MID)
    c.set(cx - 1, hy + 1, SKIN_DARK)                     # ear
    if pose.get("eyes_closed"):
        c.set(cx + 3, hy + 1, OUTLINE)
    else:
        c.set(cx + 3, hy, EYE_GREEN)
        c.set(cx + 3, hy + 1, OUTLINE)
    # Front arm swinging forward/back, or raised over the head when lifting/carrying.
    raised = pose.get("raised")
    if raised is not None:
        top = fy_b - 13 - int(raised * 9)
        c.rect(cx, top, 2, fy_b - 9 - top, COAT_LIGHT)
        c.rect(cx, top - 2, 2, 2, SKIN_MID)
    elif not pose.get("hide_arm"):
        a = pose.get("arm", 0)
        c.rect(cx - 1 + a // 2, fy_b - 12, 2, 5, COAT_LIGHT)
        c.rect(cx - 1 + a, fy_b - 7, 2, 2, SKIN_MID)
    if raised is None and pose.get("shield", True):
        _shield_side(c, cx, fy_b)


def _draw_figure(c, facing, cx, fy, pose):
    if facing == "side":
        _figure_side(c, cx, fy, pose)
    else:
        _figure_vertical(c, cx, fy, facing == "up", pose)


# --------------------------------------------------------------------------- sword

def _polar(origin, angle_deg, r):
    a = math.radians(angle_deg)
    return (origin[0] + math.cos(a) * r, origin[1] + math.sin(a) * r)


def _draw_sword(c, center, angle_deg):
    """Sword held at HAND_RADIUS from the body centre, pointing along angle_deg; draws arm, hilt, guard, blade."""
    shoulder = (center[0], center[1] - 2)
    hand = _polar(center, angle_deg, HAND_RADIUS)
    c.line(shoulder, hand, COAT_MID, thick=2)
    perp = angle_deg + 90.0
    guard = _polar(hand, angle_deg, 1)
    c.line(_polar(guard, perp, -2), _polar(guard, perp, 2), GOLD)
    c.line(_polar(hand, angle_deg, -HILT_BACK), hand, HILT_DARK, thick=2)
    base = _polar(hand, angle_deg, BLADE_FROM)
    tip = _polar(hand, angle_deg, BLADE_TO)
    c.line(base, tip, STEEL_MID, thick=2)
    c.line(_polar(base, perp, -0.5), _polar(tip, perp, -0.5), STEEL_LIGHT)
    c.line(_polar(base, perp, 1), _polar(_polar(hand, angle_deg, BLADE_TO - 2), perp, 1), STEEL_DARK)
    c.set(*_polar(hand, angle_deg, BLADE_TO + 1), STEEL_LIGHT)
    c.rect(round(hand[0]) - 1, round(hand[1]) - 1, 2, 2, SKIN_MID)


def _draw_trail(c, center, a0, a1, core=SLASH_A, fade=SLASH_B):
    """Slash arc between angles a0..a1 (degrees, clockwise), drawn without an outline (white-blue by default)."""
    lo, hi = min(a0, a1), max(a0, a1)
    for y in range(c.h):
        for x in range(c.w):
            dx, dy = x - center[0], y - center[1]
            r = math.hypot(dx, dy)
            if not (TRAIL_INNER <= r <= TRAIL_OUTER):
                continue
            ang = math.degrees(math.atan2(dy, dx))
            # Bring the pixel's angle into the [lo, lo + 360) window before testing.
            while ang < lo:
                ang += 360.0
            while ang >= lo + 360.0:
                ang -= 360.0
            if ang <= hi and c.px[x, y][3] == 0:
                c.set(x, y, core if TRAIL_CORE[0] <= r <= TRAIL_CORE[1] else fade)


# --------------------------------------------------------------------------- frames

def frame_idle(facing, i):
    c = Canvas(FRAME, FRAME)
    pose = {"arm_l": 0, "arm_r": 0}
    if i == 1:
        pose["bob"] = 0
        pose["arm_l"] = pose["arm_r"] = 0
        pose["arm"] = 0
    _draw_figure(c, facing, FEET[0], FEET[1] + (0 if i == 0 else 0), pose)
    if i == 1:
        # Breathing: shift everything above the belt down one pixel.
        shifted = Canvas(FRAME, FRAME)
        top = c.img.crop((0, 0, FRAME, FEET[1] - 7))
        shifted.img.alpha_composite(c.img, (0, 0))
        shifted.img.paste(Image.new("RGBA", (FRAME, FEET[1] - 7), CLEAR), (0, 0))
        shifted.img.alpha_composite(top, (0, 1))
        shifted.px = shifted.img.load()
        c = shifted
    c.outline(OUTLINE)
    return c


def frame_walk(facing, i):
    c = Canvas(FRAME, FRAME)
    if facing == "side":
        stride, lift, bob, arm = WALK_SIDE[i]
        pose = {"stride": stride, "lift": lift, "bob": bob, "arm": arm}
    else:
        lift_l, lift_r, bob, arm_l, arm_r = WALK_VERT[i]
        pose = {"lift_l": lift_l, "lift_r": lift_r, "bob": bob, "arm_l": arm_l, "arm_r": arm_r}
    _draw_figure(c, facing, FEET[0], FEET[1], pose)
    c.outline(OUTLINE)
    return c


def frame_attack(facing, i):
    off, t0, t1, lean = ATTACK_FRAMES[i]
    base = FACING_ANGLE[facing]
    lx = round(math.cos(math.radians(base)) * lean)
    ly = round(math.sin(math.radians(base)) * lean)
    cx, fy = FEET[0] + lx, FEET[1] + ly
    center = (cx, fy - 9)
    sword_angle = base + off
    behind = facing == "up" and math.sin(math.radians(sword_angle)) < 0.2
    c = Canvas(FRAME, FRAME)
    if facing == "side":
        pose = {"hide_arm": True, "stride": 1 if lean else 0}
    else:
        # The sword hand is Joe's right: screen left when he faces down, screen right from behind.
        pose = {"hide_left_arm": facing == "down", "hide_right_arm": facing == "up"}
    if behind:
        _draw_sword(c, center, sword_angle)
        _draw_figure(c, facing, cx, fy, pose)
    else:
        _draw_figure(c, facing, cx, fy, pose)
        _draw_sword(c, center, sword_angle)
    c.outline(OUTLINE)
    if t0 is not None:
        _draw_trail(c, center, base + t0, base + t1)
    return c


def frame_hurt(facing, i):
    c = Canvas(FRAME, FRAME)
    pose = {"arm_l": -2, "arm_r": -2, "arm": -2, "eyes_closed": True, "bob": 1}
    base = FACING_ANGLE[facing]
    # Recoil: pushed one pixel back from the facing direction.
    lx = -round(math.cos(math.radians(base)))
    ly = -round(math.sin(math.radians(base)))
    _draw_figure(c, facing, FEET[0] + lx, FEET[1] + ly, pose)
    c.outline(OUTLINE)
    return c


def frame_charge(facing, i):
    """Holding a charged sword straight ahead while shuffling (legs from the walk cycle)."""
    walk_i = CHARGE_WALK_FRAMES[i]
    if facing == "side":
        stride, lift, bob, _arm = WALK_SIDE[walk_i]
        pose = {"stride": stride, "lift": lift, "bob": bob, "hide_arm": True}
    else:
        lift_l, lift_r, bob, _al, _ar = WALK_VERT[walk_i]
        pose = {"lift_l": lift_l, "lift_r": lift_r, "bob": bob,
                "hide_left_arm": facing == "down", "hide_right_arm": facing == "up"}
    base = FACING_ANGLE[facing]
    center = (FEET[0], FEET[1] - 9)
    c = Canvas(FRAME, FRAME)
    if facing == "up":
        _draw_sword(c, center, base)                 # pointing away from the camera: behind the body
        _draw_figure(c, facing, FEET[0], FEET[1], pose)
    else:
        _draw_figure(c, facing, FEET[0], FEET[1], pose)
        _draw_sword(c, center, base)
    c.outline(OUTLINE)
    return c


def frame_spin(i):
    """One step of the 360 degree spin: sword at i*45 degrees, body facing the nearest cardinal behind it."""
    angle = i * SPIN_STEP
    facing_for = {0: "side", 90: "down", 180: "side", 270: "up"}
    body_angle = (angle // 90) * 90
    facing = facing_for[body_angle]
    center = (FEET[0], FEET[1] - 9)
    body = Canvas(FRAME, FRAME)
    pose = {"hide_arm": True, "hide_left_arm": facing == "down", "hide_right_arm": facing == "up"}
    _draw_figure(body, facing, FEET[0], FEET[1], pose)
    if body_angle == 180:
        body = body.flipped()                        # facing left is the mirrored side view
    c = Canvas(FRAME, FRAME)
    behind = math.sin(math.radians(angle)) < -0.2
    if behind:
        _draw_sword(c, center, angle)
        c.paste(body)
    else:
        c.paste(body)
        _draw_sword(c, center, angle)
    c.outline(OUTLINE)
    _draw_trail(c, center, angle - SPIN_TRAIL, angle, SPIN_A, SPIN_B)
    return c


def frame_lift(facing, i):
    """Lifting an object: hands at the chest, then over the head."""
    c = Canvas(FRAME, FRAME)
    _draw_figure(c, facing, FEET[0], FEET[1], {"raised": LIFT_HEIGHTS[i], "bob": 1 if i == 0 else 0})
    c.outline(OUTLINE)
    return c


def frame_carry(facing, i):
    """Standing with the object held over the head."""
    c = Canvas(FRAME, FRAME)
    _draw_figure(c, facing, FEET[0], FEET[1], {"raised": 1.0})
    c.outline(OUTLINE)
    return c


def frame_carry_walk(facing, i):
    """Walking with the object held over the head."""
    c = Canvas(FRAME, FRAME)
    if facing == "side":
        stride, lift, bob, _arm = WALK_SIDE[i]
        pose = {"stride": stride, "lift": lift, "bob": bob, "raised": 1.0}
    else:
        lift_l, lift_r, bob, _al, _ar = WALK_VERT[i]
        pose = {"lift_l": lift_l, "lift_r": lift_r, "bob": bob, "raised": 1.0}
    _draw_figure(c, facing, FEET[0], FEET[1], pose)
    c.outline(OUTLINE)
    return c


def frame_throw(facing, i):
    """Throwing: arms snap forward (frame 0 still high, frame 1 at the chest), leaning in."""
    base = FACING_ANGLE[facing]
    lx = round(math.cos(math.radians(base)) * (i + 1))
    ly = round(math.sin(math.radians(base)) * (i + 1))
    c = Canvas(FRAME, FRAME)
    _draw_figure(c, facing, FEET[0] + lx, FEET[1] + ly, {"raised": THROW_HEIGHTS[i]})
    c.outline(OUTLINE)
    return c


BUILDERS = {"idle": frame_idle, "walk": frame_walk, "attack": frame_attack, "hurt": frame_hurt,
            "charge": frame_charge, "lift": frame_lift, "carry": frame_carry, "carry_walk": frame_carry_walk,
            "throw": frame_throw}


def make_shadow():
    """Soft oval shadow drawn under Joe (a separate sprite so it never flips or flashes)."""
    c = Canvas(14, 6)
    c.ellipse(6.5, 2.5, 6.5, 2.6, SHADOW)
    return c


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    manifest = {"frame_size": [FRAME, FRAME], "feet": list(FEET), "anims": {}}
    rows = []
    for anim, (count, fps, loop) in ANIMS.items():
        for facing in DIRS:
            frames = [BUILDERS[anim](facing, i) for i in range(count)]
            name = "%s_%s" % (anim, facing)
            pack_strip(frames).save(os.path.join(OUT_DIR, "joe_%s.png" % name))
            entry = {"frames": count, "fps": fps, "loop": loop}
            if anim == "attack":
                entry["hit_window"] = ATTACK_HIT_WINDOW
            manifest["anims"][name] = entry
            rows.append(frames)
    # The spin is one strip shared by every facing; the manifest says where each facing starts.
    spin = [frame_spin(i) for i in range(SPIN_FRAMES)]
    pack_strip(spin).save(os.path.join(OUT_DIR, "joe_spin.png"))
    manifest["anims"]["spin"] = {"frames": SPIN_FRAMES, "fps": SPIN_FPS, "loop": True, "start": SPIN_START}
    rows.append(spin)
    make_shadow().img.save(os.path.join(OUT_DIR, "joe_shadow.png"))
    with open(os.path.join(OUT_DIR, "joe_animations.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    # Contact sheet for eyeballing: one row per animation/facing, scaled 4x.
    width = max(len(r) for r in rows) * FRAME
    sheet = Image.new("RGBA", (width, len(rows) * FRAME), (72, 160, 72, 255))
    for y, r in enumerate(rows):
        for x, fr in enumerate(r):
            sheet.alpha_composite(fr.img, (x * FRAME, y * FRAME))
    upscale(sheet, 4).save(PREVIEW)
    print("Joe: %d strips written to %s" % (len(rows), OUT_DIR))


if __name__ == "__main__":
    main()
