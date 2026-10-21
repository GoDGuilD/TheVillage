# File: gen_music.py
# Description: Composes and synthesises The Village's chiptune music - ten seamless loops (title, the valley, houses, Light World dungeons, the Dark World, the dimension dungeons, Caver's tower, bosses, Caver, the ending) - from small per-track specs, writes 16-bit mono WAVs plus a manifest, checks levels and loop seams, and draws a piano-roll preview.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
#
# Run:  python -I tools/gen_music.py     (deterministic; writes assets/audio/music/*.wav + music_manifest.json,
#                                         tmp/music_roll.png; must end "0 with problems")
# Synthesis (pulse / triangle voices, noise drums, circular overlap-add so note tails wrap into bar 1) is ported
# from Chapel of Dreams' gen_audio.py. The composer is new: each track is a spec (tempo, key, mode, chord
# progression per bar, arrangement); a seeded melody generator writes a 4-bar motif, answers it over the next
# chords keeping its contour, contrasts it in the B section and closes on the tonic.
import json
import math
import os
import wave

import numpy as np

SR = 22050                        # Hz (music needs less than the effects' 44.1 kHz)
PEAK_DB = -4.0                    # every track is normalised to this peak
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")
TMP_DIR = os.path.join(ROOT, "tmp")
STEPS = 16                        # sixteenth notes per bar (4/4)
MODES = {"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10],
         "harmonic": [0, 2, 3, 5, 7, 8, 11], "dorian": [0, 2, 3, 5, 7, 9, 10]}
# Bar rhythms (sixteenths, each sums to 16): the motif generator picks from these.
RHYTHMS = [[4, 4, 4, 4], [4, 2, 2, 4, 4], [2, 2, 4, 8], [6, 2, 4, 4], [4, 4, 8], [2, 2, 2, 2, 4, 4],
           [8, 4, 4], [4, 2, 2, 8], [3, 1, 4, 4, 4], [4, 4, 2, 2, 4]]
CADENCE = [[8, 8], [4, 12], [16]]
BUSY_RHYTHMS = [5, 1, 8, 9, 2]           # the denser ones (fights): indexes into RHYTHMS
STEP_CHOICES = [-2, -1, -1, 1, 1, 2, 0]  # scale steps between two notes of a motif
BUSY_STEPS = [-3, -2, -1, 1, 2, 3]       # fights: always moving


# --------------------------------------------------------------- primitives (Chapel of Dreams' toolbox)
def phase(freq):
    return np.cumsum(freq) / SR


def pulse(freq, duty=0.5):
    return np.where((phase(freq) % 1.0) < duty, 1.0, -1.0)


def tri(freq, levels=32):
    x = 2.0 * np.abs(2.0 * (phase(freq) % 1.0) - 1.0) - 1.0
    return np.round(x * levels / 2) / (levels / 2)          # NES-style stepped triangle


def noise(n, rng):
    return rng.uniform(-1.0, 1.0, n)


def decay(n, tau):
    return np.exp(-np.arange(n) / SR / tau)


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def add_wrapped(buf, start, seg):
    """Overlap-add `seg` into circular `buf` at `start`; what runs past the end wraps to the start (seamless loop)."""
    n = len(buf)
    start %= n
    done = 0
    while done < len(seg):
        chunk = min(len(seg) - done, n - start)
        buf[start:start + chunk] += seg[done:done + chunk]
        done += chunk
        start = 0


def voice(kind, midi, n, duty=0.5, rel=0.03, vib=0.0, tau=None):
    """One note: oscillator x envelope (2 ms attack, sustain or exponential decay, linear release)."""
    r = int(rel * SR)
    total = n + r
    t = np.arange(total) / SR
    f = np.full(total, mtof(midi))
    if vib:                                                   # delayed vibrato
        f = f * (1 + vib * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / 0.15, 0, 1))
    w = pulse(f, duty) if kind == "pulse" else tri(f)
    env = np.ones(total)
    a = int(0.002 * SR)
    env[:a] = np.linspace(0, 1, a)
    if tau:
        env *= np.exp(-t / tau)
    env[n:] *= np.linspace(1, 0, r)
    return w * env


def kick(rng):
    n = int(0.18 * SR)
    f = 130 * np.exp(-np.arange(n) / SR * 18) + 40
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * decay(n, 0.07)


def snare(rng):
    n = int(0.13 * SR)
    return (noise(n, rng) * 0.8 + tri(np.full(n, 190.0)) * 0.4) * decay(n, 0.04)


def hat(rng):
    n = int(0.04 * SR)
    return np.diff(noise(n + 1, rng)) * decay(n, 0.01)


# --------------------------------------------------------------- harmony and melody
def scale(spec):
    """Every MIDI note of the track's scale from two octaves below the key to three above."""
    root, steps = spec["key"], MODES[spec["mode"]]
    return [root + 12 * o + s for o in range(-2, 4) for s in steps]


def chord(spec, degree):
    """Triad on scale degree 1..7; "b2", "b6", "b7" are borrowed major chords a semitone below the scale's degree."""
    d = str(degree)
    flat = d.startswith("b")
    deg = int(d.lstrip("b")) - 1
    steps = MODES[spec["mode"]]
    if flat:                                                  # borrowed major chord (bII, bVI, bVII) in any mode
        root = spec["key"] + MODES["major"][deg] - 1
        return [root, root + 4, root + 7]
    return [spec["key"] + steps[(deg + k) % 7] + 12 * ((deg + k) // 7) for k in (0, 2, 4)]


def nearest(pool, target):
    return min(pool, key=lambda m: (abs(m - target), m))


def compose(spec, rng):
    """Lead melody: [(midi or None for a rest, length in sixteenths)] per bar."""
    bars = len(spec["prog"])
    sc = [m for m in scale(spec) if spec["lead_lo"] <= m <= spec["lead_hi"]]
    centre = (spec["lead_lo"] + spec["lead_hi"]) // 2

    def chord_pool(bar, octave_shift=0):
        tones = {t % 12 for t in chord(spec, spec["prog"][bar])}
        # chromatic range: a borrowed chord's tones may lie outside the scale
        return [m + octave_shift for m in range(spec["lead_lo"], spec["lead_hi"] + 1) if m % 12 in tones]

    def bar_notes(bar, rhythm, contour, start, shift=0):
        """Pitches for `rhythm`: strong beats land on chord tones, others follow `contour` (scale steps)."""
        out, pos, cur = [], 0, start
        for k, ln in enumerate(rhythm):
            if k > 0:
                idx = min(range(len(sc)), key=lambda i: abs(sc[i] - cur))
                cur = sc[max(0, min(len(sc) - 1, idx + contour[k]))]
            if pos % 8 == 0:                                   # beats 1 and 3: a chord tone
                cur = nearest(chord_pool(bar), cur + shift)
            out.append((cur, ln))
            pos += ln
        return out

    pool = [RHYTHMS[i] for i in BUSY_RHYTHMS] if spec.get("busy") else RHYTHMS
    steps = BUSY_STEPS if spec.get("busy") else STEP_CHOICES
    motif = []                                                 # 4 bars of (rhythm, contour)
    for _ in range(4):
        rhythm = pool[rng.integers(len(pool))]
        contour = [0] + [int(rng.choice(steps)) for _ in rhythm[1:]]
        motif.append((rhythm, contour))
    contrast = []
    for _ in range(4):
        rhythm = pool[rng.integers(len(pool))]
        contour = [0] + [int(rng.choice([-1, 1, 2, -2, 3])) for _ in rhythm[1:]]
        contrast.append((rhythm, contour))
    mel, cur = [], centre
    for b in range(bars):
        section = (b // 4) % 4                                 # A, A', B, A''
        if b == bars - 1:                                      # cadence: the tonic, long
            rhythm = CADENCE[rng.integers(len(CADENCE))]
            tonic = nearest([m for m in sc if m % 12 == spec["key"] % 12], cur)
            notes = [(nearest(chord_pool(b), cur), rhythm[0])] + [(tonic, ln) for ln in rhythm[1:]]
            if len(rhythm) == 1:
                notes = [(tonic, 16)]
        elif section == 2:
            rhythm, contour = contrast[b % 4]
            notes = bar_notes(b, rhythm, contour, cur, shift=3)
        else:
            rhythm, contour = motif[b % 4]
            notes = bar_notes(b, rhythm, contour, cur)
        if spec.get("rests") and b % 4 == 3 and b != bars - 1:  # breathe at the end of each phrase
            notes = notes[:-1] + [(None, notes[-1][1])]
        mel.append(notes)
        cur = next((m for m, _ in reversed(notes) if m is not None), cur)
    return mel


# --------------------------------------------------------------- arrangement
def render(spec):
    rng = np.random.default_rng(spec["seed"])
    step = SR * 60 / spec["bpm"] / 4                           # one sixteenth in samples (non-integer)
    bars = len(spec["prog"])
    total = int(round(bars * STEPS * step))                    # the loop ends exactly on a bar line
    pos = lambda s: int(round(s * step))
    mix = np.zeros(total)
    mel = compose(spec, rng)
    for b in range(bars):
        base = b * STEPS
        tones = chord(spec, spec["prog"][b])
        bass_root = tones[0] - 12 * spec.get("bass_octaves", 2)
        # Arpeggio (pulse) or held pads.
        arp = spec.get("arp")
        if arp:
            pat, every = arp
            for k, s in enumerate(range(0, STEPS, every)):
                idx = pat[k % len(pat)]
                m = tones[idx % len(tones)] + 12 * (idx // len(tones))
                add_wrapped(mix, pos(base + s), spec["arp_amp"] * voice("pulse", m, int(step * every * 0.8), 0.25,
                                                                         0.01, tau=0.12 * every / 2))
        if spec.get("pad"):
            for m in tones[:3]:
                add_wrapped(mix, pos(base), spec["pad"] * voice("pulse", m, int(step * STEPS * 0.95), 0.125, 0.08,
                                                                 vib=0.004))
        # Bass (triangle): a figure of (sixteenth, semitones above the root, length).
        for s, off, ln in spec["bass"]:
            add_wrapped(mix, pos(base + s), spec["bass_amp"] * voice("tri", bass_root + off, int(step * ln * 0.9),
                                                                      rel=0.02))
        # Lead.
        s = 0
        for m, ln in mel[b]:
            if m is not None:
                add_wrapped(mix, pos(base + s), spec["lead_amp"] * voice(spec.get("lead_voice", "pulse"), m,
                                                                          int(step * ln * 0.9), spec["duty"], 0.05,
                                                                          vib=spec.get("vib", 0.0)))
            s += ln
        # Drums: (kicks, snares, hats every n sixteenths) - a fill closes every 4th bar.
        drums = spec.get("drums")
        if drums:
            kicks, snares, hat_every = drums
            for k in kicks:
                add_wrapped(mix, pos(base + k), 0.5 * kick(rng))
            for k in snares + ([13, 14, 15] if b % 4 == 3 else []):
                add_wrapped(mix, pos(base + k), 0.25 * snare(rng))
            if hat_every:
                for k in range(0, STEPS, hat_every):
                    add_wrapped(mix, pos(base + k), (0.06 if k % 4 else 0.09) * hat(rng))
    mix = 0.5 * (mix + np.roll(mix, 1))                        # gentle circular low-pass (the seam stays smooth)
    mix -= mix.mean()
    return mix / np.max(np.abs(mix)) * 10 ** (PEAK_DB / 20), mel


# Bass figures: (sixteenth, semitones above the chord root, length in sixteenths).
WALK = [(0, 0, 4), (4, 7, 4), (8, 12, 4), (12, 7, 4)]
DRIVE = [(k, (0, 0, 12, 0, 0, 7, 12, 7)[k // 2], 2) for k in range(0, 16, 2)]
HALF = [(0, 0, 8), (8, 7, 8)]
WHOLE = [(0, 0, 16)]
GALLOP = [(0, 0, 3), (3, 0, 3), (6, 12, 2), (8, 0, 3), (11, 0, 3), (14, 7, 2)]
OSTINATO = [(k, (0, 12, 7, 12)[(k // 2) % 4], 2) for k in range(0, 16, 2)]

TRACKS = {
    # The title: a gentle, hopeful call in G major.
    "title": dict(seed=11, bpm=96, key=67, mode="major", lead_lo=67, lead_hi=88, duty=0.25, vib=0.006,
                  prog=[1, 5, 6, 4, 1, 5, 4, 5, 6, 4, 1, 5, 6, 4, 5, 1], arp=([0, 1, 2, 1], 2), arp_amp=0.07,
                  bass=HALF, bass_amp=0.4, lead_amp=0.17, drums=([0, 8], [12], 4), rests=True),
    # The valley (Light World overworld): a striding march in C major.
    "valley": dict(seed=23, bpm=128, key=72, mode="major", lead_lo=69, lead_hi=91, duty=0.125, vib=0.005,
                   prog=[1, 4, 5, 1, 6, 4, 5, 1, 4, 5, 3, 6, 2, 5, 4, 1], arp=([0, 1, 2, 3, 2, 1], 2),
                   arp_amp=0.06, bass=DRIVE, bass_amp=0.42, lead_amp=0.16, drums=([0, 8], [4, 12], 2)),
    # Houses: a quiet waltz-like lullaby in F major, no drums.
    "house": dict(seed=31, bpm=84, key=65, mode="major", lead_lo=65, lead_hi=84, duty=0.5, vib=0.004,
                  lead_voice="tri", prog=[1, 6, 2, 5, 1, 6, 4, 1], arp=([0, 1, 2, 1], 4), arp_amp=0.05,
                  bass=HALF, bass_amp=0.35, lead_amp=0.3, rests=True),
    # Light World dungeons: a cautious minor-key walk in A minor.
    "shrine": dict(seed=43, bpm=100, key=69, mode="minor", lead_lo=64, lead_hi=84, duty=0.25, vib=0.008,
                   prog=[1, 6, 4, 5, 1, 6, 7, 5, 4, 1, 6, 5, 4, 7, 5, 1], arp=([0, 2, 1, 2], 2), arp_amp=0.07,
                   bass=WALK, bass_amp=0.4, lead_amp=0.15, drums=([0], [8], 4), rests=True),
    # The Dark World: the valley's key turned minor and slower, heavier.
    "dark_world": dict(seed=23, bpm=112, key=72, mode="minor", lead_lo=67, lead_hi=87, duty=0.25, vib=0.01,
                       prog=[1, "b6", "b7", 1, 4, "b6", 5, 1, "b6", "b7", 4, 1, "b6", 4, 5, 1],
                       arp=([0, 1, 2, 1], 2), arp_amp=0.06, bass=GALLOP, bass_amp=0.42, lead_amp=0.15,
                       drums=([0, 6, 8], [4, 12], 4)),
    # The dimension dungeons: a tense harmonic-minor ostinato in E.
    "dimension": dict(seed=53, bpm=112, key=64, mode="harmonic", lead_lo=64, lead_hi=86, duty=0.125, vib=0.01,
                      prog=[1, 1, 4, 5, 1, "b6", 4, 5, 6, 4, 5, 1, 4, "b6", 5, 1], arp=([0, 1, 2, 3], 1),
                      arp_amp=0.045, bass=OSTINATO, bass_amp=0.4, lead_amp=0.14, drums=([0, 10], [8], 4),
                      rests=True),
    # Caver's tower: urgent, D minor, borrowed flat chords.
    "tower": dict(seed=61, bpm=136, key=62, mode="minor", lead_lo=69, lead_hi=93, duty=0.25, vib=0.008,
                  prog=[1, "b2", 1, 5, 4, "b6", "b7", 5, 1, "b2", 4, 5, "b6", "b7", 5, 1],
                  arp=([0, 1, 2, 3, 2, 1], 1), arp_amp=0.045, bass=DRIVE, bass_amp=0.42, lead_amp=0.15,
                  drums=([0, 8, 14], [4, 12], 2), busy=True),
    # Bosses: fast and hard, B minor.
    "boss": dict(seed=71, bpm=152, key=71, mode="minor", lead_lo=71, lead_hi=95, duty=0.25, vib=0.0,
                 prog=[1, "b6", "b7", 1, 1, "b6", 4, 5], arp=([0, 1, 2, 1], 1), arp_amp=0.05, bass=DRIVE,
                 bass_amp=0.45, lead_amp=0.15, drums=([0, 6, 8, 14], [4, 12], 2), busy=True),
    # Caver himself: harmonic minor, the fastest, with a held pad of dread.
    "caver": dict(seed=83, bpm=160, key=62, mode="harmonic", lead_lo=69, lead_hi=96, duty=0.125, vib=0.006,
                  prog=[1, "b6", 4, 5, 1, "b2", "b6", 5], arp=([0, 1, 2, 3], 1), arp_amp=0.04, pad=0.035,
                  bass=GALLOP, bass_amp=0.45, lead_amp=0.15, drums=([0, 3, 8, 11], [4, 12], 2), busy=True),
    # The ending: slow and wistful, G major drifting to its relative minor.
    "ending": dict(seed=97, bpm=76, key=67, mode="major", lead_lo=67, lead_hi=88, duty=0.5, vib=0.006,
                   lead_voice="tri", prog=[1, 3, 6, 4, 1, 3, 4, 5, 6, 3, 4, 1, 6, 4, 5, 1], pad=0.03,
                   bass=WHOLE, bass_amp=0.35, lead_amp=0.3, rests=True),
}


def write_wav(path, x):
    pcm = np.clip(np.round(x * 32767), -32768, 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return pcm.astype(np.float64) / 32768.0


def db(v):
    return 20 * math.log10(max(v, 1e-9))


def roll(rolls):
    """Piano roll of every lead (one band per track) so the melodies can be checked by eye."""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return
    W, H = 960, 60
    img = Image.new("RGB", (W, H * len(rolls)), (18, 18, 28))
    dr = ImageDraw.Draw(img)
    for r, (name, mel) in enumerate(rolls.items()):
        total = sum(ln for bar in mel for _, ln in bar)
        notes = [m for bar in mel for m, _ in bar if m is not None]
        lo, hi = min(notes), max(notes)
        x = 0
        for b, bar in enumerate(mel):
            dr.line([(x * W / total, r * H), (x * W / total, r * H + H)], fill=(40, 40, 60) if b % 4 else (70, 70, 100))
            for m, ln in bar:
                if m is not None:
                    y = r * H + 6 + (hi - m) * (H - 14) / max(1, hi - lo)
                    dr.rectangle([x * W / total, y, (x + ln) * W / total - 1, y + 2], fill=(120, 210, 255))
                x += ln
        dr.text((4, r * H + 1), name, fill=(255, 220, 120))
    img.save(os.path.join(TMP_DIR, "music_roll.png"))


def main():
    os.makedirs(MUSIC_DIR, exist_ok=True)
    os.makedirs(TMP_DIR, exist_ok=True)
    manifest, rolls, bad = {}, {}, 0
    for name, spec in TRACKS.items():
        x, mel = render(spec)
        y = write_wav(os.path.join(MUSIC_DIR, name + ".wav"), x)
        rolls[name] = mel
        pk, rms = db(np.max(np.abs(y))), db(math.sqrt(np.mean(y ** 2)))
        diffs = np.abs(np.diff(y))
        seam = abs(y[-1] - y[0])
        flags = ""
        if abs(pk - PEAK_DB) > 0.3:
            flags += " BAD-LEVEL"
        if rms < -30:
            flags += " TOO-QUIET"
        if seam > max(4 * np.median(diffs), np.percentile(diffs, 99.5)):
            flags += " SEAM"
        bad += bool(flags)
        manifest[name] = {"duration_s": round(len(y) / SR, 3), "bpm": spec["bpm"], "bars": len(spec["prog"]),
                          "peak_db": round(pk, 2), "rms_db": round(rms, 2), "loop": True}
        print("%-11s %6.2f s  %3d bpm  peak %6.2f dB  rms %6.2f dB  seam %.4f%s"
              % (name, len(y) / SR, spec["bpm"], pk, rms, seam, flags))
    with open(os.path.join(MUSIC_DIR, "music_manifest.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, indent=1)
    roll(rolls)
    print("%d tracks, %d with problems" % (len(TRACKS), bad))


if __name__ == "__main__":
    main()
