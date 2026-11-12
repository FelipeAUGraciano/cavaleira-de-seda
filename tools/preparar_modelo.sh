#!/usr/bin/env bash
# Prepara um .glb vindo da IA (Hunyuan, TRELLIS, Tripo) para o jogo:
#   1. reduz a malha para ~N triângulos (gltfpack)       2. reduz as texturas para 1024 px
# Uso: tools/preparar_modelo.sh entrada.glb nome [triangulos]
#   ex.: tools/preparar_modelo.sh ~/Downloads/abc.glb sapo 20000
# Sai em assets/models/<nome>/<nome>_vNN.glb (próxima versão livre).
# Precisa de: gltfpack (npm i -g gltfpack) e Python 3 com Pillow (pip install pillow).
set -euo pipefail
in="$1"; name="$2"; tris="${3:-20000}"
here="$(cd "$(dirname "$0")/.." && pwd)"
dir="$here/assets/models/$name"; mkdir -p "$dir"
v=1; while [ -e "$dir/${name}_v$(printf %02d $v).glb" ]; do v=$((v+1)); done
out="$dir/${name}_v$(printf %02d $v).glb"
total=$(python3 - "$in" <<'PY'
import sys,struct,json
b=open(sys.argv[1],'rb').read(); n,=struct.unpack('<I',b[12:16]); j=json.loads(b[20:20+n])
print(sum(j['accessors'][p['indices']]['count']//3 for m in j['meshes'] for p in m['primitives'] if 'indices' in p))
PY
)
ratio=$(python3 -c "print(min(1.0, $tris / max($total, 1)))")
echo "$total triângulos -> ~$tris (fator $ratio)"
tmp="$(mktemp --suffix .glb)"
gltfpack -i "$in" -o "$tmp" -si "$ratio" -noq -kn   # -kn: mantém nós com nome (encaixes de patas, ponto da lâmina)
python3 "$here/tools/glb_textures.py" "$tmp" "$out" 1024
rm -f "$tmp"
echo "Pronto: $out"
