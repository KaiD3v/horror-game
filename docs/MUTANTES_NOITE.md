# Os mutantes da noite

São três mutantes que só saem à noite no vilarejo, das 18:00 às 05:59 (Noite e Madrugada). De dia o vilarejo continua como está, só com o Interno no largo.

Quem sai depende do que o jogador já tem (`vilarejo.gd` `roster()`, ver [TUTORIAL_VILAREJO.md](TUTORIAL_VILAREJO.md)):
sem o facão, uma Bruxa; com o facão, as duas Bruxas e o Poceiro; com a besta, também a Carpideira.

## Análise

À noite, no vilarejo, o jogador enxerga pouco: a névoa é azulada, a lua é fraca e a única luz forte é a lamparina. Por isso os três mutantes foram desenhados em torno dos sentidos de quem caça no escuro:

- **luz:** a lamparina na mão ilumina, mas também chama;
- **som:** correr e lutar fazem barulho;
- **vista:** alguém pode dar o alarme.

Cada um pede uma resposta diferente do jogador, e as respostas se atrapalham. É daí que vem a tensão.

Outra regra: nenhum deles anda como gente. O Interno e a Enfermeira caminham em pé pelas ruas. Os da noite usam o que a noite oferece: telhados, poço e escuro.

| | Sentido | Onde fica | O que o jogador faz | O que custa |
|---|---|---|---|---|
| **A Bruxa** (feita) | luz | nas cumeeiras dos telhados | pendura a lamparina no cinto | passa a enxergar pouco |
| **O Poceiro** (feito) | som | sai do poço do largo | anda agachado, não corre, evita lutar | fica lento perto dele |
| **A Carpideira** (feita) | vista | anda pelas vielas com uma vela | mata em silêncio (besta) ou se esconde | se ela grita, chama os outros dois |

Os três se cruzam. Com a lamparina guardada, a Bruxa não acha o jogador, mas ele também não vê a Carpideira chegando. Correr da Bruxa acorda o Poceiro. A vela da Carpideira é a única outra luz no vilarejo à noite, e a Bruxa também vai atrás dela.

## A Bruxa (feita)

"Bruxa" é o nome que se dá no interior à mariposa preta grande, a que entra pela janela e anuncia morte na casa. Esta foi a mulher levada da casa 4, a da pichação "ELES VOLTAM À NOITE" e do rastro de arrasto até a Colônia. Ainda veste os restos da camisola.

### Visual (`tools/personagens/bruxa_build.py`)

- Mede 1,94 m com as antenas. É magra até o osso, corcunda, de pele cinza-parda coberta de pó.
- **Os braços viraram asas.** Três dedos-osso saem de cada pulso em leque, e uma membrana empoeirada vai deles até as coxas.
  - Cada asa tem uma **mancha em forma de olho**, como a da mariposa: anel preto, anel ocre e centro escuro.
  - A borda de trás é recortada entre os dedos.
- **Olhos enormes e pretos que devolvem a luz.** O material `b_brilho` é emissivo. No jogo ele brilha forte quando a lamparina na mão está a até 22 m.
  - De longe, a primeira coisa que o jogador vê é um par de pontos acesos numa cumeeira.
- Antenas de pluma, língua enrolada, gola de pelo grosso como a de mariposa e trapos da camisola de algodão manchada.
- O modelo tem 1390 triângulos e 16 ossos, no mesmo kit do Interno e da Enfermeira (`lowpoly.py`).
  - A membrana é pesada vértice a vértice, entre o braço e o corpo, para dobrar junto com as asas.
- Animações:
  - `Idle`: empoleirada, agachada e enrolada nas asas como numa capa; a cabeça gira devagar e estala uma vez.
  - `Alert`: a cabeça se ergue para a luz e as asas se abrem.
  - `Fly`: o planeio, inclinada para a frente, com uma batida lenta e as pernas para trás.
  - `Walk`: corre de quatro, apoiada nos pulsos e nos pés, com as asas dobradas nas costas. Faz 3,5 m/s em 1x.
  - `Attack`: empina com as asas abertas e rasga para baixo com as duas garras no quadro 10.
  - `Hit`: é jogada para trás e as asas abrem num tranco.
  - `Death`: cai de costas e encolhe pernas e asas, como mariposa morta.
- Renders: `renders/bruxa/` (frente, ¾, lado e costas; um quadro sim, outro não de cada animação).

### Comportamento (`godot_demo/scripts/enemies/bruxa.gd`, estende `Enemy`)

- **Chegada:** ao anoitecer (18:00), duas Bruxas pousam em cumeeiras a mais de 12 m do jogador.
  - As cumeeiras são achadas por um raio sobre cada `casa_NN` do vilarejo. As ruínas não têm telhado e ficam de fora.
  - Os corpos da noite anterior somem nessa hora.
- **A luz chama:**
  - com a lamparina na mão, ela vem de até **22 m**, desde que tenha linha de vista do telhado;
  - com a lamparina no cinto, só a **2,5 m**.
  - Ao ser chamada, ela se vira e encara a luz por 1,5 s, com os olhos acesos. Depois estala, abre as asas e plana até um ponto do navmesh a 4 m do jogador.
- **Em volta da luz:** no chão, ela circula a 4 m, fora do alcance, a 2,6 m/s, como mariposa em volta do lampião.
  - A cada 2 a 4 s, mergulha em linha reta a 5 m/s e rasga (1 de dano).
  - Depois do golpe fica parada 0,8 s, e essa é a janela para contra-atacar.
  - Ela é mais rápida que a corrida (2,6 m/s): fugir não adianta.
- **Apagar a luz:** com a lamparina pendurada e a mais de 2,5 m, ela perde o jogador.
  - Durante 6 s, ela ronda o lugar onde a luz sumiu. Quem fica parado ali é achado de novo.
  - Depois disso, voa de volta para a cumeeira livre mais próxima.
- **Vida:** 3. O golpe lateral tira 1, o golpe por cima 2, e um virote mata.
  - Atingida no ar, ela cai.
  - Atingida no telhado, ela desce planando em cima do jogador.
- **Amanhecer** (06:00): as que estão vivas voam para o norte, por cima da Colônia, e somem.
- **A Carpideira:** a vela dela também a chama, e ela circula em volta sem mergulhar. O grito dela a faz voar até onde está o jogador (`call_to`).
- **Sem passos.** Os avisos são:
  - o farfalhar das asas enquanto voa e corre;
  - estalos secos ao ver a luz, de vez em quando no telhado e antes de cada mergulho.

### Sons

Todos vêm do ElevenLabs (flow "Vila de Santa Clara — sons", modelo de efeitos sonoros), convertidos por `tools/sons/sounds_import.py`; os MP3 ficam em `audio_fontes/elevenlabs/`. Ela não fala.

- `bruxa_asas` (loop): asas de mariposa grandes e empoeiradas batendo devagar.
- `bruxa_estalo_1..2`: rajadas de cliques secos, de inseto, na garganta.
- `bruxa_guincho`: um guincho fino e rascante que desce, quando ela é ferida ou morre.

### Testes (`vilarejo.tscn -- --autotest`, `bruxa_tests`)

Os testes conferem que:
- de dia não há Bruxa;
- ao anoitecer, duas pousam em cumeeiras;
- os olhos brilham com a lamparina na mão;
- a luz a chama: ela estala, sai do telhado e plana até a luz;
- ela circula e mergulha até acertar o jogador;
- com a lamparina no cinto, ela perde o jogador, ronda e volta para um telhado;
- um virote a mata;
- ao amanhecer, ela vai embora.

Capturas: `captures/demo_v30_bruxa_telhado.png`, `demo_v31_bruxa_voo.png` e `demo_v32_bruxa_ataque.png`.

### Para o autor testar no jogo

- O alcance de 22 m e o raio de 4 m: se ela vem cedo ou tarde demais.
- O ritmo dos mergulhos (2 a 4 s) e a janela de 0,8 s para contra-atacar.
- Se apagar a luz salva fácil demais, ou se os 6 s de ronda bastam.
- Se os sons do ElevenLabs servem.
- Se duas Bruxas por noite é o número certo (`BRUXAS` em `vilarejo.gd`).

## O Poceiro (feito)

O homem que cavou o poço do largo, desceu e ficou lá embaixo. É ele quem puxa os baldes de volta à noite.

### Visual (`tools/personagens/poceiro_build.py`)

- Mede 2,16 m e é corcunda, com ombros enormes, braços longos e mãos do tamanho de pás.
- **É cego.** A pele cresceu por cima dos olhos e só restaram duas covas com uma cicatriz. Tem orelhas grandes e rasgadas, e a cabeça está sempre inclinada, escutando.
- A pele é pálida e encharcada, com limo verde. A boca fica frouxa, com poucos dentes.
- Veste um macacão de trabalho podre e botas de borracha até o joelho.
- Leva uma corda na cintura com um **balde de lata** no quadril direito. É o aviso dele: o balde bate e a água chacoalha a cada passo, como as chaves da Enfermeira.
- O modelo tem 1364 triângulos e 16 ossos, no mesmo kit dos outros.
- Animações:
  - `Idle`: parado, escutando; a cabeça pende para um lado e depois para o outro, e a respiração é pesada.
  - `Listen`: congela com um som, vira a cabeça para ele e ergue a mão perto da orelha.
  - `Walk`: passada pesada e cambaleante; faz 1,68 m/s em 1x.
  - `Attack`: junta os punhos no alto e desce como uma marreta no quadro 20.
  - `Hit`: é jogado para trás.
  - `Death`: os joelhos cedem e ele cai de cara.
  - `Climb`: sobe (ou desce) a parede do poço, uma mão por cima da outra.
- Renders: `renders/poceiro/` e a folha `renders/poceiro/poceiro_folha.png`.

### Comportamento (`godot_demo/scripts/enemies/poceiro.gd`, estende `Enemy`)

- **Chegada:** ao anoitecer, ele sobe pelo poço do largo com a água escorrendo, sai pela borda e fica de pé ao lado.
- **No amanhecer**, volta ao poço e desce. Se morrer, o corpo some na noite seguinte.
- **Caça só pelo som.** Luz e vista não contam. A cada quadro ele ouve o jogador até uma distância que depende do que o jogador faz:

  | O que o jogador faz | Ouvido até |
  |---|---|
  | correndo | 16 m |
  | trotando (o passo normal) | 9 m |
  | andando (Ctrl) | 4 m |
  | agachado andando | 1,5 m |
  | parado | 1,2 m (é a distância em que ele sente o jogador) |
  | golpe, virote, bloqueio, esquiva ou dano | 14 m |

- **Vai até o som, não até o jogador.** Ao ouvir algo, ele urra, vira a cabeça e anda até o lugar do barulho a 1,9 m/s, mais rápido que o trote e mais lento que a corrida.
  - Se o jogador se cala e se afasta, ele chega ao lugar, escuta por 3 s e volta a vagar em volta do poço.
- **De perto, ele sente o jogador mesmo parado.** O golpe de dois punhos tira **2** de vida.
- **Vida:** 10. Ser atingido conta a ele onde o jogador está. É melhor passar por ele do que lutar.
- **O sino da capela**, que ninguém toca, faz ele ir até a porta da igreja.
- A luta contra a Bruxa faz barulho: golpes e dano chamam o Poceiro.
- O grito da Carpideira faz ele ir até onde está o jogador.

### Sons

Todos vêm do ElevenLabs (flow "Vila de Santa Clara — sons", modelo de efeitos sonoros), convertidos por `tools/sons/sounds_import.py`; os MP3 ficam em `audio_fontes/elevenlabs/`.

- `poceiro_balde` (loop): o balde de lata batendo e a água, a cada passo.
- `poceiro_respira`: respiração molhada, com bolhas.
- `poceiro_rugido_1..2`: um urro grave e encharcado, quando ele ouve, golpeia ou é ferido.
- `poceiro_queda`: a queda na morte.
- `poceiro_agua`: a água escorrendo quando ele sai do poço ou desce de volta.
- Os passos usam o `mutante_passo` do Interno.

### Testes (`vilarejo.tscn -- --autotest`, `poceiro_tests`)

Os testes conferem que:
- ao anoitecer, ele sobe pelo poço e fica ao lado;
- agachado e parado a 5 m, o jogador não é ouvido;
- uma corrida a 14 m é ouvida e ele urra;
- ele vai até o lugar do som (e não até o jogador) e escuta;
- de perto, o golpe tira 2;
- ser atingido conta onde o jogador está;
- o sino o leva até a igreja;
- no amanhecer, ele desce o poço.

Capturas: `captures/demo_v33_poceiro_poco.png` e `demo_v34_poceiro_golpe.png`.

### Para o autor testar no jogo

- As distâncias de audição e se o trote (9 m) deixa explorar com ele por perto.
- Se 2 de dano por golpe é pesado demais (`attack_damage`).
- Se os sons do ElevenLabs servem, e se o balde soa no ritmo dos passos.
- A ideia da nota que fala dele ("os baldes voltam cheios de manhã") continua em aberto.

## A Carpideira (feita)

É a carpideira dos velórios do sertão, a mulher que se paga para chorar o morto e que nunca mais parou. Anda pelas vielas de luto, de véu preto, com uma vela de igreja nas mãos.

### Visual (`tools/personagens/carpideira_build.py`)

- Mede 1,83 m. É magra, vestida de preto até o chão, com o corpete abotoado até o pescoço e a saia em sino rasgada na barra.
- **Véu de renda preta:** cobre a cabeça e os ombros e cai pelas costas até a cintura. É aberto só no rosto.
- **A vela:** é uma vela grossa de igreja, segura com as duas mãos na altura do peito.
  - A cera escorreu pelos dedos e grudou as mãos nela.
  - A chama tem material emissivo (`c_chama`).
  - Um terço pende da mão esquerda até o joelho.
- **O rosto, aceso por baixo pela vela:**
  - olhos enormes e sem pálpebra, porque ela não consegue fechá-los: é ela quem vê;
  - as bordas dos olhos são vermelhas de tanto chorar, e lágrimas de cera escorrem pelas bochechas;
  - a mandíbula é comprida, num osso próprio, e cai até o peito quando ela grita.
- O modelo tem 1540 triângulos e 17 ossos (16 mais a mandíbula), no mesmo kit dos outros.
  - Os vértices da saia são pesados um a um: no quadril em cima e nas pernas embaixo, cada lado na sua perna.
- Animações:
  - `Idle`: parada, chorando; os soluços sacodem os ombros e a cabeça balança sobre a vela.
  - `Walk`: passo de procissão, lento e curto; o vestido desliza e a vela fica parada. Faz 0,78 m/s em 1x.
  - `Notice`: viu o jogador; a cabeça se ergue e vira, o corpo se inclina e a vela vai para a frente.
  - `Scream`: joga a cabeça para trás, a mandíbula cai e a vela sobe por cima da cabeça.
  - `Hit`: é jogada para trás.
  - `Death`: os joelhos cedem, ela se dobra sobre a vela e tomba de lado.
- Renders: `renders/carpideira/` (frente, ¾, lado e costas; um quadro sim, outro não de cada animação).

### Comportamento (`godot_demo/scripts/enemies/carpideira.gd`, estende `Enemy`)

- **Chegada:** ao anoitecer, ela começa numa viela a mais de 18 m do jogador.
  - As vielas são os pontos do navmesh ao lado de cada `casa_NN`.
  - Ela anda de uma viela para outra a 0,8 m/s e para de 4 a 9 s em cada uma.
- **Ouve-se antes de se ver:**
  - o choro toca em loop e é ouvido até 35 m; a névoa deixa ver uns 25 m;
  - a cada 18 a 35 s, o choro vira um **choro de criança** por 4 s, para atrair o jogador.
- **A vela é a única outra luz do vilarejo à noite.**
  - É uma luz de 6 m presa à mão dela; ilumina o rosto e acompanha a vela no grito.
  - Dá para vê-la de longe e desviar.
  - **A Bruxa também vai atrás dela:** se a vela está à vista de uma cumeeira, a Bruxa desce e circula em volta, como mariposa, sem mergulhar.
  - A lamparina do jogador na mão, ou ele chegar a menos de 2,5 m, tira a Bruxa da vela.
  - Se a vela apaga, a Bruxa volta para o telhado.
- **É ela quem vê,** só na frente dela (cerca de 66° para cada lado), sem nada no caminho, e até uma distância que depende do jogador:

  | O jogador | Visto até |
  |---|---|
  | lamparina na mão | 20 m |
  | lamparina no cinto, em pé | 8 m |
  | lamparina no cinto, agachado | 4 m |

  - Por trás ela não vê nada, nem a lamparina.
- **O grito:**
  - quando vê o jogador, ela suspira, para e o encara;
  - depois de 1,2 s olhando, **grita**; se o jogador sai da vista antes, ela se acalma e volta a chorar;
  - o grito (até 120 m) chama os outros dois para onde o jogador está: o Poceiro ouve o lugar, e as Bruxas voam até lá e rondam por 6 s;
  - depois ela segue o jogador de longe, a 1,5 m/s (o trote, a 1,66 m/s, ganha distância devagar; a corrida, rápido) e para a 4 m dele;
  - enquanto ainda vê o jogador, grita de novo a cada 6 s;
  - se fica 6 s sem vê-lo, volta a chorar.
- **Não ataca.** É fraca, com vida 2:
  - um virote ou um golpe por cima a matam;
  - qualquer golpe **por trás** a mata antes do grito;
  - um golpe lateral pela frente tira 1, e ela grita;
  - morta, a vela apaga.
- **Amanhecer:** ela anda até a porta da capela e entra. O corpo de quem morreu some na noite seguinte.

### Sons

Todos vêm do ElevenLabs (flow "Vila de Santa Clara — sons", modelo de efeitos sonoros), convertidos por `tools/sons/sounds_import.py`; os MP3 ficam em `audio_fontes/elevenlabs/`. São choro e grito sem palavras: o jogo continua sem dublagem.

- `carpideira_choro` (loop, 10 s): uma mulher chorando o morto, em soluços e lamentos.
- `carpideira_crianca`: o choro baixo de uma criança no escuro.
- `carpideira_suspiro`: a respiração puxada quando ela vê o jogador, ou quando é atingida.
- `carpideira_grito_1..2`: um grito agudo, que sobe, áspero, a voz quebrando.
- `carpideira_queda`: a queda na morte e a vela rolando.
- Não tem passos: o vestido desliza.

### Testes (`vilarejo.tscn -- --autotest`, `carpideira_tests`)

Os testes conferem que:
- ao anoitecer, ela começa longe, com a vela acesa;
- anda chorando, e o choro vira choro de criança;
- a vela dela tira uma Bruxa do telhado, e a Bruxa circula em volta sem mergulhar;
- por trás, nem com a lamparina ela vê;
- pela frente, a 6 m, agachado no escuro, ela não vê;
- em pé, a 6 m, ela vê e suspira;
- se o jogador sai da vista antes do grito, ela volta a chorar;
- quando ela grita, o Poceiro ouve onde o jogador está e as Bruxas voam até lá;
- ela segue o jogador e desiste fora da vista;
- um golpe pela frente só a faz gritar, e um golpe por trás a mata e apaga a vela;
- no amanhecer, ela entra na capela.

Capturas: `captures/demo_v35_carpideira_vela.png` e `demo_v36_carpideira_grito.png`.

### Para o autor testar no jogo

- As distâncias de visão (20, 8 e 4 m) e o 1,2 s antes do grito: se dá tempo de se esconder ou atirar.
- Se ela seguindo e gritando a cada 6 s pesa demais com os outros dois chegando.
- Se dá para chegar por trás dela para matar, e se isso é fácil demais.
- Se o choro de criança engana e se os sons do ElevenLabs servem.
- Se uma Carpideira por noite basta.
