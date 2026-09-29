# Sumário executivo — uma página

**O que foi analisado.** 18.457 produtos de catálogo lançados entre 1970 e 2022, com preço
de tabela de lançamento no varejo dos EUA. Toda afirmação sobre preço sai de um escopo
declarado: **4.626 produtos** (2007–2022, com preço informado, 20 peças ou mais,
excluindo merchandise) — 25,1% do catálogo, e o único pedaço em que a fonte sustenta
afirmação. Mix e cobertura rodam sobre as 18.457 linhas.

> **Base de preço:** duas unidades, sempre declaradas. **Nominal** = dólar corrente do ano
> de lançamento. **Real** = dólares constantes de 2022, deflacionado pelo CPI-U (BLS,
> `CUUR0000SA0`). A escolha muda o sinal da conclusão, não só a magnitude.

---

## A resposta em uma frase

**O produto não foi reprecificado. Foi recomposto.** O preço unitário caiu em poder de
compra, o produto ficou maior, e o portfólio ganhou uma cauda cara no topo — sem que a
tabela de preços percebida mudasse.

---

## Os três achados

**1 · O tijolo ficou 26% mais barato; o set ficou 68% maior.**
Preço por peça, 2007 → 2022: **+3,9% nominal**, **−26,4% real**. No mesmo período o set
médio ganhou 68,3% de peças e subiu **+23,8% real** (contra +74,8% nominal). Metade do
"aumento de preço" que aparece em dólar corrente é apenas inflação. A divergência aperta a
partir de 2017: o preço por peça real cai 18% enquanto o ticket médio real sobe 21%.
**Isso é ticket médio via tamanho, não via preço unitário.**

**2 · O prêmio de licença é ruído: +0,4% por peça.**
O produto licenciado custa 18,7% mais caro porque tem 18,2% mais peças. Onde a licença se
paga é em conteúdo: **+47% de densidade de minifigura** (5,97 contra 4,06 por mil peças,
2018–2022) e presença no topo da escada. Dois recortes enganam e foram testados: o
"desconto" de −36,4% nos produtos pequenos é composição de linha pré-escolar (peça
fisicamente maior, não pricing); o "prêmio" de +22,9% nos grandes é a linha adulta
própria, densa em peça barata, derrubando o denominador do outro lado.

**3 · A escada de preços subiu na etiqueta e ficou parada no bolso.**
Fatia do catálogo acima de US$ 50: **17,7% → 37,8% nominal**, mas **38,6% → 37,8% real**.
A mediana real **cai 5,5%** enquanto a média real sobe 23,8% — a distância entre as duas é
a cauda superior engordando. E a disciplina de ponto de preço **aumentou**: 98,8% dos
preços terminam em `.99` (96,9% nos anos 2000 contra 99,5% nos 2010), com apenas 141
pontos de preço distintos em todo o catálogo.

---

## De uma olhada — 2007 → 2022, escopo de preço

| Indicador | Nominal | **Real (USD 2022)** |
|---|---|---|
| Preço por peça | +3,9% | **−26,4%** |
| Preço médio por produto | +74,8% | **+23,8%** |
| **Mediana** de preço | +33,3% | **−5,5%** |
| Fatia acima de US$ 50 | 17,7% → 37,8% | **38,6% → 37,8%** |
| Peças por produto | +68,3% | +68,3% *(não deflaciona)* |
| Preços terminados em `.99` | 98,8% | — *(o `.99` só existe em dólar corrente)* |

**Qual base usar, para quê.** *Arquitetura de preço e ponto psicológico* → a **nominal**;
ninguém deflaciona uma etiqueta. *Ficou mais caro para quem compra?* → a **real**. E a
resposta é: o produto típico, não; o topo da linha, sim.

---

## O que isso significa para quem faz preço

1. **Crescimento de ticket sem reprecificação é possível — e é o que aconteceu aqui.**
   Quinze anos de aumento de receita por unidade vendida sem tocar na tabela percebida,
   inteiramente por composição de produto. É uma alavanca que raramente aparece em
   discussão de preço porque não passa por uma decisão de preço.
2. **Ponto de preço rígido é um ativo, não uma limitação.** Os 141 pontos distintos e o
   `.99` quase universal significam que a empresa nunca precisou pedir ao cliente que
   reaprendesse a tabela. A recomposição de portfólio foi o instrumento.
3. **A cauda de cima é onde o valor foi capturado.** Média real sobe, mediana real cai:
   crescimento concentrado no topo, não distribuído. Isso é uma tese de mix a validar com
   dado de volume — que este dataset não tem.
4. **O prêmio de marca não está na etiqueta do licenciamento.** Está em tamanho e em
   conteúdo. Cobrar prêmio por licença no preço unitário seria visível e comparável; o
   caminho escolhido não é.

---

## Os limites, sem os quais nada acima vale

- **É preço de tabela, não preço praticado.** Sem desconto, promoção, volume, margem ou
  custo. **Nada aqui é afirmação sobre receita ou rentabilidade.**
- **Não há preço antes de 2007** — cobertura de 0% nos anos 70 e 80. As décadas antigas
  são analisáveis só em volume e mix.
- **"Peça" não é unidade homogênea.** Uma peça pré-escolar não é uma peça padrão; todo
  corte de preço por peça entre linhas de produto precisa controlar isso, e os que
  aparecem aqui controlam.
- **A comparação com o índice de brinquedos indica direção, não magnitude.** Ela sugere
  que a marca se posicionou acima da categoria; ela **não** sustenta "ficou 147% mais cara
  que os concorrentes", porque o índice do BLS é ajustado hedonicamente e dominado por
  eletrônico. A ressalva completa está em `qualidade-do-dado.md` seção 11.
- **Só mercado EUA.**

A lista completa, com os vieses medidos e as coberturas ano a ano, está em
[`qualidade-do-dado.md`](qualidade-do-dado.md).

---

**Mais fundo:** [`achados.md`](achados.md) (as cinco perguntas, com as tabelas completas) ·
[`modelo-powerbi.md`](modelo-powerbi.md) (o modelo dimensional e o porquê de cada decisão) ·
[`dashboard-spec.md`](dashboard-spec.md) (as oito páginas do relatório).
