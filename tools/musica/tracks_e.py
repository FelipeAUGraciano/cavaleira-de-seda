"""Portao, Guardiao (3 fases), stingers curtos, Casulo, Menu."""
from cs_synth import *
from tracks_c import organ

SH = SHAPES

# Tema da Cavaleira com o mesmo contorno em Fa maior (graus diatonicos) e Re maior
CAV_F = [('F4', 1), ('A4', 1), ('C5', 2), ('Bb4', .5), ('A4', .5), ('G4', 1), ('F4', 1),
         ('E4', 1), ('F4', 2)]
CAV_DM = [('D4', 1), ('F#4', 1), ('A4', 2), ('G4', .5), ('F#4', .5), ('E4', 1), ('D4', 1),
          ('C#4', 1), ('D4', 2)]

ROOTS = {'Dm': ('D2', 'min'), 'C': ('C2', 'maj'), 'Bb': ('Bb1', 'maj'), 'F': ('F2', 'maj'),
         'Gm': ('G1', 'min'), 'A': ('A1', 'maj'), 'D': ('D2', 'maj'), 'Bm': ('B1', 'min'),
         'G': ('G1', 'maj')}


def ctones(name, oct_=12):
    r, k = ROOTS[name]
    m = midi(r) + oct_
    return [m + i for i in SH[k]]


def portao():
    reseed(131)
    s = Song(90, 32, tail=5, rt60=1.8, lpf=8000)
    prog = (['Dm', 'C', 'Bb', 'F'] * 3 + ['F', 'C', 'Dm', 'Bb'] * 4 + ['F', 'C', 'Bb', 'C'])
    strg = lambda f, d: string(f, d, a=.05, r=.3, cut=3800)
    for b in range(32):
        nm = prog[b]
        tl = ctones(nm, 24)
        d = s.barsec(b) + .3
        for i, mm in enumerate(tl):                               # cordas sustentadas
            s.add(string(hz(mm - 12 if i == 0 else mm), d, a=.5, r=.7, cut=3000),
                  s.at(b), pan=-.5 + .5 * i, gain=.16, send=.25)
        if b >= 4:                                                # coral claro
            for i, mm in enumerate(tl[:3]):
                s.add(choir(hz(mm + 12), d, 'ah', a=.7, r=.8, lowcut=5000, vdepth=.005),
                      s.at(b), pan=-.4 + .4 * i, gain=.16, send=.25)
        if b >= 12:                                               # metais suaves
            for i, mm in enumerate(tl[:3]):
                s.add(horn(hz(mm), d, a=.25, r=.5, dark=800, bright=2200), s.at(b),
                      pan=.3 - .3 * i, gain=.12, send=.25)
        s.add(bass(hz(ROOTS[nm][0]), s.barsec(b) * .9, cut=350, a=.2, r=.5), s.at(b), gain=.35)
        hp_ = [tl[0] + 12 * (i // 3) for i in range(1)]            # harpa em colcheias
        pool = [tl[0], tl[1], tl[2], tl[0] + 12, tl[1] + 12, tl[2] + 12]
        for i in range(8):
            ix = [0, 1, 2, 3, 4, 5, 4, 2][i]
            s.add(harp(hz(pool[ix] + 12 if ix < 3 else pool[ix]), 1.6), s.at(b, i / 2),
                  pan=-.5 + .14 * i, gain=.2 * (1.2 if i == 0 else 1), send=.25)
        if b % 4 == 0:
            s.add(bell(hz(tl[2] + 24), 3.5, bright=1.1), s.at(b), gain=.26, pan=.3, send=.3)
    seq(s, 8, CAV, strg, gain=.6, pan=-.1, send=.3)                # Re menor
    seq(s, 8, transp(CAV, -12), lambda f, d: horn(f, d, a=.08, r=.3, dark=800, bright=2000),
        gain=.25, send=.3)
    for bar, g in ((20, .62), (26, .55)):                          # Fa maior, transformado
        seq(s, bar, CAV_F, strg, gain=g, pan=-.1, send=.3)
        seq(s, bar, transp(CAV_F, -12), lambda f, d: horn(f, d, a=.06, r=.3, dark=1000, bright=3500),
            gain=.35, send=.3)
        seq(s, bar, transp(CAV_F, 12), lambda f, d: bell(f, 1.8), gain=.18, pan=.3, send=.3)
    s.bed(lambda n: hp(lp(white(n), 11000, 2), 5000, 2) * (.6 + .4 * np.sin(2 * np.pi * 2 * np.arange(n) / s.N)),
          gain=.35, send=.2)

    t = Song(90, 32, tail=4, rt60=1.8, lpf=6000)
    for b in range(32):
        nm = prog[b]
        r, _ = ROOTS[nm]
        for beat, g in ((0, 1.0), (2, .6)):
            t.add(taiko(hz(r) * 1.05, 1.4), t.at(b, beat), gain=.85 * g, send=.2)
        tl = ctones(nm, 24)
        for i in range(8):
            t.add(string(hz(tl[i % 3]), .1, a=.004, r=.04, cut=3500), t.at(b, i / 2),
                  pan=.4 * (-1) ** i, gain=.22, send=.2)
        if b % 4 == 3:                                             # rufo de timpano
            for i in range(8):
                t.add(taiko(hz(r) * 1.05, .5), t.at(b, 3) + i * t.spb / 8, gain=.2 + .5 * i / 8)
    hrn = lambda f, d: horn(f, d, a=.04, r=.25, dark=1000, bright=4000)
    for b in range(0, 32, 4):
        seq(t, b, EXP, hrn, gain=.55, pan=.2, send=.3)
        seq(t, b, transp(EXP, 12), hrn, gain=.3, pan=-.2, send=.3)
        seq(t, b + 2, transp(EXP, 7), hrn, gain=.35, pan=.1, send=.3)
    return {'mus_portao': (master(s.render(), -18), True),
            'mus_portao_tensao': (master(t.render(), -20), True)}


def guardiao():
    out = {}
    cyc_min = ['Dm', 'Bb', 'Gm', 'A'] * 4
    cyc_maj = ['D', 'A', 'Bm', 'G', 'D', 'A', 'G', 'A'] * 2
    for ph in (1, 2, 3):
        reseed(140 + ph)
        s = Song(140, 16, tail=5, rt60=2.4 if ph == 1 else 1.9, lpf=6000)
        prog = cyc_maj if ph == 3 else cyc_min
        e = s.spb / 2
        drone_f = s.qf(73.4)
        t_ = np.arange(s.N) / SR
        s.add((np.sin(2 * np.pi * drone_f * t_) + .4 * np.sin(4 * np.pi * drone_f * t_)) / 1.4,
              0, gain=.3, send=.1)
        for b in range(16):
            nm = prog[b]
            r, _ = ROOTS[nm]
            tl = ctones(nm, 12)
            d = s.barsec(b) + .3
            for i, mm in enumerate(tl):                                  # orgao + metais + coral
                s.add(organ(hz(mm), d, a=.2, r=.5, cut=1500 if ph == 1 else 2200, drive=2.0),
                      s.at(b), pan=-.4 + .4 * i, gain=.12, send=.2)
                s.add(horn(hz(mm + 12), d, a=.15, r=.4, dark=800 + 400 * ph, bright=2600 + 600 * ph),
                      s.at(b), pan=.4 - .4 * i, gain=.1 + .03 * ph, send=.25)
                s.add(choir(hz(mm + 12), d, 'ah', a=.5, r=.7, lowcut=3500 + 1500 * ph),
                      s.at(b), pan=-.3 + .3 * i, gain=.1 + .03 * ph, send=.3)
            s.add(bass(hz(r), s.barsec(b) * .9, cut=400, a=.1, r=.4), s.at(b), gain=.45)
            s.add(taiko(hz(r) * 1.05, 1.6), s.at(b), gain=1.0 if ph != 2 else .8, send=.25)
            s.add(taiko(hz(r) * 1.2, 1.0), s.at(b, 2), gain=.6, send=.25)
            if ph >= 2:                                                   # forja 3+3+2
                for pos, ga in ((0, .8), (3, .55), (6, .4)):
                    s.add(anvil(hz('D4') * (1.5 if pos == 3 else 1), .6), s.at(b) + pos * e,
                          gain=ga * (.7 if ph == 3 else .9), pan=(-.2, .1, .25)[pos // 3], send=.25)
            else:
                if b % 2 == 0:
                    s.add(anvil(hz('D4'), .8), s.at(b), gain=.28, pan=.2, send=.4)
            if ph == 2:                                                   # caos: 16as e rufos
                e16 = s.spb / 4
                for i in range(16):
                    s.add(string(hz(tl[(i * 2 + b) % 3] + 12), .06, a=.003, r=.03, cut=3800),
                          s.at(b) + i * e16, pan=.5 * np.sin(i + b), gain=.22, send=.15)
                for i in (6, 7, 14, 15):
                    s.add(snare(.14), s.at(b) + i * e, gain=.4, pan=.1, send=.15)
                for _ in range(2):
                    s.add(drop(hz(int(RNG.choice(tl)) + 36), .5), s.at(b, RNG.random() * 4),
                          pan=float(RNG.uniform(-.8, .8)), gain=.5, send=.7)
            if ph == 3:                                                   # sinos e arpejos
                for i in range(8):
                    s.add(bell(hz(tl[i % 3] + 24), 1.6, bright=1.1), s.at(b, i / 2),
                          pan=.5 * np.sin(i), gain=.15, send=.35)
                if b % 4 == 3:
                    for i in range(8):
                        s.add(taiko(hz(r) * 1.05, .5), s.at(b, 3) + i * s.spb / 8, gain=.2 + .5 * i / 8)
            if ph == 1 and b in (6, 14):                                  # eco da caixinha e das gotas
                s.add(bell(hz('D6'), 2.4), s.at(b, 2), gain=.2, pan=.3, send=.6)
                s.add(drop(hz('A5'), .5), s.at(b, 3), gain=.3, pan=-.4, send=.7)
        # Tema da Cavaleira em todas as fases, cada vez mais forte
        strg = lambda f, d: string(f, d, a=.05, r=.3, cut=3200 + 600 * ph)
        hrn = lambda f, d: horn(f, d, a=.06, r=.3, dark=900, bright=3200)
        if ph == 1:
            starts, th, g = (0, 8), CAV, .5
        elif ph == 2:
            starts, th, g = (0, 4, 8, 12), [(n, d / 1.5) for n, d in CAV], .6
        else:
            starts, th, g = (0, 4, 8, 12), CAV_DM, .72
        for bar in starts:
            seq(s, bar, th, strg, gain=g, pan=-.1, send=.3)
            seq(s, bar, transp(th, -12), hrn, gain=.3 + .08 * ph, send=.3)
            if ph == 3:
                seq(s, bar, transp(th, 12), strg, gain=.28, pan=.3, send=.3)
        if ph == 2:
            for bar in (7, 15):
                s.add(sweep(s.barsec(bar), 400, 6000, shape=lambda u: u ** 1.6), s.at(bar), gain=.4)
        out[f'mus_boss_guardiao_{ph}'] = (master(s.render(), -14), True)
    return out


# ------------------------------------------------------------ stingers ------
def stinger_vitoria():
    reseed(151)
    s = Song(60, 7, tail=4, rt60=3.8, lpf=5000)
    notes = [('F4', 0, .9), ('E4', .9, .9), ('D4', 1.8, .9), ('C4', 2.7, .9), ('D4', 3.6, 3.2)]
    for nt, t0, d in notes:
        s.add(string(hz(nt), d, a=.06, r=.6, cut=3200), t0, gain=.55, pan=-.1, send=.5)
        s.add(bell(hz(nt) * 2, 2.5), t0, gain=.3, pan=.25, send=.6)
    for t0, ch_ in ((0, ['G2', 'D3', 'Bb3']), (1.8, ['A2', 'E3', 'C#4']), (2.7, ['F2', 'C3', 'A3'])):
        for i, nt in enumerate(ch_):
            s.add(pad(hz(nt), .9, a=.2, r=.8, cut=1200), t0, pan=-.3 + .3 * i, gain=.2, send=.5)
    for i, nt in enumerate(['D2', 'A2', 'D3', 'F#3', 'A3', 'D4']):           # Re maior (picardia)
        s.add(pad(hz(nt), 3.0, a=.5, r=2.0, cut=1600), 3.6, pan=-.5 + .2 * i, gain=.2, send=.5)
    for i, nt in enumerate(['D4', 'F#4', 'A4']):
        s.add(choir(hz(nt), 2.6, 'ah', a=.9, r=1.5, lowcut=3000), 3.7, pan=-.3 + .3 * i, gain=.18, send=.6)
    s.add(bell(hz('F#5'), 3.2), 3.9, gain=.22, pan=.3, send=.7)
    return {'stinger_vitoria': (master(s.render(loop=False, total=7.5, fade_out=1.2), -16), False)}


def stinger_morte():
    reseed(161)
    s = Song(60, 4, tail=3, rt60=3.0, lpf=3800)
    seqn = ['D5', 'F5', 'A5', 'G5', 'F5', 'E5', 'D5']
    t0 = 0.0
    gaps = [.34, .38, .46, .6, .8, 1.05, 1.4]
    for i, (nt, g) in enumerate(zip(seqn, gaps)):
        f = hz(nt) * (1 - .035 * i ** 1.35) * 2 ** (RNG.uniform(-25, 25) * i / 6 / 1200)
        s.add(bell(f, 1.6, fall=.9), t0, gain=.55 * (1 - .08 * i), pan=.3 * (-1) ** i, send=.6)
        t0 += g
    n = int(4.4 * SR)
    fr = 82 * (38 / 82) ** np.clip(tt(n) / 4.4, 0, 1)
    dr = (np.sin(2 * np.pi * np.cumsum(fr) / SR) + .4 * osc_saw(fr, n) * .3) * np.linspace(1, 0, n) ** 1.5
    s.add(nrm(lp(dr, 600)) * env_ar(n, .2, .3), 0, gain=.5, send=.3)
    return {'stinger_morte': (master(s.render(loop=False, total=4.8, fade_out=1.0), -16), False)}


def stinger_evolucao():
    reseed(171)
    s = Song(60, 8, tail=4, rt60=3.5, lpf=6000)
    for k in range(26):                                                  # rachaduras de casca
        tm = 0.05 + 1.7 * (k / 26) ** .8
        s.add(leg_click(), tm, gain=.35 + .5 * k / 26, pan=float(RNG.uniform(-.7, .7)), send=.2)
        if k % 5 == 0:
            n = int(.08 * SR)
            s.add(nrm(hp(white(n), 900, 2) * exp_dec(n, .02)), tm, gain=.45, send=.2)
    n = int(4.4 * SR)                                                    # pad em espiral ascendente
    u = tt(n) / 4.4
    fr = 110 * 8 ** u
    sp = lp(osc_saw(fr, n), 2400) + .5 * osc_sine(fr * 2.0, n)
    s.add(nrm(sp * env_ar(n, 1.5, .8)), 0.8, gain=.35, send=.5)
    for i, nt in enumerate(['D4', 'F#4', 'A4', 'E5']):                   # coral abre num acorde brilhante
        s.add(choir(hz(nt), 3.2, 'ah', a=2.0, r=1.8, lowcut=5000), 3.0, pan=-.4 + .27 * i,
              gain=.22, send=.5)
    th = [(nt, d * .33) for nt, d in transp(CAV, 24)[:-1]]                # Tema nos sinos, rapido
    t0 = 3.4
    for nt, d in th:
        s.add(bell(hz(nt), 1.8, bright=1.1), t0, gain=.45, pan=.3, send=.5)
        t0 += d
    s.add(glass(hz('D6'), 2.6, a=.15, r=1.6), t0, gain=.35, pan=-.1, send=.6)   # nota longa aguda
    s.add(bell(hz('D6'), 4.0, bright=1.2), t0, gain=.35, send=.7)
    s.add(bell(hz('A6'), 3.0, ratios=(1, 2.0, 3.0), amps=(1, .3, .1)), t0 + .1, gain=.2, pan=.4, send=.7)
    return {'stinger_evolucao': (master(s.render(loop=False, total=8.6, fade_out=1.3), -16), False)}


def stinger_segredo():
    reseed(181)
    s = Song(60, 3, tail=2, rt60=3.0, lpf=7000)
    for i, nt in enumerate(['D5', 'F5', 'A5', 'D6']):
        s.add(bell(hz(nt), 1.7, bright=1.15), .13 * i, gain=.55, pan=-.3 + .2 * i, send=.5)
    s.add(bell(hz('D7'), 1.4, ratios=(1, 2.4, 4.1), amps=(1, .3, .1)), .52, gain=.2, pan=.3, send=.7)
    s.add(bell(hz('A6'), 1.6, ratios=(1, 2.4), amps=(1, .3)), .39, gain=.2, pan=-.3, send=.7)
    return {'stinger_segredo': (master(s.render(loop=False, total=2.8, fade_out=.7), -16), False)}


def casulo():
    reseed(191)
    s = Song(66, 24, bar_beats=3, tail=6, rt60=2.8, lpf=4200)
    prog = [('D2', 'min'), ('Bb1', 'maj'), ('G1', 'min'), ('A1', 'maj')]
    box = lambda f, d: bell(f, 2.4)
    lullaby = [('D4', 1), ('F4', 1), ('A4', 1), ('G4', 1.5), ('F4', .5), ('E4', 1),
               ('D4', 1), ('C4', 1), ('D4', 1)]
    for b in range(24):
        r, k = prog[b % 4]
        m = midi(r)
        for i, mm in enumerate([m + 12, m + 12 + SH[k][1], m + 12 + SH[k][2], m + 24]):
            s.add(pad(hz(mm), s.barsec(b) + .5, a=1.5, r=2.0, cut=900, sub=.2), s.at(b),
                  pan=-.4 + .27 * i, gain=.2, send=.5)
        s.add(bass(hz(m), s.barsec(b) * .9, cut=300, a=.3, r=.6), s.at(b), gain=.28)
    for ph in range(6):
        b0 = ph * 4
        up = 12 if ph == 4 else 0
        seq(s, b0, transp(lullaby, up + 12), box, gain=.5 if ph < 5 else .38, pan=-.1, send=.6)
        if 2 <= ph <= 3:
            seq(s, b0, lullaby, lambda f, d: string(f, d, a=.1, r=.5, cut=1800), gain=.18,
                pan=.2, send=.5)
        if ph == 5:
            s.add(bell(hz('A5'), 3.0), s.at(b0 + 3, 1), gain=.2, pan=.3, send=.7)
    s.bed(lambda n: lp(white(n), 260, 2) * (.55 + .45 * np.sin(2 * np.pi * 12 * np.arange(n) / s.N)),
          gain=.9, rms=.14, send=.1)
    return {'mus_casulo': (master(s.render(), -20), True)}


def menu():
    reseed(201)
    s = Song(76, 24, tail=7, rt60=3.4, lpf=4800)
    prog = (['Dm', 'Bb', 'Gm', 'A'] + ['Dm', 'F', 'Bb', 'A'] + ['Dm', 'Bb', 'Gm', 'A'] +
            ['Bb', 'F', 'Gm', 'A'] + ['Dm', 'Bb', 'F', 'A'] + ['Gm', 'Bb', 'C', 'A'])
    ROOTS['C'] = ('C2', 'maj')
    for b in range(24):
        nm = prog[b]
        tl = ctones(nm, 12)
        d = s.barsec(b) + .5
        for i, mm in enumerate(tl + [tl[0] + 12]):                      # pad de caverna
            s.add(pad(hz(mm), d, a=1.4, r=2.2, cut=1200), s.at(b), pan=-.5 + .33 * i,
                  gain=.15, send=.7)
        if b >= 4:                                                      # cordas
            for i, mm in enumerate(tl):
                s.add(string(hz(mm + 12), d, a=1.0, r=1.2, cut=2200), s.at(b), pan=-.3 + .3 * i,
                      gain=.12, send=.5)
        if 12 <= b < 20:                                                # coral distante
            for i, mm in enumerate(tl[:3]):
                s.add(choir(hz(mm + 12), d, 'ah', a=1.2, r=1.5, lowcut=2200), s.at(b),
                      pan=-.4 + .4 * i, gain=.11, send=.9)
            s.add(bell(hz(tl[2] + 36), 3.0, bright=1.05), s.at(b, 1.5), gain=.14, pan=.4, send=.8)
        pool = [m_ + 36 for m_ in tl] + [m_ + 48 for m_ in tl]
        for tb in np.sort(RNG.random(int(RNG.integers(1, 3))) * 4):    # gotas
            s.add(drop(hz(int(RNG.choice(pool))), .5), s.at(b, tb), pan=float(RNG.uniform(-.8, .8)),
                  gain=float(RNG.uniform(.3, .55)), send=.8)
    for b in (0, 8, 16):
        s.add(bell(hz('D3'), 7, ratios=(1, 2.4, 4.1, 6.3), amps=(1, .5, .3, .15)), s.at(b),
              gain=.4, send=.8)
    f0 = s.qf(73.4)
    t_ = np.arange(s.N) / SR
    s.add((np.sin(2 * np.pi * f0 * t_) + .35 * np.sin(4 * np.pi * f0 * t_)) / 1.35, 0, gain=.22, send=.1)
    strg = lambda f, d: string(f, d, a=.1, r=.4, cut=3500)
    box = lambda f, d: bell(f, 2.5)
    for b0 in (4, 16):
        seq(s, b0, CAV, strg, gain=.55, pan=-.1, send=.5)
        seq(s, b0, transp(CAV, 12), strg, gain=.2, pan=.2, send=.5)
        seq(s, b0 + 3, transp(CAV, 12), box, gain=.45, pan=.15, send=.7)
    return {'mus_menu': (master(s.render(), -18), True)}


TRACKS = {'portao': portao, 'guardiao': guardiao,
          'stinger_vitoria': stinger_vitoria, 'stinger_morte': stinger_morte,
          'stinger_evolucao': stinger_evolucao, 'stinger_segredo': stinger_segredo,
          'casulo': casulo, 'menu': menu}
