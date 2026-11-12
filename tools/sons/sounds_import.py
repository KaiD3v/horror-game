# The game's sounds from ElevenLabs (flow "Vila de Santa Clara — sons": sound effects with eleven_text_to_sound_v2,
# Dona Firmina's prayer as a wordless murmur loop: no voice acting in the game; the spoken take is kept apart in
# sounds_elevenlabs_extra/), downloaded as MP3 into sounds_elevenlabs/.
# This converts them to what the game loads: godot_demo/sounds/<name>.wav, mono 44.1 kHz 16-bit, each peak set to
# the level the game's volumes were tuned for. Loops were generated seamless (loop on); footsteps lose their lead-in
# silence so they land on the stride; the clock is rebuilt as a steady tick-tock.
# Needs ffmpeg on the PATH (or FFMPEG=...). Run: python tools/sons/sounds_import.py
import os, subprocess, wave, shutil, glob
import numpy as np
from scipy import signal

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
SRC, OUT = os.path.join(paths.AUDIO_SOURCES, "elevenlabs"), paths.SOUNDS
FFMPEG = os.environ.get("FFMPEG") or shutil.which("ffmpeg") or glob.glob(
    os.path.expanduser("~/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg*/*/bin/ffmpeg.exe"))[0]
SR = 44100
PEAK = {"vento": 0.7, "casa": 0.5, "fogo": 0.6, "velas": 0.35, "relogio": 0.5, "coro": 0.45, "sino": 0.8, "cao": 0.6,
        "reza": 0.55, "porta": 0.8, "corvo": 0.75, "rangido": 0.6, "passo": 0.6,
        "musica": 0.4,  # musica_venda: the shop radio (sound-effects model: this connector has no music model)
        # the protagonist's actions and body, the mutant, the rain (2026-11-10)
        "facao": 0.75, "besta": 0.75, "lamparina": 0.6, "dano": 0.8, "coracao": 0.7, "mutante": 0.85, "chuva": 0.6, "compra": 0.6, "curativo": 0.6,
        "bloqueio": 0.8,  # the machete blocking a blow (2026-11-10)
        # the night mutants (docs/MUTANTES_NOITE.md, 2026-11-11): per sound, by its name without the take number
        "bruxa_asas": 0.6, "bruxa_estalo": 0.7, "bruxa_guincho": 0.8,
        "poceiro_balde": 0.9, "poceiro_respira": 0.6, "poceiro_rugido": 0.85, "poceiro_queda": 0.85, "poceiro_agua": 0.7,
        "carpideira_choro": 0.9, "carpideira_crianca": 0.6, "carpideira_suspiro": 0.7, "carpideira_grito": 0.9,
        "carpideira_queda": 0.8, "bau_abrir": 0.8, "bau_achado": 0.75, "pedra_arrastar": 0.85, "escalar": 0.7, "pouso": 0.8,
        # the progression items at work (2026-11-11): the padlock, the crowbar's planks, the pickaxe, the rubble, the rope
        "cadeado_abrir": 0.7, "tabua_arrancar": 0.85, "tabua_cair": 0.8, "picareta_pedra": 0.85, "entulho_desabar": 0.85,
        "corda_amarrar": 0.7, "caminhao_partindo": 0.8, "viga_cedendo": 0.85, "papel_desdobrar": 0.5, "sineta": 0.7, "onibus": 0.7, "lata_abrir": 0.6, "ambiente_hospital": 0.5, "tela_arame": 0.6, "cidade_madrugada": 0.5, "chave_fechadura": 0.6, "impacto_grave": 0.9,
        "morcegos": 0.55, "morcegos_guincho": 0.7, "cana_cortar": 0.85,
        "ossos_pisar": 0.75, "corda_arrebentar": 0.8, "garrafa_quebrar": 0.85,
        "porteiro_chaves": 0.7, "porteiro_golpe": 0.95, "porteiro_gemido": 0.75, "porteiro_rugido": 0.9, "porteiro_queda": 0.85,
        "lampiao_quebrar": 0.85, "pedra_quebrar": 0.85}
LOOPS = ("ambiente_hospital", "cidade_madrugada", "onibus", "vento", "casa", "fogo", "velas", "relogio", "coro", "reza", "musica", "chuva", "coracao",
         "bruxa_asas", "poceiro_balde", "carpideira_choro", "morcegos")  # generated seamless


def load(path):
    raw = subprocess.run([FFMPEG, "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype="<f4").astype(float)


def fade(x, a, b):
    x = x.copy(); na, nb = int(a * SR), int(b * SR)
    if na: x[:na] *= np.linspace(0, 1, na)
    if nb: x[-nb:] *= np.linspace(1, 0, nb)
    return x


def circular(x, sos):
    """Filter a loop as if it went round: warm the filter on its own tail, so the end still meets the start."""
    n = min(len(x), SR)
    return signal.sosfilt(sos, np.concatenate([x[-n:], x]))[n:]


def failing_radio(x, seed=1974):
    """The shop's radio, badly tuned and dying: AM band, a little overdriven, mains hum, hiss and crackle, the
    pitch wandering with one tuning slip, and three dropouts where the music sinks into static. Every modulation
    is periodic over the clip and no event sits on the seam, so it still loops."""
    r = np.random.default_rng(seed); L = len(x); t = np.arange(L) / SR; T = L / SR
    # pitch: a slow wobble (whole cycles over the loop) plus one slip down and back (a smooth bump in the time warp)
    warp = 0.0035 * np.sin(2 * np.pi * 3 * t / T) + 0.0015 * np.sin(2 * np.pi * 7 * t / T + 1.0)
    c, w = 0.62 * T, 0.9
    warp += 0.03 * np.exp(-((t - c) / (w / 2)) ** 2)  # time runs late then catches up: flat, then back in tune
    x = np.interp((t - warp) * SR % L, np.arange(L), x, period=L)
    # AM radio: narrow band, a touch of overdrive
    x = circular(x, signal.butter(2, [280, 3600], "bandpass", fs=SR, output="sos"))
    x = np.tanh(2.2 * x / (np.max(np.abs(x)) + 1e-9)) / np.tanh(2.2)
    # dropouts: the music fades into the static and comes back
    gain = np.ones(L); burst = np.zeros(L)
    for at in (0.18, 0.47, 0.81):
        c0, d = at * T + r.uniform(-0.4, 0.4), r.uniform(0.35, 0.75)
        e = np.clip(np.minimum((t - (c0 - 0.12)) / 0.12, ((c0 + d + 0.18) - t) / 0.18), 0, 1)
        e = e * e * (3 - 2 * e)
        gain *= 1 - 0.88 * e; burst = np.maximum(burst, e)
    hiss = circular(r.standard_normal(L), signal.butter(2, [900, 6000], "bandpass", fs=SR, output="sos"))
    hiss /= np.max(np.abs(hiss))
    flutter = 0.6 + 0.4 * np.sin(2 * np.pi * 11 * t / T) ** 2   # the static breathes a little
    crackle = np.zeros(L)
    for at in r.uniform(0.3, T - 0.3, int(T * 5)):
        i = int(at * SR); k = int(SR * r.uniform(0.001, 0.006))
        crackle[i:i + k] += r.uniform(-1, 1) * r.uniform(0.2, 1.0) ** 2
    crackle = circular(crackle, signal.butter(1, 1500, "highpass", fs=SR, output="sos"))
    hum = 0.02 * np.sin(2 * np.pi * 120 * t) + 0.01 * np.sin(2 * np.pi * 180 * t)  # whole cycles over 15 s
    return x * gain + hiss * (0.045 * flutter + 0.35 * burst) + 0.5 * crackle * (1 + 2 * burst) + hum


for path in sorted(glob.glob(os.path.join(SRC, "*.mp3"))):
    name = os.path.splitext(os.path.basename(path))[0]
    x = load(path)
    kind = name.split("_")[0]
    base = name.rstrip("0123456789").rstrip("_")  # bruxa_estalo_2 -> bruxa_estalo
    if base in PEAK:
        kind = base
    if kind == "passo" or name.startswith("mutante_passo"):  # start on the impact, end clean
        start = max(0, int(np.argmax(np.abs(x) > 0.08 * np.max(np.abs(x)))) - int(0.005 * SR))
        x = fade(x[start:], 0.0, 0.05)
    elif name == "musica_venda":  # from the shop radio, failing (see failing_radio)
        x = failing_radio(x)
    elif name == "relogio":  # the take's ticks came unevenly spaced: rebuild a steady tick... tock, one a second
        env = np.convolve(np.abs(x), np.ones(64) / 64, "same")
        on = int(np.argmax(env > 0.5 * env.max()))
        tick = fade(x[max(0, on - int(0.01 * SR)):on + int(0.3 * SR)], 0.002, 0.08)
        tock = np.interp(np.arange(0, len(tick), 0.94), np.arange(len(tick)), tick)  # read slower: a touch lower
        x = np.zeros(2 * SR); x[:len(tick)] += tick; x[SR:SR + len(tock)] += 0.85 * tock
    elif kind not in LOOPS:  # one-shots: no click at the cut
        x = fade(x, 0.0, 0.08)
    x = x / (np.max(np.abs(x)) + 1e-9) * PEAK[kind if kind in PEAK else name]
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    print("%-18s %5.2fs" % (name, len(x) / SR))
