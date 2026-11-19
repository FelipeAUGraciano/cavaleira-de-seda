"""Galerias Umidas, Bercario, Centopeia-blindada."""
from cs_synth import *

SH = SHAPES


def galerias():
    reseed(11)
    s = Song(84, 32, tail=7, rt60=3.4, lpf=4500)
    A = [('E2', 'min'), ('C2', 'maj'), ('D2', 'maj'), ('B1', 'min')]
    Cp = [('D2', 'min'), ('Bb1', 'maj'), ('C2', 'maj'), ('A1', 'maj')]

    def ch(b):
        return (Cp if 16 <= b < 24 else A)[b % 4]

    # pad de caverna (reverb longo)
    for b in range(32):
        r, k = ch(b)
        m = midi(r)
        tones = [m + 12, m + 12 + SH[k][1], m + 12 + SH[k][2], m + 24, m + 24 + SH[k][2]]
        g = .12 if 16 <= b < 24 else .17
        for i, mm in enumerate(tones):
            s.add(pad(hz(mm), s.barsec(b) + .6, a=1.3, r=2.4, cut=1300),
                  s.at(b), pan=-.5 + .25 * i, gain=g, send=.75)

    # gotas d'agua aleatorias, mas dentro do acorde
    dens = {0: 4, 1: 3, 2: 2, 3: 4}
    for b in range(32):
        r, k = ch(b)
        m = midi(r)
        pool = [m + 36 + x for x in SH[k]] + [m + 48 + x for x in SH[k]]
        for tb in np.sort(RNG.random(dens[b // 8] + int(RNG.integers(0, 2))) * 4):
            s.add(drop(hz(int(RNG.choice(pool))), .5), s.at(b, tb),
                  pan=float(RNG.uniform(-.8, .8)), gain=float(RNG.uniform(.35, .7)), send=.8)

    # ostinato de baixo em colcheias (entra em B, sai no fim de A')
    pat = [0, 0, 7, 0, 0, 7, 12, 7]
    acc = [1, .55, .7, .55, .9, .55, .7, .55]
    for b in range(8, 28):
        gb = 1.0 if b < 24 else 1 - (b - 24) / 4
        if b == 8:
            gb = .6
        m = midi(ch(b)[0])
        for i in range(8):
            s.add(bass(hz(m + pat[i]), .2, cut=520, decay=.25), s.at(b, i / 2),
                  gain=.5 * acc[i] * gb, send=.15)

    # C: Tema da Cavaleira na marimba (uma vez)
    seq(s, 16, CAV, lambda f, d: marimba(f, 1.7), gain=.75, pan=-.1, send=.55)

    # sino grave raro
    for b in (0, 12, 28):
        s.add(bell(hz('E3'), 7, ratios=(1, 2.4, 4.1, 6.3), amps=(1, .5, .3, .15)),
              s.at(b), gain=.55, send=.8)

    # ---- camada de tensao
    t = Song(84, 32, tail=5, rt60=2.2, lpf=4000)
    for b in range(32):
        r, k = ch(b)
        m = midi(r)
        for beat in (0, 2):
            t.add(taiko(66, 1.2), t.at(b, beat), gain=.55 if beat else .75, send=.2)
        tl = [m + 24, m + 24 + SH[k][1], m + 24 + SH[k][2], m + 36]
        for i, ix in enumerate([0, 2, 1, 2, 0, 2, 3, 2]):
            t.add(string(hz(tl[ix]), .09, a=.004, r=.04, cut=2600), t.at(b, i / 2),
                  pan=.4 * np.sin(b + i), gain=.32 * (1 if i % 2 == 0 else .7), send=.25)
    kfast = round(36 * t.dur)
    am = lambda n: 0.55 + 0.45 * np.sin(2 * np.pi * kfast * np.arange(n) / t.N)
    sw = lambda n: 0.6 + 0.4 * np.sin(2 * np.pi * 5 * np.arange(n) / t.N)
    t.bed(lambda n: bp(white(n), 2200, 4800) * am(n) * sw(n), gain=1.0, pan=-.3, send=.2)
    t.bed(lambda n: bp(white(n), 2600, 5200) * am(n)[::-1] * sw(n), gain=.8, pan=.3, send=.2)

    return {'mus_galerias': (master(s.render(), -18), True),
            'mus_galerias_tensao': (master(t.render(), -20), True)}


def bercario():
    reseed(21)
    s = Song(72, 24, tail=7, rt60=3.0, lpf=4200)
    prog = [('D2', 'min'), ('Bb1', 'maj'), ('G1', 'min'), ('A1', 'sus4')]
    mbox = lambda f, d: bell(f, 2.6)

    for b in range(24):
        r, k = prog[b % 4]
        m = midi(r)
        notes = [m + 12, m + 12 + SH[k][1], m + 12 + SH[k][2], m + 24]
        g = .13 if b < 12 else .18
        for i, mm in enumerate(notes):
            s.add(pad(hz(mm), s.barsec(b) + .4, a=2.0, r=2.8, cut=800),
                  s.at(b), pan=-.4 + .27 * i, gain=g, send=.6)
        if b % 4 == 3:   # sus4 -> A (terca maior entra no 3o tempo)
            s.add(pad(hz(m + 12 + 4), 2.0, a=.4, r=2.5, cut=900), s.at(b, 2), gain=.12, send=.6)

    # Tema na caixinha: 1a metade, lento e delicado
    th = transp(CAV, 12)
    seq(s, 0, th, mbox, gain=.5, pan=-.1, send=.7)
    seq(s, 4, th, mbox, gain=.45, pan=.1, send=.7)
    seq(s, 8, th[:6], mbox, gain=.35, pan=0, send=.8)
    # 2a metade: fragmentos agudos, "aprendendo a se mexer"
    hi = transp(CAV, 24)
    frags = [(12, 0, [0, 1, 2]), (14, 2, [3, 4, 5, 6]), (16, 0, [0, 1]),
             (17, 2, [2, 3, 4]), (19, 1, [5, 6, 7, 8]), (21, 0, [0, 1, 2]), (22, 3, [6, 7, 8])]
    for bar, beat, ix in frags:
        seq(s, bar, [hi[i] for i in ix], lambda f, d: bell(f, 1.8), beat=beat,
            gain=.3, pan=float(RNG.uniform(-.6, .6)), send=.8)

    # batimento (duas batidas, pausa)
    for b in range(24):
        for beat in (0, 2):
            s.add(thump(90, 44, .5, .05, .16), s.at(b, beat), gain=.85, send=.1)
            s.add(thump(80, 42, .45, .05, .13), s.at(b, beat + .62), gain=.55, send=.1)
    # estalos de seda
    for b in range(24):
        for _ in range(int(RNG.integers(3, 7))):
            s.add(leg_click(), s.at(b, RNG.random() * 4), pan=float(RNG.uniform(-.9, .9)),
                  gain=float(RNG.uniform(.1, .35)), send=.35)

    # ---- camada de tensao
    t = Song(72, 24, tail=6, rt60=2.6, lpf=3500)
    pr = [('D2', 'Eb2'), ('Bb1', 'B1'), ('G1', 'Ab1'), ('A1', 'Bb1')]
    for b in range(24):
        a_, b_ = pr[b % 4]
        d = t.barsec(b) + .3
        t.add(string(hz(a_), d, a=.9, r=1.4, cut=650, vib=4.4), t.at(b), gain=.7, send=.4)
        t.add(string(hz(b_), d, a=1.3, r=1.4, cut=600, vib=4.0), t.at(b), gain=.38, pan=.2, send=.4)
        for beat in range(4):
            t.add(thump(90, 44, .45, .05, .15), t.at(b, beat), gain=.8, send=.1)
            t.add(thump(80, 42, .4, .05, .12), t.at(b, beat + .35), gain=.5, send=.1)
    t.bed(lambda n: lp(white(n), 55, 4) * (0.65 + 0.35 * np.sin(2 * np.pi * 3 * np.arange(n) / t.N)),
          gain=1.0, rms=.25)

    return {'mus_bercario': (master(s.render(), -18), True),
            'mus_bercario_tensao': (master(t.render(), -20), True)}


def centopeia():
    reseed(31)
    bb = [3.5, 3.5, 4, 4]                   # 7+7+8+8 colcheias
    groups = {7: [3, 2, 2], 8: [3, 3, 2]}
    legs = [leg_click() for _ in range(10)]

    def legs_group(S, b, e, start, g, gain, ramp=1.0):
        for j in range(g * 3):
            S.add(legs[int(RNG.integers(0, 10))], S.at(b) + start * e + j * e / 3,
                  pan=float(RNG.uniform(-.85, .85)),
                  gain=gain * float(RNG.uniform(.45, 1.0)) * (1.3 if j == 0 else 1) * ramp,
                  send=.12)

    S = Song(128, 24, bar_beats=bb, tail=5, rt60=1.7, lpf=5000)
    e = S.spb / 2
    shifts = [0, 0, 5, 0, 7, 0]
    motif = {7: [(0, 0, 2), (1, 2, 1), (0, 3, 2), (6, 5, 2)],
             8: [(0, 0, 3), (1, 3, 1), (0, 4, 2), (6, 6, 2)]}   # E F E Bb
    for b in range(24):
        n8 = int(bb[b % 4] * 2)
        sec = b // 8
        pos = 0
        quiet = 16 <= b < 20
        for gi, g in enumerate(groups[n8]):
            legs_group(S, b, e, pos, g, .5 if not quiet else .35)
            if not quiet or gi == 0:
                S.add(thump(95, 45, .35, .04, .12, drive=2.5), S.at(b) + pos * e,
                      gain=.95 if gi == 0 else .6, send=.1)
            pos += g
        S.add(plate(190 * (1 if b % 2 == 0 else 1.5), 2.6), S.at(b), gain=.45, send=.3)
        if b % 4 in (2, 3):
            S.add(plate(340, 1.8), S.at(b) + (n8 // 2) * e, gain=.3, send=.3)
        # metais graves com o motivo cromatico
        if not (16 <= b < 23):
            sh = shifts[b // 4]
            for (iv, st, ln) in motif[n8]:
                nt = 40 + sh + [0, 1, 6][[0, 1, 6].index(iv)]
                f = hz(nt + (0 if iv != 6 else 0))
                d = ln * e
                x = np.tanh(2.2 * horn(f, d, a=.01, r=.05, dark=520, bright=2000))
                S.add(x, S.at(b) + st * e, gain=.8, send=.12)
                if sec >= 1:
                    S.add(horn(f * 2, d, a=.01, r=.05, dark=800, bright=2600), S.at(b) + st * e,
                          gain=.35, pan=.3, send=.15)
            if sec >= 1 and b < 16:
                for f in (hz('E3'), hz('Bb3'), hz('E4')):
                    S.add(horn(f, 1.5 * e, a=.01, r=.05, dark=900, bright=3000),
                          S.at(b) + (n8 - 2) * e, gain=.22, pan=-.3, send=.2)
    # resposta: Tema da Cavaleira, mais agudo
    seq(S, 20, transp(CAV, 12), lambda f, d: string(f, d, a=.02, r=.15, cut=4500),
        gain=.55, pan=.1, send=.35)
    for b in range(20, 23):
        S.add(plate(120, 3), S.at(b), gain=.35, send=.4)
    S.bed(lambda n: sum(np.sin(2 * np.pi * S.qf(f) * np.arange(n) / SR + p) *
                        a for f, a, p in [(82.4, 1, 0), (82.4 + 1 / S.dur * 3, .6, 1), (164.8, .3, 2)]),
          gain=.5, rms=.12)

    # intro: 4 compassos de patas chegando; termina onde o loop comeca
    I = Song(128, 4, bar_beats=bb, tail=4, rt60=1.7, lpf=5000)
    ei = I.spb / 2
    for b in range(4):
        n8 = int(bb[b] * 2)
        pos = 0
        for g in groups[n8]:
            legs_group(I, b, ei, pos, g, .5, ramp=(.12 + .88 * (b * 8 + pos) / 28) ** 1.3)
            pos += g
    for b in (1, 2):
        I.add(thump(95, 45, .35, .04, .12, drive=2.5), I.at(b), gain=.4 * b, send=.1)
    I.bed(lambda n: lp(white(n), 70, 4) * np.linspace(.1, 1, n), gain=1.0, rms=.2)
    hit = I.at(3, 3.0)
    I.add(plate(190, 2.6), hit, gain=.9, send=.3)
    I.add(thump(95, 45, .35, .04, .12, drive=2.5), hit, gain=1.0)
    I.add(np.tanh(2.2 * horn(hz('E2'), .5, a=.01, r=.1, dark=520, bright=2000)), hit, gain=.9)
    intro = I.render(loop=False, fade_out=.1)

    return {'mus_boss_centopeia_intro': (master(intro, -14), False),
            'mus_boss_centopeia': (master(S.render(), -14), True)}


TRACKS = {'galerias': galerias, 'bercario': bercario, 'centopeia': centopeia}
