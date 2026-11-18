# Desenha o mapa de cada camada (câmaras, bichos, pilares, luz) e marca as câmaras vazias.
# Antes rode:  godot --headless --path . res://tests/analise_mapa.tscn | grep ^ROOM > /tmp/rooms.tsv
# (o teste grava /tmp/mapa_B.json e /tmp/mapa_G.json). Saída em /tmp/mapout/.
import json, sys, collections
from PIL import Image, ImageDraw, ImageFont
rows = {}
for line in open('/tmp/rooms.tsv'):
    f = line.rstrip('\n').split('\t')
    rows[(f[1], f[2])] = dict(area=int(f[4]), nb=int(f[5]), nc=int(f[6]), dens=float(f[7]), bichos=json.loads(f[8]), coisas=json.loads(f[9]))
try:
    FB = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 22)
    FS = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
    FT = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 30)
    FX = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 12)
except Exception:
    FB = FS = FT = FX = ImageFont.load_default()
PAL = [(70,96,140),(88,120,96),(120,92,130),(130,110,70),(70,120,130),(120,80,80),(90,90,140),(100,130,80)]
def level(d):
    if d < 0.7: return 'vazia', (235,70,60)
    if d < 1.5: return 'pouca coisa', (240,170,50)
    return 'ok', None
def render(layer, title, sel, out):
    D = json.load(open(f'/tmp/mapa_{layer}.json'))
    ox, oz = D['origin']; W, H = D['w'], D['h']
    ids = [r for r in D['rooms'] if sel(r)]
    cells = [c for r in ids for c in D['rooms'][r]]
    if not cells: return
    xs = [c[0] for c in cells]; ys = [c[1] for c in cells]
    x0, x1, y0, y1 = min(xs)-6, max(xs)+6, min(ys)-6, max(ys)+6
    S = 7; M = 70; LEG = 330
    img = Image.new('RGB', ((x1-x0)*S + 2*M + LEG, (y1-y0)*S + 2*M + 60), (14,14,20))
    d = ImageDraw.Draw(img)
    def px(i, j): return (M + (i-x0)*S, M + 60 + (j-y0)*S)
    # chão andável fora das câmaras
    for j in range(y0, y1):
        if j < 0 or j >= H: continue
        row = D['walk'][j]
        for i in range(x0, x1):
            if 0 <= i < W and row[i] == '1':
                a = px(i, j); d.rectangle([a[0], a[1], a[0]+S-1, a[1]+S-1], fill=(38,38,48))
    cent = {}
    for k, r in enumerate(sorted(ids)):
        col = PAL[k % len(PAL)]
        st = rows.get((layer, r))
        lv, warn = level(st['dens']) if st else ('ok', None)
        for c in D['rooms'][r]:
            a = px(*c); d.rectangle([a[0], a[1], a[0]+S-1, a[1]+S-1], fill=col)
        cs = D['rooms'][r]
        cent[r] = (sum(c[0] for c in cs)/len(cs), sum(c[1] for c in cs)/len(cs))
        if warn:
            # borda da câmara
            cellset = set(map(tuple, cs))
            for (i, j) in cellset:
                a = px(i, j)
                for (di, dj, seg) in ((1,0,[(S-1,0),(S-1,S-1)]),(-1,0,[(0,0),(0,S-1)]),(0,1,[(0,S-1),(S-1,S-1)]),(0,-1,[(0,0),(S-1,0)])):
                    if (i+di, j+dj) not in cellset:
                        d.line([(a[0]+seg[0][0], a[1]+seg[0][1]), (a[0]+seg[1][0], a[1]+seg[1][1])], fill=warn, width=3)
    # grade de 10 m
    for i in range(x0 - x0 % 10, x1, 10):
        a = px(i, y0); d.line([a, (a[0], img.height - M + 10)], fill=(60,60,72), width=1)
        d.text((a[0]+2, M + 40), f'x{int(ox+i)}', font=FX, fill=(110,110,125))
    for j in range(y0 - y0 % 10, y1, 10):
        a = px(x0, j); d.line([a, (img.width - LEG - M + 10, a[1])], fill=(60,60,72), width=1)
        d.text((M - 50, a[1]-7), f'z{int(oz+j)}', font=FX, fill=(110,110,125))
    # pontos
    for kind, name, X, Z in D['pts']:
        i, j = X - ox, Z - oz
        if not (x0 <= i < x1 and y0 <= j < y1): continue
        a = px(i, j); a = (a[0], a[1])
        if kind == 'bicho':
            c = (240,90,90) if ('Centopeia' in name or 'Lagarto' in name or 'Serpente' in name) else (150,110,255) if 'Escorpi' in name else (190,160,110) if 'Besouro' in name else (255,150,40) if ('Salamandra' in name or 'Peixe' in name or 'Verme' in name) else (120,120,130) if 'Golem' in name else (250,210,80) if 'Sapo' in name else (200,140,255) if 'Irmã' in name else (255,120,210) if 'Morcego' in name else (170,60,40) if 'Formiga' in name else (60,200,200) if 'Cobra' in name else (120,230,120)
            d.ellipse([a[0]-5, a[1]-5, a[0]+5, a[1]+5], fill=c, outline=(0,0,0))
        elif kind == 'anchor':
            d.rectangle([a[0]-3, a[1]-3, a[0]+3, a[1]+3], fill=(210,210,220))
        elif kind == 'fungus_light':
            d.ellipse([a[0]-3, a[1]-3, a[0]+3, a[1]+3], fill=(90,255,170))
        elif kind == 'pickup':
            d.polygon([(a[0], a[1]-7), (a[0]+5, a[1]), (a[0], a[1]+7), (a[0]-5, a[1])], fill=(200,120,255), outline=(255,255,255))
        elif kind == 'nest':
            d.ellipse([a[0]-9, a[1]-9, a[0]+9, a[1]+9], fill=(110,70,45), outline=(220,150,90), width=2)
        elif kind == 'fire':
            d.polygon([(a[0], a[1]-6), (a[0]-5, a[1]+4), (a[0]+5, a[1]+4)], fill=(255,140,40))
        else:
            d.polygon([(a[0], a[1]-6), (a[0]+6, a[1]), (a[0], a[1]+6), (a[0]-6, a[1])], fill=(255,180,60))
    for r, (ci, cj) in cent.items():
        a = px(ci, cj)
        st = rows.get((layer, r)); lv, warn = level(st['dens']) if st else ('ok', None)
        t = r; name = D['names'].get(r, '')
        for txt, fnt, dy in ((t, FB, -16), (name, FS, 8)):
            w = d.textlength(txt, font=fnt)
            d.text((a[0]-w/2+1, a[1]+dy+1), txt, font=fnt, fill=(0,0,0))
            d.text((a[0]-w/2, a[1]+dy), txt, font=fnt, fill=warn if warn else (240,240,245))
    d.text((M, 20), title, font=FT, fill=(240,240,245))
    # legenda
    lx = img.width - LEG + 10; ly = M + 60
    items = [((235,70,60),'borda vermelha = câmara vazia'),((240,170,50),'borda laranja = pouca coisa'),
             ((250,210,80),'Sapo'),((200,140,255),'Irmã'),((255,120,210),'Morcego'),((120,230,120),'Larva'),((240,90,90),'Lagarto / Centopeia / Serpente'),((170,60,40),'Formiga (novo)'),((60,200,200),'Cobra'),((190,160,110),'Besouro'),((150,110,255),'Escorpião'),((255,150,40),'Bicho de fogo'),((120,120,130),'Golem'),((110,70,45),'formigueiro'),((200,120,255),'coletável'),
             ((210,210,220),'pilar / gancho (âncora)'),((90,255,170),'fungo de luz'),((255,140,40),'tocha'),((255,180,60),'isca / item / outro'),((38,38,48),'chão fora de câmara')]
    for c, t in items:
        d.rectangle([lx, ly, lx+16, ly+16], fill=c); d.text((lx+24, ly), t, font=FS, fill=(220,220,230)); ly += 26
    ly += 14; d.text((lx, ly), 'Mais vazias (coisas a cada 100 m²):', font=FS, fill=(240,240,245)); ly += 24
    lst = sorted([(rows[(layer, r)]['dens'], r) for r in ids if (layer, r) in rows])
    for dens, r in lst[:12]:
        lv, warn = level(dens)
        d.text((lx, ly), f'{r} {D["names"].get(r,"")[:20]}  {dens:.2f}', font=FS, fill=warn or (200,200,210)); ly += 20
    img.save(out)
    print(out, img.size)
import os; os.makedirs('/tmp/mapout', exist_ok=True)
render('B', 'Berçário — mapa atual', lambda r: True, '/tmp/mapout/mapa_bercario.png')
render('G', 'Galerias Úmidas — andar de cima', lambda r: r.startswith('G'), '/tmp/mapout/mapa_galerias_cima.png')
render('G', 'Galerias Úmidas — Profundezas', lambda r: r.startswith('P'), '/tmp/mapout/mapa_galerias_profundezas.png')
render('A', 'Abismo — Ato 2', lambda r: True, '/tmp/mapout/mapa_abismo.png')
render('R', 'Rio de Brasa — Ato 3', lambda r: True, '/tmp/mapout/mapa_rio.png')
