"""Chefes e cacadores humanos."""
from sfx_lib import *

# ================================================================== chefes ====


@sfx('mae_rugido', 1, 'a', d=(2300, 2700))
def mae_rugido(v):
    g = growl(2.3, 85, 55, rough=28, dist=2.5, dark=700)
    g = g * hump(len(g), .15, 1.2)
    hs = whoosh(2.2, 1500, 7000, .3, 1.0)
    sq = lp(squeal(1.6, 900, 600, fm=11, idx=2.0, hissy=.3, tau=.8), 3000)
    rb = lp(white(Nn(2.4)), 140, 2) * hump(Nn(2.4), .2, 1.0)
    return mix([(g, 0, 1.0), (hs, 0, .5), (sq, .2, .3), (nrm(rb), 0, .5)], dur=2.5)


@sfx('mae_pisada', 3, 'a', d=(550, 650))
def mae_pisada(v):
    th = thump(J(70, 90), 36, .6, .1, .22, click=.05)
    n = Nn(.5)
    tr = lp(white(n), 130, 2) * (.5 + .5 * np.sin(2 * np.pi * 17 * tt(n))) * ad(n, .01, .25)
    parts = [(th, 0, 1.0), (nrm(tr), 0, .6)]
    for _ in range(5):
        parts.append((stone_hit(.12, J(300, 1200)), J(.1, .5), J(.2, .5)))
    return mix(parts, dur=.6)


@sfx('centopeia_patas_loop', 1, 'm', loop=True, d=2.0)
def centopeia_patas_loop(v):
    lb = LoopBuf(2.0)
    legs = [tick(.02, J(2500, 4500), J(5500, 9000), .004) for _ in range(12)]
    for _ in range(230):
        lb.add(legs[Ri(0, 12)], J(0, 2.0), J(.25, 1.0))
    lb.bed(lambda n: bp(white(n), 3000, 7000) * (.5 + .5 * np.abs(srand(n, 40))), gain=1.0, rms=.02)
    return lb.buf


@sfx('centopeia_golpe', 1, 'a', d=(550, 650))
def centopeia_golpe(v):
    parts = []
    for i in range(3):
        parts.append((modal([J(500, 700), J(1100, 1600), J(2300, 3200), J(3900, 5200)], [1, .7, .5, .3],
                            [.12, .08, .05, .03], .4), .05 * i, .8 - .15 * i))
    parts += [(thump(120, 60, .2, .03, .08), .12, .9),
              (nrm(crackle_sig(Nn(.25), 1000, 400, 3500)) * ad(Nn(.25), .002, .1), .12, .8)]
    return mix(parts, dur=.6)


@sfx('colosso_pisada', 3, 'a', d=(1100, 1300))
def colosso_pisada(v):
    th = thump(J(60, 75), 36, 1.0, .12, .3, click=0)
    dust = bp(white(Nn(.9)), 200, 1500) * hump(Nn(.9), .3, 1.0)
    parts = [(th, 0, 1.0), (nrm(dust), .05, .35)]
    for k in range(9):
        t = .2 + .8 * (k / 9) ** 1.2 + J(0, .05)
        parts.append((mix([(stone_hit(.2, J(300, 1200)), 0, .6), (thump(J(120, 220), 70, .1, .02, .04, click=0), 0, .5)]),
                      t, J(.15, .5) * (1 - k / 14)))
    return mix(parts, dur=1.2)


@sfx('colosso_respira_loop', 1, 'm', loop=True, d=4.0)
def colosso_respira_loop(v):
    lb = LoopBuf(4.0)
    N = lb.N

    def breath(n):
        u = (np.arange(n) % N) / N
        env = (np.sin(np.pi * u ** .8)) ** 1.5
        w = 1 / (1 + np.exp((u - .45) * 14))                # inspira (mais agudo) -> expira (mais grave)
        return env * (w * bp(white(n), 90, 500) + (1 - w) * 1.2 * bp(white(n), 60, 260))
    lb.bed(breath, gain=1.0, rms=.2, xf=.3)
    return lb.buf


@sfx('serpente_sibilo', 1, 'a', d=(1400, 1600))
def serpente_sibilo(v):
    n = Nn(1.5)
    t = tt(n)
    w = whoosh(1.5, 3500, 7500, .5, 1.0)
    h = w * (.55 + .45 * np.sin(2 * np.pi * 5.5 * t))
    br = bp(white(n), 1200, 3500) * hump(n, .4, 1.0)
    return mix([(h, 0, 1.0), (nrm(br), 0, .3)], dur=1.5)


@sfx('serpente_bote', 1, 'a', d=(650, 750))
def serpente_bote(v):
    return mix([(whoosh(.28, 500, 4500, .35, 1.0), 0, .8),
                (tick(.02, 2000, 6000, .004), .25, 1.0),
                (nrm(crackle_sig(Nn(.12), 1200, 500, 3500)) * ad(Nn(.12), .002, .04), .26, .7),
                (thump(120, 55, .3, .04, .1), .26, .9),
                (nrm(crackle_sig(Nn(.4), 600, 500, 4500)) * ad(Nn(.4), .002, .15), .3, .6),
                (stone_hit(.3), .3, .4)], dur=.7)


@sfx('rainha_rugido', 1, 'a', d=(1900, 2100))
def rainha_rugido(v):
    g = growl(1.8, 120, 70, rough=35, dist=3, dark=1500)
    g = g * hump(len(g), .2, 1.1)
    cr = nrm(crackle_sig(Nn(2.0), 180, 1200, 8000)) * hump(Nn(2.0), .3, 1.0)
    fb = nrm(bp(white(Nn(2.0)), 150, 1500)) * hump(Nn(2.0), .3, 1.0)
    return mix([(g, 0, 1.0), (cr, 0, .6), (fb, 0, .4), (hiss(1.8, 3000, 8000, .3), 0, .15)], dur=2.0)


@sfx('rainha_onda', 1, 'a', d=(2300, 2700))
def rainha_onda(v):
    return mix([(whoosh(2.5, 250, 2200, .5, 1.2), 0, 1.0),
                (nrm(bp(white(Nn(2.5)), 100, 1200)) * hump(Nn(2.5), .5, 1.0), 0, .8),
                (nrm(crackle_sig(Nn(2.5), 260, 1000, 8000)) * hump(Nn(2.5), .5, 1.0), 0, .8),
                (nrm(lp(white(Nn(2.5)), 90, 2)) * hump(Nn(2.5), .5, 1.0), 0, .4)], dur=2.5)


@sfx('capita_comando', 1, 'a', d=(850, 950))
def capita_comando(v):
    ha = vocal(.2, 190, 170, 'ah', breath=.5, lowcut=3000, peak=.2)
    ra = vocal(.5, 175, 130, 'eh', breath=.3, lowcut=3000, peak=.3)
    gr = np.tanh(2.0 * mix([(ha, 0, 1.0), (ra, .24, 1.0), (nrm(hp(white(Nn(.04)), 2500)) * ad(Nn(.04), .001, .01), .2, .5)]))
    return echo(nrm(gr), [.14, .28, .42], [.4, .25, .15], 2500)[:Nn(.9)]


@sfx('capita_frasco', 1, 'a', d=(850, 950))
def capita_frasco(v):
    parts = [(tick(.015, 3000, 9000, .003), 0, .8)]
    for t in np.sort(cs.RNG.exponential(.12, 24)):
        if t < .5:
            parts.append((bell(J(1800, 6000), J(.08, .2), ratios=(1, 2.3, 3.7), fall=.6), float(t), J(.2, .6)))
    parts += [(whoosh(.7, 300, 2500, .35, 1.0), .1, .8),
              (nrm(crackle_sig(Nn(.8), 400, 1000, 7000)) * hump(Nn(.8), .3, 1.0), .1, .7)]
    return mix(parts, dur=.9)


@sfx('capita_giro', 1, 'a', d=(650, 750))
def capita_giro(v):
    def circ(t0, g):
        return [(whoosh(.16, 500, 3500, .9, 1.0), t0, g), (whoosh(.18, 3500, 500, .1, 1.2), t0 + .14, g)]
    body = nrm(bp(white(Nn(.6)), 200, 800)) * hump(Nn(.6), .3, 1.0)
    return mix(circ(0, 1.0) + circ(.3, .9) + [(body, 0, .25)], dur=.7)


# ================================================================ cacadores ====


@sfx('espada_golpe', 3, 'm', d=(220, 280))
def espada_golpe(v):
    d = J(.2, .26)
    w = whoosh(d, J(900, 1300), J(4500, 6500), .45, 1.2)
    ring = modal([J(2800, 3600), J(5200, 6500)], [.3, .15], [.1, .06], .2)
    return mix([(w, 0, 1.0), (ring, .12, .25)], dur=d + .02)


@sfx('espada_escudo', 2, 'a', d=(270, 330))
def espada_escudo(v):
    th = thump(J(150, 190), 85, .2, .02, .06, click=.1)
    wd = modal([J(190, 260), J(310, 400), J(520, 700)], [1, .6, .4], [.06, .045, .03], .25)
    mt = modal([J(1800, 2400), J(3200, 4200)], [1, .5], [.1, .07], .3)
    return mix([(th, 0, 1.0), (wd, 0, .7), (mt, 0, .35), (tick(.01, 2000, 7000, .003), 0, .5)], dur=.3)


@sfx('flecha_disparo', 2, 'm', d=(270, 330))
def flecha_disparo(v):
    tw = twang(J(170, 230), .25, tau=.12, bend=.04, harm=5)
    return mix([(tw, 0, 1.0), (whoosh(.12, 2500, 6500, .3, 1.0), .02, .6), (tick(.01, 2500, 7000, .003), 0, .5)], dur=.3)


@sfx('flecha_fogo_voo', 1, 'm', d=(550, 650))
def flecha_fogo_voo(v):
    return mix([(whoosh(.55, 3500, 800, .45, 1.2), 0, 1.0),
                (nrm(crackle_sig(Nn(.6), 260, 1200, 7000)) * hump(Nn(.6), .4, 1.0), 0, .6),
                (nrm(bp(white(Nn(.6)), 300, 1500)) * hump(Nn(.6), .4, 1.0), 0, .3)], dur=.6)


@sfx('tocha_whoosh', 1, 'm', d=(370, 430))
def tocha_whoosh(v):
    return mix([(nrm(bp(white(Nn(.4)), 200, 2500)) * hump(Nn(.4), .3, 1.0), 0, 1.0),
                (whoosh(.38, 300, 2200, .35, 1.0), 0, .6),
                (nrm(crackle_sig(Nn(.4), 300, 1200, 7000)) * hump(Nn(.4), .3, 1.0), 0, .4)], dur=.4)


@sfx('bota_passo', 4, -10, d=(120, 180))
def bota_passo(v):
    th = thump(J(150, 190), 90, .1, .02, .04, click=0)
    lt = bp(white(Nn(.03)), 1200, 3500) * ad(Nn(.03), .002, .012)
    gr = nrm(crackle_sig(Nn(.06), 700, 2500, 8000)) * ad(Nn(.06), .001, .02)
    return mix([(th, 0, 1.0), (nrm(lt), 0, .4), (gr, .01, .3),
                (nrm(lp(white(Nn(.1)), 1500, 2)) * ad(Nn(.1), .002, .03), 0, .4)], dur=J(.13, .16))


@sfx('armadilha_estalo', 1, 'a', d=(130, 180))
def armadilha_estalo(v):
    md = modal([J(1400, 1800), J(2600, 3400), J(4200, 5200)], [1, .7, .4], [.03, .02, .015], .12)
    return mix([(tick(.01, 3500, 9000, .002), 0, 1.0), (tick(.01, 3000, 8000, .002), .025, .8), (md, 0, .7)], dur=.15)


@sfx('armadilha_fogo', 1, 'a', d=(850, 950))
def armadilha_fogo(v):
    return mix([(whoosh(.3, 300, 3000, .2, 1.0), 0, .9),
                (nrm(bp(white(Nn(.9)), 100, 1500)) * hump(Nn(.9), .15, 1.0) * ad(Nn(.9), .01, .5), 0, .9),
                (nrm(crackle_sig(Nn(.9), 300, 1200, 7000)) * ad(Nn(.9), .01, .4), 0, .6)], dur=.9)
