"""cs_synth.py - mini biblioteca de sintese (so numpy + scipy) para as musicas de
"Cavaleira de Seda". Sem samples, sem MIDI, tudo calculado.

Ideias principais
-----------------
* Song: acumula eventos num buffer "seco" + barramentos de reverb. No fim,
  render() convolui os envios com uma resposta de impulso sintetica e DOBRA a
  cauda de volta sobre o comeco (wrap), entao o loop emenda sem clique.
* Song.bed(): camadas continuas (ruido, drones) feitas com crossfade circular.
* master(): normaliza em LUFS (K-weighting BS.1770) e limita o pico.
"""
import os
import shutil
import subprocess
from functools import lru_cache

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
PEAK_DB = -1.5          # margem interna; o codec Vorbis pode "estourar" ~0.3 dB
RNG = np.random.default_rng(0)


def reseed(seed):
    """Semente fixa por faixa -> resultado 100% reprodutivel."""
    global RNG
    RNG = np.random.default_rng(seed)


# ----------------------------------------------------------------- notas ----
_NN = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def midi(x):
    if not isinstance(x, str):
        return x
    p = _NN[x[0]]
    i = 1
    while x[i] in '#b':
        p += 1 if x[i] == '#' else -1
        i += 1
    return 12 * (int(x[i:]) + 1) + p


def hz(x):
    return 440.0 * 2.0 ** ((midi(x) - 69) / 12.0)


SHAPES = {
    'min': [0, 3, 7], 'maj': [0, 4, 7], 'sus4': [0, 5, 7], 'dim': [0, 3, 6],
    'min7': [0, 3, 7, 10], 'dom7': [0, 4, 7, 10], 'maj7': [0, 4, 7, 11],
    'pow': [0, 7, 12], 'maj9': [0, 4, 7, 14], 'min9': [0, 3, 7, 14],
}


def chord(root, kind='min'):
    r = midi(root)
    return [r + i for i in SHAPES[kind]]


# Temas (nota, duracao em tempos de semínima)
CAV = [('D4', 1), ('F4', 1), ('A4', 2), ('G4', .5), ('F4', .5), ('E4', 1),
       ('D4', 1), ('C4', 1), ('D4', 2)]
EXP = [('A3', .75), ('A3', .25), ('C4', 1), ('D4', 1), ('E4', 1),
       ('E4', .75), ('D4', .25), ('C4', 1), ('A3', 2)]


def transp(items, semis):
    return [((midi(it[0]) + semis) if it[0] is not None else None,) + tuple(it[1:])
            for it in items]


# ------------------------------------------------------------- envelopes ----
def tt(n):
    return np.arange(n) / SR


def fade(x, a=0.003, r=0.01):
    x = x.copy()
    n = len(x)
    na = min(n // 2, int(a * SR))
    nr = min(n // 2, int(r * SR))
    if na > 1:
        x[:na] *= np.linspace(0, 1, na)
    if nr > 1:
        x[n - nr:] *= np.linspace(1, 0, nr)
    return x


def env_ar(n, a, r):
    """ataque e release suaves (cosseno); sustenta no meio."""
    e = np.ones(n)
    na = max(1, min(n // 2, int(a * SR)))
    nr = max(1, min(n // 2, int(r * SR)))
    e[:na] = 0.5 - 0.5 * np.cos(np.pi * np.arange(na) / na)
    e[n - nr:] *= 0.5 + 0.5 * np.cos(np.pi * (np.arange(nr) + 1) / nr)
    return e


def exp_dec(n, tau):
    return np.exp(-np.arange(n) / (tau * SR))


def nrm(x, p=1.0):
    m = np.max(np.abs(x))
    return x * (p / m) if m > 1e-9 else x


# ------------------------------------------------------------ osciladores ----
def _fa(freq, n):
    return np.full(n, float(freq)) if np.isscalar(freq) else np.asarray(freq, float)


def osc_sine(freq, n=None, ph0=0.0):
    f = _fa(freq, n)
    return np.sin(2 * np.pi * (np.cumsum(f) / SR + ph0))


def osc_saw(freq, n=None, ph0=None):
    f = _fa(freq, n)
    if ph0 is None:
        ph0 = RNG.random()
    p = np.cumsum(f) / SR + ph0
    return 2 * (p - np.floor(p)) - 1


def pphase(freq):
    """fase (ciclos) periodica: corrige a fase para fechar numero inteiro de
    ciclos em len(freq) amostras -> drone com frequencia variavel emenda no loop."""
    n = len(freq)
    p = np.cumsum(freq) / SR
    total = p[-1]
    p0 = p - freq / SR
    return p0 - (total - np.round(total)) * np.arange(n) / n


# ---------------------------------------------------------------- filtros ----
@lru_cache(maxsize=None)
def _sos(kind, f, order, f2=0):
    if kind == 'bandpass':
        return signal.butter(order, [f, f2], 'bandpass', fs=SR, output='sos')
    return signal.butter(order, f, kind, fs=SR, output='sos')


def _c(f):
    return int(min(max(f, 20), 20000))


def lp(x, f, order=2):
    return signal.sosfilt(_sos('lowpass', _c(f), order), x)


def hp(x, f, order=2):
    return signal.sosfilt(_sos('highpass', _c(f), order), x)


def bp(x, lo, hi, order=2):
    lo, hi = _c(lo), _c(hi)
    if hi <= lo + 5:
        hi = lo + 10
    return signal.sosfilt(_sos('bandpass', lo, order, hi), x)


def white(n):
    return RNG.standard_normal(n)


# ------------------------------------------------------------- instrumentos --
def bell(f, dur=2.5, ratios=(1, 2.76, 5.40, 8.93), amps=(1, .45, .22, .10),
         bright=1.0, fall=1.0):
    """caixinha de musica / vidro / sino: parciais inarmonicos, decaimento."""
    n = int(dur * SR)
    t = tt(n)
    x = np.zeros(n)
    for k, (r, a) in enumerate(zip(ratios, amps)):
        fr = f * r
        if fr > 16000:
            continue
        tau = dur / (5.0 + 2.0 * k) * fall
        x += a * (bright ** k) * np.sin(2 * np.pi * fr * t) * np.exp(-t / tau)
    return nrm(fade(x, .002, .06))


def marimba(f, dur=1.5):
    n = int(dur * SR)
    t = tt(n)
    x = (np.sin(2 * np.pi * f * t) * np.exp(-t / (dur / 5)) +
         .38 * np.sin(2 * np.pi * f * 3.93 * t) * np.exp(-t / (dur / 12)) +
         .10 * np.sin(2 * np.pi * f * 9.0 * t) * np.exp(-t / (dur / 25)))
    x += .12 * bp(white(n), 1800, 5000) * np.exp(-t / .012)
    return nrm(fade(x, .001, .08))


def drop(f, dur=.5):
    """gota d'agua afinada: pluck curto com leve glissando ascendente."""
    n = int(dur * SR)
    t = tt(n)
    fr = f * (1 - .06 * np.exp(-t / .05))
    ph = 2 * np.pi * np.cumsum(fr) / SR
    x = np.sin(ph) * np.exp(-t / .11) + .25 * np.sin(2 * ph) * np.exp(-t / .05)
    return nrm(fade(x, .002, .06))


def harp(f, dur=2.0):
    n = int(dur * SR)
    t = tt(n)
    x = np.zeros(n)
    for k in range(1, 8):
        if f * k > 14000:
            break
        x += (1 / k ** 1.15) * np.sin(2 * np.pi * f * k * t * (1 + .0004 * k * k)) * \
            np.exp(-t / (dur / (3.0 + 1.4 * k)))
    x += .15 * bp(white(n), 2000, 6000) * np.exp(-t / .008)
    return nrm(fade(x, .001, .1))


def _saws(f, n, dets, vib=None):
    x = np.zeros(n)
    for c in dets:
        fr = (f * vib if vib is not None else f) * 2 ** (c / 1200)
        x += osc_saw(fr, n)
    return x / len(dets)


def pad(f, dur, a=1.2, r=2.0, cut=1500, dets=(-9, 0, 9), sub=0.0):
    n = int((dur + r) * SR)
    x = lp(_saws(f, n, dets), cut, 2)
    if sub:
        x += sub * osc_sine(f / 2, n)
    return nrm(x * env_ar(n, a, r))


def string(f, dur, a=.12, r=.4, cut=3000, vib=5.3, vdepth=.0035, dets=(-7, 0, 7)):
    n = int((dur + r) * SR)
    t = tt(n)
    v = 1 + vdepth * np.sin(2 * np.pi * vib * t + RNG.random() * 6.28) * np.minimum(1, t / .4)
    x = lp(_saws(f, n, dets, v), cut, 2)
    return nrm(x * env_ar(n, a, r))


def bass(f, dur, cut=600, a=.005, r=.08, decay=None, sub=.6):
    n = int((dur + r) * SR)
    x = lp(osc_saw(f, n), cut, 2) + sub * osc_sine(f, n)
    e = env_ar(n, a, r)
    if decay:
        e = e * exp_dec(n, decay)
    return nrm(x * e)


def horn(f, dur, a=.12, r=.25, dark=700, bright=3200, vib=5.0, vdepth=.003):
    n = int((dur + r) * SR)
    t = tt(n)
    v = 1 + vdepth * np.sin(2 * np.pi * vib * t) * np.minimum(1, t / .5)
    src = .6 * osc_saw(f * v, n) + .4 * osc_saw(f * v * 2 ** (6 / 1200), n)
    d = lp(src, dark, 2)
    b = lp(src, bright, 2)
    sw = env_ar(n, a * 1.5 + .04, r) ** 2
    return nrm((d * (1 - sw) + b * sw) * env_ar(n, a, r))


VOW = {'oo': ((300, 1.0), (870, .30), (2240, .08)),
       'ah': ((800, 1.0), (1150, .55), (2900, .18)),
       'mm': ((250, 1.0), (1100, .10), (2400, .03)),
       'eh': ((530, 1.0), (1840, .35), (2480, .12)),
       'ee': ((270, 1.0), (2290, .30), (3010, .12))}


def choir(f, dur, vowel='oo', a=1.0, r=1.5, vib=5.0, vdepth=.006, breath=.04, lowcut=None):
    """coro sintetico: serra detuned -> formantes em paralelo (sem voz real)."""
    n = int((dur + r) * SR)
    t = tt(n)
    v = 1 + vdepth * np.sin(2 * np.pi * vib * t + RNG.random() * 6.28) * np.minimum(1, t / (a + .5))
    src = _saws(f, n, (-11, 0, 11), v)
    out = np.zeros(n)
    for fc, g in VOW[vowel]:
        out += g * bp(src, fc * .87, fc * 1.15, 2)
    if breath:
        out += breath * bp(white(n), 900, 3500)
    if lowcut:
        out = lp(out, lowcut, 2)
    return nrm(out * env_ar(n, a, r))


def flute(f, dur, a=.07, r=.12, air=.18):
    n = int((dur + r) * SR)
    t = tt(n)
    v = 1 + .006 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, t / .3)
    ph = 2 * np.pi * np.cumsum(f * v) / SR
    x = np.sin(ph) + .18 * np.sin(2 * ph) + .05 * np.sin(3 * ph)
    x += air * bp(white(n), min(f * 2, 9000), min(f * 6, 12000)) * (1 + np.sin(ph * .0))
    return nrm(x * env_ar(n, a, r))


def glass(f, dur, a=.9, r=1.2):
    """vidro friccionado: seno puro com vibrato lento e ataque suave."""
    n = int((dur + r) * SR)
    t = tt(n)
    v = 1 + .004 * np.sin(2 * np.pi * 4.1 * t + RNG.random() * 6.28) * np.minimum(1, t / 1.2)
    ph = 2 * np.pi * np.cumsum(f * v) / SR
    x = np.sin(ph) + .30 * np.sin(2 * ph) + .12 * np.sin(3 * ph)
    return nrm(x * env_ar(n, a, r))


def thump(f0=110, f1=42, dur=.6, tau_f=.06, tau_a=.2, click=.15, drive=1.0):
    n = int(dur * SR)
    t = tt(n)
    fr = f1 + (f0 - f1) * np.exp(-t / tau_f)
    x = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / tau_a)
    if click:
        x += click * bp(white(n), 1200, 5000, 1) * np.exp(-t / .008)
    if drive > 1:
        x = np.tanh(x * drive)
    return nrm(fade(x, .001, .05))


def taiko(f=65, dur=1.6):
    n = int(dur * SR)
    t = tt(n)
    fr = f * (1 + 1.2 * np.exp(-t / .045))
    body = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / .35)
    skin = .8 * bp(white(n), 180, 900) * np.exp(-t / .05)
    thud = .3 * bp(white(n), 1500, 4000, 1) * np.exp(-t / .012)
    return nrm(fade(body + skin + thud, .001, .1))


def snare(dur=.22, tone=200, bright=1500):
    n = int(dur * SR)
    t = tt(n)
    x = hp(white(n), bright, 2) * np.exp(-t / .06) + \
        .6 * np.sin(2 * np.pi * tone * t) * np.exp(-t / .04)
    return nrm(fade(x, .0005, .02))


def hat(dur=.06, lo=6500):
    n = int(dur * SR)
    return nrm(fade(hp(white(n), lo, 2) * exp_dec(n, .012), .0003, .01))


def leg_click(dur=.02):
    n = int(dur * SR)
    c = RNG.uniform(2500, 5500)
    return nrm(fade(bp(white(n), c, c * 1.9, 2) * exp_dec(n, .004), .0002, .004))


def anvil(f=420, dur=.7):
    n = int(dur * SR)
    t = tt(n)
    rat = (1, 2.32, 4.25, 6.63, 9.38, 12.1)
    amp = (1, .8, .6, .4, .3, .2)
    tau = (.45, .3, .2, .14, .1, .07)
    x = np.zeros(n)
    for r_, a_, t_ in zip(rat, amp, tau):
        if f * r_ < 15000:
            x += a_ * np.sin(2 * np.pi * f * r_ * t) * np.exp(-t / (t_ * dur / .7))
    x += .5 * bp(white(n), 2000, 8000) * np.exp(-t / .01)
    return nrm(fade(x, .0005, .08))


def plate(f=180, dur=3.0):
    n = int(dur * SR)
    t = tt(n)
    rat = (1, 1.47, 2.09, 2.56, 3.41, 4.96, 6.1)
    x = np.zeros(n)
    for k, r_ in enumerate(rat):
        if f * r_ < 15000:
            x += (1 / (1 + .35 * k)) * np.sin(2 * np.pi * f * r_ * t + k) * \
                np.exp(-t / (dur / (3 + 1.2 * k)))
    x += .7 * bp(white(n), 1500, 7000) * np.exp(-t / .02)
    return nrm(fade(x, .0005, .15))


def sweep(dur, f0, f1, bands=7, shape=None):
    """ruido filtrado cuja banda sobe (f1>f0) ou desce (f1<f0) ao longo do tempo."""
    n = int(dur * SR)
    t = tt(n)
    x = np.zeros(n)
    nz = white(n)
    for i in range(bands):
        u = i / (bands - 1)
        c = f0 * (f1 / f0) ** u
        w = np.exp(-0.5 * ((t / dur - u) / (0.8 / bands)) ** 2)
        x += w * bp(nz, c * .75, c * 1.33)
    if shape is not None:
        x *= shape(t / dur)
    return nrm(fade(x, .01, .05))


def breath_noise(dur, lo=250, hi=1200, peak=.4):
    n = int(dur * SR)
    t = tt(n) / dur
    e = np.where(t < peak, (t / peak) ** 1.5, ((1 - t) / (1 - peak)) ** 1.3)
    return nrm(bp(white(n), lo, hi) * e)


def crackle_sig(n, rate=25, lo=1500, hi=7000):
    imp = (RNG.random(n) < rate / SR) * (RNG.random(n) ** 2 * 2 + .1) * np.sign(white(n))
    return bp(imp, lo, hi, 2)


# ------------------------------------------------------------------ reverb --
def make_ir(rt60, lpf=5000, pre=.015):
    n = int(rt60 * SR)
    t = np.arange(n) / SR
    dec = np.exp(-6.9078 * t / rt60)
    off = int(pre * SR)
    ir = np.zeros((2, n + off))
    for c in range(2):
        g = np.random.default_rng(1000 + c)
        nz = g.standard_normal(n) * dec
        a = lp(nz, lpf, 1)
        d = lp(nz, lpf * .3, 1)
        w = np.clip(t / rt60 * 1.5, 0, 1)
        nz = a * (1 - w) + d * w
        k = int(.005 * SR)
        nz[:k] *= np.linspace(0, 1, k)
        ir[c, off:] = nz
    ir /= np.sqrt(np.sum(ir ** 2, axis=1, keepdims=True))
    return ir


class Song:
    """Linha do tempo de uma faixa. Tempos em segundos; 'beat' = semínima."""

    def __init__(self, bpm, bars, bar_beats=4.0, tail=6.0, rt60=3.0, lpf=5000):
        self.bpm = bpm
        self.spb = 60.0 / bpm
        if np.isscalar(bar_beats):
            bb = [float(bar_beats)] * bars
        else:
            bb = [float(bar_beats[i % len(bar_beats)]) for i in range(bars)]
        self.bb = bb
        self.nb = bars
        self.bstart = np.concatenate([[0], np.cumsum(bb)]) * self.spb
        self.N = int(round(self.bstart[-1] * SR))
        self.T = int(tail * SR)
        self.dur = self.N / SR
        self.dry = np.zeros((2, self.N + self.T))
        self.buses = {'main': [np.zeros((2, self.N + self.T)), rt60, lpf]}

    def add_bus(self, name, rt60, lpf=5000):
        self.buses[name] = [np.zeros((2, self.N + self.T)), rt60, lpf]

    def at(self, bar, beat=0.0):
        return self.bstart[bar] + beat * self.spb

    def barsec(self, b):
        return self.bstart[b + 1] - self.bstart[b]

    def qf(self, f):
        """frequencia quantizada para caber num numero inteiro de ciclos no loop."""
        return max(1, round(f * self.dur)) / self.dur

    def per(self, k, n=None, phase=0.0):
        n = n or self.N
        return np.sin(2 * np.pi * k * np.arange(n) / self.N + phase)

    def add(self, sig, t, pan=0.0, gain=1.0, send=0.0, bus='main'):
        i = int(round(t * SR))
        if i < 0:
            sig = sig[-i:]
            i = 0
        n = min(sig.shape[-1], self.dry.shape[1] - i)
        if n <= 0:
            return
        if sig.ndim == 2:
            l = sig[0, :n] * gain
            r = sig[1, :n] * gain
        else:
            a = (pan + 1) * np.pi / 4
            l = sig[:n] * np.cos(a) * gain
            r = sig[:n] * np.sin(a) * gain
        self.dry[0, i:i + n] += l
        self.dry[1, i:i + n] += r
        if send > 0:
            b = self.buses[bus][0]
            b[0, i:i + n] += l * send
            b[1, i:i + n] += r * send

    def bed(self, fn, gain=1.0, pan=0.0, send=0.0, xf=1.0, rms=.2, bus='main', peak=None):
        """camada continua em loop: fn(n)->mono (n = N + crossfade).
        peak=1.0 normaliza pelo pico (use em sinais esparsos, tipo estalos de brasa)."""
        X = int(xf * SR)
        x = fn(self.N + X)
        fi = np.sin(np.linspace(0, np.pi / 2, X))
        fo = np.cos(np.linspace(0, np.pi / 2, X))
        r = x[:self.N].copy()
        r[:X] = x[:X] * fi + x[self.N:self.N + X] * fo
        if peak:
            r = r * (peak / (np.abs(r).max() + 1e-12))
        else:
            r = r * (rms / (np.sqrt(np.mean(r ** 2)) + 1e-12))
        self.add(r, 0.0, pan, gain, send, bus)

    def render(self, loop=True, total=None, fade_out=0.0):
        N, T = self.N, self.T
        L = N + T
        wets = []
        for name, (buf, rt60, lpf) in self.buses.items():
            if not buf.any():
                continue
            ir = make_ir(rt60, lpf)
            m = buf.sum(0) * .7071
            wets.append(np.stack([signal.fftconvolve(m, ir[0]), signal.fftconvolve(m, ir[1])]))
        Lmax = max([L] + [w.shape[1] for w in wets])
        out = np.zeros((2, Lmax))
        out[:, :L] += self.dry
        for w in wets:
            out[:, :w.shape[1]] += w
        if loop:
            pad_ = (-Lmax) % N
            out = np.pad(out, ((0, 0), (0, pad_)))
            return out.reshape(2, -1, N).sum(1)
        n = int(round((total if total else N / SR) * SR))
        if out.shape[1] < n:
            out = np.pad(out, ((0, 0), (0, n - out.shape[1])))
        out = out[:, :n].copy()
        if fade_out > 0:
            k = int(fade_out * SR)
            out[:, -k:] *= (0.5 + 0.5 * np.cos(np.pi * np.arange(k) / k))
        return out


def seq(s, bar, items, fn, beat=0.0, gain=1.0, pan=0.0, send=0.0, bus='main', tie=0.0):
    """toca [(nota, duracao_em_tempos[, ganho])] em sequencia. fn(freq, dur_s)->array."""
    t = s.at(bar, beat)
    c = 0.0
    for it in items:
        nme, d = it[0], it[1]
        g = it[2] if len(it) > 2 else 1.0
        if nme is not None:
            s.add(fn(hz(nme), d * s.spb + tie), t + c * s.spb, pan, gain * g, send, bus)
        c += d
    return c


# ------------------------------------------------------------ loudness/save --
def _kw(x):
    """filtro K-weighting da ITU-R BS.1770 para SR qualquer."""
    G, Q, fc = 3.999843853973347, 0.7071752369554196, 1681.9744509555319
    A = 10 ** (G / 40)
    w0 = 2 * np.pi * fc / SR
    al = np.sin(w0) / (2 * Q)
    cw = np.cos(w0)
    b0 = A * ((A + 1) + (A - 1) * cw + 2 * np.sqrt(A) * al)
    b1 = -2 * A * ((A - 1) + (A + 1) * cw)
    b2 = A * ((A + 1) + (A - 1) * cw - 2 * np.sqrt(A) * al)
    a0 = (A + 1) - (A - 1) * cw + 2 * np.sqrt(A) * al
    a1 = 2 * ((A - 1) - (A + 1) * cw)
    a2 = (A + 1) - (A - 1) * cw - 2 * np.sqrt(A) * al
    y = signal.lfilter([b0 / a0, b1 / a0, b2 / a0], [1, a1 / a0, a2 / a0], x, axis=-1)
    Q2, fc2 = 0.5003270373238773, 38.13547087613982
    K = np.tan(np.pi * fc2 / SR)
    a0 = 1 + K / Q2 + K * K
    a1 = 2 * (K * K - 1) / a0
    a2 = (1 - K / Q2 + K * K) / a0
    return signal.lfilter([1, -2, 1], [1, a1, a2], y, axis=-1)


def lufs_of(x):
    y = _kw(x)
    p = (y ** 2).sum(0)
    blk, hop = int(.4 * SR), int(.1 * SR)
    if len(p) < blk:
        return -0.691 + 10 * np.log10(np.mean(p) + 1e-12)
    cs = np.concatenate([[0], np.cumsum(p)])
    st = np.arange(0, len(p) - blk + 1, hop)
    z = (cs[st + blk] - cs[st]) / blk
    l = -0.691 + 10 * np.log10(z + 1e-12)
    z1 = z[l > -70]
    if len(z1) == 0:
        return -70.0
    rel = -0.691 + 10 * np.log10(z1.mean()) - 10
    z2 = z[l > max(rel, -70)]
    return -0.691 + 10 * np.log10(z2.mean() + 1e-12)


def _limit(x, lim):
    k = lim * .6
    a = np.abs(x)
    over = a > k
    y = x.copy()
    y[over] = np.sign(x[over]) * (k + (lim - k) * np.tanh((a[over] - k) / (lim - k)))
    return y


def bass_control(x, max_ratio=0.5, fc=60.0):
    """limita a fracao de energia (RMS) abaixo de fc Hz. Filtro por FFT circular:
    zero-fase e periodico, entao NAO cria salto na emenda do loop."""
    n = x.shape[-1]
    f = np.fft.rfftfreq(n, 1 / SR)
    X = np.fft.rfft(x, axis=-1)
    P = (np.abs(X) ** 2).sum(0)
    Mb = 1 / (1 + (f / fc) ** 8)                       # |H|^2 de um Butterworth de 4a ordem
    Mc = 1 / np.sqrt(1 + (f / (1.3 * fc)) ** 8)        # corte um pouco mais largo

    def ratio(k):
        p = P * (1 - (1 - k) * Mc) ** 2
        return np.sqrt((p * Mb).sum() / p.sum())

    if ratio(1.0) <= max_ratio:
        return x
    lo, hi = 0.02, 1.0
    for _ in range(30):                                # maior ganho k que cumpre o limite
        mid = (lo + hi) / 2
        if ratio(mid) > max_ratio:
            hi = mid
        else:
            lo = mid
    return np.fft.irfft(X * (1 - (1 - lo) * Mc), n, axis=-1)


def decode_ogg(path):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-f', 'f32le', '-ac', '2',
                          '-ar', str(SR), '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).T.astype(np.float64)


def master(x, lufs=-18.0, peak_db=PEAK_DB, bass=0.5):
    x = bass_control(x, bass)
    lim = 10 ** (peak_db / 20)
    g = 1.0
    for _ in range(4):
        y = _limit(x * g, lim)
        d = lufs - lufs_of(y)
        if abs(d) < .25:
            break
        g *= 10 ** (d / 20)
    return _limit(x * g, lim)


def seam_ratio(x):
    """salto na emenda (fim -> inicio) relativo ao maior salto normal entre amostras."""
    jump = np.max(np.abs(x[:, 0] - x[:, -1]))
    ref = np.percentile(np.abs(np.diff(x, axis=1)), 99.9) + 1e-9
    return jump / ref


def save(name, x, outdir):
    os.makedirs(os.path.join(outdir, 'wav'), exist_ok=True)
    os.makedirs(os.path.join(outdir, 'ogg'), exist_ok=True)
    wp = os.path.join(outdir, 'wav', name + '.wav')
    i16 = np.round(np.clip(x, -1, 1).T * 32767).astype(np.int16)
    wavfile.write(wp, SR, i16)
    if shutil.which('ffmpeg'):
        op = os.path.join(outdir, 'ogg', name + '.ogg')
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wp, '-c:a', 'libvorbis',
                        '-q:a', '5', op], check=True)
    return wp
