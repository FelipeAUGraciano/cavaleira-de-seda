# Cavaleira de Seda — v0.8

Fangame top-down de sobrevivência e estratégia: uma aranha recém-nascida precisa sobreviver numa caverna onde tudo é maior que ela. O **Ato 1 é jogável do começo ao fim** (Berçário e Galerias Úmidas, até a Centopeia-blindada), no modo hardcore: morte permanente por ato, visão curta e quedas para o andar de baixo.

O que mudou em cada versão está em [`CHANGELOG.md`](CHANGELOG.md). O design completo fica no GDD (documento do projeto).

## O que tem hoje

- **Protagonista:** Filhote de Seda que vira Cavaleira de Seda no nível 8 (muda no casulo). Combo com cone no chão, mordida com bote e veneno, esquiva, fio lançado (Q) que puxa bichos ou te puxa até a parede, fio-guia e teia de captura no Modo Tecelagem, runa que ilumina (e te denuncia).
- **Menu do casulo:** teia de 17 habilidades (1 ponto por nível), evolução e despensa (presas embrulhadas não apodrecem). Descansar salva, cura e faz a muda; não dá para dormir com um bicho te caçando perto.
- **Criaturas:** irmãs, larvas, sapos, morcegos, lagartos, a Mãe e a Centopeia-blindada, com fome, sono, medo e golpes avisados por marcas no chão. Teia por tamanho (pequeno fica preso, médio rasga, grande arrebenta).
- **Mundo:** Galerias em dois andares geradas como caverna orgânica, ciclo de luz de 5 minutos, território, pilares variados, ganchos de parede nos abismos.
- **Menus:** 3 espaços de save, Opções (som, tela, brilho, controles remapeáveis no teclado e no controle).
- **Arte:** modelos 3D da protagonista, de todas as criaturas, da Mãe e dos props; o chão e as paredes são gerados em código.

## Como abrir

1. Instale o **Godot 4.7.x** (versão padrão, não a .NET): https://godotengine.org/download
2. Abra o Godot → **Importar** → escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar. Abre o menu inicial: **Novo jogo** escolhe um dos 3 espaços e começa do Berçário, **Continuar** volta ao último casulo, **Carregar** escolhe outro espaço.

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
| Comer / abrir o menu do casulo | E | B |
| Tecer casulo | C | Direcional para baixo |
| Apagar / acender runa | F | Clique no analógico direito |
| Mapa | M | Direcional para cima |
| Ajuda na tela | H | Back |
| Pausa, Opções e menu | Esc | Start |
| Testes: +1 nível / novo jogo direto | F1 / F8 | — |

Todas as teclas podem ser trocadas em **Opções → Controles**. No **Modo Tecelagem** o tempo cai para 25%. Clique em um pilar e depois em outro (até 12 m) para esticar um **fio-guia**. Andar no fio é 1,5× mais rápido, silencioso, e é o único jeito de cruzar o abismo. O botão direito arma uma **teia de captura** (a partir do nível 3).

## O que tem em cada camada

**Berçário (início):** B1 eclosão (coma uma irmã menor) → B2 corredor (uma irmã faminta te caça; ou vá pela trilha baixa, mais escura) → B3 salão das teias (primeiro fio-guia sobre o abismo; a fresta ao sul leva ao cristal secreto de B4) → B5 despensa (apague a runa com F e passe pela pata da Mãe) → B6 fuga (corra! teça o fio no segundo abismo) → túnel para as Galerias.

**Galerias Úmidas (dois andares):** caverna orgânica com bolsões de abismo; cair de cima leva ao andar de baixo (P1–P6), de onde se volta pelas passagens. As câmaras principais: G1 entrada → G2 poça (Sapo-de-rocha) ou G3 túnel dos morcegos → G4 Grande Gruta (casulo e território). Do G4: G5 jardim (Lagarto-lanterna) e G12 ninho (três lagartos, cristal de energia) ao sul, G7 lago (cristal na ilha) a sudoeste, G6 ponte quebrada (três fendas) a leste → G8 Galeria do eco (aventureiros ao longe; fresta secreta para G10) → G9 Acampamento (tochas, diário) → G13 Antecâmara (último casulo) → G14 Covil da Centopeia → G15 Borda da Fenda (queda para o Abismo). G11 Poças ácidas liga o jardim à Antecâmara (Resistência a Ácido 3). A parede de cristal da G16 abre no Ato 4.

**Câmara de teste:** a câmara cinza da v0.1 continua no projeto (`world/layers/test_chamber.tscn`) para o teste automático dos sistemas.

Sistemas: 4 recursos que aparecem no corpo da aranha (placas = PV, runa = Energia, cachecol = Seda, abdômen = Saciedade), fome, território, vibração nos fios, casulo com save, veneno, Enredado com crítico ×2, furtividade por luz e barulho, e um ecossistema básico (o sapo caça e come larvas).

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
  creatures/   creature.gd (base), larva.gd, frog.gd, bat.gd, lizard.gd, sister.gd, corpse.gd
  npc/         adventurer.gd (aventureiros vistos de longe)
systems/
  ai/          needs.gd (fome, sono, medo, inquietação), brain.gd (escolhe a atividade),
               behavior.gd (base) e behaviors.gd (vagar, dormir, comer, fugir, passear, combate, recuar, brigar)
  world/       nav_grid.gd (caminhos em 3 grades: pequeno, grande, voo), cave_clock.gd (Brilho/Caça), track.gd (rastros)
  web/         âncoras, fio-guia, teia de captura, casulo
  ecosystem/   repovoamento da câmara
  fx.gd        formas cinza e efeitos simples
world/         title.tscn (menu inicial), layer_base.gd (base de toda camada)
  layers/      bercario.tscn, galerias.tscn, abismo.tscn (provisório), test_chamber.tscn
systems/level/ cave_builder.gd (cavernas orgânicas), map_system.gd, pickup.gd, fire.gd (tochas), note.gd (coisas para ler)
systems/spider_legs.gd   as 8 patas com IK
systems/models.gd        troca formas cinza por modelos .glb (assets/models/)
assets/models/ modelos 3D, um por pasta (veja "Modelos 3D" abaixo)
tools/         preparar_modelo.sh (reduz malha e texturas dos modelos da IA)
actors/bosses/ mother_leg.gd (pata da despensa), mother_chase.gd (fuga), centipede.gd (Centopeia-blindada)
ui/            hud.gd, cocoon_menu.gd (menu do casulo), options_menu.gd, skill_icons.gd, vision_overlay.gd
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

## Dublagem

As falas do monólogo e os nomes de arquivo estão em [`docs/falas.md`](docs/falas.md). Grave, salve como `audio/voice/<id>.ogg` e o jogo toca sozinho.

## Modelos 3D

O jogo procura `assets/models/<nome>/<nome>_vNN.glb` e usa a versão mais alta. Se o arquivo não existe, a forma cinza continua. Os nomes estão na aba "Modelos 3D" do GDD.

As IAs geram modelos pesados demais (o Hunyuan entrega ~1,5 milhão de triângulos e texturas 4K, uns 80 MB). Antes de usar, rode:

```
tools/preparar_modelo.sh ~/Downloads/modelo.glb sapo 20000
```

Ele reduz a malha para ~20 mil triângulos e as texturas para 1024 px (uns 2,5 MB) e salva como a próxima versão. Ajustes finos (girar, subir, escalar, "já veio com patas") ficam na tabela `TUNING` de `systems/models.gd`.

## Testes automáticos

```
godot --headless --path . res://tests/smoke_test.tscn       # sistemas centrais
godot --headless --path . res://tests/bercario_test.tscn    # Berçário de ponta a ponta
godot --headless --path . res://tests/galerias_test.tscn    # Galerias (os dois andares, fios, ganchos, paredes)
godot --headless --path . res://tests/covil_test.tscn       # Antecâmara, Covil e a Centopeia
godot --headless --path . res://tests/vida_test.tscn        # mundo vivo e desempenho
godot --headless --path . res://tests/dificuldade_test.tscn # Filhote, evolução, predadores que te caçam
godot --headless --path . res://tests/hardcore_test.tscn    # golpes, fúria, perseguição, visão, quedas, morte por ato
godot --headless --path . res://tests/golpes_test.tscn      # golpes e fio (Q) da jogadora
godot --headless --path . res://tests/casulo_test.tscn      # habilidades, despensa e menu do casulo
godot --headless --path . res://tests/menu_test.tscn        # menu inicial, espaços de save, Opções e pausa
godot --headless --path . res://tests/models_test.tscn      # modelos 3D e encaixes
tools/checar_avisos.sh godot                                # avisos do GDScript (todos os scripts)
```

Os testes jogam sozinhos: fio sobre o abismo, queda, combate, comer, casulo, save, morte por ato, menus e os chefes. As capturas de tela ficam em `tests/screenshot_*.tscn`.
