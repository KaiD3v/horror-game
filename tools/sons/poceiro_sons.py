# O Poceiro's sounds, synthesized (no ElevenLabs credits; he does not speak):
#   poceiro_balde (loop): the tin bucket at his hip, a clank and a slosh of water on every heavy step (1.07 s a step)
#   poceiro_respira_1..2: a wet, bubbling breath through the slack mouth, now and then while he listens
#   poceiro_rugido_1..2: a low, waterlogged roar: when he hears you, when he strikes, when he is hurt
#   poceiro_queda: the death fall, a heavy wet thud
#   poceiro_agua: water pouring off him as he hauls himself out of the well (or the splash going back down)
# 44.1 kHz mono 16-bit into godot_demo/sounds/. Seeded. Run: python tools/sons/poceiro_sons.py
import os, sys
import numpy as np
from scipy import signal
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import audio

SR = 44100
rng = np.random.default_rng(1977)


def noise(n, kind, f):
    return signal.sosfilt(audio.sos(kind, f, SR), rng.standard_normal(n))


def clank(f0):
    n = int(0.5 * SR); t = np.arange(n) / SR
    x = sum(np.sin(2 * np.pi * f0 * r * t + rng.uniform(0, 6)) * np.exp(-t / (0.09 / r)) for r in (1.0, 2.31, 3.9, 5.4))
    x[: int(0.003 * SR)] += rng.standard_normal(int(0.003 * SR))
    return x


# balde: 4.28 s loop = 4 steps; on each a clank (the bucket swinging into his hip) and a slosh after it
L = int(4.28 * SR); loop = np.zeros(L)
for i in range(4):
    at = int((i * 1.07 + rng.uniform(-0.02, 0.02)) * SR)
    c = clank(rng.uniform(420, 520)) * rng.uniform(0.5, 1.0)
    idx = (np.arange(len(c)) + at) % L; np.add.at(loop, idx, c)
    m = int(0.45 * SR); t = np.arange(m) / SR
    s = noise(m, "bandpass", [300, 1800]) * np.sin(np.pi * np.minimum(1, t / 0.45)) ** 2 * (1 + 0.6 * np.sin(2 * np.pi * 9 * t))
    idx = (np.arange(m) + at + int(0.08 * SR)) % L; np.add.at(loop, idx, 0.5 * s)
audio.write_wav("poceiro_balde", loop, SR, 0.6)

# respira: a slow in-and-out through water in the throat: band noise swelling, bubbles popping in it
for k, dur in ((1, 2.2), (2, 2.8)):
    n = int(dur * SR); t = np.arange(n) / SR
    env = np.sin(np.pi * t / dur) ** 1.5
    air = noise(n, "bandpass", [150, 700]) * env
    bub = np.zeros(n)
    for _ in range(int(dur * 14)):
        j = rng.integers(0, n - 2000); m = 1500; tt = np.arange(m) / SR
        f = rng.uniform(250, 600) * (1 + 3 * tt)
        bub[j:j + m] += np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / 0.008) * env[j]
    audio.write_wav("poceiro_respira_%d" % k, air + 0.5 * bub, SR, 0.6)

# rugido: a low voice (55-80 Hz) with a rattling growl, through a throat formant, gargling noise on top
for k, (f0, dur) in ((1, (62, 1.6)), (2, (75, 2.1))):
    n = int(dur * SR); t = np.arange(n) / SR
    f = f0 * (1 + 0.25 * np.sin(np.pi * t / dur)) + 4 * np.sin(2 * np.pi * 5 * t)
    ph = 2 * np.pi * np.cumsum(f) / SR
    v = sum(np.sin(h * ph) / h ** 0.8 for h in range(1, 14)) * (1 + 0.7 * np.sin(2 * np.pi * 28 * t))
    v = signal.sosfilt(audio.sos("bandpass", [90, 900], SR), v) + 0.35 * noise(n, "bandpass", [300, 1500]) * (1 + np.sin(2 * np.pi * 13 * t))
    env = np.minimum(1, t / 0.12) * np.clip((dur - t) / (dur * 0.5), 0, 1)
    audio.write_wav("poceiro_rugido_%d" % k, v * env, SR, 0.8)

# queda: a thud (low sine drop) and wet cloth slapping
n = int(1.2 * SR); t = np.arange(n) / SR
thud = np.sin(2 * np.pi * (70 - 30 * t) * t) * np.exp(-t / 0.18)
slap = noise(n, "bandpass", [400, 3000]) * np.exp(-t / 0.06)
audio.write_wav("poceiro_queda", thud + 0.4 * slap, SR, 0.85)

# agua: water streaming off him, 3 s, falling away; heavy drops in it
n = int(3.0 * SR); t = np.arange(n) / SR
stream = noise(n, "bandpass", [500, 4000]) * (1 + 0.5 * np.sin(2 * np.pi * 3.3 * t)) * np.exp(-t / 1.4)
drops = np.zeros(n)
for _ in range(60):
    j = rng.integers(0, n - 3000); m = 2500; tt = np.arange(m) / SR
    drops[j:j + m] += np.sin(2 * np.pi * rng.uniform(600, 1400) * (1 + 2 * tt) * tt) * np.exp(-tt / 0.012) * rng.uniform(0.3, 1)
audio.write_wav("poceiro_agua", stream + 0.6 * drops, SR, 0.7)
print("ok: poceiro_balde, poceiro_respira_1..2, poceiro_rugido_1..2, poceiro_queda, poceiro_agua ->", paths.SOUNDS)
