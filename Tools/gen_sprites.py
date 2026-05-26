#!/usr/bin/env python3
"""
Genera sprites placeholder SNES-style para The Village.
Uso: python Tools/gen_sprites.py
"""

import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT  = os.path.join(ROOT, "assets", "sprites")

# ─── Helpers ─────────────────────────────────────────────────────────────────

def p(r, g, b): return (r, g, b, 255)
T = (0, 0, 0, 0)

def from_art(rows, pal):
    """Convierte lista de strings + palette dict → Image RGBA."""
    h, w = len(rows), len(rows[0])
    assert all(len(r) == w for r in rows), "Filas desiguales"
    img = Image.new("RGBA", (w, h))
    px  = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            px[x, y] = pal[ch]
    return img

def hstack(*imgs):
    """Une imágenes horizontalmente."""
    total_w = sum(i.width for i in imgs)
    h = imgs[0].height
    out = Image.new("RGBA", (total_w, h))
    x = 0
    for img in imgs:
        out.paste(img, (x, 0))
        x += img.width
    return out

def vstack(*imgs):
    """Une imágenes verticalmente."""
    w = imgs[0].width
    total_h = sum(i.height for i in imgs)
    out = Image.new("RGBA", (w, total_h))
    y = 0
    for img in imgs:
        out.paste(img, (0, y))
        y += img.height
    return out

def save(img, rel_path):
    path = os.path.join(OUT, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  OK  assets/sprites/{rel_path}  ({img.width}x{img.height})")

# ─── Paleta global ───────────────────────────────────────────────────────────

K   = p(16,  16,  40)   # outline negro-azulado

# Slime
sD  = p(32,  104,  40)
sM  = p(72,  160,  72)
sL  = p(120, 200, 104)
sH  = p(184, 232, 168)
sE  = p(24,   32,  80)  # ojo
sW  = p(248, 252, 255)  # brillo ojo

# Hierba
gD  = p(48,  120,  32)
gM  = p(80,  168,  56)
gL  = p(128, 208,  96)
gH  = p(176, 240, 136)

# Tierra
dD  = p(104,  64,  24)
dM  = p(152, 104,  56)
dL  = p(200, 152, 104)

# Árbol / hojas
tD  = p(24,   72,  16)
tM  = p(48,  128,  32)
tL  = p(80,  168,  56)
tH  = p(128, 208,  96)

# Tronco
rkD = p( 88,  48,  16)
rkM = p(136,  88,  48)
rkL = p(176, 128,  80)

# Piedra / muro
stD = p(64,   64,  80)
stM = p(104, 104, 120)
stL = p(152, 152, 168)
stH = p(208, 208, 224)

# Agua
wD  = p(24,   64, 152)
wM  = p(48,  112, 200)
wL  = p(96,  160, 232)
wH  = p(184, 216, 248)

# Espada
swD = p(48,   48,  80)   # metal oscuro
swM = p(120, 120, 168)   # metal medio
swL = p(200, 200, 232)   # metal claro
swH = p(252, 252, 255)   # brillo
swG = p(200, 160,  48)   # guardia dorada
swR = p(160,  56,  48)   # mango rojo

# Arbusto
bD  = p(32,   96,  24)
bM  = p(64,  152,  48)
bL  = p(104, 192,  72)
bH  = p(152, 224, 112)

# Flor
fl  = p(240, 216,  48)   # amarilla
fp  = p(200, 120, 192)   # rosa

# ─── SLIME ───────────────────────────────────────────────────────────────────
# Sprite sheet: 4 frames × 16px = 64×16
# Frame 0: idle A   Frame 1: idle B (squished)
# Frame 2: walk A   Frame 3: walk B

SP = {'.':T,'K':K,'1':sD,'2':sM,'3':sL,'4':sH,'e':sE,'w':sW}

# idle A — forma normal
idle_a = from_art([
    "................",
    ".....KKKK.......",
    "....K2222K......",
    "...K222222K.....",
    "...K243342K.....",
    "...K233332K.....",
    "...Kwe22weK.....",
    "...Kee22eeK.....",
    "...K222222K.....",
    "...K112211K.....",
    "....K1111K......",
    ".....KKKK.......",
    "................",
    "................",
    "................",
    "................",
], SP)

# idle B — ligeramente aplastado (squish, efecto de respiración)
idle_b = from_art([
    "................",
    "................",
    "....KKKKKKK.....",
    "...K2222222K....",
    "..K224333422K...",
    "..K2we222we2K...",
    "..K2ee222ee2K...",
    "..K222222222K...",
    "...K1111111K....",
    "....KKKKKKK.....",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
], SP)

# walk A — inclinado izquierda
walk_a = from_art([
    "................",
    "....KKKK........",
    "...K2222K.......",
    "..K222222K......",
    "..K243342K......",
    "..K233332K......",
    "..Kwe22weK......",
    "..Kee22eeK......",
    "..K222222K......",
    "..K112211K......",
    "...K1111K.......",
    "....KKKK........",
    "................",
    "................",
    "................",
    "................",
], SP)

# walk B — inclinado derecha
walk_b = from_art([
    "................",
    "........KKKK....",
    ".......K2222K...",
    "......K222222K..",
    "......K243342K..",
    "......K233332K..",
    "......Kwe22weK..",
    "......Kee22eeK..",
    "......K222222K..",
    "......K112211K..",
    ".......K1111K...",
    "........KKKK....",
    "................",
    "................",
    "................",
    "................",
], SP)

slime_sheet = hstack(idle_a, idle_b, walk_a, walk_b)
save(slime_sheet, "enemies/slime.png")

# ─── ESPADA ──────────────────────────────────────────────────────────────────
# 16×16 — item en el suelo / sprite de ataque

EWP = {'.':T,'K':K,'D':swD,'M':swM,'L':swL,'H':swH,'G':swG,'R':swR}

sword = from_art([
    "........KK......",
    ".......KHHK.....",
    "......KLHHK.....",
    ".....KLLMK......",
    "....KLLMK.......",
    "...KLLMK........",
    "..KLLMK.........",
    "..KMMK..........",
    "..KGGK..........",
    "..KGGK..........",
    "..KRRK..........",
    "..KRRK..........",
    "...KRK..........",
    "....K...........",
    "................",
    "................",
], EWP)

save(sword, "player/sword.png")

# ─── ARBUSTO ─────────────────────────────────────────────────────────────────
# 16×16 — decoración del mapa

BP = {'.':T,'K':K,'1':bD,'2':bM,'3':bL,'4':bH,'g':gM,'G':gL}

bush = from_art([
    "................",
    "....KKKKKK......",
    "...K333333K.....",
    "..K33444433K....",
    "..K34444443K....",
    ".K3K34444K3K....",
    ".K2K23343K2K....",
    "KK222233322KK...",
    "K122222222221K..",
    "K122222222221K..",
    "K112222222211K..",
    ".KK1111111KK....",
    "..KK111111KK....",
    "...gKKKKKKg.....",
    "..ggggggggg.....",
    "................",
], BP)

save(bush, "world/bush.png")

# ─── TILESET BOSQUE ──────────────────────────────────────────────────────────
# 128×48 — 4 columnas × 3 filas de tiles 16×16
# Fila 0: hierba | hierba+flor | tierra | piedra
# Fila 1: árbol-copa | árbol-tronco | agua | muro
# Fila 2: hierba-borde N | hierba-borde E | borde esquina | sombra

TP = {
    '.': T,
    'K': K,
    'D': gD, 'M': gM, 'L': gL, 'H': gH,
    'd': dD, 'm': dM, 'l': dL,
    'T': tD, 'U': tM, 'V': tL, 'W': tH,
    'r': rkD,'s': rkM,'t': rkL,
    'A': stD,'B': stM,'C': stL,'E': stH,
    'a': wD, 'b': wM, 'c': wL, 'e': wH,
    'f': fl, 'p': fp,
}

def tile(rows): return from_art(rows, TP)

# T00 — Hierba base
t00 = tile([
    "DDMMLLMMDDMMLLMD",
    "MDDMMLLMMDDMMLLD",
    "MMMDDMMLLMMDDMML",
    "LLMMMDDMMLLMMDDM",
    "MLLMMMDDMMLLMMDD",
    "MMLLMMMDDMMLLMMD",
    "DMMLLMMMDDMMLLMM",
    "DDMMLLMMMDDMMLLM",
    "MDDMMLLMMMDDMMLL",
    "LMDDMMLLMMMDDMML",
    "LLMDDMMLLMMMDDMM",
    "MLLMDDMMLLMMMDDM",
    "MMLLMDDMMLLMMMDD",
    "DMMLLMDDMMLLMMMD",
    "DDMMLLMDDMMLLMMM",
    "MDDMMLLMDDMMLLMM",
])

# T01 — Hierba con flor
t01 = tile([
    "DDMMLLMMDDMMLLMD",
    "MDDMMLLMMfDMMLLD",
    "MMMDDMMLfMMDDMML",
    "LLMMMDDMMpLLMMDD",
    "MLLMMMDpMMpLLMMD",
    "MMLLpMMDpMLLLMMD",
    "DMMpLfMMDMMpLLMM",
    "DDMMfLMMMDpMMpLM",
    "MDDMMpLMMMpDMMLL",
    "LMDDMMpLMMfDpMML",
    "LLMDDMMfLMMfDDMM",
    "MLLMDDMMLpMMDDMM",
    "MMLLMDDMMLfMMDDM",
    "DMMpLMDDMMpLMMDD",
    "DDMMpLMDDMMpLMMM",
    "MDDMMLfMDDMMpLMM",
])

# T02 — Tierra / camino
t02 = tile([
    "mmdllddmmddllddm",
    "mdllddmmdmllddmm",
    "dllddmmddllddmmd",
    "lddmmdlddmmdlddm",
    "ddmmdlddmmdlddmm",
    "dmmddlddmmdlddmm",
    "mmddlddmmdlddmmm",
    "mddlddmmddlddmmm",
    "ddlddmmddlddmmmm",
    "dlddmmdlddmmmddl",
    "lddmmdlddmmmddll",
    "ddmmdlddmmddlldd",
    "dmmddlddmmdllddd",
    "mmddlddmmdlldddm",
    "mddlddmmdllddmmm",
    "ddlddmmdllddmmmm",
])

# T03 — Piedra / suelo interior
t03 = tile([
    "AABBCCBBAAABBCCB",
    "ABBCCBBAAABBCCBB",
    "BBCCBBAAABBCCBBA",
    "BCCBBAAABBCCBBAA",
    "CCBBAAABBCCBBAAB",
    "ABBBBAAABBBBAABC",
    "BBBBAABBBBBBAABB",
    "BBBAABBBBBBBAABB",
    "BBAABBBBBBBBAABB",
    "BAABBBBBBBBBAABB",
    "AABBBBBBBBBBAABC",
    "CCBBAAABBCCBBAAB",
    "BCCBBAAABBCCBBAA",
    "BBCCBBAAABBCCBBA",
    "ABBCCBBAAABBCCBB",
    "AABBCCBBAAABBCCB",
])

# T10 — Copa de árbol
t10 = tile([
    "....TTTTTTT.....",
    "...TUUUUUUUT....",
    "..TUUVWWVUUT....",
    ".TUUVWWWWVUUT...",
    "TUUVWWWWWWVUUT..",
    "TUUVWWWWWWVUUT..",
    "TUUVWWWWWWVUUT..",
    ".TUUVWWWWVUUT...",
    "..TUUVWWVUUT....",
    "...TUUUUUUT.....",
    "....KKKKKK......",
    "....TTTTTT......",
    ".....ssss.......",
    ".....rssr.......",
    ".....rssr.......",
    ".....KKKK.......",
])

# T11 — Tronco de árbol
t11 = tile([
    ".....KKKK.......",
    ".....rssr.......",
    "....rstsrK......",
    "....rstsrK......",
    "....rstsrK......",
    "....rstsrK......",
    "....rstsrK......",
    "....rstsrK......",
    "....rstsrK......",
    "....rstsrK......",
    "....rssrKK......",
    "....rssrKK......",
    "...KrsssrK......",
    "...KrssrsrK.....",
    "..KKKrrrKKK.....",
    "MMDDMMMMMMDDDMMM",
])

# T12 — Agua (animada, solo frame 0 aquí)
t12 = tile([
    "aaaabbbbaaaabbbb",
    "aabbbbaaaabbbbaa",
    "abbbcccbbbcccbba",
    "bbccccccccccccbb",
    "bcccceeecccceebb",
    "cccceeeecccccebb",
    "cccceeeeeccceeeb",
    "bccceeeeeccceebb",
    "bbcccceeecccccbb",
    "abbbccccccccbbba",
    "aabbbcccbbbcccbb",
    "aaabbbbbbbbbbbba",
    "aaaabbbbaaaabbbb",
    "aabbbbaaaabbbbaa",
    "abbbcccbbbcccbba",
    "bbccccccccccccbb",
])

# T13 — Muro de piedra
t13 = tile([
    "AABBCCBBAAABBCCB",
    "KKKKKKKKKKKKKKKK",
    "CBBAABBCCBBAAABB",
    "CBBAABBCCBBAAABB",
    "CBBAABBCCBBAAABB",
    "KKKKKKKKKKKKKKKK",
    "BBAAABBCCBBAAABB",
    "BBAAABBCCBBAAABB",
    "BBAAABBCCBBAAABB",
    "KKKKKKKKKKKKKKKK",
    "AABBCCBBAAABBCCB",
    "AABBCCBBAAABBCCB",
    "AABBCCBBAAABBCCB",
    "KKKKKKKKKKKKKKKK",
    "CCBBAAABBCCBBAAB",
    "AABBCCBBAAABBCCB",
])

# T20 — Borde Norte (hierba→tierra)
t20 = tile([
    "DDMMLLMMDDMMLLMD",
    "MDDMMLLMMDDMMLLD",
    "MMMDDMMLLMMDDMML",
    "LLMMMDDMMLLMMDDM",
    "KKKKKKKKKKKKKKKK",
    "mddllddmmdlldddm",
    "ddlldddmmdlldddm",
    "mddllddmmdlldddm",
    "lddmmddmmdllddmm",
    "mddllddmmdlldddm",
    "ddlldddmmdlldddm",
    "mddllddmmdlldddm",
    "lddmmddmmdllddmm",
    "mddllddmmdlldddm",
    "ddlldddmmdlldddm",
    "mddllddmmdlldddm",
])

# T21 — Borde Este (hierba→exterior)
t21 = tile([
    "DDMMLLMMDDMMKMMM",
    "MDDMMLLMMDDMKLLL",
    "MMMDDMMLLMMKLLMM",
    "LLMMMDDMMLLKMMDD",
    "MLLMMMDDMMKDMMLL",
    "MMLLMMMDDMKMMLLM",
    "DMMLLMMMDDKMLLMM",
    "DDMMLLMMMKDMMLLM",
    "MDDMMLLMMKMMMLLM",
    "LMDDMMLLKMMMLLMM",
    "LLMDDMMKLLMMMDDM",
    "MLLMDDMKLLMMMDDM",
    "MMLLMDMKLLMMMDDM",
    "DMMpLmKllmddmmmd",
    "DDMMpKmddmmllmmm",
    "MDDMKLmddmmllmmm",
])

# T22 — Sombra/variante oscura hierba
t22 = tile([
    "DDMMDDMMDDMMDDMM",
    "MDDMMDDMMDDMMDDM",
    "MMDDMMDDMMDDMMDD",
    "DMMDDMMDDMMDDMMD",
    "DDMMDDMMDDMMDDMM",
    "MDDMMDDMMDDMMDDM",
    "MMDDMMDDMMDDMMDD",
    "DMMDDMMDDMMDDMMD",
    "DDMMDDMMDDMMDDMM",
    "MDDMMDDMMDDMMDDM",
    "MMDDMMDDMMDDMMDD",
    "DMMDDMMDDMMDDMMD",
    "DDMMDDMMDDMMDDMM",
    "MDDMMDDMMDDMMDDM",
    "MMDDMMDDMMDDMMDD",
    "DMMDDMMDDMMDDMMD",
])

# T23 — Hierba oscura con musgo
t23 = tile([
    "DTDMTLMMDDMMTLMD",
    "MDDMMTLMMDDMMTLD",
    "MMTDDMMTLMMDDMML",
    "LLMMMDTMMLLMMDDT",
    "MLLMMMDTMMLLMMDD",
    "MMLLMMMDDMMTLMMD",
    "DMMLLMMMTDMMLLMM",
    "DDMMLLMMMTDMMLLM",
    "MDDMMLLMMMTDMMLL",
    "LMDDMMTLMMMDDMML",
    "LLMDDMMTLMMTDDMM",
    "MLLMDDMMLDMMMDDM",
    "MMLLMDDMMLLMMMDD",
    "DMMLLMDDMMTLMMMD",
    "DDMMLLMDDMMTLMMM",
    "MDDMMLLMDDMMTLMM",
])

# ─── Ensamblaje del tileset ───────────────────────────────────────────────────

row0 = hstack(t00, t01, t02, t03)
row1 = hstack(t10, t11, t12, t13)
row2 = hstack(t20, t21, t22, t23)

tileset = vstack(row0, row1, row2)
save(tileset, "world/tileset_forest.png")

print()
print("Sprites generados. Importa en Godot:")
print("  - enemies/slime.png         AnimatedSprite2D del Slime")
print("    Frame size: 16x16, 4 frames: idle(0-1) walk(2-3)")
print("  - player/sword.png          AnimatedSprite2D del ataque")
print("  - world/bush.png            Decoracion / Sprite2D")
print("  - world/tileset_forest.png  TileMapLayer, tile size 16x16")
