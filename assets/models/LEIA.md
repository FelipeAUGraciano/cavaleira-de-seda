# Modelos 3D

Um modelo por pasta: `assets/models/<nome>/<nome>_v01.glb`. O jogo usa sempre a versão mais alta.
Antes de colocar aqui, passe o arquivo da IA por `tools/preparar_modelo.sh` (reduz malha e texturas).
A lista de nomes e os pedidos para a IA estão na aba "Modelos 3D" do GDD.

| Modelo | Arquivo | Origem |
| --- | --- | --- |
| Irmã-aranha (veio com patas) | irma_corpo/irma_corpo_v01.glb | Hunyuan 3D, 1,5 M → 20 mil triângulos |
| Sapo-de-rocha | sapo/sapo_v01.glb | Hunyuan 3D, 1,5 M → 20 mil triângulos |
| Ovo de aranha | ovo/ovo_v01.glb | Hunyuan 3D, 1,5 M → 2 mil triângulos (brilho leve no ninho) |
| Larva-de-musgo | larva/larva_v01.glb | Hunyuan 3D, 1,5 M → 5 mil triângulos |
| Morcego-eco | morcego/morcego_v01.glb | 8 mil triângulos (asas abertas) |
| Lagarto-lanterna | lagarto/lagarto_v01.glb | 12 mil triângulos; a isca do modelo substitui a de código (a luz continua) |
| Centopeia: cabeça | centopeia_cabeca/centopeia_cabeca_v01.glb | 8 mil triângulos |
| Centopeia: segmento | centopeia_segmento/centopeia_segmento_v01.glb | 3 mil triângulos, repetido 11 vezes |
| Centopeia: cauda | centopeia_cauda/centopeia_cauda_v01.glb | 4 mil triângulos |
| Cavaleira: corpo | cavaleira_corpo/cavaleira_corpo_v01.glb | 32 mil → 16 mil triângulos; os nós `leg_socket_L1..R4` dizem de onde saem as patas |
| Cavaleira: segmento de pata | cavaleira_pata/cavaleira_pata_v01.glb | 1,5 mil triângulos; esticado no fêmur e na tíbia das 8 patas (16 peças) |
| Cavaleira: lâmina de cristal | cavaleira_lamina/cavaleira_lamina_v01.glb | 68 triângulos, cristal transparente; `attach_point` é onde ela prende. Só na forma Cavaleira |

Os nós vazios com nome (encaixes, pontos de encaixe) só sobrevivem porque `preparar_modelo.sh` usa `gltfpack -kn`.
