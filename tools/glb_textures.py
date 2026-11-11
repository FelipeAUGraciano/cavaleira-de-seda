"""Reduz as texturas de um .glb (PNG 4K -> 1024) e reempacota. Uso: glb_textures.py in.glb out.glb [lado]
A cor vira JPEG (sem transparência); normal e rugosidade continuam PNG."""
import sys, struct, json, io
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
side = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
b = open(src, 'rb').read()
clen, = struct.unpack('<I', b[12:16])
j = json.loads(b[20:20 + clen])
off = 20 + clen
blen, = struct.unpack('<I', b[off:off + 4])
binc = b[off + 8:off + 8 + blen]

views = j['bufferViews']
image_views = {im['bufferView'] for im in j.get('images', []) if 'bufferView' in im}
normal_imgs = set()
for m in j.get('materials', []):
    if 'normalTexture' in m:
        normal_imgs.add(j['textures'][m['normalTexture']['index']]['source'])
base_imgs = set()
for m in j.get('materials', []):
    t = m.get('pbrMetallicRoughness', {}).get('baseColorTexture')
    if t: base_imgs.add(j['textures'][t['index']]['source'])

new_data = {}
for i, im in enumerate(j.get('images', [])):
    v = views[im['bufferView']]
    raw = binc[v.get('byteOffset', 0):v.get('byteOffset', 0) + v['byteLength']]
    img = Image.open(io.BytesIO(raw))
    print(f'  imagem {i}: {img.size} {img.mode}', 'normal' if i in normal_imgs else 'cor' if i in base_imgs else 'outra')
    if max(img.size) > side:
        img = img.resize((side, side), Image.LANCZOS)
    out = io.BytesIO()
    if i in base_imgs and img.mode in ('RGB', 'RGBA') and (img.mode == 'RGB' or img.getextrema()[3][0] == 255):
        img.convert('RGB').save(out, 'JPEG', quality=90)
        im['mimeType'] = 'image/jpeg'
    else:
        img.save(out, 'PNG', optimize=True)
        im['mimeType'] = 'image/png'
    new_data[im['bufferView']] = out.getvalue()

# reconstrói o buffer binário
newbin = bytearray()
for vi, v in enumerate(views):
    start = v.get('byteOffset', 0)
    data = new_data.get(vi, binc[start:start + v['byteLength']])
    while len(newbin) % 4: newbin.append(0)
    v['byteOffset'] = len(newbin)
    v['byteLength'] = len(data)
    newbin += data
while len(newbin) % 4: newbin.append(0)
j['buffers'][0]['byteLength'] = len(newbin)
js = json.dumps(j, separators=(',', ':')).encode()
while len(js) % 4: js += b' '
total = 12 + 8 + len(js) + 8 + len(newbin)
with open(dst, 'wb') as f:
    f.write(struct.pack('<III', 0x46546C67, 2, total))
    f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
    f.write(struct.pack('<II', len(newbin), 0x004E4942)); f.write(newbin)
print(f'{dst}: {total/1e6:.1f} MB')
