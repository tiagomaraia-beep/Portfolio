# Arquitetura do sistema de agentes

Sete agentes, duas classes, uma memória. Três fluxogramas do desenho que está rodando —
estado de 7 de outubro de 2026.

| | |
|---|---|
| Agendados (acordam sozinhos) | 3 — `bibliotecario` 22:00 · `carreira` seg–sex 08:00 · `manobrista` 07:00 |
| Sob demanda (chamados pelo assunto) | 4 — `sql-analytics` · `python-analytics` · `powerbi-modelagem` · `excel-modelagem` |
| Onde rodam | 1 como rotina na nuvem, 2 como tarefa local do Claude Code |
| Memória | um vault Obsidian, com briefing, fila, diário e aprendizados por agente |

## 1. O cérebro: o vault como memória, e o bibliotecario que o mantém

O modelo não lembra de nada entre uma execução e outra. O que faz o sistema ter memória é o vault — e o que impede o vault de apodrecer é um agente dedicado só a ele.

```mermaid
flowchart TB
  TIAGO["Tiago"]
  FORA["Web e APIs"]
  RAW[("raw/ · fontes brutas")]

  subgraph VAULT["Vault Maraia — a memória"]
    direction TB
    SCHEMA["CLAUDE.md · as regras"]
    WIKI["wiki/ · o conhecimento"]
    IDX["index.md · o catálogo"]
    LOG["log.md · o histórico"]
  end

  subgraph SESSAO["Qualquer sessão do Claude"]
    direction TB
    S1["1 · lê o índice"]
    S2["2 · abre as páginas"]
    S3["3 · trabalha"]
    S4["4 · escreve de volta"]
    S1 --> S2 --> S3 --> S4
  end

  BIB["bibliotecario · 22:00"]
  LINT{"lint do vault"}
  MEC["conserta"]
  PERG["pergunta na fila"]
  REP["repasse na agenda"]
  FONTES["wiki/fontes/"]

  TIAGO -->|fato novo| SESSAO
  FORA -->|pesquisa| SESSAO
  S1 -.->|lê| IDX
  S2 -.->|lê| WIKI
  SCHEMA -.->|rege a escrita| S4
  S4 -->|atualiza| WIKI
  S4 -->|acrescenta| LOG
  S4 -->|sincroniza| IDX

  RAW -->|ingest| BIB
  BIB -->|cria página| FONTES
  FONTES --> WIKI
  BIB --> LINT
  LINT -->|mecânico| MEC
  LINT -->|julgamento| PERG
  LINT -->|outro escopo| REP
  MEC -->|corrige| WIKI
```

- `raw/` guarda as fontes brutas e é imutável: ler sempre, editar nunca.
- O passo 4 escreve com frontmatter, `atualizado:` e `fontes:`, preservando contradições.
- O lint procura link quebrado, página órfã, frontmatter faltando, nome duplicado e resumo desatualizado.

## 2. O agente agendado: cinco passos, sempre os mesmos

O prompt da tarefa é fino de propósito: só manda ler o protocolo. A inteligência mora no vault, então mudar comportamento é editar um arquivo, não reconfigurar a tarefa.

```mermaid
flowchart TB
  NUVEM["Rotina na nuvem"]
  LOCAL["Tarefa local no Mac"]
  PROMPT["Prompt fino"]

  subgraph LER["1 · LER, nesta ordem"]
    direction TB
    A["protocolo"]
    B["briefing"]
    C["aprendizados"]
    D["fila"]
    E["diário"]
    F["páginas da wiki"]
    A --> B --> C --> D --> E --> F
  end

  P2{"2 · PLANEJAR"}
  NADA["encerra com uma linha"]
  P3["3 · FAZER"]
  PORTAO{"vai sair do vault?"}
  RASC["vira rascunho"]

  subgraph ESCREVER["4 · ESCREVER, nesta ordem"]
    direction TB
    W1["wiki/"]
    W2["fila"]
    W3["aprendizados"]
    W4["diário"]
    W5["agenda"]
    W6["log e index"]
    W1 --> W2 --> W3 --> W4 --> W5 --> W6
  end

  P5["5 · FECHAR"]

  NUVEM -->|bibliotecario| PROMPT
  LOCAL -->|carreira e manobrista| PROMPT
  PROMPT -->|leia o protocolo| LER
  LER --> P2
  P2 -->|até 3 tarefas| P3
  P2 -->|nada útil hoje| NADA
  P3 --> PORTAO
  PORTAO -->|sim| RASC
  PORTAO -->|não| ESCREVER
  RASC -->|espera o Tiago| ESCREVER
  ESCREVER --> P5
  NADA --> P5
```

- Planejar é no máximo 3 tarefas: uma recorrente e até duas do backlog, pulando o que espera resposta do Tiago.
- As tarefas locais só disparam com o app Claude aberto; se o Mac estiver desligado, a execução acontece na abertura seguinte.
- Fechar atualiza o artefato-retrato do agente em toda execução, resume em 3 linhas e só notifica se houver decisão a tomar.

## 3. Os subagentes em stand-by: chamados pelo assunto, não pelo relógio

Os quatro agentes de dados não têm agendamento e não consomem nada sozinhos. Ficam parados até um pedido cair no escopo deles.

```mermaid
flowchart TB
  PEDIDO["Pedido do Tiago"]
  ORQ{"Roteia pelo assunto"}
  ROT[("~/.claude/agents/ · roteador fino")]

  SQL["sql-analytics"]
  PY["python-analytics"]
  BI["powerbi-modelagem"]
  XL["excel-modelagem"]

  BRIEF[("briefing no vault")]
  STACK[("stack-de-dados")]
  ENTREGA["código + leitura de negócio"]
  PROP{"muda o vault?"}
  PROPOE["propõe; ele registra"]
  FIM["encerra na sessão"]

  PEDIDO --> ORQ
  ROT -.->|dispara| ORQ
  ORQ -->|SQL| SQL
  ORQ -->|Python| PY
  ORQ -->|Power BI| BI
  ORQ -->|Excel| XL
  SQL -.->|lê| BRIEF
  PY -.->|lê| BRIEF
  BI -.->|lê| BRIEF
  XL -.->|lê| BRIEF
  BRIEF -.->|calibra| STACK
  SQL --> ENTREGA
  PY --> ENTREGA
  BI --> ENTREGA
  XL --> ENTREGA
  ENTREGA --> PROP
  PROP -->|sim| PROPOE
  PROP -->|não| FIM
```

- O roteador em `~/.claude/agents/` tem só a descrição que dispara o agente e o caminho do vault; o briefing que vale está no vault.
- Os quatro entregam da mesma forma. A diferença é onde o resultado roda: SQL e Python executam na sessão; Power BI e Excel são aplicativos do Tiago, então a entrega é a medida DAX, a fórmula ou o `.xlsx` pronto.
- Sem agendamento, os quatro não consomem uso sozinhos.

## As regras que valem para todos

1. **Não falam com ninguém pelo Tiago.** O que sairia vira rascunho e espera aprovação.
2. **Não apagam nada.** Corrige-se acrescentando, com as duas versões e datas.
3. **Não inventam.** Fato sem fonte vira `(confirmar)` ou pergunta na fila.
4. **Conteúdo do empregador é sempre genérico** — compliance.
5. **Não mudam o próprio briefing** nem criam agentes novos. Podem propor, na fila.
6. **Não mexem na fila de outro agente** — vira repasse na agenda.
7. **Prompt fino, vault grosso.**
