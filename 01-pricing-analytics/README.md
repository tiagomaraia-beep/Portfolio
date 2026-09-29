# Pricing analytics de um catálogo de 18.457 produtos

**SQL → modelagem dimensional → Power BI.** Um catálogo de produtos de 1970 a 2022 lido
como um analista lê uma lista de preços: unit economics, prêmio de licença, escada de
preços, mix de portfólio e cobertura de sortimento — com correção por inflação e com uma
página inteira dedicada ao que o dado **não** permite afirmar.

O dataset é público (catálogo LEGO, origem Brickset). O enquadramento é de pricing.

> **Base de preço:** preço de lançamento no varejo dos EUA, em duas unidades — **USD
> nominal** (dólar do ano) e **USD constantes de 2022**, deflacionado pelo CPI-U do BLS.
> Todo número deste repositório declara em qual das duas está. Não existe leitura neutra:
> a mesma série dá índice 103,9 numa base e 73,6 na outra.

---

## Os três achados

**1. O tijolo ficou 26% mais barato. O set ficou 68% maior.**
Em dólar corrente o preço por peça mal se move entre 2007 e 2022 (US$ 0,0986 → 0,1025,
índice 103,9). Corrigido pela inflação, **cai 26,4%** (índice 73,6). No mesmo período o
set médio ganhou 68,3% de peças e subiu 23,8% em poder de compra — contra +74,8%
nominais. *Metade do "aumento de preço" que aparece no nominal é só inflação.*

**2. O prêmio de licença é ruído no preço do tijolo: +0,4%.**
O set licenciado custa 18,7% mais caro porque tem 18,2% mais peças. A licença se paga em
outro lugar: **+47% de densidade de minifigura** (5,97 contra 4,06 por mil peças,
2018–2022). O "desconto de licença" de −36,4% que aparece nos sets pequenos é Duplo
disfarçado — peça fisicamente maior, não decisão de preço.

**3. A escada de preços subiu na etiqueta e ficou parada no bolso.**
Em dólar corrente, a fatia do catálogo acima de US$ 50 mais que dobra: 17,7% → 37,8%. Em
poder de compra, a mesma fatia **não se move**: 38,6% → 37,8%. A mediana real **cai 5,5%**
enquanto a média real sobe 23,8%. Não houve reprecificação — 98,8% dos preços terminam em
`.99` e existem só 141 pontos de preço distintos. **Houve adição de produto caro no topo.**

O sumário de uma página está em [`docs/sumario-executivo.md`](docs/sumario-executivo.md).
A apuração completa, com as cinco perguntas, está em [`docs/achados.md`](docs/achados.md).

---

## Os dois dashboards

| Dashboard | Para quê | Onde |
|---|---|---|
| **Explorador de sets** | Navegar pelo catálogo: escolher uma coleção, buscar um set, ver a foto e os detalhes, e comparar os maiores, os mais raros e os mais divertidos | [`dashboard/index.html`](dashboard/) · [abrir no navegador](https://tiagomaraia-beep.github.io/Portifolio/01-pricing-analytics/dashboard/) |
| **Pricing do catálogo** | Os três achados de preço (real × nominal, prêmio de licença, escada de preços) em gráficos | [claude.ai/artifact/B6vghWEKUke5JTPskgJAQa](https://claude.ai/artifact/B6vghWEKUke5JTPskgJAQa) |

### Como usar o explorador

- **Abrir:** pelo link acima, ou baixando `dashboard/index.html` e abrindo no navegador. É um arquivo único, sem instalação: os 18.457 sets estão dentro dele. As fotos vêm do Brickset, então pedem internet.
- **Filtros** (valem para tudo na tela): coleção, busca por nome ou código do set, intervalo de anos, tipo e "só com foto". O padrão mostra só **sets de montar** (`category = 'Normal'`), o mesmo recorte das análises em SQL; "Todos os tipos" inclui brindes, livros, chaveiros e afins.
- **Indicadores:** número de sets, total de peças, preço médio (só entre os sets que têm preço) e total de minifiguras, sempre sobre o filtro atual. Abaixo, os lançamentos por ano.
- **Abas:**
  - *Explorar* — a lista inteira, ordenável por ano, peças, preço ou nome.
  - *Maiores* — mais peças, mais caros, mais minifiguras e as maiores coleções por total de peças.
  - *Raros* — pelo índice de raridade, descrito abaixo.
  - *Divertidos* — sets agrupados por palavra no nome (dragões, piratas, ninja, robôs, espaço, dinossauros, comida, Natal e outros). Há 101 sets com "dragon" no nome.
- **Detalhe:** clicar num set abre a foto, a ficha (ano, peças, minifiguras, preço de lançamento, idade mínima, grupo, tipo, raridade), o link para o Brickset e os maiores sets da mesma coleção.

### A lógica por trás

- **Mesma base das análises:** o explorador lê o `data/lego_sets.csv`. Preço é o de lançamento no varejo dos EUA, em **dólar nominal**. O explorador não deflaciona; a série real está no SQL (`sql/04-deflacao-e-serie-real.sql`) e no dashboard de pricing.
- **Índice de raridade (0 a 4):** mede **escassez de produção**, não valor de mercado. Soma sinais de que um set saiu em pouca quantidade: tema pequeno, brinde ou exclusivo, tema que durou um ano só e lançamento até 1985. Um set com índice 3 ou mais ganha o selo "raro".
- **Preço médio só com preço:** a média ignora os sets sem preço, e o rótulo diz quantos entraram. Antes de 2000 quase não há preço na base (ver `docs/qualidade-do-dado.md`), então uma média de coleção antiga pode vir de poucos sets.

---

## O que esta peça demonstra

| | |
|---|---|
| **SQL** | perfilagem de qualidade antes de qualquer conclusão, esquema estrela com chave substituta, `window functions`, CTEs encadeadas, deflação por série de índice |
| **Modelagem dimensional** | uma fato aditiva e seis dimensões conformadas; razão fora da fato e valor deflacionado dentro; dimensão com dois papéis via relação inativa |
| **DAX** | 66 medidas, contexto de filtro explicado medida a medida, sem inteligência de tempo (e o porquê) |
| **Rigor analítico** | escopo declarado em flag, duas bases de preço nunca misturadas, e uma página inteira sobre os limites do dado |

**A decisão de modelagem que eu defenderia numa entrevista:** *escopo e base são
propriedade da métrica, não do visual.* Não existe neste modelo uma medida de preço sem
escopo, nem uma medida de preço sem `(nominal)` ou `(real, USD 2022)` no nome, nem coluna
crua arrastável — e nem a faixa de preço troca de base sem que uma medida declare a troca.
O número errado não é difícil de achar: é **impossível de escrever**.

---

## Como ler este repositório

```
docs/sumario-executivo.md   ← comece aqui (1 página)
docs/achados.md               as cinco perguntas, respondidas
docs/qualidade-do-dado.md     o que o dado NÃO permite afirmar
docs/dicionario-de-dados.md   o contrato: tabelas, chaves, cardinalidades
docs/modelo-powerbi.md        o modelo em estrela e o porquê de cada decisão
docs/dashboard-spec.md        as oito páginas do relatório e a paleta validada
docs/passo-a-passo-powerbi.md como reproduzir no Power BI Desktop
dashboard/index.html          o explorador de sets (arquivo único)
sql/                          00 carga · 01 qualidade · 02 estrela · 03 análises · 04 deflação
exports/                      os sete CSV que alimentam o relatório
dax/medidas.dax               as 66 medidas
theme/                        o tema do Power BI
```

**Caminhos de leitura, por quem você é:**

- **Recrutador com 90 segundos** → os três achados acima, depois
  `docs/sumario-executivo.md`.
- **Gestor de FP&A / Pricing** → `docs/achados.md` e a seção 11 de
  `docs/qualidade-do-dado.md` (a comparação com o índice de brinquedos, e por que ela
  precisa de ressalva).
- **Analista técnico** → `sql/04-deflacao-e-serie-real.sql` e `docs/modelo-powerbi.md` §6,
  que é onde estão as duas decisões espelhadas: por que a razão fica **fora** da fato e o
  valor deflacionado fica **dentro**.

---

## O que este dado não responde

Está em voz alta porque é o que separa a leitura sênior da ingênua:

- **Nada sobre receita, margem ou sucesso comercial.** É preço de tabela de lançamento,
  sem unidade vendida, sem desconto, sem custo. Tema com mais produtos não é tema que
  vendeu mais — é tema com mais SKUs.
- **Nada antes de 2007** em matéria de preço: a cobertura da fonte é 0% nos anos 70 e 80.
  O escopo de preço é de **4.626 produtos, 25,1% do catálogo** — e é o pedaço sobre o qual
  dá para afirmar alguma coisa.
- **Nada ponderado por vendas.** O deflator é índice de cesta ponderada por consumo; o
  preço médio aqui é média simples de SKU lançado.
- **Nada fora dos EUA.**

A lista completa, com os vieses medidos, está em
[`docs/qualidade-do-dado.md`](docs/qualidade-do-dado.md).

---

## Reproduzir

**A camada de dados** (SQLite, sem dependência além do `sqlite3`):

```bash
cd data
sqlite3 lego.db < ../sql/00-carga.sql
sqlite3 lego.db < ../sql/01-qualidade-do-dado.sql
sqlite3 lego.db < ../sql/02-modelo-estrela.sql
sqlite3 lego.db < ../sql/03-analises.sql
sqlite3 lego.db < ../sql/04-deflacao-e-serie-real.sql
```

**A camada de relatório:** `docs/passo-a-passo-powerbi.md`, do zero ao dashboard, com
nomes de painel e de campo. Dois avisos que valem a leitura antes de começar:

1. **Locale.** Os CSV usam ponto decimal. O Power BI em pt-BR lê `44.99` como separador de
   milhar e o erro **não aparece** — o relatório carrega e os números ficam 100× maiores.
   O passo 2 trata isso, e o teste de fumaça do passo 7 denuncia se escapar.
2. **Teste de fumaça antes de qualquer visual.** Três blocos de números de controle. Se
   não baterem, há relacionamento duplicando linha, e um dashboard bonito sobre um modelo
   quebrado custa mais caro para descobrir depois.

---

## Créditos e limites

Dados: catálogo LEGO via Brickset (público). Índices de preço: U.S. Bureau of Labor
Statistics, CPI-U `CUUR0000SA0` e CPI de brinquedos `CUUR0000SERE01`, média anual.

Este é um projeto de portfólio, sem vínculo com a LEGO Group nem com o BLS. Os preços são
de tabela de lançamento no mercado americano; nada aqui descreve preço praticado, receita
ou desempenho comercial da empresa.
