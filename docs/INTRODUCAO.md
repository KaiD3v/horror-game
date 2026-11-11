# A cutscene de introdução

*Data: 2026-11-11. Implementada (`scripts/ui/intro.gd`, classe `Intro`), com as recomendações do plano.
As diferenças do plano estão em "Como ficou", no fim.*

## O que ela precisa responder

1. **Por que ele veio.** Recebeu uma carta da mãe, que lhe disseram ter morrido em 1959.
2. **O que aconteceu com ele.** Chegou por baixo, pela ravina, porque a ponte já tinha caído. Na subida, a viga em
   que ele se apoiou cedeu atrás dele, e agora não tem volta.
3. **O que aconteceu aqui.** Isso só é insinuado, porque o resto o jogo conta pelas notas:
   - a ponte foi serrada, e não caiu sozinha;
   - a vila está vazia;
   - lá em cima a Colônia tem luz acesa.

Tudo vale para o que o jogo já diz:
- premissa A de [CENARIOS.md](CENARIOS.md): ele procura a mãe, internada quando ele era criança, e ele viveu no
  preventório;
- março de 1974 (o calendário da venda e o diário de 14 e 15 de março);
- o ofício nº 117/74 ("Quem tem parente internado aguarde comunicação");
- o bilhete do Tonho ("a ponte caiu... ouviu serrarem as vigas");
- a venda abastece a Colônia de noite.

## A história por trás (o que o jogador fica sabendo)

- Ele nasceu na Colônia por volta de 1950. Filhos de internos eram tirados dos pais e criados no preventório, como
  aconteceu de fato nas colônias brasileiras.
- Aos 9 anos o mandaram para a cidade, junto com um papel da Colônia que comunicava a morte da mãe.
- Em fevereiro de 1974 chega uma carta com a letra dela. O carimbo é da *Agência Postal da Vila de Santa Clara*: alguém
  pôs no correio por ela. Fica um gancho para o Seu Bento dizer, mais tarde, que foi ele.
- A carta é curta e assustada. Ela está viva, não deixam ninguém sair, e "depois de março não vai ter mais ninguém para
  buscar". Ela assina só "tua mãe". Quem ela é fica para o fim: a ficha dela é a última que se acha.
- Ele não sabe que, enquanto viajava, a ponte foi serrada e a vila se trancou.

**O objetivo** que a cutscene deixa no caderno: *"Subir à Colônia"*. A descrição diz: "A carta veio de lá. O portão fica
no alto da estrada." Assim o portão trancado e a chave ganham sentido.

## O roteiro (cerca de 1 min 40 s, pulável)

Não tem voz, nem para economizar créditos nem por estilo. O texto aparece na tela, com a fonte do jogo, e o som carrega
o resto: vento, chuva fina, madeira, o sino.

| # | Plano | O que se vê | Som | Tempo |
|---|---|---|---|---|
| 1 | Preto | "Serra de Santa Clara · março de 1974" | vento | 4 s |
| 2 | Papéis sobre o preto | O **ofício de 1959**, frio: "Comunicamos o falecimento da interna...". Por cima dele desliza a **carta de 1974**, na letra trêmula dela. O jogador lê no ritmo dele (E passa), como as notas. | papel | ~25 s |
| 3 | A estrada, ao sul da ravina, de madrugada | Faróis acesos na neblina. Uma legenda: *"Daqui o senhor vai a pé. Ninguém sobe pra Santa Clara."* Os faróis dão ré e somem. Ele fica com a lamparina. | motor de caminhão indo embora | 8 s |
| 4 | A cabeceira da ponte | Ele chega à beira da ravina. Em close, a ponte caída e uma viga com o **corte limpo de serra** e serragem clara: não foi a chuva. | água no fundo, vento | 8 s |
| 5 | A travessia | Ele desce pela beirada (`Climb_Ledge` ao contrário), atravessa pela ponte desabada sobre a água e sobe pela viga pendurada (`Climb_Ledge`). A câmera fica de lado, como num plano de cinema. | madeira rangendo | 20 s |
| 6 | A viga cede | Ele chega ao alto e a viga estala e cai na água. Ele olha para trás: a volta acabou. | estalo, a viga caindo, splash | 6 s |
| 7 | A barricada | Ele passa pelos cavaletes da cabeceira. Na tábua há um cartaz de **PROCURA-SE**. | vento | 6 s |
| 8 | A vila e a Colônia | A câmera sobe por trás dele e mostra os telhados na neblina e a torre da capela. Bem no alto, a **luz acesa na torre da Colônia** (`silhueta_luz`, que já existe). O sino da capela toca uma vez. Entra o título: **SANTA CLARA**. | sino | 10 s |
| 9 | O controle | A câmera desce até a posição normal de jogo, no `spawn_jogador`. Aparece o aviso "Tarefa nova: Subir à Colônia", e o jogo começa às 06:30, como hoje. | vento | 3 s |

**Para pular**, segure Esc ou E por 1 s; um terço vai se fechando no canto e confirma. Pular leva direto ao fim do
plano 9 (tarefa, nota e marca incluídas), para quem pula não perder nada. As cartas ficam no caderno, em Notas, para
reler.

## Como fazer (técnico)

Por ordem do que se reaproveita:

- **`Cutscene`** (novo, `scripts/ui/cutscene.gd`, uns 150 linhas): um `CanvasLayer` com
  - faixas pretas (letterbox),
  - legenda,
  - título,
  - o pular segurando a tecla.

  O roteiro é uma função `await` por plano, sem editor nem formato próprio. A câmera é uma `Camera3D` própria, movida
  por tweens de marcador a marcador e devolvida à do jogador no fim. O protagonista é o próprio `Player` com
  `busy = true`, movido por tweens e animado com `play()`, como já fazem `Chest`, `Climbable` e `BlockedDoor`.
- **As cartas:** duas entradas novas em `NotesData`, *Ofício de óbito* (papel `oficio`) e *Carta da mãe* (papel
  `caderno`), mostradas pelo `NotesReader`. Ficam lidas desde o começo, e por isso aparecem no caderno. Talvez valha um
  papel `carta`, com envelope e selo, em `notas_papeis.py`.
- **Quando roda:** em um jogo novo. O `menu.gd` `_start()` já leva ao vilarejo; ele passa
  `SceneRouter.arriving = "intro"`, e o `vilarejo.gd` roda a cutscene no `_started()` se não houver Story `intro:vista`.
  Carregar um save nunca a repete. O `SaveGame.settle` acontece depois dela.
- **O cenário (Blender):**
  - a ponte caída ganha o corte de serra: as pontas das vigas retas, com a face clara;
  - a viga pendurada do lado norte vira um objeto próprio (`ponte_viga_solta`), para o Godot derrubar no plano 6. Depois
    da intro ela fica caída na água (Story);
  - um cartaz na tábua da barricada.
- **A travessia (plano 5):** os pontos do caminho são marcadores no GLB (`intro_01`... na beira sul, na ponte, no pé da
  viga, no alto). Assim o roteiro não carrega números do terreno.
- **Sons novos no ElevenLabs:** três efeitos, cerca de 20 créditos.
  - caminhão velho dando ré e indo embora na neblina;
  - viga de madeira estalando e caindo na água;
  - papel sendo desdobrado.

  O resto já existe: vento, sino, rangido, `tabua_cair`, chuva.
- **A tarefa:** `QuestData` ganha `colonia` ("Subir à Colônia"), com `Story.set_task("colonia", "ativa")` no fim.

## Testes (só os dela)

`test_vilarejo.gd` `intro_tests`:
- a cutscene roda inteira num jogo novo;
- cada plano tira uma captura (`intro_1`... `intro_9`);
- no fim, o jogador está no `spawn_jogador` com o controle de volta;
- a câmera do jogo está ativa;
- `intro:vista` está marcada;
- a tarefa está ativa;
- as duas cartas estão no caderno;
- a viga está caída;
- pular no meio dá o mesmo estado final;
- carregar um save não repete a cutscene.

## Decisões para o autor

1. **Quem escreveu a carta.** Recomendo as duas cartas (o ofício de óbito de 1959 e a carta dela de 1974), porque a
   contradição entre elas é o gancho. As alternativas:
   - só a carta dela, mais simples;
   - só um ofício da Colônia chamando para buscar os pertences, mais frio, e o mistério começa na Colônia.
2. **Como ele chega.** Recomendo só os faróis e o som do caminhão, sem modelo. Um caminhão modelado custa um modelo novo
   para 8 segundos de tela.
3. **A travessia: cinema ou jogável?** Recomendo cinema nesta versão. Jogável, ela vira o tutorial de escalar e descer
   (as mecânicas já existem), mas pede um trecho da ravina sem a cerca e mais testes.
4. **O nome dele.** A carta diz "meu filho", e o nome pode continuar em aberto. Se o autor quiser um nome, ele entra no
   envelope.
5. **Quem é a mãe.** Fica em aberto até a última ficha. Uma possibilidade, só anotada: a ficha da Celina A. diz "sem
   família".

## Versão 2: três atos (implementada)

A versão 1 era quase só ele caminhando até a vila, e o porquê ficava em duas cartas soltas. A versão 2 gasta dois terços
do tempo com ele e com a mãe. São cerca de 2 minutos no total, e dá para pular tudo segurando E (ou Esc) por 1 s.

**Ato 1: o parlatório, 1955** (`Abertura`, em sépia, uns 15 s)
- Um menino do lado das visitas e a mãe do outro lado da tela de arame, contra a janela.
- As mãos dos dois na tela, uma de cada lado, e a fala dela em legenda: "Eu vou te buscar."
- A sineta da enfermeira (o fim da visita); o menino é puxado para trás. As mãos são só do close; no plano aberto elas
  não aparecem.
- O parlatório é o mesmo cenário (`Parlatorio`) que agora existe na Colônia, ao lado da portaria. Pela portaria se entra
  do lado das visitas, pelo pátio do lado dos internos, e a tela não deixa passar.

**Ato 2: São Paulo, março de 1974** (`Abertura`, uns 50 s)
- Ele volta do turno de vigia noturno com a lamparina. O som é de chuva e de um relógio.
- Ele acha um envelope por baixo da porta e lê a carta da mãe (`carta_mae`). Ela lembra o parlatório e inverte a
  promessa: "Agora é você que tem que vir."
- Na lata sobre o caixote ao lado da cama estão o ofício de óbito de 1959 (`obito`) e a foto dela. Virada, a foto mostra
  no verso "Pro meu menino. Tua mãe, 1955.", na mesma letra da carta (`foto`).
- Na parede está o recorte de jornal de 1962 (`recorte`): a lei acabou com o isolamento obrigatório, mas o Dr. Moura
  diz que os que ficaram "não têm para onde ir".
- Ele apaga a lamparina da mesa e sai.
- Por fim, o ônibus da noite: o rosto dele na janela e as luzes da estrada passando.

**Ato 3: a chegada** (`Intro`, no vilarejo, uns 35 s, metade do que era)
- "28 de março de 1974". O ônibus o deixa na estrada: "Pra Santa Clara não tem mais linha."
- A ponte caída e o toco serrado.
- Ele desce e, depois de um corte, já está subindo do outro lado. A viga cede atrás dele.
- A câmera sobe sobre a vila e entra o título. Lá no alto, a luz da torre da Colônia apaga e acende.
- A tarefa "Subir à Colônia" entra no caderno.

**Como funciona**
- O "Novo jogo" abre `scenes/abertura.tscn` (`Abertura`). Os três cenários são montados em código, afastados entre si, e
  uma câmera corta entre eles.
- No fim, a `Abertura` vai para o vilarejo, que toca a `Intro`. Pular na `Abertura` pula a `Intro` também
  (`Intro.skip_next`).
- A base das duas é `Cutscene` (`scripts/ui/cutscene.gd`). Ela cuida de:
  - faixas pretas, legenda e título;
  - pular segurando a tecla;
  - a câmera própria, com um movimento por vez (`cam_tw`), cancelado a cada corte;
  - esperas que encurtam quando a cena é pulada.
- As pessoas da `Abertura` são os próprios modelos do jogo com os clipes que já existem. O menino é o protagonista em
  0,62 de escala. A mãe tem modelo próprio (`npc_mae`, `tools/personagens/npcs/mae.py`): interna de uns 30 anos, com a
  camisola clara, o cabelo preso, a pulseira de paciente e chinelos de pano. As mãos do close são blocos com a pele de
  cada um (o material do próprio modelo), e o rosto da foto vem de uma câmera pequena apontada para ela no parlatório.
- As quatro folhas (carta, ofício, foto, recorte) ficam no caderno, em Notas.
- Sons do ElevenLabs:
  - versão 1: `caminhao_partindo`, `viga_cedendo`, `papel_desdobrar` (45 créditos);
  - versão 2: `onibus`, `lata_abrir` e `sineta` (45 créditos no total). A `sineta` substituiu um apito que soou mal.
- Testes:
  - `test_abertura.gd`: a abertura inteira, com uma captura a cada 1,5 s (`demo_abertura_<plano>_<n>`), e `--only=skip`;
  - `test_vilarejo.gd` `intro_tests`: a chegada inteira e pulada;
  - `test_colonia.gd` `parlatorio_tests`;
  - `test_menu.gd`.
