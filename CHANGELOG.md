# Histórico de versões

O que entrou em cada versão, da mais nova para a mais antiga. O estado atual do jogo está no README.

## O fim do jogo: o Portão da Superfície, o Guardião e os finais (19/11)

- **Camada nova, o Portão da Superfície (P1–P8), o ato final.** A corda da Capitã agora sobe para cá (antes era "Fim do Ato 4 / próxima versão").
  - **Escadaria antiga (P1):** degraus esculpidos e um mural com a espiral, uma aranha e um dragão lado a lado.
  - **Acampamento grande (P2):** de onde a expedição veio. 9 caçadores (4 no esquadrão do alerta 3), tendas, fogueiras, paliçada, 4 armadilhas de fogo, rações e o diário do acampamento. O alerta da caçada e as armadilhas viraram peças reaproveitáveis (`HuntDirector`, `FireTrap`).
  - **Ninho alto (P4, segredo):** do outro lado de um abismo, por fio. Cristal de pedra-da-lua e um ninho de pássaro: "como eu sei o que é um pássaro?".
  - **Galeria iluminada (P3):** **luz do dia** em fachos. Dentro do facho todo mundo te vê, com ou sem runa, e ela enxerga longe; entre eles, sombra. (A Sombra do Breu não some na luz.)
  - **Câmara do eco final (P5):** a última toca. A caverna ecoa falas de antes.
  - **Ponte do Guardião (P6):** abismo com duas ilhas da ponte caída. Rajadas de vento a cada 7 s (com aviso): no chão empurram para o abismo; no fio, ela se agarra e para.
  - **Arena (P7) e Saída (P8):** seis pilares, o portão de pedra com a espiral e a luz do dia vazando.
- **O Guardião do Portão é o Colosso da Fenda** — o dragão que no Abismo só dava para evitar. 1350 PV, 3 fases, cada uma testando uma coisa:
  1. **Esquiva:** as escamas seguram 75%; a investida (linha no chão) que bate num pilar ou na parede deixa ele atordoado, com as escamas abertas.
  2. **Teia:** ele aprende a frear antes dos pilares. O teto cai (marcas no chão), ele cospe estilhaços de cristal e solta um tremor em volta. Só a **teia de captura** no caminho da investida o enrosca.
  3. **Escuro:** a poeira apaga a arena e ele fica cego (caça pela vibração, como no Abismo). Perdeu você, fareja de costas: golpe por trás entra dobrado.
  - Cada troca de fase tem rugido, música própria (guardiao_1/2/3) e dica. Golpe enorme não pula fase. Fase vencida fica vencida; se você foge da arena, ele volta para o portão e a vida volta ao começo da fase. A câmera abre na luta para caber o dragão inteiro. Dá para comer (Pele de Cristal, Energia).
- **Finais:** ela sai pela boca da caverna e a cena, pintada em 2D, muda pelo ramo: **Lâmina** (o vale ao amanhecer, a vila ao longe), **Teia** (a floresta de manhã e o primeiro fio do mundo de cima), **Runa** (a noite e a espiral como constelação) ou **Rara** (a lua na cor da forma rara). Depois vêm o parágrafo da forma (cada uma das 16 tem o seu), a **pista da reencarnação** ("Quem eu era, antes da caverna?"), os números da jornada, os créditos e "Fim". O espaço de save ganha "★ zerado".
- A arte da Cavaleira recortada sem o fundo (`assets/ui/cavaleira_recorte.png`) para o final.
- Bestiário: área nova e o Guardião (32 criaturas). Sons novos do Portão com prompt no GDD (enquanto não existem, o jogo usa os parecidos).
- Testes: `portao_test` (camada, luz do dia, vento, as 3 fases, fuga da arena, portão, final e volta ao menu). O `cacada_test` agora confere que a corda leva ao Portão.

## Bestiário (19/11)

- **Tela nova (B, ou pela pausa e pelo casulo):** lista das 31 criaturas por área (Berçário, Galerias, Abismo, Rio de Brasa, a caçada) e a ficha de cada uma com retrato, nota da Cavaleira, golpes, sentidos, dica e o que comer dá. Teclado (↑↓ bicho, ←→ área), controle e mouse (clique e rodinha). O jogo pausa enquanto está aberta.
- **Três níveis por bicho:** *vista* (nome, tamanho, onde vive, a nota dela), *derrotada* (golpes com dano e efeito, PV, sentidos, como lidar) e *comida* (saciedade, seda, XP e os bônus da carne). Quem ainda não foi visto é uma sombra "???" com a área. A Mãe, o Colosso e a Cortina viva ("perigos") anotam tudo só de serem vistos e sobrevividos.
- **Ver de verdade:** conta quando o bicho está dentro do alcance da sua visão (ou te caçando por perto). O Mímico fingindo de pilar e quem está dentro da lava não contam.
- **Números de verdade:** PV, golpes, sentidos e comida são copiados do bicho na hora (o que o jogo usa, inclusive a dificuldade).
- **Conhecimento:** fica com o mapa descoberto (sobrevive à morte) e é gravado no save na hora, sem esperar o casulo.
- **Retratos:** cada bicho fotografado em 3D num estúdio (`tools/bestiario/retratos.tscn` gera `assets/ui/bestiario/<id>.png`). Dá para trocar qualquer um por uma arte 2D com o mesmo nome.
- Nova ação **Bestiário** (B / direcional para a direita), remapeável em Opções → Controles. Teste novo: `bestiario_test`.

## A Cavaleira 2D no menu (19/11)

- No menu inicial, a Cavaleira agora é a arte 2D (a mesma do casulo) no lugar do modelo 3D. A caverna 3D continua atrás (teia, fungos, cristais, casulo, pó, câmera girando).
- A borda da arte se desfaz em elipse na caverna; a espiral das costas pulsa em ciano junto com a luz da runa no chão, ela respira (sobe e desce bem pouco) e um brilho atravessa a arte a cada ~7 s.

## A cara do jogo: menu, pausa, opções e HUD (19/11)

- **Menu inicial "caverna viva":** atrás do menu roda uma cena 3D de verdade — a Cavaleira (modelo, patas e lâminas) parada na frente de uma teia grande esticada entre dois pilares, fungos roxos e verdes acesos, cristais, um ninho de ovos e um casulo balançando num fio. A runa das costas pulsa, ela respira e olha em volta, pó boia na luz e a câmera dá a volta devagar. Logo novo em Cinzel ("CAVALEIRA / DE SEDA" com o fio e a espiral da runa), botões à esquerda e entrada saindo do escuro.
- **Estilo de seda** (`ui/silk_ui.gd`): as mesmas cores e fontes do menu do casulo (azul-noite, dourado, ciano da runa; Cinzel nos títulos, Alegreya Sans no texto), molduras finas com nós nos cantos. O botão em foco ganha borda dourada, a espiral girando ao lado e um brilho correndo pelo fio de baixo.
- **Pausa:** a interface do jogo some (antes a lista de controles ficava por baixo e saía da tela); à esquerda o nome do lugar, a sala e a fase da caverna; à direita um cartão com o retrato, forma, nível, XP e as quatro barras.
- **Opções:** painel no estilo novo (abas com a ativa em dourado, deslizadores ciano). O aviso antigo de que "os efeitos ainda não existem" saiu.
- **HUD:** painel de vida com medalhão do nível (o anel ciano em volta é o XP), forma, bolsa e tecelagem; barras em cápsula com ícone (coração, raio, carretel, presa). Condições e situações viram pílulas coloridas em cima do painel (Envenenada, Runa apagada, Sobre fio, Caçada…). Mini-mapa com moldura de seda. A lista de controles tem largura fixa e quebra linha (não sai mais da tela).
- O resumo do save conhece todas as camadas (Rio de Brasa e a caçada) e todas as formas.
- `menu_test` confere a cena 3D do menu e as fontes; `screenshot_menu` agora tira HUD, pausa, opções e menu.

## Os efeitos sonoros (19/11)

- **195 arquivos** em `audio/sfx/` (todos os da aba "Efeitos sonoros (prompts)", feitos em Python pelo criador); o gerador fica em `tools/sfx/`.
- Conferido: nenhum faltando nem sobrando; mono nos efeitos e estéreo nos ambientes; picos abaixo de -1 dBFS; níveis batendo com baixo/médio/alto (passos e cliques ~ -11 dB de pico, golpes ~ -1 dB); loops sem salto na emenda. Quatro sons começam com um fade curto de 20–50 ms de propósito (gêiser borbulhando, descanso, onda da Rainha, teia de captura).
- O barramento Efeitos ganhou um limitador (muitos golpes juntos não estouram).
- `sfx_test` confere também os arquivos de verdade (todas as famílias, variações, loops).

## Efeitos sonoros: o tocador e os prompts (19/11)

- **Aba "Efeitos sonoros (prompts)" no GDD:** 9 prompts (jogadora, ataques, teia, impactos, bichos por família, chefes, caçadores, ambiente, interface), ~140 arquivos contando as variações. Lista dos nomes em `audio/sfx/README.md`.
- **Autoload `Sfx`:** sons em 3D com o ouvido na jogadora (não na câmera lá em cima), variações sorteadas, afinação levemente diferente a cada toque e limite de repetições por som; o que faltar fica em silêncio.
- **Já ligado em:** passinhos (mais fracos com a runa apagada), esquiva, dano, morte, comer, runa, Pulso, muda, descanso, queda, nível; garras e mordida; ataques dos kits (pelo formato da área: linha = corte, círculo = martelada, anel = onda; e sons próprios para chicote, bote, raio, explosão, sombra, aparar, guarda, espelho, cristal), projéteis (dardo, bola de fogo, cuspe) e loops de lança-chamas, campo elétrico e carga das foices; fio lançado, fio-guia, teia de captura, bicho preso, teia rompida, fio queimado, embrulhar; golpe acertando (carne, casca, crítico, chefe com casca), morte e corpo caindo; bichos por família (alerta ao te notar, ataque no começo do golpe, dor); chefes (rugido e pisadas da Mãe, patas e golpe da Centopeia, pisadas e respiração do Colosso, sibilo e bote da Serpente, rugido e onda da Rainha, comando, frasco e giro da Capitã); caçadores (passos de bota que dá para ouvir chegando, espada, flecha, tocha, armadilha de fogo); gêiseres, fogueiras e tochas; ambiente de cada mapa; cliques dos menus, abrir/fechar o casulo, pegar item, ação negada.
- Teste novo: `sfx_test` (com sons de teste em `tests/fixtures/sfx/`).

## As músicas (19/11)

- **32 faixas** em `audio/music/` (todas as da aba "Músicas (prompts)", feitas em Python pelo criador): 6 mapas com camada de tensão, Colosso e alerta da caçada por cima, Fuga da Mãe, Centopeia e Serpente com intro, Rainha com camada de fúria, Capitã com a trompa, Guardião (3 fases, para o Portão), casulo, menu e 4 curtas. O gerador fica em `tools/musica/` (sementes fixas: gera sempre igual).
- Conferido: durações batem com o pedido (base e tensão do mesmo tamanho), volume (~ -18 LUFS nos mapas, ~ -14 nos chefes), picos abaixo de -1,7 dBFS e emendas de loop sem salto.
- O barramento Música ganhou um limitador (base + tensão + camada por cima somadas chegavam a +2,4 dB no Abismo com o Colosso); a camada por cima toca 4 dB abaixo, e começa em fase com a base.
- Testes: o `juice_test` agora confere que as faixas são achadas, em loop, e que a intro do chefe toca antes. O `cacada_test` ficou estável (o caçador do teste precisa ter linha de visão; o batedor tem só o fio do teste no mapa).

## Sensação dos golpes e o tocador de música (19/11)

- **Pausa no impacto:** cada golpe que entra congela o jogo por uns centésimos (mais no crítico, no golpe pesado e no abate); levar um golpe também. Golpes em área e fogo contínuo não emendam uma pausa na outra.
- **Faíscas e poeira:** o golpe solta faíscas na cor do tipo (comum, fogo, veneno, ácido, crítico em amarelo); golpe pesado levanta poeira. Ao levar dano, faíscas vermelhas nela.
- **Recuo:** o bicho amassa e volta quando apanha.
- **Morte:** o bicho tomba de lado, encolhe e some, com faíscas e poeira; o cadáver assenta no lugar em seguida (antes ele só sumia e aparecia a bolinha).
- **Números de dano:** sobem do bicho (brancos; críticos e golpes pesados maiores e coloridos).
- **Opções → Tela:** liga/desliga Números de dano, Pausa no impacto e Tremer a tela.
- **Música (autoload `Music`):** procura os .ogg em `res://audio/music/` com os nomes da aba "Músicas (prompts)" do GDD (lista também em `audio/music/README.md`). Faixa do mapa + camada de tensão sincronizada (sobe quando um bicho te caça a menos de 18 m); chefes trocam a música quando a luta começa (com intro, se houver) e voltam ao mapa quando morrem (com a vitória); Colosso perto e alerta 3 da caçada tocam por cima; casulo aberto troca para a do casulo; curtas na morte, na muda, nos segredos e no Fim do Ato. Sem os arquivos, tudo segue em silêncio, sem erro.
- Teste novo: `juice_test`. Captura: `tests/screenshot_juice.tscn`. O teste dos modelos agora compara o pilar com a altura dele (que muda com o nome do nó).

## Ataques próprios: cada ramo e cada forma final troca o golpe e a mordida (19/11)

- **Ramos** (um kit cada): **Ceifadora** — Foice (dois cortes de 120° e o terceiro em linha de 4 m) e Bote longo (3,5 m, +50%). **Tecelã** — Chicote de seda (linha de 4 m; 3 acertos deixam lento) e Novelo (7 m, gruda). **Arauta** — Faísca (linha de 6 m, 5 de energia) e Lampejo (cone de 4 m que atordoa).
- **Formas finais e raras: dois estilos (A/B)**, escolhidos no casulo (aba Evolução) e trocados quando quiser:
  - **Executora:** A) Frenesi (combo sem fim que acelera a cada acerto seguido) + Degola (bote de 5 m que mata abaixo de 35%). B) Foices gêmeas (segurar carrega um corte em linha de 3 a 6 m que atravessa todos) + Misericórdia (segura o preso no chão golpeando).
  - **Bastiã:** A) Martelo (pancada lenta num círculo à frente: derruba e quebra a casca) + Investida de ombro (6 m empurrando; contra a parede, +25). B) Muralha (guarda de frente que bloqueia e devolve) + Pisão (onda de 4 m que derruba, até quem voa).
  - **Senhora das Teias:** A) Chicote de guerra (5 m; 3 acertos prendem) + Casulo rápido (embrulha o preso na hora). B) Rede viva (novelo que vira teia de captura onde cai, sem pilar) + Puxar a rede (traz todos os presos).
  - **Saltadora:** A) Pêndulo (gira presa a um fio em volta de um ponto) + Bote aéreo (pulo de 5 m por cima de bichos e buracos curtos). B) Ricochete (3 dardos de seda que deixam lento) + Bate e volta.
  - **Vidente:** A) Ponto fraco (golpe preciso: pelo lado marcado no bicho, 3x e atordoa) + Leitura (marca um bicho: golpes nele são críticos, os dele doem metade). B) Antecipação (aparar e devolver 30) + Olhar da runa (os bichos fogem de medo).
  - **Tempestade:** A) Raio (8 m, pula para outro bicho) + Descarga (toda a energia num golpe). B) Campo elétrico (orbe que gira e dá choque) + Trovão nos fios (choque por todos os seus fios).
  - **Seda Ardente:** A) Lança-chamas (sopro contínuo que superaquece) + Brasa (fogo no chão). B) Garras de fogo (enchem a fornalha) + Explosão.
  - **Sombra do Breu:** A) Golpe silencioso (quem não te viu morre) + Passo sombrio (aparece atrás do bicho). B) Sombra viva (clone que atrai os bichos) + Breu (nuvem que apaga tochas e te esconde).
  - **Viúva:** A) Cuspe de veneno (poça) + Picada fatal (6 doses; presa envenenada cura 20%). B) Fios venenosos + Dreno (cura com o veneno dos bichos).
  - **Corrosiva:** A) Cuspe ácido (linha de 6 m com rastro) + Derreter (segurar a mordida). B) Banho ácido (respingo em volta) + Dissolver (come o cadáver de uma vez).
  - **Pedra-da-lua:** A) Lança de luar (estocada de 4 m) + Estouro (gasta o escudo numa onda). B) Golpe espelhado (acertos recarregam o escudo) + Refletir (devolve flechas, cuspes e golpes).
- Todos mostram a área no chão antes de acertar (cone, linha, círculo, anel), com cores do tipo (fogo, veneno, ácido, luar). O HUD mostra calor, frenesi, guarda, campo e espelho.
- Técnico: kits em `actors/player/kits/` (`AttackKit` com movimentos cronometrados, projéteis e áreas no chão; `KitBook` escolhe o kit pela forma e estilo). O estilo vai para o save. Bichos ganharam medo (`scare`) e distração (`distract`); fogueiras e tochas podem ser apagadas (`Fire.snuff`). O veneno passa de 5 doses só pela Picada fatal.
- Teste novo: `kits_test` (45 checagens, um por ataque). Captura: `tests/screenshot_kits.tscn`.

## A última muda: 6 formas de ramo e 5 formas raras (18/11)

- **Quando:** no nível 10 do ramo (Ceifadora, Tecelã ou Arauta), a aba Evolução do casulo abre a última muda. Pelo XP do jogo, isso cai no fim do Rio de Brasa ou no começo do Ato 4. O nível volta a 1; habilidades e pontos ficam. Depois dela não há outra muda.
- **Cada ramo se divide em dois:**
  - **Executora de Seda** (Lâmina · Fúria): combo 22/22/40; execução (golpe em bicho com menos de 25% da vida mata na hora; em chefe, dano dobrado); cada abate cura 8%.
  - **Bastiã de Pedra** (Lâmina · Couraça): 280 PV base; -40% de dano; espinhos (quem te acerta de perto leva 40% de volta); nada te empurra; mais lenta.
  - **Senhora das Teias** (Teia · Rede): 180 de Seda; fio e teia por 40%; a teia de captura segura 6 presas, bicho M fica preso 6 s e bicho grande que arrebenta perde o passo por 2,5 s.
  - **Saltadora do Vento** (Teia · Voo): fio-guia +7 m, 1,9x nos fios; mergulho ao chegar de um fio lançado (Q): 30 de dano e atordoa em volta; esquiva pela metade.
  - **Vidente da Runa** (Runa · Olho): enxerga 10 m; marca os bichos a 18 m através das paredes (vermelho = te notou); esquiva com mais tempo invulnerável.
  - **Sacerdotisa da Tempestade** (Runa · Pulso): 240 de Energia, volta 50% mais rápido; Pulso Espiral a 8,5 m que atordoa e acerta 26.
- **Formas raras (servem para qualquer ramo):**
  - **Seda Ardente** — Resistência a Fogo 5 + Cristal de fogo (R10): imune a calor, brasa e queimadura (a lava não queima); seus fios e teias não pegam fogo (tochas, flechas, frasco, armadilhas, sopro); golpes incendeiam (5 PV/s por 3 s; bichos de fogo não pegam).
  - **Sombra do Breu** — Pérola negra (A5) + Resistência à Podridão 3: parada e de runa apagada, ninguém te vê (só encostando ou ouvindo); emboscada em quem não te notou dá 2,5x; energia volta no escuro.
  - **Viúva de Seda** — Resistência a Veneno 4: golpes e mordida envenenam (2 doses); imune a veneno; a teia de captura envenena.
  - **Corrosiva** — Resistência a Ácido 5: golpes corroem (o alvo leva +40% por 5 s, até chefe de casca); imune a ácido; a teia de captura derrete quem prende (6 PV/s).
  - **Cavaleira de Pedra-da-lua** — Pele de Cristal (comer a Centopeia) + 4 cristais de pedra-da-lua: escudo de 50 que volta 6 s depois do último golpe (HUD: ESCUDO); -20% de dano; a runa ilumina 60% mais longe. É a silhueta da visão da Fresta de cristal (G10).
- **Menu do casulo:** trilha Filhote → Cavaleira → ramo → última muda; as duas formas do ramo à esquerda, as raras à direita (com cadeado e "pronta"); passar o mouse mostra o que a forma faz e o que falta.
- Cada forma nova tem uma marca no corpo (foices, placas, coroa, asas de seda, olhos, halo duplo, chamas, véu, ampulheta, gotas, placas de pedra-da-lua).
- Fogo passa por um lugar só (`WebNetwork.burn_strand` / `burn_trap`): a teia de captura queimada agora some de verdade (antes ficava no chão quando um caçador a queimava).
- Abismo: mais 2 escorpiões (Ossário e Raízes negras), para a Viúva de Seda ter folga. Os cristais de pedra-da-lua agora são contados (e vão para o save).
- Teste novo: `evolucao_test`. Captura: `tests/screenshot_evolucao.tscn`.

## Ato 4: a caçada nas Galerias (18/11)

- **Chegada:** no topo da Chaminé (R14) do Rio de Brasa, tela "Fim do Ato 3" e ela sai no canto do Ninho dos lagartos (G12). As Galerias são as mesmas do Ato 1 (o mapa explorado no Ato 1 já vem desenhado), mas agora uma expedição humana caça a "aranha da runa". Não dá para voltar ao Rio pela Chaminé.
- **Alerta da caçada (0 a 3, no HUD como ●●○):** sobe quando um caçador te vê (+0,8), quando um batedor queima um fio seu (+0,4), quando uma armadilha estoura (+0,5) ou quando um caçador some (+0,6). Depois de 20 s sem te verem, cai 1 nível a cada 25 s. **No 3**, o esquadrão do acampamento (4 caçadores) sai atrás do último lugar onde te viram; volta quando o alerta cai abaixo de 2.
- **Caçadores (13 + a Capitã, G):** enxergam com as tochas (runa acesa te entrega de muito mais longe; apagada, só de perto) e ouvem barulho.
  - **Espadachim:** corte que emenda, estocada e empurrão de escudo. Lanterna no cinto.
  - **Arqueira:** flechas de fogo de longe (12 m): queimam seus fios no caminho e te deixam queimando.
  - **Batedor:** tocha na mão; segue o rastro de seda (vai até o seu fio mais próximo e queima) e golpe de tocha.
  - **Vencidos, viram comida** como os bichos (embrulhar e comer: 80 de saciedade, 35 de seda).
- **Capitã da expedição (minichefe, 480 PV):** guarda a corda da Subida antiga (G16). Corte pesado, investida com escudo, frasco de fogo (área que queima e acaba com as teias por perto) e, furiosa, giro da espada. Na metade da vida sopra a trompa: chegam 2 espadachins. A teia segura metade do tempo nela (armadura). Vencida, a corda fica livre: subir mostra **"Fim do Ato 4"** (o Portão da Superfície vem na próxima versão).
- **O que mudou nas câmaras:**
  - **G4 Grande Gruta:** acampamento-base (tendas, fogueira, caixas, bandeira, tochas), com o esquadrão e as ordens da Capitã (pedra/papel para ler).
  - **G22 Fosso escuro:** a toca do Ato 1 foi queimada (casulo preto, chão de cinza).
  - **As teias que você deixou no Ato 1 viraram carvão** (fios pretos e quebrados nos mesmos pilares).
  - **G7 Lago escondido:** a ilha é a **única toca** (só se chega por fio: os caçadores não alcançam).
  - **G5 Jardim de musgo:** 5 armadilhas de fogo no chão (placa de metal: estoura 16 + queimadura, queima fios, rearma em 8 s; sobre um fio não dispara).
  - **G6, G8, G9:** patrulhas; G9 ocupado, com suprimentos (**ração dos caçadores**: vai para a bolsa como uma presa).
  - **Profundezas:** os caçadores não descem. Rota de fuga, com bichos.
  - **Bichos:** comida escassa (poucas larvas, nada repõe ao descansar); os que sobraram são **alfas** (+5 níveis, mais vida e golpes 50% mais fortes): Lagarto-lanterna alfa no Ninho, lagartos e irmãs caçadoras alfa.
- Correções: chegar de outra camada não troca mais as tocas (dens) da memória pelas do disco.
- Teste novo: `cacada_test`. Captura: `tests/screenshot_cacada.tscn`.

## Abismo e Rio de Brasa abertos: dá para ir e voltar (18/11)

- **A Rampa quente liga os dois andares nos dois sentidos.** No Abismo, subir a rampa (A14) leva ao Rio; no Rio, a **descida a oeste da Margem fria** (degraus para o escuro, com a luz fria do Abismo) leva de volta ao topo da Rampa quente. Berçário e Galerias continuam sem volta.
- A tela "Fim do Ato 2" aparece só na primeira subida; depois o carregamento mostra só "Rio de Brasa" ou "Abismo".
- Voltando do Rio, ela **desce a rampa andando** (a queda dramática e o "ferida e sem seda" são só da primeira chegada).
- **As teias ficam onde você deixou:** fios, teias de captura e casulos de cada andar são guardados ao sair e voltam ao entrar de novo (também no save). A toca de cada andar já era lembrada.
- Correção: chegar numa camada não reaproveita mais um save antigo daquela mesma camada por engano, e o conhecimento em memória (mapas, teias) não é trocado pelo do disco.
- Rio de Brasa: a toca (Câmara fria) agora tem túneis firmes até a Forja e o Ninho (antes, dependendo da geração, a forja podia ficar sem ligação com a toca).

## Ato 3: o Rio de Brasa inteiro (18/11)

- **Chegada:** no topo da Rampa quente (A14) ela sobe correndo, vem a tela "Fim do Ato 2" e o título "Rio de Brasa · Ato 3".
- **Caverna gerada de um andar** (como Galerias e Abismo), ~220 × 140 m, 20 câmaras com nome, cortada por um **rio de lava** de norte a sul. A lava brilha (o fundo dos buracos agora pode ser lava rasa e acesa) e todo buraco do andar é lava: cair queima 40% da vida (menos com Resistência a Fogo) e você sai pela beirada.
- **Calor:** a até 3 m da lava perde vida aos poucos (2,5/s); cada ponto de Resistência a Fogo corta 25% (4 = imune). HUD mostra "CALOR".
- **Resistência a Fogo (nova):** comer salamandras, peixes-magma, vermes de lava (+1; a rainha dá +2), o cristal de fogo (+1) e aguentar calor (a cada 45 s, até 2).
- **Fios sobre a lava queimam em 8 s** (soltam faísca antes de arrebentar).
- **Câmaras:**
  - R1 Margem fria (poça com peixes), R2 Mirante do rio (a escolha das duas rotas).
  - **R3 Ilhas de basalto:** três ilhas no meio do rio com pilares a até 8 m; a **brasa** das ilhas queima rápido (14/s) sem Resistência a Fogo 3.
  - **R8 Rota de pedra:** a volta longa pelo sul, sem lava, com 2 golems dormindo no caminho.
  - **R7 Câmara fria (a toca):** obsidiana resfriada, 4 frestas.
  - R6 Ninho das salamandras (ovos), R4 Forja dos golems (bigornas, moldes e uma pedra escrita), R17 Grota dos peixes, R19 Corredor das brasas, R20 Fosso morno.
  - **R5 Gêiseres:** 5 gêiseres que borbulham 1 s e estouram 0,8 s: arremessam e queimam.
  - **R9 Pântano de cinzas** e R18 Cinzeiro: a cinza no ar tira 2 m da visão.
  - **R10 Cristais de fogo (segredo):** atrás de uma fresta; o cristal de fogo dá Resistência a Fogo +1 e fica guardado como material de uma evolução rara.
  - R11 Antecâmara (ponto seguro) → **R12 Salamandra-rainha** → **R13 Fluxo resfriado** (o fosso de lava esfria quando ela cai) → **R14 Chaminé** ("Fim do Ato 3"; a volta às Galerias, Ato 4, vem na próxima versão).
- **Bichos novos (~58):**
  - **Besouro-brasa** (P, bandos): a comida fácil; descansar repõe.
  - **Peixe-magma** (P): mora na lava; salta em você quando chega na beirada, fica se debatendo no chão (a hora de pegar) e volta. Embaixo da lava não dá para acertar.
  - **Verme de lava** (M): sai da lava e cospe duas bolas de fogo (marca no chão), depois afunda.
  - **Salamandra-chama** (M, pares): sopro de fogo em linha que queima seus fios e te deixa queimando; mordida; chicote de cauda furiosa.
  - **Golem de basalto** (G): dorme parado como pedra; correr perto ou bater acorda. Soco, pisão e arremesso de pedra. Perdendo você, volta a dormir no lugar.
  - **Aranha de cinza** (P, matilhas): como as aranhas-lobo, mais o fio de cinza que deixa lenta.
  - **Morcego de cinza** (P, bandos): mergulho que queima.
  - **Salamandra-rainha (chefe, G, 420 PV):** sopro, mordida, cauda e, furiosa, investida. De tempos em tempos brilha inteira e solta a **onda de fogo**: um anel que cresce até a parede, queima todas as teias e fios da arena e quem estiver no chão (esquive na hora). Depois da onda a pele esfria 3,5 s: dano cheio. Fora disso a pele segura metade.
- **Queimando (novo estado):** 4 PV por segundo enquanto durar; "QUEIMANDO" no HUD.
- Testes: `rio_test` (novo). Capturas: `tests/screenshot_rio.tscn`. Mapa: `desenhar_mapa.py` desenha o Rio de Brasa.

## Abismo cheio de bicho e os três ramos de evolução (17/11)

- **Evoluções depois da Cavaleira (escolha livre):** no nível 10 da Cavaleira, a aba Evolução do casulo destrava os três ramos; clique em um e descanse para fazer a muda (o nível volta a 1, habilidades e pontos ficam).
  - **Ceifadora de Seda (Lâmina):** 140 PV (+10/nível), combo 14/14/26, corpo maior (mais alcance), couraça (-15% de dano). Crista vermelha nas costas.
  - **Tecelã do Abismo (Teia):** 120 de Seda (+7/nível), fio-guia pela metade da seda e +3 m de alcance, teia de captura -40%, 30% mais rápida nos fios. Manto de seda.
  - **Arauta da Runa (Runa):** 150 de Energia (+7/nível), enxerga 8 m no escuro, muito mais furtiva, energia volta mesmo com a runa apagada e o Pulso Espiral já vem (custa 10, atordoa a 6,5 m). Halo de luz.
- **Abismo cheio (~60, como as Galerias):** 51 bichos ao carregar + 8 larvas que aparecem com o tempo, o Colosso e a Cortina viva.
  - **Aranha-lobo do breu (nova, P, matilhas de 3–4):** aranhas que não tecem, só correm e caçam. Enxergam no escuro (de 12 m se a runa estiver acesa); uma que te sente bate as patas e a matilha toda vem. Mordida, bote de longe e mordida no flanco. Matilhas no A15, A16 e A17.
  - **Mímico de estalagmite (novo, M):** finge ser pilar. Quem passa a 2,4 m leva o bote (agarra, puxa e morde 22). Pistas: não acende no Modo Tecelagem e a Leitura (Alt) mostra que é bicho. Comer dá Energia máxima. Três na Floresta, um no Santuário, um no Beco sem volta.
  - **Lesma de ácido (nova, M, 130 PV):** lenta, pasta o musgo dos fungos e deixa rastro de ácido que queima (sobre um fio, não). Cospe ácido longe, esmaga de perto. Comer dá Resistência a Ácido. No Lago negro, no Fosso das raízes e no Fosso dos besouros.
  - **Morcego gigante (novo, M, bandos):** os da Cortina viva acordados: ouvem quem se mexe a 14 m, mergulho de 18. Bandos no Fosso dos besouros, no Santuário e por cima do Abismo duplo.
  - Mais um escorpião (Beco sem volta) e besouros também no Fundo da queda e no Santuário.
- **Ácido na jogadora:** cuspe e rastro da lesma tiram vida na hora; Resistência a Ácido 3 anula.
- Base do Abismo continua sendo só a **A4 Fenda do refúgio**.

## O Abismo inteiro: caverna gerada, A5–A19 e a Serpente-cega (17/11)

- **Mesma pegada das Galerias:** o Abismo virou uma caverna orgânica de um andar (autômato celular, semente fixa) com as câmaras de trava e de chefe feitas à mão. Faixas de rocha em volta da Trilha, da Cortina viva, do Abismo duplo e da arena garantem que nenhum salão gerado vire atalho. ~180 × 120 m, 19 câmaras com nome.
- **Câmaras novas:**
  - **A5 Lago negro:** água preta com uma sombra enorme passando embaixo (e anéis na água). Corrente de fios margem → pedrinha → ilha; na ilha, a **pérola negra**: Resistência a Escuridão (+1,5 m de visão no escuro).
  - **A6 Floresta de estalagmites:** dezenas de pilares (o lugar para subir a Tecelagem).
  - **A7 Ninho dos escorpiões:** 3 escorpiões e o ninho com ovos.
  - **A8 Cortina viva:** túnel coberto de morcegos gigantes, da ponta leste da Trilha até a Câmara de cristal.
  - **A9 Abismo duplo:** fenda de 16 m com pilares a 17,6 m nas bordas: só com Tecelagem 5. Cair é morte.
  - **A10 Câmara de cristal:** lâminas de cristal nas paredes (encostar corta, -8 PV); fresta secreta de volta para a toca; cristal de pedra-da-lua no meio.
  - **A11 Santuário afundado:** colunas quebradas, a espiral da runa brilhando no chão e duas pedras para ler (E). Ponto seguro.
  - **A12 Toca da Serpente-cega**, **A13 Poço de vapor** (jatos de vapor a cada 3,5 s, -10 PV) e **A14 Rampa quente** (no topo: "Fim do Ato 2"; o Rio de Brasa vem na próxima versão).
  - Partes geradas com nome: A15 Galeria dos ecos mortos, A16 Fosso das raízes, A17 Raízes negras, A18 Fosso dos besouros e A19 Beco sem volta (só se chega por uma rachadura da Trilha).
- **A toca do Abismo (A4) tem 4 frestas:** Trilha, Floresta, Lago negro e a fresta secreta da Câmara de cristal.
- **Tecelagem (nova):** cada fio-guia tecido conta. Tecelagem 2/3/4/5 com 8/20/36/56 fios; o fio-guia vai de 12 m até 18 m. Aparece no HUD.
- **Escorpião-de-obsidiana (novo, M, nível 7):** sente o chão (andando 7 m, correndo 11 m; parada ou num fio, não), enxerga 5 m. Pinças em cone que emendam, ferrão em linha que **envenena** e, furioso, giro de cauda. Comer a carne envenena um pouco e sobe a **Resistência a Veneno** (cada ponto corta 25% do veneno).
- **Veneno na jogadora (novo):** perde 3 PV por segundo enquanto durar; aparece "ENVENENADA" no HUD.
- **Cortina viva (nova trava):** runa acesa ou correr por baixo acorda a cortina: ela se fecha, empurra você para trás e machuca até você sair. Runa apagada e andando devagar, você passa. **Pulso Espiral** derruba os morcegos por 9 s.
- **Serpente-cega (chefe novo, G, nível 13, 300 PV):** cega, caça só por vibração. Sente quem anda no chão (andando 9 m, correndo 16 m), fios e teias que vibram (22 m) e uma **teia de captura nova** (tecer faz a teia tremer). Vai sempre na vibração mais nova e dá o **bote** (linha no chão). Se o bote acaba numa teia de captura, ela morde a teia e fica **enredada 5,5 s** com as escamas abertas (dano cheio). Fora disso as escamas seguram 70% do dano. De perto: mordida em cone; furiosa: chicote de cauda em volta. A cauda dela tapa o Poço de vapor; vencida, o caminho abre.
- Besouros também no Fosso dos besouros e nas Raízes negras; larvas perto dos fungos do norte.
- Mapa do Abismo: `tools/desenhar_mapa.py` agora desenha também o Abismo (`/tmp/mapout/mapa_abismo.png`).
- Teste `abismo_test` ampliado (caminhos, travas, Tecelagem, pérola, escorpião, Cortina viva, Serpente, vapor, fim do ato).

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
