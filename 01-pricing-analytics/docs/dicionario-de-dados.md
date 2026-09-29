# Dicionário de dados — modelo estrela `lego.db`

**Contrato de entrega para a camada de Power BI.** Tudo aqui foi apurado rodando query
contra `data/lego.db` em 2026-09-20. Fonte primária: `data/lego_sets.csv` (18.457 linhas
de dados + cabeçalho), origem Brickset, catálogo LEGO de 1970 a 2022.

> **Preço de lançamento (MSRP dos EUA) em duas unidades.** `vl_preco_usd` é o dólar
> corrente do ano de lançamento (**nominal**); `vl_preco_usd_2022` é o mesmo preço em
> **dólares constantes de 2022**, deflacionado pelo CPI-U. Todo visual precisa declarar
> em qual das duas está. Metodologia e ressalvas em `docs/qualidade-do-dado.md`.

Arquivos de entrada do modelo: `exports/*.csv` (**sete** arquivos, UTF-8, vírgula,
cabeçalho na primeira linha, texto entre aspas quando necessário).

> ### ⚠️ Esta é a versão 3 do contrato — mudou o que o Power BI já consome
> `docs/modelo-powerbi.md` e `dax/medidas.dax` foram escritos sobre a versão anterior.
> A lista exata do que refazer está na **última seção deste documento**. Resumo:
> `fato_sets` ganhou 3 colunas, `dim_calendario` ganhou 4, e existe uma **sétima tabela**
> (`dim_faixa_tamanho`) com uma **sexta relação**.

---

## Visão geral do esquema

Estrela clássica: uma fato na granularidade de **set**, seis dimensões conformadas,
chave substituta inteira (`sk_`) em todas.

```
                     dim_calendario
                           |
   dim_tema  -----------  FATO_SETS  -----------  dim_categoria
                        /     |     \
      dim_faixa_preco  dim_faixa_etaria  dim_faixa_tamanho
```

| Tabela | Papel | Grão | Linhas | Chave primária |
|---|---|---|---|---|
| `fato_sets` | fato | 1 linha = 1 set (`set_id`) | 18.457 | `sk_set` |
| `dim_tema` | dimensão | 1 linha = 1 tema | 154 | `sk_tema` |
| `dim_calendario` | dimensão | 1 linha = 1 ano | 53 | `sk_ano` |
| `dim_categoria` | dimensão | 1 linha = 1 categoria | 7 | `sk_categoria` |
| `dim_faixa_preco` | dimensão | 1 linha = 1 faixa | 7 | `sk_faixa_preco` |
| `dim_faixa_etaria` | dimensão | 1 linha = 1 faixa | 7 | `sk_faixa_etaria` |
| **`dim_faixa_tamanho`** | **dimensão (nova)** | 1 linha = 1 faixa de nº de peças | **6** | `sk_faixa_tamanho` |

A fato não é agregada: ela tem exatamente a mesma contagem de linhas do CSV de origem
(18.457 = 18.457) e `set_id` continua único nela.

---

## `fato_sets` — 18.457 linhas

Grão: **um set de catálogo**. Não há mais de uma linha por `set_id`.
Só carrega medidas **aditivas** — a justificativa está na seção "Por que razões não
entram na fato".

| Coluna | Tipo | Papel | Nulos | Descrição |
|---|---|---|---|---|
| `sk_set` | INTEGER | PK | 0 | Chave substituta. Gerada por `ROW_NUMBER() OVER (ORDER BY ano, set_id)` — determinística ao recarregar. |
| `set_id` | TEXT | dimensão degenerada | 0 | Chave natural do Brickset (ex.: `75192-1`). Única. Fica na fato porque não tem atributo próprio. |
| `nome_set` | TEXT | atributo | 0 | Nome comercial do set. |
| `subtema` | TEXT | atributo | 3.556 | Subtema quando a origem informa. `NULL` = não informado; a origem trazia string vazia. |
| `sk_tema` | INTEGER | FK → `dim_tema` | 0 | |
| `sk_ano` | INTEGER | FK → `dim_calendario` | 0 | |
| `sk_categoria` | INTEGER | FK → `dim_categoria` | 0 | |
| `sk_faixa_preco` | INTEGER | FK → `dim_faixa_preco` | 0 | Aponta para a linha `0` quando não há preço — a fato **nunca** aponta para nulo. |
| `sk_faixa_etaria` | INTEGER | FK → `dim_faixa_etaria` | 0 | Aponta para a linha `0` quando não há idade mínima. |
| **`sk_faixa_tamanho`** | INTEGER | **FK → `dim_faixa_tamanho` (nova)** | 0 | Faixa de nº de peças. Aponta para a linha `0` nos 3.924 sets sem contagem. |
| `qt_sets` | INTEGER | **medida aditiva** | 0 | Sempre `1`. Deixa "quantos sets" explícito como medida (`SUM`) em vez de contagem de linha. |
| `qt_pecas` | INTEGER | **medida aditiva** | 3.924 | Número de peças. `NULL` = não informado, **não é zero**. Existem 16 sets com `0` peças de verdade na origem. |
| `qt_minifigs` | INTEGER | **medida aditiva** | 0 | Minifiguras. Vazio na origem foi convertido para `0` — decisão com viés conhecido, ver qualidade do dado. |
| `vl_preco_usd` | REAL | **medida aditiva** | 11.475 | Preço de lançamento no varejo dos EUA, **USD nominal** (dólar do ano). `NULL` = não informado. |
| **`vl_preco_usd_2022`** | REAL | **medida aditiva (nova)** | 11.475 | O mesmo preço em **USD constantes de 2022**. `vl_preco_usd × dim_calendario[fator_deflator_base2022]`, calculado **linha a linha** na carga. Em 2022 é idêntico ao nominal (checado: 0 divergências). |
| `flag_tem_preco` | INTEGER | flag 0/1 | 0 | `1` em 6.982 linhas. Equivale a `vl_preco_usd IS NOT NULL` (checado: 0 divergências). |
| **`flag_preco_99`** | INTEGER | **flag 0/1 (nova)** | 0 | `1` em **6.897** linhas — preço termina em `.99`. Comparado em centavos inteiros (`ROUND(preço×100) % 100 = 99`), nunca testando o resto de um `REAL` direto. `0` em toda linha sem preço (checado). |
| `flag_escopo_pricing` | INTEGER | flag 0/1 | 0 | `1` em 4.626 linhas. Universo defensável de preço por peça — critério abaixo. |
| `url_brickset` | TEXT | atributo | 0 | Link da ficha de origem. |

### Somas de controle da fato (batem com a origem, apuradas em 2026-09-20)

| Medida | Origem (`stg_lego_sets`) | Fato | Bate? |
|---|---|---|---|
| Linhas | 18.457 | 18.457 | sim |
| `SUM(vl_preco_usd)` | 262.068,09 | 262.068,09 | sim |
| `SUM(qt_pecas)` | 3.291.343 | 3.291.343 | sim |
| `SUM(qt_minifigs)` | 22.372 | 22.372 | sim |
| `SUM(qt_sets)` | — | 18.457 | = contagem de linhas |
| **`SUM(vl_preco_usd_2022)`** | — | **314.872,10** | novo |
| **`SUM(flag_tem_preco)`** | — | **6.982** | |
| **`SUM(flag_preco_99)`** | — | **6.897** | novo |
| **`SUM(flag_escopo_pricing)`** | — | **4.626** | |

**Use estes números como teste de fumaça depois de importar no Power BI.** Todos foram
reconferidos lendo o **CSV exportado**, não o banco — que é o que o Power BI lê. Se
qualquer um divergir, algum relacionamento virou muitos-para-muitos e está duplicando
linha.

### As duas flags — critério exato

`flag_tem_preco = 1` ⟺ a origem informou `US_retailPrice`. Nada mais. Serve para
separar "não tem preço" de "preço zero", que são coisas diferentes.

`flag_escopo_pricing = 1` ⟺ **as quatro condições ao mesmo tempo**:

1. `categoria = 'Normal'` — exclui merchandise sem peça (`Gear`), livros, coleções.
2. `vl_preco_usd` informado.
3. `qt_pecas >= 20` — elimina componentes eletrônicos avulsos vendidos como "set"
   (o EV3 Intelligent Brick tem 1 peça e custa US$ 224,95).
4. `ano >= 2007` — antes disso a cobertura de preço da fonte é baixa demais.

Resultado: 4.626 sets (25,1% do catálogo), 2007 a 2022, 96 temas. **Toda afirmação
sobre preço por peça deve sair deste filtro.** As perguntas de mix e cobertura, que
não dependem de preço, rodam sobre as 18.457 linhas.

---

## `dim_tema` — 154 linhas

Grão: tema. Hierarquia tema → grupo validada como 1:N na origem (154 temas, 17 grupos,
154 pares distintos → nenhum tema pertence a dois grupos). Por isso a dimensão pode ser
desnormalizada sem risco de multiplicar linha no join.

| Coluna | Tipo | Descrição |
|---|---|---|
| `sk_tema` | INTEGER | PK. `ROW_NUMBER() OVER (ORDER BY tema)`. |
| `tema` | TEXT | Ex.: `Star Wars`, `City`, `Duplo`. Também único (154 valores). |
| `grupo_tema` | TEXT | Agrupador da origem (`Licensed`, `Modern day`, `Pre-school`…). `'Não informado'` em 1 linha (tema *LEGO Universe*, grupo ausente na origem). |
| `flag_licenciado` | INTEGER | `1` quando `grupo_tema = 'Licensed'` — propriedade intelectual de terceiro. |

**Atenção ao grupo `Miscellaneous`**: é um catch-all, não uma categoria de produto.
Ele contém `Gear` (48,1% do grupo), `Collectable Minifigures` (13,1%), `Books` (10,7%),
`Promotional` (10,0%) e `Service Packs` (6,6%). Um gráfico de mix por `grupo_tema` sem
filtrar categoria mostra `Miscellaneous` como o maior grupo dos anos 2010 (42,5%) — o
que é um artefato, não um fato de negócio.

---

## `dim_calendario` — 53 linhas

Grão: **ano**. O dataset não tem data, só ano de lançamento — por isso a dimensão de
tempo tem grão anual e **não** é uma tabela de datas contínua.

| Coluna | Tipo | Descrição |
|---|---|---|
| `sk_ano` | INTEGER | PK. É o próprio ano (chave natural já inteira). |
| `ano` | INTEGER | 1970 a 2022, sem buraco (53 anos, 53 linhas). |
| `decada` | INTEGER | 1970, 1980, … 2020. |
| `rotulo_decada` | TEXT | `'1970s'` … `'2020s'`. |
| `flag_preco_confiavel` | INTEGER | `1` a partir de 2007 (16 anos), `0` antes (37 anos). |
| **`cpi_u_media_anual`** | REAL | CPI-U dos EUA, todos os itens, média anual (BLS, série `CUUR0000SA0`). 2007 = 207,342; 2022 = 292,655. Sem nulos nos 53 anos. |
| **`fator_deflator_base2022`** | REAL | `CPI-U(2022) / CPI-U(ano)`. Multiplica um valor nominal daquele ano para trazê-lo a dólares de 2022. 2007 = **1,41146**; 2022 = **1,0**; máximo 7,5427 (1970). |
| **`cpi_toys_media_anual`** | REAL | CPI de brinquedos (BLS, `CUUR0000SERE01`). 2007 = 70,584; 2022 = 29,681. **`NULL` nos 8 anos de 1970 a 1977** — a série começa em 1978. |
| **`flag_cpi_toys_disponivel`** | INTEGER | `1` em 45 anos, `0` nos 8 sem série de brinquedos. Existe para o visual nunca desenhar um ponto onde não há índice. |

O fator não foi aceito da fonte sem conferência: foi recalculado como `CPI(2022)/CPI(ano)`
nos 53 anos e bateu em todos (**0 divergências** acima de 1e-5).

**A deflação em si não mora aqui, mora na fato.** `dim_calendario` guarda o índice; quem
carrega o valor já convertido é `fato_sets[vl_preco_usd_2022]`. O motivo está na seção
"Por que o preço real vai pré-calculado na fato" mais abaixo — e é a decisão espelhada
da que mantém preço por peça **fora** da fato.

`flag_preco_confiavel` é atributo **do ano**, não do set: mede a cobertura da fonte
naquele ano, não uma propriedade do produto. Por isso mora na dimensão. No Power BI ele
vira filtro de página nos visuais de preço.

**Marcar como tabela de datas no Power BI**: não marque. Com grão anual e sem coluna de
data, `Mark as date table` e as funções de time intelligence (`SAMEPERIODLASTYEAR`,
`DATEADD`) não se aplicam. Variação ano a ano se faz com `CALCULATE(..., dim_calendario[ano] = SELECTEDVALUE(...) - 1)`
ou com a própria coluna `ano` como inteiro.

---

## `dim_categoria` — 7 linhas

| Coluna | Tipo | Descrição |
|---|---|---|
| `sk_categoria` | INTEGER | PK. |
| `categoria` | TEXT | `Normal`, `Gear`, `Book`, `Collection`, `Extended`, `Other`, `Random`. |
| `flag_contem_pecas` | INTEGER | `0` para `Gear` e `Random` — mercadoria sem peça; nunca entra em preço por peça. |

`Gear` tem 2.832 sets e **zero peça informada em todos eles**. São relógios, chaveiros,
mochilas. Entram no mix de portfólio; não entram em unit economics.

---

## `dim_faixa_tamanho` — 6 linhas (**nova nesta versão**)

Banda de número de peças. Mesma família de `dim_faixa_preco` e `dim_faixa_etaria`: uma
faixa fixa sobre uma medida da fato, promovida a dimensão para poder filtrar e ordenar.

| `sk` | `faixa_tamanho` | `ordem_faixa` | `pecas_minimo` | `pecas_maximo` | Sets |
|---|---|---|---|---|---|
| 0 | Peças não informadas | 0 | NULL | NULL | 3.924 |
| 1 | Até 99 peças | 1 | 0 | 99 | 8.342 |
| 2 | 100 a 249 peças | 2 | 100 | 249 | 2.658 |
| 3 | 250 a 499 peças | 3 | 250 | 499 | 1.724 |
| 4 | 500 a 999 peças | 4 | 500 | 999 | 1.196 |
| 5 | 1.000 peças ou mais | 5 | 1000 | NULL | 613 |

**Por que dimensão e não coluna de texto na fato.** O Power BI tinha derivado
`faixa_tamanho` + `ordem_tamanho` como duas colunas no Power Query — e declarou isso
como dívida. A dívida está paga aqui, mas em outro formato, e a diferença importa:

- O modelo **já tem duas bandas como dimensão** (`faixa_preco`, `faixa_etaria`). Uma
  terceira banda como coluna de texto na fato seria incoerente com o próprio modelo.
- `Sort by column` passa a morar **dentro da dimensão**, junto das outras duas, em vez
  de um par de colunas soltas na tabela de fatos.
- Rótulo e fronteira ficam num lugar só. Mudar "até 99 peças" para "até 149" é uma linha
  de `INSERT`, não uma busca por `CASE` espalhado em query e em Power Query.

**Rótulos e `ordem_faixa` são idênticos aos que o Power BI já tinha criado** — nenhum
visual quebra por causa de texto. O que muda é de onde a coluna vem.

**Coerência garantida por query:** 0 linhas em que `sk_faixa_tamanho` discorda de
`qt_pecas`, e os mínimos/máximos observados na fato batem com os limites da dimensão
(faixa 5: mínimo 1.000, máximo 11.695).

---

## `dim_faixa_preco` — 7 linhas

Faixas **fixas em dólar**, não quantis. Quantil recalculado a cada ano move a fronteira
e destrói a comparação temporal — que é exatamente a pergunta 3 (migração de mix).

| `sk` | `faixa_preco` | `ordem_faixa` | `limite_inferior` | `limite_superior` |
|---|---|---|---|---|
| 0 | Sem preço informado | 0 | NULL | NULL |
| 1 | Até US$ 9.99 | 1 | 0,00 | 9,99 |
| 2 | US$ 10 a 19.99 | 2 | 10,00 | 19,99 |
| 3 | US$ 20 a 49.99 | 3 | 20,00 | 49,99 |
| 4 | US$ 50 a 99.99 | 4 | 50,00 | 99,99 |
| 5 | US$ 100 a 199.99 | 5 | 100,00 | 199,99 |
| 6 | US$ 200 ou mais | 6 | 200,00 | NULL |

A linha `0` existe para a fato nunca apontar para nulo. **No Power BI, `ordem_faixa` deve
ser definida como `Sort by column` de `faixa_preco`** — sem isso o eixo sai em ordem
alfabética e "US$ 100 a 199.99" aparece antes de "US$ 20 a 49.99".

## `dim_faixa_etaria` — 7 linhas

Mesma lógica; a linha `0` absorve as 11.670 linhas sem `agerange_min` na origem.

| `sk` | `faixa_etaria` | `ordem_faixa` | `idade_minima` | `idade_maxima` |
|---|---|---|---|---|
| 0 | Não informada | 0 | NULL | NULL |
| 1 | 1 a 3 anos | 1 | 1 | 3 |
| 2 | 4 a 6 anos | 2 | 4 | 6 |
| 3 | 7 a 9 anos | 3 | 7 | 9 |
| 4 | 10 a 13 anos | 4 | 10 | 13 |
| 5 | 14 a 17 anos | 5 | 14 | 17 |
| 6 | 18 anos ou mais | 6 | 18 | NULL |

Também precisa de `Sort by column` = `ordem_faixa`.

---

## Relações — cardinalidade e direção do filtro

Agora são **seis**. Todas **um-para-muitos da dimensão para a fato, filtro cruzado
simples (single), dimensão filtrando a fato**. Nenhuma bidirecional. Nenhuma inativa.

| # | De (lado 1) | Para (lado N) | Cardinalidade | Direção do filtro | Ativa |
|---|---|---|---|---|---|
| 1 | `dim_tema[sk_tema]` | `fato_sets[sk_tema]` | 1 : N | dim → fato (single) | sim |
| 2 | `dim_calendario[sk_ano]` | `fato_sets[sk_ano]` | 1 : N | dim → fato (single) | sim |
| 3 | `dim_categoria[sk_categoria]` | `fato_sets[sk_categoria]` | 1 : N | dim → fato (single) | sim |
| 4 | `dim_faixa_preco[sk_faixa_preco]` | `fato_sets[sk_faixa_preco]` | 1 : N | dim → fato (single) | sim |
| 5 | `dim_faixa_etaria[sk_faixa_etaria]` | `fato_sets[sk_faixa_etaria]` | 1 : N | dim → fato (single) | sim |
| **6** | **`dim_faixa_tamanho[sk_faixa_tamanho]`** | **`fato_sets[sk_faixa_tamanho]`** | **1 : N** | **dim → fato (single)** | **sim** |

### Evidência de que a cardinalidade é essa (query rodada, não suposição)

**Lado "1" — a chave é única na dimensão:**

| Dimensão | Linhas | `COUNT(DISTINCT sk)` | `COUNT(DISTINCT` chave natural `)` |
|---|---|---|---|
| `dim_tema` | 154 | 154 | 154 |
| `dim_calendario` | 53 | 53 | 53 |
| `dim_categoria` | 7 | 7 | 7 |
| `dim_faixa_preco` | 7 | 7 | 7 |
| `dim_faixa_etaria` | 7 | 7 | 7 |
| **`dim_faixa_tamanho`** | **6** | **6** | **6** |

**Lado "N" — quantas linhas da fato por linha da dimensão:**

| Relação | Chaves usadas | Mín. fatos | Máx. fatos |
|---|---|---|---|
| `dim_tema` → fato | 154 de 154 | 1 | 2.832 (`Gear`) |
| `dim_calendario` → fato | 53 de 53 | 40 | 967 (2022) |
| `dim_categoria` → fato | 7 de 7 | 64 | 12.757 (`Normal`) |
| `dim_faixa_preco` → fato | 7 de 7 | 114 | 11.475 (sem preço) |
| `dim_faixa_etaria` → fato | 7 de 7 | 121 | 11.670 (não informada) |
| **`dim_faixa_tamanho` → fato** | **6 de 6** | **613** | **8.342 (até 99 peças)** |

**Órfãos — nenhum.** `LEFT JOIN` da fato para cada dimensão devolveu 0 linhas sem par
nas **seis** chaves. **Linhas de dimensão não usadas — nenhuma** nas seis. Ou seja: o
Power BI não deve criar nenhuma linha em branco automática ("blank row") do lado "um".
Se ele criar, a importação trouxe coisa diferente do que está aqui.

**Por que filtro simples e não bidirecional:** as seis dimensões filtram a fato e nada
mais. Não há segunda fato, não há ponte. Ligar bidirecional só criaria caminho ambíguo e
abriria porta para `CALCULATE` se comportar de forma não óbvia. Se em algum momento fizer
falta filtrar uma dimensão pelo que existe na fato, o caminho é
`CROSSFILTER` dentro da medida específica, não mudar o relacionamento.

---

## Por que razões (preço por peça) NÃO vão pré-calculadas na fato

Esta é a decisão de modelagem central do projeto e ela é deliberada.

**Preço por peça é uma razão, e razão não é aditiva.** Se a fato trouxesse uma coluna
`ppp` calculada linha a linha, todo visual que agregasse — por tema, por ano, por faixa —
teria de fazer `AVERAGE(ppp)`. Isso é a **média das razões**: um set de 30 peças pesa
exatamente o mesmo que o Millennium Falcon de 7.541 peças.

O número que um analista de pricing quer é a **razão dos totais**:
`SUM(vl_preco_usd) / SUM(qt_pecas)`.

A diferença não é acadêmica. Medida nos dois universos, em 2026-09-20:

| Universo | Sets | Média das razões `AVG(preço/peças)` | Razão dos totais `SUM(preço)/SUM(peças)` |
|---|---|---|---|
| Normal, com preço, 2007+, sem corte de peças | 4.984 | **0,6385** | **0,1105** |
| Escopo oficial (`flag_escopo_pricing = 1`) | 4.626 | **0,1657** | **0,1082** |

Sem o corte de peças a diferença é de quase seis vezes — a média das razões é dominada
pela cauda de eletrônicos avulsos de 1 a 2 peças. Mesmo já dentro do escopo limpo, ela
ainda exagera em 53%, porque continua dando a um set Duplo de 20 peças o mesmo peso que
ao Millennium Falcon de 7.541. A razão dos totais responde à pergunta real: "quanto
custou o tijolo médio que a LEGO vendeu".

Deixar a razão fora da fato **força** esse cálculo a virar medida DAX e torna o erro
impossível de cometer por acidente. É também o que torna o modelo reusável: a mesma fato
responde "preço por peça por tema", "por ano", "por faixa etária" sem recarga.

**A medida canônica no Power BI é:**

```dax
Preço por peça =
DIVIDE (
    SUM ( fato_sets[vl_preco_usd] ),
    SUM ( fato_sets[qt_pecas] )
)
```

sempre avaliada dentro do escopo `fato_sets[flag_escopo_pricing] = 1`.

Pela mesma razão não vão para a fato: preço médio por set, peças médias por set,
minifigs por mil peças, prêmio de licença, share de faixa. **Toda métrica deste projeto
que tem divisão é medida, não coluna.**

---

## Por que o preço REAL, ao contrário, VAI pré-calculado na fato

A regra acima ("razão não entra na fato") convive com a decisão oposta para
`vl_preco_usd_2022`, e a diferença entre as duas é exatamente o ponto a saber explicar.

`vl_preco_usd_2022` **não é uma razão: é um fato aditivo expresso em outra unidade.**
Multiplicar um valor por um escalar constante dentro da linha preserva a aditividade —
é o mesmo padrão de guardar um valor em moeda local e em moeda de reporte lado a lado.
`SUM(vl_preco_usd_2022)` é um número que significa alguma coisa; `AVG(preço/peças)` não.

**E precisa ser calculado linha a linha, não no fim.** Dentro de um mesmo ano o fator é
constante e tanto faz. Num agregado de vários anos, não:

| Forma de calcular o preço por peça real de 2007–2022 | Resultado |
|---|---|
| **Certo** — deflacionar cada linha e depois somar | **0,1286** |
| (referência nominal) | 0,1082 |
| **Errado** — nominal agregado × fator médio do período | **0,1333** |

3,7% de erro, e da mesma família do erro de "média das razões": a média do fator ignora
que os anos têm pesos diferentes no total.

Deixar isso pronto na fato evita que a camada de DAX precise de
`SUMX(fato_sets, fato_sets[vl_preco_usd] * RELATED(dim_calendario[fator_deflator_base2022]))`
— que funciona, mas é uma iteração de contexto de linha fácil de escrever errado e cara
de auditar. **A medida real é um `SUM` simples**, igual à nominal:

```dax
Preço por peça (real, USD 2022) =
DIVIDE ( SUM ( fato_sets[vl_preco_usd_2022] ), SUM ( fato_sets[qt_pecas] ) )
```

**Regra de bolso para as duas decisões juntas:** o que é aditivo pode ser pré-calculado
na fato e deve, quando o cálculo é fácil de errar depois; o que é razão nunca pode,
porque agregar razão é sempre errado.

### Uma armadilha que a deflação cria

Deflacionar **não altera** comparação entre grupos **dentro de um mesmo ano** — os dois
lados levam o mesmo fator e ele cancela na razão. Conferido: o prêmio de licença em 2013,
2017, 2021 e 2022 é idêntico nas duas bases (−24,2%, −10,3%, +24,5%, +17,5%).

Mas **altera qualquer agregado multi-ano** em que os grupos tenham composição temporal
diferente. No prêmio por faixa de tamanho, que agrega 16 anos, o real difere do nominal
(ex.: faixa "até 99 peças", −36,4% nominal contra −39,2% real) porque o set licenciado é
sistematicamente mais novo (ano médio 2016,3–2017,4) que o próprio (2014,3–2015,5), e
deflacionar levanta mais o lado velho. A exceção confirma: na faixa de 1.000+ peças os
anos médios empatam (2017,0 × 2017,1) e o prêmio quase não se move (+22,9% → +23,8%).

**Consequência para o relatório:** todo número de comparação entre grupos citado fora de
um ano específico precisa dizer em qual base está. Dentro de um ano, tanto faz.

---

## O que a camada de Power BI precisa saber antes de começar

1. **Importar os sete CSV de `exports/`.** São a saída oficial do modelo; o `.db` é o
   ambiente de trabalho do SQL, não a fonte do relatório.
2. **Criar as seis relações acima**: 1:N, single, dimensão → fato. Verificar que o
   Power BI não inferiu nenhuma bidirecional sozinho.
3. **Rodar o teste de fumaça** das somas de controle.
4. **`Sort by column`** em `dim_faixa_preco[faixa_preco]`, `dim_faixa_etaria[faixa_etaria]`
   e `dim_faixa_tamanho[faixa_tamanho]` → todas para `ordem_faixa`.
5. **Não marcar `dim_calendario` como tabela de datas** — grão anual, sem coluna de data.
6. **Toda medida de preço por peça é `DIVIDE(SUM, SUM)`**, nunca `AVERAGE` de uma razão.
7. **Todo visual de preço filtra `flag_escopo_pricing = 1`**; todo visual de mix ou
   cobertura roda sobre as 18.457 linhas. Misturar os dois escopos no mesmo visual é o
   erro mais provável deste projeto.
8. **Todo título de visual de preço declara a base**: "USD nominal de lançamento" ou
   "USD constantes de 2022". Nunca omitir — a mesma série conta histórias opostas nas
   duas bases (índice 103,9 contra 73,6 em 2022).
9. **`cpi_toys_media_anual` é `NULL` em 8 anos** (1970–1977). Use
   `flag_cpi_toys_disponivel = 1` para o visual não desenhar um ponto onde não há índice.

---

## ⚠️ O que mudou nesta versão — lista de ajuste para o Power BI

`docs/modelo-powerbi.md`, `docs/passo-a-passo-powerbi.md`, `docs/dashboard-spec.md` e
`dax/medidas.dax` foram escritos sobre a versão 2 dos exports. Abaixo, item a item.

### Arquivos
| Arquivo | Estado | Ação |
|---|---|---|
| `exports/fato_sets.csv` | **19 colunas** (era 16) | reimportar; conferir tipagem das novas |
| `exports/dim_calendario.csv` | **9 colunas** (era 5) | reimportar |
| `exports/dim_faixa_tamanho.csv` | **novo arquivo** | importar como sétima consulta |
| `dim_tema`, `dim_categoria`, `dim_faixa_preco`, `dim_faixa_etaria` | inalterados | nada a fazer |

### Dívida técnica recolhida — **apagar etapas do Power Query**
| O que estava no Power Query | O que fazer agora |
|---|---|
| Coluna personalizada `faixa_tamanho` em `fato_sets` | **Apagar a etapa.** Passa a vir de `dim_faixa_tamanho[faixa_tamanho]`, via a relação 6. |
| Coluna personalizada `ordem_tamanho` em `fato_sets` | **Apagar a etapa.** Virou `dim_faixa_tamanho[ordem_faixa]`. |
| Coluna personalizada `flag_preco_99` em `fato_sets` | **Apagar a etapa.** Agora vem pronta do CSV. |
| Colunas `faixa_preco_5` / `ordem_faixa_5` em `dim_faixa_preco` | **Fica como está.** É agrupamento de apresentação — a decisão de deixá-la na camada de relatório continua certa. |

**Atenção nos visuais que já usam `faixa_tamanho`:** o rótulo e a ordem são idênticos aos
que você criou, então nenhum texto muda. O que muda é a **tabela de origem do campo** —
qualquer visual que referenciava `fato_sets[faixa_tamanho]` precisa apontar para
`dim_faixa_tamanho[faixa_tamanho]`. O mesmo vale para a regra de cor por `ordem_tamanho`
(§9.5 do seu passo a passo) e para a linha de `Classificar por coluna` (§5.3).

### Tipagem no Power Query — cuidado de localidade
As três colunas numéricas novas usam **ponto** como separador decimal:
`vl_preco_usd_2022`, `cpi_u_media_anual`, `fator_deflator_base2022`, `cpi_toys_media_anual`.
Tipar com **`Alterar Tipo > Usando Localidade… > Inglês (Estados Unidos)`**, exatamente
como você já faz com `vl_preco_usd`. Em pt-BR sem isso, `1.41146` vira 141.146.

### Propriedades de coluna
- `sk_faixa_tamanho` → ocultar, `Resumo padrão = Não resumir`.
- `flag_preco_99` → ocultar, `Resumo padrão = Não resumir`.
- `vl_preco_usd_2022` → ocultar (é insumo de medida, como o nominal).
- `dim_faixa_tamanho[sk_faixa_tamanho]` e `[ordem_faixa]` → ocultar, `Não resumir`.
- `cpi_u_media_anual`, `fator_deflator_base2022`, `cpi_toys_media_anual` → `Não resumir`
  (somar um índice de preço não significa nada).
- `flag_cpi_toys_disponivel` → ocultar, `Não resumir`.

### Medidas a acrescentar em `dax/medidas.dax`
Cada medida nominal de preço ganha uma gêmea real. O padrão é trocar a coluna, nada mais:

```dax
Preço por peça (real, USD 2022) =
DIVIDE ( SUM ( fato_sets[vl_preco_usd_2022] ), SUM ( fato_sets[qt_pecas] ) )

Preço médio de set (real, USD 2022) =
AVERAGE ( fato_sets[vl_preco_usd_2022] )

Sets com preço .99 =
SUM ( fato_sets[flag_preco_99] )

% de preços terminados em .99 =
DIVIDE ( SUM ( fato_sets[flag_preco_99] ), SUM ( fato_sets[flag_tem_preco] ) )
```

**Não** escreva a versão real como `SUMX` com `RELATED(fator_deflator_base2022)`: a
deflação já está materializada linha a linha na fato, e refazê-la em DAX só acrescenta
risco. O fator na dimensão está lá para transparência e uso pontual, não para a medida.

### Números do dashboard que mudaram
Ver `docs/achados.md` — em especial a **escada de preços**, que estava respondida sobre
um escopo diferente do resto da peça e foi realinhada. O que isso muda num visual já
construído: a mediana de 2007 passa de **US$ 24,99 para US$ 29,99** e a variação da
mediana 2007→2022 de **+60,0% para +33,3%**. Se algum cartão ou título tem esses números
escritos à mão, precisa ser atualizado.
