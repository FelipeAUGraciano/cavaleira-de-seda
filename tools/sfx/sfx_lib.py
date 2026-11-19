"""sfx_lib.py - ferramentas para os efeitos sonoros (so numpy + scipy).
Usa as primitivas de cs_synth (osciladores, filtros, sinos) e acrescenta:
whoosh, modal, chirp, squeal, growl, vocal, twang, blup, fogo, LoopBuf e o
acabamento (grave, 10 kHz, pico -1 dBFS, nivel)."""
import numpy as np
from scipy import signal

import cs_synth as cs
from cs_synth import (SR, bp, lp, hp, white, tt, nrm, osc_sine, osc_saw, VOW, bell,
                      thump, crackle_sig, hz)

SFX = []                       # (nome, n, nivel, loop, estereo, dur_ms, funcao)
LEVELS = {'b': -9.0, 'm': -3.0, 'a': 0.0}


def sfx(name, n=1, level='m', loop=False, stereo=False, d=None):
    """registra uma receita. d = (min_ms, max_ms) esperado (ou segundos exatos p/ loop)."""
    def deco(f):
        SFX.append((name, n, level, loop, stereo, d, f))
        return f
    return deco


def J(a, b):
    return float(cs.RNG.uniform(a, b))


def Ri(a, b):
    return int(cs.RNG.integers(a, b))


def Nn(d):
    return max(2, int(round(d * SR)))


# ---------------------------------------------------------------- envelopes --
def ad(n, a=.002, tau=.1):
    e = np.exp(-np.arange(n) / (tau * SR))
    na = int(a * SR)
    if na > 1:
        e[:na] *= np.linspace(0, 1, na)
    return e


def hump(n, peak=.3, p=1.5):
    u = np.arange(n) / max(n - 1, 1)
    peak = min(max(peak, .02), .98)
    return np.where(u < peak, (u / peak) ** p, ((1 - u) / (1 - peak)) ** p)


def srand(n, rate):
    """ruido suave (baixa frequencia) normalizado, para modulacao aleatoria."""
    return nrm(lp(white(n), rate, 1))


def mix(parts, dur=None):
    parts = [(np.asarray(a, float), float(t), g) for a, t, g in parts]
    end = max(int(round(t * SR)) + len(a) for a, t, g in parts)
    n = int(round(dur * SR)) if dur else end
    y = np.zeros(n)
    for a, t, g in parts:
        i = int(round(t * SR))
        m = min(len(a), n - i)
        if m > 0:
            y[i:i + m] += a[:m] * g
    return y


# ------------------------------------------------------------ blocos de som --
def tick(dur=.01, lo=2500, hi=8000, tau=.003):
    n = Nn(dur)
    return nrm(bp(white(n), lo, hi, 2) * ad(n, .0002, tau))


def modal(freqs, amps, taus, dur):
    n = Nn(dur)
    t = tt(n)
    x = np.zeros(n)
    for f, a, tau in zip(freqs, amps, taus):
        x += a * np.sin(2 * np.pi * f * t + J(0, 6.28)) * np.exp(-t / tau)
    return nrm(x)


def chirp(f0, f1, dur, tau=None, a=.002):
    n = Nn(dur)
    t = tt(n)
    fr = f0 * (f1 / f0) ** (t / dur)
    return np.sin(2 * np.pi * np.cumsum(fr) / SR) * ad(n, a, tau or dur / 3)


def blup(f, dur=.08, rise=.7):
    """bolha / gota: seno que sobe de tom e morre rapido."""
    n = Nn(dur)
    t = tt(n)
    fr = f * (rise + (1 - rise) * (1 - np.exp(-t / (dur * .4))))
    ph = 2 * np.pi * np.cumsum(fr) / SR
    return (np.sin(ph) + .3 * np.sin(2 * ph)) * ad(n, .001, dur / 3)


def whoosh(dur, f0, f1, peak=.4, p=1.5, bands=6):
    n = Nn(dur)
    u = tt(n) / dur
    nz = white(n)
    x = np.zeros(n)
    for i in range(bands):
        w = i / (bands - 1)
        c = f0 * (f1 / f0) ** w
        x += np.exp(-.5 * ((u - w) / (.8 / bands)) ** 2) * bp(nz, c * .7, c * 1.4)
    return nrm(x * hump(n, peak, p))


def hiss(dur, lo=3000, hi=9000, peak=.3, p=1.2):
    n = Nn(dur)
    return nrm(bp(white(n), lo, hi) * hump(n, peak, p))


def squeal(dur, f0, f1, fm=55, idx=.5, hissy=.5, a=.004, tau=None):
    n = Nn(dur)
    t = tt(n)
    fr = f0 * (f1 / f0) ** (t / dur)
    ph = 2 * np.pi * np.cumsum(fr) / SR
    x = np.sin(ph + idx * np.sin(2 * np.pi * fm * t)) + .35 * np.sin(2 * ph)
    x = x + hissy * bp(white(n), 2500, 8000)
    return nrm(x * ad(n, a, tau or dur * .5))


def growl(dur, f0, f1, rough=40, dist=2.0, dark=900):
    n = Nn(dur)
    t = tt(n)
    fr = f0 * (f1 / f0) ** (t / dur) * (1 + .03 * np.sin(2 * np.pi * rough * t))
    src = osc_saw(fr, n) + .5 * osc_saw(fr * 1.5, n) + .35 * white(n)
    x = lp(src, dark, 2) * (.65 + .35 * np.sin(2 * np.pi * rough * t))
    return nrm(np.tanh(dist * nrm(x)))


def twang(f, dur, tau=.25, bend=.06, harm=6):
    n = Nn(dur)
    t = tt(n)
    fr = f * (1 + bend * np.exp(-t / .04))
    ph = 2 * np.pi * np.cumsum(fr) / SR
    x = np.zeros(n)
    for k in range(1, harm + 1):
        x += (1 / k) * np.sin(k * ph) * np.exp(-t / (tau / (1 + .4 * (k - 1))))
    return nrm(x * np.minimum(1, t / .002))


def vocal(dur, f0, f1, vowel='ah', breath=.25, lowcut=2500, a=.03, peak=.3):
    """formantes sinteticos (serra -> filtros em paralelo): sem voz real, sem palavras."""
    n = Nn(dur)
    t = tt(n)
    fr = f0 * (f1 / f0) ** (t / dur) * (1 + .012 * np.sin(2 * np.pi * 5.5 * t))
    src = osc_saw(fr, n)
    out = np.zeros(n)
    for fc, g in VOW[vowel]:
        out += g * bp(src, fc * .87, fc * 1.15)
    out += breath * bp(white(n), 800, 4500)
    if lowcut:
        out = lp(out, lowcut, 2)
    e = hump(n, peak, 1.0)
    na = int(a * SR)
    e[:na] = np.minimum(e[:na], np.linspace(0, 1, na))
    return nrm(out * e)


def croak(f, dur, pulses=28):
    n = Nn(dur)
    t = tt(n)
    fr = f * (1 + .05 * np.sin(2 * np.pi * 14 * t))
    x = np.sin(2 * np.pi * np.cumsum(fr) / SR) + .5 * np.sin(4 * np.pi * np.cumsum(fr) / SR)
    am = np.clip(np.sin(2 * np.pi * pulses * t) * 1.5, 0, 1)
    return nrm(lp(x * am, 1200, 2) * hump(n, .3, 1.0))


def echo(x, delays, gains, lpf=2500):
    n = len(x) + int(max(delays) * SR) + 1
    y = np.zeros(n)
    y[:len(x)] += x
    for d, g in zip(delays, gains):
        i = int(d * SR)
        y[i:i + len(x)] += lp(x, lpf, 1) * g
    return y


def fire(dur, roar=.7, crack=.7, rate=200):
    n = Nn(dur)
    r = bp(white(n), 120, 1300) * (.6 + .4 * srand(n, 12))
    c = crackle_sig(n, rate, 1200, 8000)
    return nrm(roar * nrm(r) + crack * nrm(c))


def stone_hit(dur=.3, f=None, g=1.0):
    f = f or J(350, 600)
    return modal([f, f * J(2.1, 2.7), f * J(4.0, 5.2)], [1, .6, .3], [.10, .06, .03], dur) * g


# -------------------------------------------------------------------- loops --
class LoopBuf:
    """buffer mono circular de N amostras: eventos dao a volta, ruido usa crossfade."""

    def __init__(self, dur):
        self.N = Nn(dur)
        self.dur = self.N / SR
        self.buf = np.zeros(self.N)

    def add(self, sig, t, gain=1.0):
        i = int(round(t * SR)) % self.N
        sig = np.asarray(sig, float) * gain
        k = 0
        while k < len(sig):
            m = min(len(sig) - k, self.N - i)
            self.buf[i:i + m] += sig[k:k + m]
            k += m
            i = 0

    def bed(self, fn, gain=1.0, rms=.2, peak=None, xf=.25):
        X = int(xf * SR)
        x = fn(self.N + X)
        fi = np.sin(np.linspace(0, np.pi / 2, X))
        fo = np.cos(np.linspace(0, np.pi / 2, X))
        r = x[:self.N].copy()
        r[:X] = x[:X] * fi + x[self.N:self.N + X] * fo
        r = r * (peak / (np.abs(r).max() + 1e-12)) if peak else r * (rms / (np.sqrt(np.mean(r ** 2)) + 1e-12))
        self.buf += r * gain

    def t(self):
        return np.arange(self.N) / SR

    def per(self, k, phase=0.0):
        return np.sin(2 * np.pi * k * np.arange(self.N) / self.N + phase)


# ---------------------------------------------------------------- acabamento --
def _lp_circ(X, fc=10000.0):
    n = X.shape[-1]
    f = np.fft.rfftfreq(n, 1 / SR)
    return np.fft.irfft(np.fft.rfft(X, axis=-1) / np.sqrt(1 + (f / fc) ** 8), n, axis=-1)


def finish(x, level, loop=False):
    """grave controlado, corte em 10 kHz, pico -1 dBFS, depois o nivel pedido."""
    X = np.atleast_2d(np.asarray(x, float)).copy()
    X = cs.bass_control(X, .5)
    if loop:
        X = _lp_circ(X, 9500)
    else:
        sos = signal.butter(8, 8800, 'lowpass', fs=SR, output='sos')
        X = signal.sosfilt(sos, X, axis=-1)
        m = np.abs(X).max()
        idx = int(np.argmax(np.abs(X).max(0) > m * .003))      # corta silencio inicial (< -50 dB)
        X = X[:, max(0, idx - 15):]
        n = X.shape[1]
        na = max(2, int(.0003 * SR))
        nr = min(int(.025 * SR), max(2, int(n * .2)))
        X[:, :na] *= np.linspace(0, 1, na)
        X[:, n - nr:] *= np.linspace(1, 0, nr) ** 1.5
    X *= 10 ** (-1 / 20) / (np.abs(X).max() + 1e-12)
    lv = LEVELS[level] if isinstance(level, str) else float(level)
    return X * 10 ** (lv / 20)
