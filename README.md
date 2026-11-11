# Cavaleira de Seda — protótipo cinza

Fangame top-down de sobrevivência e estratégia: uma aranha recém-nascida precisa sobreviver numa caverna onde tudo é maior que ela. Este é o **protótipo cinza** (formas simples, sem arte final). Ele existe para responder uma pergunta: *o loop de 10 minutos é divertido?*

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
| Ajuda na tela | H | Back |
| Pausa | Esc | Start |
| Testes: +1 nível / apagar save | F1 / F8 | — |

No **Modo Tecelagem** o tempo cai para 25%. Clique em um pilar e depois em outro (até 12 m) para esticar um **fio-guia**. Andar no fio é 1,5× mais rápido, silencioso, e é o único jeito de cruzar o abismo. O botão direito arma uma **teia de captura** (a partir do nível 3).

## O que tem na câmara de teste

- **Oeste:** início, larvas e uma poça com um Sapo-de-rocha.
- **Centro:** um abismo de 6 m. Cair custa 25 PV.
- **Leste:** mais comida, outro sapo e a saída.

Sistemas: 4 recursos que aparecem no corpo da aranha (placas = PV, runa = Energia, cachecol = Seda, abdômen = Saciedade), fome, território, vibração nos fios, casulo com save, veneno, Enredado com crítico ×2, furtividade por luz e barulho, e um ecossistema básico (o sapo caça e come larvas).

## Roteiro de teste (15 min)

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
world/         main.tscn + test_chamber.gd (a câmara é montada por código)
ui/            hud.gd
audio/voice/   arquivos de dublagem (veja docs/falas.md)
tests/         teste automático e capturas de tela
```

Os valores de balanceamento ficam como constantes no topo de cada script (`player.gd`, `frog.gd`, `larva.gd`...).

## Dublagem

As falas do monólogo e os nomes de arquivo estão em [`docs/falas.md`](docs/falas.md). Grave, salve como `audio/voice/<id>.ogg` e o jogo toca sozinho.

## Quando os modelos 3D chegarem

Cada ator monta seu visual em `_build_visual()` com formas cinza. Para trocar por um modelo, importe o `.glb` e substitua o conteúdo desse método por uma instância do modelo. A física e a lógica não mudam.

## Teste automático

```
godot --headless --path . res://tests/smoke_test.tscn
```

O teste joga sozinho: atravessa o abismo pelo fio, cai, luta, come, tece um casulo, salva, e confere o ataque do sapo e a teia de captura. São 20 verificações.
