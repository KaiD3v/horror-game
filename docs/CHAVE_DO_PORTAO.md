# A chave do portão: o chefe do vilarejo e as melhorias (plano)

*Data: 2026-11-11. Plano. Feito: fase 1, as melhorias (ver "Fase 1, feita" no fim). Continua [TUTORIAL_VILAREJO.md](TUTORIAL_VILAREJO.md). Coordenadas em
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
