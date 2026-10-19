# File: gen_sfx.py
# Description: Synthesises The Village's chiptune sound effects (sword, spin, hits, bush/pot, pickups, shield, ledges, doors, menus, dialogue, saves, game over, items, chests, shop, dungeons, act 1, world warps) as 16-bit mono WAVs and self-checks their levels.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-20
# Version: 3.3.0
#
# Run:  python -I tools/gen_sfx.py   (deterministic; writes assets/audio/sfx/*.wav and tmp/sfx_waveforms.png)
# Synthesis toolbox ported from Chapel of Dreams' gen_audio.py (pulse/triangle/noise oscillators,
# swept band-pass, exponential envelopes, bit-crushing). Sounds aim at the SNES/ALttP palette:
# short, bright, distinct from each other.
import math
import os
import wave

import numpy as np

SEED = 1991                      # fixed seed -> identical output on every run
SR = 44100                       # Hz
FADE_S = 0.004                   # fade in/out applied to every effect (kills clicks)
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
TMP_DIR = os.path.join(ROOT, "tmp")
rng = np.random.default_rng(SEED)


# --------------------------------------------------------------- primitives
def tt(dur):
    """Time axis in seconds."""
    return np.arange(int(round(dur * SR))) / SR


def sweep(f0, f1, dur, curve=1.0):
    """Per-sample frequency gliding exponentially from f0 to f1."""
    n = int(round(dur * SR))
    x = (np.arange(n) / max(1, n - 1)) ** curve
    return f0 * (f1 / f0) ** x


def phase(freq):
    """Integrate a frequency array into a 0..1 phase (click-free sweeps)."""
    return np.cumsum(freq) / SR % 1.0


def pulse(freq, duty=0.5):
    """NES/SNES-style pulse wave."""
    return np.where(phase(freq) < duty, 1.0, -1.0)


def tri(freq, levels=32):
    """Stair-stepped triangle wave."""
    w = 2.0 * np.abs(2.0 * phase(freq) - 1.0) - 1.0
    return np.round(w * (levels / 2)) / (levels / 2)


def noise(n):
    """White noise in -1..1 (seeded)."""
    return rng.uniform(-1.0, 1.0, n)


def decay(n, tau, attack=0.001):
    """Exponential decay with a short linear attack."""
    env = np.exp(-(np.arange(n) / SR) / tau)
    a = max(1, int(attack * SR))
    env[:a] *= np.linspace(0, 1, a)
    return env


def bandpass(x, fc, q=2.0):
    """State-variable band-pass with a per-sample centre frequency."""
    low = band = 0.0
    out = np.empty(len(x))
    inv_q = 1.0 / q
    for i in range(len(x)):
        f = 2.0 * math.sin(math.pi * min(fc[i], SR / 6.0) / SR)
        low += f * band
        high = x[i] - low - inv_q * band
        band += f * high
        out[i] = band
    return out


def lowpass(x, cutoff):
    """One-pole low-pass."""
    a = 1 - math.exp(-2 * math.pi * cutoff / SR)
    out = np.empty(len(x))
    y = 0.0
    for i in range(len(x)):
        y += a * (x[i] - y)
        out[i] = y
    return out


def crush(x, step):
    """Sample-and-hold bit crusher."""
    return x[(np.arange(len(x)) // step) * step]


def fit(n, *arrs):
    """Trim/pad arrays to length n so layers can be summed."""
    return [np.pad(a, (0, max(0, n - len(a))))[:n] for a in arrs]


def finish(x, peak_db):
    """Remove DC, fade the ends, normalise to the requested peak."""
    x = x - x.mean()
    f = int(FADE_S * SR)
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    return x / np.max(np.abs(x)) * 10 ** (peak_db / 20)


def notes(seq, duty=0.25, tau=0.06):
    """Consecutive pulse blips: seq = [(freq, seconds), ...]."""
    parts = []
    for f, d in seq:
        n = int(d * SR)
        parts.append(pulse(np.full(n, f), duty) * decay(n, tau))
    return np.concatenate(parts)


def whoosh(f0, f1, dur, q, body, body_f):
    """Swing whoosh: swept band-passed noise plus a singing pulse sweep."""
    n = int(dur * SR)
    s = bandpass(noise(n), sweep(f0, f1, dur), q)
    s /= np.max(np.abs(s))
    env = np.sin(np.pi * (np.arange(n) / n) ** 0.7) ** 1.5
    return s * env + body * 0.5 * pulse(sweep(body_f[0], body_f[1], dur), 0.25) * env


# ------------------------------------------------------------------- effects
def sword_slash():
    return whoosh(600, 3400, 0.15, 1.8, 0.6, (600, 1300))


def sword_spin():
    # Two overlapping rising whooshes plus a ringing tone: the spin feels bigger than a slash.
    a = whoosh(300, 2600, 0.42, 1.2, 0.9, (300, 1400))
    ring = np.sin(2 * np.pi * phase(sweep(1200, 2400, 0.42))) * decay(int(0.42 * SR), 0.3) * 0.4
    a, ring = fit(len(a), a, ring)
    return a + ring


def charge_ready():
    # Bright "ting" when the spin attack is charged.
    t = tt(0.35)
    n = len(t)
    return (np.sin(2 * np.pi * 2637 * t) + 0.5 * np.sin(2 * np.pi * 3951 * t)) * decay(n, 0.09)


def enemy_hit():
    n = int(0.12 * SR)
    thump = pulse(sweep(320, 90, 0.12), 0.5) * decay(n, 0.035)
    nb = lowpass(noise(n), 5000) * decay(n, 0.02)
    return crush(thump * 0.8 + nb * 0.7, 2)


def enemy_die():
    d = 0.45
    n = int(d * SR)
    base = noise(n)
    out = np.empty(n)
    step_t, i = 1.0, 0
    while i < n:                                   # grit whose hold grows: the crunch pitch falls
        step = int(step_t)
        out[i:i + step] = base[i]
        i += step
        step_t = min(36.0, step_t * 1.05 + 0.2)
    blip = pulse(sweep(1200, 150, d), 0.125) * decay(n, 0.1)
    return out * decay(n, 0.12) * 0.8 + blip * 0.5


def hurt():
    d = 0.24
    n = int(d * SR)
    f = sweep(600, 200, d) * (1 + 0.05 * np.sin(2 * np.pi * 30 * tt(d)))
    return pulse(f, 0.5) * decay(n, 0.12) + 0.4 * crush(noise(n), 3) * decay(n, 0.03)


def player_die():
    d = 1.0
    n = int(d * SR)
    f = sweep(700, 70, d, 0.7)
    return pulse(f, 0.25) * decay(n, 0.45) * 0.7 + tri(f * 0.5) * decay(n, 0.55)


def bush_cut():
    n = int(0.16 * SR)
    rustle = bandpass(noise(n), sweep(3500, 1500, 0.16), 1.5)
    rustle /= np.max(np.abs(rustle))
    return rustle * decay(n, 0.05) + 0.3 * pulse(sweep(500, 250, 0.16), 0.125) * decay(n, 0.04)


def lift():
    n = int(0.12 * SR)
    return tri(sweep(180, 420, 0.12)) * decay(n, 0.08) + 0.3 * lowpass(noise(n), 1200) * decay(n, 0.03)


def throw():
    return whoosh(900, 300, 0.16, 1.4, 0.3, (500, 300))


def shatter():
    n = int(0.3 * SR)
    out = np.zeros(n)
    for k in range(7):                             # several bright shards landing a few ms apart
        start = int(rng.uniform(0, 0.12) * SR)
        m = int(0.06 * SR)
        c = bandpass(noise(m), np.full(m, rng.uniform(2500, 6000)), 5.0) * decay(m, 0.012)
        c /= np.max(np.abs(c)) + 1e-9
        seg = c[:n - start]
        out[start:start + len(seg)] += seg * (1.0 - k * 0.08)
    thud = tri(sweep(150, 60, 0.3)) * decay(n, 0.05)
    return out + thud * 0.8


def pickup_heart():
    return notes([(1046.5, 0.06), (1318.5, 0.06), (1568.0, 0.12)], 0.25, 0.07)


def pickup_gem():
    return notes([(1568.0, 0.05), (2093.0, 0.1)], 0.125, 0.06)


def shield_block():
    t = tt(0.18)
    n = len(t)
    clang = (np.sin(2 * np.pi * 1800 * t) + 0.6 * np.sin(2 * np.pi * 2710 * t)) * decay(n, 0.05)
    return clang + 0.5 * crush(noise(n), 2) * decay(n, 0.01)


def spit():
    n = int(0.12 * SR)
    return pulse(sweep(220, 600, 0.12), 0.25) * decay(n, 0.06) + 0.4 * lowpass(noise(n), 2000) * decay(n, 0.02)


def ledge_hop():
    n = int(0.16 * SR)
    return pulse(sweep(300, 900, 0.16, 0.7), 0.25) * decay(n, 0.1)


def land():
    n = int(0.1 * SR)
    return tri(sweep(140, 50, 0.1)) * decay(n, 0.04) + 0.5 * lowpass(noise(n), 1500) * decay(n, 0.025)


def door():
    # Wooden door: a soft knock followed by a short creak.
    n = int(0.3 * SR)
    knock = tri(sweep(180, 90, 0.3)) * decay(n, 0.03)
    creak = pulse(sweep(140, 210, 0.3), 0.18) * np.sin(np.pi * np.arange(n) / n) ** 2 * 0.4
    return knock + creak


# --- Phase 4: menus, dialogue, saves --------------------------------------------------

def menu_move():
    # A tiny tick for each cursor step.
    return notes([(1760.0, 0.03)], 0.25, 0.02)


def menu_select():
    return notes([(1046.5, 0.04), (1568.0, 0.08)], 0.25, 0.05)


def menu_back():
    return notes([(1174.7, 0.04), (784.0, 0.08)], 0.25, 0.05)


def text_blip():
    # One letter of a dialogue box being typed (played every few letters).
    return notes([(1318.5, 0.025)], 0.5, 0.012)


def pause():
    # Menus open: a short rising pair.
    return notes([(659.3, 0.05), (987.8, 0.05), (1318.5, 0.1)], 0.25, 0.06)


def save_done():
    # Saved: a bright little arpeggio.
    return notes([(784.0, 0.06), (1046.5, 0.06), (1318.5, 0.06), (1568.0, 0.18)], 0.25, 0.08)


def game_over():
    # A slow falling line on a soft triangle.
    seq = [(523.3, 0.22), (493.9, 0.22), (466.2, 0.22), (440.0, 0.6)]
    parts = []
    for f, d in seq:
        n = int(d * SR)
        parts.append(tri(np.full(n, f)) * decay(n, d * 0.8, 0.005))
    return np.concatenate(parts)


# --- Phase 5: items, chests, shop -----------------------------------------------------

def item_get():
    # The "you got it" fanfare: a rising arpeggio that lands on a held chord tone.
    return notes([(523.3, 0.09), (659.3, 0.09), (784.0, 0.09), (1046.5, 0.09), (784.0, 0.09), (1046.5, 0.45)],
                 0.25, 0.18)


def heart_piece():
    return notes([(784.0, 0.07), (987.8, 0.07), (1174.7, 0.07), (1568.0, 0.25)], 0.125, 0.12)


def chest_open():
    # Lid creak up, then a soft thud.
    n = int(0.28 * SR)
    creak = pulse(sweep(160, 420, 0.28), 0.18) * np.sin(np.pi * np.arange(n) / n) ** 2 * 0.5
    thud = tri(sweep(120, 60, 0.28)) * decay(n, 0.04)
    return creak + thud


def boomerang():
    # A short airy whirr (replayed while the boomerang flies).
    n = int(0.18 * SR)
    wob = 0.5 + 0.5 * np.sin(2 * np.pi * 22 * np.arange(n) / SR)
    return bandpass(noise(n), np.full(n, 1400.0), 3.0) * wob * np.sin(np.pi * np.arange(n) / n)


def arrow_shot():
    n = int(0.12 * SR)
    return whoosh(2400, 900, 0.12, 4.0, 0.3, (900, 500)) * decay(n, 0.08)


def arrow_hit():
    n = int(0.08 * SR)
    return tri(sweep(500, 200, 0.08)) * decay(n, 0.03) + 0.3 * crush(noise(n), 3) * decay(n, 0.01)


def bomb_place():
    n = int(0.08 * SR)
    return tri(sweep(220, 160, 0.08)) * decay(n, 0.03)


def explode():
    # Big crushed-noise burst with a falling low body.
    n = int(0.6 * SR)
    body = tri(sweep(120, 35, 0.6)) * decay(n, 0.2)
    return 0.9 * lowpass(crush(noise(n), 3), 2500) * decay(n, 0.18, 0.003) + body


def unlock():
    return notes([(1318.5, 0.04), (1046.5, 0.04), (1568.0, 0.1)], 0.5, 0.05)


def lantern():
    n = int(0.25 * SR)
    return bandpass(noise(n), sweep(400, 2200, 0.25), 2.0) * np.sin(np.pi * np.arange(n) / n)


def shop_buy():
    return notes([(1568.0, 0.05), (2093.0, 0.05), (2637.0, 0.12)], 0.25, 0.07)


def error():
    # A low double buzz: not enough gems / magic / ammo.
    gap = np.zeros(int(0.03 * SR))
    return np.concatenate([notes([(196.0, 0.09)], 0.5, 0.1), gap, notes([(185.0, 0.12)], 0.5, 0.1)])


# --- Phase 6: dungeons ------------------------------------------------------------------

def fall():
    # A long falling whistle into a pit.
    sw = sweep(1200, 120, 0.7, 1.4)
    return pulse(sw, 0.25) * decay(len(sw), 0.45)


def shutter():
    # Iron bars grinding open or shut.
    sw = sweep(220, 110, 0.35)
    n = len(sw)
    grind = bandpass(crush(noise(n), 4), np.full(n, 600.0), 2.0) * np.sin(np.pi * np.arange(n) / n)
    clank = tri(sw) * decay(n, 0.05)
    return grind + clank


def switch_click():
    return notes([(880.0, 0.03), (1318.5, 0.08)], 0.5, 0.04)


def block_push():
    n = int(0.3 * SR)
    return lowpass(noise(n), 700) * np.sin(np.pi * np.arange(n) / n) + 0.3 * tri(np.full(n, 70.0)) * decay(n, 0.2)


def boss_die():
    # A long rumbling burst, then a falling chime.
    sw = sweep(90, 30, 0.9)
    n = len(sw)
    rumble = lowpass(crush(noise(n), 3), 1800) * decay(n, 0.4, 0.003) + tri(sw) * decay(n, 0.5)
    chime = notes([(1568.0, 0.1), (1318.5, 0.1), (1046.5, 0.1), (784.0, 0.4)], 0.25, 0.15)
    return np.concatenate([rumble, 0.6 * chime])


# --- Phase 7: Act 1 ------------------------------------------------------------------------

def dash():
    sw = sweep(300, 1200, 0.25, 0.6)
    n = len(sw)
    return bandpass(noise(n), sw, 3.0) * decay(n, 0.2) + 0.3 * pulse(sw * 0.5, 0.25) * decay(n, 0.1)


def bonk():
    sw = sweep(160, 60, 0.2)
    n = len(sw)
    return tri(sw) * decay(n, 0.06) + 0.6 * lowpass(crush(noise(n), 3), 1500) * decay(n, 0.03)


def fireball():
    sw = sweep(900, 300, 0.3)
    n = len(sw)
    return bandpass(noise(n), sw, 2.0) * decay(n, 0.2) + 0.4 * lowpass(noise(n), 900) * decay(n, 0.1)


def ice_shard():
    return notes([(2637.0, 0.04), (3136.0, 0.08)], 0.125, 0.04)


def orb():
    sw = sweep(500, 900, 0.3)
    n = len(sw)
    return tri(sw) * np.sin(np.pi * np.arange(n) / n) + 0.3 * pulse(sw * 1.5, 0.5) * decay(n, 0.15)


def clank():
    # A blow that does nothing (armour, the wrong weapon).
    t = tt(0.15)
    n = len(t)
    return (np.sin(2 * np.pi * 1400 * t) + 0.5 * np.sin(2 * np.pi * 2100 * t)) * decay(n, 0.04)


def magic_jar():
    return notes([(1046.5, 0.05), (1568.0, 0.05), (2093.0, 0.12)], 0.5, 0.08)


def act_end():
    # The end of Act 1: a slow minor rise that resolves.
    seq = [(440.0, 0.25), (523.3, 0.25), (659.3, 0.25), (622.3, 0.5), (659.3, 0.9)]
    parts = []
    for f, d in seq:
        n = int(d * SR)
        parts.append(0.6 * tri(np.full(n, f)) * decay(n, d * 0.9, 0.01) + 0.3 * pulse(np.full(n, f * 2), 0.25) * decay(n, d * 0.4))
    return np.concatenate(parts)


# --- Phase 8: the two worlds ---------------------------------------------------------------

def warp():
    # Stepping between the worlds: a shimmering rise over a hollow hum.
    sw = sweep(300, 1600, 0.45, 0.8)
    n = len(sw)
    shimmer = pulse(sw, 0.125) * np.sin(np.pi * np.arange(n) / n) * (0.6 + 0.4 * np.sin(2 * np.pi * 18 * np.arange(n) / SR))
    hum = tri(np.full(n, 110.0)) * np.sin(np.pi * np.arange(n) / n) * 0.5
    return shimmer + hum


# name -> (generator, peak dB)
SFX = {
    "sword_slash": (sword_slash, -5.0), "sword_spin": (sword_spin, -4.0), "charge_ready": (charge_ready, -6.0),
    "enemy_hit": (enemy_hit, -3.5), "enemy_die": (enemy_die, -4.0), "hurt": (hurt, -3.5),
    "player_die": (player_die, -3.5), "bush_cut": (bush_cut, -5.0), "lift": (lift, -5.5), "throw": (throw, -5.5),
    "shatter": (shatter, -4.0), "pickup_heart": (pickup_heart, -5.5), "pickup_gem": (pickup_gem, -6.0),
    "shield_block": (shield_block, -5.0), "spit": (spit, -5.5), "ledge_hop": (ledge_hop, -5.5),
    "land": (land, -5.0), "door": (door, -5.0),
    "menu_move": (menu_move, -8.0), "menu_select": (menu_select, -6.5), "menu_back": (menu_back, -6.5),
    "text_blip": (text_blip, -9.0), "pause": (pause, -6.0), "save_done": (save_done, -6.0),
    "game_over": (game_over, -5.0),
    "item_get": (item_get, -5.5), "heart_piece": (heart_piece, -6.0), "chest_open": (chest_open, -5.5),
    "boomerang": (boomerang, -8.0), "arrow_shot": (arrow_shot, -6.0), "arrow_hit": (arrow_hit, -6.0),
    "bomb_place": (bomb_place, -6.5), "explode": (explode, -3.5), "unlock": (unlock, -6.0),
    "lantern": (lantern, -7.0), "shop_buy": (shop_buy, -6.0), "error": (error, -7.0),
    "fall": (fall, -6.0), "shutter": (shutter, -5.5), "switch_click": (switch_click, -6.5),
    "block_push": (block_push, -6.5), "boss_die": (boss_die, -3.5),
    "dash": (dash, -6.5), "bonk": (bonk, -4.5), "fireball": (fireball, -5.5), "ice_shard": (ice_shard, -7.0),
    "orb": (orb, -6.0), "clank": (clank, -6.0), "magic_jar": (magic_jar, -6.5), "act_end": (act_end, -4.5),
    "warp": (warp, -5.5),
}


def write_wav(path, x):
    """16-bit mono PCM; returns the quantised data for checking."""
    pcm = np.clip(np.round(x * 32767), -32768, 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return pcm.astype(np.float64) / 32768.0


def main():
    os.makedirs(SFX_DIR, exist_ok=True)
    os.makedirs(TMP_DIR, exist_ok=True)
    data, bad = {}, 0
    for name, (gen, pk) in SFX.items():
        y = write_wav(os.path.join(SFX_DIR, name + ".wav"), finish(gen(), pk))
        data[name] = y
        peak = 20 * math.log10(np.max(np.abs(y)))
        flags = ""
        if abs(peak - pk) > 0.6:                     # each effect must land on its own target level
            flags += " BAD-LEVEL"
        if abs(y[0]) > 0.003 or abs(y[-1]) > 0.003:
            flags += " CLICK"
        bad += bool(flags)
        print("%-14s %6.3f s  peak %6.2f dB%s" % (name, len(y) / SR, peak, flags))
    try:
        from PIL import Image, ImageDraw
        W, H = 900, 30
        img = Image.new("RGB", (W, H * len(data)), (20, 20, 28))
        dr = ImageDraw.Draw(img)
        for r, (name, y) in enumerate(data.items()):
            cy = r * H + H // 2
            for cx, c in enumerate(np.array_split(np.abs(y), W)):
                h = int(c.max() * (H / 2 - 1))
                dr.line([(cx, cy - h), (cx, cy + h)], fill=(120, 200, 255))
            dr.text((4, r * H + 1), name, fill=(255, 220, 120))
        img.save(os.path.join(TMP_DIR, "sfx_waveforms.png"))
    except ImportError:
        pass
    print("%d effects, %d with problems" % (len(data), bad))


if __name__ == "__main__":
    main()
