# SUPERSEDED: the game now uses ElevenLabs sounds (sounds_import.py). Kept as the procedural fallback.
# Village and interior sounds, synthesized (numpy + scipy), lo-fi like the textures: 22 kHz mono 16-bit WAVs in
# godot_demo/sounds/. Loops are made seamless by crossfading their tail into their head. Seeded: same files each run.
#   vento (loop), corvo_1-3, sino, rangido_1-2, cao, reza (loop), porta,
#   passo_terra_1-4, passo_madeira_1-4, passo_ladrilho_1-4,
#   casa (interior room tone, loop), fogo (loop), velas (loop), relogio (loop), coro (loop)
# Run: python sounds_build.py   (also writes renders/sons/sons_sintetizados_previa.wav, a 40 s mix of the village to listen to)
import os, wave
import numpy as np
from scipy import signal
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import audio

SR = 22050
OUT = os.path.join(paths.AUDIO_SOURCES, "sintetizados")  # superseded by ElevenLabs (sounds_import.py)
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1974)


def t_(sec):
    return np.arange(int(sec * SR)) / SR


def noise(sec):
    return rng.standard_normal(int(sec * SR))


def band(x, lo, hi, order=2):
    return signal.sosfilt(signal.butter(order, [lo, hi], "bandpass", fs=SR, output="sos"), x)


def lp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, "lowpass", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, "highpass", fs=SR, output="sos"), x)


def smooth_random(sec, every, lo=0.0, hi=1.0):
    """A slow random curve: random values every `every` seconds, cosine-interpolated."""
    n = int(sec / every) + 2
    pts = rng.uniform(lo, hi, n)
    x = t_(sec) / every; i = np.floor(x).astype(int); f = (1 - np.cos(np.pi * (x - i))) / 2
    return pts[i] * (1 - f) + pts[i + 1] * f


def env(sec, a, r, curve=2.0):
    t = t_(sec); e = np.minimum(1, t / max(a, 1e-4)) * np.clip((sec - t) / max(r, 1e-4), 0, 1) ** curve
    return e


def reverb(x, wet=0.3, size=1.0):
    """A cheap room/outdoor tail: a few feedback combs into an allpass."""
    y = np.zeros(len(x) + int(SR * 1.5 * size))
    xx = np.concatenate([x, np.zeros(len(y) - len(x))])
    for d, g in ((0.0297, 0.77), (0.0371, 0.74), (0.0411, 0.72), (0.0437, 0.7)):
        D = int(d * size * SR)
        y += signal.lfilter([1], np.concatenate([[1], np.zeros(D - 1), [-g]]), xx)
    y = lp(y, 3500) / 4
    return xx + wet * y


def seamless(x, fade=1.5):
    """Loop: crossfade the last `fade` seconds into the start, drop them."""
    n = int(fade * SR); head, tail = x[:n], x[-n:]
    w = np.linspace(0, 1, n)
    out = x[:-n].copy(); out[:n] = head * w + tail * (1 - w)
    return out


def save(name, x, peak=0.8):
    return audio.write_wav(name, x, SR, peak, OUT, eps=1e-9)


S = {}

# --- wind: pink-ish noise through a wandering band, gusts, a thin whistle round the eaves (24 s loop) -----------------
sec = 25.5
n = noise(sec); pink = lp(n, 900, 1) + 0.3 * lp(n, 200, 1)
gust = smooth_random(sec, 2.5, 0.25, 1.0) ** 1.6
mixw = smooth_random(sec, 3.0)  # the band wanders between a low moan and a higher rush (crossfaded, no clicks)
w = band(pink, 150, 450) * (1 - mixw) + band(pink, 400, 1100) * mixw
whistle = band(noise(sec), 700, 760, 2) * smooth_random(sec, 4.0, 0, 1) ** 3 * 0.8
S["vento"] = save("vento", seamless(w * gust + whistle * gust + 0.15 * lp(n, 120), 1.5), 0.7)

# --- crows: nasal falling caws, rough, in twos and threes, outdoors ---------------------------------------------------
for k, count in ((1, 2), (2, 3), (3, 1)):
    out = np.zeros(int(SR * 2.4))
    for i in range(count):
        d = rng.uniform(0.28, 0.4); t = t_(d)
        f0 = rng.uniform(520, 640) * (1 - 0.18 * t / d)
        ph = 2 * np.pi * np.cumsum(f0) / SR
        saw = sum(np.sin(h * ph) / h for h in range(1, 12))
        rough = 1 + 0.6 * band(noise(d), 25, 70)
        caw = band(saw * rough, 900, 1700) + 0.6 * band(saw * rough, 2200, 3200)
        caw *= env(d, 0.02, 0.1, 1.2)
        start = int(SR * (0.05 + i * rng.uniform(0.42, 0.55)))
        out[start:start + len(caw)] += caw
    S["corvo_%d" % k] = save("corvo_%d" % k, reverb(out, 0.35, 1.3), 0.75)

# --- the chapel bell: inharmonic bell partials, strike, long hum ----------------------------------------------------------
sec = 7.0; t = t_(sec); f = 392.0
bell = np.zeros_like(t)
for ratio, amp, dec in ((0.5, 0.7, 4.0), (1.0, 0.8, 2.5), (1.19, 0.6, 2.0), (1.5, 0.35, 1.6), (2.0, 0.6, 1.4), (2.51, 0.3, 0.9),
                        (2.66, 0.25, 0.8), (3.01, 0.2, 0.6), (4.07, 0.15, 0.4)):
    for det, g in ((0.0, 1.0), (0.7, 0.25)):  # a slow, shallow beat in each partial
        bell += amp * g * np.sin(2 * np.pi * (f * ratio + det) * t) * np.exp(-t / dec)
bell += 0.4 * hp(noise(sec), 2000) * np.exp(-t / 0.02)
S["sino"] = save("sino", reverb(lp(bell, 4000), 0.4, 1.6), 0.8)

# --- creaks: stick-slip pulses gliding in pitch through a wood resonance (the shop sign, the clothesline posts) -----------
for k in (1, 2):
    sec = rng.uniform(1.0, 1.6); t = t_(sec)
    fr = 25 + 45 * np.sin(np.pi * t / sec) ** 2 * rng.uniform(0.7, 1.2) + 6 * smooth_random(sec, 0.08, -1, 1)
    ph = np.cumsum(fr) / SR
    pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * (0.6 + 0.4 * rng.random(len(t)))
    res = rng.uniform(450, 700)
    creak = band(pulses, res * 0.85, res * 1.15, 2) + 0.4 * band(pulses, res * 2.1, res * 2.4, 2)
    S["rangido_%d" % k] = save("rangido_%d" % k, reverb(creak * env(sec, 0.05, 0.2, 1), 0.2), 0.6)

# --- a dog howling far off (towards the Colônia) -------------------------------------------------------------------------
sec = 3.6; t = t_(sec)
f0 = 430 + 120 * np.sin(np.pi * np.clip(t / 2.6, 0, 1)) - 60 * np.clip((t - 2.4) / 1.2, 0, 1) + 6 * np.sin(2 * np.pi * 5.5 * t)
ph = 2 * np.pi * np.cumsum(f0) / SR
howl = (np.sin(ph) + 0.35 * np.sin(2 * ph) + 0.12 * np.sin(3 * ph)) * env(sec, 0.4, 1.0, 1.5)
S["cao"] = save("cao", reverb(lp(howl + 0.05 * noise(sec) * env(sec, 0.4, 1.0), 1400), 0.6, 1.8), 0.6)

# --- Dona Firmina praying under her breath: a buzz in syllables through wandering vowels, phrases and pauses (12 s loop)
sec = 13.5; t = t_(sec)
f0 = 205 + 15 * smooth_random(sec, 0.6, -1, 1) - 10 * (t % 3.2) / 3.2
ph = 2 * np.pi * np.cumsum(f0) / SR
buzz = sum(np.sin(h * ph) / h ** 0.9 for h in range(1, 16))
syll = 0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(4.2 + 1.5 * smooth_random(sec, 0.5, -1, 1)) / SR)
phrase = (smooth_random(sec, 1.1, 0, 1) > 0.32).astype(float)
phrase = lp(phrase, 6, 1)
vowels = ((700, 1150), (450, 1900), (500, 900), (330, 2200))
weights = np.array([smooth_random(sec, 0.12) ** 3 for _ in vowels]); weights /= weights.sum(0) + 1e-9  # vowels glide
voice = sum(wt * (band(buzz, f1 * 0.8, f1 * 1.2) + 0.6 * band(buzz, f2 * 0.85, f2 * 1.15)) for wt, (f1, f2) in zip(weights, vowels))
syll = syll * smooth_random(sec, 0.23, 0.35, 1.0)  # each syllable its own weight
breath = 0.25 * band(noise(sec), 1500, 4000)
S["reza"] = save("reza", seamless(lp((voice + breath) * syll * phrase, 3000), 1.5), 0.5)

# --- a door: a creak opening and the thud of it shutting behind you ----------------------------------------------------
sec = 1.4; t = t_(sec)
fr = 30 + 60 * np.clip(t / 0.7, 0, 1); ph = np.cumsum(fr) / SR
pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float)
door = band(pulses, 380, 520) * (t < 0.75)
th = (t >= 0.85)
thud = th * (np.sin(2 * np.pi * 75 * (t - 0.85)) * np.exp(-(t - 0.85) / 0.08) + 0.5 * lp(noise(sec), 600) * np.exp(-(t - 0.85) / 0.04))
S["porta"] = save("porta", reverb(9.0 * door + 2.5 * thud, 0.3), 0.8)

# --- footsteps: dirt (soft crunch), wood (knock and boom), tiles (hard click, a little ring) ----------------------------
for k in range(1, 5):
    sec = 0.22; t = t_(sec)
    crunch = lp(noise(sec), rng.uniform(1200, 1800)) * env(sec, 0.005, 0.15, 2.5)
    grit = hp(noise(sec), 3000) * (rng.random(len(t)) > 0.985) * env(sec, 0.002, 0.12, 2)
    S["passo_terra_%d" % k] = save("passo_terra_%d" % k, crunch + 0.8 * grit, 0.55)
    knock = band(noise(sec), 350, 900) * np.exp(-t / 0.025)
    boom = np.sin(2 * np.pi * rng.uniform(85, 120) * t) * np.exp(-t / 0.06)
    S["passo_madeira_%d" % k] = save("passo_madeira_%d" % k, reverb(knock + 1.2 * boom, 0.15, 0.6), 0.6)
    click = hp(noise(sec), 2200) * np.exp(-t / 0.012) + 0.4 * np.sin(2 * np.pi * rng.uniform(180, 240) * t) * np.exp(-t / 0.03)
    S["passo_ladrilho_%d" % k] = save("passo_ladrilho_%d" % k, reverb(click, 0.35, 1.2), 0.55)

# --- interiors -----------------------------------------------------------------------------------------------------
sec = 21.5  # room tone: the wind muffled by the walls, a low hum, a board settling now and then
tone = lp(noise(sec), 220, 2) * smooth_random(sec, 3.0, 0.4, 1.0) + 0.3 * lp(noise(sec), 60, 2)
for at in rng.uniform(1, sec - 3, 3):
    i = int(at * SR); c = S["rangido_%d" % rng.integers(1, 3)] * 0.25
    tone[i:i + len(c)] += lp(c, 900)[:len(tone) - i]
S["casa"] = save("casa", seamless(tone, 1.5), 0.5)
sec = 10.5; t = t_(sec)  # stove fire: a low roar, crackles
fire = lp(noise(sec), 300) * (0.6 + 0.4 * smooth_random(sec, 0.7))
for at in rng.uniform(0, sec, int(sec * 7)):
    i = int(at * SR); L = int(SR * rng.uniform(0.004, 0.02)); amp = rng.uniform(0.3, 1.5) ** 2
    fire[i:i + L] += amp * hp(rng.standard_normal(L), 1500)[:len(fire) - i]
S["fogo"] = save("fogo", seamless(fire, 1.0), 0.6)
sec = 8.5; t = t_(sec)  # candles: a faint flutter, a rare tick
can = 0.4 * lp(noise(sec), 180) * smooth_random(sec, 0.4, 0.3, 1.0)
for at in rng.uniform(0, sec, 6):
    i = int(at * SR); L = int(SR * 0.006); can[i:i + L] += 0.5 * hp(rng.standard_normal(L), 2500)[:len(can) - i]
S["velas"] = save("velas", seamless(can, 0.8), 0.35)
sec = 2.0; t = t_(sec)  # the shop's wall clock: tick, tock
clk = np.zeros_like(t)
for at, f in ((0.0, 2600), (1.0, 2100)):
    tt = t - at; m = tt >= 0
    clk[m] += (band(noise(sec), f * 0.8, f * 1.2)[m] * np.exp(-tt[m] / 0.006) + 0.4 * np.sin(2 * np.pi * 900 * tt[m]) * np.exp(-tt[m] / 0.02))
S["relogio"] = save("relogio", reverb(clk, 0.2, 0.5)[:len(t)], 0.5)
sec = 17.5; t = t_(sec)  # the chapel: a low choir-like drone under everything, breathing, hardly there
drone = sum(a * np.sin(2 * np.pi * (f + 0.15 * k) * t + k) for k, (f, a) in enumerate(((110, 1), (164.8, 0.6), (220.5, 0.4), (277, 0.2))))
drone *= 0.6 + 0.4 * smooth_random(sec, 2.5)
drone += 0.15 * band(noise(sec), 400, 1200) * smooth_random(sec, 3.0, 0, 1)
S["coro"] = save("coro", seamless(lp(drone, 1500), 1.5), 0.45)

# --- a 40 s preview mix of the village: wind, steps on the road, crows, the bell, the dog, a creak, the prayer -----------
sec = 40.0; mix = np.zeros(int(sec * SR))


def add(x, at, gain):
    i = int(at * SR); x = x[:len(mix) - i]; mix[i:i + len(x)] += gain * x


v = S["vento"]
for at in np.arange(0, sec, len(v) / SR):
    add(v, at, 0.45)
for k, at in enumerate(np.arange(1.0, 24.0, 0.66)):
    add(S["passo_terra_%d" % (k % 4 + 1)], at, 0.35)
add(S["corvo_2"], 6.0, 0.4); add(S["rangido_1"], 11.0, 0.35); add(S["corvo_1"], 17.5, 0.3)
add(S["cao"], 21.0, 0.35)
for at in (26.0, 30.0, 34.0):
    add(S["sino"], at, 0.45)
r = S["reza"]; add(r * np.linspace(0, 1, len(r)) ** 2, 24.0, 0.35)
with wave.open(paths.render("sons", "sons_sintetizados_previa.wav"), "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((mix / np.max(np.abs(mix)) * 0.85 * 32767).astype("<i2").tobytes())
print(sorted(S))
