# Shared pieces of the sound tools (tools/sons): writing the WAVs the game loads and the filters they all use.
import os, wave
import numpy as np
from scipy import signal
import paths


def write_wav(name, x, sr, peak=None, folder=paths.SOUNDS, eps=0.0):
    """Mono 16-bit <folder>/<name>.wav; peak: normalise to it first (eps keeps a silent clip from dividing by 0)."""
    x = np.asarray(x, dtype=float)
    if peak is not None:
        x = x / (np.max(np.abs(x)) + eps) * peak
    os.makedirs(folder, exist_ok=True)
    with wave.open(os.path.join(folder, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    return x


def sos(kind, f, sr, order=2):
    """A Butterworth filter as second-order sections: kind lowpass/highpass/bandpass, f a cutoff or [lo, hi]."""
    return signal.butter(order, f, kind, fs=sr, output="sos")
