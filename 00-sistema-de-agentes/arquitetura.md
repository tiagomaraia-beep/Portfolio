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

O modelo não lembra de nada entre uma execução e outra. O que faz o sistema ter memória é o vault — e o que impede o vault de apodrecer é um agente dedicado só a ele. O `bibliotecario` não produz conteúdo sobre a vida do Tiago: conserta, liga e ingere.

```mermaid
flowchart TB
  TIAGO["Tiago<br/>pedido · correção · decisão"]
  FORA["Web e APIs<br/>Gupy · Greenhouse · LinkedIn"]
  RAW[("raw/<br/>fontes brutas<br/>imutável: ler sempre, editar nunca")]

  subgraph VAULT["O cérebro — vault Obsidian Maraia"]
    direction TB
    SCHEMA["CLAUDE.md<br/>schema e convenções de escrita"]
    WIKI["wiki/<br/>projetos · decisões · empresas<br/>pessoas · conceitos · fontes · sínteses"]
    IDX["index.md<br/>catálogo, uma linha por página"]
    LOG["log.md<br/>histórico append-only"]
  end

  subgraph SESSAO["Qualquer sessão do Claude"]
    direction TB
    S1["1 · lê o index.md"]
    S2["2 · abre só as páginas relevantes"]
    S3["3 · trabalha"]
    S4["4 · escreve de volta<br/>frontmatter · atualizado: · fontes:<br/>contradição se registra, não se apaga"]
    S1 --> S2 --> S3 --> S4
  end

  BIB["bibliotecario<br/>diário, 22:00 · rotina na nuvem"]
  LINT{"lint do CLAUDE.md<br/>link quebrado · página órfã<br/>frontmatter faltando · nome duplicado<br/>resumo desatualizado"}
  MEC["conserta o mecânico"]
  PERG["vira pergunta na fila"]
  REP["repasse na agenda<br/>para o agente do assunto"]
  FONTES["wiki/fontes/<br/>uma página por fonte"]

  TIAGO -->|traz fato novo| SESSAO
  FORA -->|pesquisa| SESSAO
  S1 -.->|lê| IDX
  S2 -.->|lê| WIKI
  SCHEMA -.->|rege a escrita| S4
  S4 -->|atualiza| WIKI
  S4 -->|acrescenta| LOG
  S4 -->|sincroniza| IDX

  RAW -->|ingest: toda fonte vira página| BIB
  BIB -->|cria| FONTES
  FONTES --> WIKI
  BIB --> LINT
  LINT -->|mecânico e óbvio| MEC
  LINT -->|exige julgamento| PERG
  LINT -->|fora do meu escopo| REP
  MEC -->|corrige| WIKI
```

- O vault é a única fonte de verdade, e toda escrita passa pelas regras do `CLAUDE.md`.
- O que é mecânico o bibliotecario conserta; o que exige julgamento vira pergunta na fila; o que é de outro domínio vira repasse na agenda.
- Nada é apagado. Contradição se registra com as duas versões e as duas datas.

## 2. O agente agendado: cinco passos, sempre os mesmos

O prompt da tarefa agendada é fino de propósito: ele só manda ler o protocolo. Toda a inteligência mora no vault, então mudar o comportamento de um agente é editar um arquivo — não reconfigurar a tarefa, o que exigiria aprovação no computador.

```mermaid
flowchart TB
  NUVEM["Rotina na nuvem<br/>bibliotecario 22:00"]
  LOCAL["Tarefa local do Claude Code<br/>manobrista 07:00 · carreira seg–sex 08:00<br/>só dispara com o app aberto"]
  PROMPT["Prompt fino<br/>só manda ler o protocolo"]

  subgraph LER["1 · LER, sempre nesta ordem"]
    direction TB
    A["AGENTES.md + CLAUDE.md"]
    B["briefing — quem sou, escopo, limites"]
    C["aprendizados — vale mais que instinto"]
    D["fila — o que fazer"]
    E["últimas 3 entradas do diário"]
    F["páginas da wiki ligadas às tarefas"]
    A --> B --> C --> D --> E --> F
  end

  P2{"2 · PLANEJAR<br/>no máximo 3 tarefas<br/>1 recorrente + até 2 do backlog<br/>pular o que espera resposta"}
  NADA["dia parado é resultado válido<br/>uma linha no diário e encerra"]
  P3["3 · FAZER<br/>dentro do escopo do briefing<br/>pesquisa e leitura são livres"]
  PORTAO{"PORTÃO HUMANO<br/>isto sairia do sistema?"}
  RASC["vira rascunho e espera o Tiago<br/>nada é enviado, publicado<br/>ou candidatado"]

  subgraph ESCREVER["4 · ESCREVER, nesta ordem"]
    direction TB
    W1["páginas da wiki/"]
    W2["fila — fecha, acrescenta, reordena"]
    W3["aprendizados, se aprendeu regra nova"]
    W4["diário — append-only"]
    W5["linha do agente na agenda"]
    W6["log.md + index.md"]
    W1 --> W2 --> W3 --> W4 --> W5 --> W6
  end

  P5["5 · FECHAR<br/>artefato-retrato atualizado sempre<br/>resumo de 3 linhas<br/>notifica só se houver decisão"]

  NUVEM --> PROMPT
  LOCAL --> PROMPT
  PROMPT --> LER
  LER --> P2
  P2 -->|há o que fazer| P3
  P2 -->|nada relevante hoje| NADA
  P3 --> PORTAO
  PORTAO -->|sim| RASC
  PORTAO -->|fica no vault| ESCREVER
  RASC --> ESCREVER
  ESCREVER --> P5
  NADA --> P5
```

- O passo 4 não é opcional: é o que faz o sistema aprender, já que entre duas execuções o agente não lembra de nada.
- O limite de três tarefas e o caminho "dia parado" existem para o agente não inventar trabalho — cada execução consome uso do plano.
- O `manobrista` acrescenta uma regra própria: trabalha por branch e pull request, nunca empurra na `main`. O `carreira` lê o painel de vagas no passo 1 e o republica no passo 5.

## 3. Os subagentes em stand-by: chamados pelo assunto, não pelo relógio

Os quatro agentes de dados não têm agendamento e não consomem nada sozinhos. Ficam parados até um pedido cair no escopo deles — e quem roteia é o assunto do pedido, dentro da sessão em que o Tiago já está trabalhando.

```mermaid
flowchart TB
  PEDIDO["Pedido do Tiago<br/>em qualquer pasta do Mac"]
  ORQ{"Sessão principal<br/>roteia pelo assunto do pedido"}
  ROT[("~/.claude/agents/NOME.md<br/>roteador fino:<br/>só a descrição que dispara<br/>e o caminho do vault")]

  SQL["sql-analytics<br/>query · CTE · window function<br/>qualidade de dado"]
  PY["python-analytics<br/>pandas · ETL · gráfico<br/>automação de relatório"]
  BI["powerbi-modelagem<br/>esquema estrela · DAX<br/>Power Query"]
  XL["excel-modelagem<br/>modelagem financeira<br/>cenários · variância"]

  BRIEF[("vault: agentes/NOME/<br/>briefing · fila · diário · aprendizados")]
  STACK[("stack-de-dados<br/>nível real por ferramenta<br/>calibra o quanto explicar")]

  ENTREGA["Entrega: código ou arquivo<br/>+ leitura de negócio<br/>análise sem leitura não conta"]
  PROP{"Mudança no vault?"}
  PROPOE["propõe ao Tiago<br/>ele registra"]
  FIM["encerra na sessão"]

  PEDIDO --> ORQ
  ROT -.->|dispara o agente| ORQ
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

- A diferença de classe não é de ferramenta, é de autonomia: o agendado escolhe a própria tarefa e escreve no vault; o sob demanda recebe a tarefa pronta — o pedido *é* o plano — e nunca escreve no vault por conta própria.
- Os quatro entregam da mesma forma. A diferença é onde o resultado roda: SQL e Python executam na sessão; Power BI e Excel são aplicativos do Tiago, então a entrega é a medida DAX, a fórmula ou o `.xlsx` pronto para abrir.
- O roteador em `~/.claude/agents/` só aponta; o briefing que vale está no vault.

## As regras que valem para todos

1. **Não falam com ninguém pelo Tiago.** Nenhum envia email, mensagem, candidatura, comentário ou
   publicação. O que sairia do sistema vira rascunho e espera aprovação.
2. **Não apagam nada.** Nem as fontes brutas, nem páginas, nem fatos dentro delas. Corrige-se
   acrescentando, e a contradição fica registrada com as duas versões e datas.
3. **Não inventam.** Fato sem fonte não vira afirmação: vira `(confirmar)` ou pergunta na fila.
4. **Conteúdo do empregador é sempre genérico** — compliance: nenhum cliente, valor, deal ou
   projeto específico entra em arquivo, exemplo ou portfólio.
5. **Não mudam o próprio briefing** nem criam agentes novos. Podem propor, na fila.
6. **Não mexem na fila de outro agente** — o que é de escopo alheio vira repasse na agenda.
7. **Prompt fino, vault grosso.** O prompt externo só diz onde ler, porque mudar o prompt de uma
   rotina exige aprovação e mudar um arquivo do vault não.
