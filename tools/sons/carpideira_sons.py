# A Carpideira's sounds, synthesized (no ElevenLabs credits; a voice made of a buzz through vowel formants):
#   carpideira_choro (loop): her weeping, heard before she is seen: wails that fall away, sobs, hitching breaths
#   carpideira_crianca_1..2: what she does now and then instead: a small child's cry, to draw you in
#   carpideira_suspiro: the sharp breath in when she has seen you
#   carpideira_grito_1..2: the scream that calls the others: shrill, rising, rough
#   carpideira_queda: the fall when she dies
# 44.1 kHz mono 16-bit into godot_demo/sounds/. Seeded. Run: python tools/sons/carpideira_sons.py
import os, sys
import numpy as np
from scipy import signal
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import audio

SR = 44100
rng = np.random.default_rng(1979)
VOWELS = {"a": [(800, 90), (1250, 110), (2900, 160)], "o": [(500, 80), (950, 100), (2800, 150)],
          "u": [(380, 70), (900, 100), (2600, 150)], "e": [(600, 80), (1900, 120), (2900, 160)],
          "grito": [(1000, 150), (1700, 180), (3200, 250)]}


def noise(n, kind, f):
    return signal.sosfilt(audio.sos(kind, f, SR), rng.standard_normal(n))


def buzz(f0, rough=0.0):
    """A glottal buzz along the pitch curve f0 (Hz per sample): harmonics falling off, jittered when rough."""
    f = f0 * (1 + rough * 0.03 * signal.sosfilt(audio.sos("lowpass", 30, SR), rng.standard_normal(len(f0))) * 8)
    ph = 2 * np.pi * np.cumsum(f) / SR
    hs = [h for h in range(1, 40) if h * f0.max() < 8000]
    x = sum(np.sin(h * ph) / h ** 1.1 for h in hs)
    if rough:
        x += rough * 0.5 * np.sin(ph / 2)  # a subharmonic: the voice breaking
    return x


def vowel(x, v):
    """Through the vowel's three formants (two-pole resonators in parallel)."""
    out = np.zeros_like(x)
    for i, (f, bw) in enumerate(VOWELS[v]):
        r = np.exp(-np.pi * bw / SR)
        out += signal.lfilter([1 - r], [1, -2 * r * np.cos(2 * np.pi * f / SR), r * r], x) / (1 + i)
    return out


def morph(x, v1, v2):  # from one vowel to the other along the clip
    k = np.linspace(0, 1, len(x))
    return vowel(x, v1) * (1 - k) + vowel(x, v2) * k


def wail(dur, f_hi, f_lo, sob_hz, v1="a", v2="o"):
    """A wail falling from f_hi to f_lo, broken by sobs (sob_hz), a little vibrato; breath under it."""
    n = int(dur * SR); t = np.arange(n) / SR
    f0 = f_lo + (f_hi - f_lo) * (1 - t / dur) ** 1.5 + 6 * np.sin(2 * np.pi * 5.5 * t)
    x = morph(buzz(f0, 0.3), v1, v2) + 0.15 * noise(n, "bandpass", [1500, 5000])
    sob = 0.45 + 0.55 * np.abs(np.sin(np.pi * sob_hz * t)) ** 0.6
    return x * sob * np.minimum(1, t / 0.06) * np.clip((dur - t) / 0.25, 0, 1)


def gasp(dur, lo=700, hi=2600):
    """A breath sucked in: noise through a band that rises."""
    n = int(dur * SR); t = np.arange(n) / SR
    x = noise(n, "bandpass", [lo, hi]) * (1 + 0.3 * np.sin(2 * np.pi * 40 * t))
    return x * np.sin(np.pi * t / dur) ** 2


def put(buf, x, at, gain=1.0):  # into a loop buffer, wrapping round
    idx = (np.arange(len(x)) + int(at * SR)) % len(buf)
    np.add.at(buf, idx, gain * x)


# choro: 9.6 s loop: three wails, each followed by hitching breaths, one quiet whimper
L = np.zeros(int(9.6 * SR))
for at, dur, hi, lo in ((0.0, 1.9, 470, 330), (3.4, 1.5, 430, 320), (6.3, 2.0, 500, 310)):
    put(L, wail(dur, hi, lo, rng.uniform(3.5, 5.0)), at)
    for k in range(3):
        put(L, gasp(0.14), at + dur + 0.1 + 0.22 * k, 0.12)
put(L, wail(0.8, 360, 300, 6.0, "u", "u"), 8.5, 0.4)
audio.write_wav("carpideira_choro", L, SR, 0.55)

# crianca: two or three short "uaa" cries, high and bright, the mouth opening on each; a catch of breath between
for k, cries in ((1, 3), (2, 2)):
    parts = []
    for i in range(cries):
        dur = rng.uniform(0.6, 0.9); n = int(dur * SR); t = np.arange(n) / SR
        f0 = rng.uniform(520, 600) * (1 + 0.15 * np.sin(np.pi * t / dur)) + 12 * np.sin(2 * np.pi * 7 * t)
        x = morph(buzz(f0, 0.15), "u", "a") * np.minimum(1, t / 0.05) * np.clip((dur - t) / 0.15, 0, 1)
        parts += [x, 0.12 * gasp(0.25, 1200, 4000), np.zeros(int(0.1 * SR))]
    audio.write_wav("carpideira_crianca_%d" % k, np.concatenate(parts), SR, 0.6)

# suspiro: the sharp breath in, a voiced catch at its end
g = gasp(0.45, 900, 3500)
n = int(0.2 * SR); t = np.arange(n) / SR
g[-n:] += 0.25 * vowel(buzz(np.full(n, 480.0)), "e") * np.sin(np.pi * t / 0.2)
audio.write_wav("carpideira_suspiro", g, SR, 0.7)

# grito: rising from a wail into a shrill held scream, rough, the voice breaking; it carries over the village
for k, f_a, f_b, dur in ((1, 650, 1150, 2.4), (2, 720, 1250, 2.0)):
    n = int(dur * SR); t = np.arange(n) / SR
    f0 = f_a + (f_b - f_a) * np.minimum(1, t / 0.5) ** 0.7 + 25 * np.sin(2 * np.pi * 7.5 * t)
    x = morph(buzz(f0, 0.8), "a", "grito") + 0.35 * noise(n, "bandpass", [2000, 6000])
    x = np.tanh(2.5 * x / np.max(np.abs(x)))  # strained
    audio.write_wav("carpideira_grito_%d" % k, x * np.minimum(1, t / 0.08) * np.clip((dur - t) / 0.5, 0, 1), SR, 0.9)

# queda: a body in cloth going down, the candle rolling away
n = int(1.0 * SR); t = np.arange(n) / SR
thud = np.sin(2 * np.pi * (90 - 40 * t) * t) * np.exp(-t / 0.12)
cloth = noise(n, "bandpass", [300, 2500]) * np.exp(-t / 0.15)
roll = np.zeros(n); j = int(0.35 * SR)
roll[j:] = noise(n - j, "bandpass", [1500, 4000]) * np.exp(-(t[j:] - 0.35) / 0.2) * (1 + np.sin(2 * np.pi * 18 * t[j:]))
audio.write_wav("carpideira_queda", thud + 0.5 * cloth + 0.15 * roll, SR, 0.8)
print("ok: carpideira_choro, carpideira_crianca_1..2, carpideira_suspiro, carpideira_grito_1..2, carpideira_queda ->", paths.SOUNDS)
