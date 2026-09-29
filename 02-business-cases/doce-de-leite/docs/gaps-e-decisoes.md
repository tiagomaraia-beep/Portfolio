# Gaps fechados e decisões de modelagem

Companheiro de `leitura-da-origem.md` (o que a planilha de faculdade tinha) e do
`business-case-fpa-planta-alimentos.xlsx` (o que foi feito). Aqui: **o que mudou, por quê, e
o que ainda não tem fonte.**

---

## Parte 1 — Os oito gaps

### Gap 1 — DRE em formato FP&A · **fechado**
A origem não tinha nenhuma linha de EBITDA, EBIT, despesa operacional separada de custo, ou
margem. O que ela chamava de "Lucro bruto" já era depois de todo o custo fixo, inclusive
depreciação — era EBIT com nome errado.

A aba `4. DRE` traz: Receita bruta → deduções → Receita líquida → custo variável → frete →
comissão → **Margem de contribuição** → custo fixo → manutenção e seguro → contingência →
**EBITDA** → depreciação → **EBIT** → IRPJ/CSLL → **Lucro líquido**, com **margem sobre
receita líquida em cada uma das quatro linhas de resultado**. Mais um bloco de memória por
unidade que alimenta a ponte de variância.

Margem EBITDA: 34,9% no ano 1, 55,8% no ano 10.

### Gap 2 — Premissas enterradas em fórmula · **fechado**
Todas migraram para a aba `2. Inputs`, cada uma com rótulo, unidade e a célula de origem citada:
- `=0,18+0,0065+0,03+0,03+0,25` virou cinco linhas: ICMS, PIS, COFINS, comissão, margem-alvo.
- `(H16-240000)*0,1` virou IRPJ, adicional, limite do adicional e CSLL, em quatro células.
- Manutenção 3%, seguro 1,5% e contingência 10% do CAPEX, que estavam como literal em 10
  linhas cada, viraram uma célula por premissa.
- O CTU e o volume, que estavam **digitados à mão**, viraram cálculo e link.

### Gap 3 — Depreciação errada · **fechado, com antes/depois documentado**
Ver a Parte 2 abaixo e a seção C da aba `3. Depreciacao`.

### Gap 4 — Taxa de desconto · **fechado na estrutura, `(confirmar)` nos parâmetros**
A origem descontava a 12,25%, declarada como "a Selic vigente em outubro de 2020", sem
prêmio de risco nenhum. O bloco H da aba `2. Inputs` constrói:

```
Ke   = Rf + Beta realavancado x ERP
WACC = Ke x E/V + Kd x (1-t) x D/V
```

Com os placeholders atuais (Rf 12,25% · ERP 7,0% · Beta 0,85 · D/E 0), **WACC = 18,2%**.

| | VPL |
|---|---|
| @ Selic 12,25% | R$ 63,4 mi |
| @ WACC 18,2% | R$ 40,9 mi |
| **Impacto de trocar a taxa** | **R$ 22,5 mi, ou 35% do VPL** |

A tabela da seção C da aba `7. Cenarios` mostra o VPL para taxas de 12,25% a 24% — exata,
porque o fluxo de caixa não depende da taxa.

**Ainda `(confirmar)`:** ERP, beta e D/E são placeholders. Ver Parte 4.

### Gap 5 — Cenários e sensibilidade · **fechado**
- Três cenários por **seletor único** (`2. Inputs!C5`), cinco alavancas: volume, margem-alvo,
  custo variável unitário, contingência e mix regional.
- **Tornado** de cinco alavancas (aba `7`, seção B), cada uma variada isoladamente.
- **Sensibilidade ao custo de capital** (seção C), exata.
- **Tabela bidimensional** VPL = f(WACC, g) com perpetuidade (seção D).

O VPL vai de R$ 24,8 mi (pessimista) a R$ 52,3 mi (otimista). Em nenhum cenário o projeto
destrói valor: a TIR não cai abaixo de 37,8%.

A alavanca que mais move o VPL é a **margem-alvo**, não o volume — e é a premissa com menos
base no caso.

### Gap 6 — Checks, capa e sumário · **fechado**
A aba `10. Checks` traz **19 amarrações**, cada uma com valor A, valor B, diferença, status e
uma linha explicando por que o check existe. Um veredito consolidado no topo, replicado na capa.

Os checks vão além do óbvio: recalculam o VPL por `SOMARPRODUTO` sem passar pela linha de
fatores de desconto, verificam que a TIR zera o VPL, que a depreciação acumulada nunca
ultrapassa a base depreciável, que o capital de giro volta a zero no fim do horizonte, que
a ponte de EBITDA fecha em todos os anos, e que o **motor de cenários — uma segunda
implementação do modelo, escrita com outras fórmulas — chega ao mesmo VPL e ao mesmo EBITDA**.

Estado: **19 de 19 OK**, nas seis combinações de cenário × modo de precificação.

O check 19 é posterior: na revisão do modelo, o payback descontado do motor de cenários
(4,40 anos no pessimista) não batia com o da aba `6. Valuation` (4,91). O motor dividia o
saldo acumulado **descontado** pelo fluxo do ano **sem descontar** — dois paybacks para o
mesmo cenário, e nenhum check pegava. O motor foi corrigido e o check 19 passou a amarrar
as duas implementações, como os checks 13 e 14 já faziam com VPL e EBITDA.

### Gap 7 — Ponte de variância de EBITDA · **fechado**
Aba `9. Ponte EBITDA`, decomposição na ordem volume → preço → mix → custo variável → custo fixo:

```
Efeito volume  = (V1 − V0) × margem de contribuição unitária ANTERIOR
Efeito preço   = V1 × Δ(preço líquido − comissão unitária)
Efeito mix     = V1 × (frete unitário ponderado ANTERIOR − atual)
Efeito custo   = V1 × (custo variável unitário ANTERIOR − atual)
Efeito fixo    = −(custo fixo total atual − anterior)
```

Fecha **exatamente** no ΔEBITDA — não por tolerância, por álgebra. Há três pontes: ano a ano
(anos 2 a 10), um ano destacado por seletor, e cenário ativo contra o Base. Todas com check próprio.

Mais um comentário de gestor em cinco linhas, escrito em linguagem de comitê.

### Gap 8 — Ponto de equilíbrio · **fechado**
A origem calculava o PE sobre um CTU **diferente** do usado na DRE (15,3406 contra 15,323),
e não tinha nenhuma leitura de negócio. A seção E da aba `7` traz:

| | Ano 1 | Ano 10 |
|---|---|---|
| PE contábil | 438.675 un | 285.608 un |
| PE de caixa | 363.165 un | 236.333 un |
| Ocupação no PE | 35,3% | 9,3% |
| **Margem de segurança** | **64,7%** | **90,7%** |
| Alavancagem operacional | 1,41x | 1,08x |

Com a leitura: o PE de caixa é menor que o contábil pela depreciação — é o número que importa
numa crise de demanda; e a alavancagem operacional alta diz que **o risco do caso é volume,
não margem**.

---

## Parte 2 — A depreciação, antes e depois

O autor anotou "Depreciacao esta errada" em `22.2 Fluxo de Caixa!C5` e não disse onde.
São **quatro defeitos**, com sinais opostos:

| # | Defeito | Sinal |
|---|---|---|
| D1 | Base de R$ 16.185.053 contra os R$ 16.201.826 corretos. Faltavam R$ 16.773: itens de laboratório pegos antes do acréscimo de 15%, e bancada (R$ 3.800) e armário de laboratório (R$ 4.048) sem classificação | subdepreciava |
| D2 | "Material de informática e móveis" tem vida de 5 anos na própria tabela da origem e era depreciado por 10: R$ 313.844 sobre base de R$ 156.922 — **200% do custo** | superdepreciava R$ 156.922 |
| D3 | R$ 594 mil de reinvestimento saía do caixa nos anos 4, 5 e 7 e nunca entrava na base | subdepreciava |
| D4 | Virava custo fixo unitário dividida por unidades **produzidas** e voltava ao resultado multiplicada por unidades **vendidas**: no ano 1 deduzia R$ 974.270 e somava de volta R$ 885.859 — **R$ 88.412 de caixa fantasma, todo ano** | inflava o FCL |

**Não era erro:** o terreno (R$ 908.612) estar fora da base está certo. E o mecanismo do
escudo fiscal — deduzir antes do imposto, somar de volta no fluxo — estava correto. O
problema era o valor, não o lugar.

### Antes e depois

| | Origem | Corrigida |
|---|---|---|
| Ano 1 a 4 | 885.859 | 888.564 |
| Ano 5 | 885.859 | 904.664 |
| Ano 6 e 7 | 885.859 | 899.608 |
| Ano 8 a 10 | 885.859 | 928.588 |
| **Total em 10 anos** | **8.858.586** | **9.043.902** |
| Diferença | | **+185.316** |

Em R$ o erro era modesto — o que não o torna menos grave. O que interessa é o **método**: a
origem tinha uma constante; o modelo tem um registro de ativos com classe, ano de entrada,
valor e vida útil, e um cronograma que responde a qualquer reinvestimento novo. E o defeito
D4, que era o maior em caixa, desaparece por construção, porque volume de custo e volume de
receita passaram a ser o mesmo número.

---

## Parte 3 — Decisões de modelagem

Cada decisão muda um número do caso em relação à origem. Todas são reversíveis mexendo na
aba `2. Inputs`.

**D-01 — Volume = unidades produzidas, não vendidas.**
A origem vendia ~10% mais unidades do que produzia, todo ano, sem estoque. As duas séries
estão na aba `2. Inputs` (a de vendas fica visível, em cinza, como referência). Adotei a
produção, que é o balanço de massa da engenharia. Reduz a receita do ano 1 em ~9%.

**D-02 — A parcela de 3% do markup virou despesa.**
Na origem essa parcela entrava no preço e nunca aparecia como custo: virava margem escondida,
e a margem realizada era 28%, não os 25% declarados. Aqui é uma linha "Comissão sobre vendas".
Para voltar ao comportamento da origem, zerar a alíquota em `2. Inputs`. **É `(confirmar)`:
a origem nunca identificou o que era essa parcela.**

**D-03 — CAPEX corrigido e realocado ao ano declarado.**
Quatro correções: o CUB (R$ 2.163,98/m²) somado como investimento; 25 notebooks multiplicados
pelo preço do tanque de leite; uma soma elevada ao quadrado no laboratório; a empilhadeira de
2030 contada duas vezes. O reinvestimento de 2028 cai de R$ 5.745.001 para **R$ 143.119** — que
é exatamente o que a coluna descreve (renovação de 5 anos dos ativos de vida curta) e bate com
a vida útil de 5 anos da própria tabela da origem. Além disso, a origem pulava o ano de 2026 e
antecipava todo o reinvestimento em um ano; aqui cada desembolso fica no ano em que a origem o
declara.

**D-04 — Depreciação por registro de ativos.** Ver Parte 2.

**D-05 — Manutenção, seguro e contingência sobre o CAPEX acumulado.**
A origem usava só o CAPEX do ano 0. Diferença pequena (+3,5% de base ao fim), mas é o
tratamento correto: o ativo novo também precisa de manutenção e de seguro.

**D-06 — Capital de giro reconstruído.**
Sobre os prazos declarados na própria aba `22.1` da origem (30 dias de recebimento, 30 de
pagamento, caixa mínimo de 30 dias), com o giro de estoque de 17,3 dias derivado do detalhe
item a item dela (o leite gira em 1 dia, os demais insumos em 30). **Uma correção:** o caixa
mínimo passa a ser calculado sobre o custo **caixa**, não sobre o custo total — depreciação não
exige caixa. E a liberação do giro no ano 10 é uma linha explícita, em vez de acontecer por
uma célula vazia, como na origem.

**D-07 — Modo de precificação com seletor.**
No modo 1 (custo + markup, a lógica da origem), **custo mais alto gera VPL mais alto**, porque
o preço sobe junto: o modelo premia ineficiência. Isso não é um bug da origem, é a consequência
lógica de precificar por markup — mas torna qualquer sensibilidade a custo enganosa. O modo 2
fixa o preço por ano e faz a sensibilidade a custo se comportar como o negócio se comporta. O
caso base roda no modo 1, para ser comparável à origem.

**D-08 — WACC = Ke, porque D/E = 0.**
Não há dívida em nenhuma aba da origem, nem contratação de financiamento, nem despesa
financeira. Forçar uma estrutura de capital seria inventar. O D/E é um input: colocar um valor
ali liga o resto da fórmula.

**D-09 — Caso base sem valor terminal.**
Para ser comparável à origem, que também não tinha. As duas alternativas estão calculadas em
separado na aba `6`: **liquidação** (VPL R$ 42,5 mi, somando o valor contábil líquido do
imobilizado) e **continuidade** (VPL R$ 76,1 mi, perpetuidade com g = 0). As três visões não se
somam — são hipóteses alternativas sobre o que acontece no ano 11.

**D-10 — Depreciação começa no ano seguinte à entrada do ativo.**
Convenção declarada, aplicada igual para o ano 0 e para os reinvestimentos. Faz a renovação de
informática de 2028 pegar exatamente onde o bloco original de 5 anos termina.

**D-11 — Mix = mix regional.**
É a única dimensão de mix com dado duro na origem (Sul 5% · Sudeste 80% · Nordeste 3% · Norte
2% · Centro-Oeste 10%, com frete unitário diferente por região). Há também três sabores
(tradicional, caju, café), mas a origem **não divide o volume entre eles** — modelar mix de
sabor exigiria inventar a divisão. O efeito do mix regional é pequeno em base (o frete é 0,4%
do custo e 80% já está no Sudeste); a alavanca existe para testar mudança de distribuição, e a
ponte reporta isso honestamente.

**D-12 — A engenharia não foi refatorada.**
Balanço de massa, balanço de energia, mapa de ocupação e APPCC entram como premissa, com a
célula de origem citada. Não é escopo de FP&A recalcular processo.

**D-13 — Sem `PROCX`, sem referência entre arquivos, sem macro.**
`PROCX` é função de matriz dinâmica e não sobrevive a um arquivo gerado por script; o modelo
usa `ÍNDICE`+`CORRESP`, que faz o mesmo e abre em qualquer lugar. Nenhuma fórmula aponta para
fora do arquivo.

---

## Parte 4 — O que ficou `(confirmar)`

Tudo em **amarelo** no arquivo. Nenhum destes números foi inventado com cara de fato; todos
estão marcados na célula e listados na capa.

| Premissa | Valor atual | O que falta |
|---|---|---|
| **Prêmio de risco de mercado (ERP Brasil)** | 7,0% | Placeholder. Fonte a usar: Damodaran, *Country Risk Premiums*, linha do Brasil. |
| **Beta desalavancado do setor** | 0,85 | Placeholder. Fonte a usar: Damodaran, *Betas by Sector — Food Processing*. |
| **D/E alvo e Kd** | 0 e 14% | O caso não tem dívida. Se houver intenção de alavancar, é uma decisão, não um dado. |
| **Taxa livre de risco** | 12,25% | A origem diz "Selic de outubro de 2020" e usa 12,25% — os dois não se conciliam. Atualizar com a Selic ou a NTN-B da data que o caso adotar. |
| **Margem-alvo crescente** | 25% → 43% | Sobe 2 p.p. ao ano na origem, sem estudo de preço. É a alavanca que mais move o VPL. |
| **Contingência de 10% do CAPEX ao ano** | 10% | Em 10 anos consome 100% do investimento inicial. É a maior premissa não justificada da origem. |
| **Comissão e outros sobre venda** | 3% | A parcela do markup que a origem nunca identificou. |
| **Preço de mercado (modo 2)** | semeado com o preço do próprio modelo | Substituir por preço observado de doce de leite 600 g. |
| **Crescimento na perpetuidade (g)** | 0% | Só importa se a visão de continuidade for a apresentada. |
| **Crescimento de 10% ao ano de market share** | 10% | Vem da aba de projeção da origem (`B19`), sem fonte. É o que sustenta toda a curva de volume. |

---

## Parte 5 — Achados que não estavam na lista dos oito gaps

Erros de fórmula encontrados na leitura da origem, todos corrigidos no modelo novo e
documentados em `leitura-da-origem.md`:

1. **R$ 5,6 mi de CAPEX fantasma em 2028** — 25 notebooks ao preço do tanque de leite
   (`AF20` usa `$N$4` no lugar de `$N$20`) e uma soma elevada ao quadrado no laboratório
   (`AF41` usa `*15%*` onde o padrão da planilha é `+15%*`).
2. **O CUB somado como investimento** — `AM10` soma `AM3`, que é R$ 2.163,98 por m², não um valor.
3. **Empilhadeira contada duas vezes** — `AA53` soma `AH17` duas vezes dentro do mesmo `SOMA`.
4. **Rotação de fornecedor copiada da linha errada** — `K24` = 260 onde deveria ser 12,
   inflando a necessidade de capital de giro do ano 2 em ~R$ 438 mil.
5. **Vender mais do que se produz** — duas séries de volume divergentes em ~10%, sem estoque.
6. **Defasagem de um ano** entre a aba de produção (linha rotulada 2023) e o P&L (ano 2024).
7. **CTU digitado à mão** no P&L (15,323) contra o CTU calculado (15,3406) — e o ponto de
   equilíbrio usando o segundo enquanto o resultado usava o primeiro.
8. **Payback digitado como texto** ("2,5 anos"), não calculado.
9. **Sem valor terminal** — o VPL truncava em 10 anos uma planta que continua operando.
10. **Margem escondida de 3 p.p.** — a parcela do markup que entrava no preço e nunca virava despesa.
11. **`(H16-240000)*0,1`** geraria crédito de imposto se o lucro ficasse abaixo do limite do adicional.
12. **O modelo premiava ineficiência** — consequência do markup sobre custo, agora explícita e com seletor.

---

## Parte 6 — O que eu faria a seguir

**Uma coisa só: fechar o bloco H da aba `2. Inputs` com fontes reais.**

Beta, ERP e estrutura de capital são os três números que decidem se o VPL do caso é R$ 41 mi
ou outro qualquer, e hoje são os únicos placeholders do modelo. Tudo o mais tem célula de
origem citada. Com esses três resolvidos — e são 20 minutos em duas tabelas do Damodaran — o
modelo sai de "estruturalmente pronto" para "apresentável numa entrevista", e a frase mais
forte da peça deixa de ter asterisco: *trocar a Selic pelo WACC tira R$ 22,5 mi do VPL, e essa
é a diferença entre um projeto que parece excepcional e um projeto que é bom.*
