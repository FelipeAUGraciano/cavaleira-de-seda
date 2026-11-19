"""check.py - decodifica os .ogg finais e confere o que o jogo vai realmente tocar."""
import glob
import os
import subprocess

import numpy as np
from scipy import signal

import cs_synth as cs

LOOPS_EXPECT = {   # duracao esperada (s) a partir do BPM/compassos do prompt
    'mus_galerias': 32 * 4 * 60 / 84, 'mus_galerias_tensao': 32 * 4 * 60 / 84,
    'mus_bercario': 24 * 4 * 60 / 72, 'mus_bercario_tensao': 24 * 4 * 60 / 72,
    'mus_boss_centopeia': 6 * 15 * 60 / 128, 'mus_boss_centopeia_intro': 15 * 60 / 128,
    'mus_abismo': 96.0, 'mus_abismo_tensao': 96.0, 'mus_colosso': 32.0,
    'mus_boss_serpente': 32 * 3 * 60 / 92, 'mus_boss_serpente_intro': 4 * 3 * 60 / 92,
    'mus_rio': 32 * 4 * 60 / 96, 'mus_boss_rainha': 32 * 4 * 60 / 132,
    'mus_boss_rainha_tensao': 32 * 4 * 60 / 132,
    'mus_cacada': 32 * 4 * 60 / 84, 'mus_cacada_tensao': 32 * 4 * 60 / 84,
    'mus_cacada_alerta': 16 * 4 * 60 / 84, 'mus_boss_capita': 32 * 4 * 60 / 124,
    'mus_fuga_mae': 16 * 4 * 60 / 150, 'mus_portao': 32 * 4 * 60 / 90,
    'mus_boss_guardiao_1': 16 * 4 * 60 / 140, 'mus_casulo': 24 * 3 * 60 / 66,
    'mus_menu': 24 * 4 * 60 / 76,
}
ONESHOT = ('intro', 'stinger', 'trompa')


def decode(path):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-f', 'f32le', '-ac', '2',
                          '-ar', '44100', '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).T.astype(np.float64)


def main():
    base = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saida', 'ogg')
    files = sorted(glob.glob(os.path.join(base, '*.ogg')))
    bad = 0
    print(f"{'arquivo':30s} {'dur':>7s} {'esper':>7s} {'LUFS':>6s} {'pico':>6s} {'emenda':>6s} "
          f"{'cliques':>7s} {'<60Hz':>6s}  status")
    for p in files:
        nm = os.path.basename(p)[:-4]
        x = decode(p)
        dur = x.shape[1] / cs.SR
        pk = 20 * np.log10(np.abs(x).max())
        lu = cs.lufs_of(x)
        is_one = any(k in nm for k in ONESHOT)
        seam = cs.seam_ratio(x) if not is_one else float('nan')
        # cliques isolados: salto muito acima do vizinho (alta-passada, janela deslizante)
        h = signal.sosfilt(signal.butter(2, 3000, 'highpass', fs=cs.SR, output='sos'), x[0])
        a = np.abs(h)
        loc = np.convolve(a, np.ones(2205) / 2205, 'same') + 1e-6
        clicks = int(np.sum((a > 14 * loc) & (a > 0.02)))
        lo = signal.sosfilt(signal.butter(4, 60, 'lowpass', fs=cs.SR, output='sos'), x[0])
        lofrac = np.sqrt(np.mean(lo ** 2) / (np.mean(x[0] ** 2) + 1e-12))
        exp = LOOPS_EXPECT.get(nm)
        if nm.endswith('_guardiao_2') or nm.endswith('_guardiao_3'):
            exp = LOOPS_EXPECT['mus_boss_guardiao_1']
        if nm == 'mus_portao_tensao':
            exp = LOOPS_EXPECT['mus_portao']
        probs = []
        if pk > -1.0:
            probs.append('pico>-1')
        if exp and abs(dur - exp) > 0.03:
            probs.append('duracao')
        if not is_one and seam > 1.5:
            probs.append('emenda')
        if lofrac > (0.65 if nm == 'mus_colosso' else 0.6):
            probs.append('grave-forte')
        if not np.all(np.isfinite(x)):
            probs.append('NaN')
        bad += bool(probs)
        print(f"{nm:30s} {dur:7.2f} {exp if exp else float('nan'):7.2f} {lu:6.1f} {pk:6.1f} "
              f"{seam:6.2f} {clicks:7d} {lofrac:6.2f}  {'OK' if not probs else ','.join(probs)}")
    print(f"\n{len(files)} arquivos, {bad} com problema")


if __name__ == '__main__':
    main()
