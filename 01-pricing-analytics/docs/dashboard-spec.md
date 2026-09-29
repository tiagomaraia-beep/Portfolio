# Especificação do dashboard — pricing de catálogo

Oito páginas, uma pergunta por página, a resposta escrita no canto superior esquerdo e
nenhum KPI sem comparação. As formas de gráfico e a paleta seguem o método da skill
`dataviz`: a forma é escolhida pelo **trabalho que o dado precisa fazer**, e a cor é
**calculada e validada**, não escolhida por gosto.

**Nada aqui foi renderizado.** É especificação e paleta validada por script; o
`docs/passo-a-passo-powerbi.md` é o roteiro de construção e a conferência visual é no
Desktop do Tiago.

> **Versão 3.** A narrativa mudou com a entrega da deflação, e ela mudou para melhor.
> O relatório agora conta que **o tijolo barateou 26% em poder de compra** e que
> **a migração da escada de preços é quase toda etiqueta, não bolso**. A leitura
> nominal não foi descartada: virou o contraponto, porque é ela que descreve a
> arquitetura de preço que o comprador via na prateleira.

---

## 1. Grade e anatomia de página

Canvas **1280 × 720** (`Formatar página > Tamanho da tela > Personalizado`).
Margem externa 24 px, medianiz 16 px. Toda página repete a mesma anatomia:

| Bloco | Posição (x, y, l × a) | Conteúdo |
|---|---|---|
| **Pergunta da página** | 24, 24, 1232 × 44 | a pergunta, 20 pt, tom primário |
| **Resposta** | 24, 84, 396 × 176 | **canto superior esquerdo**: figura-manchete (≥ 48 px) + frase de resposta em 14 pt |
| **Linha de KPI** | 436, 84, 820 × 104 | 3 ou 4 cartões de 196 × 104, medianiz 16 |
| **Visual principal** | 436, 200, 820 × 360 | o gráfico que sustenta a resposta |
| **Visual de apoio** | 24, 272, 396 × 288 | o recorte que impede a leitura ingênua |
| **Rodapé** | 24, 572, 1232 × 124 | ressalvas, sentinela de escopo, navegação |

**Figura-manchete: exatamente uma por página.** Se duas coisas disputam o tamanho 48 px,
a página tem duas perguntas e precisa virar duas páginas.

**Nenhum KPI sem comparação.** Todo cartão é `rótulo · valor · delta contra uma base
nomeada`. A base é dita por extenso — "vs. 2007", "vs. tema próprio", "vs. leitura
nominal" — nunca uma seta solta.

**Delta não é colorido.** Isto é análise de catálogo, não desempenho contra meta: preço
por peça cair não é bom nem ruim. Cartão em Power BI colore variação de verde e vermelho
por padrão, e isso importaria um juízo de valor que a métrica não tem. Deltas em tinta
secundária (`#52514E`) com sinal explícito. Cor com valência fica reservada para estado, e
neste relatório **não há nenhum**.

---

## 2. Paleta — validada, não escolhida

A skill `dataviz` manda rodar o validador em vez de olhar. O validador dela é Node, que
não está instalado nesta máquina, então portei a matemática para Python (OKLab, simulação
Machado-Oliveira-Fernandes 2009 em severidade 1,0, contraste WCAG) e **reproduzi primeiro
os números documentados da paleta de referência** — pior par adjacente ΔE 9,1 em claro e
8,4 em escuro, piso de visão normal 19,6 e 19,3 — antes de validar os meus recortes.

| Uso | Cores | Resultado |
|---|---|---|
| Categórico de 2 séries (real × nominal; licenciado × próprio) | `#2A78D6` · `#EB6834` | ΔE CVD **24,7** · visão normal **33,6** · contraste ≥ 3:1 — passa tudo |
| Categórico de 3 séries (gráfico indexado) | `#2A78D6` · `#EB6834` · `#1BAF7A` | ΔE CVD **9,2** (todos os pares) · visão normal **24,0** — passa; aqua a 2,74:1 exige **rótulo direto visível**, que o gráfico tem |
| Rampa ordinal de 5 degraus (faixas de preço) | `#86B6EF` `#5598E7` `#2A78D6` `#1C5CAB` `#104281` | monotônica, menor salto de L **0,093** (piso 0,06), ponta clara **2,06:1** (piso 2,0), matiz único (3°) — passa |
| Rampa sequencial (mapa de calor) | `#CDE2FB` → `#3987E5` → `#0D366B` | contínua, um matiz, mais escuro = mais |
| De-ênfase | `#898781` (3,5:1) | cinza para "o resto", nunca uma cor de série |
| Tinta | primária `#0B0B0B` · secundária `#52514E` · eixo `#898781` | texto **nunca** veste a cor da série |
| Grade e eixo | `#E1E0D9`, fio de 1 px, **sólido** | tracejado lê como projeção |

### A convenção de cor das duas bases — fixa no relatório inteiro

> **Real (USD 2022) = slot 1, azul `#2A78D6`. Nominal = slot 2, laranja `#EB6834`.**

Vale em toda página que mostra as duas. A cor segue a **entidade** (a base), nunca a
posição no gráfico nem o valor — se um filtro inverter qual das duas está por cima, as
cores não trocam de dono. O azul é a base real porque ela é a leitura principal da peça;
o laranja é o contraponto.

**Por que a faixa de preço tem cinco degraus e não seis.** A rampa de uma cor só sustenta
cinco degraus com salto de luminosidade perceptível nesta base: testei as 1.716
combinações de seis degraus da rampa azul e **nenhuma** passa — o piso de 0,06 de ΔL e o
piso de 2:1 de contraste da ponta clara não cabem juntos em seis passos. Em vez de forçar
uma sexta cor (que, para um leitor com deuteranopia, seria a mesma que a quinta), as duas
faixas de topo se fundem em `US$ 100 ou mais`. As seis continuam inteiras na matriz de
tabela da mesma página. **Restrição de cor virou decisão de edição, não gambiarra.**

**Sem gráfico divergente neste relatório.** A paleta tem o par azul↔vermelho documentado e
ele não é usado: a única candidata seria a variação ano a ano, onde a polaridade já está na
**posição** da barra em relação à linha zero. Pintar a barra negativa de vermelho
acrescentaria "isso é ruim" a um número que não é ruim.

**Modo escuro.** Um relatório do Power BI não troca de superfície sozinho — adota uma.
Este adota a clara (`#FCFCFB`). Os degraus escuros equivalentes, validados como conjunto
contra `#1A1A19`: séries `#3987E5` `#D95926` `#199E70`; rampa ordinal `#184F95` `#256ABF`
`#3987E5` `#6DA7EC` `#9EC5F4`; tinta `#FFFFFF` / `#C3C2B7`; grade `#2C2C2A`. Não é o tema
claro invertido — são degraus escolhidos para a faixa escura.

O arquivo pronto está em `theme/lego-analytics-tema.json`.

---

## 3. As oito páginas

Convenção: **[P]** = página com filtro `fato_sets[flag_escopo_pricing] = 1` +
`dim_calendario[flag_preco_confiavel] = 1`, título via `[Título de escopo — preço real]`
ou `[… nominal]` conforme o visual, sentinela no rodapé. **[C]** = catálogo completo,
título via `[Título de escopo — catálogo]`.

---

### Página 1 — Resumo **[P]**
**Pergunta:** *O que aconteceu com o preço deste catálogo em quinze anos?*

**Resposta (canto superior esquerdo).** Figura-manchete: **73,6** (índice de preço por
peça em dólares de 2022, 2007 = 100). Frase: *"O tijolo ficou 26% mais barato. O set ficou
68% maior. Em dólar corrente nada disso aparece."*

**KPI (4 cartões, todos com comparação):**

| Cartão | Medida | Comparação |
|---|---|---|
| Preço por peça (real) | `Preço por peça (real, USD 2022)` | `Variação do preço por peça vs. primeiro ano (real)` → **−26,4% vs. 2007** (nominal: +3,9%) |
| Preço médio por set (real) | `Preço médio por set (real, USD 2022)` | `Variação do preço médio por set vs. primeiro ano (real)` → **+23,8% vs. 2007** (nominal: +74,8%) |
| Peças por set | `Peças por set` | `Variação de peças por set vs. primeiro ano` → +68,3% vs. 2007 |
| Prêmio de licença | `Prêmio de licença por peça (nominal)` | contra tema próprio → +0,4% |

Os dois primeiros cartões trazem o número nominal entre parênteses no subtítulo. É a
forma mais compacta de dizer "as duas leituras existem e divergem" sem gastar um cartão.

**Visual principal — gráfico de linhas indexado, três séries, eixo único.**
Eixo X `dim_calendario[ano]`; valores `Índice de preço por peça (real, primeiro ano = 100)`,
`Índice de preço médio por set (real, primeiro ano = 100)` e
`Índice de peças por set (primeiro ano = 100)`. Cores nos três primeiros slots; legenda
presente e as três pontas com rótulo direto (**73,6**, **123,8**, **168,3**).
Linha de 2 px, marcador de ponta ≥ 8 px com anel de 2 px na cor da superfície.
*Por que indexado:* três medidas em escalas incomparáveis (0,10 / 67,96 / 663) no mesmo
gráfico só é honesto com base comum em um eixo. **Eixo duplo está proibido** — é o erro
número um de gráfico e inventa correlação que o dado não tem.
*O que o gráfico mostra de uma vez:* uma linha descendo e duas subindo. O tijolo
barateando enquanto o set encarece e cresce — o achado 1 inteiro, num visual.

**Visual de apoio — as mesmas três séries em valor absoluto**, três mini-linhas empilhadas
sem eixo Y rotulado, rótulo só na ponta. Existe para que ninguém precise confiar no índice
sem ver o número de verdade.

**Rodapé:** sentinela · *"Base real: USD constantes de 2022, CPI-U (BLS). A leitura
nominal está na página 2, e ela diz o contrário."* · botões de navegação.

---

### Página 2 — Unit economics **[P]**
**Pergunta:** *O tijolo encareceu?*

**Resposta:** figura-manchete **−26,4%**, frase *"Em dólar corrente, o preço por peça subiu
3,9%. Em poder de compra, caiu 26,4%. As duas frases são verdadeiras."*

**KPI:** preço por peça real em 2022 (US$ 0,1025 · −26,4% vs. 2007) · preço por peça
nominal em 2022 (US$ 0,1025 · +3,9% vs. 2007) · pico real da série (0,1684 em 2013 ·
índice 121,0) · sets no escopo (4.626 · 25,1% do catálogo).

O primeiro e o segundo cartão têm **o mesmo valor em 2022 e deltas opostos**. Isso não é
erro: 2022 é o ano-base da deflação, então nele as duas bases coincidem por construção.
O subtítulo do segundo cartão diz isso em uma linha.

**Visual principal — duas linhas na mesma escala, `Preço por peça (real, USD 2022)` e
`Preço por peça (nominal)`.** Eixo X `dim_calendario[ano]`. Real em azul, nominal em
laranja, legenda presente, rótulo direto nas quatro pontas (2007: 0,1392 e 0,0986;
2022: 0,1025 nos dois).
*Por que duas linhas num eixo só, se "eixo duplo é proibido":* porque **não são duas
escalas** — as duas séries estão em dólares por peça. O que a proibição veda é alinhar
arbitrariamente duas unidades diferentes; aqui a unidade é a mesma e a distância entre as
linhas *é* a informação (é a inflação acumulada).
*O que o gráfico faz sozinho:* as duas linhas **convergem em 2022**, porque o fator de
deflação daquele ano é 1,0. A convergência explica a deflação sem uma palavra — e, de
quebra, é um teste: se elas não se encontrarem no último ponto, a coluna deflacionada veio
errada.

**Visual de apoio — barras de `Variação a/a do preço por peça (real)`**, uma cor só
(slot 1), crescendo dos dois lados da linha zero. Sem cor divergente, pelo motivo da
seção 2.

**Rodapé:** sentinela · *"Preço por peça é `DIVIDE(SUM(preço); SUM(peças))` — razão dos
totais. A média das razões daria 0,1657 no mesmo escopo, 53% acima. E a deflação é linha a
linha: aplicar um fator médio ao agregado daria 0,1333, 3,7% acima."*

---

### Página 3 — A categoria **[P]** · ⚠ análise secundária
**Pergunta:** *A LEGO barateou junto com a categoria de brinquedos?*

**Resposta:** figura-manchete **247**, frase *"Não. A LEGO barateou 26% em poder de compra;
a categoria barateou 70%. A marca se posicionou acima da própria categoria."*

**KPI:** LEGO, preço por peça real (−26,4% · 2007→2022) · CPI de brinquedos real (−70,2% ·
mesmo período) · CPI-U geral (+41,1% nominal · a régua) · LEGO contra a categoria (índice
247,1 · base 2007 = 100).

**Visual principal — duas linhas indexadas**, `Índice de preço por peça (real, primeiro ano
= 100)` e `Índice CPI de brinquedos (real, primeiro ano = 100)`, eixo X `dim_calendario[ano]`,
filtro de visual `dim_calendario[flag_cpi_toys_disponivel] = 1`.
Real da LEGO em azul, categoria em laranja, rótulo direto nas duas pontas (73,6 e 29,8).
*Por que o índice-razão não entra como terceira linha:* ele chega a 247 enquanto as outras
duas vivem entre 30 e 120; plotado junto, achata as duas que importam. Ele é a
figura-manchete, que é a forma certa para "um número é o ponto".
*Por que o filtro de flag:* `cpi_toys_media_anual` é `NULL` de 1970 a 1977 — a série do BLS
começa em 1978. Sem o filtro, o gráfico desenha a linha caindo a zero no começo, e um ponto
que não existe na fonte vira um dado na tela.

**Visual de apoio — caixa de texto, não gráfico: a ressalva.** É o elemento mais
importante da página e por isso ocupa a área do visual de apoio inteira, com fundo
`#F9F9F7` e fio de 1 px:

> **Este número indica direção, não magnitude.** O CPI de brinquedos é ajustado
> hedonicamente pelo BLS e é dominado por eletrônico e videogame, onde a capacidade por
> dólar explodiu — quedas de índice que não correspondem a etiquetas caindo na prateleira.
> "Brinquedos" não é "set de construção". E nosso preço por peça é uma correção de
> qualidade caseira, não hedonia. **Formulação defensável:** *"a LEGO se posicionou acima
> da categoria"*. **Indefensável:** *"a LEGO ficou 147% mais cara que os concorrentes"*.

*Por que a ressalva é um visual e não um rodapé:* porque é o número mais citável e mais
perigoso do relatório. Quem tira print desta página tem de levar a ressalva junto.

**Rodapé:** sentinela · *"O índice relativo é idêntico nas duas bases, porque o CPI-U
cancela na razão — serve de checagem da conta, não de atestado da leitura."*

---

### Página 4 — Prêmio de licença **[P]**
**Pergunta:** *Tema licenciado cobra prêmio, a peças comparáveis?*

**Resposta:** figura-manchete **+0,4%**, frase *"No preço do tijolo, não. O licenciado
custa mais porque é maior — e entrega personagem."*

**KPI:** preço médio (US$ 52,01 · +18,7% vs. próprio) · peças por set (480 · +18,2% vs.
próprio) · minifigs por mil peças (5,97 · **+47%** vs. próprio, 2018–2022) · preço por peça
(0,1084 · +0,4% vs. próprio).

**Visual principal — barras agrupadas por faixa de tamanho de set**, eixo
`dim_faixa_tamanho[faixa_tamanho]` (5 baldes com peças informadas, ordenados por
`dim_faixa_tamanho[ordem_faixa]`), duas séries (`Preço por peça — licenciado (nominal)` e
`— próprio (nominal)`) nos slots 1 e 2, legenda presente e rótulo direto nas duas barras
de "Até 99 peças", que é onde mora a armadilha.
*Por que por faixa de tamanho e não no agregado:* o agregado diz +0,4% e some com a
história. Por faixa aparecem os dois extremos que enganam — **−36,4% nos sets pequenos
(é Duplo) e +22,9% nos grandes (é a linha adulta própria)**.
*Por que o campo vem da dimensão:* `dim_faixa_tamanho` substituiu as colunas que este
relatório derivava no Power Query. Rótulo e ordem são idênticos; a origem do campo não.

**Visual de apoio — barras de preço por peça por tema** (temas com ≥ 40 sets no escopo),
ordenado decrescente, **forma de ênfase**: todas no slot 1; as de grupo `Pre-school` e
`Junior` no cinza de de-ênfase, com legenda de duas entradas (`tema` /
`pré-escolar e júnior — peça maior`). Botão de indicador alterna para
`Preço por peça (nominal, ex-pré-escolar e júnior)`.
*Por que ênfase e não oito cores:* a história é "estas quatro posições do topo não são
pricing, são geometria de peça". Oito matizes enterrariam exatamente esse ponto.

**Rodapé:** sentinela · *"Esta página usa a base nominal, e isso é uma escolha: dentro de
um mesmo ano as duas bases dão o mesmo prêmio, porque o deflator cancela na razão. Os
números por faixa de tamanho agregam dezesseis anos, e aí a base importa — o prêmio real
da faixa 'até 99 peças' é −39,2% contra −36,4% nominal, porque o set licenciado é
sistematicamente mais novo. A medida `Prêmio de licença por peça (real, USD 2022)` está no
modelo e entra na matriz da visão de tabela."* · *"Duplo: 0,6825 por peça contra 0,1037 do
System — peça fisicamente maior, não decisão de preço."*

---

### Página 5 — Escada de preços **[P]**
**Pergunta:** *A escada de preços subiu — para o comprador, ou só na etiqueta?*

**Resposta:** figura-manchete **−0,8 p.p.**, frase *"Só na etiqueta. Em poder de compra, a
fatia acima de US$ 50 ficou parada: 38,6% em 2007, 37,8% em 2022."*

**KPI:**

| Cartão | Valor | Comparação |
|---|---|---|
| Share acima de US$ 50, **real** | 37,8% | **−0,8 p.p. vs. 2007** (era 38,6%) |
| Share acima de US$ 50, **nominal** | 37,8% | **+20,1 p.p. vs. 2007** (era 17,7%) |
| Mediana **real** | US$ 39,99 | **−5,5% vs. 2007** (era US$ 42,33) |
| Média **real** | US$ 67,96 | **+23,8% vs. 2007** (era US$ 54,89) |

Os dois últimos cartões são o achado: **a mediana real cai e a média real sobe.** O set
típico não ficou mais caro; a cauda de cima engordou. Um par de cartões diz isso melhor que
qualquer gráfico.

**Visual principal — dois gráficos de coluna empilhada 100%, lado a lado** (múltiplos
pequenos), cada um 402 × 360 dentro da área do visual principal:

| | Esquerda | Direita |
|---|---|---|
| Título | `Escada nominal — a etiqueta` | `Escada real — o bolso` |
| Valor | `Participação da faixa no mix (nominal)` | `Participação da faixa no mix (real, USD 2022)` |
| Legenda | `dim_faixa_preco[faixa_preco_5]`, **visível** | mesma, **oculta** |
| Eixo X | `dim_calendario[ano]` | idem, mesma escala |

Mesma rampa ordinal de 5 degraus nos dois, vão de 2 px na cor da superfície entre
segmentos — nunca borda desenhada em volta. Rótulo dentro do segmento só onde couber com
folga.
*Por que múltiplos pequenos e não duas séries no mesmo gráfico:* são duas composições
completas, cada uma somando 100%. Sobrepor seria ilegível; indexar não se aplica a share.
Lado a lado, com eixo idêntico, a comparação é direta — a esquerda **inclina**, a direita
**não**.
*Por que a legenda aparece só uma vez:* o Power BI não compartilha legenda entre visuais;
duas legendas idênticas a 40 cm de distância são ruído. A da esquerda serve às duas, e uma
caixa de texto de uma linha diz isso.

**Visual de apoio — dois cartões de estatística, sem gráfico**:
`98,8% dos preços terminam em .99` (e subindo: 96,9% nos anos 2000 contra **99,5%** nos
2010) e `141 pontos de preço distintos em 6.982 sets`.
*Por que não histograma:* com 141 valores distintos e 98,8% em `.99`, um histograma de bins
automáticos vira um pente — barras altas nos `.99` e vales vazios. A faixa fixa é a unidade
de análise correta, e o número solto conta melhor essa parte.
*O que os dois cartões provam:* que **não houve reprecificação**. O ponto de preço não só
ficou rígido, ele enrijeceu. O que mudou foi a composição do portfólio.

**Visão de tabela (obrigatória, mesma página):** matriz `ano` × **as seis faixas originais**
(`dim_faixa_preco[faixa_preco]`), com `Participação da faixa no mix (nominal)`,
`Participação da faixa no mix (real, USD 2022)` e
`Delta de participação vs. primeiro ano (real, USD 2022)` como colunas de valor. É aqui que
as faixas `US$ 100 a 199.99` e `US$ 200 ou mais` voltam separadas, e é a versão acessível
dos dois gráficos empilhados.

**Rodapé:** sentinela · *"A escada nominal não é 'a errada'. Ela é a resposta certa para
arquitetura de preço e ponto psicológico — ninguém deflaciona uma etiqueta, e o `.99` só
existe em dólar corrente. A real é a resposta certa para 'ficou mais caro para quem
compra'."* · *"Share é sobre sets lançados, não unidades vendidas."*

---

### Página 6 — Mix de portfólio **[C]**
**Pergunta:** *De que o portfólio passou a ser feito?*

**Resposta:** figura-manchete **36,9%**, frase *"Mais de um terço dos sets de construção
dos anos 2020 é licenciado. Em 1990 era zero."*

**KPI:** share licenciado nos anos 2020 (36,9% · vs. 0,7% nos anos 90) · sets de construção
nos anos 2020 (1.570 · vs. 4.557 nos 2010, década de 3 anos) · temas ativos em 2022 (35 ·
−3 vs. 2021) · Top 5 do ano (48,1% · +6,5 p.p. vs. 2018).

**Visual principal — colunas de `Share licenciado` por década**, série única, sem legenda,
rótulo direto nas seis colunas (são seis valores; aqui rotular tudo cabe). O filtro de
categoria `Normal` já está dentro de `[Sets de construção]`.

**Visual de apoio — barras horizontais do Top 10 temas de 2022**, `Share do tema no ano`,
ênfase: licenciados no slot 1, próprios no cinza de de-ênfase, legenda de duas entradas.
Barra horizontal porque os nomes são longos.

**Rodapé:** *"`Miscellaneous` é catch-all, não categoria de produto: 48,1% dele é `Gear`
(mochila, chaveiro, relógio). Esta página roda só em categoria `Normal` — sem esse filtro,
`Miscellaneous` apareceria como o maior grupo dos anos 2010, com 42,5%."* · *"2022 é o fim
da base: tema ativo nele não encerrou, só não tem futuro observado."*

---

### Página 7 — Cobertura **[C, com preço e idade informados]**
**Pergunta:** *Onde o catálogo é ralo?*

**Resposta:** figura-manchete **34**, frase *"34 sets para 14–17 anos em cinco anos, contra
639 para 7–9. E o adulto não tem porta de entrada: zero abaixo de US$ 20."*

**KPI:** sets 14–17 anos (34 · contra 639 na faixa de 7–9) · sets 18+ abaixo de US$ 20
(0 · contra 68 acima de US$ 100) · sets 7–9 acima de US$ 200 (0) · cobertura de idade
informada (36,8% do catálogo).

**Visual principal — mapa de calor (matriz com plano de fundo condicional)**, linhas
`dim_faixa_etaria[faixa_etaria]`, colunas `dim_faixa_preco[faixa_preco]` (as seis,
**base nominal** — a pergunta é de sortimento, não de poder de compra), valor `Sets`,
filtros de visual `ano` entre 2018 e 2022 e `ordem_faixa > 0` nas duas faixas. Plano de
fundo por gradiente sequencial de um matiz: mínimo `#CDE2FB`, centro `#3987E5`, máximo
`#0D366B`; número visível em cada célula, em branco ou tinta conforme a luminosidade.
*Por que mapa de calor:* grade de duas dimensões comparando magnitude — o caso canônico. E
**a célula zero é a resposta**, então precisa estar visível como célula pálida com um `0`
escrito, nunca ausente.

**Visual de apoio — barras de `Cobertura de idade informada` por ano** (2015–2022), série
única, rótulo nos dois anos que caem: 2018 (71,1%) e 2019 (69,7%). Prova a ressalva do
rodapé com dado, em vez de só afirmá-la.

**Rodapé (a ressalva mais importante do relatório):** *"`agerange_min` falta em 63,2% do
catálogo e a cobertura oscila entre 69,7% e 91,0% mesmo entre sets recentes. Uma célula
vazia pode ser ausência de produto **ou** ausência de dado — o dataset não distingue. A
leitura defensável é 'entre os sets com idade informada, a faixa adolescente e a entrada
adulta são as mais ralas', não 'a LEGO não atende adolescentes'."*

---

### Página 8 — Qualidade do dado **[C]**
**Pergunta:** *Em que condições estes números valem?*

**Resposta:** figura-manchete **25,1%**, frase *"Um quarto do catálogo sustenta toda
afirmação sobre preço. É pouco — e é o pedaço sobre o qual dá para afirmar alguma coisa."*

**KPI:** sets no escopo de preço (4.626 · de 18.457) · cobertura de preço da fonte em 2007
(66,6% · contra 0,0% nos anos 70 e 80) · cobertura de idade (36,8%) ·
`Minifigs somadas (catálogo)` (22.372 · **é um piso**: 54,5% da origem vinha vazio e virou
zero).

**Visual principal — colunas de `Cobertura de preço da fonte` por ano**, 1970–2022, série
única, com linha de referência vertical em 2007 rotulada *"corte do escopo"*. É o gráfico
que justifica o projeto inteiro começar em 2007.

**Visual de apoio — funil do escopo em barras horizontais**: 18.457 no catálogo → 12.757 de
categoria `Normal` → 5.168 com preço → 4.988 de 2007 em diante → **4.626** com 20 peças ou
mais. Cada barra rotulada com o número e com o critério que aplica.

**Rodapé:** as oito limitações do resumo executivo de `docs/qualidade-do-dado.md`, em duas
colunas de texto, com destaque para a que mudou de status: *"a limitação nº 1 — preço
nominal — foi resolvida nesta versão. As outras sete continuam de pé."*

---

## 4. Regras de marca e de acessibilidade que valem em todas as páginas

- **Marca fina.** Coluna e barra no máximo 24 px; linha de 2 px; marcador ≥ 8 px com anel
  de 2 px na cor da superfície; preenchimento de área a ~10% de opacidade, nunca bloco
  saturado.
- **Os dois espaçadores.** Vão de 2 px na cor da superfície entre segmentos empilhados e
  entre barras vizinhas; anel de 2 px nos marcadores sobrepostos. **Nunca** uma borda
  desenhada em volta da marca para separá-la.
- **Grade e eixo** em fio de 1 px sólido, `#E1E0D9`, recessivos. Tracejado é proibido.
- **Legenda sempre presente a partir de 2 séries**; série única não tem caixa de legenda,
  porque o título já nomeia o que está plotado.
- **Rótulo direto é seletivo** — a ponta, o extremo, a série que importa. Nunca um número
  em cada ponto.
- **Texto nunca veste a cor da série.** Valor, rótulo e legenda em tinta primária,
  secundária ou de eixo; a identidade vem da marca colorida ao lado do texto. A exceção é
  o rótulo **dentro** de um preenchimento, que escolhe branco ou tinta pela luminosidade.
- **Rótulo que não cabe não é cortado.** Se não couber dentro do segmento com folga, vai
  para fora da ponta, ou para a dica de ferramenta e a matriz. Nunca recortado.
- **Visão de tabela para todo visual.** O Power BI oferece `Modo de foco > Mostrar como
  tabela`; a página 5 ganha uma matriz explícita porque é a que mais depende de cor.
- **Texto alternativo em todo visual** (`Formatar visual > Geral > Texto alternativo`),
  com a **leitura** do gráfico em uma frase, não a descrição da forma. Ex.: *"Preço por
  peça em dólares de 2022 cai de 0,139 para 0,103 entre 2007 e 2022, enquanto a série
  nominal fica plana"*, e não *"gráfico de linhas por ano"*.
- **Um filtro para cada coisa, acima do que ele filtra.** Segmentadores na faixa superior
  da página, nunca dentro do cartão de um visual. Filtro de escopo é filtro de **página**.
- **Sem eixo duplo, em lugar nenhum.** Duas medidas de escala diferente → indexar à base
  comum (páginas 1 e 3) ou dois visuais. Duas medidas na **mesma** unidade podem dividir
  um eixo, e é o que a página 2 faz.
- **Toda página de preço declara a base no título do visual**, por medida de rótulo, nunca
  por texto digitado. Não existe visual de preço sem base declarada.

---

## 5. Tema do Power BI

`theme/lego-analytics-tema.json`, importado por `Exibição > Temas > Procurar temas`. Fixa
as oito cores de dados na ordem validada, a superfície, as tintas, os extremos do gradiente
sequencial e a cor de grade — assim nenhum visual depende de alguém lembrar de pintar à mão.
Ele também traz **rótulo de dados desligado por padrão**, de propósito: rótulo em cada
ponto é ruído e se liga visual por visual, só onde esta especificação pede.

Se o Desktop recusar o arquivo, ele aponta a chave problemática na mensagem: remova a chave
apontada e importe de novo. O bloco `visualStyles` é o candidato mais provável, porque é a
parte do esquema que mais muda entre versões — e o relatório funciona sem ele, só com
`dataColors` e as cores nomeadas.
