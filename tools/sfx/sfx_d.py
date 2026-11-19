"""Ambiente dos mapas (estereo, 40 s em loop), fontes no mundo e interface."""
from sfx_lib import *
from cs_synth import Song


def amb(rt60, lpf=4500):
    return Song(60, 1, bar_beats=40.0, tail=6.0, rt60=rt60, lpf=lpf)       # N = 40,000 s exatos


def drip(f):
    return mix([(cs.drop(f, .35), 0, 1.0), (modal([f * 2.6, f * 4.1], [.3, .15], [.06, .04], .25), 0, .25)], dur=.35)


def pan_r():
    return J(-.85, .85)


def wind(s, lo, hi, k, pan, rms=.08, send=.3):
    s.bed(lambda n: bp(white(n), lo, hi) * (.5 + .5 * s.per(k, n, J(0, 6))), gain=1.0, pan=pan, rms=rms, send=send)


def creak(d):
    n = Nn(d)
    fr = J(180, 380) * (1 + .08 * np.sin(2 * np.pi * 9 * tt(n)))
    x = np.sin(2 * np.pi * np.cumsum(fr) / SR) * hump(n, .4, 1.0) + .2 * bp(white(n), 800, 2500) * hump(n, .4, 1.0)
    return nrm(x)


@sfx('amb_bercario', 1, 'b', loop=True, stereo=True, d=40.0)
def amb_bercario(v):
    s = amb(2.0, 3500)
    s.add_bus('far', 3.5, 3000)
    t = np.arange(s.N) / SR
    x = (np.sin(2 * np.pi * 62.5 * t) + .6 * np.sin(2 * np.pi * 93.75 * t) + .3 * np.sin(2 * np.pi * 125 * t)) * \
        (.7 + .3 * np.sin(2 * np.pi * .2 * t))
    s.add(x / np.abs(x).max(), 0, gain=.45, send=.1)
    for pan, k in ((-.6, 3), (.6, 5)):
        s.bed(lambda n: lp(white(n), 500, 2) * (.6 + .4 * s.per(k, n, J(0, 6))), gain=1.0, pan=pan, rms=.1, send=.2)
    for k in range(16):                                               # pulsacao baixa
        s.add(thump(60, 40, .5, .06, .18, click=0), 2.5 * k, gain=.5, send=.15)
    for _ in range(8):                                                # seda rangendo
        s.add(creak(J(.35, .7)), J(0, 39), pan=pan_r(), gain=.25, send=.3)
    for _ in range(7):                                                # irmas chiando ao longe
        s.add(lp(hiss(J(.8, 1.4), 3000, 7000, .5), 4000, 2), J(0, 39), pan=pan_r(), gain=.12, send=1.0, bus='far')
    return s.render()


@sfx('amb_galerias', 1, 'b', loop=True, stereo=True, d=40.0)
def amb_galerias(v):
    s = amb(3.8, 4500)
    for _ in range(38):                                               # gotas na agua
        s.add(drip(J(500, 2200)), J(0, 39.5), pan=pan_r(), gain=J(.2, .8), send=.8)
    for _ in range(10):                                               # gotas na pedra
        s.add(mix([(tick(.012, 1500, 6000, .004), 0, 1), (modal([J(900, 2600)], [.5], [.02], .06), 0, .6)]),
              J(0, 39.5), pan=pan_r(), gain=J(.15, .5), send=.8)
    wind(s, 180, 900, 3, -.7)
    wind(s, 180, 900, 5, .7)
    s.bed(lambda n: lp(white(n), 150, 2), gain=1.0, rms=.04)
    return s.render()


@sfx('amb_abismo', 1, 'b', loop=True, stereo=True, d=40.0)
def amb_abismo(v):
    s = amb(5.0, 3000)
    wind(s, 60, 260, 2, -.6, rms=.1, send=.3)
    wind(s, 60, 260, 3, .6, rms=.1, send=.3)
    s.bed(lambda n: bp(white(n), 110, 135, 3) * (.4 + .6 * s.per(3, n)), gain=1.0, pan=-.3, rms=.05, send=.5)
    s.bed(lambda n: bp(white(n), 170, 200, 3) * (.4 + .6 * s.per(2, n, 1.3)), gain=1.0, pan=.3, rms=.04, send=.5)
    for _ in range(5):                                                # pedrinhas caindo, raramente
        casc = mix([(mix([(modal([J(500, 1500)], [1], [.02], .08), 0, 1), (tick(.01, 1000, 5000, .004), 0, .4)]),
                     .07 * i + J(0, .03), J(.4, 1.0)) for i in range(6)], dur=.55)
        s.add(casc, J(0, 38), pan=pan_r(), gain=.25, send=.9)
    return s.render()


@sfx('amb_rio', 1, 'b', loop=True, stereo=True, d=40.0)
def amb_rio(v):
    s = amb(2.5, 4000)
    for _ in range(70):                                               # lava borbulhando ao longe
        s.add(lp(blup(J(70, 260), J(.1, .2), .6), 600, 2), J(0, 39.5), pan=pan_r(), gain=J(.15, .5), send=.3)
    s.bed(lambda n: bp(white(n), 3000, 8000) * (.5 + .5 * s.per(4, n, J(0, 6))), gain=1.0, pan=-.4, rms=.08, send=.2)
    s.bed(lambda n: bp(white(n), 2500, 7000) * (.5 + .5 * s.per(6, n, J(0, 6))), gain=1.0, pan=.4, rms=.06, send=.2)
    s.bed(lambda n: lp(white(n), 120, 2) * (.6 + .4 * s.per(2, n)), gain=1.0, rms=.06)
    for _ in range(25):                                               # rocha esquentando
        s.add(mix([(tick(.012, 1500, 5000, .004), 0, 1), (modal([J(800, 2500)], [.4], [.015], .05), 0, .5)]),
              J(0, 39.5), pan=pan_r(), gain=J(.1, .3), send=.4)
    return s.render()


@sfx('amb_cacada', 1, 'b', loop=True, stereo=True, d=40.0)
def amb_cacada(v):
    s = amb(3.4, 4500)
    s.add_bus('far', 2.0, 2500)
    for _ in range(20):
        s.add(drip(J(500, 2200)), J(0, 39.5), pan=pan_r(), gain=J(.2, .7), send=.8)
    wind(s, 180, 900, 3, -.7, rms=.06)
    wind(s, 180, 900, 4, .7, rms=.06)
    s.bed(lambda n: crackle_sig(n, 35, 700, 3500), gain=.22, pan=.5, send=.5, peak=1.0, bus='far')
    s.bed(lambda n: lp(white(n), 500, 2) * (.5 + .5 * s.per(5, n)), gain=1.0, pan=.5, rms=.025, send=.4, bus='far')
    for _ in range(10):                                               # metal tilintando
        s.add(lp(modal([J(2200, 3600), J(4600, 6000)], [1, .5], [.05, .03], .2), 5000, 2), J(0, 39.5),
              pan=pan_r(), gain=.1, send=.6, bus='far')
    for g in range(5):                                                # passos distantes
        t0 = J(0, 36)
        pn = J(-.8, .8)
        for k in range(Ri(3, 5)):
            st = lp(mix([(thump(150, 90, .1, .02, .04, click=0), 0, 1), (lp(white(Nn(.08)), 1500, 2) * ad(Nn(.08), .002, .03), 0, .3)]),
                    500, 2)
            s.add(st, t0 + .5 * k, pan=pn, gain=.15, send=.5, bus='far')
    return s.render()


# ------------------------------------------------------------ fontes no mundo --
@sfx('loop_fogueira', 1, 'm', loop=True, d=4.0)
def loop_fogueira(v):
    lb = LoopBuf(4.0)
    lb.bed(lambda n: bp(white(n), 100, 700) * (.6 + .4 * srand(n, 10)), gain=1.0, rms=.12)
    lb.bed(lambda n: crackle_sig(n, 35, 800, 6000), gain=.4, peak=1.0)
    for _ in range(14):
        lb.add(mix([(tick(.012, 1500, 6000, .004), 0, 1), (modal([J(700, 2200)], [.5], [.015], .04), 0, .6)]),
               J(0, 4.0), J(.3, .8))
    return lb.buf


@sfx('loop_lava', 1, 'm', loop=True, d=4.0)
def loop_lava(v):
    lb = LoopBuf(4.0)
    lb.bed(lambda n: bp(white(n), 50, 300) * (.6 + .4 * srand(n, 6)), gain=1.0, rms=.12)
    lb.bed(lambda n: bp(white(n), 2500, 6000), gain=1.0, rms=.02)
    for _ in range(28):
        lb.add(blup(J(80, 300), J(.1, .25), .6), J(0, 4.0), J(.3, 1.0))
    return lb.buf


@sfx('geiser_aviso', 1, 'm', d=(900, 1100))
def geiser_aviso(v):
    parts = [(whoosh(1.0, 800, 3500, .9, 2.0), 0, .5), (nrm(lp(white(Nn(1.0)), 200, 2)) * hump(Nn(1.0), .8, 1.0), 0, .3)]
    for t in .95 * np.sort(cs.RNG.random(16)) ** .6:
        parts.append((blup(J(120, 400), J(.06, .12), .6), float(t), .4 + .6 * float(t)))
    return mix(parts, dur=1.0)


@sfx('geiser_erupcao', 1, 'a', d=(900, 1100))
def geiser_erupcao(v):
    n = Nn(1.0)
    jet = nrm(bp(white(n), 1500, 8000)) * ad(n, .01, .5)
    return mix([(jet, 0, 1.0), (thump(90, 50, .4, .06, .15, click=0), 0, .8),
                (nrm(bp(white(n), 400, 2500)) * ad(n, .01, .45), 0, .4)], dur=1.0)


@sfx('gota_agua', 3, 'b', d=(250, 350))
def gota_agua(v):
    f = J(650, 1500)
    return mix([(cs.drop(f, .3), 0, 1.0), (modal([J(2500, 3500)], [.3], [.05], .2), 0, .3), (blup(J(250, 420), .06), .005, .3)],
               dur=.3)


@sfx('pedra_cai', 2, 'b', d=(500, 700))
def pedra_cai(v):
    parts = []
    t = 0.0
    for i in range(Ri(5, 9)):
        f = J(900, 3200)
        parts.append((mix([(modal([f, f * 2.2], [1, .4], [.02, .012], .08), 0, 1), (tick(.01, 1500, 6000, .004), 0, .5)]),
                      t, J(.3, .9) * (1 - .07 * i)))
        t += J(.04, .12) * (1 + i * .15)
    return mix(parts, dur=.6)


# ------------------------------------------------------------------ interface --
@sfx('ui_mover', 1, 'b', d=(40, 90))
def ui_mover(v):
    return mix([(tick(.03, 1500, 4000, .006), 0, 1.0),
                (np.sin(2 * np.pi * 1800 * tt(Nn(.03))) * ad(Nn(.03), .0005, .012), 0, .5)], dur=.06)


@sfx('ui_confirmar', 1, 'm', d=(180, 230))
def ui_confirmar(v):
    return mix([(bell(hz('D6'), .18, ratios=(1, 2.4, 4.0), amps=(1, .3, .1), fall=.8), 0, .9),
                (bell(hz('A6'), .18, ratios=(1, 2.4, 4.0), amps=(1, .3, .1), fall=.8), .07, .8)], dur=.2)


@sfx('ui_voltar', 1, 'b', d=(160, 210))
def ui_voltar(v):
    return mix([(bell(hz('D6'), .17, ratios=(1, 2.4, 4.0), amps=(1, .3, .1), fall=.8), 0, .8),
                (bell(hz('A5'), .17, ratios=(1, 2.4, 4.0), amps=(1, .3, .1), fall=.8), .07, .8)], dur=.18)


@sfx('ui_abrir', 1, 'm', d=(450, 550))
def ui_abrir(v):
    parts = [(whoosh(.35, 1500, 5500, .5, 1.2), 0, .5)]
    for i, nm in enumerate(('D5', 'A5', 'D6')):
        parts.append((bell(hz(nm), .35, fall=.8), .12 + .04 * i, .45))
    return mix(parts, dur=.5)


@sfx('ui_item', 1, 'm', d=(330, 400))
def ui_item(v):
    return mix([(bell(hz(nm), .25, bright=1.1, fall=.8), .06 * i, .8) for i, nm in enumerate(('D5', 'F#5', 'A5', 'D6'))],
               dur=.35)


@sfx('ui_erro', 1, 'b', d=(130, 180))
def ui_erro(v):
    return mix([(thump(J(150, 170), 85, .12, .02, .04, click=0), 0, 1.0), (modal([210], [1], [.03], .1), 0, .4)], dur=.15)
