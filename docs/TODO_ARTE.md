# TODO: melhorias artísticas

Pendências levantadas na análise de arte de 2026-11-09. Marque `[x]` quando estiver aprovado no jogo pelo autor.

## Acabamento do cenário

Os quatro itens estão feitos e falta o teste do autor no jogo. A descrição está em `VILAREJO.md`, seção "Acabamento".

- [~] Sombreamento da base das paredes, dos cantos e da terra sob as casas, por oclusão ambiente calculada no build e guardada na cor dos vértices.
- [~] Manchas por cima das superfícies: umidade, musgo, escorridos dos peitoris e rachaduras nas casas, na capela e no muro.
- [~] Silhuetas de fundo além da neblina: duas serras em anel, com araucárias.
- [~] A Colônia vista por cima do muro: pavilhões, torre do relógio, chaminé, torre de vigia e duas janelas acesas.

## Vida e clima

Os quatro itens estão feitos e falta o teste do autor no jogo. A descrição está em `VILAREJO.md`, seção "Vida e clima".

- [~] Garoa fina com partículas e som. Debaixo dos telhados não chove. Poças na estrada brilham à luz da lamparina e têm anéis dos pingos.
- [~] Corvos animados: são 9, bicam e pulam. Fogem a 7 m do jogador, ou a 3 m se ele estiver agachado, e o bando inteiro vai junto.
- [~] Neblina que se move: 46 bancos descem o vale vindos da Colônia.
- [~] Folhas levadas pelo vento, e cinzas e brasas saindo da casa queimada.

## Os mutantes

- [ ] **Mutante atual:** uma animação de corrida e outra de busca, farejando.
  - [~] Os sons estão feitos: grunhidos, grito ao ver o jogador, golpe, dor, morte e passos pesados (ver VILAREJO.md, "Sons"). Falta o teste do autor no jogo.
- [~] **A Enfermeira:** modelo, animações, comportamento e sons feitos (ver [ENFERMEIRA.md](ENFERMEIRA.md)). Falta o teste do autor no jogo.
- [~] **Jogador ferido:** feito, falta o teste do autor no jogo.
  - O sangue sai de `godot_demo/shaders/sangue.gdshader`, uma passada extra sobre a roupa e a pele. O `scripts/player/player.gd` guarda a posição de repouso de cada vértice em CUSTOM0, e por isso as manchas acompanham as animações.
  - A atadura já começa manchada e encharca aos poucos, até cobrir o antebraço.
  - No 1º golpe aparecem um corte nas costas, do omoplata esquerdo para baixo, e sangue na mão esquerda.
  - No 2º golpe aparecem as costelas, o ombro direito (o que a câmera vê), um corte na testa escorrendo pelo rosto, a coxa e a mão direita.
  - Cada mancha se espalha em cerca de 1,3 s, com borda irregular, respingos, sangue fresco na borda e seco no meio.
  - Com 1/3 da vida, uma respiração pesada e trêmula entra em 2 s. Ela para na morte. O som é sintetizado por `ferido_sons.py` (`respiracao.wav`).
  - Os cortes, quando abrem e o tamanho de cada um são constantes no topo do shader.

## Interface e apresentação

- [~] Tela de título. O menu está feito (`scenes/menu.tscn`), com a arte do autor, neblina e vento. Falta a música do rádio, se o autor ainda quiser.
- [~] **Stamina e vida sem barras.** Feito, falta o teste do autor no jogo.
  - A barra de stamina saiu. Abaixo de 60% de stamina ele começa a ofegar (`ofego.wav`, de `ferido_sons.py`). Sem fôlego, o ofego fica forte e as bordas da tela escurecem e abrem no ritmo dele.
  - A vida aparece na tela por `godot_demo/shaders/visao.gdshader`. A cada golpe a cor vai sumindo e um vermelho escuro fecha pelas bordas. No último golpe a borda pulsa, como sangue nas têmporas.
  - Isso se soma ao sangue no corpo e à respiração pesada do "Jogador ferido".
- [~] **Notas e documentos.** Feito, falta o teste do autor no jogo.
  - São 7 papéis (`godot_demo/scripts/ui/notes_reader.gd` e `scripts/data/notes_data.gd`):
    - três no vilarejo: na mala da estrada, na porta da `casa_04` e no portão da Colônia;
    - um em cada interior: na mesa do bar da venda, no balcão da armaria e no altar da capela;
    - a ficha da Enfermeira, na mesa de cirurgia da Colônia.
  - Os papéis são caderno arrancado, ofício com carimbo e ficha de paciente com foto (`notas_papeis.py`). O envelhecimento é o mesmo dos cartazes.
  - E lê o papel: o jogo pausa e o papel aparece em 2x, com o texto na fonte do jogo, apoiado nas pautas.
  - O papel lido sai do chão e fica guardado entre as cenas. Tab relê os papéis guardados, A/D folheia.
  - Os textos contam o vilarejo: a ponte serrada, o Zé que abriu a porta, o ofício do Dr. Moura e o fiado da Colônia. Duas notas dão dicas de jogo: a do Tenório ("não tire a luz de cima dela") e a ficha da Enfermeira (a luz a paralisa).
- [~] **Fonte própria: "Santa Clara".** Feito, falta o teste do autor no jogo.
  - É uma fonte de pixel desenhada à mão em `fonte.py`, com 113 caracteres, acentos do português incluídos. Ela é gerada como BMFont em `godot_demo/ui/fonts/santa_clara.fnt`.
  - Está como tema padrão do projeto (`tema.tres`), então vale no HUD, nos avisos, nas notas e no menu.
  - Funciona em múltiplos de 12 px (12, 24, 36, 48), com escala inteira para ficar nítida.
  - A amostra está em `renders/interface/fonte_santa_clara.png`.
  - As placas e cartazes do cenário continuam com a fonte antiga. Trocar exige regerar as texturas.

## Som

- [ ] Uma trilha ambiente por área.
- [ ] Stingers: acordes curtos de susto quando o mutante vê o jogador.
- [ ] Batimento cardíaco perto do perigo. Hoje o coração só bate com a vida baixa (`coracao.wav`).
- [~] Sons de ação do protagonista (facão, besta, lamparina, dano), vida baixa e a chuva nova. Feito, falta o teste do autor no jogo.

Observações:
- O jogo não tem dublagem.
- Economizar créditos do ElevenLabs. O que for possível sai do gerador local (`sounds_build.py`).
- Para o mutante, use o ElevenLabs só para grunhidos e grito.
