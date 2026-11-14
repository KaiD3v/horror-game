# Melhorias sutis

Ideias de upgrades que crescem com o jogo sem virar árvore de habilidades. Hoje só existem o coração de ex-voto
(mais vida) e a conta de terço (mais fôlego); dinheiro, virotes e curas não têm limite.

## Regras

1. **O limite é um objeto que dá para imaginar.** Seis virotes amarrados num pano, não "6/6". O número só aparece na
   hora em que importa: na loja e ao pegar algo que não cabe.
2. **A melhoria vem de alguém ou de algum lugar.** Ela vem de uma pessoa (Tenório, Seu Dito, Firmina) ou de uma casa
   explorada, quase nunca da prateleira. Cada uma tem uma frase, um dono e um porquê.
3. **Dois ou três degraus, no máximo.** Cada degrau tem que mudar uma decisão. Se só mexe numa conta, não entra.
4. **O que sobra não some.** Virote que não cabe fica no chão, dinheiro fica guardado com alguém. A escolha é voltar
   ou não para buscar.
5. **Troca, não só ganho, onde couber.** A luz mais forte também é vista de mais longe. É jogo de terror: ficar mais
   forte também chama atenção.
6. **Proibido:** juntar material, receita, "nível 1/5" e loja de melhorias.

## As ideias

### 1. Virotes: o pano, a aljava, a bolsa de cinto *(recomendada)*

| Degrau | Cabe | De onde vem |
|---|---|---|
| Pano amarrado | 6 | O começo: os 6 virotes iniciais já enchem. |
| Aljava de couro | 12 | Do Tenório, nas garrafas. **Já existe** e hoje só abafa o barulho; passa a guardar também. |
| Bolsa de cinto | 18 | O Seu Dito costura de lona de caminhão se você levar um pedaço de lona (o banco do carro caído na ravina, por exemplo). |

- O armeiro só vende o que cabe: "Não cabe mais, freguês. Volta quando gastar."
- Ao passar por um virote que não cabe: "Não cabe mais nenhum." Ele fica lá.
- Pede pouca coisa nova: `Inventory.add` passa a respeitar o teto, a loja confere o espaço e o pickup avisa.
- **Por que muda o jogo:** hoje dá para chegar ao Porteiro com 40 virotes. Com teto, cada tiro pesa, e voltar para
  pegar os virotes do chão vira decisão.

### 2. Dinheiro: o bolso, o porta-níquel, a capanga *(recomendada, com cuidado)*

| Degrau | Cabe | De onde vem |
|---|---|---|
| Bolso da calça | Cr$ 60 | O começo. |
| Porta-níquel | Cr$ 120 | Achado: a bolsa de mola da professora, ou na casa do motorista. |
| Capanga de couro | Cr$ 250 | Do Seu Bento, depois do porão ("Era do meu pai. Leva."). |

- **O que passa do teto fica com o Bento:** "Deixar guardado". Ele anota no caderno de fiado, que agora fica ao
  contrário: é ele quem deve a você. Dá para buscar a qualquer hora na venda, só de dia, quando ela está aberta.
- **Cuidado:** limitar dinheiro só funciona se ele entra mais rápido do que sai. Hoje se ganha pouco (baús, tarefas,
  palitinho). Antes de pôr o teto, contar quanto dinheiro existe no vilarejo; se nunca passar de Cr$ 100, o teto não
  morde e não vale fazer.

### 3. Curas: o bolso do paletó, o embornal, a maleta da enfermeira *(recomendada)*

| Degrau | Cabe (ataduras + garrafadas) | De onde vem |
|---|---|---|
| Bolso do paletó | 2 | O começo. |
| Embornal de pano | 4 | Da Firmina, depois do escapulário ("Pra levar as ervas direito"). |
| Maleta de couro | 6 | Da Celina, a enfermeira, na casa dela: uma maleta de primeiros socorros com o nome bordado. |

- **Por que muda o jogo:** hoje dá para comprar todo o estoque da venda e virar tanque. Com teto, curar vira escolha
  de quando, e a garrafada (2 corações num espaço só) passa a valer mais que duas ataduras.

### 4. Besta: a alavanca de pé de cabra

- O "pé de cabra" de verdade é uma alavanca de armar besta (o nome em inglês é *goat's foot lever*). O armeiro vê o
  seu pé de cabra e diz: "Isso aí arma besta, sabia? Me empresta uma noite."
- No dia seguinte devolve o pé de cabra (continua abrindo tábuas) e a besta passa a recarregar mais rápido.
- Um degrau só. Custa uma noite sem pé de cabra, que é o preço de verdade.

### 5. Lamparina: o pavio e o lampião

- **Pavio novo** (Bento, barato): a chama para de piscar. Ela não fica mais forte, fica mais confiável. Pequeno, mas
  sentido.
- **Lampião de camisinha** (Seu Dito, caro): ilumina o dobro, mas chia (dá para ouvir) e a Carpideira e as mães veem
  de mais longe. **Escolhe-se** qual levar, como o facão e a besta. Uma troca de verdade, não um ganho puro.
- O combustível ficou de fora de propósito: querosene acabando é um sistema inteiro de controle. Só valeria num
  modo difícil.

### 6. Lembranças: guardar ou devolver

Hoje as lembranças são entregues e viram história (o escapulário para a Firmina, o relógio para o Seu Dito). Algumas
podem ter um efeito pequeno **enquanto você carrega**, e aí devolver custa algo:

- **Medalha de São Cristóvão** (protetor de quem atravessa, hoje sem uso): carregando, a queda segura vai de 2,2 m
  para 3 m. Quem a quer de volta: alguém da Colônia, mais tarde (a mulher do Abílio?). Devolver dá a história; guardar
  dá o pulo.
- A regra é uma só: o efeito é pequeno e o livro de itens diz o que é ("Protege quem atravessa"), sem número.

### 7. Passos: a alpargata

- **Alpargata de corda** (Seu Dito): os passos agachados quase não fazem barulho. Mexe só na furtividade, que já é o
  centro do jogo de noite (Poceiro, Carpideira, procissão).
- Um degrau só. O `rattle()` já existe: é o mesmo lugar onde a aljava abafa.

### Ficaram de fora (e por quê)

- **Mochila com espaço total / grade de inventário:** é inventário em tetris, chato e fora do tom.
- **Facão afiado / dano maior:** o combate é para ser evitado; deixar o facão mais forte empurra para o lado errado.
- **Velas para salvar** (tipo fita de tinta do Resident Evil): combina com o oratório e com o Bento ("vela eu tenho
  muita"), mas pune quem tem pouco tempo para jogar. Só num modo difícil, se um dia existir.

## Ordem sugerida

1. **Virotes** (a aljava já existe; é o que mais muda o combate).
2. **Curas** (mesmo sistema de teto; aproveita a Firmina e a Celina).
3. **Alavanca da besta** e **alpargata** (um degrau cada, fechadas).
4. **Dinheiro**, depois de contar o dinheiro do vilarejo.
5. **Lampião** e **medalha**, que mexem na percepção dos inimigos e pedem mais testes.

Virotes e curas compartilham o mesmo código: um teto por tipo (`municao`, `cura`), lido do objeto que você carrega.
