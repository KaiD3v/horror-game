# Cenários para o jogo: análise, pesquisa e propostas

*Data: 2026-11-09. Base: o protagonista, o mutante e a demo no Godot como estão hoje.*

---

## 1. O que o jogo já está dizendo

Antes de inventar um lugar, vale ler o que os modelos e as mecânicas já contam. Um cenário que combina é aquele que explica essas escolhas, em vez de brigar com elas.

| O que já existe | O que sugere sobre o lugar |
|---|---|
| Lanterna a óleo como única luz | Não há energia elétrica, ou ela caiu. Época antiga (anos 1950 a 70) ou lugar isolado. |
| Facão (não é espada nem arma de fogo) | Interior, mato, roça, floresta. É uma ferramenta de trabalho, não de soldado. |
| Capote verde, cachecol vermelho, braço esquerdo enfaixado | Alguém comum e já ferido, vindo de fora e de um lugar frio ou úmido. Não é herói militar. |
| Mutante com **camisola hospitalar e pulseira de paciente** | A origem é uma **instituição de saúde**: os monstros eram internos. |
| Mutante **sem olhos**, cicatriz costurada | Houve intervenção cirúrgica, ou seja, **experimento**. E faz sentido ele "enxergar" pelo som. |
| Estilo N64: neblina, luz sem sombra, texturas de 32 px | Ambientes fechados ou enevoados, com visão curta. A neblina é ao mesmo tempo atalho técnico e ferramenta de medo (é o caso clássico de Silent Hill). |
| Andar 0,91 m/s; correr 2,6 m/s por 4 s; mutante a 1,45 m/s, visão de 8 m com linha de visada | O mapa precisa ter **coisas que quebram a linha de visada** (pilares, portas, curvas), **voltas** para escapar e **lugares de fôlego**. |
| Combate caro: o mutante aguenta 6 de dano, e a esquiva só vai para trás | O jogo tende a **evitar mais que lutar**. O cenário deve oferecer rotas alternativas, não só arenas. |
| Mutante com 2,18 m e cápsula de 0,35 m de raio | Portas e corredores precisam ser medidos. Isso vira mecânica (ver 4.2). |

**Conclusão da análise:** o jogo já aponta para *um lugar isolado, sem luz, onde uma instituição "cuidava" de pessoas e as transformou*. O horror central é humano, e as criaturas são a consequência.

---

## 2. O que a pesquisa trouxe

### 2.1 Design de níveis de terror

- **Mapa interligado, com atalhos que se abrem.** A mansão do primeiro Resident Evil é o exemplo citado por todos: salas trancadas, atalhos que só abrem mais tarde e um retorno constante a lugares conhecidos. O que o jogador ganha é **conhecer o espaço**, não ficar mais forte. Também se fala em subverter uma arquitetura familiar para gerar incerteza. ([GameHaunt](https://gamehaunt.com/deconstructing-the-level-design-of-iconic-horror-mansions), [FinalBoss](https://finalboss.io/resident-evils-spencer-mansion-still-teaches-horror-better))
- **Neblina e baixa definição tiram informação, e a imaginação preenche o resto.** A neblina de Silent Hill nasceu para esconder a distância curta de desenho e virou assinatura estética. A distância curta também deixa o inimigo aparecer já perto. ([GGRecon](https://ggrecon.com/articles/why-are-ps1-graphics-in-horror-games-so-scary), [Superjump](https://www.superjumpmagazine.com/drafting-through-the-mists/))
- **Perseguições funcionam quando surpreendem** e quando a fuga se resolve quebrando a linha de visada: subir, passar por uma fresta, dar a volta. Esconderijos que não são roteirizados, onde você nunca sabe se vai ser achado, sustentam a tensão. ([Game Developer: Outlast 2](https://gamedeveloper.com/audio/the-art-of-the-chase-level-design-and-player-orientation-in-i-outlast-2-i-), [Game Developer: tension and chase](https://gamedeveloper.com/design/creating-horror-through-level-design-tension-jump-scares-and-chase-sequences), [Dread Central: Haunting Ground](https://www.dreadcentral.com/editorials/480027/terrifying-chase-haunting-grounds-clever-run-and-hide-horror/))

### 2.2 Lugares reais que podem inspirar (sempre ficcionalizados)

O Brasil tem lugares reais com a combinação exata de isolamento, instituição e abandono. Usar o país como base dá ao jogo uma identidade que quase nenhum jogo de terror tem.

- **Hospitais-colônia de isolamento.** De 1924 até a segunda metade do século XX, pessoas com hanseníase eram internadas à força em colônias que funcionavam como cidades fechadas. O país chegou a ter dezenas delas (as contagens vão de ~33 a 101). Muitos pacientes ficaram lá mesmo depois do fim da política. ([Rev. Bras. Enfermagem](https://doaj.org/article/441d971117d54196977f6a053ab66473), [VICE](https://www.vice.com/pt/article/memorias-do-isolamento/), [Mirabilia](https://www.revistamirabilia.com/sites/default/files/medicinae/pdfs/med_2015-02-03_0.pdf))
- **Cubatão, o "Vale da Morte" nos anos 80.** Polo industrial na serra, céu amarelado, cheiro de enxofre, doenças respiratórias e más-formações em recém-nascidos. Houve ainda o incêndio da Vila Socó (1984), em palafitas, causado por vazamento de oleoduto. ([NSC Total](https://www.nsctotal.com.br/noticias/vale-da-morte-como-esta-a-cidade-brasileira-que-ja-foi-a-mais-poluida-do-mundo), [Toda Matéria](https://www.todamateria.com.br/desastres-ambientais-no-brasil/))
- **Madeira-Mamoré, a "Ferrovia do Diabo".** Ferrovia na floresta, construída entre 1907 e 1912 à custa de milhares de doentes de malária. Foi abandonada aos poucos e hoje sobrevivem locomotivas e estações em ruína. ([Correio Braziliense](https://www.correiobraziliense.com.br/cbradar/a-capital-que-nasceu-de-uma-ferrovia-a-cidade-construida-as-margens-do-rio-madeira-em-torno-da-lendaria-ferrovia-do-diabo/), [Fiocruz](https://agencia.fiocruz.br/sites/agencia.fiocruz.br/files/revistaManguinhosMateriaPdf/RM02pag45a46Fio_0.pdf))
- **Fordlândia.** Uma cidade-empresa americana erguida na Amazônia em 1928, com casas no estilo de Michigan, caixa-d'água e serraria, depois engolida pela floresta. Teve revolta de trabalhadores e uma praga nas seringueiras. ([Wikipedia](https://wikipedia.com/wiki/Fordlandia), [Culture Trip](https://theculturetrip.com/south-america/brazil/articles/fordlandia-the-ill-fated-1920s-prohibition-town-henry-ford-built-in-the-amazon), [IHU Unisinos](https://ihu.unisinos.br/545222-em-ruinas-cidade-construida-por-henry-ford-na-amazonia-aguarda-tombamento-como-patrimonio-historico-brasileiro))

> **Cuidado com o tema.** Hanseníase, poluição e mortes na ferrovia atingiram pessoas reais, e algumas ainda estão vivas. Regra proposta: **nomes, lugares e datas fictícios**, e a mutação **nunca** vem da doença real. Ela vem de quem explorou os doentes: o experimento, o soro, o vazamento. Assim o monstro é o que a instituição fez, não o paciente, e o jogo não reforça o estigma que essas pessoas sofreram.

---

## 3. Propostas de cenário

Cada proposta traz premissa, motivo do encaixe, áreas, ameaças humanas e mutantes, ganchos de mecânica e viabilidade no estilo atual.

### A. Colônia Santa Clara (hospital-colônia na serra) ⭐ recomendada

**Premissa.** Anos 1970, numa serra fria e enevoada. A Colônia Santa Clara foi construída para isolar doentes e é uma cidade inteira cercada por muro: pavilhões, igreja, cemitério, cadeia própria, padaria, usina a lenha. Quando o isolamento acabou, a colônia foi "esvaziada". Na verdade, um médico continuou ali com os internos que não tinham para onde ir e testou neles um "soro de regeneração". O protagonista chega procurando alguém: a mãe, que foi internada quando ele era criança e de quem foi separado.

**Por que combina.** A camisola e a pulseira do mutante passam a contar a história sozinhas. A falta de luz se explica pela usina a lenha parada, o que justifica a lanterna. A serra explica o capote, o cachecol e a neblina, e o facão vem do mato em volta do muro. É a proposta que **usa tudo o que já foi feito**.

**Áreas (mapa central com atalhos):**
- *Portaria e muro*: entrada, guarita, o primeiro bilhete.
- *Pátio central*: o eixo, com neblina densa e coreto. Liga tudo.
- *Pavilhões masculino e feminino*: corredores longos com leitos, ideais para perseguição em linha.
- *Igreja*: sala segura, onde se salva o jogo (a luz das velas não atrai).
- *Refeitório e cozinha*: muitos obstáculos baixos para dar voltas no mutante.
- *Enfermaria e centro cirúrgico*: onde o experimento aconteceu. Arquivo e fichas dos pacientes.
- *Preventório (a casa das crianças separadas)*: o clímax emocional. É onde o protagonista viveu.
- *Usina e porão*: restaurar a luz muda o mapa, porque as áreas iluminadas viram zonas seguras.
- *Cemitério*: covas abertas, e as covas vazias são a pista de para onde os corpos foram.

**Humanos.**
- *O Doutor*: o antagonista; ainda vivo, ainda "tratando".
- *Os Irmãos*: antigos funcionários que ficaram e veem os mutantes como milagre. São ameaça humana, com armas de fogo raras.
- *Uma interna lúcida*: aliada, deixa recados. Não está claro se ela é parte do experimento.

**Mutantes (a partir do mutante atual).**
- *O Interno*: o modelo que já existe, a ameaça padrão.
- *A Enfermeira*: magra e silenciosa; aparece por trás. Feita: ver [ENFERMEIRA.md](ENFERMEIRA.md).
- *Os Pequenos*: rastejantes, vêm do preventório. Pouca vida, em grupo.
- *O Enxerto*: vários corpos costurados num só. Chefe, alto demais para as portas.

**Ganchos de mecânica.**
- **Portas baixas** nos pavilhões antigos (ver 4.2).
- **O Interno caça pelo som**, já que não tem olhos (ver 4.1).
- **Fichas de pacientes** como coletáveis que montam a história, e a ficha da mãe é a última.
- **A usina**: ligar a luz muda o comportamento das criaturas por região.

**Viabilidade.** Muito alta. É arquitetura modular (paredes de 3 m, portas, janelas com grade, leitos, cruzes), com texturas de 32 px de reboco descascado e azulejo. Um kit de umas 30 peças cobre a colônia inteira.

---

### B. Vale do Enxofre (cidade industrial envenenada)

**Premissa.** Anos 1980. Um polo petroquímico no pé da serra e uma vila operária sobre palafitas no mangue. A neblina é **amarela**: é gás. A empresa tem a própria clínica, onde "acompanhava" os operários contaminados. Depois de um vazamento, a vila foi isolada pelo exército, e o protagonista entra procurando o irmão, que era operário.

**Por que combina.** A neblina vira veneno, não só clima, e o sistema de fôlego ganha sentido: no gás, correr gasta o dobro. O mutante de camisola vem da clínica da empresa. O horror é corporativo e muito brasileiro.

**Áreas.** Vila de palafitas (passarelas estreitas e água por baixo), escola e igreja da vila, oleoduto (um túnel linear de perseguição), a refinaria (torres, escadas, verticalidade), a clínica da empresa, o posto do exército.

**Humanos.** Soldados do cerco, que atiram em qualquer coisa que se mexa. Saqueadores. O engenheiro que sabe a verdade.

**Mutantes.** *Os Inchados* (pulmões que estouram e soltam gás ao morrer), *os Operários* (fundidos ao macacão e à máscara), *a Coisa do Mangue* (aquática, ataca de baixo das passarelas).

**Ganchos.** Máscara de gás com filtros como recurso. Bolsões de gás amarelo bloqueiam rotas. A maré sobe e desce e abre caminhos.

**Viabilidade.** Média. Estruturas industriais exigem mais peças, e água e gás pedem shaders simples, mas a neblina colorida sai praticamente de graça com o `Environment` que já existe.

---

### C. A Ferrovia do Diabo (linha férrea na floresta)

**Premissa.** Começo do século XX, ou um presente em que ela foi esquecida. Uma ferrovia abandonada atravessa a floresta, e o hospital da companhia ficava na estação central. O protagonista precisa atravessar a linha de uma estação até a outra.

**Por que combina.** O facão finalmente tem mato para abrir. A estrutura é naturalmente uma sequência de **estações (pontos de respiro)** ligadas por **trechos de trilho (perseguição)**. Os vagões são corredores perfeitos para fuga.

**Áreas.** Estações (de madeira, com relógio parado), vagões tombados, ponte sobre o rio, cemitério da companhia, acampamento dos trabalhadores, o hospital da companhia, uma locomotiva que pode ser religada.

**Humanos.** Seringueiros que ainda vivem na mata, o maquinista enlouquecido, a companhia que nunca desistiu.

**Mutantes.** *Os Febris* (trabalhadores tomados por algo que veio da água), *o Dormente* (fundido aos trilhos e dormentes), criaturas que vivem no rio.

**Ganchos.** Viagem de trole entre as estações. Clareiras abertas a facão, com mato que fecha atrás de você. Chuva que apaga a lanterna.

**Viabilidade.** Média. A floresta é a parte cara em low poly: árvores em cartões cruzados à moda N64 e neblina pesada resolvem.

---

### D. Vila Michigan (cidade-empresa engolida pela selva)

**Premissa.** Uma cidade americana inteira no meio da floresta: casas de madeira com varanda, caixa-d'água, cinema, hospital moderno para a época. Uma praga da seringueira passou para as pessoas. É horror de fungo e planta, ao lado do mutante cirúrgico.

**Por que combina.** É o "familiar subvertido" que a pesquisa aponta: subúrbio limpo, comprido demais, no lugar errado. Dá um visual que não se parece com nada que já existe.

**Áreas.** Rua principal, casas (todas iguais, o que confunde de propósito), serraria, caixa-d'água (vista do mapa), seringal, hospital da empresa, o porto no rio.

**Mutantes.** *Os Brotados* (látex e raízes saindo do corpo), *a Árvore* (ninho fixo que se espalha) e o Interno, vindo do hospital.

**Viabilidade.** Alta para as casas, que são modulares e repetidas (bom para o orçamento), e média para a vegetação.

---

## 4. Ideias que servem para qualquer cenário

### 4.1 O mutante sem olhos deveria ouvir, não ver

Hoje `scripts/enemies/enemy.gd` usa visão de 8 m com raio de linha de visada. Mas o modelo **não tem olhos**. Trocar a visão por **audição** deixa tudo coerente e cria jogo:

| Ação do jogador | Ruído | Raio aproximado |
|---|---|---|
| Andar | baixo | 3 m |
| Correr | alto | 10 m |
| Golpe de facão / porta | alto | 8 m |
| Parado | nenhum | — |

Correr passa a ter **dois custos**: fôlego e barulho. Fugir correndo chama outros. Andar devagar perto dele vira a tensão central. É um ajuste pequeno no código: o mutante testa a distância do ruído em vez da linha de visada.

### 4.2 Portas que o monstro não atravessa

O mutante tem 2,18 m, e uma porta antiga de 1,90 a 2,00 m não o deixa passar. Isso cria **rotas seguras legíveis**: o jogador aprende a ler a arquitetura (porta baixa e estreita é refúgio) e o mapa ganha uma camada sem nenhum sistema novo. Mais tarde, uma criatura menor (os Pequenos) quebra essa regra.

### 4.3 Medidas para o greybox

- Corredor: no mínimo 1,6 m de largura (a cápsula do mutante tem 0,7 m, e ele precisa virar).
- Porta normal: 2,4 m de altura. Porta de refúgio: 1,9 m.
- Algo que quebre a linha de visada a cada 6 a 8 m nos trechos de perseguição: o mutante corre 1,45 m/s e o jogador abre ~4,6 m durante os 4 s de corrida.
- Sala segura a cada 2 ou 3 áreas, com a regra visível (vela acesa, por exemplo).

---

## 5. Comparativo

| | A. Colônia | B. Vale do Enxofre | C. Ferrovia | D. Vila Michigan |
|---|---|---|---|---|
| Usa o que já existe (mutante, lanterna, facão, capote) | ★★★ | ★★ | ★★★ | ★★ |
| Identidade e originalidade | ★★★ | ★★★ | ★★ | ★★★ |
| Custo de produção low poly | baixo | médio | médio | baixo a médio |
| Mapa interligado com atalhos | ★★★ | ★★ | ★ (linear) | ★★ |
| Peso emocional da história | ★★★ | ★★ | ★★ | ★★ |
| Risco de tema sensível | alto (exige cuidado) | médio | médio | baixo |

## 6. Recomendação

**Começar pela Colônia Santa Clara (A).** É a única proposta em que tudo o que já foi modelado tem uma explicação: a camisola, a pulseira, a lanterna, a neblina, o facão e o braço enfaixado. Ela também é a mais barata de construir e a que mais se presta ao mapa interligado que define o gênero.

As outras não se perdem; podem virar **atos** de um jogo maior. Por exemplo, a viagem até a colônia pela ferrovia (C) como prólogo, ou a origem do soro na cidade-empresa (D) como último ato.

### Primeiro passo concreto: fatia vertical "Pavilhão B"

```
                [Igreja]  <- sala segura
                    |
[Portaria]--[ Pátio central (neblina) ]--[Refeitório]--(atalho, abre por dentro)
                    |                          |
             [Pavilhão B]==porta baixa==[Enfermaria]
             (corredor de leitos,               |
              perseguição)                   [Porão/Usina]  <- chave do gerador
```

1. ✅ *(2026-11-09: `godot_demo/scripts/levels/colonia.gd`, cena principal do projeto)* **Greybox no Godot** com as caixas que `scripts/core/level.gd` já desenha (`_box`) e as medidas de 4.3, testando fuga, porta baixa e atalho.
2. **Mutante por audição** (4.1), testado no greybox.
3. **Kit modular no Blender** (`lowpoly.py`): parede, porta normal e baixa, janela com grade, leito, cruz, lampião de parede. Texturas de 32 px.
4. **Um bilhete, uma ficha de paciente e uma chave**: o mínimo de narrativa e de chave e fechadura.

---

### Fontes
- [GameHaunt: Deconstructing the Level Design of Iconic Horror Mansions](https://gamehaunt.com/deconstructing-the-level-design-of-iconic-horror-mansions)
- [FinalBoss: Resident Evil's Spencer Mansion](https://finalboss.io/resident-evils-spencer-mansion-still-teaches-horror-better)
- [GGRecon: Why are PS1 graphics in horror games so scary?](https://ggrecon.com/articles/why-are-ps1-graphics-in-horror-games-so-scary)
- [Superjump: Through Mist, Light, and Darkness](https://www.superjumpmagazine.com/drafting-through-the-mists/)
- [Game Developer: chase level design in Outlast 2](https://gamedeveloper.com/audio/the-art-of-the-chase-level-design-and-player-orientation-in-i-outlast-2-i-)
- [Game Developer: tension, jump scares and chase sequences](https://gamedeveloper.com/design/creating-horror-through-level-design-tension-jump-scares-and-chase-sequences)
- [Dread Central: Haunting Ground](https://www.dreadcentral.com/editorials/480027/terrifying-chase-haunting-grounds-clever-run-and-hide-horror/)
- [Revista Brasileira de Enfermagem: hospitais-colônia](https://doaj.org/article/441d971117d54196977f6a053ab66473)
- [VICE: Memórias do isolamento](https://www.vice.com/pt/article/memorias-do-isolamento/)
- [Revista Mirabilia: hospitais-colônia](https://www.revistamirabilia.com/sites/default/files/medicinae/pdfs/med_2015-02-03_0.pdf)
- [NSC Total: Cubatão, o Vale da Morte](https://www.nsctotal.com.br/noticias/vale-da-morte-como-esta-a-cidade-brasileira-que-ja-foi-a-mais-poluida-do-mundo)
- [Toda Matéria: desastres ambientais no Brasil](https://www.todamateria.com.br/desastres-ambientais-no-brasil/)
- [Correio Braziliense: a Ferrovia do Diabo](https://www.correiobraziliense.com.br/cbradar/a-capital-que-nasceu-de-uma-ferrovia-a-cidade-construida-as-margens-do-rio-madeira-em-torno-da-lendaria-ferrovia-do-diabo/)
- [Fiocruz: malária na Madeira-Mamoré](https://agencia.fiocruz.br/sites/agencia.fiocruz.br/files/revistaManguinhosMateriaPdf/RM02pag45a46Fio_0.pdf)
- [Wikipedia: Fordlândia](https://wikipedia.com/wiki/Fordlandia)
- [Culture Trip: Fordlândia](https://theculturetrip.com/south-america/brazil/articles/fordlandia-the-ill-fated-1920s-prohibition-town-henry-ford-built-in-the-amazon)
- [IHU Unisinos: Fordlândia em ruínas](https://ihu.unisinos.br/545222-em-ruinas-cidade-construida-por-henry-ford-na-amazonia-aguarda-tombamento-como-patrimonio-historico-brasileiro)
