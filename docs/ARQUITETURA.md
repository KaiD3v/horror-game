# Arquitetura e organização do projeto

*Data: 2026-11-10. Esta é a refatoração que veio antes de continuar o desenvolvimento. O objetivo é que qualquer coisa nova (um NPC, um inimigo, um interior, uma nota) use o que já existe, em vez de ser escrita do zero.*

## Pastas

```
protagonista-terror/
  godot_demo/                 o jogo (projeto Godot 4.7)
    project.godot             cena inicial: scenes/menu.tscn; tema: ui/tema.tres
    scenes/                   menu.tscn · levels/ (vilarejo, colonia, treino) · interiors/ (armaria, venda, capela)
    scripts/
      core/                   base de tudo: Level, Paths, Audio, Looks, Nodes, GameInput, SceneRouter,
                              Interactable, Interactor
      player/                 Player e as partes dele: animação, casaco, lamparina, virote, condição (sangue, fôlego)
      enemies/                Enemy (base), Mutante, Enfermeira, Bruxa, Poceiro, Carpideira, Dummy
      npcs/                   Npc
      shop/                   Shop (regras de compra), ShopMenu (a tela), ShopCounter (o "E · comprar" de um vendedor)
      world/                  Door, Footsteps, RandomEvents, Clima, Corvo
      ui/                     Hud, menu, NotesReader, NotePaper, WeaponWheel (a roda de armas do Q)
      data/                   dados sem lógica: NpcCatalog, NotesData, Atmospheres, DayData, ItemCatalog, ShopCatalog
      levels/                 o script de cada fase: vilarejo, colonia, treino, interior (único para todos os interiores)
    shaders/                  sangue, visao, silhueta, neblina_bancos, poca, menu_neblina
    models/characters/        protagonista, monster, enfermeira, bruxa, poceiro, carpideira, npc_<quem> (.glb gerados)
    models/levels/            vilarejo, armaria, venda, capela (.glb gerados)
    textures/ sounds/ ui/     texturas, sons e interface (fonte, tema, arte do menu)
    tests/                    AutoTest (base) e um test_<cena>.gd por cena; check_scripts.gd
    captures/                 saída dos testes (capturas de tela)
  tools/                      o pipeline: tudo o que gera os arquivos do jogo
    comum/                    paths.py, audio.py, lowpoly.py (personagens), npc_kit.py, vila_kit.py (cenários)
    personagens/              protagonista_build + protagonista_rig, monster_build, enfermeira_build, bruxa_build, poceiro_build,
                              carpideira_build,
                              npcs_build (roda npcs/<quem>.py)
    cenarios/                 vilarejo_build (+ pacote vilarejo/), armaria_build, venda_build, capela_build
    texturas/                 scenery_textures, notas_papeis, fonte, roda_armas (o terço e as plaquinhas da roda)
    sons/                     sounds_import (ElevenLabs), clima_sons, enfermeira_sons, bruxa_sons, poceiro_sons, carpideira_sons, ferido_sons, sounds_build
    renders/                  renders de conferência (protagonista, mutante, vilarejo, NPCs lado a lado)
  blender/                    .blend salvos pelos builds: personagens/, npcs/, cenarios/
  audio_fontes/               MP3 do ElevenLabs (elevenlabs/, elevenlabs_extra/) e o conjunto sintetizado antigo
  renders/                    imagens de conferência: protagonista/, mutante/, enfermeira/, bruxa/, poceiro/, carpideira/, npcs/, cenarios/,
                              texturas/, interface/, sons/, godot/
  docs/                       documentação (esta, VILAREJO, ENFERMEIRA, MUTANTES_NOITE, CENARIOS, TODO_ARTE)
```

Regras:
- **Os `.glb`, as texturas, os sons e a fonte são gerados.** A fonte da verdade são os scripts em `tools/`. Não se edita o arquivo gerado.
- **Nenhum caminho fixo.** No Godot, todo `res://` passa por `Paths` (`scripts/core/paths.gd`). Nos scripts Python, tudo passa por `tools/comum/paths.py`.
- **Os builds são determinísticos.** Rodar um build sem mudar nada gera um arquivo byte a byte igual. Foi assim que esta refatoração foi conferida (ver "Verificação").

## Godot: as peças e como usá-las

### Level (`scripts/core/level.gd`)
É a base de toda fase jogável. Ela já traz:
- o jogador;
- o HUD;
- o uso de objetos com E (`Interactor`);
- os passos;
- as notas daquela cena;
- os NPCs nos marcadores;
- as portas;
- o navmesh e as consultas de chão (`ground`, `ray`, `reachable`);
- Enter para recomeçar;
- o gancho de teste.

Uma fase sobrescreve três métodos:
- `_build()`: ambiente, geometria, NPCs, inimigos e navmesh;
- `_player_start()`: onde o jogador começa;
- `_started()`: som e clima, depois que o jogador e o HUD existem.

### Criar uma coisa nova

| Quero criar... | O que fazer (o resto já existe) |
|---|---|
| **um NPC** | 1. Um arquivo em `tools/personagens/npcs/<quem>.py`, copiando o de um NPC existente: rosto (`Face`), cores, tabela de juntas, `limbs`/`head`/`finish` de `npc_kit.py`. Acrescente o nome em `NPCS` de `npcs_build.py`. 2. Uma entrada em `NpcCatalog` (nome, papel e, se quiser, a luz e o som que ele traz). 3. Um marcador `npc_<quem>` no GLB da fase. `Level.spawn_npcs` faz o resto: colisão, idle fora de fase, luz, som. |
| **um inimigo** | Estender `Enemy` e preencher os atributos em `_init()`: modelo, vida, velocidade, alcance e tempo do golpe, cooldown. Depois, escrever só o `_decide()`, o que ele faz parado, alerta e perseguindo. O golpe, o atordoamento, o navmesh e a morte já vêm da base. Ver `Mutante` (30 linhas) e `Enfermeira`. |
| **um interior** | 1. O build em `tools/cenarios/<nome>_build.py`, com `vila_kit.Room` e os marcadores `entrada`, `porta`, `luz_*`, `npc_*`, `som_*` e `teto`. 2. Uma cena `scenes/interiors/<nome>.tscn` com o script `interior.gd` e as configurações (modelo, porta, título, chão, ambiente). **Não precisa de código.** 3. Um `porta_<nome>` no vilarejo e uma linha em `DOORS` de `vilarejo.gd`. |
| **um vendedor** | Pôr `"loja": "<id>"` na entrada do NPC em `NpcCatalog` e criar a loja em `ShopCatalog` (título, fala, ofertas com item, quantidade, preço e estoque). O NPC ganha "E · comprar com <nome>" e a tela de compra. **Sem código.** |
| **um item** | Uma entrada em `ItemCatalog` com nome, descrição e `tipo`. Os tipos de hoje são `"cura"` (usado com F) e `"municao"` (o virote, gasto pela besta). Um tipo novo de efeito é um caso a mais em `Inventory.use()`. |
| **uma nota** | Uma entrada em `NotesData`: cena, posição, papel e texto. Ela aparece no chão, tem leitor e entra na coleção. |
| **algo para usar com E** | Um `Interactable` (prompt e raio) e o tratamento no sinal `used`, ou uma subclasse que sobrescreve `_use()`. Exemplos: `Door`, `NotePaper` e o ferrolho da Colônia. |
| **uma porta entre cenas** | `Door.make(marcador, "E · entrar...", cena, chegada)`. |
| **um evento ambiente aleatório** | `RandomEvents.add(nome, primeira, intervalo, função)`. |
| **uma arma na roda (Q)** | Uma entrada em `WHEEL` de `weapon_wheel.gd` (modo, nome, nota, arte, tecla) e a plaquinha dela em `tools/texturas/roda_armas.py` (uma função que desenha a figura pirografada e um ângulo em `SLOTS`). Com uma tecla própria, mais uma linha em `GameInput.KEYS` e em `Player._unhandled_input`. A arma em si é um `Player.Mode` com as animações de sacar e guardar; `Player.equip()` guarda o que estiver na mão antes de sacar a nova. |
| **o dia e o clima numa fase** | Usar `day = DayCycle.outdoors(self, env, sol, materiais_de_silhueta, clima)` ao ar livre, ou `DayCycle.indoors(self, luzes_de_janela, vidros)` num interior. O relógio (`WorldTime`) e o clima (`Weather`) continuam entre as cenas. Horários, cores e chances ficam em `DayData`. |
| **um som** | `Audio.play2d` / `play3d`, ou `loop_player` mais `fade` para um loop que entra e sai. |
| **um ambiente (céu, neblina)** | Um preset em `Atmospheres` e `Looks.environment(self, preset)`. |
| **uma fase de greybox** | Estender `Level` e montar com `Looks.box` e `Looks.triplanar`. Ver `colonia.gd` e `treino.gd`. |

### O jogador (`scripts/player/`)
O `player.gd` (antes com 630 linhas) foi dividido por responsabilidade:

| Arquivo | Responsabilidade |
|---|---|
| `player.gd` | modos, ações, movimento, câmera, luz da lamparina, dano |
| `player_animation.gd` | a árvore de animação |
| `coat_physics.gd` | a física das abas do casaco |
| `lantern_hook.gd` | a lamparina no gancho do cinto |
| `bolt.gd` | o virote em voo, que agora é um nó próprio |
| `player_condition.gd` | o sangue no corpo, a respiração, o ofego e o cansaço |

### Testes (`tests/`)
Os testes saíram dos scripts das fases e agora ficam em `tests/`.

Para rodar uma cena com `-- --autotest`:
1. A fase chama `AutoTest.attach(self)`.
2. Isso carrega `tests/test_<cena>.gd`, que estende `AutoTest`.
3. O `AutoTest` traz `check`, `wait`, `shot`, `tap`, `until`, `put`, `walk`, `map_shot` e `notes_suite` (testa as notas de qualquer cena).
4. A saída termina em `AUTOTEST PASS` ou `AUTOTEST FAILED: ...`.

Os interiores compartilham `test_interior.gd`. Cada um acrescenta só o passeio próprio (`tour()`).

Comandos:

```
G=C:/Users/kaikr/Desktop/Godot_v4.7.2-stable_win64_console.exe
$G --headless --path godot_demo --script res://tests/check_scripts.gd      # todos os scripts compilam
$G --path godot_demo res://scenes/levels/vilarejo.tscn -- --autotest       # (menu, treino, colonia, interiors/...)
```

## Pipeline (`tools/`)

### Bibliotecas comuns (`tools/comum/`)
| Arquivo | O que tem |
|---|---|
| `paths.py` | onde fica cada coisa: `paths.character()`, `paths.level()`, `paths.blend()`, `paths.render()`, `SOUNDS`, `TEXTURES` |
| `audio.py` | `write_wav` e `sos`, usados por todos os scripts de som |
| `lowpoly.py` | o kit dos personagens: `Kit`, `Poser`, `armature`, `mat`, `new_image`, `lin`, `V` |
| `npc_kit.py` | o que todo NPC divide: `Face` (rosto pintado), `grime`, esqueleto humano, cabeça, orelhas, membros, avental e `finish()` (rig, idle, .blend, .glb, renders) |
| `vila_kit.py` | o kit dos cenários: materiais, construtor de malha `B`, peças de objetos, `Room` (casca de interior) e `bake_ao`, a oclusão nas cores de vértice para qualquer fase |

### O vilarejo em módulos
O `vilarejo_build.py` tinha 1000 linhas. Agora ele só roda as partes, na ordem de build. As partes ficam no pacote `cenarios/vilarejo/`:

| Módulo | O que tem |
|---|---|
| `layout` | ruas, lugares das casas, altura do terreno |
| `paredes` | peças de parede comuns a todos os prédios |
| `construcoes` | casas, ruína, capela, poço, muro da Colônia, cemitério, cercas |
| `natureza` | terreno, árvores mortas, pedras, vegetação |
| `objetos` | o kit de objetos espalhados |
| `narrativa` | o sangue, as correntes, a ponte caída, a carcaça, os corvos |
| `horizonte` | as serras e a Colônia além da neblina |

### Comandos
Rodar a partir da raiz do projeto:

```
B="C:/Program Files/Blender Foundation/Blender 5.2/blender.exe"
"$B" -b --factory-startup --python tools/cenarios/vilarejo_build.py
"$B" -b --factory-startup --python tools/personagens/npcs_build.py          # ou npcs/<quem>.py sozinho
"$B" -b --factory-startup --python tools/personagens/protagonista_build.py --python tools/personagens/protagonista_rig.py
python tools/texturas/scenery_textures.py ; python tools/sons/clima_sons.py ; ...
```

Depois de gerar os arquivos, `$G --headless --path godot_demo --import` reimporta no Godot.

## O que mudou

Os principais problemas encontrados e o que foi feito com cada um:

| Problema | O que foi feito |
|---|---|
| `main.gd` era ao mesmo tempo a sala de treino, a base das fases, o HUD, o som, as portas e os testes | Virou `Level` e `Hud`, mais `Audio`, `SceneRouter`, `Footsteps` e `AutoTest`. A sala de treino é só mais uma fase (`treino.gd`). |
| Portas, notas e ferrolho tinham, cada um, a própria checagem de distância, o próprio aviso e o próprio E | Agora usam um sistema só: `Interactable` com `Interactor`. |
| O NPC era criado à mão em cada fase, e a luz e a reza da Dona Firmina estavam escritas no vilarejo | Agora são `Npc` + `NpcCatalog` + o marcador `npc_<quem>`. |
| O Mutante e a Enfermeira repetiam o golpe, o atordoamento e o caminho pelo navmesh | Essa parte foi para a base `Enemy`. Cada inimigo escreve só o `_decide()`. |
| Três scripts de interior só para mudar constantes | Um `interior.gd`. Cada sala é configurada no próprio `.tscn`. |
| `put`, `walk`, `check`, o bake do navmesh, `reachable`, `ground` e a captura do mapa estavam copiados em várias fases | Estão uma vez só, no `Level` ou no `AutoTest`. |
| Shaders escritos como texto dentro dos scripts | São arquivos em `shaders/`. |
| A linha de controles e a mensagem de morte repetidas em quatro cenas | Ficam no `Hud`. |
| Caminhos fixos `C:\Users\...` em 8 scripts Python e `res://` espalhados pelo código | Passam por `paths.py` e `Paths`. |
| `save()` e `sos()` copiados em 5 scripts de som | Ficam em `audio.py`. `V()` estava em 3 builds e foi para `lowpoly.py`. `lin` e `new_image` do protagonista agora vêm do `lowpoly`. |
| Os 3 NPCs num arquivo só, com o kit misturado | O kit foi para `npc_kit.py`, com um arquivo por NPC. |
| Arquivos soltos | Tudo foi para pastas por tipo:<br>• os `.glb` duplicados na raiz foram apagados;<br>• as texturas que o Godot extraía dos `.glb` (cerca de 70 PNG soltos) agora ficam embutidas no próprio `.glb`;<br>• os renders foram separados por assunto. |

### Verificação
- **Pipeline:** cada script refatorado foi rodado de novo, e o arquivo gerado foi comparado por md5 com o de antes.
  - São idênticos: os 10 `.glb`, as 60 texturas, os 34 sons do jogo, os 27 sons sintetizados antigos e a fonte.
  - A exceção é o `armaria.glb`. O arquivo antigo estava desatualizado em relação ao kit, e o script original gera o mesmo arquivo que o refatorado.
- **Jogo:** as 7 cenas passam no autotest e `check_scripts.gd` compila todos os scripts.
- **Backup:** a cópia completa de antes está em `../protagonista-terror_backup_2026-11-10`.
  - Ela não guarda o `armaria.glb` antigo. Conferir o original foi rodar o build da armaria da própria cópia, e isso sobrescreveu ali o `armaria.glb`, o `armaria.blend` e os renders da armaria.
