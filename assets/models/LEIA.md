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

| Mãe: corpo | mae_corpo/mae_corpo_v01.glb | 43 mil → 16 mil triângulos; patas nos `leg_socket_L1..R4` |
| Mãe: pata | mae_pata/mae_pata_v01.glb | 4 mil triângulos; juntas hip → joint_1..3 → tip (dobradas em código, actors/bosses/mae_legs.gd) |
| Ovo (novo) | ovo/ovo_v02.glb | 2,8 mil triângulos; brilho reduzido em systems/models.gd (TUNING) |
| Casulo | casulo/casulo_v01.glb | 15,6 mil → 6 mil |
| Presa embrulhada | presa/presa_v01.glb | 11,7 mil → 3 mil (cadáveres) |
| Cristal | cristal/cristal_v01.glb | 108 triângulos (cristais de PV/Energia) |
| Pilar de teia | pilar_teia/pilar_teia_v01.glb | 14,6 mil → 6 mil (Berçário) |
| Estalagmites A, B, C | estalagmite_*/..._v01.glb | ~2,5 mil cada; pilares das Galerias e enfeite das cavernas (clareadas no TUNING) |
| Rochas A, B, C | rocha_*/..._v01.glb | 2 mil cada (clareadas no TUNING) |
| Fungos roxo e verde | fungo_*/..._v01.glb | 8,5 mil → 1,5 mil cada |
| Teia de canto | teia_canto/teia_canto_v01.glb | 1,6 mil; deitada no chão como teia decorativa |

Os nós vazios com nome (encaixes, pontos de encaixe) só sobrevivem porque `preparar_modelo.sh` usa `gltfpack -kn`.
