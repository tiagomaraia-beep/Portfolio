# Business cases — análise de investimento

**Três decisões de investimento modeladas em padrão FP&A.** Cada uma responde a uma pergunta de
dono: vale investir, sob quais condições, e o que precisa ser verdade para a resposta mudar. Cada
PDF segue a mesma estrutura — **projeto · modelagem · análise · resultado · conclusão** — e termina
declarando o que o modelo **não** sustenta.

> **Sobre os valores:** o caso do estacionamento envolve uma negociação real, então os valores
> monetários estão **indexados** — o investimento inicial do cenário de aluguel vale 100.
> Percentuais, prazos, razões e índices são os do modelo. Nos outros dois, os valores são os reais.

---

## As três decisões

**1. A planta de doce de leite vale ser construída — com um terço menos de folga do que a origem dizia.**
VPL de R$ 40,9 mi, TIR de 47,7%, payback descontado de 3,7 anos. O número da origem era R$ 66,5 mi,
e a diferença não é detalhe de cálculo: **R$ 22,5 mi vinham de descontar o fluxo pela Selic**, sem
nenhum prêmio de risco. A ponte separa as duas parcelas:

```
VPL da origem                                 66,5 mi
(1) reconstruir o fluxo de caixa              (3,1 mi)
(2) trocar a Selic pelo WACC de 18,2%        (22,5 mi)
VPL do modelo                                 40,9 mi
```

O projeto continua aprovado. O que muda é a honestidade do número: **35,5% do VPL original era
remuneração de risco que ninguém estava cobrando.**

**2. No estacionamento, comprar o terreno — e a razão é o contrato, não o imóvel.**
Faltam **2 anos** de locação. Com o terreno alugado, o valor do negócio passa a depender de um
desfecho que não está nas mãos do comprador: renovar a preço de mercado vale 976, não renovar vale
158, e o valor esperado a 50% de chance cai para 567 — contra **968 comprando**. Comprar vence até
com o terreno valendo zero no ano 10, com qualquer aluguel de renovação e com custo de capital
entre 8% e 30% ao ano. Só se inverte com renovação praticamente certa: **acima de 97% de
probabilidade**, ou seja, contrato novo assinado antes do fechamento.

E um achado que vale mais que a escolha entre os dois cenários: **o preço pedido é baixo demais
para as premissas.** Equivale a 0,63 vez o fluxo de caixa do primeiro ano, e os dois anos
garantidos de contrato já geram 3,3 vezes esse valor. Bastariam **32% de ocupação** para justificar
o preço no pior desfecho, contra os 80% informados pelo operador. Ou a receita está superestimada,
ou há algo fora do modelo — e é isso que se valida antes de negociar, não depois.

**3. A locadora cria valor, mas a folga é de 7%.**
VPL de R$ 119 mil a 14,5% a.a., TIR de 17,9%, índice de lucratividade de 1,09. O projeto fica de pé
por pouco, e o que decide é a receita por carro: **uma queda de 7,2% no ticket ou na ocupação zera
todo o valor criado.** Cada R$ 100 por semana de ticket move o VPL em R$ 110 mil.

A revenda da frota, ao contrário, tem folga larga — aguenta cair de 60% para 41,7% do valor de
compra. Mas é ela que carrega o projeto: sem a venda no ano 5, o VPL seria **negativo em R$ 285
mil**. A recomendação é investir **com uma condição**: cotar o ticket semanal de mercado antes de
comprometer R$ 1,5 milhão em frota.

---

## O que a validação encontrou

Os três modelos foram verificados por recálculo — as fórmulas são reavaliadas uma a uma, em vez de
se confiar no valor que a planilha exibe. **Em dois dos três casos, o que apareceu mudou a
recomendação.**

| Caso | O que a validação pegou | Efeito |
|---|---|---|
| Doce de leite | Depreciação calculada errado e payback descontado pelo método errado | Corrigidos; a ponte de VPL passou a fechar |
| Estacionamento | Payback somava um ano a mais, por um índice deslocado no `CORRESP` | Indicador corrigido |
| Estacionamento | O comparativo tributário omitia o ISS fora do DAS, o adicional de IRPJ e a saída do Simples no ano 4 | O Simples deixou de ser o regime mais barato |
| Estacionamento | **O prazo do contrato de locação não estava no modelo** | **A recomendação passou de alugar para comprar** |
| Locação | Valor por veículo em **R$ 150**, não R$ 150 mil — retorno aparente de **2.731%** | Sem a correção, os indicadores de retorno eram inutilizáveis |
| Locação | A premissa de frota máxima não era lida por nenhuma fórmula | Célula morta que parecia governar o modelo |

Os dois últimos são do tipo que uma revisão visual não pega: o primeiro porque 2.731% parece
empolgante em vez de suspeito, e o segundo porque a célula está lá, preenchida, com rótulo.

---

## Os três casos

| Caso | Pergunta | Resposta | Material |
|---|---|---|---|
| **Planta de doce de leite** | Vale construir a fábrica? E quanto a taxa de desconto muda a resposta? | Investir. VPL de R$ 40,9 mi ao WACC de 18,2% — R$ 22,5 mi abaixo do número descontado pela Selic | [PDF](01-doce-de-leite-analise-de-investimento.pdf) · [modelo e documentação](doce-de-leite/) |
| **Aquisição de estacionamento** | Comprar só o ponto e alugar o terreno, ou comprar os dois, com 2 anos restantes de contrato? | Comprar os dois: VPL 968 contra 567 esperado. E validar a receita antes de negociar | [PDF](02-compra-de-estacionamento-analise-de-investimento.pdf) |
| **Locação de veículos** | Vale investir numa frota de 10 carros, e quanto a receita por carro pode cair? | Investir, com condição. VPL de R$ 119 mil, com 7,2% de folga no ticket e na ocupação | [PDF](03-locacao-de-veiculos-analise-de-investimento.pdf) |

O modelo completo da planta de doce de leite está publicado em [`doce-de-leite/`](doce-de-leite/),
com a auditoria da planilha de origem e as decisões de modelagem. Os outros dois envolvem dados de
negociação e estão representados pelos PDFs.

---

## Como foi feito

A modelagem e a validação foram divididas entre dois agentes do
[meu sistema](../00-sistema-de-agentes/), em papéis separados de propósito: **um constrói o modelo
em Excel, o outro o recalcula pelas fórmulas e confere cada amarração.** Quem modela não é quem
valida — pela mesma razão que ninguém confere o próprio fechamento. Eu defino a pergunta, as
premissas e o que conta como decisão; a recomendação é minha.

As amarrações são o critério de pronto: **19 checks** na planta de doce de leite, com as 4.650
fórmulas recalculadas em todas as combinações de cenário; **22** no estacionamento; **23** na
locação. Se um check sai de `OK`, o modelo não vira PDF.

---

## O que estes modelos não respondem

Em voz alta, porque é o que separa a leitura sênior da ingênua:

- **O WACC da planta é estrutura, não cotação.** O modelo constrói `Ke = Rf + β × ERP` e
  `WACC = Ke × E/V + Kd × (1−t) × D/V`, mas o prêmio de risco, o beta e o D/E são **placeholders
  marcados em amarelo**, sem fonte. A conclusão de que a Selic subavalia o risco não depende deles;
  o valor exato do VPL, sim.
- **A tributação não passou por contador.** Os regimes foram modelados com a regra e a base legal
  citadas — Anexo III do Simples e Súmula Vinculante 31 do STF na locação; regime ano a ano e ISS
  fora do DAS no estacionamento — e as premissas adotadas estão declaradas em cada PDF. Não
  substituem parecer.
- **A receita do estacionamento é informada pelo operador**, não auditada. É a premissa que mais
  move o resultado, e o próprio PDF diz que validá-la contra o histórico é o passo seguinte.
- **No modo custo + markup da planta, custo mais alto produz VPL mais alto**, porque o preço é
  derivado do custo. É comportamento do modelo, não do negócio — por isso existe o modo de preço de
  mercado, e por isso o achado está documentado em vez de escondido.
- **Nada aqui é recomendação de investimento.** São exercícios de modelagem sobre um projeto
  acadêmico e dois projetos próprios.

---

## Como ler

- **Recrutador com 90 segundos:** as três decisões acima.
- **Gestor de FP&A:** o [PDF da planta](01-doce-de-leite-analise-de-investimento.pdf), pela ponte de
  VPL — é onde a diferença entre um número e um número defensável cabe em três linhas.
- **Quem quer ver a estrutura do modelo:** [`doce-de-leite/`](doce-de-leite/) para as dez abas e as
  convenções, [`docs/leitura-da-origem.md`](doce-de-leite/docs/leitura-da-origem.md) para a
  auditoria da planilha de origem célula por célula, e
  [`docs/gaps-e-decisoes.md`](doce-de-leite/docs/gaps-e-decisoes.md) para os oito gaps fechados e o
  que ficou em aberto.
