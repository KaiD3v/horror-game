# A Bruxa's sounds, synthesized (no ElevenLabs credits; she has no voice to act):
#   bruxa_asas (loop): dusty wings beating, soft and papery, while she glides and scuttles round the light
#   bruxa_estalo_1..3: a dry chatter of clicks, when she notices the light, now and then on the roof, before a dart
#   bruxa_guincho_1..2: a thin, rasping shriek when hurt or dying
# 44.1 kHz mono 16-bit into godot_demo/sounds/. Seeded. Run: python tools/sons/bruxa_sons.py
import os, sys
import numpy as np
from scipy import signal
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import audio

SR = 44100
rng = np.random.default_rng(1976)

# asas: 2.4 s loop, 7 beats a second; each beat a swell of band-passed noise (the membrane) with a papery crackle
L = int(2.4 * SR); t = np.arange(L) / SR
beat = np.maximum(0, np.sin(2 * np.pi * 7.5 * t)) ** 3          # 18 whole beats in 2.4 s: seamless
air = signal.sosfilt(audio.sos("bandpass", [180, 1200], SR), rng.standard_normal(L))
crackle = signal.sosfilt(audio.sos("highpass", 3000, SR), rng.standard_normal(L)) * (rng.random(L) < 0.004)
wings = air * (0.25 + beat) + 2.5 * crackle * beat
audio.write_wav("bruxa_asas", wings, SR, 0.55)

# estalo: 10-25 clicks in a burst, each a short damped resonance, faster towards the middle
for k in (1, 2, 3):
    n = int(0.9 * SR); x = np.zeros(n); at = 0.02
    for i in range(rng.integers(10, 26)):
        f = rng.uniform(1800, 3400); m = int(0.012 * SR); tt = np.arange(m) / SR
        c = np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.0018) + rng.standard_normal(m) * np.exp(-tt / 0.0006) * 0.5
        j = int(at * SR)
        if j + m >= n:
            break
        x[j:j + m] += c * rng.uniform(0.4, 1.0)
        at += rng.uniform(0.018, 0.05) * (1.4 - np.sin(np.pi * i / 20))
    audio.write_wav("bruxa_estalo_%d" % k, x, SR, 0.7)

# guincho: a high sawtooth-ish voice sliding down, through a nasal formant, with a rasp
for k, (f0, f1, dur) in ((1, (2300, 1100, 0.7)), (2, (2700, 900, 1.1))):
    n = int(dur * SR); tt = np.arange(n) / SR
    f = f0 + (f1 - f0) * (tt / dur) ** 0.7 + 60 * np.sin(2 * np.pi * 23 * tt)
    ph = 2 * np.pi * np.cumsum(f) / SR
    v = sum(np.sin(h * ph) / h for h in range(1, 6))
    v = signal.sosfilt(audio.sos("bandpass", [900, 4200], SR), v) + 0.3 * signal.sosfilt(audio.sos("highpass", 2500, SR), rng.standard_normal(n))
    env = np.minimum(1, tt / 0.03) * np.clip((dur - tt) / (dur * 0.6), 0, 1) ** 1.5
    audio.write_wav("bruxa_guincho_%d" % k, v * env, SR, 0.75)
print("ok: bruxa_asas, bruxa_estalo_1..3, bruxa_guincho_1..2 ->", paths.SOUNDS)
