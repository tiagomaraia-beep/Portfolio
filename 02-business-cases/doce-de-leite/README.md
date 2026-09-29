# Business case FP&A — planta de doce de leite

Peça de portfólio. Um projeto de conclusão de Engenharia de Alimentos (UNICAMP) relido como
caso de investimento no padrão que um FP&A entrega.

```
README.md                                       <- este arquivo
modelo/
  business-case-fpa-planta-alimentos.xlsx       <- o modelo novo. 10 abas.
docs/
  leitura-da-origem.md                          <- auditoria da planilha de origem, aba por aba, célula por célula
  gaps-e-decisoes.md                            <- os 8 gaps, as decisões de modelagem e o que ficou (confirmar)
```

A planilha original da faculdade (27 abas, trabalho em grupo) não é publicada aqui; a auditoria dela está em `docs/leitura-da-origem.md`.

---

## O caso em uma tela

Planta de doce de leite em embalagem de 600 g, 10 anos (2024–2033), CAPEX de R$ 17,1 mi
no ano 0, distribuição nacional com 80% do volume no Sudeste.

| Indicador | Cenário base |
|---|---|
| WACC | 18,2% *(placeholder — ver `(confirmar)`)* |
| VPL @ WACC, sem valor terminal | R$ 40,9 mi |
| VPL @ Selic 12,25% (critério da origem) | R$ 63,4 mi |
| **Diferença — o preço de descontar pela Selic** | **R$ 22,5 mi** |
| TIR | 47,7% |
| Payback simples / descontado | 2,7 anos / 3,7 anos |
| Índice de lucratividade | 2,91x |
| EBITDA ano 1 → ano 10 | R$ 10,4 mi → R$ 53,6 mi |
| Margem EBITDA ano 1 → ano 10 | 34,9% → 55,8% |
| Margem de segurança sobre o ponto de equilíbrio, ano 1 | 64,7% |
| Checks de amarração | **19 de 19 OK** |

A ponte que liga a planilha de faculdade a este modelo:

```
VPL da origem                                        66.467.823
(1) reconstruir o fluxo de caixa                     (3.071.505)
(2) trocar a Selic pelo WACC                        (22.510.607)
VPL do modelo @ WACC                                 40.885.711
```

---

## As 10 abas

| Aba | O que tem |
|---|---|
| **1. Capa** | Sumário executivo, indicadores, o que foi corrigido, índice, premissas a confirmar. |
| **2. Inputs** | Toda premissa do modelo, com a célula de origem citada. Seletor de cenário em `C5`. Modo de precificação no bloco C. |
| **3. Depreciacao** | Registro de ativos por classe e vida útil, cronograma linear, e o diagnóstico dos quatro defeitos da origem com o antes/depois. |
| **4. DRE** | Resultado em formato FP&A, margem em cada linha, e a memória por unidade que alimenta a ponte. |
| **5. Fluxo de Caixa** | Capital de giro reconstruído, fluxo de caixa livre, e a comparação linha a linha com o fluxo da origem. |
| **6. Valuation** | Construção do WACC, VPL, TIR, payback calculado, três visões de valor terminal e a ponte de VPL contra a origem. |
| **7. Cenarios e Sensibilidade** | Três cenários, tornado de cinco alavancas, sensibilidade ao custo de capital, tabela WACC × g, ponto de equilíbrio e leitura de risco. |
| **8. Motor de Cenarios** | Camada de cálculo: 13 corridas do modelo inteiro. Não editar — as alavancas ficam na aba 2. |
| **9. Ponte EBITDA** | Volume × preço × mix × custo variável × custo fixo, ano a ano, fechando exatamente, com comentário de gestor. |
| **10. Checks** | 19 amarrações. Se alguma sair de `OK`, o modelo não sai da gaveta. |

Camadas separadas: **Inputs (2) → Cálculo (3, 8) → Output (4, 5, 6, 7, 9) → Verificação (10)**.

---

## Como mexer

**Trocar de cenário:** aba `2. Inputs`, célula `C5` — `1` pessimista, `2` base, `3` otimista.
O modelo inteiro, incluindo VPL, TIR e ponto de equilíbrio, responde ao seletor. As cinco
alavancas ficam no bloco I da mesma aba: volume, margem-alvo, custo variável unitário,
contingência e participação do Sudeste.

**Trocar o modo de precificação:** bloco C da aba `2. Inputs`. `1` = custo + markup, a lógica
da origem. `2` = preço de mercado fixo, uma linha de preço por ano. A diferença importa: no
modo 1 o preço sobe junto com o custo, então **custo mais alto gera VPL mais alto**. É o
comportamento do modelo, não do negócio — e é um dos achados da leitura.

**Trocar a taxa de desconto:** bloco H da aba `2. Inputs`. As células em amarelo são
placeholders sem fonte e precisam ser substituídas antes de qualquer apresentação.

**Não editar** a aba `8. Motor de Cenarios`: é cálculo puro, dirigido pela aba 2.

---

## Convenções

- **Cor**: azul = input · preto = fórmula · verde = link de outra aba · amarelo = premissa a confirmar
  (e também o seletor de cenário e o de modo de precificação, as duas células onde se mexe).
  Exceção: a aba `8. Motor de Cenarios` fica toda em preto — é camada de cálculo, onde quase
  toda célula é link, e pintá-la de verde seria ruído.
- **Sinal**: despesa negativa em toda a DRE e no fluxo de caixa. Totais são somas, não subtrações.
- **Uma fórmula por linha**, arrastada na horizontal. Nenhuma célula com lógica própria no meio de uma linha.
- **Nenhuma premissa dentro de fórmula.** Toda constante do modelo tem célula, rótulo, unidade e fonte citada.
- **Coluna C = ano 0 (2023)**; colunas D a M = anos 1 a 10 (2024 a 2033), em todas as abas.
- **Coluna O** de cada aba de cálculo traz a fonte ou a observação da linha.

### Sobre as fórmulas estarem em inglês no arquivo

O formato `.xlsx` **sempre** grava nome de função em inglês, com vírgula como separador —
é o Excel que traduz na exibição. Abrindo este arquivo num Excel em português, `SUMIFS`
aparece como `SOMASES`, `IFERROR` como `SEERRO`, `INDEX`/`MATCH` como `ÍNDICE`/`CORRESP`,
e os separadores viram ponto e vírgula, sozinhos. Nada a fazer.

Uma exceção deliberada: **não há `PROCX` (XLOOKUP) no arquivo**, e sim `ÍNDICE`+`CORRESP`.
`PROCX` é uma função de matriz dinâmica; um arquivo gerado por script não carrega os
metadados de derramamento que ela precisa, e ela falharia em qualquer leitor que não seja
o Excel moderno. `ÍNDICE`+`CORRESP` faz o mesmo trabalho e abre em qualquer lugar.

---

## Como reconstruir o `.xlsx`

O modelo foi gerado por script e é reprodutível. Os scripts de construção não fazem parte da
entrega — o `.xlsx` é a entrega. Se for preciso regerar, a ordem é: Inputs → Depreciação →
DRE → Fluxo de Caixa → Valuation → Motor de Cenários → Cenários → Ponte → Checks → Capa.

Verificação usada: a biblioteca `formulas` (Python) recalcula as 4.650 fórmulas do arquivo
e confirma **zero erros** nas seis combinações de cenário × modo de precificação, com os
19 checks em `OK` em todas elas. O arquivo é gravado com `fullCalcOnLoad`, então o Excel
recalcula tudo ao abrir — sem isso, um arquivo gerado por script abre zerado.

---

## Compliance

Todo dado deste modelo vem do projeto acadêmico do autor. Nenhum dado, cliente, valor ou
estrutura de projeto profissional entra neste arquivo.
