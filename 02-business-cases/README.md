# Business cases — análise de investimento

Três decisões de investimento modeladas no padrão de FP&A: premissas isoladas, cenários, sensibilidade e uma recomendação. Cada PDF segue a mesma estrutura: **projeto · modelagem · análise · resultado · conclusão**.

| Caso | Pergunta | Arquivo |
|---|---|---|
| Planta de doce de leite | Vale construir a fábrica? E quanto a escolha da taxa de desconto muda a resposta? | [PDF](01-doce-de-leite-analise-de-investimento.pdf) · [modelo e documentação](doce-de-leite/) |
| Compra de estacionamento | Comprar o terreno ou alugar? E em que regime tributário? | [PDF](02-compra-de-estacionamento-analise-de-investimento.pdf) |
| Locação de veículos | Qual frota e qual ocupação sustentam a operação em 3 anos, e em que regime tributário? | [PDF](03-locacao-de-veiculos-analise-de-investimento.pdf) |

**Como os modelos foram construídos e validados:** com agentes de IA financeiros — um agente de modelagem em Excel para a estrutura e um agente de validação que recalcula o arquivo avaliando as fórmulas, e não os valores em cache. No caso da fábrica, a validação encontrou erros de depreciação e do método de payback descontado; o modelo final fecha 19 de 19 checagens de amarração.

**Sobre os valores:** no caso do estacionamento, os valores monetários estão indexados (investimento inicial do cenário de aluguel = 100). Percentuais, prazos e índices são os do modelo.
