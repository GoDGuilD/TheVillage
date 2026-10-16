# File: palette.py
# Description: Master colour palette for every generated sprite and tile of The Village (Light World + Dark World); no colour literals elsewhere.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.5.0
#
# The look follows A Link to the Past: bright, saturated Light World greens and earth tones with a
# dark outline on characters, and a Dark World that re-uses the same shapes in sick purples/olives.
# Joe keeps the costume colours from Chapel of Dreams (teal coat, red scarf, gold pendant) so the
# trilogy reads as one character.


def _hex(h):
    """Convert '#rrggbb' to an opaque RGBA tuple."""
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


# Transparent pixel (the canvas background for every sprite).
CLEAR = (0, 0, 0, 0)

# --- Shared neutrals -------------------------------------------------------
OUTLINE = _hex("#181020")      # near-black used for all character outlines
INK     = _hex("#080610")      # deepest shadow
SHADOW  = (16, 12, 24, 96)     # soft drop shadow under actors (semi-transparent)
WHITE   = _hex("#ffffff")

# --- Skin ------------------------------------------------------------------
SKIN_LIGHT = _hex("#f8c8a0")
SKIN_MID   = _hex("#d89870")
SKIN_DARK  = _hex("#a06048")

# --- Hair (dark brown, per lore) ------------------------------------------
HAIR_DARK  = _hex("#301c14")
HAIR_MID   = _hex("#4c3020")
HAIR_LIGHT = _hex("#70482c")

# --- Joe's clothing (shared with Chapel of Dreams) -------------------------
COAT_DARK  = _hex("#1c3c3c")
COAT_MID   = _hex("#2c6058")
COAT_LIGHT = _hex("#48927c")
PANTS_DARK = _hex("#28243c")
PANTS_MID  = _hex("#3e3a5a")
BOOT_DARK  = _hex("#1c1620")
BOOT_MID   = _hex("#4a3428")
SCARF_RED  = _hex("#c83040")
SCARF_DARK = _hex("#801c2c")
GOLD       = _hex("#f0c040")
GOLD_DARK  = _hex("#a87818")
EYE_GREEN  = _hex("#40d080")

# --- Steel / sword --------------------------------------------------------
STEEL_DARK  = _hex("#6878a0")
STEEL_MID   = _hex("#a8b8d8")
STEEL_LIGHT = _hex("#e8f0ff")
HILT_DARK   = _hex("#5a3020")
SLASH_A     = _hex("#ffffff")  # sword-arc core
SLASH_B     = _hex("#a8d0ff")  # sword-arc fade
SPIN_A      = _hex("#fff4a0")  # spin-attack arc core (warmer than a slash)
SPIN_B      = _hex("#f0b040")  # spin-attack arc fade

# --- Shield (the family shield: deep blue face, steel rim, gold emblem) ----
SHIELD_FACE = _hex("#3050a8")
SHIELD_DARK = _hex("#203470")
SHIELD_RIM  = _hex("#c0c8e0")

# --- Light World ground -----------------------------------------------------
GRASS_DARK   = _hex("#287838")
GRASS_MID    = _hex("#48a048")
GRASS_LIGHT  = _hex("#70c058")
GRASS_HILITE = _hex("#a0e070")
DIRT_DARK    = _hex("#9c6c38")
DIRT_MID     = _hex("#c89858")
DIRT_LIGHT   = _hex("#e8c088")
FLOWER_RED   = _hex("#f05050")
FLOWER_YEL   = _hex("#f8e050")
FLOWER_WHITE = _hex("#f8f8f0")

# --- Light World trees, bushes, rocks --------------------------------------
LEAF_DARK   = _hex("#184828")
LEAF_MID    = _hex("#287838")
LEAF_LIGHT  = _hex("#48a850")
LEAF_HILITE = _hex("#88d070")
BARK_DARK   = _hex("#3c2418")
BARK_MID    = _hex("#6c4428")
BARK_LIGHT  = _hex("#946038")
BUSH_DARK   = _hex("#1c5c2c")
BUSH_MID    = _hex("#38904c")
BUSH_LIGHT  = _hex("#68c068")
ROCK_DARK   = _hex("#585868")
ROCK_MID    = _hex("#8888a0")
ROCK_LIGHT  = _hex("#c0c0d0")

# --- Water -------------------------------------------------------------------
WATER_DARK  = _hex("#2850a8")
WATER_MID   = _hex("#3878d0")
WATER_LIGHT = _hex("#70a8f0")
WATER_FOAM  = _hex("#d0e8ff")

# --- Village buildings and terrain -------------------------------------------
ROOF_RED_DARK   = _hex("#7c2420")
ROOF_RED_MID    = _hex("#b83c2c")
ROOF_RED_LIGHT  = _hex("#e0704c")
ROOF_BLUE_DARK  = _hex("#203c74")
ROOF_BLUE_MID   = _hex("#3864a8")
ROOF_BLUE_LIGHT = _hex("#6c98d8")
WALL_DARK       = _hex("#a08868")    # plaster walls
WALL_MID        = _hex("#d8c8a0")
WALL_LIGHT      = _hex("#f4ecd0")
GLASS_DARK      = _hex("#28406c")
GLASS_LIGHT     = _hex("#88b8e8")
CLIFF_DARK      = _hex("#5c3c28")    # earthen cliff faces and ledge lips
CLIFF_MID       = _hex("#8c5c38")
CLIFF_LIGHT     = _hex("#b88450")

# --- Interiors ------------------------------------------------------------------
FLOOR_DARK  = _hex("#7c5430")        # wooden floor planks
FLOOR_MID   = _hex("#a87444")
FLOOR_LIGHT = _hex("#c89460")
INWALL_DARK = _hex("#3c2c38")        # interior wall tops (seen from above)
INWALL_MID  = _hex("#c8b498")        # interior wall face
INWALL_LIGHT = _hex("#e8d8bc")
MAT_RED     = _hex("#a82c3c")
MAT_LIGHT   = _hex("#e0606c")
BED_BLUE    = _hex("#3c5ca8")
BED_LIGHT   = _hex("#8cacf0")
LINEN       = _hex("#f0ece0")

# --- Enemies ------------------------------------------------------------------
SLIME_DARK   = _hex("#1c4c78")   # jelly slime (blue gel)
SLIME_MID    = _hex("#3c88c8")
SLIME_LIGHT  = _hex("#88c8f0")
CAVER_DARK   = _hex("#4c1028")   # Caver's colours on his cursed guards' tabards
CAVER_RED    = _hex("#901c44")
CAVER_LIGHT  = _hex("#c8406c")
SPIT_DARK    = _hex("#a03420")   # rock-spitter shell (octorok-like)
SPIT_MID     = _hex("#e06838")
SPIT_LIGHT   = _hex("#f8a868")

# --- Props, pickups, effects -------------------------------------------------
POT_DARK     = _hex("#6c3c24")
POT_MID      = _hex("#b0683c")
POT_LIGHT    = _hex("#e09c68")
HEART_RED    = _hex("#e82840")
HEART_LIGHT  = _hex("#ff98a0")
GEM_G_DARK   = _hex("#1c7028")   # gems are the money (green 1, blue 5, red 20)
GEM_G_MID    = _hex("#40c050")
GEM_G_LIGHT  = _hex("#b0f8a0")
GEM_B_DARK   = _hex("#1c3c98")
GEM_B_MID    = _hex("#4878e8")
GEM_B_LIGHT  = _hex("#b8d0ff")
GEM_R_DARK   = _hex("#8c1428")
GEM_R_MID    = _hex("#e83850")
GEM_R_LIGHT  = _hex("#ffb0b8")
SMOKE_LIGHT  = _hex("#f4f4fc")
SMOKE_MID    = _hex("#b8b8cc")
SMOKE_DARK   = _hex("#787890")
SPARK_CORE   = _hex("#fffce0")
SPARK_EDGE   = _hex("#f8d040")

# --- Dark World (the Caver's mirror of the same land) ----------------------
DW_GRASS_DARK  = _hex("#3c3048")
DW_GRASS_MID   = _hex("#5c4c5c")
DW_GRASS_LIGHT = _hex("#807060")
DW_DIRT_DARK   = _hex("#583830")
DW_DIRT_MID    = _hex("#805848")
DW_DIRT_LIGHT  = _hex("#a88068")
DW_LEAF_DARK   = _hex("#281830")
DW_LEAF_MID    = _hex("#483058")
DW_LEAF_LIGHT  = _hex("#705088")
DW_WATER_DARK  = _hex("#381c48")
DW_WATER_MID   = _hex("#58306c")
DW_SKY_GLOW    = _hex("#c05878")

# --- UI (ALttP-style: deep-blue boxes with a pale double rim, gold highlights) -------
UI_BOX_FILL   = _hex("#101848")    # dialogue / menu box interior
UI_BOX_EDGE   = _hex("#283890")    # inner bevel of the box
UI_RIM_LIGHT  = _hex("#f0f0f8")    # outer rim
UI_RIM_MID    = _hex("#a8b0d0")
UI_RIM_DARK   = _hex("#585c88")
UI_GOLD       = _hex("#f8d040")    # cursor, titles, selected rows
UI_GOLD_DARK  = _hex("#b08820")
UI_TEXT       = _hex("#f8f8f8")
UI_TEXT_DIM   = _hex("#8890b8")
UI_WELL       = _hex("#181828")    # empty meter well
MAGIC_DARK    = _hex("#188030")    # magic meter fill
MAGIC_MID     = _hex("#38c048")
MAGIC_LIGHT   = _hex("#a0f090")
KEY_DARK      = _hex("#a87818")
KEY_MID       = _hex("#e8b830")
KEY_LIGHT     = _hex("#fff0a0")
SEAL_DARK     = _hex("#6c3c9c")    # the three family seals (violet stone in a gold ring)
SEAL_MID      = _hex("#a068d8")
SEAL_LIGHT    = _hex("#e0c0ff")
LOGO_TOP      = _hex("#fff4b0")    # title logo letter gradient
LOGO_MID      = _hex("#f0c040")
LOGO_LOW      = _hex("#c07020")
LOGO_SHADE    = _hex("#5c2810")

# --- Villagers (NPC clothing and hair) -------------------------------------------------
HAIR_WHITE    = _hex("#e8e8f0")    # Tato's hair and beard
HAIR_GREY     = _hex("#a8a8b8")
ROBE_DARK     = _hex("#3c2c5c")    # Tato's elder robe
ROBE_MID      = _hex("#5c4888")
ROBE_LIGHT    = _hex("#8870b8")
APRON_DARK    = _hex("#a89878")    # Boni's shop apron
APRON_MID     = _hex("#e0d4b0")
SHIRT_GREEN_D = _hex("#2c6430")    # Boni's shirt
SHIRT_GREEN_M = _hex("#4c9848")
HAIR_ORANGE_D = _hex("#9c4818")    # Boni's hair
HAIR_ORANGE_M = _hex("#d87830")
VEST_DARK     = _hex("#5c3418")    # Janga's leather vest
VEST_MID      = _hex("#8c5428")
VEST_LIGHT    = _hex("#b87840")
BANDANA_D     = _hex("#1c5c8c")    # Janga's blue bandana
BANDANA_M     = _hex("#3888c8")
DRESS_DARK    = _hex("#8c2c50")    # village woman
DRESS_MID     = _hex("#c84c78")
DRESS_LIGHT   = _hex("#f08cac")
TUNIC_DARK    = _hex("#7c6c20")    # village boy
TUNIC_MID     = _hex("#c0a838")

# --- Items, chests and puzzle props (Phase 5) ------------------------------------------
CHEST_DARK    = _hex("#5c3418")    # chest wood
CHEST_MID     = _hex("#9c5c28")
CHEST_LIGHT   = _hex("#d08840")
CHEST_BAND    = _hex("#c8a030")    # gold bands and lock
CHEST_INSIDE  = _hex("#281408")
BOOM_DARK     = _hex("#1c3c8c")    # the boomerang (blue, red tips)
BOOM_MID      = _hex("#3c70d8")
BOOM_LIGHT    = _hex("#90c0ff")
BOOM_TIP      = _hex("#e04040")
BOW_DARK      = _hex("#6c3c18")
BOW_MID       = _hex("#a86830")
BOW_STRING    = _hex("#e8e0c8")
ARROW_SHAFT   = _hex("#c09060")
ARROW_FLETCH  = _hex("#e85050")
BOMB_DARK     = _hex("#141c38")
BOMB_MID      = _hex("#28386c")
BOMB_LIGHT    = _hex("#7088c8")
FUSE          = _hex("#d0b080")
BOOM_FLASH    = _hex("#ff6040")    # a bomb about to burst flashes this colour
BLAST_CORE    = _hex("#fffce8")    # explosion
BLAST_HOT     = _hex("#f8e050")
BLAST_MID     = _hex("#f08030")
BLAST_DARK    = _hex("#a03020")
LANTERN_BRASS = _hex("#c89838")
LANTERN_DARK  = _hex("#7c5818")
LANTERN_GLASS = _hex("#fff0a0")
FLAME_CORE    = _hex("#fff8c0")
FLAME_MID     = _hex("#f8b030")
FLAME_EDGE    = _hex("#e05018")
STONE_DARK    = _hex("#4c4c5c")    # torch bases, key blocks
STONE_MID     = _hex("#7c7c90")
STONE_LIGHT   = _hex("#b0b0c4")
CRACK         = _hex("#282834")
