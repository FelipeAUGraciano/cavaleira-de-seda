"""make_sfx.py - gera os efeitos sonoros de Cavaleira de Seda.

Uso:  python3 make_sfx.py                 (todos)
      python3 make_sfx.py pc_ kit_corte   (so os que comecam com esses prefixos)
Saida: saida_sfx/wav/*.wav e saida_sfx/ogg/*.ogg  ->  copie os .ogg para res://audio/sfx/
Semente fixa por arquivo (CRC32 do nome): o resultado nao depende da ordem nem do filtro.
"""
import importlib
import os
import sys
import time
import zlib

import numpy as np

import cs_synth as cs
import sfx_lib as L

MODS = ['sfx_a', 'sfx_b', 'sfx_c', 'sfx_d']
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saida_sfx')


def load():
    for m in MODS:
        importlib.import_module(m)
    return L.SFX


def files_of(entry):
    name, n, level, loop, stereo, d, fn = entry
    for v in range(n):
        yield (f'{name}_{v + 1}' if n > 1 else name), v


def render(entry, fname, v):
    name, n, level, loop, stereo, d, fn = entry
    cs.reseed(zlib.crc32(fname.encode()))
    x = fn(v)
    return L.finish(x, level, loop=loop)


def main(prefixes):
    os.makedirs(OUT, exist_ok=True)
    entries = load()
    count = 0
    t0 = time.time()
    for e in entries:
        for fname, v in files_of(e):
            if prefixes and not any(fname.startswith(p) for p in prefixes):
                continue
            x = render(e, fname, v)
            assert np.all(np.isfinite(x)), fname
            src = x
            ceil = 0.0
            for _ in range(5):                       # confere o OGG decodificado: pico <= -1 dBFS
                cs.save(fname, x, OUT)
                if not cs.shutil.which('ffmpeg'):
                    break
                dec = cs.decode_ogg(os.path.join(OUT, 'ogg', fname + '.ogg'), x.shape[0])
                over = 20 * np.log10(np.abs(dec).max() + 1e-12) + 1.0
                if over <= 0:
                    break
                ceil -= over + .05
                x = src * 10 ** (ceil / 20)
            count += 1
            print(f'  {fname:30s} {x.shape[0]}ch {x.shape[1] / cs.SR * 1000:7.0f} ms  '
                  f'pico {20 * np.log10(np.abs(x).max()):5.1f} dB', flush=True)
    print(f'{count} arquivos em {time.time() - t0:.0f}s')


if __name__ == '__main__':
    main(sys.argv[1:])
