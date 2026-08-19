#!/usr/bin/env python3
"""
Generates Fiat Cor's click sounds.

Four short synthetic clicks — no sample library, no licensing questions.
Run:  python3 tools/make_clicks.py
Writes to qml/sounds/.

The timbre: a fast-decaying tone with a little harmonic body, plus a very
short noise transient that gives the actual "tick". The attack is
effectively instant (a 0.3 ms ramp only to avoid an aliasing snap), the
decay is exponential. Everything stays under 60 ms so SoundEffect can
retrigger on fast subdivisions without queueing.

The four voices form a pitch and level hierarchy, so a bar reads as a
shape rather than as a row of identical taps:

    strong (downbeat)  high  and loud
    medium (secondary) mid   and present
    normal             low   and quiet
    subdivision        low, dry and very quiet
"""

import math
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "qml", "sounds")

# name, fundamental (Hz), decay tau (s), length (s), noise share, peak level
VOICES = [
    # Downbeat: brightest and loudest — has to carry across a room.
    ("click-strong.wav", 1568.0, 0.011, 0.055, 0.30, 0.92),
    # Secondary accent: a minor third below the downbeat. Clearly a stress,
    # clearly not the one.
    ("click-medium.wav", 1318.5, 0.010, 0.050, 0.28, 0.80),
    # Plain beat: a fifth below the downbeat, subordinate.
    ("click-normal.wav", 1046.5, 0.013, 0.055, 0.26, 0.62),
    # Subdivision: same pitch as the plain beat but drier and much quieter,
    # so the pulse still reads as pulse and not as extra beats.
    ("click-sub.wav",    1046.5, 0.007, 0.035, 0.22, 0.30),
]


def render(freq, tau, length, noise_mix, peak, seed):
    n = int(SR * length)
    t = np.arange(n) / SR

    env = np.exp(-t / tau)

    # Tone with some harmonic body. The second partial gives "wood",
    # the third gives bite.
    tone = (np.sin(2 * math.pi * freq * t)
            + 0.35 * np.sin(2 * math.pi * freq * 2 * t) * np.exp(-t / (tau * 0.6))
            + 0.15 * np.sin(2 * math.pi * freq * 3 * t) * np.exp(-t / (tau * 0.4)))
    tone /= 1.5

    # Noise transient: only the first few milliseconds. This is what makes
    # the ear hear an attack rather than a beep.
    rng = np.random.default_rng(seed)
    noise = rng.uniform(-1.0, 1.0, n) * np.exp(-t / 0.0018)

    sig = (1.0 - noise_mix) * tone + noise_mix * noise
    sig *= env

    # 0.3 ms attack ramp — prevents a hard discontinuity at sample 0.
    ramp_n = max(1, int(SR * 0.0003))
    sig[:ramp_n] *= np.linspace(0.0, 1.0, ramp_n)

    # 2 ms fade-out so the file does not end mid-oscillation.
    fade_n = max(1, int(SR * 0.002))
    sig[-fade_n:] *= np.linspace(1.0, 0.0, fade_n)

    m = np.max(np.abs(sig))
    if m > 0:
        sig = sig / m * peak
    return sig


def write_wav(path, sig):
    pcm = (np.clip(sig, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, (name, freq, tau, length, noise_mix, peak) in enumerate(VOICES):
        sig = render(freq, tau, length, noise_mix, peak, seed=1234 + i)
        write_wav(os.path.join(OUT, name), sig)
        print("wrote %-20s %5d frames  %5.1f ms  peak %.2f"
              % (name, len(sig), 1000.0 * len(sig) / SR, np.max(np.abs(sig))))


if __name__ == "__main__":
    main()
