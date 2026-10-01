"""Procedural soundtrack for Mahasigma Simulator (original, no samples).

Indonesian flavour: angklung-style shaken bamboo chords and bonang-style gong-chime
melodies on pentatonic scales, over a light pop/lo-fi groove.

    pip install numpy && python3 tools/gen_music.py      (needs ffmpeg for .ogg)

Outputs assets/audio/music/{kampus_pagi,kampus_malam,sedih,lulus}.ogg
Loops are rendered with their tails wrapped to the start, so they repeat seamlessly.
"""
import os
import subprocess
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "music")
rng = np.random.default_rng(7)

NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(name: str) -> float:
    """'A4' -> 440.0"""
    n, o = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((NOTE[n] + 12 * (o - 4) - 9) / 12)


def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


# --- Instruments -----------------------------------------------------------------

def angklung(f, dur, vel=1.0):
    """Shaken bamboo: octave pair of tubes rattling ~11 times per second."""
    t = t_axis(dur + 0.25)
    tone = np.sin(2 * np.pi * f * t) + 0.45 * np.sin(2 * np.pi * 2 * f * t) + 0.12 * np.sin(2 * np.pi * 3.01 * f * t)
    shake = 0.55 + 0.45 * np.abs(np.sin(np.pi * 11.0 * t + 0.3))
    env = np.minimum(1, t / 0.006) * np.where(t < dur, 1.0, np.exp(-(t - dur) * 14))
    return 0.22 * vel * tone * shake * env


def bonang(f, dur=1.2, vel=1.0):
    """Gong-chime: inharmonic metal partials with a long, shimmering decay."""
    t = t_axis(dur)
    parts = [(1.0, 1.0, 2.2), (2.01, 0.35, 4.0), (2.76, 0.22, 5.5), (5.4, 0.08, 9.0)]
    x = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * d) for r, a, d in parts)
    x *= 1 + 0.05 * np.sin(2 * np.pi * 5.5 * t)  # beating shimmer
    return 0.28 * vel * x * np.minimum(1, t / 0.002)


def bass(f, dur, vel=1.0):
    t = t_axis(dur + 0.08)
    x = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
    env = np.minimum(1, t / 0.01) * np.exp(-t * 1.6) * np.where(t < dur, 1, np.exp(-(t - dur) * 40))
    return 0.42 * vel * x * env


def pad(freqs, dur, vel=1.0):
    t = t_axis(dur + 0.6)
    x = np.zeros_like(t)
    for f in freqs:
        for det in (-0.004, 0.004):
            for k in range(1, 7):
                x += np.sin(2 * np.pi * f * (1 + det) * k * t + k) / k ** 1.8
    env = np.minimum(1, t / 0.35) * np.where(t < dur, 1, np.exp(-(t - dur) * 5))
    return 0.035 * vel * x * env


def epiano(f, dur, vel=1.0):
    """Two-operator FM electric piano."""
    t = t_axis(dur + 0.8)
    idx = 1.6 * np.exp(-t * 4)
    x = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * t))
    x += 0.15 * np.sin(2 * np.pi * 4 * f * t) * np.exp(-t * 12)
    env = np.minimum(1, t / 0.004) * np.exp(-t * 1.1) * np.where(t < dur, 1, np.exp(-(t - dur) * 6))
    return 0.16 * vel * x * env * (1 + 0.08 * np.sin(2 * np.pi * 4.5 * t))


def piano(f, dur, vel=1.0):
    t = t_axis(dur + 1.5)
    x = sum(np.sin(2 * np.pi * f * k * (1 + 0.0004 * k * k) * t) * np.exp(-t * (0.9 + 0.7 * k)) / k for k in range(1, 8))
    env = np.minimum(1, t / 0.003) * np.where(t < dur, 1, np.exp(-(t - dur) * 3))
    return 0.2 * vel * x * env


def brass(f, dur, vel=1.0):
    t = t_axis(dur + 0.2)
    bright = np.minimum(1, t / 0.08)
    x = sum(np.sin(2 * np.pi * f * k * t) * (bright ** (k * 0.4)) / k for k in range(1, 9))
    env = np.minimum(1, t / 0.03) * np.where(t < dur, 1, np.exp(-(t - dur) * 10))
    return 0.11 * vel * x * env


def kick(vel=1.0):
    t = t_axis(0.45)
    f = 45 + 95 * np.exp(-t * 28)
    return 0.7 * vel * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7)


def snare(vel=1.0):
    t = t_axis(0.25)
    n = rng.standard_normal(len(t))
    return vel * (0.22 * n * np.exp(-t * 22) + 0.25 * np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25))


def clap(vel=1.0):
    t = t_axis(0.22)
    n = rng.standard_normal(len(t))
    bursts = sum(np.exp(-np.maximum(0, t - d) * 60) * (t >= d) for d in (0, 0.01, 0.022))
    return 0.16 * vel * n * bursts * np.exp(-t * 14)


def hat(vel=1.0, open_=False):
    t = t_axis(0.18 if open_ else 0.06)
    n = np.diff(rng.standard_normal(len(t) + 1))
    return 0.06 * vel * n * np.exp(-t * (18 if open_ else 70))


def shaker(vel=1.0):
    t = t_axis(0.09)
    n = np.diff(rng.standard_normal(len(t) + 1))
    return 0.045 * vel * n * np.minimum(1, t / 0.02) * np.exp(-t * 35)


# --- Mixing helpers ----------------------------------------------------------------

class Track:
    def __init__(self, bpm, bars, beats=4, tail=4.0):
        self.spb = 60.0 / bpm
        self.length = int(bars * beats * self.spb * SR)
        self.buf = np.zeros((self.length + int(tail * SR), 2))

    def at(self, beat):
        return int(beat * self.spb * SR)

    def add(self, x, beat, pan=0.0, gain=1.0):
        i = self.at(beat)
        x = x * gain
        lg, rg = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        end = min(len(self.buf), i + len(x))
        self.buf[i:end, 0] += x[: end - i] * lg
        self.buf[i:end, 1] += x[: end - i] * rg

    def render(self, loop=True, reverb=0.25, room=1.6):
        out = self.buf.copy()
        if reverb > 0:
            n = int(room * SR)
            tt = np.arange(n) / SR
            for ch in range(2):
                ir = rng.standard_normal(n) * np.exp(-tt * 6.0 / room)
                ir[0] = 0
                wet = np.fft.irfft(np.fft.rfft(out[:, ch], len(out) + n) * np.fft.rfft(ir, len(out) + n))[: len(out)]
                out[:, ch] += reverb * wet / np.sqrt(np.sum(ir ** 2)) * 0.35
        if loop:
            body = out[: self.length].copy()
            tail = out[self.length:]
            k = min(len(tail), len(body))
            body[:k] += tail[:k]
            out = body
        # Gentle bus compression + normalize to -1.5 dBFS.
        out = np.tanh(out * 1.2) / np.tanh(1.2)
        out *= 0.84 / max(1e-9, np.max(np.abs(out)))
        return out


def save(name, data):
    os.makedirs(OUT, exist_ok=True)
    wav = os.path.join(OUT, name + ".wav")
    pcm = (np.clip(data, -1, 1) * 32767).astype("<i2")
    import wave
    with wave.open(wav, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    ogg = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", ogg], check=True)
    os.remove(wav)
    print(name, f"{len(data) / SR:.1f}s", f"{os.path.getsize(ogg) // 1024} KB")


CHORDS = {
    "C": ["C", "E", "G"], "Am": ["A", "C", "E"], "F": ["F", "A", "C"], "G": ["G", "B", "D"],
    "Dm": ["D", "F", "A"], "Em": ["E", "G", "B"], "E": ["E", "G#", "B"],
    "Am7": ["A", "C", "E", "G"], "Fmaj7": ["F", "A", "C", "E"], "Cmaj7": ["C", "E", "G", "B"], "G6": ["G", "B", "D", "E"],
    "Dm7": ["D", "F", "A", "C"], "Em7": ["E", "G", "B", "D"],
}


def chord(name, octave):
    return [hz(n + str(octave + (1 if NOTE[n] < NOTE[CHORDS[name][0]] else 0))) for n in CHORDS[name]]


# --- Tracks --------------------------------------------------------------------------

def kampus_pagi():
    """Title / daytime campus: bright, bouncy, angklung + bonang over a pop groove."""
    tr = Track(bpm=104, bars=16)
    prog = ["C", "Am", "F", "G"] * 3 + ["F", "G", "Em", "Am"]
    pent = ["C5", "D5", "E5", "G5", "A5", "C6"]
    motif_a = [(0, "E5", 1), (1, "G5", 0.5), (1.5, "A5", 0.5), (2, "G5", 1), (3, "E5", 0.5), (3.5, "D5", 0.5),
               (4, "C5", 1.5), (6, "D5", 0.5), (6.5, "E5", 0.5), (7, "G5", 1)]
    motif_b = [(0, "A5", 1), (1, "G5", 0.5), (1.5, "E5", 0.5), (2, "D5", 1), (3, "E5", 1),
               (4, "G5", 0.5), (4.5, "A5", 0.5), (5, "C6", 1), (6, "A5", 1), (7, "G5", 1)]
    for bar, ch in enumerate(prog):
        b0 = bar * 4
        notes = chord(ch, 4)
        root = hz(CHORDS[ch][0] + "2")
        # Bass: root, fifth, octave bounce.
        for beat, mult, d in [(0, 1, 0.9), (1.5, 1.5, 0.4), (2, 1, 0.9), (3, 2, 0.4), (3.5, 1.5, 0.4)]:
            tr.add(bass(root * mult, d * tr.spb), b0 + beat, 0.0, 0.9)
        # Angklung: each "player" shakes one chord tone, interlocking 8ths.
        for i in range(8):
            n = notes[[0, 2, 1, 2, 0, 2, 1, 2][i]]
            tr.add(angklung(n, 0.42 * tr.spb, 0.9 if i % 2 == 0 else 0.7), b0 + i * 0.5, [-0.4, 0.4][i % 2])
        tr.add(pad(chord(ch, 3), 4 * tr.spb, 0.8), b0, 0.0)
        # Drums (lighter in the first 4 bars).
        full = bar >= 4
        tr.add(kick(), b0)
        tr.add(kick(0.8), b0 + 2.5 if full else b0 + 2)
        if full:
            tr.add(clap(), b0 + 1, 0.1)
            tr.add(clap(), b0 + 3, -0.1)
        for i in range(8):
            tr.add(shaker(1.0 if i % 2 else 0.6), b0 + i * 0.5, 0.5)
    # Bonang melody in bars 4-15.
    for phrase in range(3):
        start = (4 + phrase * 4) * 4
        motif = motif_a if phrase != 1 else motif_b
        for beat, note, d in motif:
            tr.add(bonang(hz(note), 1.4), start + beat, -0.2, 0.8)
            tr.add(bonang(hz(note) * 2, 0.6), start + beat + 0.25, 0.3, 0.18)  # echo an octave up
    return tr.render(loop=True, reverb=0.22)


def kampus_malam():
    """Night / planning / bureaucracy: lo-fi swing, FM piano, sparse bonang."""
    tr = Track(bpm=78, bars=16)
    prog = ["Am7", "Fmaj7", "Cmaj7", "G6"] * 3 + ["Dm7", "Em7", "Fmaj7", "G6"]
    mel = ["A5", "C6", "D6", "E6", "G5"]
    swing = 0.08
    for bar, ch in enumerate(prog):
        b0 = bar * 4
        notes = chord(ch, 4)
        for beat in (0, 2.5):
            for j, f in enumerate(notes):
                tr.add(epiano(f, 1.6 * tr.spb, 0.8), b0 + beat + j * 0.012, -0.3 + 0.2 * j)
        root = hz(CHORDS[ch][0] + "2")
        tr.add(bass(root, 1.8 * tr.spb, 1.0), b0)
        tr.add(bass(root, 1.2 * tr.spb, 0.8), b0 + 2.5)
        tr.add(kick(0.9), b0)
        tr.add(kick(0.6), b0 + 1.75)
        tr.add(snare(0.7), b0 + 1, 0.1)
        tr.add(snare(0.7), b0 + 3, 0.1)
        for i in range(8):
            tr.add(hat(0.8 if i % 2 == 0 else 0.5), b0 + i * 0.5 + (swing if i % 2 else 0), 0.35)
        if bar % 2 == 1:
            for k in range(3):
                tr.add(bonang(hz(mel[(bar + k * 2) % len(mel)]), 1.6, 0.5), b0 + 1 + k * 1.0 + 0.5 * (k == 2), 0.25)
    out = tr.render(loop=True, reverb=0.3, room=2.0)
    crackle = np.zeros(len(out))
    pos = rng.integers(0, len(out), size=int(len(out) / SR * 9))
    crackle[pos] = rng.uniform(-0.25, 0.25, size=len(pos))
    crackle = np.convolve(crackle, np.exp(-np.arange(40) / 6.0), mode="same")
    out[:, 0] += crackle * 0.6
    out[:, 1] += crackle * 0.6
    out += rng.standard_normal(out.shape) * 0.003  # tape hiss
    return out * (0.84 / np.max(np.abs(out)))


def sedih():
    """Sad endings: slow minor piano with a distant bonang, gentle and hopeful at the end."""
    tr = Track(bpm=64, bars=16)
    prog = ["Am", "F", "C", "G", "Am", "F", "Dm", "E", "F", "G", "Em", "Am", "F", "G", "C", "C"]
    mel = {0: "E5", 1: "C5", 2: "G5", 3: "D5", 4: "E5", 5: "A5", 6: "F5", 7: "G#5", 8: "A5", 9: "B5", 10: "G5", 11: "E5", 12: "C6", 13: "B5", 14: "G5", 15: "E5"}
    for bar, ch in enumerate(prog):
        b0 = bar * 4
        notes = chord(ch, 3) + [chord(ch, 4)[0]]
        for i in range(8):
            tr.add(piano(notes[[0, 1, 2, 3, 2, 1, 2, 1][i]], 0.9 * tr.spb, 0.55), b0 + i * 0.5, -0.2 + 0.1 * (i % 3))
        tr.add(piano(hz(CHORDS[ch][0] + "2"), 3.5 * tr.spb, 0.7), b0, -0.1)
        tr.add(piano(hz(mel[bar]), 2.0 * tr.spb, 0.75), b0 + 1, 0.15)
        tr.add(pad(chord(ch, 3), 4 * tr.spb, 0.6), b0)
        if bar % 4 == 3:
            tr.add(bonang(hz(mel[bar]) / 2, 2.5, 0.35), b0 + 3, 0.4)
    return tr.render(loop=True, reverb=0.45, room=2.6)


def lulus():
    """Graduation stinger: brass + bonang fanfare and an angklung shimmer."""
    tr = Track(bpm=120, bars=2, tail=2.5)
    for beat, n in [(0, "C5"), (0.5, "E5"), (1, "G5"), (1.5, "C6")]:
        tr.add(brass(hz(n), 0.45 * tr.spb, 0.9), beat, -0.1)
        tr.add(bonang(hz(n), 1.2, 0.6), beat, 0.25)
    for f in chord("C", 4) + [hz("C6"), hz("E6")]:
        tr.add(brass(f, 3.0 * tr.spb, 0.7), 2)
    for i in range(12):
        tr.add(angklung(chord("C", 5)[i % 3], 0.2, 0.6), 2 + i * 0.25, [-0.5, 0.5][i % 2])
    tr.add(kick(), 2)
    tr.add(clap(1.2), 2)
    for b in (2, 2.25, 2.5):
        tr.add(bonang(hz("C6"), 2.0, 0.5), b, 0.3)
    return tr.render(loop=False, reverb=0.3)


if __name__ == "__main__":
    save("kampus_pagi", kampus_pagi())
    save("kampus_malam", kampus_malam())
    save("sedih", sedih())
    save("lulus", lulus())
