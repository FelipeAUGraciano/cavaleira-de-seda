"""Rio de Brasa e Salamandra-rainha (Mi frigio dominante)."""
from cs_synth import *

SH = SHAPES

# acordes do ciclo de 8 compassos: E F E Dm/E | E F G#dim->E E
CH = {'E': ['E2', 'B2', 'E3', 'G#3', 'B3'],
      'F': ['F2', 'C3', 'F3', 'A3', 'C4'],
      'DmE': ['E2', 'A2', 'D3', 'F3', 'A3'],
      'Gd': ['G#2', 'B2', 'D3', 'F3', 'B3']}
CYC = ['E', 'F', 'E', 'DmE', 'E', 'F', 'Gd', 'E']
ROOT = {'E': 'E2', 'F': 'F2', 'DmE': 'E2', 'Gd': 'G#2'}


def organ(f, dur, a=.15, r=.4, cut=1400, drive=1.8):
    return nrm(np.tanh(drive * pad(f, dur, a=a, r=r, cut=cut, dets=(-4, 0, 4))))


def _organ_bar(s, b, gain, chk=None, drive=1.8, cut=1400, a=.15):
    name = chk or CYC[b % 8]
    d = s.barsec(b) + .15
    if name == 'Gd':                              # G#dim de passagem -> E
        for i, nt in enumerate(CH['Gd']):
            s.add(organ(hz(nt), 2 * s.spb, a=a, r=.1, cut=cut, drive=drive), s.at(b),
                  pan=-.4 + .2 * i, gain=gain, send=.25)
        for i, nt in enumerate(CH['E']):
            s.add(organ(hz(nt), 2 * s.spb, a=.05, r=.4, cut=cut, drive=drive), s.at(b, 2),
                  pan=-.4 + .2 * i, gain=gain, send=.25)
        return
    for i, nt in enumerate(CH[name]):
        s.add(organ(hz(nt), d, a=a, r=.4, cut=cut, drive=drive), s.at(b),
              pan=-.4 + .2 * i, gain=gain, send=.25)


def _trills(s, b, gain):
    nm = CYC[b % 8]
    p = ('F5', 'G#5') if nm == 'F' else ('E5', 'F5')
    for i in range(16):
        s.add(organ(hz(p[i % 2]), .09, a=.003, r=.03, cut=3200, drive=1.5), s.at(b, i / 4),
              pan=.3 * (-1) ** i, gain=gain, send=.2)


def rio():
    reseed(71)
    s = Song(96, 32, tail=6, rt60=2.2, lpf=4500)
    e = s.spb / 2
    forge = lambda b: (4 <= b < 20) or b >= 24
    for b in range(32):
        brk = 20 <= b < 24
        g = .14 if b < 4 else (.2 if brk else .12)
        _organ_bar(s, b, g, a=1.2 if b < 4 else .15)
    # forja 3+3+2
    for b in range(32):
        if not forge(b):
            continue
        nm = CYC[b % 8]
        fa = hz('F4') if nm == 'F' else hz('E4')
        for (pos, ln, ga, fq, ka) in ((0, 3, .9, fa, 1.0), (3, 3, .6, fa * 1.5, .75),
                                       (6, 2, .45, fa * 2, .55)):
            s.add(anvil(fq, .7), s.at(b) + pos * e, pan=(-.15, .1, .25)[pos // 3],
                  gain=ga * .8, send=.3)
            if pos < 6:
                s.add(thump(100, 50, .4, .04, .14, drive=2.0), s.at(b) + pos * e, gain=.7 * ka)
            s.add(horn(hz(ROOT[nm]), ln * e, a=.03, r=.08, dark=500, bright=1100),
                  s.at(b) + pos * e, gain=.6 * ka, send=.1)
    # melodia em "flauta de pedra"
    mel = [('E4', 2), ('F4', 1), ('G#4', 1),
           ('A4', 1.5), ('G#4', .5), ('F4', 1), ('E4', 1),
           ('B4', 2), ('A4', 1), ('G#4', 1),
           ('F4', 1), ('E4', 1), ('D4', 2),
           ('G#4', 1), ('A4', 1), ('B4', 2),
           ('C5', 1.5), ('B4', .5), ('A4', 1), ('G#4', 1),
           ('F4', 1), ('G#4', 1), ('B4', 1), ('A4', 1),
           ('G#4', 2), ('E4', 2)]
    fl = lambda f, d: flute(f, d, a=.06, r=.12)
    seq(s, 12, mel, fl, gain=.5, pan=.1, send=.5)
    seq(s, 24, transp(mel, 12), fl, gain=.42, pan=-.1, send=.5)
    # geiseres
    for bar in (6, 10, 14, 22, 27):
        s.add(sweep(1.8, 400, 2400, shape=lambda u: np.sin(np.pi * u) ** 1.5), s.at(bar, 1),
              pan=float(RNG.uniform(-.7, .7)), gain=.22, send=.4)
    # crepitar de brasa
    ramp = lambda n: np.interp(np.arange(n), [0, s.at(20) * SR, s.at(20) * SR + 22050,
                                               s.at(24) * SR - 22050, s.at(24) * SR, n],
                               [0, 0, 1, 1, 0, 0])
    s.bed(lambda n: crackle_sig(n, 22), gain=.2, send=.2, peak=1)
    s.bed(lambda n: crackle_sig(n, 45) * ramp(n), gain=.35, send=.2, pan=.2, peak=1)

    # ---- camada de tensao
    t = Song(96, 32, tail=5, rt60=1.8, lpf=4000)
    et = t.spb / 2
    for b in range(32):
        for i in range(8):
            t.add(taiko(72, .9), t.at(b) + i * et, gain=(.8 if i in (0, 3, 6) else .45),
                  pan=-.1 + .05 * i, send=.15)
        _trills(t, b, .22)
    for b in range(0, 32, 4):
        t.add(sweep(t.at(b + 4) - t.at(b), 300, 3600, shape=lambda u: u ** 1.5), t.at(b),
              pan=float(RNG.uniform(-.5, .5)), gain=.5, send=.2)
    return {'mus_rio': (master(s.render(), -18), True),
            'mus_rio_tensao': (master(t.render(), -20), True)}


def rainha():
    reseed(81)
    s = Song(132, 32, tail=6, rt60=2.6, lpf=4500)
    e = s.spb / 2
    for b in range(32):
        g = .12 if b < 4 else .17
        _organ_bar(s, b, g, drive=3.0, cut=1700)
    # taiko e forja acelerada
    for b in range(32):
        s.add(taiko(62, 1.5), s.at(b), gain=1.0, send=.25)
        s.add(taiko(70, 1.0), s.at(b, 2), gain=.65, send=.25)
        if b >= 4:
            nm = CYC[b % 8]
            fa = hz('F4') if nm == 'F' else hz('E4')
            for pos, ga, fq in ((0, .8, fa), (3, .55, fa * 1.5), (6, .4, fa * 2)):
                s.add(anvil(fq, .6), s.at(b) + pos * e, pan=(-.2, .1, .25)[pos // 3],
                      gain=ga * (.9 if 12 <= b < 16 else .6), send=.25)
    for bar in (4, 16, 24):
        s.add(plate(150, 3.2), s.at(bar), gain=.45, send=.4)
    # tema da Rainha: largo e regio (metais)
    A = [('E4', 2), ('F4', 1), ('G#4', 1), ('B4', 3), ('A4', 1), ('C5', 2), ('B4', 1), ('A4', 1),
         ('G#4', 4)]
    B = [('E5', 2), ('D5', 1), ('C5', 1), ('B4', 2), ('A4', 1), ('G#4', 1), ('F4', 2),
         ('G#4', 1), ('A4', 1), ('E4', 4)]
    th = A + B
    brass = lambda f, d: horn(f, d, a=.08, r=.3, dark=900, bright=3600)
    for bar, up in ((4, 0), (16, 12), (24, 12)):
        seq(s, bar, th, brass, gain=.6, pan=.05, send=.35)
        seq(s, bar, transp(th, -12), brass, gain=.4, pan=-.15, send=.35)
        if up:
            seq(s, bar, transp(th, 12), brass, gain=.25, pan=.2, send=.35)
    # acordes cheios de metais nas secoes tematicas
    for b in list(range(4, 12)) + list(range(16, 28)):
        nm = CYC[b % 8]
        if nm == 'Gd':
            nm = 'E'
        for i, nt in enumerate(CH[nm][1:]):
            s.add(horn(hz(nt) * 2 if i else hz(nt), s.barsec(b), a=.05, r=.3, dark=700, bright=2800),
                  s.at(b), pan=-.5 + .3 * i, gain=.2, send=.3)
    # Tema da Cavaleira em contraponto nas cordas
    strg = lambda f, d: string(f, d, a=.06, r=.3, cut=4200)
    seq(s, 16, transp(CAV, 12), strg, beat=0, gain=.4, pan=.3, send=.4)
    seq(s, 24, transp(CAV, 12), strg, beat=0, gain=.4, pan=-.3, send=.4)
    seq(s, 20, transp(CAV, 12), strg, beat=2, gain=.3, pan=.3, send=.4)
    # fogo
    for bar in (7, 15, 23, 31):
        s.add(sweep(s.barsec(bar), 300, 3800, shape=lambda u: u ** 1.4), s.at(bar), gain=.4,
              pan=float(RNG.uniform(-.5, .5)), send=.2)
    s.bed(lambda n: crackle_sig(n, 40), gain=.22, send=.2, peak=1)
    # rufo de caixa no fim (build para o loop)
    nroll = 4 * 8
    for i in range(nroll):
        s.add(snare(), s.at(30) + i * s.spb * 8 / nroll * 1.0, gain=.2 + .6 * i / nroll, send=.2)

    # ---- camada de furia
    t = Song(132, 32, tail=5, rt60=2.0, lpf=4500)
    et = t.spb / 2
    for b in range(32):
        for i in range(8):
            t.add(taiko(75, .8), t.at(b) + i * et, gain=(.8 if i % 2 == 0 else .5),
                  pan=-.15 + .04 * i, send=.15)
        _trills(t, b, .2)
        nm = CYC[b % 8]
        for j, nt in enumerate(('E5', 'B5') if nm != 'F' else ('F5', 'C6')):
            t.add(choir(hz(nt), t.barsec(b) - .5, 'ah', a=.4, r=.6, lowcut=3500),
                  t.at(b), pan=(-.35, .35)[j], gain=.2, send=.5)
    for b in range(0, 32, 4):
        t.add(sweep(t.at(b + 4) - t.at(b), 400, 4200, shape=lambda u: u ** 1.5), t.at(b),
              gain=.45, send=.2)
    t.bed(lambda n: crackle_sig(n, 70), gain=.3, send=.2, peak=1)
    return {'mus_boss_rainha': (master(s.render(), -14), True),
            'mus_boss_rainha_tensao': (master(t.render(), -16), True)}


TRACKS = {'rio': rio, 'rainha': rainha}
