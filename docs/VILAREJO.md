# Vila de Santa Clara: o vilarejo (versão 1)

*Data: 2026-11-09. Substitui a Colônia (greybox de interiores) como mapa principal da demo.
A Colônia continua no projeto (`colonia.tscn`), e o portão dela fecha o fim da estrada do vilarejo.*

## Ideia

Um vilarejo de serra, anos 1970, no pé do morro onde fica a Colônia Santa Clara. Era quem vendia lenha,
pão e mão de obra para a colônia, e foi esvaziado junto com ela. Hoje: casas fechadas, uma capela,
o largo com o poço, árvores mortas e neblina que deixa ver uns 25 m.

## Layout (cerca de 100 x 100 m jogáveis, terreno de 150 x 150 m)

```
                 N   portão da Colônia (muro, portão tábuado: marco visual, fechado)
                 |
          [casas]|[casas]         subida
                 |
   [cemitério] [capela]--[largo + poço]--[venda/sobrado]     viela leste-oeste
                 |
        [ruína]  |   [casas]      pastos com cerca quebrada
                 |
                 S   chegada: o jogador começa na estrada, vindo do sul
```

- **Estrada de terra** do sul (chegada) ao norte (portão da Colônia), com uma viela leste-oeste no largo.
- **Terreno**: um vale. O centro é quase plano, as bordas sobem em morros que fecham a área (mais
  árvores mortas e rocha no alto). Platôs aplanados sob cada casa.
- **Largo**: poço de pedra, capela com torre do sino (marco visível na neblina), venda de dois andares.
- **Cemitério** atrás da capela: cruzes de madeira e muro baixo.

## Casas (gerador paramétrico, cada uma diferente)

| Tipo | Como é | Variação |
|---|---|---|
| Casa de taipa caiada | 1 piso, paredes brancas sujas, barra pintada embaixo, telhado de telha capa-canal de 2 águas | largura, profundidade, cor da barra, inclinação, chaminé |
| Casa de madeira | tábuas verticais, telhado mais íngreme, alpendre com esteios, sobre pilares de pedra | alpendre sim/não, cor da madeira |
| Sobrado (venda) | 2 pisos, porta larga de comércio, beiral grande | um só, no largo |
| Ruína | paredes caídas pela metade, sem telhado, dá para entrar | uma, perto da chegada |

Todas têm porta, janelas com veneziana (algumas quebradas), fundação de pedra e telhado com beiral.
V1: as casas inteiras são fechadas (sem interior). A ruína é o único "interior".

## Árvores mortas

Gerador de galhos recursivos low poly (troncos de 5 lados, 3 níveis de galhos tortos, sem folhas).
4 variantes, instanciadas cerca de 70 vezes com giro e escala aleatórios: poucas no vilarejo, muitas nas bordas.

## Vegetação (v2)

Peças em `vila_kit.py`, espalhadas por `vegetation()` em `vilarejo_build.py`:
- **Araucárias** (9, nos morros): a morta, pelada, e a seca com tufos escuros nas pontas; tronco alto e os galhos
  subindo em taça, a silhueta de candelabro da serra. Sólidas.
- **Arbustos secos** (3 variações, 40): galhos finos e folhas mortas presas; dá para passar por eles.
- **Capim alto seco** (520 tufos) e **samambaias secas** (70 touceiras, à sombra de árvores, tocos e pedras): planos
  cruzados com transparência recortada, cada tipo fundido num objeto só.
- **Tocos** (12) e **troncos caídos com musgo** (5). Sólidos.
- Texturas novas: `capim_alto`, `samambaia`, `araucaria`, `folhas_secas` (RGBA, recorte), `toco`, `casca_musgo`.

## Objetos de cena (kit)

Cada peça é modelada uma vez na origem (frente = -Y) e instanciada pelo mapa (`props()` em `vilarejo_build.py`),
para servir de kit no jogo final: barril, caixote, pilha de lenha, carroça (inteira e quebrada, com a roda solta),
varal com roupas, espantalho, banco, cocho de pedra, cruzeiro com pano, placa de direção (COLÔNIA / CEMITÉRIO),
placa de boas-vindas, carrinho de mão e meda de feno. Os sólidos têm colisão (`-col`); varal e roda solta, não.

## Moradores (NPCs, só arte por enquanto)

Feitos em `npcs_build.py` com a mesma receita do mutante (`lowpoly.py`): tabela de juntas, partes rígidas,
rosto pintado de 64 px, esqueleto de 16 ossos e um idle de 2 s em loop. Cada um vira `godot_demo/models/characters/npc_<nome>.glb`;
o `scripts/levels/vilarejo.gd` os coloca nos marcadores `npc_<nome>` do GLB do vilarejo, com colisão de cápsula.

| NPC | Papel | Visual | Onde |
|---|---|---|---|
| Seu Bento | vendedor de itens | gordo, careca de franja grisalha, bigodão, óculos, colete e avental, mãos na barriga | atrás do balcão da Venda (interior), ver abaixo; a banca dele fica ao lado da porta |
| Tenório | vendedor de armas | caçador alto de poncho, chapéu de aba larga, cartucheira, espingarda nas costas, olho leitoso com cicatriz | atrás do balcão da Armaria (interior), ver abaixo |
| Dona Firmina | dá a missão | benzedeira idosa e curvada, vestido preto, lenço e xale, terço nas mãos postas | no cruzeiro em frente à capela, velas acesas aos pés (luz quente na neblina) |

Gancho da missão (a definir): o filho de Dona Firmina foi levado para a Colônia.

### Lojas (`scripts/shop/`, dados em `ItemCatalog` e `ShopCatalog`)

- **Quem vende:** Seu Bento e Tenório. Atrás do balcão aparece "E · comprar com <nome>", e a tela de compra abre sobre papel envelhecido, com o jogo pausado.
  - A tela mostra a fala do vendedor, a lista com os preços, a descrição do item escolhido, quantos você tem, o estoque e o seu dinheiro.
  - W/S, as setas ou o mouse escolhem. E, Enter ou o clique compram. Esc ou Tab saem.
- **O que cada um vende** (a moeda é o cruzeiro, Cr$):

  | Vendedor | Item | Preço | Estoque |
  |---|---|---|---|
  | Seu Bento (Secos e Molhados) | atadura (fecha 1 ferimento) | Cr$ 8 | 6 |
  | Seu Bento | garrafada de arnica (fecha 2) | Cr$ 18 | 2 |
  | Tenório (Armas e Munição) | 3 virotes | Cr$ 9 | sem limite |
  | Tenório | 8 virotes | Cr$ 20 | 3 |

- **O inventário** (`Inventory`) continua entre as cenas e volta ao início num jogo novo. O estoque das lojas também.
  - Um jogo novo começa com Cr$ 40, 6 virotes e 1 atadura.
  - Cada recarga da besta tira um virote da aljava. Sem virotes não há recarga, e a mira mostra quantos restam.
  - F usa o primeiro curativo que tiver.
- **Ainda não dá para ganhar dinheiro.** Isso fica para depois, por exemplo com saques, missões ou o corpo dos mutantes.
- **Sons:** moedas no balcão (`compra`) e o pano da atadura (`curativo`), do ElevenLabs.


### As armas: teclas e a roda (Q, `scripts/ui/weapon_wheel.gd`)

- **Teclas:**
  - **1** saca o facão. **2** saca a besta. Apertar de novo guarda a arma.
  - **3**, com uma arma na mão, guarda a arma e volta para a lamparina. Sem arma, pendura a lamparina no gancho do cinto ou a tira de lá (antes era o L).
  - **F** usa o curativo (antes era o X).
  - **Um toque no Q** com uma arma na mão guarda a arma. Segurar o Q abre a roda.
- **A troca é direta:** do facão para a besta ele embainha e depois saca (`Player.equip`). Agachado, ele levanta primeiro.
- **A roda (segurar Q):** o tempo cai para 1/4 e aparece um terço de contas de madeira com o crucifixo pendurado embaixo.
  - Sobre o terço ficam três plaquinhas de madeira com a arma pirografada, como os ex-votos de uma sala de milagres: Facão em cima, Besta à direita e Lamparina à esquerda, cada uma com a sua tecla.
  - O mouse (ou WASD) aponta uma plaquinha, e acende atrás dela uma luz de vela que tremula. No centro aparecem o nome e uma nota (os virotes que restam, na besta).
  - Soltar o Q põe a apontada na mão. Soltar sem apontar não muda nada, a não ser num toque rápido (menos de 0,25 s), que guarda a arma.
  - Uma fitinha vermelha amarrada marca o que ele tem na mão.
  - A roda some se o jogo pausar (notas, loja) ou se ele morrer.
- **Por que um terço:** é a fé popular do lugar (a benzedeira, a capela de Santa Clara, os ex-votos) feita interface. A arte é pixel art em 2x, como as notas e a fonte, gerada por `tools/texturas/roda_armas.py`.
- **Referências que guiaram:** a roda sai do centro e se escolhe arrastando nessa direção, o gesto padrão das rodas de arma. O jogo fica bem mais lento enquanto ela está aberta, como em GTA V e The Witcher 2. E o visual é um objeto do mundo, não um painel de interface, na linha das interfaces diegéticas de Dead Space.

### Combate (`scripts/player/player.gd`)

- **Arma abaixada e arma erguida:** sacada, a arma vai na mão sem estar erguida. Cada arma tem os próprios ciclos de parado, andar, trotar e correr (`Idle/Walk/Jog/Run_Machete` e `_Crossbow`, do `protagonista_rig.py`), com as mesmas pernas da lamparina.
  - O facão vai com o braço esticado para baixo e à frente, como numa caminhada normal, e o punho reto: a mão continua o antebraço, sem dobrar para o lado. A lâmina sai do punho para cima e para a frente e balança com o passo. A lamparina segue na outra mão.
  - A besta vai baixa, com as duas mãos, apontada para o chão à frente. O virote no trilho vem de `Carry_Crossbow[_Empty]`.
  - Assim ele anda, trota e corre como explorando, virando para onde vai, com a câmera normal.
  - **Segurar o botão direito ergue a arma.** O facão sobe na guarda de bloqueio; a besta sobe na mira, com a cruz, a câmera fechada e o passo lento de lado. Só mirando o botão esquerdo dispara.
  - Golpear com o facão ou travar a mira (E) também ergue a arma.
  - Soltar o botão direito abaixa de novo.
- **Stamina:** cada golpe e cada esquiva gastam fôlego, o mesmo da corrida (4 no total):

  | Ação | Custo |
  |---|---|
  | golpe (botão esquerdo) | 0,8 |
  | golpe de cima (botão esquerdo de novo, no fim do golpe) | 1,2 |
  | esquiva (Espaço) | 1,0 |

  - Sem fôlego suficiente, a ação não sai e aparece "Sem fôlego.". Esvaziar a stamina deixa ele sem fôlego, como na corrida.
  - Os custos ficam em `Player.COST`.
- **Bloquear (segurar o botão direito, com o facão):** ele ergue o facão atravessado na frente do rosto (`Block_Loop`) e anda devagar.
  - Um golpe vindo da frente bate no facão: ele recua (`Block_Hit`), o aço soa (`bloqueio`) e só 1/4 do dano passa (`BLOCK_CHIP`). Não gasta stamina. Por isso a vida agora aceita frações.
  - Um golpe pelas costas ou pelo lado entra inteiro.
  - O golpe de cima, que era o botão direito, agora sai pelo combo: botão esquerdo de novo no fim do golpe.
- **Travar a mira (E, com uma arma na mão):** prende a câmera no inimigo mais perto à frente que ele consegue ver, até 12 m.
  - Um losango vermelho fica sobre o inimigo. A câmera vira sozinha e o mouse não a tira dali; ele anda de lado em volta do inimigo, e a besta mira no peito.
  - E de novo solta a trava. Ela também se solta sozinha se o inimigo morrer, passar de 16 m ou se a arma for guardada.
  - Sem inimigo para travar, o E continua usando portas e notas.

## Narrativa ambiental (o que aconteceu aqui, sem uma linha de texto de jogo)

Alguém foi arrastado para a Colônia, e o vilarejo tentou se trancar.

1. **O arrastão:** uma poça de sangue na porta da `casa_04`; marcas de arrasto pelo quintal até a estrada; o rastro
   subindo a estrada, com falhas, pelo largo, até o portão da Colônia, onde ficam marcas de mãos nas tábuas.
2. **O vilarejo trancado:** três casas com a porta pregada em X e acorrentada **por fora**, cadeado; um X vermelho
   pintado ao lado ("aqui tem gente") e arranhões na madeira.
3. **Pichações:** "NÃO SUBAM" no muro da Colônia, "ELES VOLTAM À NOITE" e "DEUS NOS PERDOE" nas paredes caiadas.
4. **A casa queimada:** uma casa de madeira carbonizada, metade do telhado caída, caibros pretos à mostra, entulho.
5. **A ponte caída:** uma ravina corta o sul do mapa atrás da chegada; a ponte da estrada desabou dentro dela (por isso
   ninguém sai). Na estrada, uma mala aberta com roupas espalhadas e uma boneca caída.
6. **A carcaça:** uma vaca morta no pasto, costelas, couro e crânio, com corvos em cima; os corvos crocitam dali.
7. **Os desaparecidos:** cartazes de "PROCURA-SE" no muro da Colônia ao lado do portão, nas paredes, na placa, na cerca.

## Clima

- Neblina exponencial mais neblina de altura no fundo do vale. O céu tem a mesma cor da neblina, então tudo some nela.
- A lanterna do protagonista continua sendo a luz quente da cena.

### O dia e o clima (`scripts/world/world_time.gd`, `weather.gd`, `day_cycle.gd`; dados em `scripts/data/day_data.gd`)

- **Relógio:** 1 segundo real = 1 minuto no jogo, então um dia dura 24 minutos. O relógio continua contando entre as cenas e só para quando o jogo pausa. Um jogo novo começa às 06:30. A tecla **T** avança uma hora, para testar.
- **Períodos:** Madrugada (00:00–05:59), Manhã (06:00–11:59), Tarde (12:00–17:59) e Noite (18:00–23:59). Quando um período começa, o nome e a hora aparecem na tela.
- **Luz:** a luz vem de uma tabela de horários (`DayData.LIGHT`) e passa suavemente de uma linha para a próxima. No teste, a maior mudança em um minuto de jogo é de 1,25%.
  - A luz percorre o dia assim: madrugada quase escura, amanhecer rosado às 6:30, manhã clara, meio-dia, fim de tarde frio, entardecer alaranjado às 18:00 e noite azulada.
  - Uma só luz faz o sol e a lua: de dia o sol sobe e cruza o céu; à noite a lua fica fria e fraca.
- **Clima:** cada período sorteia o próprio clima quando começa (`DayData.CHANCES`).
  - **Chuva:** a chance é de 25% na madrugada, 25% de manhã, 35% à tarde e 30% à noite. Quando sai, começa em algum momento do período e dura de 40 a 180 minutos de jogo. Uma chuva que já caía continua até o fim.
  - **Névoa:** toda manhã tem névoa. Nos outros períodos a chance é de 60% na madrugada, 30% à tarde e 45% à noite. Sem névoa, o ar fica limpo.
- **Transições:** nada muda de uma vez.
  - A chuva leva 12 minutos de jogo para engrossar ou parar. A garoa e o som dela acompanham.
  - A névoa leva 45 minutos para chegar ou levantar. Os bancos de neblina engrossam com ela, e a densidade do fog muda de 0,028 a 0,075.
  - Com chuva, o céu e o ambiente escurecem e o sol fraqueja. De dia, a névoa clareia o céu.
  - As poças se enchem em 20 minutos de chuva e secam em 4 horas. Os anéis dos pingos só aparecem enquanto chove.
  - As silhuetas das serras e da Colônia acompanham a cor do céu.
- **Interiores:** a luz das janelas segue a hora: cinza de dia, quase apagada e azulada à noite, mais fraca num dia de chuva. Os vidros escurecem junto, e a chuva se ouve abafada no telhado.
- **Para mudar:** horários, cores e chances são só números em `DayData`. Para outra fase ter o ciclo, basta uma linha: `DayCycle.outdoors(...)` ou `DayCycle.indoors(...)`. Hoje a Colônia e a sala de treino continuam com a noite fixa.

### Acabamento (`vilarejo_build.py`: `stains()`, `bake_ao()`, `ridge()`, `colony()`)

- **Sombreamento por cor de vértice.** A oclusão ambiente é calculada no build com 17 raios por canto de face, até 2,5 m, e vai na cor dos vértices (COLOR_0). O Godot multiplica essa cor sobre as texturas.
  - Escurece a base das paredes, os cantos, o que fica debaixo dos beirais e varandas, e o chão em volta das casas, árvores e objetos.
  - Malhas compartilhadas do kit (objetos, árvores) não recebem a cor, porque uma cor só não serve para todas as cópias. Mesmo assim elas fazem sombra no chão.
- **Manchas por cima das superfícies.** São decais com alfa suave, em 4 níveis como no N64, geradas pelo `scenery_textures.py`.
  - `umidade`: subindo do chão pelas paredes caiadas e pelo muro da Colônia.
  - `musgo`: na pedra da fundação, nos cantos.
  - `escorrido`: sujeira descendo dos peitoris, em cerca de 60% das janelas.
  - `rachadura`: no reboco.
  - Cada casa sorteia as suas manchas com uma semente própria, sem mudar o resto da casa. A casa queimada não tem.
- **Silhuetas além da neblina.** São duas serras em anel em volta do vale, a perto com araucárias recortadas na crista. Assim o mapa não termina no cinza.
- **A Colônia por cima do muro.** São dois pavilhões, o primeiro com torre do relógio, a usina com a chaminé, uma torre de vigia junto ao portão e araucárias.
  - Há duas janelas acesas, que tremulam, uma na torre do relógio e outra na de vigia. É o objetivo visual da estrada.
- As silhuetas são formas lisas, sem textura. O `scripts/levels/vilarejo.gd` dá a elas um shader sem sombreamento e fora da neblina do motor, com a própria névoa:
  - a Colônia fica mais escura, a serra perto mais clara e a longe mais clara ainda;
  - a névoa engrossa no pé delas.

### Vida e clima (`godot_demo/scripts/world/clima.gd`, `godot_demo/scripts/world/corvo.gd`)

Tudo segue um vento só: desce da Colônia, ao norte, em direção à ravina.

- **Garoa fina.** São riscos finos que caem em volta do jogador, um pouco inclinados pelo vento.
  - Um campo de altura acompanha a câmera, então a chuva some ao bater no chão, nos telhados e nos beirais. Debaixo de uma varanda não chove.
  - O som é o loop `garoa`.
- **Poças.** São 18, espalhadas pela estrada, só em chão plano.
  - São escuras e lisas, com anéis dos pingos.
  - A lamparina brilha nelas, e em ângulo baixo refletem o céu encoberto.
- **Neblina que anda.** São 46 bancos de névoa, cartões grandes e macios virados para a câmera, apoiados no chão e mais densos embaixo.
  - Descem o vale a 0,6 m/s e voltam a entrar pelo muro da Colônia.
  - Ficam mais suaves onde cortam o chão e quando o jogador passa por dentro deles.
- **Folhas e cinzas.**
  - Folhas secas são levadas pelo vento em volta do jogador, giram nas rajadas e ficam onde caem.
  - Da casa queimada (casa_11) sobem cinzas e algumas brasas ainda acesas.
- **Corvos vivos.** São 9 corvos: 4 na carcaça, 2 nos braços do espantalho e 3 na estrada, bicando o rastro de sangue.
  - Pousados, bicam, olham em volta e dão pulinhos.
  - Fogem a 7 m do jogador. Agachado, dá para chegar a 3 m.
  - Quando um foge, o bando vai junto, com som de asas e às vezes um grasnado, e some na neblina.
  - Voltam ao poleiro quando o jogador está longe.
  - O build exporta o corpo e uma asa como modelos (`corvo_corpo` e `corvo_asa`) e os poleiros como marcadores (`corvo_NN`).
- Os sons `garoa` e `asas` foram sintetizados com `clima_sons.py`, sem gastar créditos do ElevenLabs.

## Técnica

- `vilarejo_build.py` (Blender em modo background): gera terreno, casas, árvores, props; UV planar por
  face na escala do mundo (como o triplanar da Colônia); exporta `godot_demo/models/levels/vilarejo.glb`.
- Colisão pelo sufixo do nome no Blender: `-col` (terreno, casas, cercas, objetos) e `-colonly` (troncos das árvores).
- `godot_demo/scripts/levels/vilarejo.gd`: carrega o GLB, filtra as texturas como N64 (nearest), neblina, luz, navmesh
  em tempo de execução (célula de 0,25 m, rampas até 40°), o jogador na chegada e um mutante no largo.
- Texturas novas em `scenery_textures.py`: capim seco, lama da estrada, telha, caiação, tábua vertical,
  janela, veneziana, porta, rocha; e para os objetos: pano, estopa, feno e as placas pintadas.

## Interiores (decisão do autor)

A maioria dos interiores será uma **cena separada**, como nos Zeldas antigos: a porta da casa leva a outra cena e
volta para a frente dela. Por isso as casas por fora continuam fechadas; as portas viram os pontos de entrada.

### Primeiro interior: a Armaria do Tenório

- **Fora:** a `casa_08` (madeira vermelha com alpendre, viela leste) virou a loja: placa "ARMAS E MUNIÇÃO" pendurada
  no alpendre, a mesa de armas dele no alpendre, a carroça encostada. Marcador `porta_armaria` ao pé da escada.
- **Dentro** (`armaria_build.py` -> `armaria.glb`, cena `armaria.tscn`): 8 x 6,5 m (maior por dentro, como nos jogos
  antigos, para a câmera caber). Balcão com o Tenório, lamparina, munição, revólver, facas, livro de contas, virotes;
  na parede do fundo três espingardas, facões, machados e um troféu de veado mutado (três órbitas, galhada torta);
  prateleiras, armadilha de urso, couro esticado, fogão a lenha com brasa, barris, caixotes, sacos, tapete,
  lampião no meio; a porta trancada de um depósito com uma mancha escura no chão.
- **Porta (estilo Zelda):** E ao pé da escada entra (fade para preto); E na porta de dentro devolve você à escada da
  loja. O vilarejo recarrega ao voltar (o mutante volta ao largo).
- O kit (materiais, construtor, peças) agora mora em `vila_kit.py`, usado pelo vilarejo e pelos interiores.

### Segundo interior: a Venda do Seu Bento

- **Fora:** o sobrado do largo (`casa_07`, "SECOS E MOLHADOS"); a banca saiu da frente da porta para o lado.
  Marcador `porta_venda`.
- **Dentro** (`venda_build.py` -> `venda.glb`, cena `venda.tscn`): 9 x 7 m, caiada sobre barra verde como por fora.
  Balcão comprido com balança, potes de bala, o livro de fiado e lamparina; prateleiras até o teto com garrafas, latas
  e pacotes (com falhas: coisas que nunca voltaram), escada de mão; sacos abertos de arroz, feijão, café e milho com
  conchas; tambor de querosene com bomba; queijos sobre um barril; barril de cachaça no cavalete; linguiça e alho
  pendurados na viga; baldes, corda e lampião; canto do bar com mesa, cadeiras, garrafa, copos e um tabuleiro de damas;
  calendário de março de 1974; rádio; oratório com santo e vela. A escada para os quartos da família está pregada,
  com placa "PARTICULAR", e o teto se abre no escuro sobre ela. Junto à porta, um mural de cartazes "PROCURA-SE".
- Base comum: `vila_kit.Room` (casca da sala) no Blender e `scripts/levels/interior.gd` no Godot (luzes pelos marcadores
  `luz_<tipo>`, NPC, porta, teste e planta). A Armaria usa as mesmas.

### Terceiro interior: a Capela de Santa Clara

- **Fora:** a porta é a da torre, de frente para o largo e o cruzeiro (onde fica Dona Firmina). Marcador `porta_capela`.
- **Dentro** (`capela_build.py` -> `capela.glb`, cena `capela.tscn`): nave de 7 x 13 m e 5 m de pé-direito, ladrilho
  hidráulico, cal sobre barra azul, três janelas altas de cada lado, Via-Sacra no alto. Bancos em duas fileiras (alguns
  tortos, um tombado de costas). Presbitério num degrau atrás da grade de comunhão: altar com toalha, crucifixo e
  castiçais; retábulo azul e dourado com Santa Clara (hábito, véu, ostensório) no nicho do meio e dois santos menores.
  No corredor, um velório que ficou pela metade: caixão em cavaletes com a tampa fora do lugar e quatro castiçais
  altos acesos. Velário com dezenas de velas, tábua de ex-votos de cera (cabeças, mãos, pernas, coração, fotos, fitas),
  pia de água benta e a corda do sino. Ninguém lá dentro (o NPC dos interiores agora é opcional).
- Mais escura que as lojas (`AMBIENT`, `DIM` em `scripts/levels/interior.gd`); perto do jogador manda a lanterna dele.

## Sons

Gerados no **ElevenLabs** (fluxo "Vila de Santa Clara — sons", efeitos com `eleven_text_to_sound_v2`; loops com a
opção de loop sem emenda do modelo). O jogo **não terá dublagem**: a reza da Dona Firmina é um murmúrio sem palavras.
Os MP3 baixados ficam em `audio_fontes/elevenlabs/`; `tools/sons/sounds_import.py` (ffmpeg) converte para `godot_demo/sounds/*.wav`
(mono 44,1 kHz, pico por tipo, passos começando no impacto, relógio remontado num tique-taque regular). Versões não
usadas em `audio_fontes/elevenlabs_extra/` (o uivo e o murmúrio alternativos, a Ave-Maria falada). Os sons sintetizados
antigos (`sounds_build.py`) ficaram em `audio_fontes/sintetizados/` como reserva. Prévias: `renders/sons/sons_previa.wav` e
`renders/sons/sons_interiores_previa.wav`.

- **Vilarejo:** vento em loop; Dona Firmina murmura uma reza (só de perto); de tempos em tempos corvos nas árvores
  em volta, um cachorro uivando longe para os lados da Colônia, rangidos na placa da armaria e nos varais, e o sino da
  capela dobrando três vezes, sem ninguém para tocar.
- **Interiores:** zumbido de casa com o vento abafado; o fogão (armaria), o relógio de parede (venda), velas (venda e
  capela) e um coro distante quase inaudível (capela).
- **Música da venda:** um loop de 15 s de viola caipira lenta, em tom menor, saindo do rádio da prateleira (som
  posicional, marcador `som_musica_venda`), com o rádio falhando: faixa de AM, chiado e estalos, a sintonia oscilando
  e três quedas em que a música some na estática (`failing_radio` em `sounds_import.py`, local, sem créditos). Feita com o modelo de efeitos sonoros: o conector do ElevenLabs desta
  sessão não tem modelo de música (para isso, o conector completo em https://api.elevenlabs.io/v1/mcp).
- **Passos** por piso (terra, madeira, ladrilho; 4 de cada), mais baixos agachado e mais pesados correndo; a **porta**
  range e bate quando você passa por ela.
- **O protagonista** (`scripts/player/player.gd`, `sfx()`; 2026-11-10):
  - **facão:** sacar e guardar; o golpe corta o ar pouco antes de acertar (3 takes, o golpe de cima mais grave); acertar alguém faz um som de corte na carne (2 takes);
  - **besta:** sacar e guardar no coldre; recarregar (corda puxada, trava, virote no trilho, no tempo da animação); disparar;
  - **lamparina:** tirar e pendurar no gancho;
  - **bloqueio:** garras batendo no facão erguido, um tinido seco de aço (2 takes);
  - **dano:** um golpe na carne, o casaco rasgando e o fôlego cortado, sem voz (2 takes);
  - **vida baixa:** com 1/3 da vida, o coração bate forte, em loop, junto com a respiração pesada. Os dois param na morte (`PlayerCondition`).
- **O mutante** (`Enemy.voice`, que qualquer criatura pode usar; a Enfermeira continua muda):
  - grunhidos de vez em quando, parado ou perseguindo (3 takes);
  - o grito ao ver você;
  - o rosnado do golpe e o guincho quando apanha (2 takes cada);
  - o gemido e a queda ao morrer;
  - um passo pesado a cada 0,64 m andado (2 takes).
- **Chuva:** um loop de 20 s do ElevenLabs (chuva fina em terra, folhas e telhas, pingos dos beirais) no lugar da `garoa` sintetizada, que fica como reserva.
- **Variações:** um som com takes (`<nome>_1`, `_2`...) é sorteado a cada vez (`Audio.pick`), com o tom variando um pouco.
- Código: `scripts/core/audio.gd` (`play2d`, `play3d`, `pick`, `fade`), `scripts/world/footsteps.gd`,
  `scripts/levels/vilarejo.gd` (`_ambience`), `scripts/levels/interior.gd` (`drone`, marcadores `luz_*` e `som_*` que soam).

## Fica para depois

- Mais interiores (casas, a ruína), a Colônia atrás do portão; o andar de cima da venda.
- Música; mais mutantes.
- Kit modular reaproveitável para o jogo final.
- Melhorias artísticas pendentes: ver [TODO_ARTE.md](TODO_ARTE.md).
