# Histórico de versões

O que entrou em cada versão, da mais nova para a mais antiga. O estado atual do jogo está no README.

## Ato 2 começa: a queda da Fenda e o Abismo A1–A4 (17/11)

- **A queda:** depois da Centopeia, na Borda da Fenda (G15), o chão racha (faixas pretas, tremor crescente), a borda se desfaz e ela escorrega para dentro. Dentro da Fenda a caverna some da tela: só ela, as pedras caindo e riscos de vento passando, com a câmera descendo junto. Ela atira um fio para cima, ele pega e arrebenta; atira outro, arrebenta de novo. Escurece, vem a tela de carregamento com "Fim do Ato 1".
- **A chegada:** ela despenca do alto no Fundo da queda, bate no chão levantando poeira e fica caída um instante. Chega **ferida (30% da vida) e sem seda**. Depois aparece "Abismo · Ato 2" no estilo Elden Ring e o controle volta.
- **Abismo, primeiro trecho (A1–A4), quase breu:** ambiente quase preto; só a runa, poucos fungos e cristais frios mostram alguma coisa.
  - **A1 Fundo da queda:** ponto seguro, 4 pilares, uma presa esquecida.
  - **A2 Ossário:** carcaças velhas e uma costela gigante de alguma coisa do tamanho do Colosso. **Besouros carniceiros (novo):** bichos pequenos em bandos (4 e 3) que roem as carcaças e fogem de você. São a primeira comida fácil (devolvem seda); descansar repõe o bando.
  - **A3 Trilha do Colosso:** corredor largo e comprido. Um **dragão da terra** (o Colosso, provisório em formas simples até ter modelo) vai e volta pela trilha, parando nas pontas. Ele **sente o chão**: correr perto, ou andar num fio a até 13 m dele, chama atenção; ele enxerga só de perto (menos ainda com a runa apagada). Parada de lado no escuro, ele passa; bem no caminho das patas, ele pisa. Alerta, os olhos ficam vermelhos, ele ruge e avança pela trilha; se te alcança, **mata na hora**. Nas **rachaduras** das paredes (5 ao longo da trilha) ele não entra: fareja, desiste e volta para a ronda. Pisa e arrebenta qualquer fio no caminho. Cada passo treme a câmera, mais forte quanto mais perto.
  - **A4 Fenda do refúgio:** uma rachadura estreita na parede da trilha que dá numa câmara pequena: a **toca do Abismo** (casulo central, uma porta só, despensa). Fica a 18 m do caminho do Colosso.
  - Passagens para o Lago negro (A5) e a Cortina viva (A8) estão atrás de **desabamentos**: chegam na próxima parte.
- Correções: avisos antigos do GDScript (divisão inteira na toca, variáveis repetidas nas Galerias, sombra de função no HUD) zerados.
- Teste novo: `abismo_test`. Captura: `tests/screenshot_abismo.tscn`.

## Fim do prólogo com cena, tela de carregamento e chegada à la Elden Ring (17/11)

- **Fuga até o fim:** ao chegar na saída do Berçário ela não para mais. Faixas pretas entram, a interface some, ela dispara túnel adentro sozinha, a câmera olha para trás e a Mãe bate com o corpo na entrada. Um clarão vermelho, tremor de câmera, pedras despencando e poeira fecham o túnel atrás dela. O túnel agora segue escuro até um brilho verde lá no fundo (o musgo das Galerias).
- **Tela de carregamento:** fundo preto, uma teia sendo tecida no meio (ela é a barra de progresso; uma aranhinha vai na ponta do fio), "Fim do prólogo" em cima com a frase de antes, a porcentagem e dicas que trocam a cada 5 s. A camada carrega em segundo plano e a tela fica pelo menos 3 s. Vale para toda troca de camada.
- **Chegada:** nas Galerias ela entra correndo pela borda da câmara, a câmera chega perto e o nome da área aparece em letras serifadas douradas numa faixa escura, com um fio fino e um losango no meio, como em Elden Ring. Ela para, o nome some devagar e o controle volta. O Berçário também mostra o nome assim ao começar.
- Fonte nova: Cinzel (OFL), em `ui/fonts`.
- Teste novo: `fuga_test`. Captura: `tests/screenshot_fuga.tscn`.

## Mais difícil: menos status, seda contada, teias com limite e seta de vibração (17/11)

- **Status base menores:** Filhote 40 PV / 60 Energia / 40 Seda (era 50/80/80), +4/+3/+2 por nível (era +5/+4/+4). Cavaleira 90 PV / 90 Energia / 60 Seda (era 110/110/110), +8/+4/+3 por nível.
- **Seda não regenera sozinha:** acabou o +1 por segundo com a barriga cheia. Seda volta comendo (presa, embrulho, despensa) ou descansando na toca. Os fios-alarme passaram a custar 30 (antes 50, mais que a Seda máxima do começo).
- **Seta de vibração:** quando algo toca sua teia, aparece uma seta em volta da aranha apontando de onde veio, com a distância, como o indicador de dano dos jogos de tiro. Branca para bicho pequeno, laranja para médio, vermelha para grande e ciano para a toca; some em ~2,5 s; o mesmo bicho de novo renova a seta em vez de empilhar.
- **Limite de peso nas teias:** cada fio e cada teia de captura aguentam 3 de peso (presa pequena 1, média 2, grande arrebenta na hora). No fio, a 4ª presa pequena arrebenta e solta as outras. A teia de captura segura 3 presas pequenas no total; quem passar do limite rasga a teia e solta todo mundo (antes ela pegava 2 bichos de qualquer tamanho).
- Testes novos em `novos_test`; captura `tests/screenshot_vibracao.tscn`.

## A toca com cara de toca (15/11)

- **Interior no estilo da casa da Kumoko:** chão forrado de seda trançada (raios e anéis com véu), paredes cobertas de teia (postes, fios que cedem, zigue-zague, fios soltos e véu como lençol), teias redondas encostadas na pedra, fios em leque do chão até o alto da parede e fios atravessando por cima. Seda branca com alguns fios no ciano do território e gotas de orvalho.
- **A teia cresce:** tomar a toca começa com um tapete pequeno e a rede do casulo; cada porta tecida, cada descanso e cada embrulho guardado fazem crescer, em 5 estágios, até a toca ficar toda forrada. Só visual.
- **Antes de tomar:** a G22 é um ninho abandonado, com teia velha, cinza e rasgada nas paredes e o ninho no meio.
- **Casulo na rede:** o casulo central fica suspenso numa rede de seda presa nas paredes.
- **Despensa à vista:** cada embrulho guardado aparece pendurado na parede de teia; o saque tira um da parede.
- **Portas como as pontes:** cortina trançada, uma ponte de teia em pé (cabos torcidos, trama em zigue-zague, fio do meio, véu, orvalho e amarras até a rocha). Rasgada, sobra só o pé da cortina, fiapos pendurados e restos no chão; balança quando apanha.

## Toca e despensa (15/11)

- **Toca = câmara inteira:** nas Galerias, a **G22 Fosso escuro** virou uma câmara redonda fechada por rocha, com 4 entradas estreitas (~3 m). No meio tem um ninho velho: teça o **casulo central** ali (C, 30 de Seda) e a câmara vira sua toca. No Berçário não tem toca.
- **Só a toca salva e cura.** Acabou o casulo em qualquer lugar (os da G4 e G13 saíram). Antes de ter toca, o jogo **salva sozinho, sem curar**, ao chegar na camada e nos pontos seguros. A morte volta para a toca (ou para o último ponto seguro). O território agora nasce da toca e dos fios ligados a ela.
- **Portas de teia:** C perto de cada entrada tece uma porta (15 de Seda). Você atravessa; os bichos não (nem a navegação deles passa).
- **Saque:** com você longe, um bicho com fome sente o cheiro da despensa, vem até a entrada mais perto, rasga a porta (formigas rasgam o dobro), entra, come o embrulho mais gostoso e vai embora. Descansar remenda portas danificadas; rasgada precisa ser tecida de novo (15). O menu mostra o que aconteceu.
- **Fios-alarme** (50 de Seda, no menu da toca): avisam onde você estiver quando algo ataca uma porta ou entra. Sem eles, você só sabe se estiver perto.
- **Despensa na toca** (10 embrulhos, não estragam). **Bolsa de viagem com 2 embrulhos**; **G** come um em qualquer lugar (leva 1,2 s; levar dano interrompe).
- **Presa pequena** (larva, formiga, morcego, irmã): C embrulha onde você estiver e vai para a bolsa (10 de Seda). **Presa grande** (sapo, lagarto, cobra): C prende no fio e você **arrasta** até a toca (anda a 62% e faz mais barulho); ao entrar na toca, vai para a despensa.
- Menu da toca: aba "Toca e despensa" com despensa (comer / levar), bolsa (guardar / comer), portas, últimos acontecimentos, embrulhar presas por perto e fios-alarme.
- Correção: formiga da fila não trava mais quando a da frente morre no meio do passo.
- Teste novo: `toca_test`. Captura: `tests/screenshot_toca.tscn`.

## Câmaras cheias: bichos novos e coletáveis (15/11)

- **Formiga-de-seda (nova):** sai do formigueiro em fila, come carniça e **rói os seus fios-guia** pela ponta do pilar. Sozinha é fraca (14 PV, mordida de 6), mas uma que apanha ou te sente chama as vizinhas e o bando cerca; tem um jato de ácido curto. O formigueiro repõe as mortas devagar, só com você longe. Formigueiros na G21 (andam por G21/G9/G8) e no P2 (P2/P5/P3).
- **Cobra-das-frestas (nova):** mora num buraco na parede e não sai dele. Escondida, só os olhos brilham. Sente quem **anda** perto (parada, ou devagar com a runa apagada, você passa; fio esticado vibra muito). Dá um bote longo em linha com marca no chão, fica exposta uns segundos (hora de bater) e volta. O bote arrebenta fio-guia no caminho. Na G20, G22, G16, P1, P5 e P6. Morta, não volta.
- **Coletáveis novos:** 12 **fragmentos de runa** (a cada 4, +1 ponto de habilidade), 3 **cristais de seda** (+10 Seda máxima) e 6 **presas esquecidas** (vão para a despensa). Todos ficam salvos depois de pegos.
- **Bichos antigos** nas câmaras vazias: larvas em 10 câmaras, 4 sapos (G19, P3, P1), lagartos no Lago (G7) e no P5, um bando de morcegos na Galeria do eco, irmãs caçadoras na G19 e no P5. Fungos de luz nos salões escuros das Profundezas.
- Uma anotação nova na Subida antiga (G16).
- Teste novo: `novos_test`. Captura: `tests/screenshot_bichos_novos.tscn`.

## Mira travada e ligações novas no mapa (15/11)

- **Mira travada:** todo golpe de inimigo mira **uma vez**, onde você está quando o golpe começa, vira para lá e trava. Durante o aviso ele não gira mais atrás de você (a língua do sapo não te acompanha). Vale para sapo, lagarto, irmãs, morcego (o mergulho vai para o ponto mirado, sem perseguir) e Centopeia (investida e mordida; a mordida só pega quem está na frente da cabeça). Os golpes também não preveem mais para onde você vai: miram onde você está.
- **22 ligações novas** nas Galerias, nos lugares circulados pelo criador: 11 no andar de cima (G1↔G3, G18↔G2, G18↔G4, duas G4↔G5, G5↔G7, G22↔G7, dentro da G20, da G9 e da G21, e G21↔G15) e 11 nas Profundezas (P1, P1↔P4, P2↔P5, duas P2↔P3, P3, P3↔P6, P6 e duas no P5).

## Morte volta ao casulo, sem pedras 3D (15/11)

- **Morte:** a tela escurece e você acorda no último casulo em que descansou. O andar **não recomeça**: bichos mortos continuam mortos, fios e casulos ficam, nível e habilidades ficam. Perde metade da seda. Antes de descansar em algum casulo da camada, volta para o último ponto seguro (entrada ou câmara de passagem). Quem estava te caçando desiste, para não ficar de plantão no casulo.
- Depois de descansar, passar por uma câmara de passagem não troca mais o lugar de voltar.
- Morte permanente por ato desligada (o código continua lá, em `GameState.permadeath`, caso volte como modo opcional).
- **Sem modelos de pedra:** rochas e estalagmites 3D saíram. Os pilares e os cones das paredes voltaram a ser as rochas feitas em código.
- Caçador que perde o interesse no meio da luta termina o golpe e vai embora (antes podia emendar golpes com o interesse zerado).
- Bicho com medo (de algo maior por perto) não sai te caçando.
- Ferramenta nova: mapa de cada camada com as câmaras vazias marcadas (`tests/analise_mapa` + `tools/desenhar_mapa.py`).

## IA dos caçadores — eles desistem (13/11)

- **Interesse:** sapos, irmãs e morcegos têm um medidor de interesse em você. Ver você enche; sumir de vista, ficar num fio sobre o abismo (onde ele não alcança), se afastar demais de onde a caça começou (26 m) ou correr atrás sem chegar perto esvaziam. Com fome ele insiste mais; de barriga cheia larga rápido.
- **Desistência:** com o interesse zerado ele volta à rotina e fica 14 s ignorando você (a menos que você encoste, a 5 m).
- **Troca de presa:** com pouco interesse, uma larva por perto ganha a disputa e ele vai comer.
- **Revide:** bater num bicho enche o interesse e ele foca em você por uns segundos.
- **Encostar acorda o bicho:** a menos de ~2 m um bicho acordado sente você mesmo de costas e no escuro.
- Lagarto (emboscada) e Centopeia (chefe) continuam como antes.
- Teste novo: `caca_test`.

## Revisão geral (13/11)

- README reorganizado (estado atual) e histórico movido para este arquivo.
- Casulo: não dá para descansar com um bicho te caçando a menos de 14 m (o botão mostra "Perigo por perto"). Antes dava para abrir o menu no meio da luta e curar tudo.
- Investida: se a esquiva for interrompida, a aranha volta a colidir com os bichos (antes podia ficar atravessando tudo).
- Voo do fio (Q): sair do voo por qualquer motivo pousa o corpo e recolhe o fio.
- Olhos de Cristal aumentam a luz da visão na hora (antes só depois de recarregar).
- Lista de controles mostra o custo real do fio-guia (3 com Fio Leve).

## Novidades da v0.8 — golpes e fio da protagonista

- **Golpes como os dos inimigos:** cada golpe do combo desenha o **cone** no chão (azul), que enche até o instante do corte; o Corte em Espiral desenha um anel.
- **Mordida com bote:** a mordida avança. Se há um bicho perto na mira (até 2,6 m), ela pula até encostar nele e crava; sem alvo, dá um passinho. O cone dela é verde (veneno).
- **Sem piscar amarelo:** os inimigos não brilham mais em amarelo ao atacar. O aviso é só a marca no chão (a Centopeia e o Morcego ganharam marcas também).
- **Fio (Q) de verdade:** o fio sai da boca da aranha e voa até o alvo, ondulando. Na parede, ela espera prender, arranca, voa num arquinho e freia; o fio encurta junto e recolhe quando ela chega (não fica mais uma reta parada que ela atravessava). Errou: o fio cai.
- **Puxão melhor:** o bicho puxado sai do chão, vem até a sua frente e fica tonto um instante (dá para morder com crítico).

## Novidades da v0.8 — props e a Mãe em 3D

- **A Mãe:** corpo e pata novos. Na Fuga (B6) ela corre com as 8 patas presas nos encaixes do corpo, dobrando as juntas a cada passo; na Despensa (B5) a pata gigante se arqueia do alto até o chão.
- **Props:** ovo, casulo, presa embrulhada, cristal, pilar de teia, 3 estalagmites, 3 rochas, 2 fungos e a teia de canto. As estalagmites viram os pilares das Galerias (a altura continua variando) e enfeitam as cavernas junto com as rochas.

## Novidades da v0.8 — menu do casulo

Feito a partir do design escolhido pelo criador. **E perto de um casulo** abre o menu (o jogo pausa):

- **Retrato** da Cavaleira à esquerda (arte 2D recortada do design do menu; o Filhote aparece menor).
- **Habilidades:** uma teia com 17 nós. O centro (Fiandeira) já vem aprendido; dá para aprender um nó ligado a outro que você já tem. Cada nível dá **1 Ponto de Habilidade** (saves antigos recebem os pontos dos níveis que já tinham). Ramos:
  - Lâmina (para cima): Garras Afiadas, Corte em Espiral (Cavaleira), Investida.
  - Teia (direita): Fio Leve, Puxão, Teia Venenosa.
  - Runa (esquerda): Runa Oculta, Pulso Espiral, Olhos de Cristal.
  - Corpo (para baixo): Carapaça, Glândula Cheia, Estômago de Ferro.
  - Diagonais: Sangue Frio, Tecelã Veloz, Paladar Caçador, Passos de Seda.
  Todas mudam ações que já existem; nenhuma precisa de tecla nova.
- **Evolução:** a árvore de formas, o progresso até a muda e o que ela muda. Os ramos ficam trancados até o Ato 2.
- **Despensa:** embrulhe as presas mortas por perto (10 de Seda cada, até 8) e coma depois. Embrulhadas não apodrecem.
- **Barra de baixo:** PV, Energia, Seda, Saciedade, nível, XP, pontos e **Descansar (salvar)**. Quando dá para evoluir, o botão vira "Muda e descanso". **Esc** sai sem descansar.
- Mouse, teclado (setas, Enter, 1-2-3 ou Tab troca a aba) e controle (LB/RB trocam a aba).
- Fontes: Cinzel e Alegreya Sans (SIL Open Font License, em `assets/fonts`).

## Novidades da v0.8 — Opções e 3 espaços de save

- **Opções** (menu inicial e pausa), em três abas:
  - **Som:** volume geral, música, efeitos e dublagem.
  - **Tela:** tela cheia, brilho (para telas escuras; a caverna continua escura de propósito) e mostrar ou esconder a lista de controles.
  - **Controles:** troque qualquer tecla do teclado/mouse e qualquer botão do controle. Se a tecla já era de outra ação, as duas trocam de lugar. Esc cancela; há "Restaurar controles padrão". A lista de controles do jogo mostra as teclas novas.
- **3 espaços de save:** Novo jogo pergunta em qual espaço começar (e confirma antes de apagar um cheio); Carregar escolhe qual continuar. O save antigo vira o Espaço 1.
- As opções ficam em `user://opcoes.cfg` e valem para todos os espaços.

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
