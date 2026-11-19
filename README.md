# Cavaleira de Seda — v0.8

Fangame top-down de sobrevivência e estratégia: uma aranha recém-nascida precisa sobreviver numa caverna onde tudo é maior que ela. O **Ato 1 é jogável do começo ao fim** (Berçário e Galerias Úmidas, até a Centopeia-blindada) o **Ato 2** (a queda pela Fenda e o Abismo inteiro, até a Serpente-cega) o **Ato 3** (o Rio de Brasa inteiro, até a Salamandra-rainha e a Chaminé) e o **Ato 4** (a caçada nas Galerias, até a Capitã da expedição). Visão curta e quedas para o andar de baixo. Morrer te leva de volta à sua toca (ou ao último ponto seguro), e o andar continua como você deixou.

O que mudou em cada versão está em [`CHANGELOG.md`](CHANGELOG.md). O design completo fica no GDD (documento do projeto).

## O que tem hoje

- **Protagonista:** Filhote de Seda que vira Cavaleira de Seda no nível 8 (muda no casulo). No nível 10 da Cavaleira, você escolhe um dos três ramos: Ceifadora de Seda (Lâmina), Tecelã do Abismo (Teia) ou Arauta da Runa (Runa). No nível 10 do ramo vem a **última muda**: cada ramo se divide em dois (Executora ou Bastiã; Senhora das Teias ou Saltadora do Vento; Vidente ou Sacerdotisa da Tempestade), ou ela vira uma das **5 formas raras** se cumpriu os requisitos (Seda Ardente, Sombra do Breu, Viúva de Seda, Corrosiva, Cavaleira de Pedra-da-lua). **Cada ramo troca o golpe e a mordida por ataques próprios**, e cada forma final tem **dois estilos de ataque (A/B)**, trocados no casulo (ver CHANGELOG). Combo com cone no chão, mordida com bote e veneno, esquiva, fio lançado (Q) que puxa bichos ou te puxa até a parede, fio-guia e teia de captura no Modo Tecelagem, runa que ilumina (e te denuncia).
- **Toca:** nas Galerias, a G22 Fosso escuro é a câmara-toca. Você toma posse tecendo o casulo central no ninho velho (C) e fecha as 4 entradas com portas de teia (você passa, os bichos não). Só a toca salva e cura; antes dela o jogo salva sozinho nos pontos seguros, sem curar. Bichos com fome sentem a comida guardada, rasgam as portas e comem da despensa; fios-alarme avisam de longe.
- **Comida:** a despensa (10 embrulhos) fica na toca. Na viagem você leva 2 na bolsa e come com G em qualquer lugar. Presa pequena você embrulha onde estiver (C); presa grande vai arrastada no fio até a toca.
- **Menu da toca:** teia de 17 habilidades (1 ponto por nível), evolução, despensa, portas e fios-alarme. Descansar salva, cura, remenda portas e faz a muda; não dá para dormir com um bicho te caçando perto.
- **Criaturas:** irmãs, larvas, sapos, morcegos, lagartos, formigas-de-seda (em fila, roem seus fios), cobras-das-frestas (bote da parede), besouros carniceiros, escorpiões-de-obsidiana, aranhas-lobo do breu, mímicos de estalagmite, lesmas de ácido, morcegos gigantes, a Cortina viva, a Mãe, a Centopeia-blindada, o Colosso do Abismo e a Serpente-cega, com fome, sono, medo e golpes avisados por marcas no chão. Teia por tamanho (pequeno fica preso, médio rasga, grande arrebenta).
- **Mundo:** Galerias em dois andares geradas como caverna orgânica, ciclo de luz de 5 minutos, território, pilares variados, ganchos de parede nos abismos.
- **Menus:** menu inicial com a caverna em 3D ao fundo (a Cavaleira na frente da teia), 3 espaços de save, pausa com o lugar e um cartão da Cavaleira, Opções (som, tela, brilho, controles remapeáveis no teclado e no controle). Tudo no estilo de seda (`ui/silk_ui.gd`).
- **Arte:** modelos 3D da protagonista, de todas as criaturas, da Mãe e dos props; o chão e as paredes são gerados em código.

## Como abrir

1. Instale o **Godot 4.7.x** (versão padrão, não a .NET): https://godotengine.org/download
2. Abra o Godot → **Importar** → escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar. Abre o menu inicial: **Novo jogo** escolhe um dos 3 espaços e começa do Berçário, **Continuar** volta ao último save, **Carregar** escolhe outro espaço.

## Controles

| Ação | Teclado e mouse | Controle |
| --- | --- | --- |
| Mover | WASD | Analógico esquerdo |
| Mirar | Mouse | Analógico direito |
| Ataque (combo de 3, cone no chão) | Botão esquerdo | X |
| Mordida (bote + veneno) | Botão direito | Y |
| Esquiva / backstep (parada) | Espaço | A |
| Correr | Shift | LB |
| Lançar fio (puxa bicho / te puxa até a parede) | Q | RB |
| Modo Tecelagem (segurar) | R | LT |
| Leitura de criatura (segurar) | Alt ou Tab | RT |
| Comer / abrir o menu da toca | E | B |
| Tecer: embrulhar, arrastar, porta, casulo da toca | C | Direcional para baixo |
| Comer embrulho da bolsa | G | Direcional para a esquerda |
| Apagar / acender runa | F | Clique no analógico direito |
| Mapa | M | Direcional para cima |
| Ajuda na tela | H | Back |
| Pausa, Opções e menu | Esc | Start |
| Testes: +1 nível / novo jogo direto | F1 / F8 | — |

Todas as teclas podem ser trocadas em **Opções → Controles**. No **Modo Tecelagem** o tempo cai para 25%. Clique em um pilar e depois em outro (até 12 m) para esticar um **fio-guia**. Andar no fio é 1,5× mais rápido, silencioso, e é o único jeito de cruzar o abismo. O botão direito arma uma **teia de captura** (a partir do nível 3). Fio e teia de captura aguentam **3 de peso** (3 presas pequenas; um bicho médio pesa 2): passou disso, arrebentam e soltam todo mundo. A **Seda não volta sozinha**: só comendo ou descansando na toca. Quando algo toca sua teia, uma **seta** em volta da aranha aponta de onde veio (branca = pequeno, laranja = médio, vermelha = grande).

## O que tem em cada camada

**Berçário (início):** B1 eclosão (coma uma irmã menor) → B2 corredor (uma irmã faminta te caça; ou vá pela trilha baixa, mais escura) → B3 salão das teias (primeiro fio-guia sobre o abismo; a fresta ao sul leva ao cristal secreto de B4) → B5 despensa (apague a runa com F e passe pela pata da Mãe) → B6 fuga (corra! teça o fio no segundo abismo) → túnel para as Galerias. Na saída começa a cena final: ela dispara túnel adentro, a Mãe bate na entrada e a pedra desaba atrás; depois vem a tela de carregamento (uma teia sendo tecida, com o "Fim do prólogo" e dicas) e a chegada nas Galerias, ela entrando correndo e o nome da área numa faixa escura, à la Elden Ring.

**Galerias Úmidas (dois andares):** caverna orgânica com bolsões de abismo; cair de cima leva ao andar de baixo (P1–P6), de onde se volta pelas passagens. As câmaras principais: G1 entrada → G2 poça (Sapo-de-rocha) ou G3 túnel dos morcegos → G4 Grande Gruta. A sudoeste, G22 Fosso escuro: a toca (casulo central, portas, despensa). Do G4: G5 jardim (Lagarto-lanterna) e G12 ninho (três lagartos, cristal de energia) ao sul, G7 lago (cristal na ilha) a sudoeste, G6 ponte quebrada (três fendas) a leste → G8 Galeria do eco (aventureiros ao longe; fresta secreta para G10) → G9 Acampamento (tochas, diário) → G13 Antecâmara (último ponto seguro) → G14 Covil da Centopeia → G15 Borda da Fenda (queda para o Abismo). G11 Poças ácidas liga o jardim à Antecâmara (Resistência a Ácido 3). A parede de cristal da G16 abre no Ato 4.

**Abismo (Ato 2):** depois da Centopeia, o chão da G15 cede e ela despenca pela Fenda (cena com a câmera descendo junto e dois fios que arrebentam), passa pela tela "Fim do Ato 1" e cai no fundo, ferida (30% da vida) e sem seda. Caverna orgânica de um andar, gerada como as Galerias, com as câmaras de trava e de chefe feitas à mão. Quase breu: só a runa, poucos fungos e cristais. A1 Fundo da queda → A2 Ossário (besouros carniceiros, a primeira comida) → A3 Trilha do Colosso (um dragão da terra faz a ronda; ele sente o chão e os fios; parada de lado e com a runa apagada ele passa; se te alcança, mata na hora; nas rachaduras ele não entra; uma delas leva ao A18 Fosso dos besouros) → A4 Fenda do refúgio (a toca, com 4 frestas). Da toca: A5 Lago negro (uma sombra enorme passa embaixo; a pérola da ilha dá Resistência a Escuridão), A6 Floresta de estalagmites (dezenas de pilares: tecer sobe a Tecelagem), A7 Ninho dos escorpiões (ferrão e carne venenosos: Resistência a Veneno) e, por uma fresta secreta, A10 Câmara de cristal (lâminas que cortam). A ponta leste da Trilha sobe pela A8 Cortina viva (morcegos gigantes: runa apagada e devagar, ou Pulso Espiral) até a Câmara de cristal. A9 Abismo duplo: 17,6 m de fio, só com Tecelagem 5 → A11 Santuário afundado (a espiral da runa, pedras para ler) → A12 Toca da Serpente-cega (chefe cego que caça por vibração: arme uma teia de captura, ela dá o bote na teia que vibra e fica enredada) → A13 Poço de vapor (jatos que queimam) → A14 Rampa quente: Fim do Ato 2 (o Rio de Brasa vem na próxima versão).

**Bichos do Abismo (~60):** besouros, escorpiões, matilhas de aranhas-lobo, mímicos que fingem ser pilar, lesmas de ácido, bandos de morcegos gigantes, o Colosso e a Serpente-cega. A base é a A4 Fenda do refúgio.

**Rio de Brasa (Ato 3):** da Rampa quente do Abismo, tela "Fim do Ato 2" e chegada no rio. **Abismo e Rio são abertos:** a descida a oeste da Margem fria volta ao topo da Rampa quente, e as teias de cada andar ficam onde você deixou. Caverna gerada de um andar cortada por um rio de lava de norte a sul. Perto da lava faz calor (perde vida aos poucos; Resistência a Fogo corta 25% por ponto). No R2 Mirante, a escolha: R3 Ilhas de basalto (rápido, pilares sobre a lava; fio sobre a lava queima em 8 s; a brasa das ilhas pede Resistência a Fogo 3) ou R8 Rota de pedra (longa, sem lava, com golems dormindo). Do outro lado: R7 Câmara fria (a toca, obsidiana resfriada), R6 Ninho das salamandras, R4 Forja dos golems, R5 Gêiseres (arremessam), R9 Pântano de cinzas (a cinza encurta a visão), R10 Cristais de fogo (segredo: Resistência a Fogo +1 e material de evolução rara), R11 Antecâmara, R12 Salamandra-rainha (onda de fogo que queima todas as teias; depois dela a pele esfria), R13 Fluxo resfriado (a lava esfria quando ela cai) e R14 Chaminé (Fim do Ato 3). Bichos: besouros-brasa, peixes-magma e vermes de lava (moram na lava), salamandras-chama, golems de basalto, aranhas de cinza e morcegos de cinza. Comer bichos de fogo sobe a Resistência a Fogo; aguentar calor também (até 2).

**Som:** efeitos sonoros pelo autoload `Sfx` (nomes em `audio/sfx/README.md`; prompts no GDD) e **música:** 32 faixas em `audio/music/` (mapas com camada de tensão que sobe quando um bicho te caça, chefes, casulo, menu e curtas), tocadas pelo autoload `Music`; o gerador em Python fica em `tools/musica/`.

**Ato 4, a caçada:** a Chaminé sai nas Galerias (cena `galerias_cacada.tscn`, o mesmo mapa do Ato 1). Uma expedição humana caça a aranha: alerta da caçada 0–3 (no 3, o esquadrão do acampamento sai atrás de você), espadachins, arqueiras com flechas de fogo e batedores que seguem e queimam seus fios. A Grande Gruta virou o acampamento-base, a toca do Fosso escuro foi queimada e a única toca é a ilha do Lago escondido. Armadilhas de fogo no Jardim, suprimentos para roubar, bichos alfa e comida escassa. As Profundezas são a rota de fuga. A Capitã guarda a corda da Subida antiga (Fim do Ato 4). Caçadores vencidos viram comida.

**Tecelagem:** cada fio-guia tecido conta. Tecelagem 1 a 5 (8, 20, 36 e 56 fios): o fio-guia vai de 12 m a 18 m.

**Câmara de teste:** a câmara cinza da v0.1 continua no projeto (`world/layers/test_chamber.tscn`) para o teste automático dos sistemas.

Sistemas: 4 recursos que aparecem no corpo da aranha (placas = PV, runa = Energia, cachecol = Seda, abdômen = Saciedade), fome, território, vibração nos fios (com seta na tela), toca com save, veneno, Enredado com crítico ×2, furtividade por luz e barulho, e um ecossistema básico (o sapo caça e come larvas).

## Roteiro de teste (20 min)

Comece um jogo novo (menu inicial → Novo jogo) e jogue o Berçário e as Galerias em sequência.

Jogue sem ler o código e anote:

1. Em quanto tempo você entendeu que precisa tecer um fio para atravessar o abismo?
2. A fome te obrigou a sair do casulo? Pareceu justa ou chata?
3. O sapo foi assustador, fácil ou injusto?
4. Você usou a teia de captura e a runa apagada por estratégia, ou só atacou?
5. Os morcegos: você descobriu sozinha que ficar parada te esconde? E que fio esticado derruba eles?
6. O Lagarto-lanterna: o aviso de luz ficou claro antes do ataque?
7. A Centopeia: você entendeu sozinha que precisava fazer ela investir através de um fio? Quantas tentativas levou?
8. A cena dos aventureiros e a queda no fim: deram vontade de continuar?
9. Você se sentiu caçada? As setas vermelhas ajudaram ou só assustaram? A evolução no nível 8 chegou na hora certa?
10. O mundo pareceu vivo? Você reparou nos fungos apagando, nos morcegos saindo em bando, na Centopeia aparecendo onde você estava?
11. Qual foi o momento mais divertido? E o mais frustrante?

## Estrutura do projeto

```
autoload/      EventBus (sinais), GameState (save, espaços, falas), Settings (opções e teclas), WebNetwork (teias e território), Voice (dublagem),
               World (mundo vivo: registro espacial de criaturas e cadáveres, navegação, relógio)
actors/
  player/      player.gd — a Cavaleira
  creatures/   creature.gd (base), larva.gd, frog.gd, bat.gd, lizard.gd, sister.gd, beetle.gd, ember_beetle.gd, scorpion.gd, wolf_spider.gd, ash_spider.gd, fire_salamander.gd, basalt_golem.gd, lava_lurker.gd, magma_fish.gd, lava_worm.gd, ash_bat.gd, mimic.gd, acid_slug.gd, giant_bat.gd, bat_curtain.gd, corpse.gd
  npc/          adventurer.gd, hunter.gd (caçadores do Ato 4), captain.gd (Capitã)
  npc_old/         adventurer.gd (aventureiros vistos de longe)
systems/
  ai/          needs.gd (fome, sono, medo, inquietação), brain.gd (escolhe a atividade),
               behavior.gd (base) e behaviors.gd (vagar, dormir, comer, fugir, passear, combate, recuar, brigar)
  world/       nav_grid.gd (caminhos em 3 grades: pequeno, grande, voo), cave_clock.gd (Brilho/Caça), track.gd (rastros)
  web/         âncoras, fio-guia, teia de captura, casulo
  ecosystem/   repovoamento da câmara
  fx.gd        formas cinza e efeitos simples
world/         title.tscn (menu inicial) + title_diorama.gd (a caverna 3D atrás dele), layer_base.gd (base de toda camada)
  layers/      bercario.tscn, galerias.tscn, abismo.tscn, rio_brasa.tscn, galerias_cacada.tscn, test_chamber.tscn
systems/level/ cave_builder.gd (cavernas orgânicas), map_system.gd, pickup.gd, fire.gd (tochas), note.gd (coisas para ler)
systems/spider_legs.gd   as 8 patas com IK
systems/models.gd        troca formas cinza por modelos .glb (assets/models/)
assets/models/ modelos 3D, um por pasta (veja "Modelos 3D" abaixo)
tools/         preparar_modelo.sh (reduz malha e texturas dos modelos da IA)
actors/bosses/ mother_leg.gd (pata da despensa), mother_chase.gd (fuga), centipede.gd (Centopeia-blindada), colossus.gd (Colosso do Abismo), serpent.gd (Serpente-cega), queen_salamander.gd (Salamandra-rainha)
ui/            silk_ui.gd (cores, fontes e molduras), hud.gd, cocoon_menu.gd (menu do casulo), options_menu.gd, skill_icons.gd, vision_overlay.gd
systems/skills.gd        a teia de habilidades
audio/voice/   arquivos de dublagem (veja docs/falas.md)
tests/         teste automático e capturas de tela
```

Os valores de balanceamento ficam como constantes no topo de cada script (`player.gd`, `frog.gd`, `larva.gd`...).

### Como uma criatura pensa

```
Needs (fome, sono, medo, inquietação)  ──┐
Sentidos (_sense, 5×/s; 1,5×/s longe)  ──┼──> Brain: nota de cada Behavior ──> o de maior nota roda
Fase do relógio (CaveClock)            ──┘        (4×/s perto, 1×/s longe; decide na hora se vê você ou leva dano)
```

Cada espécie monta o seu cérebro em `_make_brain()` com os comportamentos de `systems/ai/behaviors.gd` (e os dela, como a isca do lagarto ou o bote do morcego) e define os ataques em `combat_tick()`. Para criar uma espécie nova: estender `Creature`, preencher a ficha no `_init()` (tamanho, fase de descanso, câmaras por onde passeia, o que come) e escolher os comportamentos.

**Interesse na caça (sapos, irmãs, morcegos):** cada caçador tem um medidor de interesse (0–100). Ver você enche; perder de vista, você fora de alcance (num fio sobre o abismo), longe demais de onde a caça começou (26 m) ou a perseguição sem progresso esvaziam. Fome alta deixa mais teimoso. Zerou: ele desiste, volta à rotina e passa 14 s ignorando você se estiver a mais de 5 m. Com pouco interesse, uma presa fácil por perto (larva) ganha a disputa. Bater nele dá interesse na hora (revida). Lagarto e Centopeia não usam o medidor (emboscada e chefe).

## Dublagem

As falas do monólogo e os nomes de arquivo estão em [`docs/falas.md`](docs/falas.md). Grave, salve como `audio/voice/<id>.ogg` e o jogo toca sozinho.

## Modelos 3D

O jogo procura `assets/models/<nome>/<nome>_vNN.glb` e usa a versão mais alta. Se o arquivo não existe, a forma cinza continua. Os nomes estão na aba "Modelos 3D" do GDD.

As IAs geram modelos pesados demais (o Hunyuan entrega ~1,5 milhão de triângulos e texturas 4K, uns 80 MB). Antes de usar, rode:

```
tools/preparar_modelo.sh ~/Downloads/modelo.glb sapo 20000
```

Ele reduz a malha para ~20 mil triângulos e as texturas para 1024 px (uns 2,5 MB) e salva como a próxima versão. Ajustes finos (girar, subir, escalar, "já veio com patas") ficam na tabela `TUNING` de `systems/models.gd`.

## Fonte

Os nomes de área e a tela de carregamento usam a **Cinzel** (Natanael Gama / The Cinzel Project Authors), sob a SIL Open Font License 1.1 — licença em `ui/fonts/Cinzel-OFL.txt`.

## Testes automáticos

```
godot --headless --path . res://tests/smoke_test.tscn       # sistemas centrais
godot --headless --path . res://tests/bercario_test.tscn    # Berçário de ponta a ponta
godot --headless --path . res://tests/galerias_test.tscn    # Galerias (os dois andares, fios, ganchos, paredes)
godot --headless --path . res://tests/covil_test.tscn       # Antecâmara, Covil e a Centopeia
godot --headless --path . res://tests/vida_test.tscn        # mundo vivo e desempenho
godot --headless --path . res://tests/dificuldade_test.tscn # Filhote, evolução, predadores que te caçam
godot --headless --path . res://tests/hardcore_test.tscn    # golpes, fúria, perseguição, visão, quedas, morte (volta ao casulo)
godot --headless --path . res://tests/golpes_test.tscn      # golpes e fio (Q) da jogadora
godot --headless --path . res://tests/fuga_test.tscn       # fim do prólogo: fuga, carregamento, chegada
godot --headless --path . res://tests/sfx_test.tscn        # efeitos sonoros: variações, famílias, golpes, teia, loops, ambiente
godot --headless --path . res://tests/juice_test.tscn      # pausa no impacto, faíscas, números de dano, morte tombando, tocador de música
godot --headless --path . res://tests/kits_test.tscn       # ataques próprios dos ramos e das formas (estilos A/B)
godot --headless --path . res://tests/evolucao_test.tscn   # última muda: 6 formas de ramo + 5 raras
godot --headless --path . res://tests/cacada_test.tscn     # Ato 4: alerta, caçadores, batedor, armadilhas, ilha, Capitã
godot --headless --path . res://tests/rio_test.tscn        # Rio de Brasa: rotas, calor, fios queimando, bichos de fogo, rainha
godot --headless --path . res://tests/abismo_test.tscn     # queda da Fenda e o Abismo inteiro: Colosso, toca, Tecelagem, escorpiões, Cortina viva, Serpente
godot --headless --path . res://tests/toca_test.tscn       # toca, portas, bolsa, arrasto, saque e save
godot --headless --path . res://tests/novos_test.tscn       # formigas, cobra e coletáveis novos
godot --headless --path . res://tests/caca_test.tscn        # IA: desistir, ignorar, trocar de presa, revidar
godot --headless --path . res://tests/casulo_test.tscn      # habilidades, despensa e menu do casulo
godot --headless --path . res://tests/menu_test.tscn        # menu inicial, espaços de save, Opções e pausa
godot --headless --path . res://tests/models_test.tscn      # modelos 3D e encaixes
tools/checar_avisos.sh godot                                # avisos do GDScript (todos os scripts)
```

Os testes jogam sozinhos: fio sobre o abismo, queda, combate, comer, casulo, save, morte, menus e os chefes. `tests/analise_mapa.tscn` + `tools/desenhar_mapa.py` desenham o mapa de cada camada e marcam as câmaras vazias. As capturas de tela ficam em `tests/screenshot_*.tscn`.
