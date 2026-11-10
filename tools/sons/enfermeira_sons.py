# The Enfermeira's two sounds, synthesized (no ElevenLabs credits): she has no footsteps and no voice.
#   tilintar (loop): keys and scissors on the chain at her waist, jingling at her tiptoe pace (a step every 0.4 s)
#   sopro: a slow breath through the sewn mouth, right behind the player before she stabs
# 44.1 kHz mono 16-bit into godot_demo/sounds/. Seeded. Run: python tools/sons/enfermeira_sons.py
import os, wave
import numpy as np
from scipy import signal
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import audio

SR = 44100
OUT = paths.SOUNDS
rng = np.random.default_rng(1974)


def save(name, x, peak):
    audio.write_wav(name, x, SR, peak)


def clink(freqs, decay):
    n = int(decay * 6 * SR); t = np.arange(n) / SR
    x = sum(np.sin(2 * np.pi * f * rng.uniform(0.97, 1.03) * t + rng.uniform(0, 6)) * np.exp(-t / (decay * rng.uniform(0.6, 1.2)))
            for f in freqs)
    x[: int(0.004 * SR)] += rng.standard_normal(int(0.004 * SR)) * 0.6  # the tick of metal on metal
    return x


# tilintar: 4.8 s loop = 12 steps; each step shakes 1-3 clinks; events wrap round the end so the loop is seamless
L = int(4.8 * SR); jingle = np.zeros(L)
for step in range(12):
    at = step * 0.4 + rng.uniform(-0.03, 0.03)
    for k in range(rng.integers(1, 4)):
        keys = rng.random() < 0.7
        c = clink([2310, 3720, 5130, 6890] if keys else [1580, 2950, 4400], 0.03 if keys else 0.06) * rng.uniform(0.3, 1.0)
        i = int((at + k * rng.uniform(0.02, 0.07)) * SR)
        idx = (np.arange(len(c)) + i) % L
        np.add.at(jingle, idx, c)
jingle = signal.sosfilt(signal.butter(2, 900, "highpass", fs=SR, output="sos"), jingle)
save("tilintar", jingle, 0.6)

# sopro: noise through two breathy formants, slow swell and fall, a wet rasp at the peak
n = int(1.6 * SR); t = np.arange(n) / SR
noise = rng.standard_normal(n)
air = (signal.sosfilt(signal.butter(2, [350, 900], "bandpass", fs=SR, output="sos"), noise)
       + 0.6 * signal.sosfilt(signal.butter(2, [1400, 2600], "bandpass", fs=SR, output="sos"), noise))
env = np.minimum(1, t / 0.45) ** 1.5 * np.clip((1.6 - t) / 1.0, 0, 1) ** 2
rasp = 1 + 0.5 * np.sin(2 * np.pi * 38 * t) * np.exp(-((t - 0.55) / 0.25) ** 2)  # the sewn lips flutter
save("sopro", air * env * rasp, 0.7)
print("ok: tilintar, sopro ->", OUT)
