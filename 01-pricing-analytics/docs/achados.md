# Achados — pricing analytics de um catálogo de 18.457 produtos

Catálogo LEGO, 1970–2022, lido como um analista lê uma lista de preços. As cinco
perguntas do projeto, respondidas com os números apurados em 2026-09-20 rodando query
contra `data/lego.db`. As queries estão em `sql/03-analises.sql`.

> **Base de preço:** preço de lançamento no varejo dos EUA, apurado em **duas bases** —
> USD nominal (dólar do ano) e **USD constantes de 2022**, deflacionado pelo CPI-U do BLS.
> Onde há série temporal de preço, as duas aparecem. Escopo de preço: 4.626 sets
> (categoria `Normal`, com preço, ≥ 20 peças, 2007–2022) — o universo em que o dado
> sustenta afirmação. Mix e cobertura rodam sobre as 18.457 linhas. As ressalvas
> completas estão em `docs/qualidade-do-dado.md`.

---

## Os três achados que sustentam a peça

**1. O tijolo ficou 26% mais barato. O set ficou 68% maior.**
Em dólar corrente o preço por peça mal se move entre 2007 e 2022 (US$ 0,0986 → 0,1025,
índice 103,9). Corrigido pela inflação, ele **cai 26,4%**: em dólares de 2022, o preço
por peça de 2007 era US$ 0,1392 contra US$ 0,1025 em 2022, índice **73,6**. No mesmo
período o set médio subiu de US$ 54,89 para US$ 67,96 em poder de compra constante
(**+23,8%** real, contra +74,8% nominal) e ganhou 68,3% de peças (394 → 663).
**O comprador de 2022 paga 24% mais, em dinheiro de verdade, por um set 68% maior.**

**2. O prêmio de licença não está no preço por peça — está no tamanho e na minifig.**
No agregado, temas licenciados cobram US$ 0,1084 por peça contra US$ 0,1080 dos temas
próprios: **0,4% de diferença, ou seja, ruído**. O set licenciado custa 18,7% mais caro
(US$ 52,01 contra US$ 43,82) porque tem 18,2% mais peças (480 contra 406). O que ele
entrega a mais é personagem: entre 2018 e 2022, 5,97 minifigs por mil peças contra 4,06
dos próprios — **47% mais densidade de minifig**.

**3. A escada de preços subiu na etiqueta, mas quase não subiu no bolso.**
Em dólar corrente a migração é forte: sets acima de US$ 50 saem de 17,7% do catálogo em
2007 para **37,8%** em 2022. Medida em poder de compra constante, a mesma migração
praticamente **desaparece**: 38,6% em 2007 contra 37,8% em 2022. Um set de US$ 35 em 2007
já era um set de US$ 50 de hoje. A mediana real **caiu 5,5%** (US$ 42,33 → 39,99)
enquanto a média real subiu 23,8% — ou seja, o set típico não ficou mais caro; **a cauda
de cima é que engordou**.

---

## Pergunta 1 — Preço por peça: os unit economics do catálogo

Métrica: `SUM(preço) / SUM(peças)` — razão dos totais, não média das razões (a diferença
entre as duas é de 53% mesmo no escopo limpo; ver `docs/dicionario-de-dados.md`).

| Ano | Sets | ppp nominal | **ppp real** | Índice nom. | **Índice real** | Set médio nom. | **Set médio real** | Peças |
|---|---|---|---|---|---|---|---|---|
| 2007 | 153 | 0,0986 | **0,1392** | 100,0 | **100,0** | 38,89 | **54,89** | 394 |
| 2008 | 185 | 0,1020 | 0,1387 | 103,5 | 99,7 | 39,58 | 53,79 | 388 |
| 2009 | 192 | 0,1208 | 0,1648 | 122,6 | 118,4 | 41,53 | 56,66 | 344 |
| 2010 | 185 | 0,1166 | 0,1565 | 118,2 | 112,4 | 43,21 | 57,99 | 371 |
| 2011 | 223 | 0,1219 | 0,1585 | 123,6 | 113,9 | 36,84 | 47,93 | 302 |
| 2012 | 253 | 0,1184 | 0,1509 | 120,0 | 108,4 | 35,48 | 45,23 | 300 |
| 2013 | 267 | 0,1340 | **0,1684** | 136,0 | **121,0** | 46,67 | 58,63 | 348 |
| 2014 | 312 | 0,1120 | 0,1384 | 113,6 | 99,5 | 37,89 | 46,84 | 338 |
| 2015 | 355 | 0,1138 | 0,1406 | 115,5 | 101,0 | 37,62 | 46,46 | 331 |
| 2016 | 361 | 0,1082 | 0,1319 | 109,7 | 94,8 | 40,93 | 49,91 | 378 |
| 2017 | 352 | 0,1045 | 0,1248 | 106,0 | 89,6 | 46,98 | 56,09 | 450 |
| 2018 | 355 | 0,1072 | 0,1249 | 108,7 | 89,8 | 43,68 | 50,90 | 407 |
| 2019 | 322 | 0,1079 | 0,1236 | 109,5 | 88,8 | 50,83 | 58,19 | 471 |
| 2020 | 355 | 0,1046 | 0,1183 | 106,1 | 85,0 | 55,64 | 62,92 | 532 |
| 2021 | 383 | 0,0964 | **0,1042** | 97,8 | **74,8** | 58,73 | 63,43 | 609 |
| 2022 | 373 | 0,1025 | 0,1025 | 103,9 | **73,6** | 67,96 | 67,96 | 663 |

**Período todo:** 4.626 sets, US$ 214.853,10 de lista nominal (US$ 255.395,21 em dólares
de 2022), 1.986.433 peças. Preço por peça de 0,1082 nominal e **0,1286 real**; set médio
de US$ 46,44 nominal e US$ 55,21 real.

**Leitura de negócio.** A série nominal é plana e enganosa. A série real conta a história:
o preço do tijolo sobe até 2013 (índice real 121,0), estabiliza e depois cai de forma
contínua — 121,0 em 2013 para **73,6** em 2022, uma queda de 39% em nove anos.

A divergência que importa aparece a partir de 2017. O preço por peça real cai 18% de 2017
a 2022 (0,1248 → 0,1025) enquanto o preço médio real do set sobe 21% (56,09 → 67,96) e o
tamanho médio sobe 47% (450 → 663 peças). **Isso é a assinatura de uma estratégia de
ticket médio via tamanho**: a linha adulta de sets grandes puxando a média do catálogo
para cima enquanto o tijolo individual fica mais barato.

Em dólares correntes o set médio subiu 74,8%; em poder de compra, 23,8%. Metade do
"aumento de preço" que aparece no nominal é apenas inflação.

> **Base:** deflacionado pelo CPI-U (BLS, `CUUR0000SA0`), base 2022. Fator de 2007 =
> 1,41146. Metodologia e limites em `docs/qualidade-do-dado.md` seção 1.

### A LEGO contra a própria categoria — *análise secundária, ler a ressalva*

| Série, 2007 → 2022 | Nominal | Real |
|---|---|---|
| CPI-U geral | +41,1% | — |
| LEGO, preço por peça | +3,9% | **−26,4%** |
| CPI de brinquedos (BLS `CUUR0000SERE01`) | −57,9% | **−70,2%** |
| **LEGO contra a categoria** | **+147,2%** | **+147,2%** |

A LEGO barateou 26% em poder de compra; a categoria de brinquedos barateou 70%. Contra a
própria categoria, a LEGO **encareceu cerca de 147%**. O número é idêntico nas duas bases
porque o CPI-U cancela na razão — o que serve de checagem da conta.

> ⚠️ **Este número indica direção, não magnitude.** O CPI de brinquedos é ajustado
> hedonicamente e é dominado por eletrônico e videogame, onde a qualidade por dólar
> explodiu; ele cobre "brinquedos" em geral, não set de construção; e nosso preço por
> peça é uma correção de qualidade caseira, não hedonia do BLS. A formulação defensável é
> *"a LEGO se posicionou acima da categoria"*, não *"a LEGO ficou 147% mais cara que os
> concorrentes"*. Os quatro limites estão em `docs/qualidade-do-dado.md` seção 11.

## Pergunta 2 — Prêmio de licença: tema licenciado cobra mais?

### A resposta agregada

| Tipo | Sets | Preço/peça | Preço médio | Peças médias |
|---|---|---|---|---|
| Licenciado | 1.484 | **0,1084** | US$ 52,01 | 480 |
| Próprio | 3.142 | **0,1080** | US$ 43,82 | 406 |

Prêmio por peça: **+0,4%**. Prêmio por set: +18,7%. Diferença de tamanho: +18,2%.
O prêmio de licença é quase inteiramente explicado pelo tamanho do set.

### Por faixa de tamanho — onde o número engana

Recorte por `dim_faixa_tamanho`, a dimensão de banda de peças do modelo:

| Faixa de tamanho | Sets lic. | Sets próp. | ppp lic. | ppp próp. | Prêmio nominal | **Prêmio real** |
|---|---|---|---|---|---|---|
| Até 99 peças | 206 | 1.072 | 0,1662 | 0,2613 | **−36,4%** | **−39,2%** |
| 100 a 249 peças | 454 | 758 | 0,1204 | 0,1381 | −12,9% | −16,5% |
| 250 a 499 peças | 415 | 568 | 0,1107 | 0,1127 | −1,8% | −4,7% |
| 500 a 999 peças | 275 | 455 | 0,1065 | 0,1077 | −1,1% | −3,1% |
| 1.000 peças ou mais | 134 | 289 | 0,1020 | 0,0830 | **+22,9%** | **+23,8%** |

> **Por que o prêmio real difere do nominal aqui.** Dentro de um mesmo ano os dois são
> idênticos — ambos os lados levam o mesmo deflator e ele cancela (conferido em 2013,
> 2017, 2021 e 2022). Mas estas faixas agregam 16 anos, e o set licenciado é
> sistematicamente mais novo (ano médio 2016,3–2017,4) que o próprio (2014,3–2015,5), de
> modo que deflacionar levanta mais o lado próprio. A faixa de 1.000+ peças confirma pelo
> contrário: ali os anos médios empatam (2017,0 × 2017,1) e o prêmio quase não se move.

Os dois extremos são armadilhas, e as duas foram testadas:

**O −36,4% dos sets pequenos é Duplo.** Duplo tem 273 sets no escopo, peça fisicamente
muito maior e preço por peça de 0,6825 contra 0,1037 do resto. Retirando Duplo e Junior
do recorte de menos de 100 peças, o resultado inverte:

| Cenário (< 100 peças) | Sets | ppp licenciado | ppp próprio |
|---|---|---|---|
| Com pré-escolar/júnior | 1.278 | 0,1662 | 0,2613 |
| **Sem pré-escolar/júnior** | 1.014 | 0,1662 | **0,1638** |

De −36,4% para +1,5%. O "desconto de licença" era geometria de peça.

**O +22,9% dos sets grandes é a linha adulta própria.** Do lado próprio da faixa de
1.000+ peças estão `Art` (12 sets, 48.067 peças, ppp 0,0325), `Icons` (0,0787),
`Creator Expert` (0,0796) e `Advanced models` (0,0697) — produtos muito densos em peça
pequena e barata, que derrubam o denominador dos próprios.

### O prêmio ao longo do tempo — e por que 2021–2022 é diferente

| Ano | ppp licenciado | ppp próprio | Prêmio |
|---|---|---|---|
| 2013 | 0,1095 | 0,1445 | −24,2% |
| 2017 | 0,0989 | 0,1103 | −10,3% |
| 2019 | 0,1099 | 0,1061 | +3,6% |
| 2020 | 0,1095 | 0,1023 | +7,1% |
| **2021** | 0,1106 | 0,0889 | **+24,5%** |
| **2022** | 0,1136 | 0,0966 | **+17,5%** |

Parece que o prêmio de licença finalmente apareceu. Não é isso. Controlando o mix em
2021–2022:

| Grupo (2021–2022) | Sets | Preço/peça |
|---|---|---|
| Licenciado | 322 | 0,1121 |
| Próprio (tudo) | 434 | 0,0929 |
| **Próprio, ex-`Art`/`Icons`/`Creator Expert`/`Advanced models`** | 396 | **0,1084** |

Aquelas 38 linhas adultas concentram **109.845 das 314.460 peças** dos temas próprios no
biênio — 34,9% do denominador vindo de 8,8% dos sets, a 0,0640 por peça. Com elas fora, o
prêmio cai de +20,7% para **+3,4%**.

**Leitura de negócio.** A LEGO não cobra prêmio pela licença no preço do tijolo. Ela
monetiza a licença de três outras formas: sets maiores (+18,2% de peças), mais minifigs
(5,97 contra 4,06 por mil peças entre 2018 e 2022) e presença no topo da escada de preço.
O "prêmio" recente que aparece no agregado é efeito de mix — a própria LEGO lançou uma
linha adulta de peça densa e barata que rebaixou o denominador do lado próprio.

### Os temas, individualmente (≥ 40 sets no escopo)

| # | Tema | Tipo | Sets | Preço/peça | Preço médio |
|---|---|---|---|---|---|
| 1 | Duplo | Próp. | 273 | 0,6825 | 37,94 |
| 2 | Dimensions | Próp. | 59 | 0,2725 | 20,36 |
| 3 | HERO Factory | Próp. | 79 | 0,1852 | 15,07 |
| 4 | Juniors | Próp. | 63 | 0,1660 | 21,96 |
| 5 | Bionicle | Próp. | 103 | 0,1423 | 19,19 |
| 6 | City | Próp. | 455 | 0,1381 | 44,16 |
| 7 | Disney | **Lic.** | 106 | 0,1343 | 42,92 |
| 8 | Star Wars | **Lic.** | 445 | 0,1163 | 66,24 |
| … | | | | | |
| 13 | Technic | Próp. | 183 | 0,1059 | 90,10 |
| 18 | Harry Potter | **Lic.** | 65 | 0,0962 | 77,04 |
| 21 | Ideas | Próp. | 45 | 0,0873 | 113,10 |
| 29 | Classic | Próp. | 41 | 0,0556 | 30,77 |

As quatro primeiras posições são todas de temas **próprios** — pré-escolar, júnior e
linhas de peça grande. O tema licenciado mais bem posicionado é Disney, em 7º. Star Wars,
o maior tema licenciado do catálogo, tem preço médio de US$ 66,24 por set mas fica só em
8º por peça: **caro porque é grande**. Harry Potter é ainda mais extremo — US$ 77,04 de
set médio, terceiro mais alto da lista atrás apenas de Ideas e Technic, e ainda assim
apenas 18º em preço por peça. Os três temas de set médio mais caro (Ideas US$ 113,10,
Technic US$ 90,10, Harry Potter US$ 77,04) ocupam as posições 21ª, 13ª e 18ª por peça:
preço alto de etiqueta e preço baixo de tijolo são a mesma estratégia.

---

## Pergunta 3 — Escada de preços: houve migração de mix para cima?

> **Correção de escopo nesta versão.** Esta pergunta estava respondida sobre
> `Normal + com preço` (168 sets em 2007), enquanto o resto da peça usa
> `flag_escopo_pricing` (153 sets). Agora usa o escopo oficial, como todas as outras.
> A conclusão não muda; a magnitude sim — a mediana de 2007 passa de US$ 24,99 para
> **US$ 29,99** e a variação 2007→2022 de +60,0% para **+33,3%**. Os 15 sets que o escopo
> antigo incluía têm menos de 20 peças: baratos por construção. Detalhe em
> `docs/qualidade-do-dado.md` seção 12.

### Escada nominal — a arquitetura de preços como o comprador via na época

Share de sets por faixa de preço, escopo oficial:

| Ano | ≤ $9,99 | $10–19,99 | $20–49,99 | $50–99,99 | $100–199,99 | $200+ | Sets |
|---|---|---|---|---|---|---|---|
| 2007 | **26,8%** | 18,3% | 37,3% | 13,7% | 3,3% | 0,7% | 153 |
| 2010 | 15,7% | 24,9% | 37,8% | 15,1% | 4,9% | 1,6% | 185 |
| 2013 | 16,1% | 32,2% | 31,1% | 12,4% | 5,6% | 2,6% | 267 |
| 2016 | 24,9% | 22,4% | 31,3% | 15,0% | 3,9% | 2,5% | 361 |
| 2019 | 16,5% | 23,6% | 32,9% | 18,6% | 5,9% | 2,5% | 322 |
| 2021 | 16,2% | 20,9% | 32,9% | 17,8% | 8,1% | 4,2% | 383 |
| **2022** | **11,3%** | 19,8% | 31,1% | **23,3%** | **9,4%** | **5,1%** | 373 |

### Escada real — as mesmas faixas em dólares de 2022

| Ano | ≤ $9,99 | $10–19,99 | $20–49,99 | $50–99,99 | $100–199,99 | $200+ |
|---|---|---|---|---|---|---|
| 2007 | **9,8%** | 18,3% | 33,3% | **28,1%** | 8,5% | 2,0% |
| 2010 | 9,7% | 15,1% | 34,1% | 26,5% | 10,8% | 3,8% |
| 2013 | 7,5% | 26,6% | 30,3% | 21,3% | 9,7% | 4,5% |
| 2016 | 10,2% | 25,5% | 38,0% | 15,0% | 8,0% | 3,3% |
| 2019 | 4,3% | 20,2% | 39,8% | 20,8% | 10,2% | 4,7% |
| 2021 | 5,2% | 17,2% | 40,5% | 20,1% | 11,7% | 5,2% |
| **2022** | **11,3%** | 19,8% | 31,1% | **23,3%** | 9,4% | 5,1% |

### Os dois resumos, lado a lado

| Indicador, 2007 → 2022 | Nominal | **Real (USD 2022)** |
|---|---|---|
| Share acima de US$ 50 | 17,7% → **37,8%** | 38,6% → **37,8%** |
| Share acima de US$ 100 | 4,0% → 14,5% | 10,5% → 14,5% |
| Share até US$ 9,99 | 26,8% → 11,3% | 9,8% → 11,3% |
| **Mediana** | 29,99 → 39,99 (**+33,3%**) | 42,33 → 39,99 (**−5,5%**) |
| **Média** | 38,89 → 67,96 (**+74,8%**) | 54,89 → 67,96 (**+23,8%**) |

**Leitura de negócio.** A migração da escada é quase inteiramente um fenômeno de
etiqueta. Em dólar corrente, a fatia do catálogo acima de US$ 50 mais que dobra
(17,7% → 37,8%) e parece uma reposição agressiva de portfólio para cima. Em poder de
compra constante, essa fatia **fica parada** (38,6% → 37,8%): um set de US$ 35 em 2007 já
ocupava, no orçamento do comprador, o lugar de um set de US$ 50 de hoje.

O que de fato mudou é a **forma da distribuição**, não o seu centro. A mediana real caiu
5,5% enquanto a média real subiu 23,8% — a distância entre as duas é a cauda superior
engordando. Não houve reprecificação da linha: houve adição de produto caro no topo.

Isso é consistente com a pergunta 1 (o tijolo barateando enquanto o ticket sobe) e com a
disciplina de ponto de preço, que **aumentou** no período: a fatia de preços terminados
em `.99` foi de 96,9% nos anos 2000 para **99,5%** nos anos 2010, com apenas 141 pontos
de preço distintos em todo o catálogo.

**Qual das duas escadas vale? As duas, para perguntas diferentes.**
- *Arquitetura de preço e ponto psicológico* → a **nominal**. Ninguém deflaciona uma
  etiqueta, e o `.99` só existe em dólar corrente.
- *O produto ficou mais caro para quem compra?* → a **real**. E a resposta é: o típico,
  não; o topo da linha, sim.

## Pergunta 4 — Mix de portfólio: concentração e rotação de temas

### Licenciamento é a mudança estrutural de trinta anos

Share do grupo `Licensed` no total de sets lançados por década:

| Década | Todos os sets | % licenciado | Só categoria `Normal` | % licenciado |
|---|---|---|---|---|
| 1970s | 652 | 0,0% | 616 | 0,0% |
| 1980s | 1.142 | 0,0% | 1.091 | 0,0% |
| 1990s | 2.094 | 0,6% | 1.968 | 0,7% |
| 2000s | 4.328 | 7,6% | 2.955 | 9,6% |
| 2010s | 7.481 | 19,2% | 4.557 | **24,8%** |
| 2020s (3 anos) | 2.760 | 26,7% | 1.570 | **36,9%** |

Olhando só set de construção, o licenciamento saiu de praticamente zero até 1995 para
**mais de um terço do portfólio** nos anos 2020. É a maior mudança estrutural visível no
dataset.

> **Cuidado com o grupo `Miscellaneous`.** Sem filtrar por categoria, ele aparece como o
> maior grupo dos anos 2010 (42,5%) — mas é um catch-all: 48,1% dele é `Gear`
> (merchandise sem peça), mais `Collectable Minifigures` (13,1%), `Books` (10,7%),
> `Promotional` (10,0%) e `Service Packs` (6,6%). Não é uma categoria de produto.

### Concentração: o portfólio se pulverizou e voltou a concentrar

| Ano | Temas ativos | Sets lançados | Top 5 | Top 10 | HHI |
|---|---|---|---|---|---|
| 2007 | 27 | 449 | 65,9% | 87,1% | **1.898** |
| 2010 | 31 | 529 | 48,2% | 68,8% | 749 |
| 2015 | 38 | 808 | 42,3% | 66,1% | 597 |
| 2018 | 37 | 829 | 41,6% | 67,4% | **561** |
| 2021 | 38 | 944 | 39,8% | 62,2% | 652 |
| 2022 | 35 | 967 | 48,1% | 68,3% | **996** |

HHI = soma dos quadrados dos shares, escala 0–10.000; abaixo de 1.500 é pulverizado.

O catálogo mais que dobrou de tamanho (449 → 967 lançamentos por ano) e se desconcentrou
fortemente entre 2007 e 2018: o HHI caiu de 1.898 para 561 e o Top 5 de 65,9% para 41,6%.
De 2019 em diante a curva reverte — HHI volta a 996 em 2022 e o Top 5 sobe para 48,1%,
com menos temas ativos (35 contra 38 em 2021).

Top 10 de 2022:

| # | Tema | Tipo | Sets | Share |
|---|---|---|---|---|
| 1 | Gear | Próp. | 264 | 27,3% |
| 2 | City | Próp. | 64 | 6,6% |
| 3 | Collectable Minifigures | Próp. | 48 | 5,0% |
| 4 | Ninjago | Próp. | 46 | 4,8% |
| 5 | Star Wars | **Lic.** | 43 | 4,4% |
| 6 | Books | Próp. | 41 | 4,2% |
| 7 | Friends | Próp. | 41 | 4,2% |
| 8 | Super Mario | **Lic.** | 40 | 4,1% |
| 9 | Marvel Super Heroes | **Lic.** | 39 | 4,0% |
| 10 | Creator | Próp. | 34 | 3,5% |

`Gear` sozinho responde por 27,3% dos lançamentos de 2022 — e é o que sustenta boa parte
do HHI. Tirando merchandise, a cabeça do portfólio é `City` + `Ninjago` + `Friends` do
lado próprio e `Star Wars` + `Super Mario` + `Marvel` do lado licenciado.

### Rotação: o portfólio se renova sem crescer em número de temas

| Ano | Estrearam | Encerraram | Saldo | Acumulado |
|---|---|---|---|---|
| 2011 | 8 | 2 | +6 | +7 |
| 2014 | 7 | 5 | +2 | +7 |
| 2017 | 3 | 4 | −1 | +3 |
| 2020 | 8 | 3 | +5 | +8 |
| 2021 | 2 | 6 | −4 | +4 |
| 2022 | 2 | 0 | +2 | +6 |

Em dezesseis anos o saldo acumulado é de apenas **+6 temas**, com cerca de 5 estreias e
4,5 encerramentos por ano. O portfólio **gira muito e cresce pouco**: os lançamentos
anuais dobraram (449 → 967) mas o número de temas ativos subiu só de 27 para 35. Cada
tema carrega mais SKUs. Isso é adensamento de linha, não expansão de linha.

*(O ano de 2022 é o fim da base — tema ativo nele não "encerrou", só não tem futuro
observado. Por isso 2022 não conta encerramentos.)*

---

## Pergunta 5 — Cobertura: onde o catálogo é ralo

Matriz faixa etária × faixa de preço, sets `Normal` com preço e idade informados,
2018–2022:

| Faixa etária | ≤ $9,99 | $10–19,99 | $20–49,99 | $50–99,99 | $100–199,99 | $200+ | Total |
|---|---|---|---|---|---|---|---|
| 1 a 3 anos | 13 | 18 | 23 | 12 | 5 | 2 | 73 |
| 4 a 6 anos | 168 | 113 | 156 | 45 | 4 | 2 | **488** |
| 7 a 9 anos | 36 | 156 | 243 | 160 | 44 | **0** | **639** |
| 10 a 13 anos | 38 | 31 | 17 | 17 | 25 | 8 | 136 |
| **14 a 17 anos** | **0** | **1** | **1** | 9 | 11 | 12 | **34** |
| 18 anos ou mais | **0** | **0** | 5 | 41 | 31 | 37 | 114 |

Células com 5 sets ou menos em cinco anos — os buracos:

| Faixa etária | Faixa de preço | Sets |
|---|---|---|
| 7 a 9 anos | US$ 200 ou mais | **0** |
| 14 a 17 anos | Até US$ 9,99 | **0** |
| 14 a 17 anos | US$ 10 a 19,99 | 1 |
| 14 a 17 anos | US$ 20 a 49,99 | 1 |
| 18 anos ou mais | Até US$ 9,99 | **0** |
| 18 anos ou mais | US$ 10 a 19,99 | **0** |
| 18 anos ou mais | US$ 20 a 49,99 | 5 |
| 1 a 3 anos | US$ 100 a 199,99 | 5 |
| 1 a 3 anos | US$ 200 ou mais | 2 |
| 4 a 6 anos | US$ 100 a 199,99 | 4 |
| 4 a 6 anos | US$ 200 ou mais | 2 |

**Leitura de negócio.** O catálogo tem duas concentrações claras e dois vazios.

As concentrações: 7 a 9 anos (639 sets, o núcleo, espalhado de US$ 10 a US$ 200) e 4 a 6
anos (488 sets, mas 58% deles abaixo de US$ 20 — é a faixa de entrada em preço).

Os vazios são o achado:

1. **Adolescente (14–17) quase não existe** — 34 sets em cinco anos, contra 639 da faixa
   de 7 a 9. E os poucos que existem estão todos em cima: 32 dos 34 custam US$ 50 ou
   mais. Não há produto de impulso para adolescente.
2. **O adulto (18+) não tem porta de entrada.** Zero sets abaixo de US$ 20 e apenas 5
   entre US$ 20 e US$ 50, contra 68 acima de US$ 100. A linha adulta é integralmente de
   alto ticket — o que é coerente com o achado da pergunta 1 (linha adulta puxando o
   ticket médio), mas significa que não existe produto de aquisição para esse público.
3. **Não existe produto premium infantil.** Zero sets acima de US$ 200 na faixa de 7 a 9
   anos, e só 4 acima de US$ 100 na faixa de 4 a 6. O topo da escada de preço é
   inteiramente adulto e adolescente.

**Ressalva que muda a força dessa leitura:** `agerange_min` falta em 63,2% do catálogo, e
mesmo entre sets `Normal` recentes a cobertura oscila entre 69,7% (2019) e 91,0% (2015).
Uma célula vazia acima pode ser ausência de produto **ou** ausência de dado — este
dataset não distingue as duas. A afirmação defensável é *"entre os sets com idade
informada, a faixa adolescente e a entrada adulta são as mais ralas"*, não *"a LEGO não
atende adolescentes"*.

---

## O que este dado não responde

Vale dizer em voz alta, porque é o que separa a leitura sênior da ingênua:

- **Nada sobre receita, margem ou sucesso comercial.** É preço de tabela de lançamento,
  sem unidade vendida, sem desconto, sem custo. Tema com mais sets não é tema que vendeu
  mais — é tema com mais SKUs.
- **Nada antes de 2007** em matéria de preço: a cobertura da fonte é 0% nos anos 70 e 80.
  A deflação não conserta isso — não há preço para deflacionar.
- **Nada sobre preço ajustado por qualidade.** Preço por peça é uma correção caseira
  (peça como proxy de quanto produto vem na caixa), não hedonia. E a peça nem é
  homogênea: uma peça Duplo não é uma peça System.
- **Nada ponderado por vendas.** O deflator é um índice de cesta ponderada por consumo;
  o preço médio aqui é média simples de SKU lançado. Um set que ninguém comprou pesa
  igual a um campeão de vendas.
- **Nada fora dos EUA.** O CPI-U é americano e o preço também.

As ressalvas completas, com os números de cobertura e os vieses medidos, estão em
`docs/qualidade-do-dado.md`.
