# Passo a passo — construir o relatório no Power BI Desktop

Roteiro para o Tiago reproduzir o modelo e o dashboard sozinho. Nomes de painel, aba e
campo em **português**, como aparecem no Desktop em pt-BR; o rótulo em inglês vem entre
parênteses onde o nome muda entre versões.

**Nada deste roteiro foi executado.** Eu não rodo o Power BI. Onde a interface pode ter
mudado de nome, está dito. Onde há risco de quebra silenciosa — o passo 2 — há um teste
que denuncia o erro na hora.

> **Versão 3.** Sete consultas, seis relações ativas mais uma inativa, e o preço em duas
> bases. **Se você já montou o `.pbix` pela versão anterior, vá primeiro ao Apêndice A**
> (no fim deste arquivo): é a lista do que refazer, e ela é mais curta do que recomeçar.

Ordem obrigatória: **1 → 2 → 3 → 4 → 5 → 6 → 7**. O passo 7 (teste de fumaça) vem antes de
qualquer visual. Referências: `docs/modelo-powerbi.md` (o desenho e o porquê),
`dax/medidas.dax` (o código), `docs/dashboard-spec.md` (as páginas).

---

## Passo 0 — Configurar o arquivo antes de importar qualquer coisa

Power BI Desktop, **arquivo novo**, salvo já como
`~/Desktop/Portfolio/02-lego-analytics/lego-pricing.pbix`. Só então:

`Arquivo > Opções e configurações > Opções`, coluna da esquerda, seção
**ARQUIVO ATUAL** (*CURRENT FILE*).

**Em `Carregamento de Dados` (*Data Load*), desmarque:**

- [ ] `Detectar automaticamente novas relações depois que os dados forem carregados`
- [ ] `Data/hora automática para novos arquivos` (*Auto date/time*)

A primeira é a que importa, e importa mais nesta versão: as sete tabelas têm colunas `sk_`
homônimas e a fato tem **duas** colunas que apontam para `dim_faixa_preco`
(`sk_faixa_preco` e `sk_faixa_preco_real`). Deixar o Desktop adivinhar produz relação
sobrando, na direção errada, ou **ativa onde tem de ser inativa** — que é o defeito mais
difícil de enxergar dos três.

**Em `Configurações Regionais` (*Regional Settings*):**

- `Localidade para importação` (*Locale for import*) → **`Inglês (Estados Unidos)`**

Isso resolve o passo 2 de forma global. **Faça mesmo assim a tipagem explícita do passo 2**
— ela é a que viaja dentro do `.pbix` e continua valendo se alguém abrir o arquivo com
outra configuração de máquina.

---

## Passo 1 — Importar os sete CSV

`Página Inicial > Obter dados > Texto/CSV`. Navegue até
`~/Desktop/Portfolio/02-lego-analytics/exports/` e escolha **`fato_sets.csv`**. Na janela
de visualização, antes de qualquer botão:

| Campo da janela | Valor |
|---|---|
| `Origem do Arquivo` (*File Origin*) | **`65001: Unicode (UTF-8)`** |
| `Delimitador` (*Delimiter*) | **`Vírgula`** |
| `Detecção de Tipo de Dados` (*Data Type Detection*) | **`Não detectar tipos de dados`** |

`Origem do Arquivo` errada quebra acento: `Até US$ 9.99` vira `AtÃ© US$ 9.99` e
`Peças não informadas` vira `PeÃ§as nÃ£o informadas`. `Não detectar tipos de dados` é o que
impede o Power BI de criar sozinho a etapa `Tipo Alterado` com a localidade errada — a
tipagem é feita à mão no passo 2, e por isso a detecção precisa ficar desligada aqui.

Clique **`Transformar Dados`**, **não** `Carregar`.

Já dentro do **Editor do Power Query**, repita para os outros seis:
`Página Inicial > Nova Fonte > Texto/CSV`, mesmos três campos, para
`dim_tema.csv`, `dim_calendario.csv`, `dim_categoria.csv`, `dim_faixa_preco.csv`,
`dim_faixa_etaria.csv` e **`dim_faixa_tamanho.csv`**.

No painel `Consultas` devem aparecer **sete** consultas. Renomeie cada uma para o nome da
tabela sem `.csv`.

**Confira as contagens de coluna agora**, porque é o jeito mais rápido de saber que você
pegou a versão certa do arquivo:

| Consulta | Colunas | Linhas |
|---|---|---|
| `fato_sets` | **19** | 18.457 |
| `dim_calendario` | **9** | 53 |
| `dim_tema` | 4 | 154 |
| `dim_categoria` | 3 | 7 |
| `dim_faixa_preco` | 5 | 7 |
| `dim_faixa_etaria` | 5 | 7 |
| `dim_faixa_tamanho` | 5 | **6** |

Se `fato_sets` vier com 16 colunas ou `dim_calendario` com 5, você está lendo uma cópia
antiga dos exports.

> **Use `exports/`, não `data/lego.db`.** O `.db` é o ambiente do SQL. Se o `.pbix`
> apontar para ele, quem receber só a pasta `exports/` não consegue abrir o relatório.

---

## Passo 2 — Tipagem, e o ponto onde isto quebra em silêncio

**Este é o passo perigoso do projeto inteiro, e nesta versão ele tem mais superfície:
eram três colunas decimais, agora são sete.**

Os CSV vêm com **ponto decimal** (`44.99`, `1.41146`, `292.655`) porque foram escritos por
SQLite. O Power BI em pt-BR, se deixado adivinhar, lê o ponto como **separador de
milhar**: `44.99` vira `4499` e `1.41146` vira `141.146`. Ou a célula devolve `Error`. Os
dois casos são ruins; o primeiro é pior, porque não avisa — o relatório carrega, os
gráficos aparecem, e o fator de deflação de 2007 passa a valer cento e quarenta e um mil.

**As sete colunas decimais do modelo, e onde estão:**

| Consulta | Colunas |
|---|---|
| `fato_sets` | `vl_preco_usd`, **`vl_preco_usd_2022`** |
| `dim_calendario` | **`cpi_u_media_anual`**, **`fator_deflator_base2022`**, **`cpi_toys_media_anual`** |
| `dim_faixa_preco` | `limite_inferior`, `limite_superior` |

Para cada uma: clique no cabeçalho > botão direito > `Alterar Tipo` >
**`Usando Localidade…`** (*Change Type > Using Locale…*). Na janela:

| Campo | Valor |
|---|---|
| `Tipo de Dados` | **`Número Decimal`** |
| `Localidade` | **`Inglês (Estados Unidos)`** |

Dá para selecionar as duas de `fato_sets` juntas e as três de `dim_calendario` juntas —
`Usando Localidade…` aceita seleção múltipla desde que todas virem o mesmo tipo.

Agora o resto, em bloco, por `Transformar > Tipo de Dados`:

| Consulta | → `Número Inteiro` | → `Texto` |
|---|---|---|
| `fato_sets` | `sk_set`, `sk_tema`, `sk_ano`, `sk_categoria`, `sk_faixa_preco`, `sk_faixa_etaria`, **`sk_faixa_tamanho`**, `qt_sets`, `qt_pecas`, `qt_minifigs`, `flag_tem_preco`, **`flag_preco_99`**, `flag_escopo_pricing` | `set_id`, `nome_set`, `subtema`, `url_brickset` |
| `dim_tema` | `sk_tema`, `flag_licenciado` | `tema`, `grupo_tema` |
| `dim_calendario` | `sk_ano`, `ano`, `decada`, `flag_preco_confiavel`, **`flag_cpi_toys_disponivel`** | `rotulo_decada` |
| `dim_categoria` | `sk_categoria`, `flag_contem_pecas` | `categoria` |
| `dim_faixa_preco` | `sk_faixa_preco`, `ordem_faixa` | `faixa_preco` |
| `dim_faixa_etaria` | `sk_faixa_etaria`, `ordem_faixa`, `idade_minima`, `idade_maxima` | `faixa_etaria` |
| **`dim_faixa_tamanho`** | `sk_faixa_tamanho`, `ordem_faixa`, `pecas_minimo`, `pecas_maximo` | `faixa_tamanho` |

**Quatro coisas que NÃO se faz aqui:**

1. **Não** troque nulo por zero em `qt_pecas`. Os 3.924 nulos são "não informado", não
   "zero peça" — e existem 16 sets com zero peça de verdade na origem.
2. **Não** troque nulo por zero em `cpi_toys_media_anual`. Os 8 nulos (1970–1977) são
   "a série do BLS não existia", e virar zero faria o gráfico desenhar um despencamento
   que nunca aconteceu.
3. **Não** use `Remover Linhas em Branco`. A fato sai daqui com 18.457 linhas.
4. **Não** aceite a etapa `Tipo Alterado` que o Power BI cria sozinho se você esquecer o
   `Não detectar tipos de dados` do passo 1. Se ela existir em
   `Configurações de Consulta > ETAPAS APLICADAS`, apague-a (o `x` ao lado) e refaça a
   tipagem à mão — ela é a fonte do erro de localidade.

**Confira antes de sair do editor.** Com `Exibição > Qualidade da Coluna` e
`Distribuição da Coluna` ligados:

| Coluna | O que tem de aparecer |
|---|---|
| `vl_preco_usd` | máximo **849,99** (o Millennium Falcon), zero `Error` |
| `vl_preco_usd_2022` | máximo na casa de **1.000**, não de 100.000; zero `Error` |
| `fator_deflator_base2022` | 2022 = **1**, 2007 = **1,41146**, 1970 = **7,542655** |
| `cpi_u_media_anual` | 2022 = **292,655** |
| `cpi_toys_media_anual` | 8 nulos, 45 valores |

Se `fator_deflator_base2022` estiver na casa dos milhares, a localidade não pegou.

---

## Passo 3 — A coluna que eu acrescento

Nesta versão é **uma só**. As três que existiam antes (`faixa_tamanho`, `ordem_tamanho`,
`flag_preco_99`) foram recolhidas pela camada de dados e vêm prontas — se você as tem no
seu arquivo, apague as etapas (Apêndice A).

Na consulta **`fato_sets`**: `Adicionar Coluna > Coluna Personalizada`. Nome:
**`sk_faixa_preco_real`**. Fórmula:

```m
if [vl_preco_usd_2022] = null then 0
else if [vl_preco_usd_2022] < 10 then 1
else if [vl_preco_usd_2022] < 20 then 2
else if [vl_preco_usd_2022] < 50 then 3
else if [vl_preco_usd_2022] < 100 then 4
else if [vl_preco_usd_2022] < 200 then 5
else 6
```

Tipo: **`Número Inteiro`**. Renomeie a etapa para `Faixa de preço na base real`.

**O que ela é:** a mesma classificação de `dim_faixa_preco`, aplicada ao preço
deflacionado em vez do nominal. Um set de US$ 35 em 2007 cai na faixa `US$ 20 a 49.99` pela
etiqueta e na faixa `US$ 50 a 99.99` pelo poder de compra. É o alvo da **relação inativa**
do passo 4.

**Por que dá para confiar nos limites:** rodei a mesma função sobre `vl_preco_usd` e
comparei com `sk_faixa_preco`, que veio do SQL — **zero divergências** nas linhas do escopo.
Os limites são os mesmos; o que muda é a coluna de entrada.

**Onde ela deveria morar:** na fato, no SQL, como `sk_faixa_preco`. É a dívida que esta
camada devolve nesta rodada. A relação inativa continuaria existindo de qualquer forma —
dimensão com dois papéis é modelagem, não gambiarra —, mas a **chave** deveria vir pronta.

`Página Inicial > Fechar e Aplicar`.

---

## Passo 4 — Seis relações ativas e uma inativa

Exibição **`Modelo`** (terceiro ícone da barra esquerda) >
`Página Inicial > Gerenciar relações` > `Nova`.

### As seis ativas

| # | Tabela de cima (lado 1) | Coluna | Tabela de baixo (lado N) | Coluna |
|---|---|---|---|---|
| 1 | `dim_tema` | `sk_tema` | `fato_sets` | `sk_tema` |
| 2 | `dim_calendario` | `sk_ano` | `fato_sets` | `sk_ano` |
| 3 | `dim_categoria` | `sk_categoria` | `fato_sets` | `sk_categoria` |
| 4 | `dim_faixa_preco` | `sk_faixa_preco` | `fato_sets` | `sk_faixa_preco` |
| 5 | `dim_faixa_etaria` | `sk_faixa_etaria` | `fato_sets` | `sk_faixa_etaria` |
| 6 | **`dim_faixa_tamanho`** | `sk_faixa_tamanho` | `fato_sets` | `sk_faixa_tamanho` |

Em cada uma, confira os três campos de baixo da janela:

- `Cardinalidade` = **`Um para muitos (1:*)`** (com a dimensão selecionada primeiro)
- `Direção do filtro cruzado` = **`Único`** (*Single*; em alguns builds o rótulo é `Simples`)
- `Tornar esta relação ativa` = **marcado**

### A sétima, inativa

| # | De | Coluna | Para | Coluna | Ativa |
|---|---|---|---|---|---|
| 7 | `dim_faixa_preco` | `sk_faixa_preco` | `fato_sets` | **`sk_faixa_preco_real`** | **NÃO** |

Mesma cardinalidade e mesma direção das outras, mas **desmarque `Tornar esta relação
ativa` na própria janela de criação**. Se você criar ativa e desmarcar depois, o Power BI
vai primeiro reclamar de ambiguidade com a relação 4 — ou, pior, desativar a 4 sozinho e
deixar o modelo classificando tudo pela base real sem avisar.

No diagrama ela aparece como **linha pontilhada**. É assim que tem de ficar.

**Por que inativa:** é a mesma `dim_faixa_preco` em dois papéis — classificar o set pela
etiqueta (relação 4) ou pelo poder de compra (relação 7). Ela só acorda dentro de uma
medida que tem `(real, USD 2022)` no nome, via `USERELATIONSHIP`. Assim **ninguém troca de
base arrastando um campo**: só uma medida que declara a base consegue trocar.
`docs/modelo-powerbi.md` §4 tem o argumento completo e as duas alternativas descartadas.

### Conferência

`Gerenciar relações`: **sete linhas, seis com a caixa `Ativa` marcada e exatamente uma
desmarcada.** Nenhuma `Muitos para muitos`. Nenhuma com direção `Ambos`. No diagrama, cada
relação ativa mostra `1` do lado da dimensão, `*` do lado da fato e **uma seta única**
apontando da dimensão para a fato. Seta dupla em qualquer uma é erro —
`docs/modelo-powerbi.md` §4 explica, relação por relação, o que quebra em cada caso.

---

## Passo 5 — Ocultar, resumir, classificar

**5.1 — Ocultar do modo de exibição de relatório.** Botão direito no campo >
`Ocultar no modo de exibição de relatório`.

| Tabela | Colunas a ocultar |
|---|---|
| `fato_sets` | `sk_set`, `sk_tema`, `sk_ano`, `sk_categoria`, `sk_faixa_preco`, `sk_faixa_etaria`, **`sk_faixa_tamanho`**, **`sk_faixa_preco_real`**, **`qt_sets`, `qt_pecas`, `qt_minifigs`, `vl_preco_usd`, `vl_preco_usd_2022`**, `flag_tem_preco`, **`flag_preco_99`**, `flag_escopo_pricing` |
| `dim_tema` | `sk_tema` |
| `dim_calendario` | `sk_ano`, `decada`, **`flag_cpi_toys_disponivel`** |
| `dim_categoria` | `sk_categoria` |
| `dim_faixa_preco` | `sk_faixa_preco`, `ordem_faixa`, `ordem_faixa_5`, `limite_inferior`, `limite_superior` |
| `dim_faixa_etaria` | `sk_faixa_etaria`, `ordem_faixa`, `idade_minima`, `idade_maxima` |
| **`dim_faixa_tamanho`** | `sk_faixa_tamanho`, `ordem_faixa`, `pecas_minimo`, `pecas_maximo` |

As cinco em negrito são a proteção central do modelo: **coluna oculta não é arrastável, e a
soma arrastada não carrega escopo nem base.** Com `vl_preco_usd` e `vl_preco_usd_2022`
visíveis lado a lado, é questão de tempo até alguém somar a errada.

**O que fica visível em `dim_calendario`, de propósito:** `cpi_u_media_anual`,
`fator_deflator_base2022` e `cpi_toys_media_anual`. São a **metodologia exposta** — quem
abrir o modelo vê de onde veio a deflação. Mas todas com `Não resumir` (5.2): a soma de um
índice de preços é um número sem significado.

**5.2 — `Resumo padrão = Não resumir`.** `Ferramentas de Coluna > Resumo padrão` >
**`Não resumir`**, em **todo inteiro e todo decimal que não é medida**: as sete `sk_`, a
`sk_faixa_preco_real`, `ano`, `decada`, `ordem_faixa` (nas **três** dimensões de faixa),
`ordem_faixa_5`, `pecas_minimo`, `pecas_maximo`, `idade_minima`, `idade_maxima`,
`flag_licenciado`, `flag_contem_pecas`, `flag_preco_confiavel`, `flag_tem_preco`,
`flag_preco_99`, `flag_escopo_pricing`, `flag_cpi_toys_disponivel`, e **as três colunas de
CPI**. Sem isso, `ano` vira `32.312` num cartão e o CPI-U vira `10.412`.

**5.3 — `Classificar por coluna`.** `Ferramentas de Coluna > Classificar por coluna`:

| Selecione esta coluna | Classificar por |
|---|---|
| `dim_faixa_preco[faixa_preco]` | `ordem_faixa` |
| `dim_faixa_preco[faixa_preco_5]` | `ordem_faixa_5` |
| `dim_faixa_etaria[faixa_etaria]` | `ordem_faixa` |
| **`dim_faixa_tamanho[faixa_tamanho]`** | **`dim_faixa_tamanho[ordem_faixa]`** |
| `dim_calendario[rotulo_decada]` | `decada` |

A quarta linha mudou de lugar nesta versão: antes as duas colunas viviam na fato, agora
vivem na dimensão. Se você já tinha o `Classificar por coluna` configurado sobre
`fato_sets[faixa_tamanho]`, ele morreu junto com a coluna.

**Confira que pegou:** ponha `faixa_preco` numa tabela. A ordem tem de ser
`Sem preço informado`, `Até US$ 9.99`, `US$ 10 a 19.99`, `US$ 20 a 49.99`,
`US$ 50 a 99.99`, `US$ 100 a 199.99`, `US$ 200 ou mais`. Se `US$ 100 a 199.99` vier antes
de `US$ 20 a 49.99`, o `Classificar por coluna` não foi aplicado — e o eixo ficaria
**errado com aparência de certo**, o pior tipo de erro de dashboard. Repita para
`faixa_tamanho`: `Até 99 peças` antes de `100 a 249 peças`.

**5.4 — `Categoria de dados`.** `fato_sets[url_brickset]` >
`Ferramentas de Coluna > Categoria de Dados` > **`URL da Web`**.

**5.5 — Hierarquia.** Botão direito em `dim_tema[grupo_tema]` > `Criar hierarquia`;
renomeie para **`Portfólio`**; arraste `tema` para dentro. Não inclua `subtema`: ele mora
na fato, e hierarquia não atravessa tabela.

**5.6 — Não marque tabela de datas.** `dim_calendario` **não** recebe
`Marcar como tabela de data`. Grão anual, sem coluna de data — não há para onde apontar.
`docs/modelo-powerbi.md` §5 explica por que isso contraria o reflexo e por que o reflexo
está errado aqui.

---

## Passo 6 — A tabela `_Medidas` e as 66 medidas

**6.1 — Criar a tabela.** `Página Inicial > Inserir dados`. Uma coluna, nome
`placeholder`, sem linha. Nome da tabela: **`_Medidas`**. `Carregar`.

**6.2 — Colar as medidas.** Selecione `_Medidas` e use `Página Inicial > Nova medida`.
Copie de `dax/medidas.dax` **uma medida por vez**, do nome até o último `RETURN`,
comentários inclusive — comentário dentro da medida é documentação que viaja com o arquivo.

**Cole na ordem do arquivo.** As pastas `00 Escopo`, `01 Preço nominal` e `02 Preço real`
são a base de que todo o resto depende; se você pular para a pasta `05 Tempo` primeiro, o
Power BI reclama de medida inexistente.

**6.3 — Formatar cada medida.** Aba `Ferramentas de Medida`:

| Tipo de medida | `Formato` | Observação |
|---|---|---|
| Contagem de sets | `Número Inteiro`, 0 casas | marcar `Separador de milhares` |
| Preço em dólar | `Personalizado` | máscara `"US$ "#,##0.00` |
| Preço por peça | `Personalizado` | máscara `0.0000` |
| Percentual | `Porcentagem`, 1 casa | |
| Pontos percentuais | `Personalizado` | máscara `+0.0" p.p.";-0.0" p.p."` |
| Índice | `Decimal`, 1 casa | |
| CPI | `Decimal`, 3 casas | |
| Fator de deflação | `Decimal`, 5 casas | 1,41146 precisa das cinco |
| Ano | `Número Inteiro`, 0 casas | **desmarcar** `Separador de milhares` (senão sai `2.022`) |

> A máscara personalizada se escreve sempre na forma invariante — vírgula de milhar, ponto
> decimal — e o Power BI imprime com os separadores da cultura do modelo. É o mesmo motivo
> pelo qual, dentro do DAX, `FORMAT(x; "#,##0")` é o certo e `"#.##0"` é o errado.

**6.4 — Pasta de exibição.** Campo `Pasta de exibição`, com o nome que está no comentário
de cada medida: `00 Escopo`, `01 Preço nominal`, `02 Preço real`, `03 Minifigs`,
`04 Licença`, `05 Tempo`, `06 Mix`, `07 Inflação e categoria`, `08 Qualidade`,
`09 Rótulos`.

As pastas `01` e `02` separadas não são organização: são a **regra 2** do modelo na
interface. Ninguém escolhe base por acidente quando as duas famílias moram em gavetas
diferentes.

**6.5 — Apagar o `placeholder`** depois que a primeira medida existir.

---

## Passo 7 — Teste de fumaça, em três blocos (antes de qualquer visual)

Página nova, `_conferencia`, um `Cartão de linhas múltiplas` (*Multi-row card*).
**Nenhum filtro em lugar nenhum.**

**Bloco 1 — a importação está inteira:**

| Medida | Tem de dar | O que prova |
|---|---|---|
| `Sets` | **18.457** | a fato veio inteira |
| `Preço de lista somado (catálogo, nominal)` | **US$ 262.068,09** | o locale da coluna nominal |
| `Preço de lista somado (catálogo, real USD 2022)` | **US$ 314.872,10** | o locale da coluna real, e que ela existe |
| `Peças somadas (catálogo)` | **3.291.343** | nenhum nulo virou zero |
| `Minifigs somadas (catálogo)` | **22.372** | nenhuma linha foi removida |
| `Sets com preço` | **6.982** | |
| `Sets com preço terminado em .99` | **6.897** | a coluna nova do SQL chegou |

**Bloco 2 — o escopo e as duas bases:**

| Medida | Tem de dar |
|---|---|
| `Sets no escopo de preço` | **4.626** |
| `Preço de lista somado (nominal)` | **US$ 214.853,10** |
| `Preço de lista somado (real, USD 2022)` | **US$ 255.395,21** |
| `Preço por peça (nominal)` | **0,1082** |
| `Preço por peça (real, USD 2022)` | **0,1286** |
| `Preço médio por set (nominal)` | **US$ 46,44** |
| `Preço médio por set (real, USD 2022)` | **US$ 55,21** |
| `Peças por set` | **429** |

**Bloco 3 — a relação inativa funciona.** Tabela com `dim_faixa_preco[faixa_preco]` nas
linhas, filtro de visual `dim_calendario[ano] = 2007`, e duas colunas de valor:

| Faixa | `Participação da faixa no mix (nominal)` | `Participação da faixa no mix (real, USD 2022)` |
|---|---|---|
| Até US$ 9.99 | **26,8%** | **9,8%** |
| US$ 10 a 19.99 | 18,3% | 18,3% |
| US$ 20 a 49.99 | 37,3% | 33,3% |
| US$ 50 a 99.99 | 13,7% | **28,1%** |
| US$ 100 a 199.99 | 3,3% | 8,5% |
| US$ 200 ou mais | 0,7% | 2,0% |

Se as duas colunas derem **valores idênticos em 2007**, o `USERELATIONSHIP` não pegou.
Troque o filtro para **2022** e confira o contrário: ali as duas colunas **têm** de ser
idênticas, porque o fator de deflação de 2022 é 1,0.

**Se qualquer bloco divergir, pare** e vá para a tabela de diagnóstico por sintoma em
`docs/modelo-powerbi.md` §8. Os quatro desvios mais prováveis:

- `Preço de lista somado (catálogo, nominal)` ≈ **26.206.809** → **locale** do passo 2;
- `fator_deflator_base2022` de 2007 = **141.146** → locale nas colunas novas do calendário;
- todas as somas multiplicadas pelo mesmo fator inteiro → relação duplicando linha, **ou a
  relação 7 ficou ativa**;
- `Preço por peça (real, USD 2022)` idêntico ao `Preço por peça (nominal)` em todo ano → a coluna deflacionada não
  carregou.

Não construa visual antes dos três blocos baterem.

---

## Passo 8 — Tema e página-modelo

**8.1 — Importar o tema.** `Exibição > Temas > Procurar temas` >
`theme/lego-analytics-tema.json`. Ele fixa as oito cores de dados na ordem validada, a
superfície, as tintas e os extremos do gradiente. Traz **rótulo de dados desligado por
padrão**, de propósito: rótulo em cada ponto é ruído. Ligue visual por visual, só onde
`docs/dashboard-spec.md` pede.

Se o Desktop recusar o arquivo, ele aponta a chave na mensagem de erro: remova a chave
apontada e importe de novo. O bloco `visualStyles` é o candidato mais provável, e o
relatório funciona sem ele.

**8.2 — Tamanho da tela.** Em cada página: `Formatar página > Tela > Tipo = Personalizado`,
`Largura 1280`, `Altura 720`.

**8.3 — Montar a página 1 e duplicar.** Monte a anatomia de `docs/dashboard-spec.md` §1
uma vez e depois **botão direito na aba > `Duplicar página`** para as outras sete. Layout
que se aprende uma vez é layout que o recrutador não precisa reaprender a cada aba.

**8.4 — Filtro de página nas páginas de preço.** Páginas 1 a 5: painel `Filtros` >
**`Filtros nesta página`**:

- `fato_sets[flag_escopo_pricing]` → `é` → `1`
- `dim_calendario[flag_preco_confiavel]` → `é` → `1`

O segundo impede o eixo do tempo de incluir 1985, onde a cobertura de preço é zero e o
ponto seria vazio — ou, pior, calculado sobre 15 sets de 2.094.

Páginas 6, 7 e 8 **não** levam esses filtros: rodam sobre as 18.457 linhas.

**8.5 — Título que se escreve sozinho, e que declara a base.** Em cada visual:
`Formatar visual > Geral > Título > Texto`, botão **`fx`** >
`Formatar por: Valor do campo` > `Com base no campo`:

| Visual | Medida de título |
|---|---|
| base real (páginas 1, 2, 3 e o gráfico direito da 5) | `_Medidas[Título de escopo — preço real]` |
| base nominal (páginas 4, 7 e o gráfico esquerdo da 5) | `_Medidas[Título de escopo — preço nominal]` |
| mix, rotação, cobertura, qualidade (páginas 6, 7, 8) | `_Medidas[Título de escopo — catálogo]` |

Título digitado à mão mente quando o filtro muda; título calculado não consegue. E os dois
de preço já carregam a frase da base — "USD NOMINAL de lançamento, sem correção por
inflação" ou "USD CONSTANTES DE 2022, deflacionado pelo CPI-U (BLS)". **Não existe visual
de preço sem base declarada**, e essa regra é cumprida por medida, não por disciplina.

**8.6 — Sentinela.** Rodapé de cada página de preço: um `Cartão` com
`_Medidas[Sentinela de escopo]`, 9 pt, sem título.

**8.7 — Texto alternativo.** Em cada visual, `Formatar visual > Geral > Texto alternativo`.
Escreva a **leitura**, não a forma: *"Preço por peça em dólares de 2022 cai de 0,139 para
0,103 entre 2007 e 2022, enquanto a série nominal fica plana"*, não *"gráfico de linhas"*.

---

## Passo 9 — Os visuais, em ordem de dificuldade

**9.1 — Cartões de KPI (todas as páginas).** Visual `Cartão` para o valor e uma
`Caixa de texto` embaixo para o delta, ou o visual `KPI`. Tire o `Separador de milhares`
de medidas de ano. **Desligue a cor automática do delta** (verde/vermelho): é análise de
catálogo, não desempenho contra meta — o tijolo barateando não é bom nem ruim. Delta em
tinta secundária, com sinal e com a base nomeada por extenso ("vs. 2007").

**9.2 — Colunas simples (páginas 2, 6, 7, 8).** `Gráfico de colunas clusterizado`.
`Formatar visual > Colunas > Espaçamento` para deixar a coluna em no máximo ~24 px — a
coluna não preenche a faixa, o resto é ar. `Bordas arredondadas` em 4. Rótulo de dados só
nas colunas que a especificação indica.

**9.3 — Duas linhas na mesma escala (página 2).** `Gráfico de linhas`, eixo X
`dim_calendario[ano]`, valores `Preço por peça (real, USD 2022)` e
`Preço por peça (nominal)` — nesta ordem, para o real pegar o slot 1 (azul) e o nominal o
slot 2 (laranja). `Linhas > Largura do traço = 2`, `Marcadores > Ligado`, `Tamanho ≥ 8`.
Rótulo direto nas quatro pontas.
**Nunca ative o eixo Y secundário.** Aqui não é necessário e em lugar nenhum é permitido:
as duas séries já estão na mesma unidade (dólares por peça), e é a distância entre elas
que carrega a informação.

**9.4 — Linhas indexadas de três séries (página 1).** Mesmo visual, com as três medidas de
índice. Legenda no topo, rótulo só na última categoria — se a versão não permitir rótulo
seletivo por série, use três caixas de texto ancoradas às pontas.

**9.5 — Linhas indexadas com filtro de flag (página 3).** Igual à 9.4, com duas séries, e
**filtro de visual `dim_calendario[flag_cpi_toys_disponivel] = 1`**. Sem ele o gráfico
desenha a linha de brinquedos caindo a zero entre 1970 e 1977, onde a série do BLS não
existe — um ponto que não está na fonte parecendo um dado.

**9.6 — Barras agrupadas de duas séries (página 4).** `Gráfico de barras clusterizado`,
eixo Y **`dim_faixa_tamanho[faixa_tamanho]`** (não mais `fato_sets`), valores
`Preço por peça — licenciado (nominal)` e `— próprio (nominal)`.

**9.7 — Ênfase (páginas 4 e 6).** Barras em uma cor só (slot 1) e o subgrupo que recua em
cinza `#898781`: `Formatar visual > Colunas > Cores > fx > Formatar por: Regras`, regra
sobre `dim_faixa_tamanho[ordem_faixa]` ou sobre `dim_tema[flag_licenciado]`. Legenda de
duas entradas montada com caixa de texto e dois retângulos.
*A cor segue a entidade, nunca a posição no ranking* — se um filtro mudar a ordem das
barras, as cores não trocam de dono.

**9.8 — Os dois empilhados 100% lado a lado (página 5).** Dois
`Gráficos de colunas empilhadas 100%` de 402 × 360, eixo X `dim_calendario[ano]`, legenda
`dim_faixa_preco[faixa_preco_5]`. O da esquerda usa
`Participação da faixa no mix (nominal)`; o da direita,
`Participação da faixa no mix (real, USD 2022)`. No da direita,
`Formatar visual > Legenda > Desligado` — a legenda da esquerda serve às duas, e uma caixa
de texto de uma linha diz isso. Vão de 2 px entre segmentos, **na cor do fundo, nunca
borda desenhada em volta**.
**Confira os dois eixos Y:** empilhado 100% já fixa a escala em 0–100%, mas confirme, porque
a comparação inteira depende de os dois gráficos terem a mesma régua.

**9.9 — Mapa de calor (página 7).** Visual `Matriz`. Linhas
`dim_faixa_etaria[faixa_etaria]`, colunas `dim_faixa_preco[faixa_preco]`, valores `Sets`.
Botão direito no campo `Sets` dentro do poço `Valores` > `Formatação condicional` >
`Cor do plano de fundo` > `Formatar por: Escala de cores`:

| Campo | Valor |
|---|---|
| `Mínimo` | `Menor valor`, cor `#CDE2FB` |
| `Centro` | marcado, `Médio`, cor `#3987E5` |
| `Máximo` | `Maior valor`, cor `#0D366B` |

Filtros de visual: `ano` entre 2018 e 2022; `dim_faixa_etaria[ordem_faixa]` maior que 0;
`dim_faixa_preco[ordem_faixa]` maior que 0. Ligue `Mostrar valores como texto` — **a célula
zero é a resposta desta página** e precisa aparecer como célula pálida com um `0` escrito.

**9.10 — Matriz de tabela (página 5).** Linhas `dim_calendario[ano]`, colunas
`dim_faixa_preco[faixa_preco]` (as **seis** originais), valores
`Participação da faixa no mix (nominal)`, `Participação da faixa no mix (real, USD 2022)` e
`Delta de participação vs. primeiro ano (real, USD 2022)`. É a versão acessível dos dois
empilhados, e é onde as faixas de topo voltam separadas.

**9.11 — Botão de alternância (página 4).** `Exibição > Indicadores` e `Exibição > Seleção`.
Dois visuais sobrepostos — um com `Preço por peça (nominal)`, outro com
`Preço por peça (nominal, ex-pré-escolar e júnior)` — e dois indicadores que alternam a
visibilidade. Botão com ação `Indicador`, rótulos `Todos os temas` e
`Sem pré-escolar e júnior`.

**9.12 — A caixa de ressalva (página 3).** Não é visual: é uma `Caixa de texto` ocupando a
área inteira do visual de apoio, fundo `#F9F9F7`, fio de 1 px `#E1E0D9`, com o parágrafo de
`docs/dashboard-spec.md` §3 página 3. **Ela é o elemento mais importante daquela página** —
quem tirar print do número de 147% tem de levar a ressalva junto.

---

## Passo 10 — Fechar

- `Exibição > Opções de exibição > Alinhar à grade`.
- Renomeie as abas. **Oculte** a página `_conferencia` (botão direito > `Ocultar página`)
  em vez de apagá-la: as medidas do teste de fumaça ficam de pé e quem for reproduzir o
  projeto — inclusive você, daqui a seis meses — vai querer rodar de novo depois de
  qualquer mexida no modelo.
- Salve. Para publicar, `Página Inicial > Publicar` exige conta de trabalho do Power BI
  Service; sem ela, o caminho para o portfólio é o `.pbix` no repositório mais capturas de
  tela das oito páginas, referenciadas pelo `README.md` da raiz.

---

## Apêndice A — se você já montou o `.pbix` pela versão anterior

Ordem de execução. Nada aqui é opcional, e **é mais curto do que recomeçar**.

**A.1 — Reimportar e importar.** No Editor do Power Query, para `fato_sets` e
`dim_calendario`, clique na etapa `Source` (a primeira) e confirme que ela aponta para o
arquivo atual; depois `Página Inicial > Atualizar Visualização`. As colunas novas aparecem
no fim. Importe `dim_faixa_tamanho.csv` como sétima consulta (passo 1).

**A.2 — Apagar três etapas do Power Query**, em `fato_sets`, pelo `x` ao lado da etapa em
`ETAPAS APLICADAS`:

| Etapa a apagar | Substituída por |
|---|---|
| Coluna personalizada `faixa_tamanho` | `dim_faixa_tamanho[faixa_tamanho]`, via relação 6 |
| Coluna personalizada `ordem_tamanho` | `dim_faixa_tamanho[ordem_faixa]` |
| Coluna personalizada `flag_preco_99` | `fato_sets[flag_preco_99]`, agora nativa do CSV |

`faixa_preco_5` / `ordem_faixa_5` em `dim_faixa_preco` **ficam**: a camada de dados revisou
e concordou que são agrupamento de apresentação e pertencem aqui.

**A.3 — Acrescentar `sk_faixa_preco_real`** (passo 3).

**A.4 — Tipar as quatro colunas numéricas novas** com `Usando Localidade… > Inglês (EUA)`
(passo 2). **Este é o passo que mais provavelmente vai ser esquecido**, porque o arquivo já
funcionava antes — e é o que faz `1.41146` virar `141.146` sem nenhum aviso.

**A.5 — Criar as relações 6 e 7** (passo 4). A 7 já nasce **desmarcada**.

**A.6 — Ocultar e `Não resumir`** as colunas novas (passo 5.1 e 5.2): `sk_faixa_tamanho`,
`sk_faixa_preco_real`, `vl_preco_usd_2022`, `flag_preco_99`, `flag_cpi_toys_disponivel`, as
chaves de `dim_faixa_tamanho` e as três colunas de CPI.

**A.7 — Refazer o `Classificar por coluna` de `faixa_tamanho`**, agora na dimensão
(passo 5.3). O antigo morreu junto com a coluna da fato.

**A.8 — Renomear as medidas de preço** para a convenção de base. O Power BI atualiza as
referências sozinho quando se renomeia pelo painel `Dados` — inclusive dentro de outras
medidas e nos visuais — mas **não** dentro de texto digitado à mão numa caixa de texto.
Depois, cole as medidas novas das pastas `02 Preço real`, `07 Inflação e categoria` e as
gêmeas reais de `04 Licença`, `05 Tempo` e `06 Mix`.

**A.9 — Repontar os visuais** que usavam `fato_sets[faixa_tamanho]` para
`dim_faixa_tamanho[faixa_tamanho]`, inclusive a regra de cor condicional que usava
`ordem_tamanho`. **O rótulo e a ordem são idênticos, então nada muda na tela** — e é
justamente por isso que é fácil esquecer: o visual fica quebrado com a mesma aparência de
antes. Se um campo tiver virado um alerta de "campo não encontrado", é este.

**A.10 — Corrigir os números escritos à mão** nas caixas de texto:

| Onde | Estava | Passa a ser |
|---|---|---|
| Cartão de mediana, página da escada | US$ 24,99 em 2007 · +60,0% | **US$ 29,99 em 2007 · +33,3%** |
| Manchete do resumo | índice 103,9 · "o tijolo não encareceu" | **índice real 73,6 · "o tijolo ficou 26% mais barato"** |
| Cartão de ticket médio | +74,8% | **+23,8% real**, com +74,8% como contraponto nominal |
| Manchete da escada | +10,5 p.p. acima de US$ 100 | **−0,8 p.p. acima de US$ 50, base real** |

**A.11 — Acrescentar as páginas novas.** A página 3 (categoria) não existia, e a página 5
(escada) passou de um gráfico empilhado para dois lado a lado. `docs/dashboard-spec.md` §3
tem as duas.

**A.12 — Rodar o teste de fumaça inteiro** (passo 7), os três blocos. Especialmente o
bloco 3: ele é o único que prova que a relação inativa e o `USERELATIONSHIP` funcionam, e
não existia na versão anterior.

---

## Checklist final

- [ ] Detecção automática de relação desligada **antes** da primeira carga
- [ ] **Sete** consultas, de `exports/`, UTF-8, delimitador vírgula
- [ ] `fato_sets` com **19** colunas; `dim_calendario` com **9**; `dim_faixa_tamanho` com 6 linhas
- [ ] As **sete** colunas decimais tipadas com `Usando Localidade… > Inglês (EUA)`
- [ ] Máximo de `vl_preco_usd` = **849,99**; `fator_deflator_base2022` de 2007 = **1,41146**
- [ ] `qt_pecas` com 3.924 nulos e `cpi_toys_media_anual` com 8 nulos preservados
- [ ] Três etapas antigas do Power Query apagadas; `sk_faixa_preco_real` acrescentada
- [ ] **Seis** relações ativas + **uma inativa** (linha pontilhada no diagrama)
- [ ] Nenhuma bidirecional; nenhum `(Em branco)` em eixo de dimensão
- [ ] Os cinco `Classificar por coluna` aplicados — o de `faixa_tamanho` **na dimensão**
- [ ] `dim_calendario` **não** marcada como tabela de datas
- [ ] `vl_preco_usd` e `vl_preco_usd_2022` **ambas ocultas**
- [ ] Colunas de CPI visíveis, com `Não resumir`
- [ ] Teste de fumaça: os **três** blocos batendo
- [ ] Nenhuma medida de preço sem `(nominal)` ou `(real, USD 2022)` no nome
- [ ] Filtro de página `flag_escopo_pricing` + `flag_preco_confiavel` nas páginas 1 a 5
- [ ] Título por `Valor do campo` em todos os visuais, com a base certa em cada um
- [ ] Filtro `flag_cpi_toys_disponivel = 1` no gráfico da página 3
- [ ] Sentinela de escopo no rodapé das páginas de preço, confirmando
- [ ] Texto alternativo em todos os visuais
