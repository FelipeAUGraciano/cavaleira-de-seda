"""Cacada (Galerias ocupadas), Alerta, Capita da expedicao, Fuga da Mae."""
from cs_synth import *

SH = SHAPES


def cacada():
    reseed(91)
    s = Song(84, 32, tail=6, rt60=2.0, lpf=4000)
    s.add_bus('far', 3.8, 2500)
    prog = [('E2', 'min'), ('C2', 'maj'), ('A1', 'min'), ('B1', 'dom7')]

    for b in range(32):
        r, k = prog[b % 4]
        m = midi(r)
        tones = [m + 12, m + 12 + SH[k][1], m + 12 + SH[k][2], m + 24]
        for i, mm in enumerate(tones):                       # pad seco e curto
            s.add(pad(hz(mm), s.barsec(b) * .8, a=.8, r=1.4, cut=900),
                  s.at(b), pan=-.4 + .27 * i, gain=.11, send=.35)
        s.add(bass(hz(m), 1.2, cut=400, decay=.6), s.at(b), gain=.35, send=.1)
        pool = [m + 36 + x for x in SH[k]]
        for tb in np.sort(RNG.random(int(RNG.integers(1, 3))) * 4):   # poucas gotas
            s.add(drop(hz(int(RNG.choice(pool))), .5), s.at(b, tb),
                  pan=float(RNG.uniform(-.8, .8)), gain=float(RNG.uniform(.25, .5)), send=.6)
        if b % 4 == 2:                                       # marimba esparsa
            s.add(marimba(hz(m + 24 + SH[k][2]), 1.2), s.at(b, 1.5), gain=.35,
                  pan=float(RNG.uniform(-.5, .5)), send=.4)

    # os dois temas disputando o espaco
    marim = lambda f, d: marimba(f, 1.7)
    cav = transp(CAV, 2)                                   # Re menor -> Mi menor
    muff = lambda f, d: horn(f, d, a=.1, r=.3, dark=450, bright=950)
    for bar in (4, 12, 20):
        seq(s, bar, cav, marim, gain=.7, pan=-.2, send=.5)
    seq(s, 28, cav[:5], marim, gain=.55, pan=-.2, send=.6)
    for bar in (8, 16, 24):
        seq(s, bar, EXP, muff, gain=.55, pan=.3, send=1.0, bus='far')
        seq(s, bar, transp(EXP, -12), muff, gain=.35, pan=.2, send=1.0, bus='far')
        # rufo de caixa distante antes da entrada das trompas
        for i in range(12):
            s.add(snare(.15, bright=2200), s.at(bar - 1, 2.5) + i * s.spb * .5 / 12 * 3 / 1.0 * .5,
                  gain=.12 + .35 * i / 12, pan=.3, send=1.0, bus='far')
    for b in range(0, 32, 2):
        s.add(snare(.15, bright=2200), s.at(b, 3), gain=.12, pan=.3, send=1.0, bus='far')
    s.bed(lambda n: crackle_sig(n, 14, 1200, 6500), gain=.22, pan=-.2, send=.2, peak=1)
    s.bed(lambda n: crackle_sig(n, 10, 1500, 7000), gain=.18, pan=.35, send=.2, peak=1)

    # ---- camada de tensao: marcha completa
    t = Song(84, 32, tail=5, rt60=1.4, lpf=4500)
    t.add_bus('near', 2.4, 3500)
    acc = [1, .3, .5, .3, .7, .3, .5, .3, 1, .3, .5, .3, .7, .3, .6, .5]
    e16 = t.spb / 4
    for b in range(32):
        for i in range(16):
            t.add(snare(.15, bright=2500), t.at(b) + i * e16, gain=.5 * acc[i],
                  pan=.15, send=.15)
        t.add(thump(75, 48, .45, .05, .15, drive=1.5), t.at(b), gain=.9, send=.1)
        t.add(thump(70, 46, .4, .05, .14, drive=1.5), t.at(b, 2), gain=.75, send=.1)
    near = lambda f, d: horn(f, d, a=.05, r=.25, dark=900, bright=3500)
    for b in range(0, 32, 4):
        seq(t, b, transp(EXP, 12), near, gain=.6, pan=.2, send=.35, bus='near')
        seq(t, b, EXP, near, gain=.35, pan=-.2, send=.35, bus='near')
        for j, nt in enumerate(('A3', 'E4')):
            t.add(horn(hz(nt), 2 * 4 * t.spb - .3, a=.2, r=.5, dark=700, bright=2400),
                  t.at(b + 2), pan=(-.3, .3)[j], gain=.28, send=.4, bus='near')
    return {'mus_cacada': (master(s.render(), -18), True),
            'mus_cacada_tensao': (master(t.render(), -18), True)}


def alerta():
    reseed(101)
    s = Song(84, 16, tail=5, rt60=1.8, lpf=4000)
    e16 = s.spb / 4
    acc = [1, .35, .6, .35, .8, .35, .6, .35]
    for b in range(16):
        for i in range(16):
            s.add(snare(.14, bright=2600), s.at(b) + i * e16, gain=.38 * acc[i % 8] * (1.15 if i % 8 == 0 else 1),
                  pan=.1, send=.15)
        for i in range(8):                                       # cordas graves em ostinato
            nt = 'E2' if i % 4 < 3 else 'B2'
            s.add(bass(hz(nt), .17, cut=520, decay=.14), s.at(b, i / 2),
                  gain=.5 * (1 if i % 2 == 0 else .7), send=.1)
        for beat in range(4):                                    # passos em formacao
            s.add(thump(80, 45, .3, .04, .1), s.at(b, beat), pan=(-.35, .35)[beat % 2],
                  gain=.35, send=.1)
        n = int(1.2 * SR)                                        # prato abafado
        s.add(lp(nrm(hp(white(n), 4000, 2) * exp_dec(n, .3)), 6500), s.at(b), gain=.25, pan=-.3,
              send=.3)
    hrn = lambda f, d: horn(f, d, a=.04, r=.25, dark=900, bright=3800)
    for b in range(0, 16, 2):
        seq(s, b, EXP, hrn, gain=.55, pan=.2, send=.3)
        seq(s, b, transp(EXP, 12), hrn, gain=.3, pan=-.2, send=.3)
    # gritos distantes: formantes sinteticos curtos e abafados (sem voz real)
    for bar, bt, nt in ((2, 1.5, 'D3'), (5, 3, 'F3'), (9, 0.5, 'E3'), (13, 2.5, 'D3'), (14, 3.5, 'G3')):
        s.add(choir(hz(nt), .2, 'ah', a=.02, r=.12, lowcut=1500, vdepth=.01),
              s.at(bar, bt), pan=float(RNG.uniform(-.7, .7)), gain=.28, send=.7)
    return {'mus_cacada_alerta': (master(s.render(), -18), True)}


def capita():
    reseed(111)
    s = Song(124, 32, tail=6, rt60=2.0, lpf=5000)
    s.add_bus('hall', 3.2, 4500)
    pr = {'Am': ('A1', 'min'), 'F': ('F1', 'maj'), 'C': ('C2', 'maj'), 'G': ('G1', 'maj'),
          'Dm': ('D2', 'min'), 'E': ('E2', 'dom7')}
    blocks = [['Am', 'F', 'C', 'G']] * 6 + [['Am', 'F', 'Dm', 'E']] + [['Am', 'F', 'E', 'E']]
    # quem toca em cada bloco: E=Expedicao (metais), C=Cavaleira (cordas), EC=ambos
    who = ['E', 'C', 'E', 'C', 'EC', 'C', 'E', 'EC']
    brass = lambda f, d: horn(f, d, a=.05, r=.25, dark=1000, bright=4200)
    strg = lambda f, d: string(f, d, a=.04, r=.25, cut=4000)
    e8 = s.spb / 2
    for blk in range(8):
        for j in range(4):
            b = blk * 4 + j
            r, k = pr[blocks[blk][j]]
            m = midi(r)
            tl = [m + 12, m + 12 + SH[k][1], m + 12 + SH[k][2]]
            if k == 'dom7':
                tl = [m + 12, m + 16, m + 19]
            for i, mm in enumerate(tl):                     # base de cordas
                s.add(string(hz(mm + 12), s.barsec(b), a=.05, r=.3, cut=2500),
                      s.at(b), pan=-.4 + .4 * i, gain=.14, send=.3, bus='hall')
            # baixo
            for beat, off in enumerate((0, 7, 0, 7)):
                s.add(bass(hz(m + off + (12 if off else 0)), .35, cut=500, decay=.3), s.at(b, beat),
                      gain=.45 * (1 if beat % 2 == 0 else .7), send=.1)
            # bumbo / caixa de marcha
            s.add(thump(85, 48, .4, .05, .15, drive=1.4), s.at(b), gain=.9, send=.1)
            s.add(thump(80, 46, .35, .05, .13, drive=1.4), s.at(b, 2), gain=.75, send=.1)
            for beat in (1, 3):
                s.add(snare(.18, bright=2400), s.at(b, beat), gain=.55, pan=.1, send=.15)
            for i in range(16):                                # rufos fantasmas
                if i % 4 in (1, 3) and RNG.random() < .5:
                    s.add(snare(.1, bright=3000), s.at(b) + i * s.spb / 4, gain=.15, pan=.15, send=.1)
            # cordas rapidas (ostinato em colcheias)
            if 'C' not in who[blk] or j == 3:
                for i in range(8):
                    s.add(string(hz(tl[i % 3] + 12), .1, a=.004, r=.04, cut=3500),
                          s.at(b, i / 2), pan=.4 * (-1) ** i, gain=.2, send=.2)
            # espada no escudo
            if j == 3:
                s.add(anvil(hz('A4') * 2, .5), s.at(b, 3.5), gain=.55, pan=.2, send=.3)
        b0 = blk * 4
        if 'E' in who[blk]:
            up = 12
            seq(s, b0, transp(EXP, up), brass, gain=.6, pan=.2, send=.35, bus='hall')
            seq(s, b0, EXP, brass, gain=.35, pan=-.2, send=.35, bus='hall')
            seq(s, b0 + 2, transp(EXP, up), brass, gain=.5, pan=.2, send=.35, bus='hall') \
                if blk % 2 == 0 and blk > 3 else None
        if 'C' in who[blk]:
            seq(s, b0 + (0 if who[blk] == 'EC' else 0), transp(CAV, 12 if who[blk] == 'EC' else 0),
                strg, gain=.55, pan=-.25, send=.35, bus='hall')
            seq(s, b0 + 2 if who[blk] == 'C' else b0 + 2, transp(CAV, 0)[:5], strg, beat=2,
                gain=.3, pan=-.25, send=.35, bus='hall')
    # ---- trompa (sem loop): La - Mi
    H = Song(124, 2, tail=3.0, rt60=4.5, lpf=4500)
    H.add(horn(hz('A3'), H.barsec(0) - .1, a=.3, r=.5, dark=900, bright=3200), 0, gain=.9, send=.7)
    H.add(horn(hz('E4'), H.barsec(1) - .1, a=.25, r=1.0, dark=900, bright=3400), H.at(1), gain=.9, send=.7)
    H.add(horn(hz('A2'), H.barsec(0) - .1, a=.4, r=.5, dark=600, bright=1500), 0, gain=.3, send=.7)
    trompa = H.render(loop=False, total=H.dur + 3.0, fade_out=.8)
    return {'mus_boss_capita': (master(s.render(), -14), True),
            'mus_boss_capita_trompa': (master(trompa, -14), False)}


def fuga():
    reseed(121)
    s = Song(150, 16, tail=5, rt60=1.6, lpf=4500)
    e16 = s.spb / 4
    prog = [('D2', 'min'), ('Bb1', 'maj'), ('C2', 'maj'), ('A1', 'sus4')]
    arp = [0, 1, 2, 3, 2, 1, 0, 1] * 2
    for b in range(16):
        r, k = prog[b % 4]
        m = midi(r)
        tl = [m + 24, m + 24 + SH[k][1], m + 24 + SH[k][2], m + 36]
        for i in range(16):                                      # ostinato de cordas em 16as
            s.add(string(hz(tl[arp[i]]), .07, a=.003, r=.03, cut=3200),
                  s.at(b) + i * e16, pan=.45 * np.sin(i + b), gain=.26 * (1.3 if i % 4 == 0 else 1),
                  send=.15)
        if k == 'sus4':                                          # A sus4 resolvendo em A
            for i in range(8, 16):
                s.add(string(hz(m + 24 + 4), .07, a=.003, r=.03, cut=3200),
                      s.at(b) + i * e16, pan=.3, gain=.1, send=.15) if i % 2 == 0 else None
        for i in range(8):                                       # baixo pulsante em colcheias
            s.add(bass(hz(m), .12, cut=450, decay=.12), s.at(b, i / 2),
                  gain=.65 * (1 if i % 2 == 0 else .75), send=.05)
        toms = {0: 110, 3: 90, 6: 100, 8: 80, 10: 100, 12: 90, 14: 120}   # tambores rapidos
        for i, f0 in toms.items():
            s.add(thump(f0 * 1.2, f0 * .55, .25, .03, .09), s.at(b) + i * e16,
                  pan=(-.3, .3)[i % 2], gain=.5, send=.1)
        for beat in (1, 3):
            s.add(snare(.15), s.at(b, beat), gain=.45, pan=.1, send=.1)
        if b % 4 == 0:                                           # rugido grave
            n = int(2.6 * SR)
            tt_ = tt(n)
            fr = 130 * (45 / 130) ** np.clip(tt_ / 2.6, 0, 1)
            saw_ = np.tanh(3 * osc_saw(fr, n))
            roar = nrm(saw_ + 1.2 * sweep(2.6, 1800, 150, shape=lambda u: (1 - u) ** .5))
            s.add(roar * np.concatenate([np.linspace(0, 1, int(.04 * SR)),
                                         np.exp(-np.arange(n - int(.04 * SR)) / (1.1 * SR))]),
                  s.at(b), gain=.75, send=.2)
    th = [(n, d / 2) for n, d in transp(CAV, 12)]                # Tema acelerado, por cima
    hi = lambda f, d: string(f, d, a=.01, r=.1, cut=5000, vdepth=.006)
    for b in (8, 10, 12, 14):
        seq(s, b, th, hi, gain=.6, pan=.1, send=.25)
        seq(s, b, transp(th, 12), hi, gain=.22, pan=-.2, send=.25)
    return {'mus_fuga_mae': (master(s.render(), -14), True)}


TRACKS = {'cacada': cacada, 'alerta': alerta, 'capita': capita, 'fuga': fuga}
