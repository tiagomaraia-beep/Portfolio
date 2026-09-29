# Modelo Power BI — estrela de pricing de catálogo

**O que este documento é:** o desenho do modelo semântico que consome
`exports/*.csv`, tabela por tabela, com a justificativa de cada decisão. É a peça que
responde, numa entrevista, à pergunta *"por que essa medida dá esse número?"*.

**O que este documento não é:** ele não foi executado. Nenhum agente roda o Power BI
Desktop — a máquina é do Tiago. Tudo aqui é desenho e código para colar, e
`docs/passo-a-passo-powerbi.md` é o roteiro de cliques. Os números de controle vêm de
`docs/dicionario-de-dados.md` e foram reconferidos lendo os CSV diretamente; o que **não**
foi verificado é o comportamento do Desktop, e onde isso importa está dito em voz alta.

> **Versão 3 do contrato de dados.** O modelo agora tem **sete tabelas**, **seis relações
> ativas** e **uma inativa**, e o preço existe em **duas bases** (nominal e real). Quem
> já montou o `.pbix` pela versão anterior: a lista de refação está na seção 9.

Contrato de origem: `docs/dicionario-de-dados.md`. Limites de leitura:
`docs/qualidade-do-dado.md`. Números apurados: `docs/achados.md`.

---

## 1. O desenho

Estrela clássica, uma fato e seis dimensões conformadas. Nenhuma dimensão fala com outra
dimensão. Nenhuma ponte. Nenhuma segunda fato.

```
                       dim_calendario  (53 linhas, grão = ano)
                              |  1        + CPI-U, deflator, CPI de brinquedos
                              |
                              v  N
   dim_tema  ---1----->N  fato_sets  N<-----1---  dim_categoria
   (154)                  (18.457)                     (7)
                          ^   ^   ^
                         /    |    \
                      1 /     | 1   \ 1
        dim_faixa_preco   dim_faixa_etaria   dim_faixa_tamanho
              (7)               (7)                 (6)
               \
                \ ..... relação INATIVA para sk_faixa_preco_real (seção 4)
```

Fonte: **os sete CSV de `exports/`**. O arquivo `data/lego.db` é o ambiente de trabalho
do SQL e **não** é fonte do relatório — se o `.pbix` apontar para o `.db`, a linhagem do
projeto deixa de ser reproduzível por quem só recebeu a pasta `exports/`.

---

## 2. As duas regras que governam o modelo inteiro

Tudo o que vem depois é consequência destas duas. Elas têm a mesma forma: **o número
errado não deve ser difícil de achar — deve ser impossível de escrever.**

### Regra 1 — escopo é propriedade da métrica, não do visual

Não existe, em lugar nenhum do modelo, uma medida de preço sem escopo. `[Preço por peça
(nominal)]` e `[Preço por peça (real, USD 2022)]` já nascem com
`KEEPFILTERS ( fato_sets[flag_escopo_pricing] = 1 )` dentro, e as colunas cruas da fato
estão ocultas — então também não dá para montar a divisão à mão dentro de um visual.

Visual se copia e cola entre páginas, e filtro de visual não vai junto de forma
confiável; medida vai.

### Regra 2 — base é propriedade da métrica, não do título

Toda medida de preço termina em **`(nominal)`** ou **`(real, USD 2022)`**. Não existe
`Preço por peça` neutro para alguém arrastar sem pensar, porque **leitura neutra não
existe**: a mesma série dá índice **103,9** em base nominal e **73,6** em base real, em
2022. Uma diz "o preço ficou estável", a outra diz "o preço caiu 26%". As duas são
verdadeiras.

A regra 2 é a regra 1 aplicada à unidade em vez do universo — e por isso a segunda
relação com `dim_faixa_preco` (seção 4) nasce **inativa**: nem a faixa de preço pode
trocar de base sem que uma medida declare a troca.

---

## 3. Tabela por tabela

Convenção: `Número Inteiro` = *Whole Number*, `Número Decimal` = *Decimal Number*,
`Texto` = *Text*. **Toda chave, todo `flag_`, toda `ordem_` e todo índice de preço recebe
`Resumo padrão = Não resumir`** — senão o Power BI soma inteiro por reflexo e um dia
alguém arrasta `ano` para um cartão e lê `32.312`, ou soma um CPI.

### 3.1 `fato_sets` — 18.457 linhas, grão = um set de catálogo (19 colunas)

| Coluna | Tipo | Oculta? | Observação |
|---|---|---|---|
| `sk_set` | Número Inteiro | **sim** | PK técnica |
| `set_id` | Texto | não | dimensão degenerada; é o identificador que o usuário reconhece |
| `nome_set` | Texto | não | |
| `subtema` | Texto | não | 3.556 nulos — **manter nulo** |
| `sk_tema` | Número Inteiro | **sim** | FK |
| `sk_ano` | Número Inteiro | **sim** | FK |
| `sk_categoria` | Número Inteiro | **sim** | FK |
| `sk_faixa_preco` | Número Inteiro | **sim** | FK — relação **ativa** |
| `sk_faixa_etaria` | Número Inteiro | **sim** | FK |
| **`sk_faixa_tamanho`** | Número Inteiro | **sim** | FK nova — substitui as colunas que eu derivava |
| `qt_sets` | Número Inteiro | **sim** | sempre 1; exposto só via medida `Sets` |
| `qt_pecas` | Número Inteiro | **sim** | 3.924 nulos — **nulo não é zero** |
| `qt_minifigs` | Número Inteiro | **sim** | vazio da origem já virou 0 no SQL; é um piso |
| `vl_preco_usd` | **Número Decimal** | **sim** | USD corrente; **locale quebra aqui** |
| **`vl_preco_usd_2022`** | **Número Decimal** | **sim** | USD constantes de 2022; **locale quebra aqui também** |
| `flag_tem_preco` | Número Inteiro | **sim** | usado só dentro de medida |
| **`flag_preco_99`** | Número Inteiro | **sim** | agora vem pronto do SQL |
| `flag_escopo_pricing` | Número Inteiro | **sim** | idem — ver regra 1 |
| `url_brickset` | Texto | não | Categoria de dados = **URL da Web** |

**Por que ocultar as cinco colunas de medida** (`qt_sets`, `qt_pecas`, `qt_minifigs`,
`vl_preco_usd`, `vl_preco_usd_2022`) **e os três flags:** é a implementação da regra 1.
Coluna visível é coluna arrastável, e a soma arrastada não carrega escopo nem base.
Oculta a coluna, o **único** caminho para o número é a medida. Medida continua enxergando
coluna oculta normalmente; quem perde acesso é o painel **Dados**, que é onde o erro
nasce. Com a chegada de `vl_preco_usd_2022` isso deixou de ser higiene e virou
necessidade: duas colunas de preço visíveis lado a lado são um convite a somar a errada.

**A coluna que eu acrescento na camada de relatório** (ver seção 8):

| Coluna | Tipo | Para quê |
|---|---|---|
| `sk_faixa_preco_real` | Número Inteiro (oculta) | classificar o set pela faixa do preço **real**; alvo da relação inativa |

### 3.2 `dim_calendario` — 53 linhas, grão = ano (9 colunas)

| Coluna | Tipo | Oculta? | Resumo |
|---|---|---|---|
| `sk_ano` | Número Inteiro | **sim** | Não resumir |
| `ano` | Número Inteiro | não | **Não resumir** |
| `decada` | Número Inteiro | **sim** | Não resumir |
| `rotulo_decada` | Texto | não | `Classificar por coluna` → `decada` |
| `flag_preco_confiavel` | Número Inteiro | não | Não resumir |
| **`cpi_u_media_anual`** | **Número Decimal** | não | **Não resumir** — somar um índice não significa nada |
| **`fator_deflator_base2022`** | **Número Decimal** | não | **Não resumir** |
| **`cpi_toys_media_anual`** | **Número Decimal** | não | **Não resumir** — `NULL` em 8 anos |
| **`flag_cpi_toys_disponivel`** | Número Inteiro | **sim** | Não resumir |

`flag_preco_confiavel` fica **visível** de propósito: é filtro de página nas páginas de
preço, e filtro que ninguém consegue ver é filtro que ninguém confere.

As três colunas de CPI ficam visíveis porque são a **metodologia exposta** — um
recrutador que abre o modelo vê de onde veio a deflação. Mas todas com `Não resumir`:
a soma de um índice de preços é um número sem significado, e `Não resumir` é o que
impede alguém de produzi-lo por engano.

`flag_cpi_toys_disponivel` fica oculto porque só serve dentro da medida
`[CPI de brinquedos do ano]`, que já o aplica.

### 3.3 `dim_faixa_tamanho` — 6 linhas (**nova nesta versão**)

| Coluna | Tipo | Oculta? | Observação |
|---|---|---|---|
| `sk_faixa_tamanho` | Número Inteiro | **sim** | PK |
| `faixa_tamanho` | Texto | não | **`Classificar por coluna` → `ordem_faixa`** |
| `ordem_faixa` | Número Inteiro | **sim** | Não resumir |
| `pecas_minimo` | Número Inteiro | **sim** | documentação da fronteira |
| `pecas_maximo` | Número Inteiro | **sim** | idem |

Esta tabela é a **dívida que eu devolvi, paga em formato melhor do que eu tinha
proposto**. Eu havia derivado `faixa_tamanho` e `ordem_tamanho` como duas colunas no
Power Query sobre a fato, e pedido que virassem colunas da fato no SQL. A camada de
dados devolveu uma **dimensão**, e o argumento dela vence o meu:

- o modelo já tinha duas bandas como dimensão (`faixa_preco`, `faixa_etaria`); uma
  terceira banda como coluna de texto na fato seria incoerente com o próprio modelo;
- `Classificar por coluna` passa a morar **dentro da dimensão**, junto das outras duas,
  em vez de um par de colunas soltas na tabela de fatos;
- rótulo e fronteira ficam num lugar só — mudar "até 99 peças" para "até 149" vira uma
  linha de `INSERT`, não uma caça a `CASE` espalhado.

Os rótulos e a ordem são **idênticos** aos que eu tinha criado, então nenhum texto de
visual muda. O que muda é de onde o campo vem — e isso obriga a repontar os visuais
(seção 9).

### 3.4 `dim_tema` — 154 linhas

`sk_tema` oculta; `tema`, `grupo_tema` e `flag_licenciado` visíveis. Hierarquia
**Portfólio** = `grupo_tema` › `tema`. Não inclua `subtema`: ele mora na fato, e
hierarquia não atravessa tabela.

`Miscellaneous` é catch-all, não categoria de produto (48,1% dele é `Gear`). Isso não se
resolve no modelo, resolve-se no visual: gráfico de mix por `grupo_tema` roda com
`dim_categoria[categoria] = "Normal"` — que é o que a medida `[Sets de construção]` já faz.

### 3.5 `dim_categoria` — 7 linhas

`sk_categoria` oculta; `categoria` e `flag_contem_pecas` visíveis.

### 3.6 `dim_faixa_preco` — 7 linhas, **com dois papéis**

| Coluna | Tipo | Oculta? | Observação |
|---|---|---|---|
| `sk_faixa_preco` | Número Inteiro | **sim** | PK — origem das relações 4 (ativa) e 7 (inativa) |
| `faixa_preco` | Texto | não | **`Classificar por coluna` → `ordem_faixa`** |
| `ordem_faixa` | Número Inteiro | **sim** | Não resumir |
| `limite_inferior` / `limite_superior` | Número Decimal | **sim** | documentação; locale importa |
| `faixa_preco_5` | Texto (acrescentada) | não | **`Classificar por coluna` → `ordem_faixa_5`** |
| `ordem_faixa_5` | Número Inteiro (acrescentada) | **sim** | |

Sem o `Classificar por coluna`, o eixo sai alfabético e `US$ 100 a 199.99` aparece antes
de `US$ 20 a 49.99` — o gráfico fica **errado com aparência de certo**, que é o pior tipo
de erro de dashboard.

`faixa_preco_5` funde as duas faixas de topo em `US$ 100 ou mais`, por um motivo de cor
explicado em `docs/dashboard-spec.md` §2 (a rampa sequencial de um matiz só sustenta cinco
degraus). A camada de dados revisou essa decisão e concordou em deixá-la aqui: é
agrupamento de **apresentação**, não de negócio. As seis faixas continuam inteiras na
matriz de tabela da mesma página. **Ela serve aos dois papéis** — nominal e real — porque
é uma coluna da dimensão, não da fato.

### 3.7 `dim_faixa_etaria` — 7 linhas

`faixa_etaria` recebe `Classificar por coluna` → `ordem_faixa`. A linha `0`
(`Não informada`) absorve 11.670 sets e **tem de continuar visível**: a pergunta 5 é sobre
buraco de cobertura, e apagar o "não informado" converteria falta de dado em ausência de
produto.

### 3.8 `_Medidas` — tabela vazia só para abrigar medida

Criada por `Inserir dados` com uma coluna `placeholder` apagada depois que a primeira
medida existe. 66 medidas em dez pastas de exibição, em `dax/medidas.dax`.

---

## 4. As relações — seis ativas e uma inativa

### As seis ativas

Todas: **1:N, da dimensão para a fato, filtro cruzado `Único` (*Single*), ativa.**

| # | De (lado 1) | Para (lado N) | Cardinalidade | Direção |
|---|---|---|---|---|
| 1 | `dim_tema[sk_tema]` | `fato_sets[sk_tema]` | 1:N | `Único`, dim → fato |
| 2 | `dim_calendario[sk_ano]` | `fato_sets[sk_ano]` | 1:N | `Único`, dim → fato |
| 3 | `dim_categoria[sk_categoria]` | `fato_sets[sk_categoria]` | 1:N | `Único`, dim → fato |
| 4 | `dim_faixa_preco[sk_faixa_preco]` | `fato_sets[sk_faixa_preco]` | 1:N | `Único`, dim → fato |
| 5 | `dim_faixa_etaria[sk_faixa_etaria]` | `fato_sets[sk_faixa_etaria]` | 1:N | `Único`, dim → fato |
| **6** | **`dim_faixa_tamanho[sk_faixa_tamanho]`** | **`fato_sets[sk_faixa_tamanho]`** | 1:N | `Único`, dim → fato |

O SQL já provou o lado "1" (chave única nas seis dimensões), o lado "N" (mínimo 1 fato por
linha de dimensão), zero órfãos e zero linha de dimensão sem uso. Consequência prática:
**o Power BI não deve criar nenhuma linha em branco automática** do lado "um". Se aparecer
um `(Em branco)` num eixo de dimensão, a importação trouxe coisa diferente do contrato.

### A sétima, inativa — e por que ela existe

| # | De | Para | Cardinalidade | Direção | **Ativa** |
|---|---|---|---|---|---|
| 7 | `dim_faixa_preco[sk_faixa_preco]` | `fato_sets[sk_faixa_preco_real]` | 1:N | `Único`, dim → fato | **não** |

É uma **dimensão com dois papéis**: a mesma `dim_faixa_preco` classifica o set pelo preço
**nominal** (relação 4, ativa) ou pelo preço **real** (relação 7, inativa). Um set de
US$ 35 em 2007 cai em `US$ 20 a 49.99` na leitura nominal e em `US$ 50 a 99.99` na real —
é a mesma faixa, aplicada a duas unidades.

Só acorda dentro de uma medida que carrega `(real, USD 2022)` no nome:

```dax
Participação da faixa no mix (real, USD 2022) =
CALCULATE (
    [Participação da faixa no mix (nominal)],
    USERELATIONSHIP ( dim_faixa_preco[sk_faixa_preco], fato_sets[sk_faixa_preco_real] )
)
```

**A inatividade é o recurso, não um efeito colateral.** Se as duas relações fossem
ativas o modelo seria ambíguo e o Power BI recusaria a segunda. Se a escolha de base
vivesse num campo arrastável, qualquer um trocaria de base sem perceber. Do jeito que
está, **só uma medida que declara a base consegue mudar a base** — que é a regra 2
implementada no modelo, e não só na convenção de nome.

Duas alternativas foram descartadas:

- *Duas colunas de texto na fato (`faixa_preco_real`, `ordem_faixa_real`).* Funciona, não
  precisa de `USERELATIONSHIP` — e duplica os sete rótulos e o `Classificar por coluna`
  em dois lugares, que é exatamente o que a camada de dados acabou de corrigir ao promover
  `faixa_tamanho` a dimensão. Seria andar para trás no mesmo dia.
- *Uma segunda cópia de `dim_faixa_preco`.* Duplica a dimensão inteira para ganhar um
  eixo, e obriga a manter dois conjuntos de rótulos sincronizados.

### Por que nenhuma é bidirecional

A resposta genérica ("bidirecional cria caminho ambíguo") é verdadeira e insuficiente.
Aqui não há segunda fato nem ponte, então ambiguidade não é o risco real. O risco real é
que o filtro bidirecional **sobe da fato para a dimensão** e apaga da dimensão exatamente
o que este projeto precisa mostrar. Caso a caso:

1. **`dim_tema`** — filtrar uma faixa de preço encolheria a lista de temas do segmentador.
   Temas *sem* set naquela faixa sumiriam da tela. A pergunta 5 é sobre onde o catálogo é
   ralo: o tema ausente **é** a resposta, não ruído a esconder.
2. **`dim_calendario`** — o caso mais grave, porque quebra medida em vez de visual. A
   variação ano a ano depende de `REMOVEFILTERS ( dim_calendario )` realmente limpar o
   ano. Com bidirecional, o filtro que sobrou na fato volta a propagar para o calendário
   depois do `REMOVEFILTERS`, e a medida de ano anterior passa a devolver ora o número
   certo, ora em branco, conforme o visual. É o tipo de defeito que se diagnostica como
   "problema de DAX" por dias antes de alguém olhar a seta. **Agora pesa ainda mais**: as
   colunas de CPI moram aqui, e um índice de inflação que muda conforme o filtro da fato
   deixaria de ser um índice.
3. **`dim_categoria`** — o escopo de preço exige `categoria = 'Normal'`. Com bidirecional,
   esse filtro subiria e o segmentador passaria a mostrar uma categoria só. O relatório
   afirmaria que o catálogo tem uma categoria.
4. **`dim_faixa_preco`** — o escopo exclui as 11.475 linhas sem preço. Com bidirecional, a
   faixa `Sem preço informado` desapareceria do eixo — e ela é 62,2% do catálogo e o
   assunto inteiro da página de qualidade.
5. **`dim_faixa_etaria`** — mesma coisa com `Não informada`, que são 11.670 sets. Apagar
   esse rótulo converteria "a fonte não informou" em "não existe produto", que é a leitura
   forte que `docs/qualidade-do-dado.md` §9 proíbe.
6. **`dim_faixa_tamanho`** — a faixa `Peças não informadas` tem 3.924 sets, e o escopo de
   preço exclui todos eles. Com bidirecional, ela sumiria do eixo numa página de preço, e
   a página de qualidade perderia o degrau que explica de onde vem o corte de 20 peças.

Se um dia fizer falta filtrar dimensão pelo que existe na fato, o caminho é `CROSSFILTER`
**dentro da medida específica** — o efeito fica confinado àquela medida, documentado no
código, e não muda o comportamento do resto do relatório.

### Antes de criar relação: desligar a detecção automática

`Arquivo > Opções e configurações > Opções > Arquivo atual > Carregamento de Dados` →
desmarcar **`Detectar automaticamente novas relações depois que os dados forem
carregados`**, **antes** da primeira importação. As sete tabelas têm colunas `sk_`
homônimas, e agora a fato tem **duas** colunas que apontam para `dim_faixa_preco` —
deixar o Desktop adivinhar produz relação sobrando, ativa na direção errada, ou ativa
onde deveria ser inativa.

Depois de criar tudo à mão, abra `Gerenciar relações`: **sete linhas, seis marcadas como
ativas e exatamente uma desmarcada.**

---

## 5. A decisão sobre tabela de datas — contra o reflexo

**`dim_calendario` NÃO é marcada como tabela de datas. Não existe tabela de datas neste
modelo. Isso é deliberado.**

O reflexo treinado em todo curso de Power BI é: existe tempo no modelo → crie tabela de
datas contínua → marque como tabela de datas → use inteligência de tempo. Aqui o reflexo
está errado, e o motivo é de **grão**, não de preferência.

- A origem tem `year`, não data. Não existe dia, mês nem trimestre.
- `Marcar como tabela de data` **exige** uma coluna Data/Hora, contínua, sem duplicata e
  sem buraco. `dim_calendario[ano]` é inteiro. Não há coluna para apontar.
- Fabricar uma data (`1 de janeiro de 2007`) criaria um modelo que **afirma precisão que o
  dado não tem**: `DATESYTD` sobre um calendário em que o ano inteiro acontece em 1º de
  janeiro devolve número que parece resposta.
- Consequência: `SAMEPERIODLASTYEAR`, `DATEADD`, `TOTALYTD`, `DATESINPERIOD` e a
  hierarquia automática de datas **não se aplicam**. Não é que sejam desaconselhadas —
  elas não têm sobre o que operar.

**O substituto é aritmética sobre o inteiro:**

```dax
VAR AnoAtual = SELECTEDVALUE ( dim_calendario[ano] )
VAR Anterior =
    CALCULATE ( [Preço por peça (real, USD 2022)], REMOVEFILTERS ( dim_calendario ), dim_calendario[ano] = AnoAtual - 1 )
```

Três coisas acontecem aí, e as três valem uma frase:

- `REMOVEFILTERS ( dim_calendario )` **apaga o filtro da tabela inteira**, não só da
  coluna `ano`. Precisa ser da tabela: se o visual agrupar por `rotulo_decada`, limpar só
  `ano` deixaria a década filtrando e 2009 não enxergaria 2008.
- `dim_calendario[ano] = AnoAtual - 1` é filtro booleano de coluna, e filtro booleano
  **substitui** o que havia naquela coluna. Como o `REMOVEFILTERS` já limpou, ele escreve
  num contexto limpo.
- `AnoAtual` é `VAR`, avaliado **onde está escrito** — fora do `CALCULATE`, no contexto que
  o visual entregou. Por isso ainda enxerga 2014 quando a linha é 2014, mesmo que o
  `CALCULATE` logo abaixo apague o calendário. Inverter essa ordem é o erro clássico de
  contexto de filtro, e é a razão de a medida usar `VAR` em vez de aninhar.

---

## 6. As duas decisões espelhadas: o que entra pré-calculado na fato e o que não entra

Esta seção é o coração do projeto para efeito de entrevista, porque contém duas decisões
que **parecem contraditórias e não são**.

### Razão NÃO entra na fato

`ppp` calculado linha a linha obrigaria todo visual agregado a fazer `AVERAGE(ppp)` — a
**média das razões**, em que um set de 30 peças pesa igual ao Millennium Falcon de 7.541.
No escopo limpo isso devolve **0,1657** contra os **0,1082** da razão dos totais: 53% de
erro. Deixar a razão fora da fato **força** o cálculo a virar medida e torna o erro
impossível por acidente.

### Valor deflacionado ENTRA na fato

`vl_preco_usd_2022` **não é razão: é fato aditivo em outra unidade.** Multiplicar um valor
por um escalar constante dentro da linha preserva a aditividade — é o padrão de guardar um
valor em moeda local e em moeda de reporte lado a lado. `SUM(vl_preco_usd_2022)` significa
alguma coisa; `AVG(preço/peças)` não.

E precisa ser **linha a linha**, não no fim. Dentro de um ano o fator é constante e tanto
faz; num agregado de vários anos, não:

| Forma de calcular o preço por peça real de 2007–2022 | Resultado |
|---|---|
| **Certo** — deflacionar cada linha e depois somar | **0,1286** |
| (referência nominal) | 0,1082 |
| **Errado** — nominal agregado × fator médio do período | **0,1333** |

3,7% de erro, e é o **mesmo erro da média das razões**, com outra roupa: a média do fator
ignora que os anos têm pesos diferentes no total.

### A regra que une as duas

> **O que é aditivo pode ser pré-calculado na fato — e deve, quando o cálculo é fácil de
> errar depois. O que é razão nunca pode, porque agregar razão é sempre errado.**

Consequência prática para o DAX: **as medidas reais são `SUM` simples**, iguais às
nominais, trocando só a coluna. Nenhuma medida deste projeto refaz a deflação com
`SUMX ( fato_sets ; [vl_preco_usd] * RELATED ( dim_calendario[fator_deflator_base2022] ) )`.
Funcionaria, mas é iteração em contexto de linha — fácil de escrever errado, cara de
auditar, e duplicaria uma conta que já está conferida na origem. `fator_deflator_base2022`
fica na dimensão para **transparência**, não para uso em medida.

---

## 7. A proteção contra escopo misto e base misturada

Cinco camadas, da mais estrutural para a mais visível:

**Camada 1 — o número errado não é expressável.** Regra 1 e regra 2 da seção 2: não há
medida de preço sem escopo, nem medida de preço sem base no nome, nem coluna crua
arrastável, nem faixa de preço real acessível sem `USERELATIONSHIP`.

**Camada 2 — nomes e pastas que declaram.** `Sets` (catálogo) e `Sets no escopo de preço`
são duas medidas com dois nomes. Pastas `01 Preço nominal` e `02 Preço real` separam as
duas famílias no painel.

**Camada 3 — o título do visual se escreve sozinho.** Todo visual de preço usa como título
`[Título de escopo — preço nominal]` ou `[Título de escopo — preço real]`, que já incluem
a contagem de sets vigente e a frase da base ("USD NOMINAL de lançamento, sem correção por
inflação" / "USD CONSTANTES DE 2022, deflacionado pelo CPI-U (BLS)"). Se alguém filtrar a
página e o universo mudar, o título muda junto. Título fixo mente quando o filtro muda.

**Camada 4 — a sentinela.** Cartão no rodapé de cada página de preço exibindo
`[Sentinela de escopo]`, que compara `[Sets]` com `[Sets no escopo de preço]` no contexto
da página e imprime um aviso quando divergem. Protege contra alguém tirar o filtro de
página e pôr uma contagem de catálogo ao lado de um preço.

**Camada 5 — a convergência visível.** Em 2022 o preço real é idêntico ao nominal por
construção (o fator é 1,0). Num gráfico com as duas séries, elas **se encontram no último
ponto**. Isso não foi desenhado como proteção, mas funciona como uma: se as duas linhas
não convergirem em 2022, a coluna deflacionada veio errada, e o gráfico denuncia antes de
qualquer teste.

---

## 8. Teste de fumaça — e o que fazer quando não bater

Rode **antes de criar qualquer visual de análise**, com uma tabela simples e nenhum filtro,
logo depois de criar as relações.

**Bloco 1 — a importação está inteira** (medidas da pasta `08 Qualidade`, sem escopo de
propósito):

| Medida | Valor esperado |
|---|---|
| `Sets` | **18.457** |
| `Preço de lista somado (catálogo, nominal)` | **US$ 262.068,09** |
| `Preço de lista somado (catálogo, real USD 2022)` | **US$ 314.872,10** |
| `Peças somadas (catálogo)` | **3.291.343** |
| `Minifigs somadas (catálogo)` | **22.372** |
| `Sets com preço` | **6.982** |
| `Sets com preço terminado em .99` | **6.897** |

**Bloco 2 — o escopo e as duas bases estão certos:**

| Medida | Valor esperado |
|---|---|
| `Sets no escopo de preço` | **4.626** |
| `Preço de lista somado (nominal)` | **US$ 214.853,10** |
| `Preço de lista somado (real, USD 2022)` | **US$ 255.395,21** |
| `Preço por peça (nominal)` | **0,1082** |
| `Preço por peça (real, USD 2022)` | **0,1286** |
| `Preço médio por set (nominal)` | **US$ 46,44** |
| `Preço médio por set (real, USD 2022)` | **US$ 55,21** |
| `Peças por set` | **429** |

**Bloco 3 — a relação inativa funciona.** Numa tabela com `dim_faixa_preco[faixa_preco]`
nas linhas e filtro de visual `ano = 2007`:

| Faixa | `Participação da faixa no mix (nominal)` | `Participação da faixa no mix (real, USD 2022)` |
|---|---|---|
| Até US$ 9.99 | **26,8%** | **9,8%** |
| US$ 10 a 19.99 | 18,3% | 18,3% |
| US$ 20 a 49.99 | 37,3% | 33,3% |
| US$ 50 a 99.99 | 13,7% | **28,1%** |
| US$ 100 a 199.99 | 3,3% | 8,5% |
| US$ 200 ou mais | 0,7% | 2,0% |

Se as duas colunas derem **valores idênticos**, o `USERELATIONSHIP` não pegou — ou a
relação 7 não existe, ou ela foi criada ativa e o Power BI desativou outra coisa, ou
`sk_faixa_preco_real` saiu igual a `sk_faixa_preco` porque a coluna deflacionada não
carregou. Em 2022 as duas colunas **devem** ser idênticas: o fator é 1,0. Confira em 2007.

### Diagnóstico por sintoma

| O que você vê | Causa quase certa | Onde mexer |
|---|---|---|
| `Preço de lista somado (catálogo, nominal)` ≈ **26.206.809** | **Locale**: pt-BR leu o ponto de `44.99` como separador de milhar | Power Query: `Alterar Tipo > Usando Localidade… > Inglês (Estados Unidos)`. Ver `passo-a-passo` §2 |
| `fator_deflator_base2022` de 2007 = **141.146** em vez de 1,41146 | Locale na coluna nova do calendário | idem, nas quatro colunas novas |
| Célula `Error` em `vl_preco_usd_2022` ou nas colunas de CPI | Locale, outra manifestação | idem |
| Acentos quebrados (`AtÃ© US$ 9.99`, `PeÃ§as nÃ£o informadas`) | Origem lida como Windows-1252 | `Origem do Arquivo = 65001: Unicode (UTF-8)` |
| `Sets` = **18.458** | Cabeçalho virou dado, ou linha em branco do lado "um" | Conferir `Usar Primeira Linha como Cabeçalho`; procurar `(Em branco)` nos eixos |
| Todas as somas multiplicadas pelo **mesmo fator inteiro** | Relação duplicando linha, ou a relação 7 ficou **ativa** | `Gerenciar relações`: sete linhas, seis ativas, uma inativa; nenhuma `*:*` |
| Power BI recusa criar a relação 7 | Ela está sendo criada como ativa e entraria em ambiguidade com a 4 | Desmarcar `Tornar esta relação ativa` **na janela de criação** |
| Somas certas, número **por tema** errado | Relação ligada na coluna errada (as `sk_` são todas inteiras) | Abrir cada relação e conferir o par de colunas |
| `Sets no escopo de preço` = 18.457 | `KEEPFILTERS` ausente, ou `flag_escopo_pricing` importado como texto | Conferir tipo da coluna e código da medida |
| `Preço por peça (nominal)` ≈ **0,1657** | Trocaram razão dos totais por média das razões | É `DIVIDE ( SUM ; SUM )`, nunca `AVERAGEX` de uma divisão |
| `Preço por peça (real, USD 2022)` ≈ **0,1333** | Alguém deflacionou o agregado com fator médio em vez de usar a coluna | Usar `vl_preco_usd_2022`; não refazer a deflação em DAX |
| `Preço por peça (real, USD 2022)` igual à `(nominal)` em todo ano | A coluna deflacionada não carregou, ou aponta para a mesma origem | Conferir que `fato_sets` tem 19 colunas |
| Linha do CPI de brinquedos caindo a zero antes de 1978 | `flag_cpi_toys_disponivel` não aplicado | É o `KEEPFILTERS` dentro de `[CPI de brinquedos do ano]` |
| `Minifigs somadas (catálogo)` ≠ 22.372 | `Remover Linhas Vazias`, ou nulo trocado por zero em `qt_pecas` | Revisar etapas aplicadas; `qt_pecas` mantém 3.924 nulos |

Regra de parada: **não construa visual enquanto os três blocos não baterem.**

---

## 9. O que refazer se o `.pbix` foi montado pela versão anterior

Esta é a lista de refação, na ordem em que se executa. Nada aqui é opcional.

### 9.1 Reimportar e importar

| Consulta | Ação |
|---|---|
| `fato_sets` | **reimportar** — 19 colunas (era 16): entram `sk_faixa_tamanho`, `vl_preco_usd_2022`, `flag_preco_99` |
| `dim_calendario` | **reimportar** — 9 colunas (era 5): entram as três de CPI e o flag |
| `dim_faixa_tamanho` | **importar** — sétima consulta, nova |
| `dim_tema`, `dim_categoria`, `dim_faixa_preco`, `dim_faixa_etaria` | inalteradas |

### 9.2 Apagar três etapas do Power Query — a dívida foi recolhida

| Etapa a apagar (em `fato_sets`) | Substituída por |
|---|---|
| Coluna personalizada `faixa_tamanho` | `dim_faixa_tamanho[faixa_tamanho]`, via relação 6 |
| Coluna personalizada `ordem_tamanho` | `dim_faixa_tamanho[ordem_faixa]` |
| Coluna personalizada `flag_preco_99` | `fato_sets[flag_preco_99]`, agora nativa do CSV |

`faixa_preco_5` / `ordem_faixa_5` em `dim_faixa_preco` **ficam** — a camada de dados
revisou e concordou que a decisão é de apresentação e pertence aqui.

### 9.3 Acrescentar uma etapa do Power Query — a dívida nova

`sk_faixa_preco_real` em `fato_sets` (M em `docs/passo-a-passo-powerbi.md` §3), com os
mesmos limites fixos de `dim_faixa_preco` aplicados a `vl_preco_usd_2022`. **Conferido
contra o CSV:** a mesma função aplicada a `vl_preco_usd` reproduz `sk_faixa_preco`
com **zero divergências** nas 4.626 linhas do escopo, o que valida os limites.

**Esta é a dívida que eu devolvo agora**, e ela é menor do que a anterior: o lugar certo
de `sk_faixa_preco_real` é a fato, no SQL, exatamente como `sk_faixa_preco`. A relação
inativa continuaria existindo de qualquer forma — dimensão com dois papéis é modelagem, não
gambiarra —, mas a **chave** deveria vir pronta. Enquanto não vier, ela é derivada aqui.

### 9.4 Repontar campo em visual

Todo visual que usava `fato_sets[faixa_tamanho]` passa a usar
`dim_faixa_tamanho[faixa_tamanho]`. Isso inclui, no `docs/passo-a-passo-powerbi.md`:

- o eixo do gráfico de barras agrupadas da página de licença;
- a regra de cor condicional que usava `ordem_tamanho` → agora
  `dim_faixa_tamanho[ordem_faixa]`;
- a linha de `Classificar por coluna`, que sai da fato e vai para a dimensão.

O rótulo e a ordem são idênticos, então **nenhum texto de visual muda** — o que muda é de
onde o campo vem, e o Power BI não faz isso sozinho.

### 9.5 Renomear medidas

Toda medida de preço ganhou sufixo de base. `Preço por peça` → `Preço por peça (nominal)`,
e existe agora `Preço por peça (real, USD 2022)`. O Power BI **atualiza as referências
sozinho** quando se renomeia uma medida pelo painel Dados, inclusive dentro de outras
medidas e nos visuais — mas **não** dentro de texto digitado à mão em caixa de texto.

### 9.6 Corrigir números escritos à mão

| Onde | Estava | Passa a ser |
|---|---|---|
| Cartão de mediana da página da escada | US$ 24,99 em 2007 · +60,0% | **US$ 29,99 em 2007 · +33,3%** |
| Manchete do resumo | índice 103,9 · "o tijolo não encareceu" | **índice real 73,6 · "o tijolo ficou 26% mais barato"** |
| Cartão de ticket médio | +74,8% | **+23,8% real** (o +74,8% vira o contraponto nominal) |
| Manchete da escada | +10,5 p.p. acima de US$ 100 | **−0,8 p.p. acima de US$ 50, em base real** |

A causa raiz do primeiro item vale registrar: a escada de preços estava respondida sobre
`Normal + com preço` em vez do escopo oficial. **Foi uma auditoria desta camada que achou
isso**, e a lição é de processo — escopo declarado num flag existe para ser usado sempre,
não quando parece relevante.

---

## 10. Checklist de aceite do modelo

- [ ] Detecção automática de relação **desligada** antes da primeira carga
- [ ] **Sete** tabelas importadas dos CSV de `exports/` (nenhuma do `.db`)
- [ ] `fato_sets` com **19** colunas; `dim_calendario` com **9**
- [ ] `vl_preco_usd`, `vl_preco_usd_2022`, `cpi_u_media_anual`, `fator_deflator_base2022`, `cpi_toys_media_anual`, `limite_inferior`, `limite_superior` tipados com localidade **Inglês (EUA)**
- [ ] `fator_deflator_base2022` de 2007 lendo **1,41146**, não 141.146
- [ ] Origem do arquivo = UTF-8 nas sete consultas; acentos íntegros
- [ ] `qt_pecas` com 3.924 nulos preservados; `cpi_toys_media_anual` com 8 nulos preservados
- [ ] Três etapas antigas do Power Query apagadas; `sk_faixa_preco_real` acrescentada
- [ ] **Seis** relações ativas + **uma inativa**, todas 1:N, `Único`, dimensão → fato
- [ ] Nenhuma bidirecional; nenhum `(Em branco)` em eixo de dimensão
- [ ] `Classificar por coluna`: `faixa_preco`→`ordem_faixa`, `faixa_preco_5`→`ordem_faixa_5`, `faixa_etaria`→`ordem_faixa`, **`faixa_tamanho`→`ordem_faixa` (na dimensão)**, `rotulo_decada`→`decada`
- [ ] `dim_calendario` **não** marcada como tabela de datas
- [ ] Colunas de medida e flags da fato ocultas — **inclusive `vl_preco_usd_2022`**
- [ ] Colunas de CPI visíveis mas com `Não resumir`
- [ ] Teste de fumaça: os **três** blocos batendo, inclusive a coluna real da relação inativa
- [ ] Nenhuma medida de preço sem `(nominal)` ou `(real, USD 2022)` no nome
