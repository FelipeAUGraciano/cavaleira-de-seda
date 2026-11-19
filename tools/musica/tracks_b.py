"""Abismo, Colosso (camada), Serpente-cega (chefe, com intro)."""
from cs_synth import *

SH = SHAPES


def ppiano(f, dur=5.0):
    """piano preparado: ataque percussivo e parciais inarmonicos."""
    n = int(dur * SR)
    t = tt(n)
    x = np.zeros(n)
    for r_, a_, d_ in zip((1, 2.03, 3.12, 4.41, 5.93), (1, .6, .45, .3, .2), (4, 7, 10, 14, 18)):
        if f * r_ < 14000:
            x += a_ * np.sin(2 * np.pi * f * r_ * t) * np.exp(-t / (dur / d_))
    x += .9 * bp(white(n), 250, 1100) * np.exp(-t / .03)
    return nrm(fade(x, .001, .2))


def abismo():
    reseed(41)
    s = Song(60, 24, tail=9, rt60=6.0, lpf=3500)
    D, N = s.dur, s.N
    t = np.arange(N) / SR

    # drone com batimento lento (respiracao): duas ondas ~0.1 Hz afastadas
    f1 = s.qf(69.3)
    x = np.zeros(N)
    for k, a in zip(range(1, 6), (1, .55, .35, .2, .12)):
        x += a * np.sin(2 * np.pi * k * f1 * t)
        x += a * np.sin(2 * np.pi * k * (f1 + 10 / D) * t + .7)
    x += .9 * np.sin(2 * np.pi * (f1 / 2) * t)
    x *= 0.78 + 0.22 * np.sin(2 * np.pi * 4 * t / D)
    s.add(x / np.abs(x).max(), 0, gain=.5, send=.15)

    # ressonancias metalicas longas, a distancia
    for bar, nt, pan in [(2, 'C#3', -.5), (9, 'G#3', .5), (15, 'D3', -.3), (21, 'C#3', .4)]:
        b_ = lp(bell(hz(nt), 14, ratios=(1, 2.32, 3.87, 5.41, 7.2),
                     amps=(1, .6, .4, .25, .15), fall=1.4), 2800)
        s.add(b_, s.at(bar), pan=pan, gain=.38, send=1.0)

    # coral "oo" muito baixo: cluster C# - D - G# que abre e fecha
    voices = [('C#3', 2, 9), ('D3', 5, 12), ('G#3', 8, 16), ('C#3', 14, 22), ('D3', 17, 23),
              ('G#3', 18, 22)]
    for i, (nt, b0, b1) in enumerate(voices):
        s.add(choir(hz(nt), (b1 - b0) * 4 - 2, 'oo', a=6, r=6, lowcut=1100, vdepth=.004),
              s.at(b0), pan=(-.4, .4)[i % 2], gain=.24, send=.9)

    # piano preparado, notas soltas
    for bar, beat, nt, pan in [(3, 0, 'C#4', -.3), (6, 2, 'G#3', .4), (10, 0, 'E4', .2),
                               (13, 1, 'D4', -.5), (17, 2, 'C#4', .3), (20, 0, 'A3', -.2),
                               (22, 2, 'G#4', .5)]:
        s.add(ppiano(hz(nt)), s.at(bar, beat), pan=pan, gain=.32, send=.8)

    # 2a metade: eco distorcido de 3 notas do Tema (D F A), lembranca
    def eco(nt, g, oct_=0, cut=1300):
        f = hz(nt) * 2 ** (-35 / 1200) * 2 ** oct_
        y = np.tanh(2.5 * string(f, 3.6, a=1.4, r=3.0, cut=cut, vib=3.2, vdepth=.01))
        return lp(y, cut)
    for i, nt in enumerate(('D4', 'F4', 'A4')):
        s.add(eco(nt, 1), s.at(14 + i, 1), pan=-.2, gain=.30, send=.9)
    for i, nt in enumerate(('D4', 'F4', 'A4')):
        s.add(eco(nt, 1, -1, 800), s.at(20 + i, 2), pan=.2, gain=.2, send=1.0)

    # ---- camada de tensao
    T = Song(60, 24, tail=7, rt60=4.0, lpf=3000)
    tm = 3.0
    while tm < D - 2:
        gap = RNG.uniform(.28, .42)
        T.add(thump(62, 30, 1.4, .08, .35, click=.05), tm, gain=1.0, send=.3)
        T.add(thump(55, 28, 1.2, .08, .30, click=.05), tm + gap, gain=.7, send=.3)
        nr = int(1.6 * SR)
        rum = lp(white(nr), 90, 4) * exp_dec(nr, .5) * (.6 + .4 * np.sin(2 * np.pi * 14 * tt(nr)))
        T.add(nrm(rum), tm, gain=.5, send=.2)
        tm += RNG.uniform(2.8, 5.0)
    # tremolo de cordas agudas, bem baixo
    ktr = round(11 * D)
    sw = 0.25 + 0.75 * (0.5 + 0.5 * np.sin(2 * np.pi * 3 * t / D)) ** 2
    y = (np.sin(2 * np.pi * T.qf(1108.7) * t) + .7 * np.sin(2 * np.pi * T.qf(830.6) * t)) * \
        (0.5 + 0.5 * np.sin(2 * np.pi * ktr * t / D)) * sw
    T.add(y / np.abs(y).max(), 0, gain=.07, send=.5)
    # respiracao ritmada (1 por compasso)
    def breathe(n):
        u = (np.arange(n) / N * 24) % 1
        e = np.where(u < .4, (u / .4) ** 1.5, ((1 - u) / .6) ** 1.3)
        return bp(white(n), 250, 900) * e
    T.bed(breathe, gain=.8, pan=-.1, send=.4)

    return {'mus_abismo': (master(s.render(), -18), True),
            'mus_abismo_tensao': (master(T.render(), -20), True)}


def colosso():
    reseed(51)
    s = Song(60, 8, tail=5, rt60=4.0, lpf=3000)
    D, N = s.dur, s.N
    t = np.arange(N) / SR
    # batimento sub-grave enorme
    for b in range(8):
        for beat in (0, 2):
            s.add(thump(70, 34.65, 1.5, .05, .38, click=0), s.at(b, beat), gain=1.0, send=.15)
            s.add(thump(60, 34.65, 1.1, .05, .30, click=0), s.at(b, beat + .55), gain=.65, send=.15)
    # pisadas pesadas com tremor
    for b in (1, 3, 5, 7):
        s.add(thump(55, 28, 1.8, .08, .5, click=.03, drive=1.6), s.at(b, 1.0), gain=.9, send=.3)
        nr = int(2.2 * SR)
        rum = lp(white(nr), 120, 4) * exp_dec(nr, .8) * (.5 + .5 * np.sin(2 * np.pi * 17 * tt(nr)))
        s.add(nrm(rum), s.at(b, 1.0), gain=.8, send=.2)
    # drone que sobe devagar meio tom e volta (periodico)
    fr = 69.3 * 2 ** ((0.5 / 12) * (0.5 - 0.5 * np.cos(2 * np.pi * t / D)) * 2)
    ph = pphase(fr)
    y = np.sin(2 * np.pi * ph) + .5 * np.sin(4 * np.pi * ph) + .25 * np.sin(6 * np.pi * ph)
    s.add(y / np.abs(y).max(), 0, gain=.35, send=.2)
    # respiracao grave
    def breathe(n):
        u = (np.arange(n) / N * 8) % 1
        e = np.where(u < .4, (u / .4) ** 1.5, ((1 - u) / .6) ** 1.3)
        return bp(white(n), 70, 320) * e
    s.bed(breathe, gain=1.0, rms=.25)
    return {'mus_colosso': (master(s.render(), -16, bass=.62), True)}


def _rim():
    n = int(.08 * SR)
    t = tt(n)
    return nrm(fade(bp(white(n), 1500, 4200) * np.exp(-t / .02) +
                    .7 * np.sin(2 * np.pi * 900 * t) * np.exp(-t / .015), .0005, .02))


def serpente():
    reseed(61)
    BB = 3.0                            # 6/8 = 3 semínimas por compasso
    holes = [(3, 1.5, 1.5), (7, 1, 2), (11, 2, 1), (14, 1.5, 1.5), (18, 1, 2), (21, 2, 1),
             (25, 1.5, 1.5), (27, 1, 2), (31, 2, 1)]

    def build(nbars, is_intro=False):
        S1 = Song(92, nbars, bar_beats=BB, tail=7, rt60=3.5, lpf=4500)
        S2 = Song(92, nbars, bar_beats=BB, tail=4, rt60=1.4, lpf=5000)
        return S1, S2

    def mask_for(S, hl):
        m = np.ones(S.N)
        for bar, bt, ln in hl:
            a = int(S.at(bar, bt) * SR)
            b = min(S.N, int(S.at(bar, bt + ln) * SR))
            m[a:b] = 0
            fo = int(.012 * SR)
            m[max(0, a - fo):a] = np.linspace(1, 0, a - max(0, a - fo))
            fi = int(.004 * SR)
            if b < S.N:
                m[b:b + fi] = np.linspace(0, 1, len(m[b:b + fi]))
        return m

    # ---------------- loop ----------------
    S1, S2 = build(32)
    D = S1.dur
    # cromatismo descendente no vidro friccionado
    P = [(0, 69), (8, 74), (16, 72)]
    for p0, top in P:
        for i in range(8):
            S1.add(glass(hz(top - i), S1.barsec(p0 + i) + .3, a=.6, r=1.0), S1.at(p0 + i),
                   pan=(-.3, .3)[i % 2], gain=.5, send=.8)
    for i in range(6):                                  # frase final: 69..64
        S1.add(glass(hz(69 - i), S1.barsec(24 + i) + .3, a=.6, r=1.0), S1.at(24 + i),
               pan=(-.3, .3)[i % 2], gain=.5, send=.8)
    seq(S1, 30, CAV[:5], lambda f, d: glass(f, d, a=.15, r=.8), gain=.6, send=.8)

    # coral "mm" baixo, acordes sobre o pedal de La
    chs = [[50, 53, 57], [45, 49, 52], [46, 50, 53], [45, 49, 52],
           [50, 53, 57], [43, 46, 50], [45, 49, 52], [45, 49, 52]] * 2
    for i, cc in enumerate(chs):
        for j, m_ in enumerate(cc):
            S1.add(choir(hz(m_), S1.at(2 * i + 2) - S1.at(2 * i), 'mm', a=1.2, r=1.8, lowcut=900),
                   S1.at(2 * i), pan=-.4 + .4 * j, gain=.2, send=.6)

    # baixo em notas longas que deslizam (pedal de La -> Re -> Sib -> Sol)
    holds = [(0, 3.5, 55), (4, 7.5, 73.42), (8, 11.5, 58.27), (12, 15.5, 55),
             (16, 19.5, 49), (20, 23.5, 55), (24, 27.5, 73.42), (28, 32, 55)]
    pts = []
    tb = lambda x: S1.at(int(x), (x % 1) * BB)      # compasso fracionario -> segundos
    for a_, b_, f_ in holds:
        pts += [(tb(a_), f_), (tb(b_), f_)]
    pts[0] = (0.0, pts[0][1])
    tt_ = np.arange(S1.N) / SR
    fr = np.zeros(S1.N)
    for (t0, f0), (t1, f1) in zip(pts[:-1], pts[1:]):
        i0, i1 = int(t0 * SR), min(S1.N, int(t1 * SR))
        u = np.linspace(0, 1, max(1, i1 - i0), endpoint=False)
        fr[i0:i1] = f0 + (f1 - f0) * (3 * u ** 2 - 2 * u ** 3)
    fr[int(pts[-1][0] * SR):] = pts[-1][1]
    ph = pphase(fr)
    y = np.sin(2 * np.pi * ph) + .45 * np.sin(4 * np.pi * ph) + .18 * np.sin(6 * np.pi * ph)
    S1.add(y / np.abs(y).max(), 0, gain=.55, send=.2)

    # sibilos (ruido agudo em sweep)
    for bar in (3, 9, 14, 19, 24, 27):
        S1.add(sweep(2.4, 3500, 9500, shape=lambda u: np.sin(np.pi * u) ** 2), S1.at(bar),
               pan=float(RNG.uniform(-.7, .7)), gain=.22, send=.5)

    # percussao seca e esparsa (6/8 balancado)
    e = S2.spb / 2
    rim = _rim()
    for b in range(32):
        if b % 2 == 0:
            S2.add(thump(110, 60, .3, .03, .08), S2.at(b), gain=.45, send=.05)
        for i, p in ((2, .55), (5, .45)):
            if RNG.random() < p:
                S2.add(rim, S2.at(b) + (i * e) + .035, pan=float(RNG.uniform(-.5, .5)),
                       gain=float(RNG.uniform(.25, .5)), send=.1)

    # "bote": ataque forte quando o silencio termina (e no inicio do loop)
    def bote(S, tm):
        S.add(thump(80, 38, .5, .04, .14, drive=2.0), tm, gain=1.0, send=.1)
        S.add(np.tanh(2 * bass(55, .5, cut=900, decay=.3)), tm, gain=.9, send=.1)
        n = int(.3 * SR)
        S.add(nrm(hp(white(n), 5000, 2) * exp_dec(n, .08)), tm, gain=.55, send=.2)
    for bar, bt, ln in holes:
        be = (bar + 1) % 32 if bt + ln >= BB else bar
        bote(S2, S2.at(be) if bt + ln >= BB else S2.at(bar, bt + ln))
    bote(S2, 0.0)

    loop = S1.render() * mask_for(S1, holes) + S2.render()

    # ---------------- intro (4 compassos, termina no inicio do loop) -------
    I1, I2 = build(4, True)
    I1.add(sweep(I1.dur, 3000, 9000, shape=lambda u: u ** 2.2), 0, gain=.25, send=.5)
    I1.add(glass(hz('A4'), I1.dur - 1.5, a=3.5, r=.3), 0, gain=.5, send=.8)
    I1.add(choir(hz('A2'), I1.dur - 1.5, 'mm', a=3, r=.3, lowcut=900), 0, gain=.3, send=.6)
    I1.add(choir(hz('E3'), I1.dur - 1.5, 'mm', a=3.5, r=.3, lowcut=900), 0, gain=.2, pan=.4, send=.6)
    for bar, bt in ((1, 0), (2, 0), (2, 1.5), (3, 0)):
        I2.add(rim, I2.at(bar, bt) + .03, gain=.35, pan=.2, send=.1)
    ihole = [(3, 1.5, 1.5)]
    intro = I1.render(loop=False) * mask_for(I1, ihole) + I2.render(loop=False)

    return {'mus_boss_serpente_intro': (master(intro, -14), False),
            'mus_boss_serpente': (master(loop, -14), True)}


TRACKS = {'abismo': abismo, 'colosso': colosso, 'serpente': serpente}
