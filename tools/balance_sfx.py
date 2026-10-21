# File: balance_sfx.py
# Description: Measures the loudness of every sound effect (RMS over its non-silent part), compares it with the median of the whole set, and writes assets/audio/sfx_trim.json - small dB trims that Audio applies so no effect is far louder or quieter than the rest.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
#
# Run:  python -I tools/balance_sfx.py            (writes the trim file and prints a table)
# Ported from Chapel of Dreams. Run it again after gen_sfx.py adds or changes an effect.
import json
import os
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
OUT = os.path.join(ROOT, "assets", "audio", "sfx_trim.json")
FRAME_S = 0.01                      # analysis frame length
SILENCE_DB = -50.0                  # frames quieter than this do not count towards the loudness
MAX_CUT_DB = -3.0                   # never turn an effect down by more than this
MAX_BOOST_DB = 3.0                  # ... or up by more than this
DEAD_BAND_DB = 1.0                  # differences smaller than this are left alone
STEP_DB = 0.5                       # trims are rounded to this step
# Effects that must keep their own level whatever they measure (UI feedback and the very short ticks).
PINNED = {"menu_move", "menu_select", "menu_back", "text_blip", "tick", "pickup_gem"}


def load(path):
    """Mono float samples in -1..1 and the sample rate."""
    with wave.open(path, "rb") as w:
        data = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
        if w.getnchannels() > 1:
            data = data.reshape(-1, w.getnchannels()).mean(axis=1)
        return data, w.getframerate()


def loudness_db(samples, rate):
    """RMS in dBFS over the frames that are not silent."""
    n = max(int(rate * FRAME_S), 1)
    frames = samples[: len(samples) // n * n].reshape(-1, n)
    rms = np.sqrt((frames ** 2).mean(axis=1) + 1e-12)
    live = rms[20 * np.log10(rms) > SILENCE_DB]
    if live.size == 0:
        return SILENCE_DB
    return float(20 * np.log10(np.sqrt((live ** 2).mean())))


def main():
    measured = {}
    for name in sorted(os.listdir(SFX_DIR)):
        if name.endswith(".wav"):
            samples, rate = load(os.path.join(SFX_DIR, name))
            measured[name[:-4]] = loudness_db(samples, rate)
    target = float(np.median(list(measured.values())))
    trims = {}
    for name, db in measured.items():
        if name in PINNED:
            continue
        trim = min(max(target - db, MAX_CUT_DB), MAX_BOOST_DB)
        if abs(trim) >= DEAD_BAND_DB:
            trims[name] = round(trim / STEP_DB) * STEP_DB
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(trims, f, indent=1, sort_keys=True)
    print(f"{len(measured)} effects, median loudness {target:.1f} dB, {len(trims)} trims written")
    for name in sorted(measured, key=lambda n: measured[n]):
        print(f"  {name:24s} {measured[name]:6.1f} dB  trim {trims.get(name, 0.0):+.1f}")


if __name__ == "__main__":
    main()
