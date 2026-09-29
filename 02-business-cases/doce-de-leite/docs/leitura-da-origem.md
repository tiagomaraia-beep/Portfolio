# Leitura da origem — `00-origem-projeto-faculdade.xlsx`

Auditoria da planilha de faculdade (planta de alimentos, bebida láctea 600 g, horizonte
2023–2033) **antes** de qualquer modelagem. Nada aqui foi alterado: o arquivo de origem é
lido, não editado. O original no OneDrive não foi tocado.

27 abas. Só 6 sustentam o caso de investimento; as outras 21 são engenharia (balanço de
massa/energia/sólidos, mapa de ocupação, APPCC, resíduos) e **não serão refatoradas** —
entram no modelo novo como premissa, não como cálculo.

---

## 1. Mapa das abas

| Aba | Papel | Entra no modelo novo? |
|---|---|---|
| `3. Projeção de produção - entre` | volume: produção (t) → unidades/ano | **sim** — driver de volume |
| `7. Receita base e proporçõesFra` | mix por sabor/região | sim (mix) |
| `7. Balanço de massa 10 anos` · `7. Balanço de massa batelada (c` · `7. Balanço de sólidos totais` · `7. Balanço de energia batelada` | engenharia de processo | não |
| `7. Massas iniciais, ritmo de tr` | unidades **produzidas** por ano, massas de embalagem | **sim** — driver de volume produzido |
| `8. Mapa de ocupação 2024-27 / 2028-30 / 2031-33` · `Mapa de ocupação (2h20)` · `Mapa de produção 2023/2025 (2h)` · `Mapa com referência de máquinas` · `Balanço de massa batelada ano 1` | capacidade e ocupação | não |
| `9.Orcamentos` | preço de insumos e consumo por ano | **sim** — custo de matéria-prima |
| `11. Plano APPCC...` · `12. Residuos e Subprodutos` · `13. Máquinas e equipamentos - P` | qualidade / engenharia | não |
| `Demanda de equipamentos e Inves` | **CAPEX** por ano, terreno, construção civil | **sim** |
| `20. Custos Unitários` | custo fixo e variável por ano, CVU/CFU/CTU, **depreciação** | **sim** |
| `21. PVU e Imp. sobre Faturament` | markup, preço, receita, impostos, IRPJ/CSLL, lucro líquido | **sim** |
| `22.1 Capital de Giro` | NCG ano a ano (estoque, caixa mínimo, clientes, fornecedores) | **sim** |
| `22.2 Fluxo de Caixa` | FCL, VPL, TIR, payback | **sim** |
| `22. Ponto de Equilibrio` | PE em unidades e % da produção | **sim** |
| `Página18` · `Depois excluir` (oculta) | rascunho | não |

---

## 2. As células que governam o caso

### Volume — `3. Projeção de produção - entre`
- `B19` = 10% — taxa de crescimento anual do market share (premissa solta, sem fonte).
- `B20` = 0,6 kg — peso da embalagem.
- `C23:C33` — produção em toneladas, `=H<n>*(1+$B$19)`.
- `G23:G33` — **unidades produzidas/ano, digitadas à mão** (1.368.200 … 3.404.446).
  Não são fórmula de `C`/`B20`: são número fixo. Quebra a corrente volume → receita.
- Linha 23 é rotulada **2023**; linha 33, **2033**. São 11 linhas para 10 anos de projeção.

### Preço e receita — `21. PVU e Imp. sobre Faturament`
- `B3` = `=0,18+0,0065+0,03+0,03+0,25` → markup 49,65%. Cinco parcelas somadas dentro da
  fórmula: ICMS 18% + PIS 0,65% + COFINS 3% + **0,03 não identificado** + margem 25%.
  A margem cresce 2 p.p. ao ano até 43% em 2033 (`B12` = `...+0,43`), sem justificativa.
- `C3:C12` — CTU **digitado à mão** (15,323 · 14,89 · … · 12,814). O CTU vivo está em
  `20. Custos Unitários!AE3` = **15,3406**. Diferença de R$ 0,018/un no ano 1 → o preço, a
  receita e todo o valuation rodam sobre um custo defasado.
- `E3` = `=C3/(1-B3)` — precificação por markup sobre custo total.
- `O3` = `='3. Projeção de produção - entre'!G23` — **volume vendido do ano 2024 vem da
  linha rotulada 2023.** Defasagem de um ano entre a aba de produção e o P&L.
- `I3` = `=(0,18+0,0065+0,03)*H3` — 21,65% de dedução sobre receita bruta, alíquotas
  repetidas dentro da fórmula em 10 linhas.
- `I16` = `=(0,15*H16)+((H16-240000)*0,1)` — IRPJ 15% + adicional de 10%. O adicional
  incide sobre o excedente, o que está certo, mas a fórmula não protege lucro < R$ 240 mil
  (geraria crédito de imposto) e não há escolha de regime (Lucro Real × Presumido).
- `J16` = `=0,09*H16` — CSLL 9%.
- **Não existe linha de EBITDA, EBIT, despesa operacional separada de custo, nem margem
  em nenhum ponto.** O "Lucro bruto" (`K3`) já é depois de todo o custo fixo, inclusive
  depreciação — ou seja, é EBIT com nome de lucro bruto.

### Custos — `20. Custos Unitários`
- Colunas `B:J` = custo variável; `L:T` = custo fixo; `V` = total.
- `R3` = `=0,03*'Demanda...'!$AA$46` — manutenção 3% do CAPEX/ano.
- `S3` = `...*0,015` — seguro 1,5% do CAPEX/ano.
- `T3` = `...*0,1` — **imprevistos 10% do CAPEX todo ano**: R$ 1.711.260/ano × 10 anos =
  R$ 17,1 mi, exatamente 100% do CAPEX inicial gasto em contingência. É a maior premissa
  não justificada do modelo.
- `N3` = folha salarial **digitada** (1.275.600), constante por 4 anos e depois 1.342.800.
- `AC3` = `=Y3/Y15` (CVU), `AD3` = `=Z3/Y15` (CFU) — divididos por **unidades produzidas**
  (`Y15` = 1.244.035 em 2024).
- `AE3` = `=SOMA(AC3:AD3)` — CTU.

### CAPEX — `Demanda de equipamentos e Inves`
- `AA46` = `=SOMA(AA10;AA17;AA25;AA30;AA41)+AM10` = **R$ 17.112.602** no ano 0 (2023).
- `AM10` = `=SOMA(AM3;AM5;AM6)` = 13.383.091. **`AM3` é o CUB (R$ 2.163,98 por m²), não um
  investimento** — entra somado como se fosse valor de obra. Erro de R$ 2.164.
- `AM5` = construção civil = CUB × 4.803 m² × 1,20 = R$ 12.472.315.
- `AM6` = terreno = 849.170 × 1,07 = R$ 908.612 (não depreciável — tratado certo).
- Reinvestimentos: `AA50` = 161.000 (2027) · `AA51` = 5.745.001 (2028) · `AA53` = 338.100 (2030).
- `AA53` e `AA55` somam `AH17`/`AJ17` e `AJ30` **duas vezes** dentro do `SOMA` — sem efeito
  numérico aqui porque as parcelas repetidas são zero, mas é bomba-relógio.
- `AF41` = `=SOMA(AF33:AF40)*15%*SOMA(AF33:AF40)` — **multiplicação onde deveria ser soma**:
  o padrão do resto da planilha é `SOMA(...)+15%*SOMA(...)`. Resultado: R$ 3.279.746 de
  CAPEX de laboratório em 2028, contra os R$ 5.376 corretos. Infla o CAPEX de 2028 em
  R$ 3,27 mi (o ano 4 do fluxo de caixa).

### Depreciação — `20. Custos Unitários` linhas 125–136
- Tabela de vida útil (`A128:C130`): edificações 25 anos / 4% · equipamentos 10 anos / 10%
  · informática e móveis 5 anos / 20%.
- `D133` = 12.472.315 × 4% = 498.893
- `D134` = 3.555.816 × 10% = 355.582
- `D135` = 156.922 × 20% = 31.384
- `D136` = **R$ 885.858,58/ano, constante nos 10 anos.**
- `P3:P12` = `=$D$136` — a depreciação entra no custo fixo (logo, é dedutível no lucro).
- `22.2 Fluxo de Caixa!E11:E20` = `=$D$136` — e é somada de volta no FCL.

### Capital de giro — `22.1 Capital de Giro`
- NCG = estoque + caixa mínimo (30 d de custo total) + clientes (30 d de receita bruta)
  − fornecedores. `F38` = `=SOMA(F18;F20;F22)-F37`.
- **`K24` = 260** para "Leite Integral Cru" no crédito de fornecedores do ano 2, enquanto
  `J24` = 30 dias. A rotação certa é 12 (360/30); 260 foi copiado da linha de estoque.
  Efeito: crédito de fornecedor de leite cai de R$ 461.290 (ano 1) para R$ 23.541 (ano 2),
  e a NCG do ano 2 sobe artificialmente ~R$ 438 mil.
- O ano 10 recupera toda a NCG porque `C20` está **vazia** (`D20` = `=C20-C19` = −13,29 mi).
  Funciona por acidente, não por desenho.

### Fluxo de caixa e valuation — `22.2 Fluxo de Caixa`
- `C5`: **"Depreciacao esta errada"** — anotação do próprio autor.
- `A3:A4`: a taxa de desconto é "a Taxa SELIC vigente em **outubro de 2020**".
- `J24` = **12,25%** — a Selic usada. Sem prêmio de risco, sem beta, sem estrutura de
  capital. O projeto é 100% equity: não há dívida em lugar nenhum do modelo.
- `G10` = `=(F10+E10)-(D10+B10)` → FCL = Lucro líquido + Depreciação − ΔCG − CAPEX.
- `L9` = `=TIR(G10:G20)` = **48,88%** · `L10` = `=J36` (VPL) = **R$ 66.467.823**.
- Payback simples 2,5 anos e descontado 2,8 anos, ambos **digitados como texto**
  (`C38` = "2,5 anos"), não calculados.
- **Não há valor terminal.** O VPL é a soma de 10 anos de uma planta que continua operando.
- `C43` — link para um Google Sheets externo, resíduo de trabalho em grupo.

### Ponto de equilíbrio — `22. Ponto de Equilibrio`
- `H4` = `=C4/(F4-G4)` = 267.689 un → `J4` = 21,5% da produção do ano 1.
- Usa o CTU **vivo** (`AE3` = 15,3406) enquanto o P&L usa o CTU **digitado** (15,323).
  Resultado: PVU do PE = R$ 30,468 e PVU do P&L = R$ 30,433. Duas verdades na mesma planilha.
- Classifica depreciação como custo fixo (certo para PE contábil), mas não há leitura de
  negócio: nenhuma frase diz o que 21,5% de ocupação significa para o risco do projeto.

---

## 3. Diagnóstico da depreciação — o erro que o autor anotou

`22.2 Fluxo de Caixa!C5` diz "Depreciacao esta errada". Não diz onde. São **quatro**
defeitos distintos, e o sinal de cada um é diferente:

| # | Defeito | Efeito |
|---|---|---|
| D1 | **Base incompleta.** Base usada = R$ 16.185.053. Base correta do ano 0 = CAPEX 17.112.602 − terreno 908.612 − CUB indevido 2.164 = **R$ 16.201.826**. Faltam **R$ 16.773** — itens de laboratório (`AA33`,`AA34`,`AA38`,`AA39`,`AA40`) foram pegos **antes** do acréscimo de 15%, e bancada (`AA36` = 3.800) e armário de laboratório (`AA35` = 4.048) não foram classificados em ativo nenhum. | subdeprecia |
| D2 | **Vida útil ignorada.** "Material de informática e móveis" tem vida de 5 anos (`B130`) e é depreciado nos 10 anos do horizonte: R$ 31.384 × 10 = R$ 313.844 sobre uma base de R$ 156.922. **200% do custo depreciado** — R$ 156.922 de excesso. | superdeprecia |
| D3 | **Reinvestimento sem depreciação.** R$ 6.244.101 de CAPEX entra no fluxo de caixa nos anos 4 (2027), 5 (2028) e 7 (2030) e **nunca** aparece na base. `D133:D135` só olha o ano 0. | subdeprecia |
| D4 | **Base de volume inconsistente.** A depreciação vira CFU dividindo por unidades **produzidas** (`Y15` = 1.244.035) e volta ao P&L multiplicada por unidades **vendidas** (`O3` = 1.368.200). A despesa efetivamente deduzida no ano 1 é R$ 974.270; a somada de volta no FCL é R$ 885.859. Sobra **R$ 88.412** de caixa fantasma no ano 1, e o erro se repete todo ano. | distorce o FCL |

Observação que **não** é erro: o terreno (R$ 908.612) está fora da base. Está certo — terreno
não deprecia. E a depreciação **é** deduzida antes do imposto (via CFU → CTU → CT) e somada
de volta no FCL: o mecanismo do escudo fiscal está correto. O problema é o valor, não o lugar.

---

## 4. Os oito gaps do projeto, confrontados com a planilha

| Gap | Se sustenta? | Evidência |
|---|---|---|
| 1. DRE em formato FP&A | **sim** | não existe nenhuma linha de EBITDA, EBIT ou margem; o resultado está em 3 abas |
| 2. Premissa dentro de fórmula | **sim, e é pior do que o registrado** | markup `=0,18+0,0065+0,03+0,03+0,25`, adicional IRPJ `(H16-240000)*0,1`, manutenção/seguro/imprevistos como % literal do CAPEX em 10 linhas, CTU e volume **digitados à mão** |
| 3. Depreciação errada | **sim** | quatro defeitos, tabela acima |
| 4. Selic 12,25% sem justificativa | **sim** | `J24` = 12,25%, declarada como Selic de out/2020; projeto 100% equity |
| 5. Sem cenários nem sensibilidade | **sim** | nenhuma tabela de dados, nenhum seletor, nenhuma variável de cenário |
| 6. Sem checks, capa ou sumário | **sim** | nenhuma célula de verificação na planilha inteira |
| 7. Sem ponte de variância de EBITDA | **sim** | não há sequer EBITDA para decompor |
| 8. Ponto de equilíbrio sem revisão | **sim** | roda sobre CTU diferente do usado no P&L e não tem leitura de negócio |

### Achados novos, fora dos oito gaps
- **A1. O reinvestimento de 2028 está R$ 5,6 mi inflado por duas referências erradas.**
  O ano 5 do fluxo (`AA51` = R$ 5.745.001) é o maior desembolso depois do ano 0, e é falso:
  - `AF20` = `=$N$4*T20` — multiplica 25 notebooks pelo preço do **tanque de armazenamento
    de leite** (`N4` = R$ 85.000) em vez do preço do notebook (`N20` = R$ 4.043).
    R$ 2.125.000 no lugar de R$ 101.075. A mesma troca de referência está em `AB13:AJ13`
    (chiller), onde é inofensiva só porque as quantidades são zero.
  - `AF41` = `=SOMA(AF33:AF40)*15%*SOMA(AF33:AF40)` — **multiplicação onde deveria ser soma**.
    O padrão do resto da planilha é `SOMA(...)+15%*SOMA(...)`. O resultado é a soma ao
    quadrado vezes 15%: R$ 3.279.746 no lugar de R$ 5.377.
  - CAPEX 2028 corrigido: **R$ 143.119** — que é exatamente o que a coluna descreve
    (25 notebooks, 30 cadeiras, 5 impressoras, refratômetro, phmetro, impressora de
    laboratório): a **renovação de 5 anos dos ativos de vida curta**. O número corrigido
    bate com a vida útil de 5 anos da tabela `A130`. É a melhor confirmação de que os
    R$ 5,7 mi eram erro de fórmula, não decisão de investimento.
- **A2.** `AM10` soma o CUB (R$ 2.163,98/m²) como se fosse investimento.
- **A3.** `K24` = 260 no lugar de 12 — rotação de fornecedor copiada da linha de estoque.
- **A4.** Volume vendido (`G23:G33`, digitado) e volume produzido (`Y15:Y24`, calculado)
  divergem ~10% e ninguém amarra os dois. Vender mais do que se produz, todo ano, sem estoque.
- **A5.** Defasagem de um ano entre a aba de produção (linha 2023) e o P&L (ano 2024).
- **A6.** Payback digitado como texto ("2,5 anos"), não calculado.
- **A7.** Sem valor terminal — o VPL trunca uma operação perpétua em 10 anos.
- **A8.** Nenhuma dívida no modelo: não há como haver WACC sem antes decidir a estrutura
  de capital. O modelo novo precisa declarar essa escolha, não herdá-la.

---

## 5. O que o modelo novo herda como premissa (sem recalcular)

Estes números vêm da engenharia e entram como **input**, com a aba de origem citada:

| Premissa | Valor ano 1 | Origem |
|---|---|---|
| Unidades produzidas/ano | 1.244.035 → 3.079.476 (10 anos) | `7. Massas iniciais...!R122:R131` |
| Unidades vendidas/ano | 1.368.200 → 3.079.331 | `3. Projeção...!G23:G32` |
| Custo variável total | R$ 13.924.616 | `20. Custos Unitários!K3` |
| Custo fixo caixa (sem depreciação) | R$ 4.273.811 | `20. Custos Unitários!U3 − P3` |
| CAPEX ano 0 | R$ 17.112.602 | `Demanda...!AA46` |
| Reinvestimentos | 161.000 / 5.745.001 / 338.100 | `Demanda...!AA50, AA51, AA53` |
| Terreno (não depreciável) | R$ 908.612 | `Demanda...!AM6` |
| Construção civil | R$ 12.472.315 | `Demanda...!AM5` |
| Dias de produção/ano | 200 | `22.1 Capital de Giro!C2` |
| Prazos de giro | 30 d estoque / 30 d clientes / 30 d fornecedores | `22.1 Capital de Giro!D:J` |

