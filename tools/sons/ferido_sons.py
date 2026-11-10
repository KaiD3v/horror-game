# The hurt player's breathing (player.gd, at a third of his health), synthesized (no ElevenLabs credits):
#   respiracao (loop): ragged heavy breaths through the mouth, a shaky inhale, an exhale that catches and stutters
#   ofego (loop): panting after a sprint (player.gd, with the stamina): quick, short, open-mouthed breaths
# 44.1 kHz mono 16-bit into godot_demo/sounds/. Seeded. Run: python tools/sons/ferido_sons.py
import os, wave
import numpy as np
from scipy import signal
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import audio

SR = 44100
OUT = paths.SOUNDS
rng = np.random.default_rng(31)


def sos(kind, f, order=2):
    return audio.sos(kind, f, SR, order)


def air(n, band, shake):
    """Breath noise in a band, with a mouth formant on top and a tremble (pain) in its loudness."""
    x = signal.sosfilt(sos("bandpass", band), rng.standard_normal(n + 2000))[2000:]
    x += 0.6 * signal.sosfilt(sos("bandpass", [band[0] * 1.1, band[0] * 1.6], 4), rng.standard_normal(n + 2000))[2000:]
    t = np.arange(n) / SR
    return x * (1 + shake * np.sin(2 * np.pi * rng.uniform(8, 12) * t + rng.uniform(0, 6)) * rng.uniform(0.6, 1, n // 400 + 1).repeat(400)[:n])


def env(n, attack, bumps=1):
    """Rises over `attack` of its length and dies away; `bumps` > 1 = the breath catches, in pushes."""
    u = np.linspace(0, 1, n)
    e = np.minimum(1, u / attack) * (1 - u) ** 1.5
    if bumps > 1:
        e *= 0.55 + 0.45 * np.abs(np.sin(np.pi * bumps * u ** 0.8))
    return e


cycles = []
for k in range(3):  # three breaths, each its own: the loop is 3 x ~1.7 s
    ni = int(rng.uniform(0.5, 0.65) * SR); gap = int(rng.uniform(0.05, 0.12) * SR)
    ne = int(rng.uniform(0.75, 0.95) * SR); rest = int(rng.uniform(0.08, 0.2) * SR)
    inhale = air(ni, [900, 4200], 0.35) * env(ni, 0.7) * 0.8
    exhale = air(ne, [350, 2200], 0.25) * env(ne, 0.12, bumps=(2, 3, 1)[k])
    cycles.append(np.concatenate([inhale, np.zeros(gap), exhale, np.zeros(rest)]))


def save(name, x):
    audio.write_wav(name, x, SR, 0.7)
    print("ok: %s (%.2f s) ->" % (name, len(x) / SR), OUT)


save("respiracao", np.concatenate(cycles))

pant = []
for k in range(9):  # nine pants, ~0.5 s each: in and out with hardly a gap, the out a little louder
    ni = int(rng.uniform(0.17, 0.22) * SR); ne = int(rng.uniform(0.2, 0.26) * SR); gap = int(rng.uniform(0.02, 0.06) * SR)
    pant += [air(ni, [1100, 4800], 0.15) * env(ni, 0.6) * 0.7, air(ne, [450, 2600], 0.15) * env(ne, 0.15), np.zeros(gap)]
save("ofego", np.concatenate(pant))
