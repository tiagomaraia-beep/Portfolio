# Qualidade do dado — o que este dataset **não** permite afirmar

Esta página existe para o lado contrário do dashboard. Todo número apurado no projeto
está em `docs/achados.md`; aqui estão as condições em que ele vale e as perguntas que,
com este dado, **não têm resposta honesta**.

Fonte: `data/lego_sets.csv`, 18.457 linhas, catálogo LEGO 1970–2022 (origem Brickset).
Tudo abaixo foi reapurado com query rodada contra `data/lego.db` em 2026-09-20.

---

## Resumo executivo das limitações

| # | Limitação | Consequência prática |
|---|---|---|
| 1 | ~~Preço é USD nominal~~ → **resolvido nesta versão**: o modelo agora traz preço nominal **e** em USD constantes de 2022 | A leitura nominal e a real divergem fortemente (índice 103,9 × 73,6 em 2022). Todo visual precisa declarar a base. Ver seção 12. |
| 2 | Preço falta em **62,2%** das linhas, e a falta é concentrada antes de 2007 | Nenhuma série de preço começa antes de 2007. Décadas de 70, 80 e 90 são analisáveis só em volume e mix. |
| 3 | É **preço de tabela**, não preço praticado | Não há desconto, promoção, margem, custo ou volume vendido. Não é análise de receita. |
| 4 | "Peça" não é unidade homogênea | Uma peça Duplo não é uma peça System. Preço por peça entre linhas diferentes compara coisas diferentes. |
| 5 | Idade mínima falta em **63,2%** das linhas | A matriz de cobertura por idade descreve o subconjunto informado, não o catálogo. |
| 6 | Minifigs vazio foi convertido para `0` | O total de 22.372 minifigs é um **piso**, não o número real. |
| 7 | **2022 é o fim da base**, não o fim do catálogo | Tema ativo em 2022 não "encerrou": só não tem futuro observado. |
| 8 | Só mercado **EUA** | Nada aqui vale para preço no Brasil, Europa ou Ásia. |

---

## 1. Preço em duas bases — nominal e real

O modelo traz o preço de lançamento em **duas unidades**, e a diferença entre elas é o
achado central da peça, não um detalhe técnico:

- `vl_preco_usd` — dólar **corrente** do ano de lançamento (nominal).
- `vl_preco_usd_2022` — o mesmo preço em **dólares constantes de 2022**.

Fonte do deflator: **BLS, CPI-U, US city average, all items, média anual**, série
`CUUR0000SA0`, em `data/cpi_us_anual.csv`. Fator = `CPI-U(2022) / CPI-U(ano)`.
Referências: CPI-U de 2007 = 207,342 e de 2022 = 292,655, logo o fator de 2007 é
**1,41146**. Em 2022 o fator é 1,0 e o preço real é idêntico ao nominal — o que serve de
checagem e foi conferido (0 divergências).

O fator entregue pela fonte não foi aceito de boca: foi **recalculado nos 53 anos** e
bateu em todos.

**Por que isso vira a leitura do avesso.** Em dólar corrente o preço por peça sobe 3,9%
entre 2007 e 2022. Em dólares de 2022 ele **cai 26,4%**. As duas frases são verdadeiras
e dizem coisas opostas; a segunda é a que responde "ficou mais caro para quem compra?".

**Toda série de preço precisa declarar a base no título.** Não existe leitura neutra.

### O que a deflação NÃO conserta

1. **Continua sendo preço de tabela**, não preço praticado (seção 5).
2. **Continua sem peso de vendas.** O CPI é um índice de cesta ponderada por consumo;
   nosso "preço médio" é média simples de SKU lançado. Deflacionar um número sem peso de
   volume não o transforma em índice de preço ao consumidor.
3. **Continua sem ajuste de qualidade.** Preço por peça é uma correção de qualidade
   tosca — peça como proxy de "quanto produto vem na caixa". Não é hedonia.
4. **Não muda nada antes de 2007**, porque não há preço para deflacionar (seção 2).
5. **Não altera comparações dentro de um mesmo ano** — ver a armadilha na seção 11.

---

## 2. Cobertura de preço: a restrição que define o escopo

Preço falta em 11.475 das 18.457 linhas (**62,2%**). A falta não é aleatória — ela é
quase inteiramente histórica.

### Por década

| Década | Sets | Com preço | Cobertura |
|---|---|---|---|
| 1970s | 652 | 0 | **0,0%** |
| 1980s | 1.142 | 0 | **0,0%** |
| 1990s | 2.094 | 15 | **0,7%** |
| 2000s | 4.328 | 1.115 | 25,8% |
| 2010s | 7.481 | 4.318 | 57,7% |
| 2020s | 2.760 | 1.534 | 55,6% |

### O ponto de corte, ano a ano

| Ano | Sets | Com preço | Cobertura |
|---|---|---|---|
| 2002 | 449 | 9 | 2,0% |
| 2003 | 426 | 4 | 0,9% |
| 2004 | 419 | 7 | 1,7% |
| 2005 | 395 | 43 | 10,9% |
| 2006 | 467 | 138 | 29,6% |
| **2007** | 449 | 299 | **66,6%** |
| 2008 | 443 | 279 | 63,0% |
| 2009 | 487 | 318 | 65,3% |
| 2010 | 529 | 339 | 64,1% |

O salto está em 2007. De 2007 a 2022 a cobertura fica entre **52,8% e 68,7%**, média
59,0% — irregular, mas estável o bastante para uma série temporal.

### Os dois flags, e o critério exato de cada um

O modelo carrega dois flags diferentes que são fáceis de confundir. Eles respondem a
perguntas distintas:

**`dim_calendario[flag_preco_confiavel]` — atributo do ANO.**
`1` quando `ano >= 2007` (16 anos: 2007–2022). `0` nos 37 anos anteriores.
Não olha para o set nenhum: mede se a **fonte** cobria preço naquele ano em volume
suficiente. Serve como filtro de página no Power BI, para impedir que um visual de série
temporal inclua 1985, onde a cobertura é zero e o ponto do gráfico seria vazio ou, pior,
calculado sobre 15 sets de 2.094.

**`fato_sets[flag_escopo_pricing]` — atributo do SET.**
`1` quando as **quatro** condições valem ao mesmo tempo:

| Condição | Por quê | Quanto remove |
|---|---|---|
| `categoria = 'Normal'` | Exclui merchandise, livros e coleções. `Gear` tem 2.832 sets e zero peça informada em todos. | — |
| tem preço | Sem numerador não há métrica. | 11.475 linhas |
| `qt_pecas >= 20` | Elimina componente eletrônico avulso catalogado como set. | ver abaixo |
| `ano >= 2007` | Cobertura de preço da fonte. | ver tabela acima |

Resultado: **4.626 sets**, 2007–2022, 96 temas — 25,1% do catálogo.

Os dois flags não são redundantes: `flag_preco_confiavel` governa o **eixo do tempo** de
qualquer visual; `flag_escopo_pricing` governa **quais linhas entram na conta**. Um set
de 2015 sem preço está num ano confiável e mesmo assim fora do escopo.

> **É um quarto do catálogo.** Mas é o quarto sobre o qual dá para afirmar alguma coisa.
> As perguntas de mix e de cobertura, que não dependem de preço, continuam rodando sobre
> as 18.457 linhas — e por isso os dois escopos nunca podem aparecer no mesmo visual.

---

## 3. O problema do denominador: por que o corte é em 20 peças

Preço por peça é uma razão. Se o denominador for lixo, a métrica é lixo.

Na origem, 3.924 linhas não informam peças, 16 informam `0` e 309 informam `1`. Os sets
de uma ou duas peças com preço alto não são erro de digitação — são **componentes
eletrônicos vendidos avulsos**, catalogados como set:

| Set | Nome | Ano | Peças | Preço | Preço/peça |
|---|---|---|---|---|---|
| 45500-1 | EV3 Intelligent Brick | 2013 | 1 | 224,95 | **224,95** |
| 10287-1 | Intelligent NXT Brick (Black) | 2009 | 1 | 169,99 | 169,99 |
| 88016-1 | Large Hub | 2021 | 2 | 249,99 | 125,00 |
| 45609-1 | Small Hub | 2021 | 2 | 214,95 | 107,47 |
| 45501-1 | DC Rechargeable Battery | 2013 | 1 | 99,95 | 99,95 |
| 88012-1 | Technic Hub | 2020 | 1 | 89,99 | 89,99 |

Efeito de diferentes cortes sobre a métrica (Normal, com preço, 2007+):

| Corte mínimo | Sets | Preço/peça agregado | Preço/peça máximo |
|---|---|---|---|
| sem corte | 4.984 | 0,1105 | **224,95** |
| ≥ 10 peças | 4.783 | 0,1090 | 3,00 |
| **≥ 20 peças (adotado)** | **4.626** | **0,1082** | **2,53** |
| ≥ 50 peças | 4.203 | 0,1058 | 2,53 |

O corte em 20 preserva 92,8% do universo analisável e elimina toda a cauda de
eletrônicos. Ir a 50 já começa a cortar set pequeno legítimo sem ganho (o máximo não
muda). **O corte é uma escolha, não um fato** — e o número é sensível a ela em ~2% entre
os extremos testados.

O que sobra no topo depois do corte já é produto de verdade — e revela o próximo viés:

| Set | Nome | Ano | Tema | Peças | Preço | Preço/peça |
|---|---|---|---|---|---|---|
| 45002-1 | Tech Machines Set | 2013 | Education | 95 | 239,95 | 2,526 |
| 10966-1 | Bath Time Fun: Floating Animal Island | 2022 | **Duplo** | 20 | 44,99 | 2,250 |
| 10977-1 | My First Puppy & Kitten with Sounds | 2022 | **Duplo** | 22 | 44,99 | 2,045 |

---

## 4. "Peça" não é unidade homogênea — o viés Duplo

Este é o viés mais perigoso do dataset, porque é invisível no schema.

Uma peça Duplo é fisicamente muito maior que uma peça System. Dividir preço por peça
trata as duas como equivalentes, e não são.

| Grupo | Sets no escopo | Peças médias | Preço médio | **Preço por peça** |
|---|---|---|---|---|
| Duplo | 273 | 56 | US$ 37,94 | **0,6825** |
| System (demais) | 4.353 | 453 | US$ 46,98 | **0,1037** |

Duplo aparece como o tema mais caro do catálogo por peça — **6,6× o resto** — e isso é
quase inteiramente geometria, não pricing.

A consequência já apareceu em análise: comparar temas licenciados com temas próprios nos
sets de menos de 100 peças mostrava o licenciado 36,4% **mais barato**. Com Duplo e
Junior fora, o mesmo recorte dá 0,1662 contra 0,1638 — o licenciado 1,5% mais caro. O
"desconto de licença" era Duplo inteiro.

**Regra prática: todo recorte de preço por peça que cruze linhas de produto precisa ou
excluir Duplo/Junior, ou controlar por faixa de tamanho de set.** Um visual de "temas
mais caros por peça" sem esse controle está errado por construção.

---

## 5. Preço é preço de tabela, não preço praticado

`US_retailPrice` é o MSRP de lançamento nos EUA. O dataset **não tem**:

- preço de venda efetivo, desconto, promoção ou liquidação;
- unidades vendidas, receita, margem ou custo;
- data de descontinuação ou tempo de vida do set na prateleira;
- preço fora dos EUA;
- preço de mercado secundário.

O que isso proíbe afirmar: qualquer coisa sobre **receita**, **rentabilidade**,
**elasticidade** ou **sucesso comercial**. Um tema com 455 sets lançados não é
necessariamente um tema que vendeu mais — é um tema com mais SKUs. Toda a análise é de
**estratégia de lista de preço**, que é uma pergunta legítima e diferente.

---

## 6. Nulos, por coluna

Medido sobre as 18.457 linhas de origem (`''` e `NULL` contados como a mesma coisa):

| Coluna de origem | Nulos | % | Tratamento no modelo |
|---|---|---|---|
| `year` | 0 | 0,0% | — |
| `theme` | 0 | 0,0% | — |
| `category` | 0 | 0,0% | — |
| `themeGroup` | 2 | 0,0% | rótulo explícito `'Não informado'` em `dim_tema` (tema *LEGO Universe*, 2010) |
| `subtheme` | 3.556 | 19,3% | `NULL` em `fato_sets[subtema]` |
| `pieces` | 3.924 | 21,3% | `NULL` em `qt_pecas` — **não é zero** |
| `minifigs` | 10.058 | 54,5% | **convertido para `0`** — ver abaixo |
| `agerange_min` | 11.670 | 63,2% | linha `0` de `dim_faixa_etaria` |
| `US_retailPrice` | 11.475 | 62,2% | `NULL` + linha `0` de `dim_faixa_preco` |

### A conversão de minifigs para zero é uma decisão com viés

Vazio em `minifigs` foi convertido para `0` na fato. Isso torna `qt_minifigs` aditivo e
não-nulo, ao custo de misturar "tem zero minifig" com "não informou".

O viés é grande no catálogo inteiro (54,5% das linhas) e menor, mas não desprezível,
**dentro do escopo de pricing: 1.301 dos 4.626 sets (28,1%)** tinham o campo vazio na
origem.

Consequência: **`SUM(qt_minifigs) = 22.372` é um piso**, e qualquer média de minifigs por
set é subestimada. A comparação licenciado × próprio de minifigs (achado 2d) só é
defensável porque o viés de não-informação não tem razão óbvia para ser diferente entre
os dois grupos — mas isso é uma hipótese, não um fato medido.

---

## 7. Duplicatas e integridade — o que está limpo

Nem tudo é ressalva. Estes pontos foram checados e passaram:

- **Sem duplicata de chave**: 18.457 linhas, 18.457 `set_id` distintos.
- **Nenhum preço inválido**: 0 valores zero ou negativos entre os 6.982 preços.
- **Hierarquia tema → grupo é limpa**: 154 temas, 17 grupos, 154 pares distintos. Nenhum
  tema pertence a dois grupos. Por isso `dim_tema` pôde ser desnormalizada.
- **Nenhum órfão** em nenhuma das cinco chaves estrangeiras.
- **Nenhuma linha de dimensão sem uso** na fato.
- **Somas aditivas batem com a origem** nas três medidas (preço 262.068,09; peças
  3.291.343; minifigs 22.372).
- **Calendário completo**: 1970 a 2022, 53 anos, sem buraco.

---

## 8. Outliers de preço: são reais e devem ficar

10 sets custam mais de US$ 500. Nenhum é erro:

| Set | Nome | Ano | Peças | Preço |
|---|---|---|---|---|
| 75192-1 | Millennium Falcon | 2017 | 7.541 | 849,99 |
| 75313-1 | AT-AT | 2021 | 6.785 | 849,99 |
| 2000430-1 | Identity and Landscape Kit | 2013 | 2.631 | 789,99 |
| 2000431-1 | Connections Kit | 2013 | 2.455 | 754,99 |
| 75252-1 | Imperial Star Destroyer | 2019 | 4.784 | 699,99 |
| 10294-1 | Titanic | 2021 | 9.090 | 679,99 |
| 10307-1 | Eiffel Tower | 2022 | 10.001 | 629,99 |
| 75331-1 | The Razor Crest | 2022 | 6.187 | 599,99 |
| 10276-1 | Colosseum | 2020 | 9.036 | 549,99 |
| 76210-1 | Hulkbuster | 2022 | 4.049 | 549,99 |

São flagships reais com contagem de peças coerente. **Removê-los seria apagar a
estratégia de topo de linha**, que é justamente parte do que a pergunta 3 investiga.
Os dois de 2013 (`2000430`, `2000431`) são kits de LEGO Serious Play, produto
corporativo — ficam na base, mas vale saber que não são varejo de consumo.

### Distribuição de preço (6.982 sets com preço)

| Percentil | Faixa |
|---|---|
| p1 | 1,49 – 2,99 |
| p5 | 4,99 |
| p25 | 9,99 |
| **p50 (mediana)** | **19,99** |
| p75 | 39,99 |
| p90 | 79,99 |
| p95 | 99,99 – 119,99 |
| p99 | 199,99 – 269,99 |
| p100 | 269,99 – 849,99 |

Média 37,53 contra mediana 19,99: a distribuição é fortemente assimétrica à direita.
**Média de preço de set é uma estatística ruim para este catálogo** — sempre acompanhar
de mediana.

### Os preços não são contínuos

**98,8% dos preços terminam em `.99`** e existem apenas **141 pontos de preço distintos**
entre os 6.982 sets. Isso não é ruído: é arquitetura de preço psicológico deliberada.

Implicação para o dashboard: histograma de preço com bins automáticos vai produzir um
gráfico de pente, com barras altas nos pontos `.99` e vales vazios entre eles. **Por isso
o modelo traz `dim_faixa_preco` com faixas fixas em dólar** — a faixa é a unidade de
análise correta, não o valor contínuo.

---

## 9. Cobertura de idade — a base da pergunta 5 é frágil

`agerange_min` falta em 11.670 das 18.457 linhas (63,2%). Mesmo restringindo a sets
`Normal` e a anos recentes, a cobertura oscila:

| Ano | Sets `Normal` | Com idade | Cobertura |
|---|---|---|---|
| 2015 | 499 | 454 | 91,0% |
| 2016 | 533 | 481 | 90,2% |
| 2017 | 514 | 457 | 88,9% |
| 2018 | 519 | 369 | **71,1%** |
| 2019 | 482 | 336 | **69,7%** |
| 2020 | 512 | 415 | 81,1% |
| 2021 | 550 | 426 | 77,5% |
| 2022 | 508 | 387 | 76,2% |

A queda em 2018–2019 é de **fonte**, não de produto. Portanto: a matriz idade × preço de
`docs/achados.md` descreve o **subconjunto informado**, não o catálogo. Uma célula vazia
ali pode ser ausência de produto **ou** ausência de dado, e o dataset não distingue as
duas. Isso derruba a leitura forte ("a LEGO não atende adolescentes") e sustenta só a
leitura fraca ("entre os sets com idade informada, a faixa adolescente é a mais rala").

Além disso, `agerange_min` é só o piso da faixa. Não há idade máxima — a faixa etária do
modelo é uma construção sobre o mínimo, não um intervalo da origem.

---

## 10. Fim de base e outras armadilhas temporais

**2022 é o último ano da base.** Um tema que aparece pela última vez em 2022 não
"encerrou" — ele apenas não tem futuro observado. A análise de rotação de temas exclui
2022 da contagem de encerramentos exatamente por isso; sem esse cuidado, o ano final
apareceria como uma onda de descontinuações que nunca existiu.

**2020 tem efeito de pandemia embutido e não isolável.** A base não permite separar
mudança de estratégia de choque de contexto.

**A década de 2020 tem só 3 anos** (2020, 2021, 2022). Comparar o share de uma década de
3 anos com décadas de 10 exige cuidado — use share percentual, nunca contagem absoluta.

---

## 11. A comparação com o CPI de brinquedos — leia antes de citar

Esta é a análise **secundária** do projeto e a que mais facilmente vira manchete errada.

### O que foi medido (2007 → 2022)

| Série | Nominal | Real (deflacionado pelo CPI-U) |
|---|---|---|
| CPI-U geral | +41,1% | — |
| **LEGO, preço por peça** | **+3,9%** | **−26,4%** |
| **CPI de brinquedos** (`CUUR0000SERE01`) | **−57,9%** | **−70,2%** |
| **LEGO contra a categoria** | **+147,2%** | **+147,2%** |

O número relativo é **idêntico nas duas bases** — e isso não é coincidência: o CPI-U
cancela na razão entre as duas séries. Serve como checagem de que a conta está certa.

**A leitura:** a LEGO ficou 26% mais barata em poder de compra, mas a categoria de
brinquedos ficou 70% mais barata. Contra a própria categoria, a LEGO **encareceu** cerca
de 147%.

### Por que esse número indica direção, não magnitude

Quatro limites, e nenhum deles é pequeno:

1. **O CPI de brinquedos é ajustado hedonicamente.** O BLS corrige o índice pela mudança
   de qualidade dos produtos. Numa categoria dominada por eletrônico e videogame, onde a
   capacidade por dólar cresceu de forma explosiva, a hedonia produz quedas de índice
   enormes que **não** correspondem a etiquetas caindo na prateleira. Comparar isso com
   um preço de tabela sem ajuste hedônico é comparar dois objetos diferentes.
2. **"Brinquedos" não é "set de construção".** `CUUR0000SERE01` cobre a categoria toda.
   Não há sub-índice de brinquedo de montar neste dataset, e a composição da cesta do
   BLS não é observável aqui.
3. **Nosso preço por peça é uma correção de qualidade caseira.** Usar contagem de peças
   como proxy de quantidade de produto é defensável, mas é tosco — e, como a seção 4
   mostra, nem sequer é homogêneo entre linhas (peça Duplo × peça System).
4. **Cestas diferentes, pesos diferentes.** O CPI pondera por consumo real; o "preço por
   peça" do catálogo pondera por peça lançada. Um SKU que ninguém comprou pesa igual a
   um campeão de vendas.

**Formulação defensável:** *"o preço por peça da LEGO caiu bem menos que o índice de
preços de brinquedos no mesmo período, o que sugere que a marca se posicionou acima da
categoria"* — com a ressalva de hedonia declarada junto.
**Formulação indefensável:** *"a LEGO ficou 147% mais cara que os concorrentes."*

### Onde o índice de brinquedos não existe

`cpi_toys_media_anual` é `NULL` nos **8 anos de 1970 a 1977** — a série do BLS começa em
1978. A coluna `flag_cpi_toys_disponivel` marca isso (1 em 45 anos, 0 em 8). Um visual
que ignore o flag vai desenhar uma linha caindo a zero no começo do gráfico.
Na prática o ponto é acadêmico, porque não há preço de LEGO antes de 2007 de qualquer
forma — mas o flag existe para o erro não ser possível.

### A armadilha de deflacionar comparações entre grupos

Deflacionar **não muda** comparação entre dois grupos **dentro do mesmo ano**: ambos
levam o mesmo fator e ele cancela. Conferido no prêmio de licença — 2013, 2017, 2021 e
2022 dão exatamente o mesmo percentual nas duas bases.

Mas **muda qualquer agregado de vários anos** em que os grupos tenham composição temporal
diferente. Exemplo medido, prêmio de licença por faixa de tamanho (agrega 16 anos):

| Faixa de tamanho | Prêmio nominal | Prêmio real |
|---|---|---|
| Até 99 peças | −36,4% | −39,2% |
| 100 a 249 peças | −12,9% | −16,5% |
| 250 a 499 peças | −1,8% | −4,7% |
| 500 a 999 peças | −1,1% | −3,1% |
| 1.000 peças ou mais | +22,9% | +23,8% |

A causa: o set licenciado é sistematicamente **mais novo** (ano médio de 2016,3 a 2017,4)
que o próprio (2014,3 a 2015,5), então deflacionar levanta mais o lado próprio. A faixa
de 1.000+ peças confirma pelo contrário — ali os anos médios empatam (2017,0 × 2017,1) e
o prêmio quase não se mexe.

**Regra:** todo número de comparação entre grupos citado fora de um ano específico
precisa dizer em qual base está.

---

## 12. Erros encontrados e corrigidos nesta revisão

Ao revalidar o modelo em 2026-09-20 apareceu um defeito real no que estava em disco:

**`dim_calendario[rotulo_decada]` gravava `1970` em vez de `1970s`.**

Causa: no SQLite o operador de concatenação `||` tem precedência **maior** que a
multiplicação. A expressão `(ano / 10) * 10 || 's'` era avaliada como
`(ano / 10) * ('10s' → 10)`, ou seja `197 * 10 = 1970`. O valor numérico da década saía
certo por coincidência — `'10s'` converte para `10` — mas o rótulo perdia o `s`.

Correção aplicada: `CAST((CAST(year AS INTEGER) / 10) * 10 AS TEXT) || 's'`, em
`sql/01-qualidade-do-dado.sql` e `sql/02-modelo-estrela.sql`, com a coluna regravada na
base e `exports/dim_calendario.csv` reexportado. Nenhum número de análise mudou: a coluna
`decada` (inteira) sempre esteve correta e é ela que agrupa. Só o rótulo estava errado.

Vale como lembrete de que precedência de operador em dialeto SQL não é intuição — e de
que o defeito só apareceu porque a revalidação olhou para o **conteúdo** da dimensão, não
só para as contagens.

### Divergência de escopo na escada de preços (apontada pela camada de Power BI)

A pergunta 3 (escada de preços) estava respondida em `docs/achados.md` sobre um escopo
**diferente** do resto da peça: `categoria = 'Normal' AND flag_tem_preco = 1`, em vez de
`flag_escopo_pricing = 1`. A diferença são os sets de menos de 20 peças.

| Escopo | Sets em 2007 | Mediana 2007 | Sets em 2022 | Mediana 2022 | Variação |
|---|---|---|---|---|---|
| Normal + com preço (usado antes) | 168 | US$ 24,99 | 388 | US$ 39,99 | **+60,0%** |
| `flag_escopo_pricing` (oficial) | 153 | **US$ 29,99** | 373 | US$ 39,99 | **+33,3%** |

A conclusão qualitativa não muda — a mediana subiu nos dois —, mas a **magnitude quase
dobra**, e os 15 sets extras de 2007 são exatamente o tipo de item que o corte de 20
peças existe para remover: barato por construção, porque quase não tem peça.

Corrigido: `docs/achados.md` passa a responder a pergunta 3 no escopo oficial, e mostra
as duas leituras lado a lado onde a diferença importa. **A lição é de processo**: a
pergunta que não dependia de `qt_pecas` foi a única que escorregou de escopo, porque o
filtro "parecia" desnecessário. Escopo declarado num flag existe para ser usado sempre,
não quando parece relevante.
