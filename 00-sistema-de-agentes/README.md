# Sistema de agentes de IA para análise financeira

Oito agentes de IA que modelam, validam e documentam análises de finanças, dados e produto. A memória é uma wiki em Obsidian com mais de 100 páginas interligadas. Quem decide sou eu: a decisão é o entregável, não a planilha.

O sistema em si não é público, porque a wiki guarda também a minha vida pessoal. Esta página mostra o padrão e o que ele produziu.

## Arquitetura

- **Duas classes de agente.** Os *agendados* acordam sozinhos, leem o que têm para fazer, fazem e anotam o resultado: busca de vaga, manutenção da wiki e desenvolvimento de produto. Os *sob demanda* são chamados pelo assunto do pedido, um por ferramenta: Excel, SQL, Python e Power BI.
- **Memória fora do modelo.** O agente não lembra de nada entre uma execução e outra. Cada um tem quatro arquivos: *briefing* (escopo e limites), *fila* (o que fazer), *diário* (o que foi feito) e *aprendizados* (regras descobertas na prática, que passam a valer na execução seguinte). O conhecimento de domínio fica na wiki, com a fonte de cada fato.
- **Prompt fino, wiki grossa.** O prompt de cada agente só diz onde ler. Para mudar o comportamento, edita-se o briefing.
- **Portão humano.** Nenhum agente envia, publica ou se candidata a nada. O que sairia do sistema vira rascunho e espera aprovação.
- **Validação independente.** O agente que modela não é o que valida. A validação recalcula o arquivo pelas fórmulas e confere cada amarração, em vez de confiar no valor que a planilha exibe.
- **Custo como restrição de desenho.** No máximo três tarefas por execução, e um dia sem nada relevante termina com uma linha no diário.

## O que ele produziu

| Caso | O que os agentes fizeram | A decisão |
|---|---|---|
| [Fábrica de doce de leite](../02-business-cases/) | Remodelagem em padrão FP&A, 19 checks de amarração, WACC no lugar da Selic | Investir, com VPL 35,5% menor que o original |
| [Compra de estacionamento](../02-business-cases/) | Regime tributário ano a ano, risco de renovação do contrato, preço máximo do ponto | Comprar o ponto e o terreno, porque o contrato vence em 2 anos; validar a receita antes de negociar |
| [Locação de veículos](../02-business-cases/) | Modelo de 5 anos com revenda da frota, Simples mês a mês e economia por carro | Investir, desde que o ticket se confirme: a folga é de 7% na receita por carro |
| [Pricing de catálogo](../01-pricing-analytics/) | Dois agentes em contrato (SQL → Power BI), 66 medidas DAX | O preço subiu por mix no topo, não por reprecificação |
| Campanha segmentada | Diagnóstico de extrapolação e nova alocação por receita esperada | Suéter para 95 clientes e teste A/B da oferta premium |
| [Agentes para compliance](../03-agentes-ia-financial-services/) | Dois agentes para comunicação de atividade suspeita | Uma pessoa aprova entre a análise e a redação |
| [Facility Digital](../04-facility-digital/) | Construção de um sistema de gestão de estacionamentos | Decisões de produto, documentadas por marco |

## O que a validação encontrou

Em três business cases e numa análise de dados, a validação automatizada achou erros que uma revisão visual não pegou:

- depreciação calculada errado;
- valor por veículo em R$ 150 em vez de R$ 150 mil, com retorno aparente de 2.731%;
- payback deslocado em um ano por um erro de índice;
- uma premissa que nenhuma fórmula lia;
- uma regressão estimada em médias estaduais e aplicada a clientes individuais.

Em dois casos, a recomendação mudou. Em todos, a decisão foi minha.

## O que ele não é

Não é engenharia de machine learning. O trabalho foi desenhar e operar o sistema: orquestração, memória persistente, portão humano, auditabilidade e custo por chamada.
