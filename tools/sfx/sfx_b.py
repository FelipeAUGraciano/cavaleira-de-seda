"""Teia e seda, impactos e mortes, bichos da caverna (9 familias x alerta/ataque/dor)."""
from sfx_lib import *

# ================================================================== teia ====


@sfx('teia_lancar', 2, 'm', d=(180, 230))
def teia_lancar(v):
    ch = chirp(J(2000, 2600), J(500, 700), .12, .04)
    ns = bp(white(Nn(.2)), 2500, 7000) * hump(Nn(.2), .2, 1.0)
    return mix([(ch, 0, .8), (nrm(ns), 0, .5)], dur=.2)


@sfx('teia_prender', 2, 'm', d=(230, 280))
def teia_prender(v):
    sn = tick(.015, 2000, 7000, .003)
    wd = modal([J(300, 420), J(700, 900)], [1, .5], [.03, .02], .1)
    n = Nn(.22)
    vib = np.sin(2 * np.pi * J(480, 620) * tt(n)) * ad(n, .002, .1) * (1 + .1 * np.sin(2 * np.pi * 30 * tt(n)))
    return mix([(sn, 0, 1.0), (wd, 0, .6), (vib, .02, .5)], dur=.25)


@sfx('teia_tecer', 1, 'm', d=(450, 550))
def teia_tecer(v):
    tw = twang(J(95, 115), .5, tau=.3, bend=.15, harm=6)
    fr = bp(white(Nn(.4)), 300, 1500) * hump(Nn(.4), .4, 1.0)
    return mix([(tw, 0, 1.0), (nrm(fr), 0, .2)], dur=.5)


@sfx('teia_rompe', 2, 'm', d=(280, 330))
def teia_rompe(v):
    sn = tick(.012, 3000, 9000, .002)
    wp = whoosh(.18, 5500, 1500, .2, 1.0)
    fall = chirp(J(700, 900), J(250, 350), .12, .05)
    fib = nrm(crackle_sig(Nn(.1), 600, 2000, 8000)) * ad(Nn(.1), .001, .04)
    return mix([(sn, 0, 1.0), (wp, 0, .6), (fall, .01, .4), (fib, .02, .4)], dur=.3)


@sfx('teia_queima', 2, 'm', d=(450, 550))
def teia_queima(v):
    hs = hp(white(Nn(.5)), 3000) * hump(Nn(.5), .15, 1.0) * ad(Nn(.5), .001, .35)
    cr = nrm(crackle_sig(Nn(.5), 220, 1200, 7000)) * ad(Nn(.5), .002, .25)
    sz = bp(white(Nn(.5)), 400, 1500) * hump(Nn(.5), .2, 1.0)
    return mix([(nrm(hs), 0, .6), (cr, 0, 1.0), (nrm(sz), 0, .3)], dur=.5)


@sfx('teia_captura', 1, 'b', d=(550, 650))
def teia_captura(v):
    n = Nn(.6)
    rus = bp(white(n), 2200, 7000) * (.3 + .7 * np.abs(srand(n, 30))) * hump(n, .5, 1.2)
    parts = [(nrm(rus), 0, 1.0)]
    for _ in range(5):
        parts.append((blup(J(250, 700), .03), J(.1, .5), .3))
    return mix(parts, dur=.6)


@sfx('teia_prende_bicho', 2, 'm', d=(370, 430))
def teia_prende_bicho(v):
    n = Nn(.4)
    t = tt(n)
    th = thump(J(210, 260), 90, .14, .02, .05, click=0)
    st = bp(white(n), 300, 1800) * (.5 + .5 * np.sin(2 * np.pi * J(9, 13) * t)) * hump(n, .4, 1.0)
    parts = [(th, 0, .8), (nrm(st), .03, .4)]
    for _ in range(5):
        parts.append((blup(J(300, 900), .025, .5), J(0, .22), .45))
    return mix(parts, dur=.4)


@sfx('teia_embrulhar', 2, 'b', d=(650, 750))
def teia_embrulhar(v):
    n = Nn(.7)
    u = tt(n) / .7
    am = .5 + .5 * np.sin(2 * np.pi * np.cumsum(6 + 8 * u) / SR)
    spin = bp(white(n), 2000, 6500) * am * hump(n, .6, 1.0)
    creak = chirp(180, 260, .5, .25) * hump(Nn(.5), .5, 1.0)
    return mix([(nrm(spin), 0, 1.0), (creak, .15, .25)], dur=.7)


@sfx('teia_vibra', 1, 'b', d=(280, 330))
def teia_vibra(v):
    x = twang(J(110, 135), .3, tau=.15, bend=.02, harm=4)
    return x * np.minimum(1, tt(len(x)) / .008)


# ======================================================== impactos e mortes ====


@sfx('hit_carne', 4, 'a', d=(120, 200))
def hit_carne(v):
    d = J(.12, .19)
    slap = lp(white(Nn(d)), 1800, 2) * ad(Nn(d), .0005, .02)
    body = chirp(J(150, 200), J(70, 90), .1, .035)
    sq = bp(white(Nn(.08)), 400, 1600) * ad(Nn(.08), .004, .04)
    return mix([(nrm(slap), 0, .9), (body, 0, .9), (nrm(sq), .01, .45), (blup(J(250, 450), .05), .03, .4)], dur=d)


@sfx('hit_casca', 3, 'a', d=(130, 180))
def hit_casca(v):
    tk = tick(.02, 2500, 8000, .004)
    md = modal([J(900, 1400), J(2100, 3200), J(3800, 5000)], [1, .6, .3], [.05, .035, .02], .15)
    th = thump(J(200, 280), 110, .08, .01, .03, click=0)
    return mix([(tk, 0, 1.0), (md, 0, .7), (th, 0, .4)], dur=.15)


@sfx('hit_critico', 2, 'a', d=(280, 330))
def hit_critico(v):
    th = thump(J(120, 150), 52, .25, .04, .1, click=.1)
    bl = bell(J(3000, 4200), .25, ratios=(1, 2.3, 3.8), fall=.8)
    return mix([(th, 0, 1.0), (bl, .01, .5), (whoosh(.15, 2000, 7000, .3), 0, .3)], dur=.3)


@sfx('hit_bloqueado', 2, 'm', d=(130, 180))
def hit_bloqueado(v):
    th = thump(J(150, 190), 85, .1, .015, .035, click=0)
    md = modal([J(220, 300), J(400, 520)], [1, .5], [.03, .02], .12)
    nz = lp(white(Nn(.03)), 2000, 1) * ad(Nn(.03), .0003, .008)
    return mix([(th, 0, 1.0), (md, 0, .5), (nrm(nz), 0, .3)], dur=.15)


@sfx('morte_pequena', 2, 'm', d=(350, 450))
def morte_pequena(v):
    sq = squeal(.22, J(3600, 4500), J(900, 1300), fm=70, idx=.8, hissy=.4, tau=.1)
    t = tt(len(sq))
    sq = sq * np.where(t < .2, 1.0, np.exp(-(t - .2) / .01))
    wet = bp(white(Nn(.15)), 400, 2000) * hump(Nn(.15), .3, 1.0)
    return mix([(sq, 0, 1.0), (blup(J(150, 260), .1), .2, .6), (nrm(wet), .2, .4)], dur=.4)


@sfx('morte_grande', 2, 'a', d=(1100, 1300))
def morte_grande(v):
    g = growl(.9, J(150, 180), J(45, 60), rough=J(30, 45), dist=2, dark=800)
    g = g * hump(len(g), .12, 1.0)
    fall = thump(95, 40, .5, .07, .18)
    dust = bp(white(Nn(.6)), 300, 2500) * ad(Nn(.6), .01, .3)
    return mix([(g, 0, .9), (fall, .55, 1.0), (nrm(dust), .55, .5)], dur=1.2)


@sfx('corpo_cai', 2, 'b', d=(280, 330))
def corpo_cai(v):
    th = thump(J(120, 150), 55, .28, .04, .08, click=0)
    nz = lp(white(Nn(.2)), 600, 2) * ad(Nn(.2), .003, .06)
    return mix([(th, 0, 1.0), (nrm(nz), 0, .3)], dur=.3)


# ================================================================== bichos ====
def clicks_train(k, span, lo=1800, hi=6500, accel=.6):
    parts = []
    for i in range(k):
        t = span * (i / max(k - 1, 1)) ** (1 + accel)
        parts.append((tick(.015, J(lo * .8, lo * 1.2), J(hi * .8, hi * 1.2), .003), t, J(.5, 1.0)))
    return mix(parts, dur=span + .02)


def wingbuzz(d, f):
    n = Nn(d)
    t = tt(n)
    x = osc_saw(f * (1 + .03 * np.sin(2 * np.pi * 8 * t)), n)
    return nrm(bp(x, 600, 3500) * (.5 + .5 * np.sin(2 * np.pi * 95 * t)) * hump(n, .3, 1.0))


def flap(d=.1):
    n = Nn(d)
    return nrm(lp(white(n), 900, 2) * ad(n, .01, d / 3))


def scratch(d, lo=2000, hi=5500):
    n = Nn(d)
    t = tt(n)
    am = lp((np.sin(2 * np.pi * J(55, 75) * t) > .2).astype(float), 300, 1)
    return nrm(bp(white(n), lo, hi) * am * hump(n, .4, 1.0))


def inseto(role):
    if role == 'alerta':
        return mix([(clicks_train(12, .32), 0, .9), (wingbuzz(.2, 170), .28, .5)], dur=.5)
    if role == 'ataque':
        return mix([(tick(.02, 1500, 6000, .005), 0, 1.0), (tick(.02, 1800, 6500, .005), .035, .9),
                    (nrm(crackle_sig(Nn(.08), 900, 700, 4000)) * ad(Nn(.08), .001, .03), .03, .8),
                    (thump(190, 100, .1, .015, .04, click=0), .03, .5)], dur=.28)
    return mix([(squeal(.14, J(2600, 3200), J(1500, 1900), fm=90, idx=.5, hissy=.3, tau=.06), 0, .9),
                (clicks_train(4, .1, accel=.2), .02, .7)], dur=.2)


def aracnideo(role):
    if role == 'alerta':
        return mix([(hiss(.42, 3500, 9000, .3, 1.0), 0, .8), (scratch(.3), .08, .5)], dur=.5)
    if role == 'ataque':
        return mix([(tick(.02, 2500, 7000, .005), 0, 1.0), (tick(.02, 2800, 7500, .005), .04, 1.0),
                    (hiss(.14, 3500, 9000, .2, 1.0), .03, .6), (scratch(.12), .05, .4)], dur=.3)
    return mix([(squeal(.18, J(3800, 4800), J(2600, 3200), fm=120, idx=.4, hissy=.7, tau=.08), 0, .9)], dur=.22)


def reptil(role):
    if role == 'alerta':
        return mix([(hiss(.45, 2800, 8000, .35, 1.2), 0, .8), (tick(.012, 1500, 4500, .003), .2, .8),
                    (blup(J(400, 700), .04), .21, .5), (tick(.012, 1500, 4500, .003), .26, .6),
                    (growl(.25, J(110, 140), 90, rough=35, dist=1.5), .2, .5)], dur=.5)
    if role == 'ataque':
        return mix([(growl(.24, 130, 85, rough=45, dist=2.2, dark=1200), 0, 1.0),
                    (hiss(.2, 3000, 8000, .3), 0, .4), (tick(.02, 2000, 6000, .004), .15, .8)], dur=.3)
    return mix([(growl(.16, 170, 260, rough=50, dist=1.5), 0, .8), (hiss(.15, 3000, 8000, .3), 0, .4)], dur=.2)


def anfibio(role):
    if role == 'alerta':
        return mix([(croak(J(95, 130), .4), 0, 1.0), (blup(J(200, 350), .08), .38, .4)], dur=.45)
    if role == 'ataque':
        return mix([(tick(.015, 1500, 5000, .004), 0, .8), (chirp(900, 300, .04, .015), .005, .7),
                    (nrm(bp(white(Nn(.06)), 500, 3000)) * ad(Nn(.06), .003, .03), .01, .5),
                    (blup(250, .06), .06, .5)], dur=.25)
    return mix([(croak(J(190, 260), .18, pulses=35), 0, .9), (chirp(300, 500, .1, .05), 0, .3)], dur=.2)


def voador(role):
    def ch(t0):
        return (squeal(.09, J(4800, 5500), J(6500, 7500), fm=80, idx=.4, hissy=.2, tau=.05), t0, .9)
    if role == 'alerta':
        return mix([ch(0), ch(.13), ch(.26), (flap(.1), .05, .5), (flap(.1), .24, .5)], dur=.45)
    if role == 'ataque':
        return mix([(squeal(.2, 6000, 3500, fm=80, idx=.5, hissy=.2, tau=.1), 0, .9),
                    (whoosh(.25, 300, 1500, .4), 0, .5)], dur=.3)
    return mix([(chirp(7000, 4500, .1, .03), 0, .8), (squeal(.1, 5500, 4500, fm=150, idx=.5, hissy=.1, tau=.04), 0, .5)],
               dur=.18)


def pedra(role):
    if role == 'alerta':
        n = Nn(.55)
        gr = bp(white(n), 150, 900) * (.3 + .7 * np.abs(srand(n, 18))) * hump(n, .5, 1.0)
        parts = [(nrm(gr), 0, 1.0), (chirp(J(180, 260), J(120, 160), .4, .2), 0, .3)]
        for _ in range(3):
            parts.append((tick(.02, 600, 3000, .006), J(.05, .5), .5))
        return mix(parts, dur=.55)
    if role == 'ataque':
        return mix([(thump(105, 45, .3, .05, .1), 0, 1.0), (stone_hit(.3), 0, .6),
                    (tick(.02, 1000, 5000, .005), 0, .5),
                    (nrm(bp(white(Nn(.25)), 300, 2500)) * ad(Nn(.25), .01, .1), .02, .3)], dur=.35)
    return mix([(nrm(crackle_sig(Nn(.2), 700, 500, 4500)) * ad(Nn(.2), .002, .07), 0, .9),
                (modal([J(900, 1500)], [.8], [.05], .15), 0, .6), (thump(160, 80, .1, .02, .04, click=0), 0, .5)],
               dur=.22)


def lava(role):
    if role == 'alerta':
        parts = [(hiss(.5, 2500, 7000, .4, 1.0), 0, .5)]
        for _ in range(6):
            parts.append((blup(J(100, 320), J(.08, .14), .6), J(0, .42), J(.5, 1.0)))
        return mix(parts, dur=.55)
    if role == 'ataque':
        n = Nn(.3)
        return mix([(nrm(bp(white(n), 700, 3200)) * hump(n, .4, 1.2), 0, .8), (blup(J(150, 250), .08), .05, .8),
                    (thump(110, 55, .12, .02, .05, click=0), .02, .5)], dur=.3)
    return mix([(nrm(hp(white(Nn(.12)), 2500)) * ad(Nn(.12), .002, .07), 0, .7), (blup(J(180, 300), .06), .02, .8)],
               dur=.2)


def gosma(role):
    if role == 'alerta':
        parts = [(nrm(bp(white(Nn(.4)), 300, 1500)) * hump(Nn(.4), .5, 1.0), 0, .5),
                 (chirp(800, 250, .12, .05), .3, .5)]
        for i in range(4):
            parts.append((blup(J(120, 260), J(.1, .16), .5), .08 + .1 * i, .8))
        return mix(parts, dur=.5)
    if role == 'ataque':
        return mix([(blup(J(300, 500), .07, .4), 0, 1.0),
                    (nrm(bp(white(Nn(.08)), 600, 2500)) * ad(Nn(.08), .003, .05), 0, .6),
                    (chirp(900, 300, .08, .03), .06, .4)], dur=.28)
    return mix([(chirp(J(500, 700), J(200, 260), .15, .06), 0, .8),
                (nrm(bp(white(Nn(.15)), 300, 1800)) * hump(Nn(.15), .3, 1.0), 0, .6), (blup(220, .08), .1, .5)], dur=.2)


def humano(role):
    clink = lambda t: (modal([J(2500, 3800), J(4800, 6200)], [1, .5], [.04, .03], .1), t, .22)
    if role == 'alerta':
        v = echo(vocal(.42, J(190, 230), J(260, 320), 'ah', breath=.3, lowcut=1800), [.13], [.35], 1500)
        return mix([(v, 0, 1.0), clink(.1), clink(.28)], dur=.6)
    if role == 'ataque':
        return mix([(vocal(.2, 200, 130, 'ah', breath=.6, lowcut=2200, peak=.15), 0, 1.0), clink(.02)], dur=.3)
    return mix([(vocal(.26, 220, 140, 'oo', breath=.2, lowcut=2000), 0, 1.0), clink(.1)], dur=.3)


FAMS = [('inseto', inseto), ('aracnideo', aracnideo), ('reptil', reptil), ('anfibio', anfibio),
        ('voador', voador), ('pedra', pedra), ('lava', lava), ('gosma', gosma), ('humano', humano)]
ROLES = [('alerta', -1.5, (300, 600)), ('ataque', -3.5, (200, 400)), ('dor', -3.5, (150, 300))]


def _register():
    for fam, fn in FAMS:
        for role, lvl, dr in ROLES:
            sfx(f'{fam}_{role}', 2, lvl, d=dr)(lambda v, fn=fn, role=role: fn(role))


_register()
