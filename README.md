# Cavaleira de Seda — protótipo cinza (v0.3)

Fangame top-down de sobrevivência e estratégia: uma aranha recém-nascida precisa sobreviver numa caverna onde tudo é maior que ela. Este é o **protótipo cinza** (formas simples, sem arte final). Ele existe para responder uma pergunta: *o loop de 10 minutos é divertido?*

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
3. Aperte **F5** para jogar.

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
| Pausa | Esc | Start |
| Testes: +1 nível / apagar save | F1 / F8 | — |

No **Modo Tecelagem** o tempo cai para 25%. Clique em um pilar e depois em outro (até 12 m) para esticar um **fio-guia**. Andar no fio é 1,5× mais rápido, silencioso, e é o único jeito de cruzar o abismo. O botão direito arma uma **teia de captura** (a partir do nível 3).

## O que tem em cada camada

**Berçário (início):** B1 eclosão (coma uma irmã menor) → B2 corredor (uma irmã faminta te caça; ou vá pela trilha baixa, mais escura) → B3 salão das teias (primeiro fio-guia sobre o abismo; a fresta ao sul leva ao cristal secreto de B4) → B5 despensa (apague a runa com F e passe pela pata da Mãe) → B6 fuga (corra! teça o fio no segundo abismo) → túnel para as Galerias.

**Galerias (câmara de teste):** larvas, dois Sapos-de-rocha, um abismo de 6 m e a saída a leste.

Sistemas: 4 recursos que aparecem no corpo da aranha (placas = PV, runa = Energia, cachecol = Seda, abdômen = Saciedade), fome, território, vibração nos fios, casulo com save, veneno, Enredado com crítico ×2, furtividade por luz e barulho, e um ecossistema básico (o sapo caça e come larvas).

## Roteiro de teste (20 min)

Comece um jogo novo (F8 apaga o save) e jogue o Berçário inteiro antes da câmara de teste.

Jogue sem ler o código e anote:

1. Em quanto tempo você entendeu que precisa tecer um fio para atravessar o abismo?
2. A fome te obrigou a sair do casulo? Pareceu justa ou chata?
3. O sapo foi assustador, fácil ou injusto?
4. Você usou a teia de captura e a runa apagada por estratégia, ou só atacou?
5. Qual foi o momento mais divertido? E o mais frustrante?

## Estrutura do projeto

```
autoload/      EventBus (sinais), GameState (controles, save, falas), WebNetwork (teias e território), Voice (dublagem)
actors/
  player/      player.gd — a Cavaleira
  creatures/   creature.gd (base), larva.gd, frog.gd, corpse.gd
systems/
  web/         âncoras, fio-guia, teia de captura, casulo
  ecosystem/   repovoamento da câmara
  fx.gd        formas cinza e efeitos simples
world/         main.tscn (abre o save ou o Berçário), layer_base.gd (base de toda camada)
  layers/      bercario.tscn, test_chamber.tscn
systems/level/ cave_builder.gd (cavernas orgânicas), map_system.gd, pickup.gd
systems/spider_legs.gd   as 8 patas com IK
actors/bosses/ mother_leg.gd (pata da despensa), mother_chase.gd (fuga)
ui/            hud.gd
audio/voice/   arquivos de dublagem (veja docs/falas.md)
tests/         teste automático e capturas de tela
```

Os valores de balanceamento ficam como constantes no topo de cada script (`player.gd`, `frog.gd`, `larva.gd`...).

## Dublagem

As falas do monólogo e os nomes de arquivo estão em [`docs/falas.md`](docs/falas.md). Grave, salve como `audio/voice/<id>.ogg` e o jogo toca sozinho.

## Quando os modelos 3D chegarem

Cada ator monta seu visual em `_build_visual()` com formas cinza. Para trocar por um modelo, importe o `.glb` e substitua o conteúdo desse método por uma instância do modelo. A física e a lógica não mudam.

## Testes automáticos

```
godot --headless --path . res://tests/smoke_test.tscn      # sistemas centrais (20 verificações)
godot --headless --path . res://tests/bercario_test.tscn   # Berçário de ponta a ponta (20 verificações)
```

Os testes jogam sozinhos: fio sobre o abismo, queda, combate, comer, casulo, save, sapo, teia de captura, paredes, mapa, irmãs, fresta, cristal, pata da Mãe e a fuga.
