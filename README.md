# Cavaleira de Seda — protótipo (v0.8-etapa3b)

Fangame top-down de sobrevivência e estratégia: uma aranha recém-nascida precisa sobreviver numa caverna onde tudo é maior que ela. Este é o **protótipo cinza** (formas simples, sem arte final). Ele existe para responder uma pergunta: *o loop de 10 minutos é divertido?*

## Novidades da v0.8 — a Cavaleira ganhou corpo

- **Modelos da protagonista:** corpo, segmento de pata e lâmina de cristal. As 8 patas saem dos encaixes que vieram no modelo e usam a peça do segmento (com IK, como antes).
- **Lâminas de cristal:** duas foices na frente do corpo, só depois da muda (o Filhote não tem). Cada golpe do combo mexe uma: 1º a direita varre, 2º a esquerda, 3º as duas descem juntas.
- O cachecol de caixas saiu quando o modelo está presente.

## Novidades da v0.8 — pilares, ganchos e a ponte de fio

- **Pilares de verdade:** cada âncora virou uma estalagmite feita em código, torta e facetada, com pontas menores e cascalho em volta. Altura, grossura, inclinação e formato (simples, gêmeas, monte baixo, agulha com anéis) variam pelo nome do pilar: o mesmo pilar sai sempre igual, mas nenhum é gêmeo do outro. Algumas têm veios de cristal que ajudam a achar no escuro. A colisão continua a mesma (o puzzle não muda).
- **Ganchos de parede:** chifres de rocha saindo da parede, com uma lasca de cristal na ponta. Só aparecem **em pares, um de cada lado dos bolsões de abismo** (10 nas Galerias): um fio entre eles é uma rota de fuga por cima do buraco. Ficam raros de propósito para a rede continuar sendo de pilares.
- **Ponte de fio nova:** dois cabos torcidos nas bordas, um fio no meio, trama em zigue-zague meio torta, um véu de seda bem fino, gotas de orvalho e amarras que sobem em leque até um nó de seda enrolado no pilar. Tudo gerado em código, então **não precisa de modelo** (cada fio tem um comprimento diferente).
- Se um dia chegarem os modelos `estalagmite_a/b/c`, eles substituem a rocha gerada sozinhos.

## Novidades da v0.8 (etapa 3) — Galerias orgânicas em dois andares

- **Caverna orgânica:** o oeste (Entrada, Poça rasa, Túnel dos morcegos, Grande Gruta, Jardim, Ninho dos lagartos) e o leste (Galeria do eco, Acampamento, Antecâmara) agora são uma caverna gerada por **autômato celular**: salões de formato livre que se emendam, nichos, becos sem saída e bolsões de abismo. O mapa encolheu 1/3 (cerca de 150 × 108 m por andar).
- **Câmaras feitas à mão continuam onde a história precisa:** Ponte quebrada, Lago escondido, abismo da Galeria do eco, Fresta de cristal, Poças ácidas, Subida antiga (parede de cristal), Covil da Centopeia e Borda da Fenda. Em volta das travas a caverna gerada não abre atalho.
- **Profundezas (P1–P6):** o andar de baixo é todo orgânico. Qualquer abismo do andar de cima (as fendas da Ponte, o abismo do eco, os bolsões no meio dos salões) leva para lá, bem embaixo de onde você caiu, com 35% da vida a menos. Duas **rampas** (Poça rasa e Antecâmara) ligam os andares. Os poços das Profundezas, o abismo da Subida antiga e a Fenda não têm fundo.
- **Cerca de 60 criaturas**, incluindo cinco **irmãs caçadoras**, irmãs que fugiram do ninho e caçam a Filhote pelo cheiro.
- **Mapa (M) por andar**, com as rampas marcadas.
- A caverna é sempre a mesma (semente fixa em `galerias.gd`: `UPPER_SEED` e `LOWER_SEED`). Para ver outra, troque a semente e rode `tests/preview_organic.tscn`, que gera os PNGs.

## Novidades da v0.8 (etapa 2) — escuro e quedas

- **Visão curta:** a caverna ficou quase preta. Você enxerga só um círculo pequeno em volta da aranha (3,5 m na Filhote, 5,5 m na Cavaleira) e o que tem luz: fungos, a isca do lagarto, fogo, olhos e os avisos de golpe. Na fase da Caça os fungos apagam e sobra quase só a sua luz. A runa acesa ilumina mais, mas denuncia você.
- **Quedas:** cair num abismo agora tem consequência. Abismo com andar de baixo: tira 35% da vida e você acorda lá embaixo, tendo que achar o caminho de volta. Abismo sem fundo: morte (e o ato recomeça). O lago continua só te devolvendo para a margem. Os andares de baixo chegam com o mapa novo (etapa 3); até lá, as fendas atuais são sem fundo.

## Novidades da v0.8 (etapa 1) — hardcore: combate e IA

- **Golpes estilo Monster Hunter:** cada bicho tem 3 ou 4 golpes. Antes de cada um aparece uma **marca laranja no chão** com a área, que enche até o golpe sair. O golpe vai até o fim mesmo que você saia andando (só a esquiva ou estar fora da marca salva), mira onde você **vai estar** e gira atrás de você. Depois do golpe o bicho fica parado um instante: é a hora de bater.
  - **Sapo:** bote, língua (puxa você e emenda um bote), salto esmagador e **giro de língua** contra quem fica rodando do lado dele. Furioso: cuspe ácido que deixa poça.
  - **Lagarto-lanterna:** mordida, investida em linha, chicote de cauda (quem fica do lado/atrás). Furioso: clarão da isca que te deixa lenta.
  - **Irmã faminta:** mordida, pulo, teia cuspida (deixa lenta). Furiosa: frenesi de mordidas em sequência.
  - **Morcegos:** até 3 mergulham juntos, miram à frente de quem corre e **gritam** — o grito te deixa lenta e chama todo predador por perto.
- **Fúria:** abaixo da metade da vida o bicho fica furioso: avisa menos, bate mais forte e ganha um golpe novo.
- **Perseguição que não desiste:** quem te caça segue seu barulho e seu cheiro. Só despista quem **some de vista e fica quieta** (parada, runa apagada). Aí ele ainda vasculha a área uns segundos antes de desistir.
- **Filhote frágil:** dois golpes de qualquer predador matam. A vida quase não regenera sozinha.
- **Teia por tamanho:** bicho P fica preso; M (sapo, lagarto) fica preso uns 2 s e **rasga a teia**; G (Centopeia) arrebenta na hora. Bicho andando que esbarra num fio no chão também enrosca (e o M arrebenta o fio).
- **Morte permanente por ato:** morreu, o ato recomeça do início com o nível, a forma e os itens de quando você entrou nele. Fica só o conhecimento: o mapa descoberto e as falas. O casulo continua salvando para você sair e voltar (Continuar).

## Novidades da v0.7 — mais difícil e você vira a presa

Resposta ao primeiro teste ("monótono e fácil, ninguém me caça, já começo forte, o tutorial acaba do nada, as patas estão ruins").

- **Você começa como Filhote de Seda:** 70% do tamanho, 50 PV, garra fraca (um sapo aguenta vários golpes). Para matar algo maior, use teia de captura, veneno e armadilhas de fio. Bicho maior que você te enxerga como comida.
- **Evolução:** no **nível 8**, descanse num casulo e ela faz a muda para **Cavaleira de Seda**: lâminas de cristal, 110 PV de base, golpes mais fortes e o nível volta a 1. Os cristais que você já comeu continuam valendo. Depois da muda, só bicho faminto de verdade arrisca te caçar.
- **Os predadores te caçam:** com fome, sapos, morcegos (só a Filhote), irmãs e a Centopeia seguem seu cheiro mesmo sem te ver. A estimativa deles melhora quanto mais perto estão. Quando alguém começa a te seguir, aparece uma **seta vermelha na borda da tela** apontando para ele (mais forte quanto mais perto).
- **Fim do prólogo:** sair do Berçário agora tem epílogo, um cartão "Fim do prólogo" e fala da protagonista antes de escurecer. Cada camada abre com escurecimento e um título (nome + ato).
- **Patas novas:** andar de aranha de verdade (dois grupos de quatro patas alternados). As patas pisam no chão, miram onde o corpo vai estar e não esticam mais para trás nem sobem nas paredes.

- **Menu inicial:** Continuar (mostra onde e em que nível está o save), Novo jogo (pede confirmação antes de apagar), Controles e Sair. **Esc** no jogo abre a pausa com Voltar ao jogo, mostrar/esconder controles, Menu inicial e Sair.

**Saves antigos:** no menu inicial escolha **Novo jogo**. O balanço mudou e o jogo começa na forma Filhote.

## Novidades da v0.6 — mundo vivo

A caverna agora vive sozinha, como os mapas de Monster Hunter: cada criatura tem necessidades, rotina e toca, e circula pelo mapa mesmo longe de você.

- **Ciclo da caverna (5 min):** os fungos acendem e apagam. No **Brilho**, larvas saem para pastar musgo e os caçadores dormem. Na **Caça**, sapos, lagarto, morcegos e a Centopeia acordam. A fase aparece embaixo do minimapa.
- **Necessidades:** fome, sono, medo e vontade de passear. Um "cérebro" escolhe a atividade de maior nota: dormir na toca, comer, fugir, passear para outra câmara, brigar ou lutar com você.
- **A Centopeia patrulha o leste** (G8, G9, G11, G13, G14): caça sapos e larvas, deixa rastro de arrasto, arrebenta fios por onde passa, dorme no covil e, ferida, **foge mancando para o covil** para se curar. O estrago fica: morrer não cura a Centopeia. Quando ela chega na câmara onde você está, o chão treme.
- **Morcegos em bando:** dormem pendurados no Brilho e saem juntos na Caça para caçar larvas em outras câmaras. Fios esticados no caminho deles viram armadilha.
- **Hierarquia e território:** bicho menor foge do maior (o sapo foge da Centopeia). O Lagarto-lanterna expulsa sapos do jardim. Quem é atacado por outro bicho revida. Dormindo, o lagarto quase apaga a isca: é a hora de passar.
- **Rastreio pela teia:** bichos dentro do seu território aparecem como pontos no minimapa (cor pelo tamanho). A **Leitura** (Alt) mostra o que a criatura está fazendo e como ela parece (com fome, com sono, ferida).
- **Mais rápido:** as criaturas andam presas à grade de navegação, sem testar colisão contra a malha da caverna (a física caiu de ~15 ms para ~3 ms por quadro com 20+ criaturas). Longe de você, elas pensam 1× por segundo em vez de 4×.

## Novidades da v0.5 — o Ato 1 inteiro

- **Galerias completas (G1–G15):** depois da Ponte quebrada vêm a Galeria do eco, o Acampamento, a Fresta de cristal (secreta, só para quem é pequena), a Antecâmara, o Covil da Centopeia e a Borda da Fenda. O Ninho dos lagartos (ao sul do jardim) e as Poças ácidas (atalho do jardim até a Antecâmara) também abriram.
- **Chefe: Centopeia-blindada.** Corpo de 12 segmentos que segue a cabeça. Ela sente a **vibração** do chão: correr vibra mais, ficar parada ou andar **sobre um fio** te esconde. Morde de perto e **investe** em linha reta. A carapaça segura 90% do dano e o veneno não entra. Para abrir a carapaça, faça a Centopeia investir **através de um fio esticado**: ela se enrosca por 4,5 s e leva dano cheio (e o crítico ×2). Na metade da vida, ela se enfurece. A arena fecha durante a luta; se você morrer, ela volta a dormir com a vida cheia.
- **Pele de Cristal:** comer a carapaça dá +20 PV máximo e -20% de dano recebido.
- **Fim do Ato 1:** na Borda da Fenda o chão cede e a Cavaleira cai no Abismo (por enquanto, só a sala onde ela acorda).
- **Aventureiros vistos de longe:** na Galeria do eco, três humanos com tochas passam do outro lado do abismo, e a câmera vira para mostrar.
- **Fogo queima teia:** as tochas do acampamento queimam fios e teias de captura por perto.
- **Anotações e cristais (E):** o diário da expedição no acampamento e uma visão estranha na Fresta de cristal.
- **Resistência a Ácido:** cada Sapo-de-rocha comido dá +1. Com 3, as Poças ácidas não queimam.
- **Caverna gerada 4× mais rápido** (as Galerias inteiras montam em menos de 2 s).

## Novidades da v0.4

- **Galerias Úmidas, primeira parte (G1–G7):** a camada depois do Berçário, com a Grande Gruta como centro. Dois caminhos levam até ela (a poça do sapo ou o túnel dos morcegos), o Jardim de musgo fica ao sul, o Lago escondido a sudoeste e a Ponte quebrada a leste. A Subida antiga (G16) já aparece atrás de uma parede de cristal.
- **Morcego-eco:** bando que voa e caça pelo som. Ouve quem se mexe; ficar parada faz você sumir. Mergulha para morder (só dá para acertar durante o mergulho). Um fio esticado no caminho ou um fio lançado com **Q** derruba o morcego.
- **Lagarto-lanterna:** a isca de luz atrai larvas, que ele come. Defende o território: pisca a isca como aviso e depois morde ou dá uma investida. A luz revela você de perto mesmo com a runa apagada. Comer o lagarto dá +10 de Energia máxima (uma vez).
- **Primeiro território:** na Grande Gruta, um casulo e três fios ligados a ele formam o território.
- **Lago escondido:** só uma corrente de fios (margem → pedrinha → ilha) leva ao cristal de energia.
- **Modelos 3D:** o jogo troca as formas cinza pelo modelo assim que o arquivo existe em `assets/models/`. Já entraram a **irmã-aranha** e o **Sapo-de-rocha**.

## Novidades da v0.3

- **Cavernas orgânicas:** o Berçário deixou de ser feito de blocos. Câmaras viram bolhas e elipses de borda irregular, túneis são curvos, as paredes têm altura variável (altas ao norte, baixas ao sul para não tapar a câmera), os abismos têm penhascos e há estalagmites e pedras espalhadas. Tudo gerado por `systems/level/cave_builder.gd`.
- **Trajeto menos reto:** corredor curvo, a fenda do Salão das teias corta o salão na diagonal, um túnel de fuga sinuoso, uma **trilha baixa** alternativa entre B1 e B3 e um nicho escondido no corredor.
- **A Mãe segue o túnel** curvo na fuga, em vez de andar em linha reta.
- **Mapa com a forma real** das câmaras (e abismos mais escuros).

## Novidades da v0.2

- **Berçário jogável (B1–B6):** as 6 câmaras do mapa do GDD em formas cinza — irmãs-aranha, o primeiro fio sobre um abismo, a fresta secreta com o cristal, a pata da Mãe (furtividade) e a fuga da Mãe.
- **Patas com IK:** as 8 patas pisam no chão de verdade, dão passos alternados e ficam penduradas sobre o abismo. As irmãs usam o mesmo sistema.
- **Mapa automático:** minimapa no canto e mapa completo na tecla **M**. As câmaras aparecem quando você entra nelas; travas vistas (como a fresta) ficam marcadas.
- **Camadas:** o jogo começa no Berçário e o túnel de saída leva às Galerias (por enquanto, a câmara de teste da v0.1). O save lembra em qual camada você estava.
- **Dicas de tutorial** ao entrar em cada câmara do Berçário e 10 falas novas para dublar.

Documento de design (GDD): https://claude.ai/artifact/1GWcAejdRMa5iN3mmC9C1K

![Folha de conceito](docs/conceito/cavaleira-de-seda.png)

## Como abrir

1. Instale o **Godot 4.7.x** (versão padrão, não a .NET): https://godotengine.org/download
2. Abra o Godot → **Importar** → escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar. Abre o menu inicial: **Novo jogo** começa do Berçário, **Continuar** volta ao último casulo.

## Controles

| Ação | Teclado e mouse | Controle |
| --- | --- | --- |
| Mover | WASD | Analógico esquerdo |
| Mirar | Mouse | Analógico direito |
| Ataque (combo de 3) | Botão esquerdo | X |
| Mordida (veneno) | Botão direito | Y |
| Esquiva / backstep (parada) | Espaço | A |
| Correr | Shift | LB |
| Lançar fio | Q | RB |
| Modo Tecelagem (segurar) | R | LT |
| Leitura de criatura (segurar) | Alt ou Tab | RT |
| Comer / descansar no casulo | E | B |
| Tecer casulo | C | Direcional para baixo |
| Apagar / acender runa | F | Clique no analógico direito |
| Mapa | M | Direcional para cima |
| Ajuda na tela | H | Back |
| Pausa e menu | Esc | Start |
| Testes: +1 nível / novo jogo direto | F1 / F8 | — |

No **Modo Tecelagem** o tempo cai para 25%. Clique em um pilar e depois em outro (até 12 m) para esticar um **fio-guia**. Andar no fio é 1,5× mais rápido, silencioso, e é o único jeito de cruzar o abismo. O botão direito arma uma **teia de captura** (a partir do nível 3).

## O que tem em cada camada

**Berçário (início):** B1 eclosão (coma uma irmã menor) → B2 corredor (uma irmã faminta te caça; ou vá pela trilha baixa, mais escura) → B3 salão das teias (primeiro fio-guia sobre o abismo; a fresta ao sul leva ao cristal secreto de B4) → B5 despensa (apague a runa com F e passe pela pata da Mãe) → B6 fuga (corra! teça o fio no segundo abismo) → túnel para as Galerias.

**Galerias Úmidas (G1–G15):** G1 entrada → G2 poça (Sapo-de-rocha) ou G3 túnel dos morcegos → G4 Grande Gruta (casulo e território). Do G4: G5 jardim (Lagarto-lanterna) e G12 ninho (três lagartos, cristal de energia) ao sul, G7 lago (cristal na ilha) a sudoeste, G6 ponte quebrada (três fendas) a leste → G8 Galeria do eco (aventureiros ao longe; fresta secreta para G10) → G9 Acampamento (tochas, diário) → G13 Antecâmara (último casulo) → G14 Covil da Centopeia → G15 Borda da Fenda (queda para o Abismo). G11 Poças ácidas liga o jardim à Antecâmara (Resistência a Ácido 3). A parede de cristal da G16 abre no Ato 4.

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
autoload/      EventBus (sinais), GameState (controles, save, falas), WebNetwork (teias e território), Voice (dublagem),
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
world/         main.tscn (abre o save ou o Berçário), layer_base.gd (base de toda camada)
  layers/      bercario.tscn, galerias.tscn, abismo.tscn (provisório), test_chamber.tscn
systems/level/ cave_builder.gd (cavernas orgânicas), map_system.gd, pickup.gd, fire.gd (tochas), note.gd (coisas para ler)
systems/spider_legs.gd   as 8 patas com IK
systems/models.gd        troca formas cinza por modelos .glb (assets/models/)
assets/models/ modelos 3D, um por pasta (veja "Modelos 3D" abaixo)
tools/         preparar_modelo.sh (reduz malha e texturas dos modelos da IA)
actors/bosses/ mother_leg.gd (pata da despensa), mother_chase.gd (fuga), centipede.gd (Centopeia-blindada)
ui/            hud.gd
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
godot --headless --path . res://tests/smoke_test.tscn      # sistemas centrais (20 verificações)
godot --headless --path . res://tests/bercario_test.tscn   # Berçário de ponta a ponta (20 verificações)
godot --headless --path . res://tests/galerias_test.tscn   # Galerias G1–G7 (38 verificações)
godot --headless --path . res://tests/covil_test.tscn      # G8–G15 e a Centopeia (34 verificações)
godot --headless --path . res://tests/models_test.tscn     # troca de modelos (12 verificações)
godot --headless --path . res://tests/vida_test.tscn       # mundo vivo: relógio, sono, pasto, bando, medo, brigas e desempenho
godot --headless --path . res://tests/dificuldade_test.tscn  # Filhote, evolução, predadores que te caçam, transição e patas (18 verificações)
godot --headless --path . res://tests/menu_test.tscn       # menu inicial, pausa, continuar e novo jogo (15 verificações)
godot --headless --path . res://tests/hardcore_test.tscn   # golpes, fúria, perseguição, teia por tamanho, visão, quedas e morte permanente (25 verificações)
```

Os testes jogam sozinhos: fio sobre o abismo, queda, combate, comer, casulo, save, sapo, teia de captura, paredes, mapa, irmãs, fresta, cristal, pata da Mãe e a fuga.
