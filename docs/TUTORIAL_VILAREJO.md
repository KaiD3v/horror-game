# O vilarejo como tutorial (plano)

*Data: 2026-11-11. Plano. Feito: fases 1 e 2 (ver "Fase 1, feita" e "Fase 2, feita"). Coordenadas em Godot (x, z); no Blender é (x, -z).*

## O problema

O jogo tem muitas mecânicas de uma vez: andar, correr, agachar, lamparina na mão ou no gancho, notas, baús, escalar,
empurrar, pular, descer, facão (golpe, combo, bloqueio, esquiva, trava), besta (mirar, atirar, recarregar, virotes),
curativo, salvar no oratório, ferramentas que abrem caminho, lojas, tarefas, e três mutantes da noite com regras
diferentes (luz, som, vista).

Antes da fase 1, quase tudo chegava pela faixa de controles no alto da tela (`Hud.CONTROLS`), que listava 20 teclas antes
de o jogador precisar de qualquer uma. O facão está num baú a 8 m da chegada e a besta se compra por Cr$ 20.

A meta: o jogador aprende tudo isso no vilarejo, no primeiro dia e na primeira noite, sem caixa de tutorial, sem
pausa para ler e sem texto que explique o que ele ainda não precisa.

## Regras do desenho

1. **Ensinar em lugar seguro, cobrar em lugar perigoso, depois combinar.** Cada mecânica aparece primeiro onde
   errar não custa nada. Depois volta onde custa. Por fim se junta com outra. É o 1-1 de Super Mario e o ciclo das
   masmorras de Zelda.
2. **O espaço é a trava, não o texto.** Uma porta pregada, um vão baixo ou um mato fechado dizem "aqui não, ainda".
   O jogador entende por que não passa e lembra do lugar quando acha a ferramenta.
3. **Uma coisa nova por vez.** Nenhuma sala ensina duas mecânicas novas. A sala seguinte junta a nova com uma velha.
4. **Errar sai barato no começo.** O primeiro pulo é sobre um vão raso (cair dele não chega aos 2,2 m que machucam).
   A primeira escalada é sobre chão macio. O primeiro inimigo dá 0,5 de dano.
5. **O mundo tem uma língua só.** Os mesmos sinais em todo o jogo (tabela abaixo). Aprendidos uma vez, valem para a
   Colônia.
6. **Quem explica são as pessoas e os papéis.** O Tenório ensina a lutar, a Firmina ensina a noite, o Bento ensina a
   se cuidar. Tudo pelos rumores e conversas que já existem, e pelas notas.

### O que continua escrito na tela

- **A linha de uso** ("E · arrombar a porta", "Espaço · pular"), que já existe. Ela só aparece diante da coisa e
  nunca para o jogo.
- **Linhas de situação novas, com as mesmas letras e no mesmo lugar**, só para o que não tem objeto na frente:
  "C · agachar" diante de um vão baixo, "3 · pendurar a lamparina" quando os morcegos se agitam, "Botão direito ·
  bloquear" quando um inimigo arma o golpe. Cada uma some depois que ele faz a ação duas vezes
  (Story `aprendeu:<acao>`) e nunca volta.
- **Os pensamentos dele** ("Pesado demais para as mãos.", "A queda o machucou."), como já é.
- **A faixa de controles sai do HUD.** Ela fica só no menu de pausa, em Controles, que já existe.

### A língua do lugar

| Sinal | Quer dizer | Onde aparece primeiro |
|---|---|---|
| Pedras salientes com musgo claro, raiz exposta | dá para escalar o muro | ruína da chegada |
| Borda com cal riscada (marca de tropeiro) | dá para subir nessa borda | ruína da chegada |
| Tábuas pregadas em X | pé de cabra | porta do alambique |
| Cana seca, taquara ou cipó fechando a passagem | facão | saída do alambique, depois pelo vilarejo |
| Corda velha pendendo, ou um balde num gancho | a besta corta, de longe | ossuário, depois pelo vilarejo |
| Ossos e cacos no chão | barulho: ande agachado | ossuário |
| Entulho de pedra | picareta (fica para a Colônia) | túnel do ossuário |
| Vela acesa num nicho | oratório: salvar | estrada da chegada |

## O percurso do primeiro dia

```
                           N   portão da Colônia (trancado)
                               |
                 [casa]        |        [casa]
                               |
  [cemitério]--[capela]--[largo + poço]--[venda]------[armaria]
   (ossuário embaixo da sacristia: dungeon 2; sai pelo poço do largo)
                               |
       [casa queimada]         |        [casas]
                               |
        [ruína: a sala de aula]|   [pasto, espantalho]  [ALAMBIQUE: dungeon 1]
                   [oratório]  |
                     chegada --+
               ~~~~~~~~~~~~ ravina ~~~~~~~~~~~~
```

O dia começa às 06:30 e a noite às 18:00, cerca de 11 minutos e meio de jogo. O primeiro dia foi desenhado para o
jogador sair do alambique com o facão por volta do anoitecer. Quem demorar entra na primeira noite sem arma, e por
isso a primeira noite é a mais branda (ver "As noites").

### 1. A chegada (já existe, ajustes pequenos)

- **Andar, câmera, correr:** a estrada reta de terra, subindo para o norte. A Colônia acesa no alto mostra para onde
  ir, como já é.
- **E e as notas:** a mala aberta com o bilhete do Tonho (2,5; 41,8) fica no caminho. É a primeira coisa com "E".
- **Salvar:** o oratório da estrada (-2,8; 44) fica logo depois, com a vela apagada. Acender a vela salva e ela fica
  acesa. Ele aprende que vela acesa num nicho quer dizer "aqui é seguro".

### 2. A ruína da chegada vira a sala de aula

A casa em ruínas (-10; 36) perde o baú do facão. Ela passa a ensinar o movimento, onde cair não machuca:

- **Subir:** uma parede caída a 1,2 m, com cal riscada na borda. Lá de cima se vê dentro da ruína.
- **Descer:** do outro lado, a mesma borda para descer pendurado.
- **Pular:** um vão de 1,5 m entre dois pedaços de piso. Embaixo, 1 m de altura e capim: cair não dói.
- **Agachar:** uma viga caída fecha a passagem até a altura do peito. Diante dela aparece "C · agachar".
- **A recompensa:** no canto, uma lata com Cr$ 5 e um recorte de jornal. A recompensa é pequena, mas mostra que
  vale a pena olhar.

É opcional: a estrada passa ao lado. Mas a ruína fica no caminho do olhar, e a viga e a borda riscada voltam no
alambique.

### 3. O largo: as três pessoas e as tarefas

- **Dona Firmina** (cruzeiro): a tarefa da garrafada, como já é. A capela ensina o baú, o curativo e o F.
  - **Novo:** a entrega rende também a chave da sacristia ("O padre deixava comigo. Eu limpava a igreja."). Essa
    chave abre a dungeon 2.
  - A fala da noite dela passa a ensinar a luz: "Lá em cima a luz chama. Apaga a tua quando ouvir as asas."
- **Seu Bento** (venda): dá a tarefa do alambique (dungeon 1) e empresta o pé de cabra para a porta pregada.
- **Tenório** (armaria): a besta sai da loja; os virotes continuam lá, pedindo a besta.
  - Sem lâmina: "Sem lâmina você não volta de lá. Arruma um facão primeiro."
  - Com o facão, conta onde perdeu a besta e dá a tarefa da dungeon 2.
  - Os rumores dele ensinam a lutar ("de perto, no peito"; "ergue o facão quando ela armar o golpe").

O portão da Colônia, no fim da estrada, continua trancado. Quem sobe direto vê a corrente e volta.

## Dungeon 1: o alambique do Juca (o facão)

**Onde:** no fim do pasto do sudeste, depois do espantalho, colado ao barranco leste, perto de (42; 30). Da estrada
se vê a chaminé, fria, e uma trilha de capim pisado que sai da cerca quebrada.

**A tarefa** (`QuestData` "alambique"), do Seu Bento: "O Juca do alambique não desce faz uma semana. Foi ele que
ouviu serrarem a ponte. Leva o pé de cabra: ele pregou a porta." Ao voltar com a notícia, o Bento paga Cr$ 15. O pé de
cabra fica com o jogador: é ferramenta e abre outras portas pregadas do vilarejo.

**O que ensina:** o pé de cabra, empurrar, escalar muro, pular e descer juntos, a regra da luz (morcegos), o
curativo sob pressão e o facão, primeiro como ferramenta e depois como arma.

**Por fora:** a porta pregada em X ("Pregada com tábuas. Com um pé de cabra, talvez.", `BlockedDoor` "tabuas", que já
existe). Quem chega antes da tarefa entende o que falta e volta com o Bento.

**Por dentro** (cena `alambique.tscn`, interior separado como as lojas). Cada sala ensina uma coisa e junta com uma
velha:

| Sala | Nova | Junta com | Como |
|---|---|---|---|
| 1. A moenda | empurrar | subir | Um caixote de lenha (`Pushable`) encostado sob o jirau de 1,6 m. Empurra, sobe nele, sobe no jirau. |
| 2. O jirau dos barris | a luz chama | agachar | Morcegos no telhado. Com a lamparina na mão eles revoam em cima dele (0,5 de dano, a tela escurece). Pendurada (3), passam reto. Uma brasa da fornalha embaixo deixa ver o chão sem luz. |
| 3. A torre do alambique | escalar muro | pular, descer | Sobe pela parede de tijolo com apoios até a passarela, pula o vão sobre o tanque de vinhoto e desce do outro lado. Quem cai, cai no tanque raso (1,8 m, sem dano) e sobe de novo pela escada. |
| 4. O quarto do Juca | o baú do facão | o curativo | Uma atadura num caixote antes da porta, depois dos morcegos. O baú tem o facão de cana do Juca. |
| 5. A saída | o facão corta | o golpe | A porta do quarto está fechada por feixes de cana seca. "A lâmina corta isso." Cada golpe (botão esquerdo) derruba um feixe. Lá fora, o canavial seco atrás do alambique, cortado até a cerca. |

- **O que aconteceu com o Juca:** o quarto está trancado por dentro, a janela foi quebrada por fora e há marcas de
  mão em barro no peitoril, as mesmas dos pilares do portão. Ninguém lá dentro.
- O diário do Juca (nota nova) fecha a pergunta da ponte: "Eram de branco. Serraram as vigas com serrote de
  carpinteiro e subiram pro morro."
- **Os morcegos são o primeiro inimigo**, de propósito fraco: 1 de vida, morrem com um golpe. Depois do facão, a
  sala 2 vira lugar de treinar o golpe. Eles também ensinam a regra da Bruxa: a luz na mão chama o que voa.
- **Oratório** na porta, por fora. Ao sair, o jogador salva antes da noite.

## As noites: a escala por progresso

Hoje toda noite traz os três mutantes. No plano, quem vem depende do que o jogador já tem, e não do número de dias.
Assim cada mutante chega quando o jogador tem a resposta para ele:

| O jogador tem | Vem à noite | O que ele já aprendeu para isso |
|---|---|---|
| nada | 1 Bruxa | a luz (morcegos): pendurar a lamparina basta para não ser achado |
| o facão | 2 Bruxas + o Poceiro | lutar com o facão; o Poceiro só se aprende de verdade no ossuário |
| a besta | os três (+ a Carpideira) | matar de longe e em silêncio |

- **A primeira noite com facão é a prova de luta.** A Bruxa circula e mergulha. Depois do golpe ela para 0,8 s, e
  essa é a janela que ensina bloquear e revidar. Na primeira vez que ela arma, aparece "Botão direito · bloquear".
- **Sem facão na primeira noite:** só uma Bruxa, e o jogador já sabe apagar a luz. Ele também pode passar a noite na
  venda, onde o Bento fala da porta trancada, e sair de manhã.
- Fica em `DayData` ou numa constante do `vilarejo.gd`, perguntando a `Inventory.has`. Não pede código novo nos
  mutantes.

## Dungeon 2: o ossuário de Santa Clara (a besta)

**Onde:** embaixo da capela. A porta da sacristia (no presbitério, nova no `capela.glb`) desce para o ossuário, que
corre por baixo do cemitério e do largo até o fundo do poço.

**A tarefa** (`QuestData` "besta"), do Tenório, só com o facão: "Fui atrás do rapaz da Firmina. Entrei pela
sacristia. Lá embaixo uma coisa cega me ouviu antes de eu ver ela. Larguei a besta e a corda e subi pelo poço.
Quer a besta? É tua. Só não corre lá dentro." O recado dele na armaria ("Fui atrás do rapaz da Firmina") passa a ser
o começo dessa história.

**A trava:** a chave da sacristia (`chave_sacristia`, já no catálogo), que vem da tarefa da garrafada. A ordem
natural fica: Firmina (garrafada, chave), alambique (facão), Tenório (tarefa da besta), ossuário. As travas são
ferramentas e falas, e o jogador pode fazer a garrafada e o alambique em qualquer ordem.

**O que ensina:** a regra do som (agachar, não correr), a besta (mirar, atirar, recarregar, contar virotes), a besta
como distração e a primeira luta de verdade, que pode ser evitada.

| Sala | Nova | Junta com | Como |
|---|---|---|---|
| 1. A escada da sacristia | nada | a lamparina | A descida, velas apagadas, os virotes do Tenório espalhados nos degraus (5, para pegar). Um respiro antes. |
| 2. A galeria das gavetas | o som | agachar | Ossos e cacos no chão. Andando em pé, cada passo estala alto. Agachado, quase nada. Do fundo vem a respiração do Poceiro dormindo, que fica mais alta a cada passo barulhento. Ainda não é perigo: ele está longe. |
| 3. O nicho caído | a besta | mirar e atirar | A besta do Tenório no chão, ao lado de uma mancha de sangue (baú de achado, sem baú: `Pickup`). Logo à frente, um vão que não se pula, e do outro lado uma tábua de passagem presa no alto por uma corda. Mira (botão direito), atira, a corda arrebenta e a tábua cai como ponte. Errar só custa o virote. |
| 4. A cisterna do poço | a besta distrai | o som, agachar | O Poceiro dorme na água, entre o jogador e a corda que sobe pelo poço. Garrafas e latas penduradas nas paredes. Um virote numa garrafa do lado oposto faz barulho lá, e ele vai ver. Agachado, o jogador passa pelo outro lado até a corda. |
| 5. O poço | subir pela corda | | Ele sobe pela corda do Tenório e sai no largo, ao lado do poço, de dia. O jogador descobre que esteve embaixo do vilarejo o tempo todo. A corda fica amarrada (Story `corda:poco_largo`): é um atalho de volta. |

- **Se o Poceiro acordar:** ele caça pelo som, como à noite. Dá para lutar com o facão (10 de vida: golpe 1, de cima
  2, virote 3) ou fugir pela corda.
  - Se ele morrer ali, não sobe mais do poço nas noites seguintes (Story `morto:poceiro`). É uma escolha do jogador
    com uma consequência visível, e não um castigo.
- **O rapaz da Firmina:** o escapulário dele no fundo da cisterna, perto de um túnel desmoronado que sobe para o
  norte, para a Colônia ("Pedra demais para tirar com as mãos.", `Breakable`). A picareta fica para depois, e o
  túnel promete um segundo caminho para a Colônia. Devolver o escapulário à Firmina fecha a história dela.
- **Oratório** no topo da escada da sacristia.

## Depois das dungeons: o vilarejo se abre

Cada arma nova faz o jogador olhar o vilarejo de novo, como depois de cada item num Zelda:

- **Facão:** 4 ou 5 moitas de taquara e cipó pelo vilarejo (atrás da casa queimada, no canavial, no muro do
  cemitério, no fundo da casa 04) com baús menores atrás: dinheiro, ataduras, virotes, notas.
- **Besta:** coisas penduradas que só caem de longe: um balaio na araucária, uma lata no braço do espantalho, um saco
  preso na viga da ponte caída. Cada uma tem um achado.
- **Pé de cabra:** as portas pregadas por fora (as três casas acorrentadas pedem chave; uma quarta casa, pregada,
  abre com o pé de cabra e tem um interior pequeno).
- **Dinheiro:** acaba o "Ainda não dá para ganhar dinheiro". Agora vem das tarefas (Bento Cr$ 15, Firmina Cr$ 20) e
  dos achados (Cr$ 3 a 10 cada), o bastante para virotes e ataduras sem sobrar.

## A chave do portão (decisão do autor)

Ainda não está decidido. A sugestão que fecha o percurso: o Tenório entrega a chave quando o jogador volta do
ossuário ("Eu levava cartucho lá pra cima. Os doutores me deram essa. Não sobe de noite."). Assim o caminho
principal fica: facão, besta, chave, Colônia. Outra opção: a chave no fundo da cisterna, com o escapulário.

## O que muda no código e na arte

| Peça | O quê | Custo |
|---|---|---|
| HUD | tira a faixa `CONTROLS` (fica no menu de pausa) | pequeno |
| Linhas de situação | `Hints`: mostra a linha no `prompt` do HUD até `aprendeu:<acao>` duas vezes | pequeno |
| Ruína | borda, viga, vão e lata em `narrativa.py`; tira o baú do facão de `ChestData` | médio |
| Mato que o facão corta | `Breakable` com `requires: "facao"` e feixes de cana/taquara (modelo novo, simples) | médio |
| Coisa pendurada que a besta derruba | corda que o virote arrebenta (`bolt.gd` acerta, o objeto cai) | médio |
| Morcegos | bando simples (pontos com asas, segue a lamparina na mão), 2 sons | médio |
| Alambique | casa nova por fora (`construcoes.py`) e interior `alambique_build.py` + cena | grande |
| Ossuário | porta da sacristia na capela, `ossuario_build.py` + cena; o Poceiro dormindo (estado novo) | grande |
| Tarefas e falas | `QuestData` "alambique", "besta"; Bento, Tenório, Firmina; nota do Juca; besta fora da loja | pequeno |
| Noites por progresso | quem vem à noite conforme `Inventory.has` | pequeno |
| Sons (ElevenLabs) | morcegos revoando, cana cortada, ossos sob os pés, corda arrebentando, garrafa quebrando | cerca de 5 gerações |

## Ordem de implementação (cada fase: um commit e push, só os testes dela)

1. **A língua e o HUD:** sai a faixa de controles, entram as linhas de situação (`Hints`) e as noites por progresso.
2. **O largo e a ruína:** a sala de aula na ruína, o baú do facão sai, a besta sai da loja, falas e tarefas novas.
3. **Dungeon 1, o alambique:** exterior, interior, pé de cabra do Bento, morcegos, cana cortável, o facão.
4. **Dungeon 2, o ossuário:** sacristia, ossuário, Poceiro dormindo, corda que a besta arrebenta, saída pelo poço.
5. **O vilarejo se abre:** moitas, coisas penduradas, a casa pregada e o dinheiro dos achados.

## Fase 1, feita

- **O HUD não tem mais a faixa de controles nem o nome da cena.** As teclas ficam em Controles, no menu de pausa. As
  teclas de teste da cena (T +1 hora no vilarejo, H dano no treino) aparecem embaixo de "Pausa", como "teste: ...".
- **Linhas de situação** (`scripts/ui/hints.gd`, `Hints`): aparecem na linha de uso do HUD, que tem prioridade quando
  há algo para usar com E. Cada uma some na hora em que ele faz a ação pela segunda vez (Story `aprendeu:<acao>`) e
  não volta mais.

  | Linha | Quando aparece | Conta quando ele |
  |---|---|---|
  | Botão direito · mirar | a besta na mão, sem mirar | mira |
  | Botão direito · bloquear | um inimigo arma o golpe, com o facão na mão (`Enemy.go`) | ergue o facão |
  | 3 · pendurar a lamparina | a luz da mão chamou uma Bruxa | pendura a lamparina no gancho |
  | F · curativo | ele se machuca e tem um curativo | usa um curativo |
  | C · agachar | (pronta; a fase 2 a coloca diante dos vãos baixos) | |

- **Noites por progresso** (`vilarejo.gd` `roster()`): sem o facão, 1 Bruxa; com o facão, 2 Bruxas e o Poceiro; com a
  besta, também a Carpideira.
- Testes: `test_treino.gd` `hints_tests` (e a linha de teste em `pause_tests`), `test_vilarejo.gd` `roster_tests`.

## Fase 2, feita

- **A ruína é a sala de aula** (detalhes em [VILAREJO.md](VILAREJO.md), "A ruína da entrada"). Mudou do plano:
  - o buraco tem 0,9 m (o assoalho fica alto, sobre a fundação) em vez de 1 m;
  - a borda para subir é a tulha de pedra do fundo, de 0,7 m sobre o assoalho, e a descida é pela parede caída do fundo;
  - a recompensa é uma lata com Cr$ 5 e o caderno escolar de uma menina da vila, não um recorte de jornal.
- **Agachar de verdade:** agachado, o corpo dele baixa para 1,2 m e passa sob o que é mais baixo que um homem; sob o forro
  ele não se levanta. Um golpe ou uma esquiva ainda o põem de pé mesmo ali (anotado no código).
- **A besta saiu da loja.** O Tenório tem "Perguntar por uma besta" ("Ficou lá embaixo... Arruma uma lâmina primeiro") e um
  rumor novo que ensina o bloqueio.
- **Dona Firmina:** a garrafada entregue rende também a chave da sacristia, e de noite ela ensina a pendurar a lamparina.
- **Fica para a fase 3:** o baú do facão continua junto à ruína, e a tarefa do Bento e o pé de cabra entram com o alambique.
  Sem o alambique, tirar o facão agora deixaria o jogo sem facão.
- Testes: `test_vilarejo.gd` `classroom_tests` e a entrega da garrafada em `dialog_tests`; `test_treino.gd` `unlock_tests`
  (a besta fora da loja).
