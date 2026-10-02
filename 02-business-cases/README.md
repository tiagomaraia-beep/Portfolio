# Business cases — análise de investimento

Três decisões de investimento modeladas no padrão de FP&A: premissas isoladas, cenários, sensibilidade e uma recomendação. Cada PDF segue a mesma estrutura: **projeto · modelagem · análise · resultado · conclusão**.

| Caso | Pergunta | Arquivo |
|---|---|---|
| Planta de doce de leite | Vale construir a fábrica? E quanto a escolha da taxa de desconto muda a resposta? | [PDF](01-doce-de-leite-analise-de-investimento.pdf) · [modelo e documentação](doce-de-leite/) |
| Compra de estacionamento | Comprar só o ponto e alugar o terreno, ou comprar os dois, com 2 anos restantes de contrato de locação? | [PDF](02-compra-de-estacionamento-analise-de-investimento.pdf) |
| Locação de veículos | Vale investir numa frota de 10 carros, e quanto a receita por carro pode cair antes de o VPL zerar? | [PDF](03-locacao-de-veiculos-analise-de-investimento.pdf) |

**Como os modelos foram construídos e validados:** com agentes de IA financeiros — um agente de modelagem em Excel para a estrutura e um agente de validação que recalcula o arquivo avaliando as fórmulas, e não os valores em cache. A validação encontrou, na fábrica, erros de depreciação e do método de payback descontado; na locação, o valor por veículo em R$ 150 em vez de R$ 150 mil; no estacionamento, um payback deslocado em um ano e um comparativo tributário incompleto. No estacionamento, incluir o prazo do contrato de locação inverteu a recomendação.

**Sobre os valores:** no caso do estacionamento, os valores monetários estão indexados (investimento inicial do cenário de aluguel = 100). Percentuais, prazos e índices são os do modelo.
