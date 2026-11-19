"""make_all.py - gera as musicas de Cavaleira de Seda.

Uso:  python3 make_all.py            (todas, na ordem sugerida)
      python3 make_all.py galerias bercario   (so essas)
Saida: saida/wav/*.wav e saida/ogg/*.ogg  (copie os .ogg para res://audio/music/)
"""
import importlib
import os
import sys
import time

import numpy as np

import cs_synth as cs

MODS = ['tracks_a', 'tracks_b', 'tracks_c', 'tracks_d', 'tracks_e']
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saida')


def registry():
    reg = {}
    for m in MODS:
        try:
            reg.update(importlib.import_module(m).TRACKS)
        except ModuleNotFoundError as e:
            if e.name != m:
                raise
    return reg


def main(names):
    reg = registry()
    names = names or list(reg)
    for nm in names:
        t0 = time.time()
        files = reg[nm]()
        for fname, (audio, is_loop) in files.items():
            assert np.all(np.isfinite(audio)), fname
            ceil = cs.PEAK_DB
            src = audio
            for _ in range(5):                      # o Vorbis pode "estourar" o pico: confere decodificado
                cs.save(fname, audio, OUT)
                if not cs.shutil.which('ffmpeg'):
                    break
                dec = cs.decode_ogg(os.path.join(OUT, 'ogg', fname + '.ogg'))
                over = 20 * np.log10(np.abs(dec).max()) + 1.0   # dB acima de -1 dBFS
                if over <= 0:
                    break
                ceil -= over + 0.2
                audio = cs._limit(src, 10 ** (ceil / 20))
            pk = 20 * np.log10(np.abs(audio).max())
            seam = f"emenda={cs.seam_ratio(audio):.2f}" if is_loop else "sem loop"
            print(f"  {fname:34s} {audio.shape[1] / cs.SR:6.2f}s  "
                  f"{cs.lufs_of(audio):6.1f} LUFS  pico {pk:5.1f} dB  {seam}", flush=True)
        print(f"[{nm}] {time.time() - t0:.1f}s")


if __name__ == '__main__':
    main(sys.argv[1:])
