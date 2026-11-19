"""A jogadora (corpo e movimento) + ataques da jogadora."""
from sfx_lib import *

# ===================================================== corpo e movimento ====


@sfx('pc_passo', 6, -10, d=(60, 120))
def pc_passo(v):
    d = J(.07, .1)
    n = Nn(d)
    t = tt(n)
    tap = hp(white(n), 700) * ad(n, .0003, .010)
    body = np.sin(2 * np.pi * J(180, 320) * t) * ad(n, .0003, .018)
    k1 = tick(.02, J(2500, 4000), J(5500, 8000), .005)
    k2 = tick(.02, J(2800, 4500), J(6000, 9000), .004)
    return mix([(tap, 0, .6), (body, 0, .5), (k1, 0, 1), (k2, J(.012, .028), .55)], dur=d)


@sfx('pc_esquiva', 2, 'm', d=(230, 280))
def pc_esquiva(v):
    d = .25 * J(.93, 1.07)
    n = Nn(d)
    t = tt(n)
    w = whoosh(d, J(500, 800), J(2200, 3200), .35, 1.3)
    am = lp((np.sin(2 * np.pi * J(75, 105) * t + J(0, 6)) > .1).astype(float), 400, 1)
    scr = bp(white(n), 1800, 6500) * am * hump(n, .4, 1.0)
    return mix([(w, 0, 1), (nrm(scr), .01, .55)], dur=d)


@sfx('pc_dano', 3, 'a', d=(250, 400))
def pc_dano(v):
    d = J(.28, .38)
    imp = thump(J(170, 230), J(70, 95), .16, .02, .05, click=.2)
    sq = lp(squeal(d * .9, J(3200, 4000), J(1700, 2300), fm=J(45, 70), idx=.6, hissy=.5, tau=d * .35), 7500)
    return mix([(imp, 0, 1.0), (sq, .012, .8)], dur=d)


@sfx('pc_morte', 1, 'a', d=(1100, 1300))
def pc_morte(v):
    sq = squeal(.75, 2900, 700, fm=60, idx=.7, hissy=.5, tau=.3)
    fall = thump(110, 45, .45, .06, .14, click=.1)
    dust = bp(white(Nn(.4)), 250, 2200) * ad(Nn(.4), .005, .1)
    rustle = bp(white(Nn(.3)), 1500, 5000) * hump(Nn(.3), .3, 1.0) * .3
    return mix([(sq, 0, .85), (fall, .62, 1.0), (nrm(dust), .62, .35), (rustle, .78, .3)], dur=1.2)


def _chomp():
    n = Nn(.09)
    wet = bp(white(n), 500, 2500) * ad(n, .003, .025)
    cr = nrm(crackle_sig(n, 900, 800, 5000)) * ad(n, .001, .03)
    return mix([(nrm(wet), 0, .8), (cr, 0, .8), (blup(J(300, 520), .05, .5), .01, .5)], dur=.09)


@sfx('pc_comer', 3, 'm', d=(300, 500))
def pc_comer(v):
    k = 2 + v % 2
    parts = [(_chomp(), .13 * i + J(0, .015), J(.7, 1.0)) for i in range(k + 1)]
    return mix(parts, dur=.13 * k + .13)


@sfx('pc_runa_liga', 1, 'm', d=(380, 430))
def runa_liga(v):
    fs = [hz('D5'), hz('F#5'), hz('A5'), hz('D6')]
    parts = [(bell(f, .34, fall=.55), .055 * i, .8) for i, f in enumerate(fs)]
    n = Nn(.4)
    hum = lp(osc_saw(300 * 2 ** (tt(n) / .4), n), 900) * hump(n, .7, 1.0)
    parts.append((nrm(hum), 0, .35))
    return mix(parts, dur=.4)


@sfx('pc_runa_desliga', 1, 'b', d=(330, 380))
def runa_desliga(v):
    fs = [hz('D6'), hz('A5'), hz('F#5'), hz('D5')]
    parts = [(bell(f, .3, fall=.5), .06 * i, .8 - .12 * i) for i, f in enumerate(fs)]
    n = Nn(.35)
    hum = lp(osc_saw(600 * .42 ** (tt(n) / .35), n), 900) * hump(n, .2, 1.2)
    parts.append((nrm(hum), 0, .3))
    return mix(parts, dur=.35)


@sfx('pc_pulso', 1, 'a', d=(650, 750))
def pc_pulso(v):
    boom = thump(120, 48, .7, .14, .25, click=0)
    swell = whoosh(.7, 200, 3500, .5, 1.3)
    parts = [(boom, 0, 1.0), (swell, 0, .45)]
    for i in range(9):                                   # cintilar em espiral (sobe de tom)
        parts.append((bell(J(1800, 3200) * (1 + .09 * i), .15, fall=.5), .05 + .06 * i, .3 * (1 - i / 12)))
    return mix(parts, dur=.7)


@sfx('pc_muda_casca', 1, 'm', d=(1400, 1600))
def pc_muda_casca(v):
    parts = []
    for t in .95 * np.sort(cs.RNG.random(12)) ** 1.4:
        c = tick(.03, J(800, 2500), J(3500, 7000), .008)
        pm = modal([J(600, 2000)], [1], [.015], .05)
        c = mix([(c, 0, 1), (pm, 0, .4)])
        parts.append((c, float(t), J(.5, 1.0)))
    n = Nn(.55)
    rip = bp(white(n), 1500, 6500) * (.5 + .5 * np.abs(srand(n, 70))) * hump(n, .6, 1.0)
    parts.append((nrm(rip), .85, .8))
    parts.append((whoosh(.5, 800, 5000, .5, 1.0), .8, .35))
    return mix(parts, dur=1.5)


@sfx('pc_descanso', 1, 'b', d=(900, 1100))
def pc_descanso(v):
    n = Nn(1.0)
    rus = bp(white(n), 2000, 6500) * (.3 + .7 * np.abs(srand(n, 25))) * hump(n, .45, 1.2)
    sigh = bp(white(Nn(.55)), 300, 1400) * hump(Nn(.55), .45, 1.3)
    return mix([(nrm(rus), 0, .8), (nrm(sigh), .4, .5)], dur=1.0)


@sfx('pc_queda', 1, 'm', d=(1100, 1300))
def pc_queda(v):
    w = whoosh(.85, 3200, 300, .3, 1.2)
    th = echo(thump(95, 42, .35, .05, .12), [.1, .2], [.35, .18], 900)
    return mix([(w, 0, .9), (th, .8, 1.0)], dur=1.2)


@sfx('pc_nivel', 1, 'm', d=(850, 950))
def pc_nivel(v):
    ns = ['D5', 'F#5', 'A5', 'D6', 'F#6']
    parts = [(bell(hz(nm), .55 if i < 4 else .75, bright=1.1), .085 * i, .75) for i, nm in enumerate(ns)]
    parts.append((bell(hz('D7'), .4, ratios=(1, 2.0), amps=(1, .3)), .34, .18))
    return mix(parts, dur=.9)


# ============================================================== ataques ====


@sfx('pc_garra', 4, 'm', d=(150, 220))
def pc_garra(v):
    d = J(.15, .2)
    w = whoosh(d, J(2500, 3500), J(6500, 8500), .45, 1.2)
    tk = bell(J(3000, 4800), .12, ratios=(1, 2.4, 4.0), amps=(1, .5, .2), fall=.7)
    return mix([(w, 0, 1.0), (tk, d * .5, .45)], dur=d + .02)


@sfx('pc_garra_pesada', 2, 'a', d=(280, 330))
def pc_garra_pesada(v):
    w = whoosh(.3, J(800, 1000), J(3500, 4200), .5, 1.3)
    w2 = whoosh(.3, 300, 1500, .5, 1.3)
    low = thump(150, 80, .15, .03, .06, click=0)
    tk = bell(J(1800, 2600), .2, ratios=(1, 2.4, 4.0), amps=(1, .5, .2), fall=.8)
    return mix([(w, 0, .9), (w2, 0, .7), (low, .1, .45), (tk, .15, .55)], dur=.3)


@sfx('pc_mordida', 3, 'm', d=(200, 300))
def pc_mordida(v):
    lunge = whoosh(.1, 1500, 5000, .7, 1.0)
    k1 = tick(.02, 2000, 6000, .004)
    k2 = tick(.02, 2500, 7000, .004)
    cr = nrm(crackle_sig(Nn(.12), 1200, 500, 3500)) * ad(Nn(.12), .002, .04)
    body = thump(220, 110, .12, .02, .04, click=0)
    return mix([(lunge, 0, .5), (k1, .06, 1.0), (k2, .09, .8), (cr, .09, .8), (body, .09, .5)], dur=J(.22, .28))


@sfx('kit_corte', 2, 'a', d=(430, 470))
def kit_corte(v):
    w = whoosh(.4, J(700, 1000), J(6000, 7500), .65, 1.4)
    tk = bell(J(3500, 5000), .2, ratios=(1, 2.3, 4.1), fall=.8)
    return mix([(w, 0, 1.0), (tk, .34, .6)], dur=.45)


@sfx('kit_carga_loop', 1, 'b', loop=True, d=1.0)
def kit_carga_loop(v):
    lb = LoopBuf(1.0)
    t = lb.t()
    x = np.sin(2 * np.pi * 110 * t + .8 * np.sin(2 * np.pi * 7 * t)) * (1 + .5 * np.sin(2 * np.pi * 30 * t))
    x += .5 * np.sin(2 * np.pi * 220 * t + 1.2 * np.sin(2 * np.pi * 13 * t))
    x += .25 * np.sin(2 * np.pi * 330 * t + 2 * np.sin(2 * np.pi * 9 * t))
    lb.buf += nrm(x) * .5
    lb.bed(lambda n: bp(white(n), 1800, 5500) * (.5 + .5 * np.sin(2 * np.pi * 40 * np.arange(n) / SR)),
           gain=1.0, rms=.06)
    return lb.buf


@sfx('kit_martelo', 2, 'a', d=(480, 520))
def kit_martelo(v):
    th = thump(J(120, 150), 44, .5, .05, .13, click=.1)
    cr = nrm(crackle_sig(Nn(.35), 700, 600, 4500)) * ad(Nn(.35), .002, .12)
    st = stone_hit(.3)
    rumble = lp(white(Nn(.3)), 250, 2) * ad(Nn(.3), .005, .15)
    return mix([(th, 0, 1.0), (cr, .01, .7), (st, .01, .5), (nrm(rumble), 0, .4)], dur=.5)


@sfx('kit_onda', 1, 'a', d=(750, 850))
def kit_onda(v):
    boom = thump(85, 45, .8, .12, .3, click=0)
    dust = whoosh(.8, 2500, 500, .3, 1.2)
    sh = lp(white(Nn(.8)), 600, 2) * hump(Nn(.8), .2, 1.2)
    return mix([(boom, 0, 1.0), (dust, 0, .4), (nrm(sh), 0, .5)], dur=.8)


@sfx('kit_chicote', 2, 'm', d=(230, 280))
def kit_chicote(v):
    crack = tick(.012, 3500, 9000, .002)
    burst = hp(white(Nn(.03)), 4000) * ad(Nn(.03), .0003, .008)
    wh = chirp(J(3800, 4600), J(2200, 2800), .14, .05) * .6
    air = hiss(.18, 3000, 8000, .2, 1.0)
    return mix([(crack, 0, 1.0), (nrm(burst), 0, .6), (wh, .01, .5), (air, .01, .4)], dur=.25)


@sfx('kit_dardo', 3, 'b', d=(100, 140))
def kit_dardo(v):
    ch = chirp(J(4200, 5200), J(2600, 3200), .06, .02)
    ns = bp(white(Nn(.1)), 4000, 8000) * ad(Nn(.1), .001, .02)
    return mix([(ch, 0, .8), (nrm(ns), 0, .5)], dur=.12)


@sfx('kit_bote', 1, 'm', d=(430, 470))
def kit_bote(v):
    up = whoosh(.22, 400, 2600, .8, 1.0)
    dn = whoosh(.25, 2600, 500, .15, 1.3)
    return mix([(tick(.015, 800, 3000, .004), 0, .4), (up, 0, .8), (dn, .2, .9)], dur=.45)


@sfx('kit_raio', 2, 'a', d=(280, 330))
def kit_raio(v):
    n = Nn(.3)
    t = tt(n)
    fr = 1400 * (300 / 1400) ** np.clip(t / .12, 0, 1)
    ph = 2 * np.pi * np.cumsum(fr) / SR
    idx = 6 * np.exp(-t / .08)
    zap = np.sin(ph + idx * np.sin(3.1 * ph)) * ad(n, .001, .09)
    cr = nrm(crackle_sig(n, 700, 1500, 9000)) * ad(n, .002, .12)
    clk = hp(white(n), 2500) * ad(n, .0003, .006)
    return mix([(zap, 0, .9), (cr, 0, .7), (nrm(clk), 0, .6)], dur=.3)


@sfx('kit_campo_loop', 1, 'b', loop=True, d=2.0)
def kit_campo_loop(v):
    lb = LoopBuf(2.0)
    t = lb.t()
    x = np.sin(2 * np.pi * 100 * t) * (1 + .4 * np.sin(2 * np.pi * 50 * t))
    x += .5 * np.sin(2 * np.pi * 200 * t + np.sin(2 * np.pi * 3 * t))
    x += .3 * np.sin(2 * np.pi * 301 * t)
    lb.buf += nrm(x) * .5
    lb.bed(lambda n: bp(white(n), 1500, 5000) * (.5 + .5 * np.sin(2 * np.pi * 40 * np.arange(n) / SR)),
           gain=1.0, rms=.05)
    for _ in range(9):
        lb.add(mix([(tick(.012, 3000, 8000, .003), 0, 1), (chirp(J(3500, 6000), J(1500, 2500), .03, .01), 0, .4)]),
               J(0, 2.0), J(.2, .6))
    return lb.buf


@sfx('kit_fogo_loop', 1, 'm', loop=True, d=2.0)
def kit_fogo_loop(v):
    lb = LoopBuf(2.0)
    lb.bed(lambda n: bp(white(n), 100, 900) * (.6 + .4 * srand(n, 14)), gain=1.0, rms=.2)
    lb.bed(lambda n: bp(white(n), 1500, 6000) * (.5 + .5 * np.abs(srand(n, 30))), gain=1.0, rms=.05)
    lb.bed(lambda n: crackle_sig(n, 60, 1000, 7000), gain=.35, peak=1.0)
    return lb.buf


@sfx('kit_bola_fogo', 1, 'm', d=(450, 550))
def kit_bola_fogo(v):
    w = whoosh(.5, 500, 2600, .5, 1.2)
    cr = nrm(crackle_sig(Nn(.5), 500, 1200, 7000)) * hump(Nn(.5), .3, 1.0)
    body = lp(white(Nn(.5)), 700, 2) * hump(Nn(.5), .3, 1.0)
    return mix([(w, 0, 1.0), (cr, 0, .6), (nrm(body), 0, .5)], dur=.5)


@sfx('kit_explosao', 1, 'a', d=(1100, 1300))
def kit_explosao(v):
    boom = thump(110, 40, .9, .07, .25, click=.1)
    swell = bp(white(Nn(1.2)), 100, 1500) * ad(Nn(1.2), .01, .45)
    steam = hp(white(Nn(1.2)), 3000) * ad(Nn(1.2), .02, .5)
    cr = nrm(crackle_sig(Nn(1.2), 300, 1200, 8000)) * ad(Nn(1.2), .01, .5)
    return mix([(boom, 0, 1.0), (nrm(swell), 0, .7), (nrm(steam), 0, .3), (cr, 0, .5)], dur=1.2)


@sfx('kit_cuspe', 2, 'm', d=(280, 330))
def kit_cuspe(v):
    pop = chirp(520, 260, .05, .015)
    tk = bp(white(Nn(.05)), 800, 3000) * ad(Nn(.05), .001, .015)
    sp = bp(white(Nn(.15)), 2500, 6500) * ad(Nn(.15), .002, .05)
    parts = [(pop, 0, .9), (nrm(tk), 0, .6), (nrm(sp), .1, .6)]
    for i, tm in enumerate((.12, .17, .23)):
        parts.append((blup(J(800, 2200), .05), tm, .35))
    return mix(parts, dur=.3)


@sfx('kit_acido_loop', 1, 'b', loop=True, d=1.5)
def kit_acido_loop(v):
    lb = LoopBuf(1.5)
    lb.bed(lambda n: bp(white(n), 3000, 8000), gain=1.0, rms=.05)
    for _ in range(45):
        lb.add(blup(J(500, 2400), .04), J(0, 1.5), J(.1, .5))
    return lb.buf


@sfx('kit_sombra', 1, 'm', d=(450, 550))
def kit_sombra(v):
    suc = whoosh(.5, 2600, 350, .85, 2.5)
    br = bp(white(Nn(.5)), 900, 4000) * hump(Nn(.5), .5, 1.0)
    hum = chirp(140, 70, .5, .3) * hump(Nn(.5), .6, 1.0)
    return mix([(suc, 0, 1.0), (nrm(br), 0, .3), (hum, 0, .25)], dur=.5)


@sfx('kit_guarda', 1, 'a', d=(230, 280))
def kit_guarda(v):
    th = thump(J(190, 230), 90, .2, .02, .05, click=.15)
    st = modal([J(480, 560), J(820, 900), J(1250, 1400)], [1, .6, .4], [.05, .035, .02], .2)
    tk = hp(white(Nn(.04)), 1500) * ad(Nn(.04), .0003, .008)
    return mix([(th, 0, 1.0), (st, 0, .5), (nrm(tk), 0, .3)], dur=.25)


@sfx('kit_aparar', 1, 'a', d=(380, 430))
def kit_aparar(v):
    tg = bell(J(2300, 2600), .35, ratios=(1, 2.42, 4.1), amps=(1, .4, .2), fall=.9)
    cw = whoosh(.2, 1000, 5500, .4, 1.0)
    return mix([(tg, 0, 1.0), (cw, .1, .55)], dur=.4)


@sfx('kit_espelho', 1, 'm', d=(650, 750))
def kit_espelho(v):
    n = Nn(.7)
    t = tt(n)
    x = np.zeros(n)
    for _ in range(7):
        f = J(2500, 6500)
        x += np.sin(2 * np.pi * f * t + J(0, 6)) * np.exp(-t / J(.15, .3)) * (.6 + .4 * np.sin(2 * np.pi * J(8, 14) * t))
    parts = [(nrm(x) * hump(n, .12, 1.0), 0, .8)]
    for i in range(4):
        parts.append((bell(J(2000, 4500), .3, fall=.6), .05 * i, .35))
    return mix(parts, dur=.7)


@sfx('kit_cristal', 1, 'a', d=(850, 950))
def kit_cristal(v):
    parts = [(thump(150, 70, .25, .03, .08, click=.1), 0, .5),
             (bell(J(1400, 1600), .9, ratios=(1, 1.5, 2.01), amps=(1, .6, .3), fall=1.2), 0, .5)]
    for t in np.sort(cs.RNG.exponential(.15, 28)):
        if t < .8:
            parts.append((bell(J(2200, 6500), J(.08, .2), ratios=(1, 2.3, 3.7), fall=.6), float(t), J(.2, .6)))
    return mix(parts, dur=.9)
