"""check_sfx.py - decodifica os .ogg dos efeitos e confere o que o jogo vai tocar."""
import os
import subprocess

import numpy as np
from scipy import signal

import cs_synth as cs
import make_sfx

LV = {'b': -9.0, 'm': -3.0, 'a': 0.0}


def channels(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'a:0', '-show_entries',
                          'stream=channels', '-of', 'csv=p=0', path], capture_output=True, text=True)
    return int(out.stdout.strip())


def main():
    entries = make_sfx.load()
    base = os.path.join(make_sfx.OUT, 'ogg')
    bad = 0
    n_files = 0
    print(f"{'arquivo':28s} {'ch':>2s} {'dur ms':>8s} {'pico':>6s} {'alvo':>6s} {'emenda':>6s} "
          f"{'inicio':>6s} {'>10k':>6s} {'<60Hz':>6s}  status")
    for e in entries:
        name, n, level, loop, stereo, d, fn = e
        lv = LV[level] if isinstance(level, str) else float(level)
        for fname, v in make_sfx.files_of(e):
            p = os.path.join(base, fname + '.ogg')
            n_files += 1
            if not os.path.exists(p):
                print(f'{fname:28s} FALTA')
                bad += 1
                continue
            ch = channels(p)
            x = cs.decode_ogg(p, ch)
            dur = x.shape[1] / cs.SR * 1000
            pk = 20 * np.log10(np.abs(x).max())
            tgt = -1 + lv
            m = x.mean(0)
            thr = np.abs(m).max() * .01                     # -40 dB
            onset = np.argmax(np.abs(m) > thr) / cs.SR * 1000
            seam = cs.seam_ratio(x) if loop else float('nan')
            F = np.abs(np.fft.rfft(m)) ** 2
            f = np.fft.rfftfreq(len(m), 1 / cs.SR)
            hi = F[f > 10000].sum() / F.sum()
            lo = np.sqrt(F[f < 60].sum() / F.sum())
            probs = []
            if ch != (2 if stereo else 1):
                probs.append('canais')
            if pk > -1.0 + 1e-6:
                probs.append('pico>-1')
            if pk < tgt - 1.2:
                probs.append('nivel')
            if d:
                lo_d, hi_d = (d * 1000, d * 1000) if loop else d
                if loop and abs(dur - lo_d) > 20:
                    probs.append('duracao')
                if not loop and not (lo_d * .8 <= dur <= hi_d * 1.2):
                    probs.append('duracao')
            if loop and seam > 1.5:
                probs.append('emenda')
            if not loop and onset > 40:
                probs.append('inicio')
            if hi > .01:
                probs.append('>10k')
            if lo > .7:
                probs.append('grave')
            bad += bool(probs)
            if probs or fname.endswith(('_1', 'loop')) or n == 1:
                print(f"{fname:28s} {ch:2d} {dur:8.0f} {pk:6.1f} {tgt:6.1f} {seam:6.2f} "
                      f"{onset:6.1f} {100 * hi:5.2f}% {lo:6.2f}  {'OK' if not probs else ','.join(probs)}")
    print(f'\n{n_files} arquivos, {bad} com problema')


if __name__ == '__main__':
    main()
