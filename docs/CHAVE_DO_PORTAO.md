# A chave do portão: o chefe do vilarejo e as melhorias (plano)

*Data: 2026-11-11. Plano feito por inteiro: as quatro fases (ver as seções "Fase N, feita" no fim). Continua [TUTORIAL_VILAREJO.md](TUTORIAL_VILAREJO.md). Coordenadas em
Godot (x, z).*

## A ideia

O vilarejo termina numa luta que é a prova final do tutorial: tudo o que se aprendeu de combate, junto e sob pressão.
O prêmio é a chave do portão da Colônia e um coração a mais. Junto com isso entra o sistema de melhorias, como nos Zeldas:
- **pela história**, um item único que já dá a melhoria;
- **pela exploração**, um conjunto de 4 peças, e a quarta dá a melhoria.

As duas melhorias do vilarejo: **vida** pelo chefe, **fôlego** por 4 peças escondidas no vilarejo.

## A última tarefa: "A chave do portão"

- **Quem dá:** o Tenório, quando você volta do ossuário com a besta ("Mostrar a besta"). Ele conta: "A chave do portão
  ficava com o Severino, o porteiro da Colônia. Na noite da sirene ele desceu com o molho de chaves na cinta e se trancou
  no jazigo dos Moura, no cemitério. Eu ouço ele lá embaixo, batendo nas paredes. Leva tudo que tiver."
- **Por que ali:** a carta do padre já fala do caixão vazio e da terra mexida por dentro, e o Tenório achou "pegada
  descalça". O jazigo dos Moura é da família do Dr. Euclides, o diretor. O porteiro desceu para guardar o que o doutor
  escondeu lá.
- **A entrada:** o jazigo é um mausoléu de pedra no fundo do cemitério, com grade e uma corrente podre de ferrugem. O
  pé de cabra arrebenta a corrente, a terceira porta que ele abre. Antes da tarefa, a grade só diz "Tem alguma coisa
  batendo lá embaixo." e não abre.
- **Antes da porta:** um oratório no cemitério, para salvar. Perder a luta devolve o jogador ali, não ao começo do dia.

## O chefe: O Porteiro

**Quem é:** o Severino, porteiro da Colônia, que tomou o soro do doutor para aguentar a noite. Ficou grande: 2,4 m,
curvado, o uniforme de brim rasgado nas costas, a cara enfaixada como a de um interno. Arrasta um **molho de chaves de
ferro** do tamanho de um mangual, preso à cinta por uma corrente, e leva **um lampião aceso pendurado no peito**: é a
luz dele, e é o ponto fraco.

**A arena** (cena própria, `jazigo.tscn`, como uma sala de chefe de Zelda): a cripta redonda embaixo do mausoléu, 14 m
de diâmetro.
- Oito colunas em volta, as gavetas dos Moura nas paredes e uma escadaria por onde se desce (fechada depois que ele acorda).
- Doze velas grossas em castiçais nas colunas: a luz da sala.
- No centro, o caixão aberto do doutor, vazio.

**As três fases** (vida: 30; o facão tira 1 e 2, o virote 3, e um golpe no lampião vale o dobro):

| Fase | Quando | O que ele faz | O que o jogador usa |
|---|---|---|---|
| 1. A ronda | 30 a 20 | Anda em volta e ataca com o molho de chaves: um golpe lateral (dá para bloquear, 1 de dano, só a lasca passa) e um golpe de cima com as duas mãos, telegrafado (ele ergue o molho e as chaves tilintam). O de cima não se bloqueia: 2 de dano e atravessa o facão. | **Bloquear** o lateral, **esquivar** o de cima (Espaço, de lado). Depois do de cima ele fica preso 1,2 s com o molho no chão: a janela para o **combo** (golpe e golpe de cima). **Travar a mira** (E) ajuda a circular. |
| 2. O muro | 20 a 10 | Recua para o alto do altar de pedra (2 m) e arremessa pedras de túmulo, uma a cada 3 s, com 1 de dano. Lá de cima, o facão não alcança. | **Besta**: o lampião no peito dele é o alvo, e cada virote nele derruba 3 e o faz cambalear. Entre um arremesso e outro, **esconder-se atrás das colunas** e **recarregar** (R). Os virotes acabam? Há 6 numa caixa ao pé da escada, que se repõe uma vez. |
| 3. O escuro | 10 a 0 | O lampião dele quebra (ou ele o apaga) e com a corrente ele derruba as velas: a sala fica escura. Agora ele caça a **luz**, como a Bruxa: corre para a lamparina na mão e ataca. No escuro, sem luz, ele **escuta**, como o Poceiro: correr chama. | **Pendurar a lamparina** (3) para ele perder você; **agachar** para não ser ouvido; chegar **por trás**, porque golpe pelas costas tira o triplo. Ou usar a lamparina de isca: pendurar, andar agachado e deixar que ele vá na última luz que viu. |

- **Dificuldade:** ele não tem golpe que mate de uma vez com 3 corações; o de cima tira 2. Ataduras e garrafadas
  continuam valendo (F). A luta deve durar uns 4 a 6 minutos para quem já fez as dungeons.
- **Sons:** chaves tilintando a cada passo (o aviso de sempre de onde ele está), o golpe de ferro no chão, o lampião
  quebrando, um gemido grave abafado pelas faixas. Uns 6 efeitos do ElevenLabs (por volta de 40 créditos).
- **Música:** a luta pede uma faixa própria. Escrevo o prompt para você gerar no ElevenLabs, como foi com as outras.

**O fim:** ele cai de joelhos e larga o molho de chaves. No molho, a **chave do portão** (`chave_portao`, que já existe e
abre o `Gate`) e, no caixão do doutor, o **coração de ex-voto** (a melhoria de vida, ver abaixo). A escadaria abre. Ao
sair, o Tenório e a Firmina têm fala nova.

## As melhorias

**O que já existe:** o HUD desenha um coração de ex-voto por ponto de `max_health` e uma conta de terço por meio ponto
de `stamina_max`, e o coração novo já entra brilhando. Os números também já vão no save. Falta só de onde as melhorias vêm,
e que elas durem: hoje cada cena cria o personagem com os valores de fábrica.

**Como fica:**
- **Itens novos** no `ItemCatalog`, do tipo "melhoria", únicos:
  - `coracao_exvoto`: "Coração de ex-voto. Lata batida em forma de coração, de quem pagou promessa. Um coração a mais."
    É da história e vale 1 de vida na hora;
  - `conta_terco`: "Conta de terço. Madeira escura, gasta de tanto rezar. Quatro fazem uma dezena." É da exploração; cada
    4 viram 1 conta a mais no terço do fôlego (+0,5 de fôlego, ou seja, uma conta no HUD).
- **De onde vem o valor:** vida máxima = 3 + corações; fôlego máximo = 4 + 0,5 por conjunto de 4 contas. Calculados
  pelo `Inventory` ao criar o personagem em qualquer cena; assim valem em toda parte e não dependem de save.
- **Únicas de verdade:** cada uma está num lugar só (baú ou achado com `id`, Story `pego:<id>`), nenhuma loja vende, e
  nenhuma tarefa as dá de novo. Repetir uma tarefa não é possível, e pegar de novo também não.
- **A quarta conta:** ao pegar a quarta, a faixa "Você encontrou" do baú diz "O terço ficou mais comprido" e o HUD mostra
  a conta nova brilhando (o mesmo brilho do coração novo).
- **No caderno (Tab), em Bolso:** "Contas de terço: 3 de 4".

**As 4 contas do vilarejo** (cada uma pede uma coisa aprendida, e todas ficam fora do caminho principal):

| Onde | O que pede |
|---|---|
| no fundo do tanque de vinhoto, no alambique | cair no tanque de propósito (quem caiu sem querer acha) |
| numa gaveta da galeria do ossuário, entre os ossos | andar agachado pela galeria olhando as gavetas |
| em cima do telhado da casa queimada, presa num prego | subir: um caixote para empurrar até a parede caída dos fundos, depois a borda com cal |
| debaixo da cama da casa do Zé | o pé de cabra e entrar na casa |

O telhado da casa queimada é a única peça nova de cenário: um caixote (`Pushable`) e uma borda com cal na parede dos
fundos, que já está meio caída.

## Ordem de implementação (um commit e push por fase, só os testes dela)

1. **Melhorias:** itens, cálculo da vida e do fôlego, a faixa da quarta conta, o caderno e as 4 contas nos lugares.
2. **A tarefa e a arena:** a fala do Tenório, o jazigo no cemitério (corrente, oratório), a cena da cripta.
3. **O Porteiro:** modelo e animações (Blender, como os outros mutantes), as três fases, os sons, o prêmio.
4. **O fim:** a chave abrindo o portão, as falas novas e o prompt da música da luta.

## Fase 1, feita: as melhorias

- `ItemCatalog` tipo "melhoria": `coracao_exvoto` e `conta_terco`. Nenhuma loja vende, e o teste confere isso.
- **A vida e o fôlego vêm do bolso:** `Inventory.health_max()` (3 + corações) e `breath_max()` (4 + meia conta a cada 4
  contas). O personagem de toda cena nasce com eles, e pegar uma melhoria cresce na hora: um coração novo vem cheio, uma
  conta nova também.
- **Os avisos:** "Conta de terço (2 de 4)"; na quarta, "O terço ficou mais comprido: mais fôlego.", e o terço aparece no
  HUD. No caderno, em Bolso: "Contas de terço (n de 4)".
- **As 4 contas do vilarejo** (cada uma achada uma vez, `Pickup.bead`, uma bolinha escura com um brilho fraco):

  | Onde | Mudou do plano? |
  |---|---|
  | no fundo do tanque de vinhoto, no alambique | não |
  | numa gaveta baixa da galeria do ossuário | não |
  | no oratório da casa do Zé, aos pés da santa | sim: debaixo da cama não dava, a cama é sólida |
  | no vaso em cima de um túmulo de 2 m no canto sudoeste do cemitério, com uma pedra para empurrar até ele | sim: o telhado da casa queimada pedia geometria nova no Blender; o túmulo usa só peças do jogo (pedra, borda com cal) |

- Testes: treino `upgrades_tests`; vilarejo `tomb_tests`; a conta de cada interior no teste dele.

## Fase 2, feita: a tarefa e a arena

- **A tarefa** (`QuestData` "chave"): ao mostrar a besta, o Tenório conta do Severino e do jazigo dos Moura e dá a tarefa.
  Depois dá para perguntar de novo ("Perguntar pela chave do portão").
- **O jazigo no cemitério** (`construcoes.py` `jazigo()`, `layout.JAZIGO`): mausoléu de pedra cinza no fundo do cemitério,
  de frente para o portão dele, com frontão, cruz de ferro e uma grade. Saíram dali duas covas que ficavam embaixo dele.
  - Antes da tarefa: "E · olhar a grade" e "Tem alguma coisa batendo lá embaixo."
  - Com a tarefa: a grade tem uma corrente enferrujada (`BlockedDoor` "corrente", nova: grade de ferro com dobradiça, três
    voltas de corrente e um cadeado). O pé de cabra arrebenta ("A CORRENTE CEDEU · Grade aberta") e "E · descer ao jazigo".
  - Um oratório ao lado, para salvar antes.
- **A cripta** (`jazigo_build.py`, `jazigo.tscn`, `jazigo.gd`): escada de 12 degraus da grade até a sala redonda de 14 m e
  6 m de pé-direito; 8 colunas; 10 círios em suportes de ferro (luz nova `cirio`, sem som, guardados em `candles` para a
  fase 3 apagar); gavetas dos Moura nas paredes; o altar de 2 m com a cruz (não se sobe); o caixão do doutor aberto no
  centro; 6 virotes numa caixa ao pé da escada. Marcadores para o chefe: `porteiro`, `altar`, `caixao`, `escada`.
- Ainda sem o chefe: é a fase 3.
- Testes: `test_vilarejo.gd` `jazigo_tests`, `test_jazigo.gd`.

## Fase 3, feita: O Porteiro

- **O modelo** (`tools/personagens/porteiro_build.py`, mesmo kit dos mutantes; renders em `renders/porteiro/`): 2,3 m,
  curvado, uniforme de brim azul com botões de latão, a cara enfaixada com um olho à mostra, o quepe de porteiro, os
  antebraços enfaixados, o molho de chaves de ferro na mão direita e o lampião aceso no peito (material `o_lampiao`). 1.464
  triângulos, 16 ossos. Animações: `Idle`, `Walk`, `Attack` (golpe lateral), `Smash` (golpe de cima, preso no chão do
  quadro 28 ao 56), `Throw`, `Roar`, `Jump`, `Hit`, `Death`.
- **O comportamento** (`scripts/enemies/porteiro.gd`), 30 de vida:

  | Fase | O que ele faz |
  |---|---|
  | 0 | espera junto ao caixão; acorda quando você pisa no chão da cripta (ou se apanhar) |
  | 1 (30 a 20) | anda até você; a cada três golpes, ou quando você bloqueia demais, o golpe de cima: as chaves tilintam antes, ele atravessa o bloqueio (2 de dano) e depois fica 1 s preso no chão. O lateral se bloqueia (só passa a lasca). |
  | 2 (20 a 10) | salta para o altar e arremessa uma pedra a cada 3 s. As colunas param as pedras. Lá em cima o facão não alcança ("Lá em cima o facão não alcança."); só o virote, que acerta o lampião e o faz cambalear. |
  | 3 (10 a 0) | o lampião quebra, ele desce e a sala apaga. Corre (2,1 m/s) para a lamparina na mão; no escuro ele ouve, como o Poceiro. Golpe pelas costas tira o triplo. |

  - O facão não o faz cambalear: só o virote e o golpe pelas costas.
  - **Nenhum golpe pula uma fase:** a vida para no limite da próxima, e ele só morre na última.
- **A arena** (`jazigo.gd`):
  - ao acordar: um desabamento fecha a escada atrás de você, aparece o nome e a vida dele no alto, e toca a música da luta
    (`music/chefe.mp3`, se existir);
  - na fase 2 aparece uma segunda caixa de 6 virotes, se a primeira já foi pega;
  - na fase 3 os círios se apagam um a um.
- **A morte:** a escada abre e os círios voltam. No chão fica o molho de chaves com a chave do portão (a tarefa termina ao
  pegar). No caixão, um coração de lata girando e brilhando: "Você encontrou · Coração de ex-voto", um coração a mais. Depois
  disso a cripta fica quieta (Story `morto:porteiro`).
- `Player.take_damage(n, de, pierce)`: um golpe que atravessa o bloqueio.
- Sons novos (ElevenLabs, 43 créditos): `porteiro_chaves`, `porteiro_golpe`, `porteiro_gemido`, `porteiro_rugido`,
  `porteiro_queda`, `lampiao_quebrar`, `pedra_quebrar`.
- Teste: `test_jazigo.gd` `boss_tests`. Cobre:
  - o lateral bloqueado e o golpe de cima atravessando;
  - o golpe pelas costas e nenhuma fase pulada;
  - o altar: facão inútil, virote, pedra parada na coluna e pedra que acerta no aberto;
  - o escuro: ele não acha quem está agachado com a lamparina no gancho, e vai atrás da lamparina na mão;
  - a morte, a chave e o coração.

## Fase 4, feita: o fim

- **O portão:** a chave do molho abre o `Gate` da Colônia (que já esperava `chave_portao`): a corrente cai, as folhas
  abrem uma fresta e "E · entrar na Colônia" leva para cima. O teste `gate_tests` confere.
- **Falas depois da luta**, uma vez cada:
  - Tenório, "Contar do Severino": trinta anos abrindo o portão para os doutores, "e no fim foram eles que trancaram ele
    do lado de fora"; sobe de dia; "se a tua mãe estiver lá em cima... traz ela descendo essa estrada";
  - Dona Firmina, "Contar do jazigo": era o Severino que trazia notícia do Joaquim, no começo; uma vela para ele e outra
    para quem vai subir.
- **A música da luta:** "Crypt Procession" (ElevenLabs Music, gerada pelo autor), em `godot_demo/music/chefe.mp3`.
  - Entra quando o Porteiro acorda, toca em loop e some quando ele morre.
  - A faixa original tem 2:00, mas termina em 4 s de silêncio; foi cortada em 1:55,5, com um final suave de 2 s, para o loop
    voltar sem buraco.
  - Toca a -14 dB. É bem mais alta que as outras (média de -14,5 dB, contra -20 da abertura), e por baixo dela as chaves
    precisam continuar audíveis, porque avisam o golpe de cima.
  - O prompt usado:

  > Dark boss battle theme for a 1970s Brazilian rural horror game, fought in a candlelit stone crypt under a cemetery.
  > Driving but heavy, 100 BPM, minor key. A detuned viola caipira playing a repeating, tense ostinato; low cellos and
  > double basses sawing in sharp accents; a deep procession drum (surdo) and a frame drum pounding like footsteps;
  > metallic percussion of iron keys and chains struck in rhythm; a wordless low male choir humming a mournful Catholic
  > chant underneath, swelling in the second half. Gritty, raw, analog, no synths, no lyrics, no spoken words. Builds to
  > a climax around 1:30 and returns to the opening ostinato so it loops cleanly. 2 minutes.

- Teste: `test_vilarejo.gd` `jazigo_tests` (as falas, uma vez cada).

## A entrada do Porteiro (cinemática)

`scripts/ui/boss_intro.gd` (`BossIntro`, sobre a mesma base das outras cinemáticas: faixas pretas, título e "segure E
para pular"). Uns 11 s, na primeira vez que você pisa no chão da cripta. Depois de uma morte, a nova tentativa vai direto
para a luta (`Porteiro.introduced`, que volta a falso num jogo novo).

| Plano | Duração | O que se vê | O que se ouve |
|---|---|---|---|
| 1. A escada | 2 s | por cima do ombro dele, um monte de pedras despenca e fecha a escada; a câmera treme | o desabamento |
| 2. O escuro | 3 s | os círios baixam; a câmera avança devagar pela cripta até o vulto parado junto ao caixão | as chaves dele tilintando duas vezes; começa a tensão subindo (`chefe_tensao`) |
| 3. O lampião | 2 s | de baixo, o lampião no peito dele se acende e mostra a cara enfaixada | a chama pegando (`lampiao_acender`) |
| 4. O nome | 3,5 s | ele abre os braços e ruge | no mesmo instante: o impacto (`chefe_impacto`), o rugido e a música da luta, que começa aqui; aparece "O PORTEIRO", com a legenda "Severino · porteiro da Colônia Santa Clara" |

- A tensão começa no plano 2 e é cortada no impacto, para tudo cair junto com a primeira nota da música.
- Pulando (segurar E) ou não, termina igual: a escada fechada, o lampião dele aceso, a música tocando, a câmera de volta e
  a luta começando (ele já rugiu, então parte direto para cima de você).
- Ele agora espera no escuro, com o lampião apagado, até acordar.
- O desabamento da escada virou um monte de pedras soltas, em vez de um bloco liso.
- Sons novos (ElevenLabs, 32 créditos): `chefe_tensao`, `chefe_impacto`, `lampiao_acender`.
- Teste: `test_jazigo.gd` `intro_tests` (uma captura de cada plano: `jazigo_8a` a `8d`).
