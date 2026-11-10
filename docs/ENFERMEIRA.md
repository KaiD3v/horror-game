# A Enfermeira

O segundo mutante da Colônia, previsto em `CENARIOS.md` como "magra e silenciosa; aparece por trás".

## Análise

O Interno, o mutante atual, é a ameaça direta. Ele vê você, grita, persegue e golpeia, e o jogador foge correndo ou luta com o facão.

A Enfermeira precisava pedir outra resposta do jogador. Correr não serve contra ela: o certo é **olhar para ela**, e para isso a lamparina precisa estar na mão.

Isso liga a criatura a uma mecânica que já existe, a de guardar a lamparina no cinto (tecla L). Com a lamparina guardada, o jogador fica com as mãos livres para a besta ou o facão, mas passa a enxergar pouco, e é aí que ela avança.

## Visual (`enfermeira_build.py`)

- Mede 2,13 m. É alta, magra e rígida, com braços longos demais: os dedos da mão esquerda chegam quase ao joelho.
- Veste o uniforme dos anos 70: vestido branco amarelado com manchas antigas, capa azul-marinho e touca com faixa preta.
- Tem uma gaze sobre os olhos, com sangue que escorreu por baixo, e a boca costurada. É por isso que é silenciosa.
- Na mão direita leva uma seringa de vidro grande com dose vermelha, segurada como um furador de gelo.
- Na cintura tem uma corrente com chaves e uma tesoura, que é o único som que ela faz.
- Usa meias rasgadas e sapatos de enfermeira, e anda **na ponta dos pés**.
- O modelo tem 1424 triângulos e 16 ossos. Usa o mesmo kit e o mesmo estilo de rig do mutante.
- Animações:
  - `Idle`: imóvel; uma vez por ciclo a cabeça estala para o outro ombro.
  - `Walk`: passo nas pontas dos pés, só as pernas se movem e o tronco desliza; anda a 2,1 m/s em 1x.
  - `Attack`: ergue a seringa e crava no quadro 13.
  - `Hit` e `Death`: os joelhos cedem e ela tomba de lado.
- Renders: `renders/enfermeira/` e as folhas `renders/enfermeira/enfermeira_folha.png` e `renders/enfermeira/enfermeira_detalhe.png`.

## Comportamento (`godot_demo/scripts/enemies/enfermeira.gd`, estende `scripts/enemies/enemy.gd`)

- **Só se move quando ninguém olha.** Ela está "vista" quando aparece na câmera, sem nada no caminho, e dentro do alcance da luz:
  - **9 m** com a lamparina na mão, andando ou agachado;
  - **4 m** com a lamparina no cinto, o facão ou a besta.
- Vista, ela congela no meio do passo, como uma estátua, e as chaves se calam.
- **Aparece por trás.** Sem ninguém olhando, ela vai para o ponto logo atrás da câmera, a 2,2 m/s. Isso é mais rápido que o trote (1,66 m/s) e um pouco mais lento que a corrida (2,6 m/s). Sem olhar para trás, o jogador não se livra dela.
- **Não tem passos.** O aviso é o `tilintar` das chaves enquanto ela anda e o `sopro`, uma respiração pela boca costurada, quando chega a 2,6 m das costas do jogador.
- **De perto, ataca mesmo sendo vista.** A menos de 1,5 m ela crava a seringa (1 de dano). Depois fica parada 1,4 s, e essa é a janela para o contra-ataque.
- Tem 4 de vida: o golpe lateral do facão tira 1, o golpe por cima tira 2 e o virote tira 3.
- **É alta demais para as portas baixas**, como o Interno. Ela começa trancada na Enfermaria do greybox da Colônia, cujas saídas são a porta baixa e o atalho trancado. Destrancar o atalho a solta no resto do mapa.
- Ela começa a caçar quando o jogador está a 14 m, mesmo sem vê-lo, porque sabe onde o jogador está.

## Sons (`enfermeira_sons.py`)

Os dois sons foram sintetizados localmente, sem gastar créditos do ElevenLabs. O jogo não tem dublagem e ela não fala.

- `tilintar` (loop): chaves e tesoura batendo no ritmo dos passos dela.
- `sopro`: respiração lenta com um chiado nos lábios costurados.

Se soarem artificiais demais no jogo, dá para trocar pelos efeitos do ElevenLabs depois.

## Testes (`colonia.tscn -- --autotest`)

Os testes conferem que ela:
- persegue o jogador pelas costas e as chaves tocam;
- congela quando é vista e iluminada, e as chaves se calam;
- avança mesmo sendo vista quando a lamparina vai para o cinto;
- respira na nuca e acerta o jogador pelas costas;
- morre com o facão.

Capturas: `captures/demo_c6_enfermeira_vista.png`, `demo_c7_enfermeira_costas.png` e `demo_c8_enfermeira_morta.png`.

## Para o autor testar no jogo

- O ritmo: se 2,2 m/s e o alcance de 9 m deixam a tensão boa ou ela fica fácil ou difícil demais.
- Se os sons sintetizados servem.
- Se a janela de 1,4 s depois do golpe dá para contra-atacar.
