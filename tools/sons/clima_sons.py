# Weather and wildlife sounds for the village, synthesized (no ElevenLabs credits):
#   garoa (loop): fine drizzle, a hiss plus drops ticking on leaves, wood and tiles
#   asas: a crow taking off, wingbeats speeding up then easing as it climbs away
# 44.1 kHz mono 16-bit into godot_demo/sounds/. Seeded. Run: python tools/sons/clima_sons.py
import os, wave
import numpy as np
from scipy import signal
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import audio

SR = 44100
OUT = paths.SOUNDS
rng = np.random.default_rng(74)


def save(name, x, peak):
    audio.write_wav(name, x, SR, peak)


def sos(kind, f, order=2):
    return audio.sos(kind, f, SR, order)


# garoa: 10 s loop. The hiss is filtered noise with a slow swell; filtering a looped buffer twice keeps it seamless.
L = 10 * SR
hiss = rng.standard_normal(L)
hiss = signal.sosfiltfilt(sos("bandpass", [900, 7000]), np.tile(hiss, 3))[L:2 * L]
swell = 0.8 + 0.2 * np.sin(2 * np.pi * np.arange(L) / L * 2)  # two slow swells per loop, ends where it starts
drops = np.zeros(L)
for _ in range(900):  # ~90 drops a second, near and far
    f = rng.uniform(1800, 5200); n = int(rng.uniform(0.006, 0.02) * SR); t = np.arange(n) / SR
    d = np.sin(2 * np.pi * f * t * (1 - 0.3 * t / t[-1])) * np.exp(-t / (n / SR / 4)) * rng.uniform(0.05, 1.0) ** 2
    idx = (np.arange(n) + rng.integers(L)) % L
    np.add.at(drops, idx, d)
save("garoa", hiss * swell * 0.35 + drops, 0.6)

# asas: 1.8 s, 9 beats; each beat is a push of air (low-passed noise) with a feathery rustle on top
n = int(1.8 * SR); x = np.zeros(n)
times = np.cumsum([0.0, 0.11, 0.12, 0.13, 0.15, 0.17, 0.2, 0.23, 0.27])
for i, at in enumerate(times):
    m = int(0.09 * SR); t = np.arange(m) / SR
    beat = signal.sosfilt(sos("lowpass", 700), rng.standard_normal(m)) * 3.0 + signal.sosfilt(sos("bandpass", [2500, 6000]), rng.standard_normal(m)) * 0.5
    beat *= np.minimum(1, t / 0.012) * np.exp(-t / 0.03) * (1.0 - 0.07 * i)  # fading as it climbs
    k = int(at * SR); x[k:k + m] += beat[: n - k]
save("asas", x, 0.75)
print("ok: garoa, asas ->", OUT)
