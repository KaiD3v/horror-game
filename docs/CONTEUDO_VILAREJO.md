# O vilarejo vivo: conteúdo secundário (plano)

*Data: 2026-11-11. Continua [TUTORIAL_VILAREJO.md](TUTORIAL_VILAREJO.md) e [CHAVE_DO_PORTAO.md](CHAVE_DO_PORTAO.md).
Fases 1 a 3 feitas (ver "Fase N, feita" no fim); o resto é plano. Coordenadas em Godot (x, z).*

## O problema

O caminho principal do vilarejo está completo: duas masmorras, o chefe, a chave. Fora dele, o lugar ainda é um
cenário. As pessoas ficam paradas no mesmo ponto a qualquer hora, três casas acorrentadas nunca abrem (`chained` em
`layout.py`, a `chave_cadeado` está no catálogo sem uso) e a `corda` e a `picareta` existem sem nenhum lugar onde
servir. O vilarejo é o lugar para onde o jogador volta entre os capítulos, e precisa ter vida própria.

## Regras (o que separa conteúdo rico de lista de tarefas)

1. **Cada coisa entrega uma destas**, nesta ordem de valor: entender algo da história; um verbo ou uma ferramenta
   nova; um atalho; uma melhoria única. Consumível (dinheiro, atadura, virote) só como sobra, nunca como prêmio
   principal. Se uma ideia só dá dinheiro, ela não entra.
2. **Nada de ícone, contador ou marcador.** Quem aponta são as pessoas (rumores), o próprio lugar (a língua do lugar,
   em TUTORIAL_VILAREJO.md) e o que se vê do alto. A única contagem do jogo continua sendo a das contas do terço.
3. **Pouco e feito à mão.** A meta é 6 tarefas, 3 jogos e 3 pessoas novas, e não 30 de cada. Cada tarefa tem um
   momento de que o jogador vai lembrar e cabe em 10 a 20 minutos.
4. **O mundo lembra.** O que o jogador faz muda o lugar (uma porta aberta, um sino que volta a tocar, alguém que some)
   e as pessoas comentam, uma vez (Story, como já é com o Severino). Isso é barato: são falas com condição.
5. **A hora importa.** De dia o vilarejo tem gente fazendo coisas; de noite, os mutantes. Algumas coisas só
   acontecem numa hora certa, e o jogador descobre isso olhando, não por um aviso.
6. **Nada de missão que se repete sozinha** ("traga 5 peles"), nem de juntar material para fabricar. Um jogo pode
   ser jogado de novo, mas o prêmio dele sai uma vez só.

## O tema que amarra tudo

As notas já dizem o que a Colônia era: um **leprosário** (o Serviço de Profilaxia, o decreto de 1962 que acabou com o
isolamento, os filhos separados dos pais internados, o "menor nº 112"). O conteúdo secundário conta o outro lado,
o do vilarejo: quem vendia para a Colônia, quem tinha medo dela, quem trabalhou lá, quem fechou a porta para um
ex-interno. Cada pessoa nova e cada casa trancada é um pedaço dessa história, e não uma tarefa solta.

---

## 1. As rotinas (a base de quase tudo)

Cada morador tem um dia: onde está, o que faz e o que fala ali. Nada de simulação; uma tabela por hora.

| Hora | Seu Bento | Tenório | Dona Firmina |
|---|---|---|---|
| 6h | abre a venda, varre a frente | no portão da Colônia, olhando para cima (só olha, e volta) | reza no cruzeiro, acende as velas |
| 9h a 17h | no balcão; ao meio-dia almoça na porta, no banco | na armaria; à tarde, no fundo, atirando em garrafas | à tarde no cemitério, limpando o túmulo do marido |
| 18h | fecha a venda, tranca a porta | na varanda, espingarda no colo, lamparina acesa | toca o sino (depois da tarefa do sino) e volta ao cruzeiro |
| noite | dentro da venda: bater na porta e ele fala pela fresta (vende, mais caro) | entra às 21h; a armaria fica escura | ajoelhada no cruzeiro a noite toda, velas acesas |

- **Para que serve:** o Tenório no portão às 6h é uma pergunta sem resposta, até a tarefa dele (seção 3). A Firmina
  no cemitério leva ao túmulo do marido, que tem um nome e uma data que voltam numa nota. O Bento fechado de noite
  ensina, sem texto, que de noite o vilarejo não é seu.
- **Como fica no código:** `NpcCatalog` ganha `rotina: [[hora, marcador, animação, estado_da_fala], ...]`. O NPC anda
  pelo navmesh até o próximo marcador quando a hora muda; fora da vista do jogador ele só aparece lá. As falas leem
  o estado (`"se": {"lugar": "varanda"}`). Cada um precisa de 1 ou 2 animações novas (varrer, sentar, ajoelhar).
- **Custo:** médio. Pede marcadores no `vilarejo_build.py` e animações nos NPCs.

## 2. Os sons da hora (o relógio que não é um relógio)

- **O sino da capela**, às 6h e às 18h, depois da tarefa do sino (seção 4). O das 18h é o aviso de que a noite vem.
  Hoje o jogador só tem a luz para saber disso.
- **A Voz do Brasil**, às 19h, no rádio da venda: o programa do governo que todas as rádios eram obrigadas a
  transmitir naquela hora. O som sai abafado pela porta fechada do Bento. É o detalhe de época que diz "anos 70" sem
  uma palavra na tela.
- **Custo:** pequeno. Dois sons (ElevenLabs: o sino ao longe; um rádio AM chiando com uma voz de locutor sem
  palavras claras, para não gastar com voz).

---

## 3. As pessoas novas (3)

Cada uma tem um papel no jogo e um pedaço da história. Nenhuma está ali só para dar tarefa.

### Cida, a filha do Zé (escondida)

- **Quem é:** a casa do Zé conta que a família foi levada ("Ela disse certinho: Zezinho. Vou abrir."). A Cida, de
  9 anos, não foi: estava embaixo da cama. Desde então vive escondida no forno de barro dos fundos da venda, e o Bento
  dá comida a ela sem contar para ninguém, com medo de que a Firmina ou o Tenório a "levem lá pra cima".
- **Como se encontra (tarefa "Quem come o pão do Bento"):** o Bento reclama que some pão da venda. Depois de uma
  chuva, pegadas pequenas no barro saem dos fundos da venda (as poças já existem, `DRY` em `DayData`). Seguir as
  pegadas leva ao forno. Ela foge. Na segunda vez, agachado e devagar, ela fala.
- **A escolha:** contar ao Bento que achou a menina, ou guardar o segredo dos dois. Contando, o Bento se abre (uma
  história sobre a mulher dele, que foi internada) e passa a dar desconto. Guardando, a Cida confia mais e mostra
  um esconderijo a mais.
- **O que ela dá:** o **jogo de esconde-esconde** (seção 5) e, no fim dele, o **mapa dela**: o vilarejo desenhado a lápis
  de cor, com os lugares que ela tem medo marcados com um "X" e uma carinha. Não marca nada que o jogador não tenha
  visto; marca só os medos dela, que são pistas (o forno da casa de farinha, a ruína do norte, a ravina).
- **A voz que imita:** é ela quem explica o que é a criatura que chama pelo nome. Isso prepara uma mecânica de noite
  (seção 7).

### Bastião, o ex-interno (a ruína do norte, casa 15)

- **Quem é:** um interno solto pelo decreto de 1962, que "não tinha para onde ir". Morou anos na ruína perto do
  portão. Tem as mãos marcadas pela hanseníase e esconde o rosto. O vilarejo acha que ele é um dos mutantes; ele
  não é. É a pessoa viva que mais sabe da Colônia por dentro.
- **Como se encontra (tarefa "As galinhas do Tenório"):** o Tenório diz que um bicho rouba as galinhas dele de noite
  e vem da ruína do norte. Pede para o jogador matar.
- **A escolha:** levar a cabeça do bicho (não existe: o Tenório vai ver e expulsa o Bastião a tiro), ou levar comida
  e o cobertor da casa do Zé para o Bastião. Se ajudar, o Tenório desconfia, e uma fala dele muda depois.
- **O que ele dá:** a **chave da casa 14** (a da enfermeira, seção 6), e conversa sobre a Colônia: o pavilhão das
  crianças, o túnel que passa embaixo do muro, a enfermeira. É a ponte para o capítulo da Colônia, e quem diz para que
  a picareta vai servir.
- **Por que importa:** é o único lugar onde o jogo fala do estigma de frente, sem discurso: o jogador vê como o
  vilarejo trata alguém doente e decide se repete aquilo.

### O mascate (aparece em alguns dias)

- **Quem é:** um vendedor ambulante com uma mula, Seu Dito, que sobe a estrada de dois em dois dias, de manhã, e vai
  embora à tarde. Chegou antes de a ponte cair e ficou preso deste lado.
- **Para que serve:** ele vende o que o Bento não tem e troca por achados (um relógio de bolso, uma medalha, um
  rosário de prata, encontrados nas casas trancadas). Uma única vez ele tem a **corda**, que abre a ravina (seção 6).
- **A sua história:** ele quer ir embora. Tem uma tarefa pequena e boa: baixar um tronco atravessado na ravina, que
  hoje pende de uma corda num tronco do outro lado (um virote na corda). O tronco vira uma ponte, ele vai embora numa
  manhã e deixa um bilhete com um presente. É uma pessoa que o jogador ajuda a sair, e que não volta mais.
- **Custo:** médio (um NPC e a mula, o tronco na ravina).

> Uma quarta pessoa, se fizer falta: o sineiro. Por ora a Firmina toca o sino, e uma velha puxando a corda do sino ao
> entardecer já é uma imagem forte o bastante.

---

## 4. As tarefas (6, cada uma com um momento)

| Tarefa | De quem | O momento | O prêmio | O que muda no mundo |
|---|---|---|---|---|
| **O sino da capela** | Firmina | subir a torre por dentro (escalar, empurrar a escada caída), amarrar a corda nova no sino; lá em cima, a vista do vilarejo inteiro | a vista do alto mostra uma luz na ruína do norte (o Bastião) e fumaça na pedreira | o sino toca às 6h e às 18h |
| **Quem come o pão do Bento** | Bento | seguir as pegadas pequenas na lama depois da chuva até o forno | a Cida; o esconde-esconde; o mapa | a Cida aparece de dia em lugares dela |
| **As galinhas do Tenório** | Tenório | de noite, na ruína do norte, a "criatura" acende uma vela e pede para não atirar | a chave da casa da enfermeira; o que o Bastião conta da Colônia | o Bastião fica ou vai embora; o Tenório lembra |
| **O tronco do mascate** | Seu Dito | um virote na corda do outro lado da ravina, o tronco caindo e virando ponte | o bilhete e o presente dele (a aljava de couro, seção 5) | a ponte do tronco: atalho para a ravina |
| **O túmulo sem nome** | ninguém: o jogador acha | no cemitério, um túmulo sem nome com flores frescas; ver quem deixa (a Firmina, às 15h, rotina) e perguntar | a história do marido da Firmina, que trabalhou na Colônia e não é quem ela conta (uma nota) | uma fala nova da Firmina, mais dura |
| **A rádio da Colônia** | o rádio da venda | de madrugada, sintonizar uma frequência que não devia existir (seção 5): a Colônia transmitindo uma lista de números de interno | o número 0187 é lido; o jogador sabe de quem é (a nota da mãe dele) | nenhuma: é só para ele saber |

As três últimas casas trancadas (seção 6) são prêmios destas tarefas, e não tarefas a mais.

---

## 5. Os jogos (3, dentro do mundo)

Cada um ensina ou afia algo que o jogo cobra depois, e o prêmio sai uma vez só.

### Palitinho com o Tenório (na armaria, de noite antes das 21h)

- O jogo de boteco: cada um esconde de 0 a 3 palitos na mão e os dois tentam adivinhar o total. Rápido, de sorte e
  de ler o outro: o Tenório tem manias (põe sempre o mesmo número quando está perdendo), e quem presta atenção ganha.
- **A aposta** é pequena e tem teto: ele joga com no máximo Cr$ 30 por noite, e para quando acaba. Não dá para
  enriquecer.
- **O prêmio de verdade:** a cada partida ganha, ele conta uma lembrança (a caça, a Colônia, os cartuchos que levava
  lá para cima, por que fica olhando o portão de manhã). São 4 lembranças, e a última responde à pergunta da rotina
  das 6h.

### Tiro nas garrafas (o fundo da armaria, à tarde)

- Seis garrafas no mourão, ele marca o tempo. Ensina a mirar rápido com a besta, que o Porteiro cobra no alto do
  altar.
- **O prêmio:** bater o tempo dele dá a **aljava de couro** do Tenório (os virotes não fazem mais barulho no cinto
  quando ele corre, o que conta para o Poceiro), uma vez só. Ou ela vem do mascate: uma das duas fontes, decidir.
- Os virotes gastos voltam (estão no chão), para não custar munição.

### Esconde-esconde com a Cida (de dia)

- Ela se esconde num lugar do vilarejo e dá uma pista falada ("Onde o pão fica quente", "Onde o morto não tem nome",
  "Onde o Zé guardava a cachaça"). São 3 rodadas, cada uma mais longe.
- **Para que serve:** é um passeio guiado pelos cantos do vilarejo sem nenhum marcador. Cada esconderijo dela é um
  lugar de verdade, e um deles tem um achado que o jogador ainda não tinha visto.
- **O prêmio:** o mapa desenhado (seção 3), que vai para o caderno (Tab).

### A sintonia do rádio (a venda, de madrugada)

- Girar o dial (mouse ou A/D) num chiado; perto de uma estação o som clareia. De dia só há música e a Voz do Brasil.
  De madrugada, depois das três tarefas da Firmina, do Bento e do Tenório, uma frequência a mais aparece entre
  duas estações.
- **Custo:** pequeno; 3 a 4 sons em camadas, misturados pelo volume conforme o dial.

---

## 6. Os lugares

### Abertos agora, pelo que o jogador já tem

| Lugar | A trava | Como se entra | O que tem |
|---|---|---|---|
| **A torre da capela** | nenhuma: a escada interna caiu | empurrar e subir (já se sabe) | o sino; a vista do vilarejo (a única "torre" do jogo, sem revelar ícone nenhum) |
| **O forno da venda** | nenhuma | seguir as pegadas | a Cida |
| **A ruína do norte (casa 15)** | nenhuma: só a coragem, de noite | andar até o portão | o Bastião |
| **A casa de farinha** | mato (facão) | nova, a oeste do canavial | a roda e a prensa de mandioca; uma sala pequena de enigma: empurrar a roda faz a prensa subir e abre o porão (um achado e uma nota do dono, que vendia farinha para a Colônia) |

### As casas acorrentadas (3, cada uma com uma chave de tarefa)

Cada uma é um quarto pequeno como a casa do Zé (`casa_ze_build.py` é o molde): uma família, uma história, um achado.

| Casa | De quem era | A chave vem de | O que se encontra |
|---|---|---|---|
| casa 02 (a azul, na chegada) | Dona Lurdes, a professora | a Cida (era a professora dela) | os diários de classe, com nomes de alunos riscados e "subiu" ao lado; o relógio de bolso (troca com o mascate) |
| casa 10 (a de ocre, a leste) | o motorista da Colônia | o mascate, no bilhete de adeus | a caminhonete no quintal, o livro de viagens: quem subia e quando, e a última viagem, na noite da sirene, sem volta; a medalha (troca com o mascate) |
| casa 14 (a vinho, junto do portão) | a enfermeira da Colônia | o Bastião | o quarto dela: o uniforme que falta no cabide, cartas para a mãe, uma seringa de vidro vazia. Prepara a Enfermeira ([ENFERMEIRA.md](ENFERMEIRA.md)) antes de o jogador a conhecer |

A `chave_cadeado` do catálogo vira as três chaves (`chave_lurdes`, `chave_motorista`, `chave_enfermeira`), cada uma
gasta na sua porta.

### Fechados até mais tarde (a volta depois da Colônia)

São o motivo para voltar ao vilarejo com as ferramentas do capítulo seguinte, como num Zelda.

| Lugar | A trava | O sinal no mundo (a língua do lugar) | O que tem |
|---|---|---|---|
| **O túnel do ossuário** | entulho (picareta) | já existe ("Pedra demais para tirar com as mãos.") | o segundo caminho para a Colônia |
| **A pedreira, no barranco leste** | entulho na boca da galeria (picareta) | a fumaça vista da torre; um carrinho de mina tombado | uma galeria curta; no fundo, o depósito onde o doutor guardava o soro (lore do Porteiro) e um coração de ex-voto em pedaços, se o jogo quiser uma segunda melhoria de vida |
| **O fundo da ravina** | a corda (do mascate) ou a ponte do tronco | a ponte caída, um brilho lá embaixo | o carro do Dr. Euclides, caído da ponte na noite da sirene, com a pasta dele: ele estava fugindo. A pergunta "quem derrubou a ponte" fica para a Colônia |
| **O porão da venda** | uma tampa de ferro com cadeado de segredo | números riscados no balcão | o que o Bento escondia: as coisas da mulher dele, internada na Colônia (a história que ele conta se o jogador contar da Cida), e uma carta dela, que ele nunca abriu |

---

## 7. A noite, além dos mutantes

- **A voz que imita:** à noite, de vez em quando, alguém chama o nome do personagem de dentro de uma casa (a voz da
  mãe). Abrir a porta é o que o Zé fez. Não abrir é a resposta certa, e a Cida ensinou isso. Custa pouco (um som,
  uma porta que não abre para lugar nenhum, um susto se abrir) e faz o jogador ouvir a noite.
- **A manhã depois:** o que os mutantes fizeram fica no chão de manhã (arranhões numa porta, uma galinha morta, a
  vela da Firmina apagada), e as pessoas falam disso. Uma linha por noite já basta.
- **A procissão:** uma única noite, depois do Porteiro, uma fila de luzes desce do portão até o cemitério. Seguir
  agachado, sem ser visto, até o túmulo sem nome. É um evento, não uma área. Decidir se é a Carpideira com outras.

## 8. O que fica de fora de propósito

- Pesca, colheita, criação de bicho, fabricar coisas: dariam horas de tarefa sem dizer nada sobre a Colônia.
- Colecionáveis em quantidade (figurinhas, 50 garrafas): o terço já é o colecionável, e é curto.
- Tarefas que se repetem a cada dia, e qualquer NPC que só existe para dar tarefa.
- Mapa com marcadores: o mapa é o da Cida, desenhado, e só marca medos.

---

## Ordem sugerida (cada fase: um commit e push, só os testes dela)

1. **As rotinas e os sons da hora:** a tabela de horários, o andar entre marcadores, as falas por lugar, a Voz do
   Brasil. Tudo o resto depende de onde as pessoas estão e quando.
2. **O sino da capela:** a torre, a corda, a vista do alto, o sino às 6h e às 18h.
3. **A Cida:** as pegadas, o forno, a escolha, o esconde-esconde, o mapa, a casa da professora.
4. **O Tenório e o Bastião:** o palitinho, o tiro nas garrafas, as galinhas, a ruína do norte, a casa da enfermeira.
5. **O mascate e a ravina:** o Seu Dito, as trocas, o tronco, a casa do motorista, a corda e o fundo da ravina.
6. **O rádio, o túmulo sem nome e a noite:** a sintonia, a rádio da Colônia, a voz que imita, a manhã depois.
7. **Os lugares do depois:** a pedreira e o porão da venda, travados e com o sinal posto, para abrir quando a
   picareta existir.

### Custo de arte e de som

- **Modelos:** a Cida e o Bastião (a receita dos NPCs, `npcs_build.py`), o Seu Dito e a mula, o sino e a escada da
  torre, a casa de farinha, três interiores pequenos (molde da casa do Zé), o forno, o tronco da ravina, o carro.
- **Animações dos NPCs:** varrer, sentar, ajoelhar, olhar para cima, tocar o sino.
- **Sons (ElevenLabs, sem voz):** sino ao longe, rádio AM com a Voz do Brasil, chiado e estações, palitos na mesa,
  garrafa estourando (já existe?), a mula, o tronco caindo, a voz que imita (um sussurro sem palavras). Cerca de 10
  gerações.

---

## Fase 1, feita: as rotinas e o rádio

**A tabela** (`NpcCatalog` "rotina": um horário por linha, com a cena, o lugar, a animação, o "lugar" das falas e o que
ele leva na mão):

| Hora | Seu Bento | Tenório | Dona Firmina |
|---|---|---|---|
| 0h | no balcão, a venda fechada | no balcão, a armaria fechada | ajoelhada no cruzeiro |
| 6h | na frente da venda, varrendo (com a vassoura) | no portão da Colônia, olhando para cima | de pé no cruzeiro, rezando |
| 8h a 9h | volta ao balcão às 9h | volta ao balcão às 8h | |
| 12h | almoça sentado no banco do largo | | |
| 13h | no balcão | | |
| 14h | | | ajoelhada no túmulo do marido, o Antero, no cemitério |
| 16h | | | de volta ao cruzeiro |
| 18h | fecha a venda (fica no balcão) | na varanda da armaria, com a lamparina acesa no chão | ajoelhada no cruzeiro |
| 21h | | entra e fecha a armaria | |

- **Como andam** (`Npc.go`, `Level._routine`): quando a hora muda, cada um vai para o lugar novo. Se o jogador está
  perto (30 m, o alcance da neblina), ele anda pelo navmesh com a animação de andar; quem muda de cena anda até a porta e some,
  e quem chega sai pela porta e anda até o lugar. Longe da vista, ou num interior (sem navmesh), ele só aparece lá,
  ou some, quando o jogador não está olhando.
- **Corpo:** os moradores ficam numa camada de colisão própria (`Npc.LAYER`): o jogador esbarra neles; os mutantes, o
  navmesh e a câmera não (eles mudam de lugar, então não deixam buraco no navmesh onde estavam).
- **As velas da Firmina** ficam acesas no cruzeiro quando ela vai ao cemitério (`luz` "fica", `Npc.leave_behind`).
- **O que falam** depende de onde estão (condição `lugar` do `Dialog`, duas falas alternadas para cada lugar):
  - o Bento varrendo e almoçando no banco;
  - o Tenório no portão ("Vim ver se o portão continua fechado. Continua.") e na varanda;
  - a Firmina no túmulo do Antero.
- **As portas fechadas pela hora** (`Door.hours`):
  - a venda das 18h às 6h: "E · bater na porta", as batidas (`bater_porta`), o Bento responde lá de dentro e abre;
  - a armaria das 21h às 6h: o Tenório responde e não abre.
- **A Voz do Brasil** (`DayData.radio`), das 19h às 20h:
  - o rádio da venda troca a música pelo programa;
  - na rua, o som sai abafado pela porta da venda (`vilarejo.gd` `_radio`, filtro de 1,2 kHz).
- **Animações novas dos NPCs** (`npc_kit.py` `day_actions`, as mesmas para os três): `Walk`, `Sit`, `Kneel`, `LookUp`,
  `Sweep`. Os braços ficam como foram feitos (mãos na barriga, no facão, postas), então andam sem balançar os braços.
- **Sons novos (ElevenLabs, 74 créditos):** `bater_porta` e `voz_do_brasil` (rádio AM, fanfarra e locutor sem
  palavras claras, em loop).
- **Mudou do plano:**
  - o Tenório fica de pé na varanda, com a lamparina no chão ao lado (sem cadeira nem espingarda no colo);
  - o Bento atende a batida e deixa entrar, em vez de vender pela fresta: a venda continua sendo o abrigo da noite.
- **Testes:**
  - `test_vilarejo.gd` `rotina_tests`: cada um no lugar e na animação de cada hora, as falas por lugar, o Bento
    saindo pela porta e andando até o banco, as velas no cruzeiro, a varanda, o rádio e as duas portas, com seis capturas
    `v50` a `v55`;
  - `test_venda.gd` `rotina_tests`: o balcão vazio às 7h, ele de volta às 9h30 e o rádio às 19h.

## Fase 2, feita: o sino da capela

**A tarefa** (`QuestData` "sino"):
- **Quem pede:** a Dona Firmina, depois da garrafada ("Perguntar pelo sino"). O sino que se ouve às vezes é o vento batendo o
  badalo: a corda apodreceu na noite da sirene, e sem o Ângelus ninguém sabe quando a noite chega.
- **A corda:** o Bento dá uma corda grossa ("Pedir uma corda grossa", `corda_sino`, gasta no sino como uma chave).
- **A subida:** pela portinha ao lado da porta, dentro da capela.
- **Contando a ela:** ela fecha a tarefa e diz o que sabe da fumaça na ruína do portão: "Bicho não acende fogo. Tem
  gente vivendo lá." Isso prepara o Bastião.

**A torre por dentro** (`torre_build.py`, `torre.tscn`, `torre.gd`): um poço de 4,4 m de lado e 8,4 m de altura, com a
escada caída no chão.
1. A pedra de contrapeso (`Pushable`) é empurrada uma vez para o norte, até o patamar com a borda de cal (2,4 m).
2. Ele sobe na pedra e dali no patamar.
3. Escala o muro de pedras salientes (3,5 m) até o andar de cima.
4. Uma escadinha leva ao alçapão: "E · subir ao campanário".
- A corda podre pende do alçapão, arrebentada no meio.
- Correções de colisão: o patamar e o alto do muro ganharam caixas sólidas no Godot, porque os colisores do GLB são
  ocos (a pedra atravessava o patamar e ele caía do alto do muro).

**O campanário** (no vilarejo, `vilarejo.gd` `_belfry`):
- **A chegada:** ele sai do alçapão no alto da torre real da capela, a 8,4 m. Os quatro vãos têm paredes invisíveis (cair
  dali mataria).
- **A câmera:** fica perto, por cima do ombro, por baixo do telhado da torre.
- **A neblina abre** (`DayCycle.clear`): lá em cima ela fica embaixo, como uma tampa sobre os telhados, e volta quando ele
  desce.
- **O que se vê:** na primeira vez, ele pensa: "Uma fumaça na ruína perto do portão... e outra lá no morro, a leste."
  - A fumaça da ruína tem o brilho de um fogo embaixo (o Bastião, fase 4).
  - A outra sai da pedreira no barranco leste (fase 7).
  - As fumaças não são cobertas pela neblina e se veem de longe.
- **O sino:** "E · amarrar a corda nova no sino" gasta a corda, e o sino toca. Depois disso, "E · tocar o sino".

**O Ângelus** (`Level.angelus`, Story "sino:corda"):
- Às 6h e às 18h: três badaladas três vezes, e depois nove (cerca de 50 s).
- Soa alto no vilarejo, na torre e na capela, e longe nos outros interiores.
- A Firmina vai para a capela às 6h e às 18h e puxa a corda da nave (animação `Pull`). Volta ao cruzeiro às 6h45 e às 18h45.
- As velas dela continuam no cruzeiro. A rotina ganhou horários com condição (`se` / `sem` uma marca).

**Mudou do plano:** a pedreira foi para o barranco **leste**. Do campanário só se alcança a metade da frente: a viga do
sino corta o meio, e a oeste o telhado da nave tapa a vista. A fumaça da pedreira aparece logo acima do beiral do
campanário: é preciso erguer um pouco o olhar.

**Testes:**
- `test_torre.gd`: a pedra, o patamar, o muro, o alçapão e a volta à capela.
- `test_capela.gd` `sino_tests`: a portinha, a Firmina na corda e o Ângelus.
- `test_vilarejo.gd` `sino_tests`:
  - as falas e a corda do Bento;
  - o campanário: o piso, o alçapão, a neblina, as paredes e o sino;
  - o Ângelus às 18h e a tarefa cumprida;
  - quatro capturas (`v60` a `v62` e `torre_*`).

## Fase 3, feita: a Cida

**A Cida** (`npcs/cida.py`, `npc_cida.glb`):
- **O modelo:** 1,18 m, vestido florido desbotado, tranças com fita vermelha, descalça. Usa a mesma receita dos outros NPCs, com as animações do dia.
- **Onde fica:** num forno de barro atrás da venda (`vilarejo.gd` `OVEN`; cúpula, base e a boca virada para a venda). De dia ela fica sentada na base, junto da boca. De noite fica dentro, sem aparecer.

**A tarefa do Bento** (`QuestData` "pao"):
- **Quando:** depois do alambique ("Perguntar pelo pão"): "Some pão do balaio... Isso aí tem educação."
- **As pegadas:** depois da chuva (`Weather.wet` > 0,25), pegadas pequenas cheias de água, refletindo o céu como as poças, vão dos fundos da venda até o forno. Só aparecem com a tarefa ativa e até ele conhecer a menina.
- **A timidez:** um homem em pé a menos de 9 m e ela some para dentro do forno ("Uma criança? ...Sumiu para dentro do forno."). Ela volta quando ninguém olha.
  - Agachado, ela deixa chegar e conversa. É o agachar, que o jogo já ensinou, usado para ser gentil.
- **A escolha, de volta no Bento:**
  - "Contar da menina no forno": ele se abre. A Odete, mulher dele, subiu em 68 com uma mancha na mão, e "eu deixei levarem". Ele passa a deixar pão e um cobertor, e a venda fica 25% mais barata (`Shop.price`). A Cida depois agradece o cobertor.
  - "Dizer que foi um gato": "Gato que come pão e deixa pegada de gente. ...Tá bom." O segredo dela fica guardado, e ela passa a confiar mais: o esconde-esconde ganha uma quarta rodada.

**A Cida conversa** (`dialogos/cida.gd`):
- quem ela é;
- a voz que imita: "Se alguém te chamar de dentro de uma casa, não abre. Nunca abre. Nem se for a tua mãe." Isso prepara a fase 6;
- o pai e a mãe;
- o esconde-esconde.

**O esconde-esconde** (`vilarejo.gd` `_seek_*`, `QuestData` "esconde", só de dia):
- "Fecha o olho e conta até vinte": a tela escurece um instante e ela some. A pista dela aparece na tela:
  1. "onde a água dorme e ninguém bebe": o cocho do largo;
  2. "onde o homem de palha vigia a estrada": o espantalho;
  3. "onde a casa ainda cheira a fumaça": atrás da casa queimada;
  4. só com o segredo guardado: "onde a gente aprendia a ler": a ruína da sala de aula, onde ficou a lata de figurinhas dela (Cr$ 10, uma vez).
- Ela é achada quando ele chega a menos de 2 m. No fim ela dá **o mapa dela**: uma nota (`mapa_cida`, `tools/texturas/mapa_cida.py`) desenhada a lápis de cor numa folha de caderno.
  - O vilarejo do jeito dela, com "EU" e um coração no forno.
  - Os medos em X vermelho: a ruína do portão, o campo a oeste, a ravina e a casa dela.
  - O mapa não marca nada que se possa ticar como tarefa; marca só os medos dela.

**A casa da professora** (casa 02, a azul da entrada; `professora_build.py`, `professora.tscn`):
- **A chave:** depois do mapa, a Cida dá a chave: "É da casa da Dona Lurdes... Eu não tenho coragem de entrar sozinha."
- **A porta:** a corrente da casa saiu do modelo. Agora é um cadeado (`BlockedDoor`) que a chave abre.
- **Dentro:** a cama arrumada, a escrivaninha com os diários e a lousa, a estante e a foto da turma.
  - O diário de classe (nota `diario_classe`): os nomes dos alunos com "subiu" ao lado, "para o tratamento".
  - O relógio de bolso do marido na mesa de cabeceira (`relogio_bolso`): "Ao meu Tonico. Lurdes, 1960." Pode servir de troca para o mascate.

**Testes:**
- `test_vilarejo.gd` `cida_tests`:
  - a tarefa e as pegadas, que somem no seco;
  - a fuga em pé e a volta escondida;
  - a conversa agachado e a escolha no Bento, incluindo o desconto;
  - as quatro rodadas, o mapa e a lata;
  - a chave, o cadeado e a porta.
- `test_professora.gd`: a casa e o relógio.
- Capturas `v63` a `v67`, com uma das pegadas vistas de cima.
