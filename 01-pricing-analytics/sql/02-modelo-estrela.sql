-- Pergunta: como organizar 18.457 linhas planas num modelo que o Power BI consiga medir?
-- Fonte: stg_lego_sets em data/lego.db (carga descrita em sql/01-qualidade-do-dado.sql). Dialeto: SQLite.
--
-- Esquema estrela: uma fato na granularidade de SET (1 linha = 1 set), cinco dimensoes
-- conformadas, chaves substitutas (sk_) inteiras e explicitas em todas elas.
--
-- DECISAO DE MODELAGEM -- por que preco por peca NAO esta na fato:
--   preco por peca e uma RAZAO, e razao nao e aditiva. Se a fato trouxesse uma coluna
--   ppp por linha, qualquer visual do Power BI que agregasse tema ou ano faria
--   AVERAGE(ppp) -- a media das razoes, em que um set de 30 pecas pesa igual a um de
--   7.541. O numero que um analista de pricing quer e a razao dos totais:
--   SUM(vl_preco_usd) / SUM(qt_pecas). Deixar a razao fora da fato forca esse calculo
--   a virar MEDIDA DAX e impede o erro silencioso. A fato carrega so aditivo:
--   vl_preco_usd, qt_pecas, qt_minifigs, qt_sets.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS fato_sets;
DROP TABLE IF EXISTS dim_tema;
DROP TABLE IF EXISTS dim_calendario;
DROP TABLE IF EXISTS dim_categoria;
DROP TABLE IF EXISTS dim_faixa_preco;
DROP TABLE IF EXISTS dim_faixa_etaria;
DROP TABLE IF EXISTS dim_faixa_tamanho;


-- =============================================================================
-- DIM_TEMA  -- grao: tema. 154 linhas. Hierarquia tema -> grupo validada 1:N em 01.
-- =============================================================================
CREATE TABLE dim_tema (
  sk_tema         INTEGER PRIMARY KEY,
  tema            TEXT NOT NULL,
  grupo_tema      TEXT NOT NULL,
  flag_licenciado INTEGER NOT NULL   -- 1 = propriedade intelectual de terceiro
);

INSERT INTO dim_tema (sk_tema, tema, grupo_tema, flag_licenciado)
SELECT
  ROW_NUMBER() OVER (ORDER BY theme),
  theme,
  CASE WHEN TRIM(COALESCE(themeGroup,'')) = '' THEN 'Não informado' ELSE themeGroup END,
  CASE WHEN themeGroup = 'Licensed' THEN 1 ELSE 0 END
FROM (SELECT DISTINCT theme, themeGroup FROM stg_lego_sets);
-- ROW_NUMBER() OVER (ORDER BY theme): gera a chave substituta. ORDER BY theme torna a
-- numeracao deterministica -- recarregar o modelo produz as mesmas sk. Sem PARTITION BY:
-- a numeracao e continua sobre a tabela inteira, nao reinicia por grupo.


-- =============================================================================
-- DIM_CALENDARIO  -- grao: ano. O dataset nao tem data, so ano de lancamento.
-- =============================================================================
--   Carrega tambem o CPI-U e o deflator (fonte: data/cpi_us_anual.csv, BLS). O indice
--   e atributo do ANO, entao mora aqui -- nunca na fato.
CREATE TABLE dim_calendario (
  sk_ano              INTEGER PRIMARY KEY,   -- o proprio ano: chave natural ja inteira
  ano                 INTEGER NOT NULL,
  decada              INTEGER NOT NULL,
  rotulo_decada       TEXT NOT NULL,
  flag_preco_confiavel INTEGER NOT NULL,     -- 1 a partir de 2007 (ver secao 3 de 01)
  cpi_u_media_anual        REAL NOT NULL,    -- CUUR0000SA0, media anual
  fator_deflator_base2022  REAL NOT NULL,    -- CPI-U(2022) / CPI-U(ano); 2022 = 1,0
  cpi_toys_media_anual     REAL,             -- CUUR0000SERE01; NULL antes de 1978
  flag_cpi_toys_disponivel INTEGER NOT NULL  -- 0 nos 8 anos de 1970 a 1977
);

INSERT INTO dim_calendario (sk_ano, ano, decada, rotulo_decada, flag_preco_confiavel,
                            cpi_u_media_anual, fator_deflator_base2022,
                            cpi_toys_media_anual, flag_cpi_toys_disponivel)
SELECT DISTINCT
  CAST(s.year AS INTEGER),
  CAST(s.year AS INTEGER),
  (CAST(s.year AS INTEGER) / 10) * 10,
  -- parenteses obrigatorios: em SQLite o || tem precedencia MAIOR que o *, entao
  -- (ano/10)*10 || 's' seria lido como (ano/10) * ('10s' -> 10) e devolveria 1970,
  -- nao '1970s'. O CAST explicito remove a ambiguidade.
  CAST((CAST(s.year AS INTEGER) / 10) * 10 AS TEXT) || 's',
  CASE WHEN CAST(s.year AS INTEGER) >= 2007 THEN 1 ELSE 0 END,
  CAST(p.cpi_u_media_anual AS REAL),
  CAST(p.fator_deflator_base2022 AS REAL),
  CASE WHEN TRIM(COALESCE(p.cpi_toys_media_anual,'')) = '' THEN NULL
       ELSE CAST(p.cpi_toys_media_anual AS REAL) END,
  CASE WHEN TRIM(COALESCE(p.cpi_toys_media_anual,'')) = '' THEN 0 ELSE 1 END
FROM stg_lego_sets AS s
INNER JOIN stg_cpi AS p ON CAST(p.ano AS INTEGER) = CAST(s.year AS INTEGER);
-- INNER JOIN de proposito: se algum ano do catalogo nao tivesse CPI, a linha sumiria e
-- a contagem de 53 anos acusaria na hora. Um LEFT JOIN esconderia o buraco num NULL.
-- Checagem de cobertura nos dois sentidos esta em sql/04-deflacao-e-serie-real.sql.
-- flag_preco_confiavel viaja na dimensao, nao na fato: e um atributo do ANO
-- (cobertura da fonte naquele ano), nao do set. Vira filtro de pagina no Power BI.


-- =============================================================================
-- DIM_CATEGORIA  -- grao: categoria. 7 linhas.
-- =============================================================================
CREATE TABLE dim_categoria (
  sk_categoria       INTEGER PRIMARY KEY,
  categoria          TEXT NOT NULL,
  flag_contem_pecas  INTEGER NOT NULL   -- 0 = mercadoria sem peca (Gear); fora de unit economics
);

INSERT INTO dim_categoria (sk_categoria, categoria, flag_contem_pecas)
SELECT
  ROW_NUMBER() OVER (ORDER BY category),
  category,
  CASE WHEN category IN ('Gear','Random') THEN 0 ELSE 1 END
FROM (SELECT DISTINCT category FROM stg_lego_sets);


-- =============================================================================
-- DIM_FAIXA_PRECO  -- escada de precos. Faixas de varejo, nao quantis:
--   quantil muda de fronteira a cada ano e destroi a comparacao temporal.
--   Faixa fixa em dolar permite ver MIGRACAO DE MIX entre faixas ao longo do tempo.
--   Linha 0 = 'Sem preco informado': a fato nunca aponta para NULL.
-- =============================================================================
CREATE TABLE dim_faixa_preco (
  sk_faixa_preco  INTEGER PRIMARY KEY,
  faixa_preco     TEXT NOT NULL,
  ordem_faixa     INTEGER NOT NULL,   -- coluna de ordenacao para o Power BI (Sort by column)
  limite_inferior REAL,
  limite_superior REAL
);

INSERT INTO dim_faixa_preco (sk_faixa_preco, faixa_preco, ordem_faixa, limite_inferior, limite_superior) VALUES
  (0, 'Sem preço informado',  0, NULL,   NULL),
  (1, 'Até US$ 9.99',         1, 0.00,   9.99),
  (2, 'US$ 10 a 19.99',       2, 10.00,  19.99),
  (3, 'US$ 20 a 49.99',       3, 20.00,  49.99),
  (4, 'US$ 50 a 99.99',       4, 50.00,  99.99),
  (5, 'US$ 100 a 199.99',     5, 100.00, 199.99),
  (6, 'US$ 200 ou mais',      6, 200.00, NULL);


-- =============================================================================
-- DIM_FAIXA_TAMANHO  -- banda de numero de pecas. Mesma familia de dim_faixa_preco e
--   dim_faixa_etaria: faixa fixa sobre uma medida da fato, virada em dimensao para
--   poder filtrar e ordenar. Existe porque docs/qualidade-do-dado.md secao 4 exige
--   controlar tamanho de set em QUALQUER comparacao de preco por peca entre linhas de
--   produto -- sem isso o -36,4% da faixa pequena e Duplo disfarcado.
--   Linha 0 absorve os 3.924 sets sem contagem de pecas: a fato nunca aponta para NULL.
-- =============================================================================
CREATE TABLE dim_faixa_tamanho (
  sk_faixa_tamanho INTEGER PRIMARY KEY,
  faixa_tamanho    TEXT NOT NULL,
  ordem_faixa      INTEGER NOT NULL,   -- Sort by column no Power BI
  pecas_minimo     INTEGER,
  pecas_maximo     INTEGER
);

INSERT INTO dim_faixa_tamanho (sk_faixa_tamanho, faixa_tamanho, ordem_faixa, pecas_minimo, pecas_maximo) VALUES
  (0, 'Peças não informadas', 0, NULL, NULL),
  (1, 'Até 99 peças',         1, 0,    99),
  (2, '100 a 249 peças',      2, 100,  249),
  (3, '250 a 499 peças',      3, 250,  499),
  (4, '500 a 999 peças',      4, 500,  999),
  (5, '1.000 peças ou mais',  5, 1000, NULL);


-- =============================================================================
-- DIM_FAIXA_ETARIA  -- agerange_min falta em 63% das linhas; linha 0 absorve isso.
-- =============================================================================
CREATE TABLE dim_faixa_etaria (
  sk_faixa_etaria INTEGER PRIMARY KEY,
  faixa_etaria    TEXT NOT NULL,
  ordem_faixa     INTEGER NOT NULL,
  idade_minima    INTEGER,
  idade_maxima    INTEGER
);

INSERT INTO dim_faixa_etaria (sk_faixa_etaria, faixa_etaria, ordem_faixa, idade_minima, idade_maxima) VALUES
  (0, 'Não informada',      0, NULL, NULL),
  (1, '1 a 3 anos',         1, 1,    3),
  (2, '4 a 6 anos',         2, 4,    6),
  (3, '7 a 9 anos',         3, 7,    9),
  (4, '10 a 13 anos',       4, 10,   13),
  (5, '14 a 17 anos',       5, 14,   17),
  (6, '18 anos ou mais',    6, 18,   NULL);


-- =============================================================================
-- FATO_SETS  -- grao: 1 linha = 1 set (set_id). 18.457 linhas, sem agregacao.
--   Metricas ADITIVAS apenas. qt_sets = 1 em toda linha: permite COUNT via SUM e
--   deixa o "quantos sets" explicito como metrica, nao como contagem de linha.
-- =============================================================================
CREATE TABLE fato_sets (
  sk_set               INTEGER PRIMARY KEY,
  set_id               TEXT NOT NULL UNIQUE,  -- dimensao degenerada: chave natural
  nome_set             TEXT NOT NULL,
  subtema              TEXT,
  sk_tema              INTEGER NOT NULL REFERENCES dim_tema(sk_tema),
  sk_ano               INTEGER NOT NULL REFERENCES dim_calendario(sk_ano),
  sk_categoria         INTEGER NOT NULL REFERENCES dim_categoria(sk_categoria),
  sk_faixa_preco       INTEGER NOT NULL REFERENCES dim_faixa_preco(sk_faixa_preco),
  sk_faixa_etaria      INTEGER NOT NULL REFERENCES dim_faixa_etaria(sk_faixa_etaria),
  sk_faixa_tamanho     INTEGER NOT NULL REFERENCES dim_faixa_tamanho(sk_faixa_tamanho),
  qt_sets              INTEGER NOT NULL,   -- sempre 1
  qt_pecas             INTEGER,            -- NULL = nao informado (nao e zero)
  qt_minifigs          INTEGER NOT NULL,   -- NULL da origem tratado como 0 (ver qualidade)
  vl_preco_usd         REAL,               -- USD de lancamento NOMINAL (dolar do ano)
  vl_preco_usd_2022    REAL,               -- o mesmo preco em USD CONSTANTES de 2022
  flag_tem_preco       INTEGER NOT NULL,
  flag_preco_99        INTEGER NOT NULL,   -- 1 = preco termina em .99 (ponto psicologico)
  flag_escopo_pricing  INTEGER NOT NULL,   -- 1 = entra em preco por peca (regra em 01, secao 8)
  url_brickset         TEXT
);
-- vl_preco_usd_2022 e um FATO ADITIVO, nao uma razao -- por isso, ao contrario de preco
-- por peca, ele PODE e DEVE morar na fato. E o mesmo valor em outra unidade, igual a
-- guardar moeda local e moeda de reporte lado a lado. Calcula-se linha a linha porque
-- SUM(preco*fator) != SUM(preco)*AVG(fator) num agregado de varios anos (prova em 04).

INSERT INTO fato_sets
SELECT
  ROW_NUMBER() OVER (ORDER BY CAST(s.year AS INTEGER), s.set_id) AS sk_set,
  s.set_id,
  s.name,
  NULLIF(TRIM(s.subtheme), ''),
  t.sk_tema,
  CAST(s.year AS INTEGER),
  c.sk_categoria,
  CASE
    WHEN TRIM(COALESCE(s.US_retailPrice,'')) = ''       THEN 0
    WHEN CAST(s.US_retailPrice AS REAL) <  10           THEN 1
    WHEN CAST(s.US_retailPrice AS REAL) <  20           THEN 2
    WHEN CAST(s.US_retailPrice AS REAL) <  50           THEN 3
    WHEN CAST(s.US_retailPrice AS REAL) < 100           THEN 4
    WHEN CAST(s.US_retailPrice AS REAL) < 200           THEN 5
    ELSE 6
  END AS sk_faixa_preco,
  CASE
    WHEN TRIM(COALESCE(s.agerange_min,'')) = ''         THEN 0
    WHEN CAST(s.agerange_min AS INTEGER) <=  3          THEN 1
    WHEN CAST(s.agerange_min AS INTEGER) <=  6          THEN 2
    WHEN CAST(s.agerange_min AS INTEGER) <=  9          THEN 3
    WHEN CAST(s.agerange_min AS INTEGER) <= 13          THEN 4
    WHEN CAST(s.agerange_min AS INTEGER) <= 17          THEN 5
    ELSE 6
  END AS sk_faixa_etaria,
  CASE
    WHEN TRIM(COALESCE(s.pieces,'')) = ''       THEN 0
    WHEN CAST(s.pieces AS INTEGER) <  100       THEN 1
    WHEN CAST(s.pieces AS INTEGER) <  250       THEN 2
    WHEN CAST(s.pieces AS INTEGER) <  500       THEN 3
    WHEN CAST(s.pieces AS INTEGER) < 1000       THEN 4
    ELSE 5
  END AS sk_faixa_tamanho,
  1 AS qt_sets,
  CASE WHEN TRIM(COALESCE(s.pieces,'')) = '' THEN NULL ELSE CAST(s.pieces AS INTEGER) END,
  CASE WHEN TRIM(COALESCE(s.minifigs,'')) = '' THEN 0 ELSE CAST(s.minifigs AS INTEGER) END,
  CASE WHEN TRIM(COALESCE(s.US_retailPrice,'')) = '' THEN NULL ELSE CAST(s.US_retailPrice AS REAL) END,
  CASE WHEN TRIM(COALESCE(s.US_retailPrice,'')) = '' THEN NULL
       ELSE ROUND(CAST(s.US_retailPrice AS REAL) * cal.fator_deflator_base2022, 4) END,
  CASE WHEN TRIM(COALESCE(s.US_retailPrice,'')) = '' THEN 0 ELSE 1 END,
  -- .99 comparado em CENTAVOS INTEIROS: 44.99*100 em ponto flutuante nao e exatamente
  -- 4499, entao ROUND antes do modulo. Testar o resto de um REAL direto daria falso negativo.
  CASE WHEN TRIM(COALESCE(s.US_retailPrice,'')) <> ''
        AND CAST(ROUND(CAST(s.US_retailPrice AS REAL) * 100) AS INTEGER) % 100 = 99
       THEN 1 ELSE 0 END,
  CASE WHEN s.category = 'Normal'
        AND TRIM(COALESCE(s.US_retailPrice,'')) <> ''
        AND TRIM(COALESCE(s.pieces,'')) <> ''
        AND CAST(s.pieces AS INTEGER) >= 20
        AND CAST(s.year AS INTEGER) >= 2007
       THEN 1 ELSE 0 END,
  s.bricksetURL
FROM stg_lego_sets AS s
INNER JOIN dim_tema AS t
        ON t.tema = s.theme
INNER JOIN dim_categoria AS c
        ON c.categoria = s.category
INNER JOIN dim_calendario AS cal
        ON cal.sk_ano = CAST(s.year AS INTEGER);
-- Os dois JOIN sao N:1 por construcao (dim_tema e dim_categoria vieram de SELECT DISTINCT
-- da propria staging). A checagem de que nao multiplicaram linha esta logo abaixo.

CREATE INDEX idx_fato_tema      ON fato_sets(sk_tema);
CREATE INDEX idx_fato_ano       ON fato_sets(sk_ano);
CREATE INDEX idx_fato_categoria ON fato_sets(sk_categoria);
CREATE INDEX idx_fato_tamanho   ON fato_sets(sk_faixa_tamanho);


-- =============================================================================
-- CHECAGENS DE CARDINALIDADE E INTEGRIDADE -- rodar SEMPRE antes de exportar
-- =============================================================================

-- 1. A fato tem exatamente as linhas da origem? (JOIN nao multiplicou nem perdeu)
SELECT
  (SELECT COUNT(*) FROM stg_lego_sets) AS linhas_origem,
  (SELECT COUNT(*) FROM fato_sets)     AS linhas_fato,
  (SELECT COUNT(DISTINCT set_id) FROM fato_sets) AS set_id_distintos_fato;

-- 2. Toda sk da fato existe na dimensao? (nenhum orfao)
SELECT
  (SELECT COUNT(*) FROM fato_sets f LEFT JOIN dim_tema         d ON d.sk_tema        =f.sk_tema         WHERE d.sk_tema        IS NULL) AS orfaos_tema,
  (SELECT COUNT(*) FROM fato_sets f LEFT JOIN dim_calendario   d ON d.sk_ano         =f.sk_ano          WHERE d.sk_ano         IS NULL) AS orfaos_ano,
  (SELECT COUNT(*) FROM fato_sets f LEFT JOIN dim_categoria    d ON d.sk_categoria   =f.sk_categoria    WHERE d.sk_categoria   IS NULL) AS orfaos_categoria,
  (SELECT COUNT(*) FROM fato_sets f LEFT JOIN dim_faixa_preco  d ON d.sk_faixa_preco =f.sk_faixa_preco  WHERE d.sk_faixa_preco IS NULL) AS orfaos_faixa_preco,
  (SELECT COUNT(*) FROM fato_sets f LEFT JOIN dim_faixa_etaria d ON d.sk_faixa_etaria=f.sk_faixa_etaria WHERE d.sk_faixa_etaria IS NULL) AS orfaos_faixa_etaria,
  (SELECT COUNT(*) FROM fato_sets f LEFT JOIN dim_faixa_tamanho d ON d.sk_faixa_tamanho=f.sk_faixa_tamanho WHERE d.sk_faixa_tamanho IS NULL) AS orfaos_faixa_tamanho;

-- 3. Cada dimensao tem chave unica? (se nao tiver, o JOIN vira N:N e multiplica a fato)
SELECT 'dim_tema'         AS dimensao, COUNT(*) AS linhas, COUNT(DISTINCT sk_tema)         AS chaves FROM dim_tema
UNION ALL SELECT 'dim_calendario',   COUNT(*), COUNT(DISTINCT sk_ano)          FROM dim_calendario
UNION ALL SELECT 'dim_categoria',    COUNT(*), COUNT(DISTINCT sk_categoria)    FROM dim_categoria
UNION ALL SELECT 'dim_faixa_preco',  COUNT(*), COUNT(DISTINCT sk_faixa_preco)  FROM dim_faixa_preco
UNION ALL SELECT 'dim_faixa_etaria', COUNT(*), COUNT(DISTINCT sk_faixa_etaria) FROM dim_faixa_etaria
UNION ALL SELECT 'dim_faixa_tamanho',COUNT(*), COUNT(DISTINCT sk_faixa_tamanho)FROM dim_faixa_tamanho;

-- 4. As somas aditivas batem com a origem?
SELECT
  (SELECT SUM(CAST(US_retailPrice AS REAL)) FROM stg_lego_sets WHERE TRIM(COALESCE(US_retailPrice,''))<>'') AS soma_preco_origem,
  (SELECT SUM(vl_preco_usd) FROM fato_sets)                                                                  AS soma_preco_fato,
  (SELECT SUM(CAST(pieces AS INTEGER)) FROM stg_lego_sets WHERE TRIM(COALESCE(pieces,''))<>'')               AS soma_pecas_origem,
  (SELECT SUM(qt_pecas) FROM fato_sets)                                                                      AS soma_pecas_fato,
  (SELECT ROUND(SUM(vl_preco_usd_2022),2) FROM fato_sets)                                                    AS soma_preco_real_2022;

-- 6. A faixa de tamanho bate com qt_pecas em toda linha? (a dimensao nao pode mentir)
SELECT COUNT(*) AS linhas_incoerentes FROM fato_sets
WHERE (qt_pecas IS NULL AND sk_faixa_tamanho <> 0)
   OR (qt_pecas IS NOT NULL AND sk_faixa_tamanho = 0)
   OR (qt_pecas <  100 AND sk_faixa_tamanho <> 1)
   OR (qt_pecas >= 100 AND qt_pecas <  250 AND sk_faixa_tamanho <> 2)
   OR (qt_pecas >= 250 AND qt_pecas <  500 AND sk_faixa_tamanho <> 3)
   OR (qt_pecas >= 500 AND qt_pecas < 1000 AND sk_faixa_tamanho <> 4)
   OR (qt_pecas >= 1000 AND sk_faixa_tamanho <> 5);

-- 7. O preco real so pode ser nulo onde o nominal e nulo, e em 2022 tem que ser identico
SELECT
  (SELECT COUNT(*) FROM fato_sets WHERE (vl_preco_usd IS NULL) <> (vl_preco_usd_2022 IS NULL)) AS nulos_divergentes,
  (SELECT COUNT(*) FROM fato_sets WHERE sk_ano=2022 AND flag_tem_preco=1
                                    AND ABS(vl_preco_usd - vl_preco_usd_2022) > 0.005)         AS erro_base_2022,
  (SELECT COUNT(*) FROM fato_sets WHERE flag_tem_preco=1
                                    AND vl_preco_usd_2022 < vl_preco_usd - 0.005)              AS real_menor_que_nominal;

-- 5. Distribuicao da fato pelas faixas (nenhuma linha pode ficar fora)
SELECT p.faixa_preco, COUNT(*) AS sets
FROM fato_sets AS f
INNER JOIN dim_faixa_preco AS p ON p.sk_faixa_preco = f.sk_faixa_preco
GROUP BY p.faixa_preco, p.ordem_faixa
ORDER BY p.ordem_faixa;
