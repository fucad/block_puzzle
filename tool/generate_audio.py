#!/usr/bin/env python3
"""Generates every sound effect in assets/audio/ from scratch.

All audio is synthesized here — no samples, no third-party material — so
the results are original works released under CC BY like all other assets
(see PURPOSE.md). Re-run after tweaking:  python3 tool/generate_audio.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def env(i, n, attack=0.01, release=0.25):
    """Attack/release envelope over n samples."""
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (1.0 - t) / release) if release > 0 else 1.0
    return a * r


def tone(freqs, seconds, volume=0.5, attack=0.01, release=0.25, slide=0.0):
    """Sum of sines, optional exponential pitch slide (semitones/sec)."""
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / RATE
        s = 0.0
        mult = 2 ** (slide * t / 12)
        for f in freqs:
            s += math.sin(2 * math.pi * f * mult * t)
        out.append(volume * env(i, n, attack, release) * s / len(freqs))
    return out


def mix(*clips):
    n = max(len(c) for c in clips)
    return [sum(c[i] if i < len(c) else 0.0 for c in clips) for i in range(n)]


def delay(clip, seconds):
    return [0.0] * int(RATE * seconds) + clip


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.85 / peak if peak > 0.85 else 1.0
    with wave.open(str(OUT / name), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767))
                for s in samples
            )
        )
    print(f"wrote {name} ({len(samples) / RATE:.2f}s)")


# Soft wooden tap: placing a piece.
write("place.wav", tone([220, 440, 660], 0.07, 0.6, attack=0.002, release=0.9))

# Line clear: bright upward sweep.
write("clear.wav", tone([523, 659], 0.22, 0.5, slide=14, release=0.5))

# Combo: quick major-arpeggio chime (C E G).
write(
    "combo.wav",
    mix(
        tone([523], 0.10, 0.5, release=0.6),
        delay(tone([659], 0.10, 0.5, release=0.6), 0.06),
        delay(tone([784], 0.16, 0.5, release=0.7), 0.12),
    ),
)

# All-clear: little fanfare (C G C' E').
write(
    "allclear.wav",
    mix(
        tone([523, 1046], 0.12, 0.5, release=0.5),
        delay(tone([784, 1568], 0.12, 0.5, release=0.5), 0.10),
        delay(tone([1046, 2093], 0.28, 0.5, release=0.6), 0.20),
        delay(tone([1318, 2637], 0.34, 0.4, release=0.8), 0.30),
    ),
)

# Stage win: rising resolve.
write(
    "win.wav",
    mix(
        tone([392], 0.14, 0.5, release=0.5),
        delay(tone([523], 0.14, 0.5, release=0.5), 0.12),
        delay(tone([659, 1318], 0.4, 0.5, release=0.8), 0.24),
    ),
)

# Game over / stage lost: gentle descending pair.
write(
    "lose.wav",
    mix(
        tone([392, 784], 0.2, 0.4, release=0.6),
        delay(tone([311, 622], 0.42, 0.4, release=0.8), 0.18),
    ),
)
