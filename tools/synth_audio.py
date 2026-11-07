import math, wave, struct, random, os
SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)

def write(name, samples):
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples))
    print("wrote", path)

def env(i, n, attack=0.005, release=0.3):
    t = i / SR
    total = n / SR
    a = min(1.0, t / max(attack, 1e-4))
    r = min(1.0, (total - t) / max(release, 1e-4))
    return a * max(0.0, r)

def tone(freq_fn, dur, vol=0.6, wave_fn=math.sin):
    n = int(dur * SR); out = []
    for i in range(n):
        t = i / SR
        f = freq_fn(t) if callable(freq_fn) else freq_fn
        out.append(vol * env(i, n, 0.005, dur * 0.6) * wave_fn(2 * math.pi * f * t))
    return out

def noise(dur, vol=0.4, lp_start=4000, lp_end=400):
    n = int(dur * SR); out = []; prev = 0.0
    for i in range(n):
        t = i / SR
        k = lp_end + (lp_start - lp_end) * (1 - t / dur)
        alpha = min(1.0, k / SR * 2 * math.pi)
        prev = prev + alpha * (random.uniform(-1, 1) - prev)
        out.append(vol * env(i, n, 0.002, dur * 0.7) * prev)
    return out

def mix(*tracks):
    n = max(len(t) for t in tracks); out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    peak = max(abs(s) for s in out) or 1.0
    return [s / max(1.0, peak) * 0.9 for s in out]

random.seed(42)
write("swing", mix(noise(0.18, 0.5, 2500, 300), tone(lambda t: 420 - 900 * t, 0.16, 0.25)))
write("hit", mix(tone(lambda t: 150 - 260 * t, 0.2, 0.8), noise(0.08, 0.5, 3000, 500)))
write("heavy_hit", mix(tone(lambda t: 105 - 160 * t, 0.3, 0.9), noise(0.12, 0.6, 2500, 300)))
write("parry", mix(tone(2350, 0.32, 0.45), tone(3130, 0.28, 0.3), tone(4520, 0.2, 0.2)))
write("posture_break", mix(tone(lambda t: 1500 - 800 * t, 0.5, 0.4), noise(0.35, 0.4, 5000, 200)))
write("potion", mix(tone(660, 0.1, 0.4), [0.0] * int(0.08 * SR) + tone(990, 0.14, 0.4)))
write("rupture", mix(tone(lambda t: 80 + 260 * t * t, 0.9, 0.7, lambda x: math.copysign(abs(math.sin(x)) ** 0.6, math.sin(x))), noise(0.9, 0.25, 800, 4000)))
write("quest_done", sum(([0.0] * int(d * SR) + tone(f, 0.35, 0.45) for d, f in zip([0, 0.12, 0.24, 0.36], [523, 659, 784, 1047])), []))
write("levelup", sum(([0.0] * int(d * SR) + tone(f, 0.4, 0.45) for d, f in zip([0, 0.13, 0.26, 0.39], [392, 523, 659, 784])), []))
write("click", tone(1750, 0.06, 0.3))
write("herb", mix(tone(1200, 0.09, 0.35), [0.0] * int(0.07 * SR) + tone(1600, 0.12, 0.3)))
write("death", tone(lambda t: 300 - 230 * t, 1.1, 0.6))
print("done")
