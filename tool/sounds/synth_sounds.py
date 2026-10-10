#!/usr/bin/env python3
"""Synthesises the sounds of the lullaby, bells, dinner and study rooms.

Everything is generated from sine waves and noise — no recordings, no
third-party samples — so the files are free to ship. Pure Python, no
dependencies:

    python3 tool/sounds/synth_sounds.py

Writes 16-bit mono 22 050 Hz WAV files into assets/sounds/.
"""

import math
import os
import random
import struct
import wave
from array import array

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'sounds')
TAU = 2 * math.pi


def write(name, samples, peak=0.85):
    top = max(1e-9, max(abs(s) for s in samples))
    scale = peak / top
    data = array('h', (int(max(-1.0, min(1.0, s * scale)) * 32767) for s in samples))
    path = os.path.join(OUT, name)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(f'{name:14} {len(samples) / RATE:5.2f} s')


def fade(samples, seconds_in=0.0, seconds_out=0.0):
    n_in, n_out = int(seconds_in * RATE), int(seconds_out * RATE)
    for i in range(min(n_in, len(samples))):
        samples[i] *= i / n_in
    for i in range(min(n_out, len(samples))):
        samples[-1 - i] *= i / n_out
    return samples


def note(name):
    """'A4' → 440.0; accepts sharps such as 'G#4'."""
    steps = {'C': -9, 'C#': -8, 'D': -7, 'D#': -6, 'E': -5, 'F': -4,
             'F#': -3, 'G': -2, 'G#': -1, 'A': 0, 'A#': 1, 'B': 2}
    return 440.0 * 2 ** ((steps[name[:-1]] + (int(name[-1]) - 4) * 12) / 12)


def ring(buf, start, freq, partials, amp, seconds, click=0.0, wrap=False):
    """Adds a struck, decaying tone. Partials are (ratio, level, decay/s)."""
    total = len(buf)
    for i in range(int(seconds * RATE)):
        t = i / RATE
        v = 0.0
        for ratio, level, decay in partials:
            v += level * math.exp(-decay * t) * math.sin(TAU * freq * ratio * t)
        if i < 50 and click:
            v += (random.random() * 2 - 1) * click * (1 - i / 50)
        j = start + i
        if wrap:
            j %= total
        elif j >= total:
            break
        buf[j] += amp * v


# ------------------------------------------------------------ music box

def music_box():
    """A slow waltz in A minor, nine and a half seconds, looping cleanly."""
    random.seed(3)
    beat = 0.4
    melody = [
        ('E5', 1), ('D5', 1), ('C5', 1),
        ('B4', 1), ('C5', 1), ('A4', 1),
        ('E5', 1), ('D5', 1), ('C5', 1),
        ('B4', 3),
        ('C5', 1), ('D5', 1), ('E5', 1),
        ('F5', 1), ('E5', 1), ('C5', 1),
        ('B4', 1), ('G#4', 1), ('B4', 1),
        ('A4', 3),
    ]
    bass = [('A3', 3), ('E3', 3), ('A3', 3), ('E3', 3),
            ('F3', 3), ('D3', 3), ('E3', 3), ('A3', 3)]
    tine = [(1.0, 1.0, 3.0), (2.0, 0.4, 5.5), (3.0, 0.16, 8.0),
            (4.16, 0.1, 11.0), (5.43, 0.05, 14.0)]

    total = int(beat * 24 * RATE)
    dry = [0.0] * total
    for line, level in ((melody, 1.0), (bass, 0.4)):
        t = 0
        for name, beats in line:
            # A music box is never quite in time.
            jitter = random.uniform(-0.012, 0.012)
            start = int(max(0.0, t * beat + jitter) * RATE)
            ring(dry, start, note(name) * random.uniform(0.997, 1.003), tine,
                 level, 2.4, click=0.25, wrap=True)
            t += beats

    # A small, damp room: two short echoes, wrapped so the loop is seamless.
    wet = dry[:]
    for delay, gain in ((0.083, 0.3), (0.127, 0.22), (0.191, 0.15)):
        d = int(delay * RATE)
        for i in range(total):
            wet[i] += gain * dry[i - d]
    write('musicbox.wav', [w * 0.8 for w in wet], peak=0.7)


# ------------------------------------------------------------ bells

def servant_bell(freq, name):
    """A small bell on a coiled spring: one strike and a few rattles."""
    random.seed(int(freq))
    length = int(1.7 * RATE)
    buf = [0.0] * length
    partials = [(1.0, 1.0, 3.0), (2.32, 0.55, 4.2), (4.25, 0.32, 6.0),
                (6.63, 0.18, 8.5), (9.38, 0.1, 11.0)]
    for t0, amp in ((0.0, 1.0), (0.085, 0.5), (0.165, 0.3), (0.24, 0.16)):
        ring(buf, int(t0 * RATE), freq, partials, amp, 1.6 - t0, click=0.5)
    write(name, fade(buf, 0.002, 0.08), peak=0.8)


# ------------------------------------------------------------ dinner

def plate():
    """A china plate set down on a table: a clink, a small settle."""
    random.seed(11)
    length = int(0.7 * RATE)
    buf = [0.0] * length
    china = [(1.0, 1.0, 18.0), (1.635, 0.7, 24.0), (2.376, 0.45, 30.0),
             (3.43, 0.25, 40.0), (0.508, 0.35, 14.0)]
    ring(buf, 0, 1780, china, 1.0, 0.6, click=0.6)
    ring(buf, int(0.072 * RATE), 1790, china, 0.35, 0.5, click=0.3)
    ring(buf, 0, 160, [(1.0, 1.0, 35.0)], 0.5, 0.3)
    write('plate.wav', fade(buf, 0.0, 0.05), peak=0.8)


def scrape():
    """A heavy chair dragged back over floorboards: stick and slip."""
    random.seed(5)
    length = int(0.95 * RATE)
    out = [0.0] * length
    x1 = x2 = y1 = y2 = 0.0
    next_slip = 0
    for i in range(length):
        t = i / RATE
        # Stick–slip impulses, plus a bed of friction noise.
        x = (random.random() * 2 - 1) * 0.25
        if i >= next_slip:
            x += random.uniform(0.7, 1.0)
            next_slip = i + int(RATE / random.uniform(32, 52))
        # Resonant band-pass sweeping up as the chair speeds up.
        f0 = 260 + 280 * min(1.0, t / 0.7) + 30 * math.sin(t * 23)
        w0 = TAU * f0 / RATE
        alpha = math.sin(w0) / (2 * 5.0)
        b0, a0 = alpha, 1 + alpha
        a1, a2 = -2 * math.cos(w0), 1 - alpha
        y = (b0 * x - b0 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1, y2, y1 = x1, x, y1, y
        env = min(1.0, t / 0.05) * min(1.0, (0.95 - t) / 0.15)
        out[i] = y * env
    write('scrape.wav', out, peak=0.75)


# ------------------------------------------------------------ study

def scribble():
    """A pen scratching a few quick words on paper."""
    random.seed(7)
    length = int(1.5 * RATE)
    buf = [0.0] * length
    t = 0.05
    while t < 1.35:
        dur = random.uniform(0.06, 0.16)
        start, n = int(t * RATE), int(dur * RATE)
        rate = random.uniform(25, 55)
        level = random.uniform(0.6, 1.0)
        prev = 0.0
        for i in range(n):
            x = random.random() * 2 - 1
            hp, prev = x - prev, x
            env = math.sin(math.pi * i / n) ** 0.7
            am = 0.6 + 0.4 * math.sin(TAU * rate * i / RATE)
            buf[start + i] += hp * env * am * level
        t += dur + random.uniform(0.02, 0.07)
    smooth = 0.0
    for i in range(length):
        smooth += 0.55 * (buf[i] - smooth)
        buf[i] = smooth
    write('scribble.wav', buf, peak=0.6)


if __name__ == '__main__':
    music_box()
    for freq, name in ((1318.5, 'bell_a.wav'), (1046.5, 'bell_b.wav'),
                       (880.0, 'bell_c.wav'), (659.3, 'bell_d.wav')):
        servant_bell(freq, name)
    plate()
    scrape()
    scribble()
