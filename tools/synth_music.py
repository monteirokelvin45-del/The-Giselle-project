#!/usr/bin/env python3
"""Sintetiza a banda sonora do jogo (exploração / combate / Sistema).

11025 Hz · mono · 16-bit PCM — ficheiros leves, fazem loop sem costuras.
Execução: python3 tools/synth_music.py
"""
import math
import wave
import os
import numpy as np

SR = 11025
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "music")

def t_arr(dur):
    return np.arange(int(SR * dur), dtype=np.float32) / SR

def sine(freq: float, dur: float, amp: float = 1.0, phase: float = 0.0):
    return amp * np.sin(2 * np.pi * freq * t_arr(dur) + phase).astype(np.float32)

def lowpass_fft(x: np.ndarray, cutoff: float) -> np.ndarray:
    X = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), d=1.0 / SR)
    X[freqs > cutoff] = 0.0
    return np.fft.irfft(X, len(x)).astype(np.float32)

def highpass_fft(x: np.ndarray, cutoff: float) -> np.ndarray:
    X = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), d=1.0 / SR)
    X[freqs < cutoff] = 0.0
    return np.fft.irfft(X, len(x)).astype(np.float32)

def exp_decay(t, tau: float):
    return np.exp(-t / tau).astype(np.float32)

def adsr(n: int, attack: float, decay: float, sustain: float, release: float, sustain_level: float = 0.7):
    env = np.ones(n, dtype=np.float32)
    a = int(SR * attack); d = int(SR * decay); r = int(SR * release)
    if a > 0:
        env[:a] = np.linspace(0.0, 1.0, a, dtype=np.float32)
    if a + d < n:
        env[a:a + d] = np.linspace(1.0, sustain_level, d, dtype=np.float32)
        env[a + d:] = sustain_level
    if r > 0 and r < n:
        env[-r:] *= np.linspace(sustain_level, 0.0, r, dtype=np.float32)
    return env

def write_wav(name: str, samples: np.ndarray):
    samples = samples / max(1e-9, float(np.abs(samples).max())) * 0.55
    pcm = (samples * 32767).astype(np.int16)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print("wrote", path, f"({len(pcm) / SR:.1f}s)")

# ------------------------------------------------------- exploração (Am) -----
def exploration():
    dur = 40.0
    t = t_arr(dur)
    mix = np.zeros_like(t)
    chords = [  # Am · F · C · G — 10 s cada
        (55.00, 110.00, 164.81), (43.65, 87.31, 174.61),
        (65.41, 130.81, 196.00), (49.00, 98.00, 146.83),
    ]
    seg_t = dur / 4.0
    seg = int(SR * seg_t)
    for i, (root, third, fifth) in enumerate(chords):
        for j, freq in enumerate((root, third, fifth)):
            s = sine(freq, seg_t, amp=0.32 - 0.06 * j)
            s += sine(freq * 2.001, seg_t, amp=0.07)     # shimmer subtil detune
            s *= adsr(len(s), attack=1.8, decay=0.5, sustain=0.0, release=2.5, sustain_level=0.82)
            mix[i * seg:(i + 1) * seg] += s
    # Arpejo de sinos — uma nota a cada ~3.3 s
    bells = [440.00, 523.25, 659.25, 783.99, 659.25, 523.25, 587.33, 659.25, 440.00, 392.00, 440.00, 523.25]
    step = dur / len(bells)
    for i, freq in enumerate(bells):
        start = int(i * step * SR)
        note = sine(freq, 4.5, amp=0.16) + sine(freq * 2.0, 4.5, amp=0.05)
        note *= exp_decay(t_arr(4.5), 1.1)
        end = min(start + len(note), len(mix))
        mix[start:end] += note[:end - start]
    # Vento: ruído filtrado muito baixo
    noise = np.random.default_rng(7).standard_normal(len(t)).astype(np.float32)
    wind = lowpass_fft(noise, 320.0) * 0.05
    wind *= 0.6 + 0.4 * np.sin(2 * np.pi * 0.05 * t)
    mix += wind
    write_wav("exploration.wav", mix)

# ----------------------------------------------------------- combate (Dm) -----
def combat():
    bpm = 100.0
    beat = 60.0 / bpm
    bars = 16
    total = 4 * bars * beat
    mix = np.zeros_like(t_arr(total))
    # Baixo: D2, D2, F2, C2 a cada dois tempos
    bass_freqs = [73.42, 73.42, 87.31, 65.41]
    step = beat * 2
    for i in range(int(total / step)):
        freq = bass_freqs[(i % 4)]
        start = int(i * step * SR)
        note = lowpass_fft(np.sign(np.sin(2 * np.pi * freq * t_arr(0.24))).astype(np.float32), 720.0) * 0.42
        note *= exp_decay(t_arr(0.24), 0.09)
        end = min(start + len(note), len(mix))
        mix[start:end] += note[:end - start]
    # Kick em todos os tempos
    for i in range(int(total / beat)):
        start = int(i * beat * SR)
        tt = t_arr(0.22)
        kick = np.sin(2 * np.pi * (58.0 * np.exp(-tt * 14.0) + 40.0) * tt).astype(np.float32)
        kick *= exp_decay(tt, 0.075) * 0.85
        end = min(start + len(kick), len(mix))
        mix[start:end] += kick[:end - start]
    # Hats nos contratempos
    rng = np.random.default_rng(11)
    for i in range(int(total / (beat / 2))):
        if i % 2 == 0:
            continue
        start = int(i * (beat / 2) * SR)
        hat = highpass_fft(rng.standard_normal(int(0.045 * SR)).astype(np.float32), 5200.0) * 0.22
        hat *= exp_decay(t_arr(0.045), 0.012)
        end = min(start + len(hat), len(mix))
        mix[start:end] += hat[:end - start]
    # Acorde de ataque a cada 4 compassos (Dm)
    for bar in (0, 4, 8, 12):
        start = int(bar * 4 * beat * SR)
        stab = np.zeros(int(0.5 * SR), dtype=np.float32)
        for freq in (146.83, 174.61, 220.00):
            stab += lowpass_fft((np.sign(np.sin(2 * np.pi * freq * t_arr(0.5)))).astype(np.float32), 1500.0) * 0.16
        stab *= exp_decay(t_arr(0.5), 0.16)
        end = min(start + len(stab), len(mix))
        mix[start:end] += stab[:end - start]
    write_wav("combat.wav", mix)

# ------------------------------------------------------------- Sistema --------
def system():
    dur = 40.0
    t = t_arr(dur)
    mix = np.zeros_like(t)
    for freq, amp in ((55.0, 0.30), (82.41, 0.18), (110.0, 0.10)):
        s = sine(freq, dur, amp=amp)
        s *= 0.75 + 0.25 * np.sin(2 * np.pi * 0.05 * t + 1.0)
        mix += s
    # Cluster agudo com batimento (9 Hz) — inquietante
    for freq, amp in ((1244.5, 0.045), (1253.5, 0.045), (1661.0, 0.022)):
        s = sine(freq, dur, amp=amp)
        s *= 0.4 + 0.6 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t))
        mix += s
    # Sinos graves espaçados
    for start_s in (2.0, 15.0, 28.0):
        start = int(start_s * SR)
        note = sine(82.41, 6.0, amp=0.2) + sine(164.81, 6.0, amp=0.07)
        note *= exp_decay(t_arr(6.0), 1.6)
        end = min(start + len(note), len(mix))
        mix[start:end] += note[:end - start]
    noise = np.random.default_rng(23).standard_normal(len(t)).astype(np.float32)
    mix += lowpass_fft(noise, 180.0) * 0.04
    write_wav("system.wav", mix)

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    exploration()
    combat()
    system()
