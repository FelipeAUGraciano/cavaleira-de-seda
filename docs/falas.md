# Falas do monólogo (para dublagem)

Cada fala toca uma vez por save. Para dublar, grave o áudio e salve em `audio/voice/` com o **id** como nome do arquivo, por exemplo `audio/voice/inicio.ogg`. Também aceita `.wav` e `.mp3`. Se o arquivo não existir, o jogo só mostra a legenda.

| id | Quando toca | Texto |
| --- | --- | --- |
| `inicio` | Ao começar (Berçário) | ...Ok. Eu sou uma aranha. Uma aranha MINÚSCULA. Num ninho. Ótimo. |
| `b1_fome` | Entrando na Câmara de eclosão (B1) | Minhas irmãs estão me olhando do mesmo jeito que eu olho pra elas. |
| `b2_irma` | Entrando no Corredor das cascas (B2) | Ela é maior que eu. E mais rápida. E muito, MUITO mais faminta. |
| `b3_teias` | Entrando no Salão das teias (B3) | As teias da Mãe são enormes. Dá pra prender um fio nelas... |
| `b4_fresta` | Entrando na Fresta do ninho (B4) | Ser pequena tem suas vantagens. |
| `b5_pata` | Entrando na Despensa da Mãe (B5) | Aquilo é... a pata da Mãe. Não respira. Não brilha. Não existe. |
| `b5_visto` | Quando a pata da Mãe a percebe | Ela me sentiu! |
| `b6_fuga` | Entrando na Fuga (B6) | CORRE, CORRE, CORRE, CORRE! |
| `b6_pega` | Quando a Mãe a alcança | AAAH! Ela é ENORME! |
| `b_saida` | Saindo do Berçário | Ela não cabe no túnel... Consegui. Acho. |
| `galerias` | Chegando às Galerias (câmara de teste) | Galerias úmidas... cheiro de musgo. E de comida. |
| `primeiro_dano` | Primeiro dano recebido | AI! Ok, ok, tudo aqui é maior que eu. Anotado. |
| `primeira_refeicao` | Primeira vez que come | Larva crua. Gosto de musgo molhado. Mas a fome venceu o nojo. |
| `comeu_podre` | Primeira carne podre | Eca. Eca, eca, eca. ...Mas acho que meu estômago ficou mais forte. |
| `primeira_tecelagem` | Primeira vez no Modo Tecelagem | Tudo ficou lento... Consigo ver onde prender meus fios. |
| `primeiro_fio` | Primeiro fio-guia | Um fio! Andar nele é rápido e silencioso. Isso muda tudo. |
| `primeiro_zip` | Primeira vez que se puxa até a parede | Fio, parede, VOOOU! |
| `primeiro_puxao` | Primeira presa puxada com fio | Vem cá, lanchinho! |
| `primeiro_casulo` | Primeiro casulo | Um casulo! Agora tenho onde dormir sem virar janta. |
| `primeiro_descanso` | Primeiro descanso | Casulo quentinho... Isso aqui é meu agora. Meu território. |
| `territorio` | Primeira vez no território | Sinto cada fio vibrando. Aqui é seguro... mais ou menos. |
| `runa_apagada` | Primeira vez que apaga a runa | Shhh... Apagada, sou só mais uma sombra na caverna. |
| `primeira_armadilha` | Primeira teia de captura | Pronto. Agora é só esperar alguém pisar... Paciência de aranha. |
| `nivel_3` | Ao chegar no nível 3 | Nível 3! Sinto que consigo tecer uma teia de captura. Modo Tecelagem e botão direito. |
| `fome` | Primeira vez faminta | Minha barriga está roncando tão alto que vai me denunciar. |
| `primeira_queda` | Primeira queda no abismo | Não olha pra baixo. Não olha pra baixo. ...Olhei. |
| `primeira_morte_pre` | Na primeira morte | Ah, não... tudo ficou escuro... |
| `primeira_morte` | Ao acordar depois da primeira morte | ...Tá. Aranha teimosa não desiste. |
| `saida` | Ao chegar na saída | Ar fresco?! ...Não. Só mais caverna. Mas é um começo. |

Dica de gravação: mono, 44,1 kHz, com uns 0,2 s de silêncio no começo e no fim. O Godot importa `.ogg` e `.wav` direto.
