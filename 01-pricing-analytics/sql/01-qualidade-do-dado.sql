-- Pergunta: o dado sustenta uma analise de pricing? Onde ele e confiavel e onde nao e?
-- Fonte: data/lego_sets.csv (18.457 linhas) carregado em data/lego.db, tabela stg_lego_sets. Dialeto: SQLite.
--
-- Este arquivo e o perfil que precede qualquer analise. Nenhuma conclusao de negocio sai
-- daqui: o objetivo e delimitar o escopo analitico defensavel.
-- Resultados registrados abaixo de cada query foram apurados em 2026-09-20.

-- =============================================================================
-- 0. CARGA DA STAGING
--    Tudo entra como TEXT de proposito: o CSV tem vazio ('') onde deveria haver
--    NULL, e converter na carga esconderia o problema em vez de medi-lo.
-- =============================================================================
-- CREATE TABLE stg_lego_sets (
--   set_id TEXT, name TEXT, year TEXT, theme TEXT, subtheme TEXT,
--   themeGroup TEXT, category TEXT, pieces TEXT, minifigs TEXT,
--   agerange_min TEXT, US_retailPrice TEXT, bricksetURL TEXT,
--   thumbnailURL TEXT, imageURL TEXT);
-- .mode csv
-- .import --skip 1 data/lego_sets.csv stg_lego_sets


-- =============================================================================
-- 1. VOLUME E UNICIDADE DA CHAVE
-- =============================================================================
SELECT
  COUNT(*)                  AS linhas,
  COUNT(DISTINCT set_id)    AS set_id_distintos,
  COUNT(*) - COUNT(DISTINCT set_id) AS duplicatas
FROM stg_lego_sets;
-- RESULTADO: 18457 linhas | 18457 set_id distintos | 0 duplicatas.
-- set_id e chave natural confiavel. Nao ha deduplicacao a fazer.


-- =============================================================================
-- 2. NULOS POR COLUNA
--    '' e NULL sao tratados como a mesma coisa: ausencia de informacao.
-- =============================================================================
SELECT
  COUNT(*) AS linhas,
  SUM(CASE WHEN TRIM(COALESCE(year,''))         = '' THEN 1 ELSE 0 END) AS nulo_ano,
  SUM(CASE WHEN TRIM(COALESCE(theme,''))        = '' THEN 1 ELSE 0 END) AS nulo_tema,
  SUM(CASE WHEN TRIM(COALESCE(themeGroup,''))   = '' THEN 1 ELSE 0 END) AS nulo_grupo_tema,
  SUM(CASE WHEN TRIM(COALESCE(subtheme,''))     = '' THEN 1 ELSE 0 END) AS nulo_subtema,
  SUM(CASE WHEN TRIM(COALESCE(category,''))     = '' THEN 1 ELSE 0 END) AS nulo_categoria,
  SUM(CASE WHEN TRIM(COALESCE(pieces,''))       = '' THEN 1 ELSE 0 END) AS nulo_pecas,
  SUM(CASE WHEN TRIM(COALESCE(minifigs,''))     = '' THEN 1 ELSE 0 END) AS nulo_minifigs,
  SUM(CASE WHEN TRIM(COALESCE(agerange_min,'')) = '' THEN 1 ELSE 0 END) AS nulo_idade_min,
  SUM(CASE WHEN TRIM(COALESCE(US_retailPrice,''))='' THEN 1 ELSE 0 END) AS nulo_preco
FROM stg_lego_sets;
-- RESULTADO: ano 0 | tema 0 | grupo_tema 2 | subtema 3556 | categoria 0
--            pecas 3924 | minifigs 10058 | idade_min 11670 | PRECO 11475 (62,2%)
-- O preco, que e a metrica central do projeto, falta em quase dois tercos das linhas.
-- Isso nao e ruido: e a restricao que define o escopo (ver secao 3).


-- =============================================================================
-- 3. COBERTURA DE PRECO AO LONGO DO TEMPO  -- a checagem mais importante do arquivo
-- =============================================================================
SELECT
  -- CAST + parenteses: em SQLite o || tem precedencia maior que o *; sem isso a
  -- expressao vira (ano/10) * ('10s' -> 10) e o rotulo perde o 's'.
  CAST((CAST(year AS INTEGER) / 10) * 10 AS TEXT) || 's' AS decada,
  COUNT(*) AS sets,
  SUM(CASE WHEN TRIM(COALESCE(US_retailPrice,'')) <> '' THEN 1 ELSE 0 END) AS com_preco,
  ROUND(100.0 * SUM(CASE WHEN TRIM(COALESCE(US_retailPrice,'')) <> '' THEN 1 ELSE 0 END)
        / COUNT(*), 1) AS pct_com_preco
FROM stg_lego_sets
GROUP BY decada
ORDER BY decada;
-- RESULTADO: 1970s 652 sets / 0 com preco (0,0%)
--            1980s 1142 / 0 (0,0%)
--            1990s 2094 / 15 (0,7%)
--            2000s 4328 / 1115 (25,8%)
--            2010s 7481 / 4318 (57,7%)
--            2020s 2760 / 1534 (55,6%)
-- Ano a ano, o salto e em 2007: 2005=10,9%, 2006=29,6%, 2007=66,6%, e a partir dai
-- a cobertura fica estavel entre 52% e 69%.
-- DECISAO: serie temporal de preco comeca em 2007. Antes disso o dado nao sustenta
-- afirmacao nenhuma sobre nivel de preco.


-- =============================================================================
-- 4. OUTLIERS DE PRECO
-- =============================================================================
WITH precos AS (
  SELECT CAST(US_retailPrice AS REAL) AS preco
  FROM stg_lego_sets
  WHERE TRIM(COALESCE(US_retailPrice,'')) <> ''
)
SELECT
  COUNT(*)                                       AS n,
  ROUND(MIN(preco), 2)                           AS minimo,
  ROUND(AVG(preco), 2)                           AS media,
  ROUND(MAX(preco), 2)                           AS maximo,
  SUM(CASE WHEN preco <= 0 THEN 1 ELSE 0 END)    AS preco_zero_ou_negativo,
  SUM(CASE WHEN preco > 500 THEN 1 ELSE 0 END)   AS acima_de_500
FROM precos;
-- RESULTADO: n=6982 | min 1,49 | media 37,53 | max 849,99 | zero/negativo 0 | >500: 10
-- Nenhum preco invalido. Os 10 acima de US$ 500 sao flagships reais (Millennium Falcon
-- 75192 com 7.541 pecas a 849,99; Titanic 10294 com 9.090 pecas a 679,99). Sao cauda
-- legitima do catalogo, nao erro de digitacao: NAO devem ser removidos.

-- Percentis de preco: a escada de precos real do catalogo.
WITH precos AS (
  SELECT CAST(US_retailPrice AS REAL) AS preco
  FROM stg_lego_sets
  WHERE TRIM(COALESCE(US_retailPrice,'')) <> ''
),
centis AS (
  SELECT preco, NTILE(100) OVER (ORDER BY preco) AS centil
  FROM precos
)
-- NTILE(100) OVER (ORDER BY preco): ordena os 6.982 precos do menor para o maior e
-- corta em 100 baldes de ~70 linhas. Sem PARTITION BY porque o corte e sobre o catalogo
-- inteiro, nao dentro de grupos.
SELECT centil, ROUND(MIN(preco), 2) AS limite_inferior, ROUND(MAX(preco), 2) AS limite_superior
FROM centis
WHERE centil IN (1, 5, 25, 50, 75, 95, 99, 100)
GROUP BY centil
ORDER BY centil;
-- RESULTADO: p1 1,49-2,99 | p5 4,99 | p25 9,99 | p50 19,99 | p75 39,99
--            p95 99,99-119,99 | p99 199,99-269,99 | p100 269,99-849,99
-- Os precos se concentram em pontos psicologicos (.99). A mediana do catalogo e
-- US$ 19,99 e 75% dos sets custam ate US$ 39,99.


-- =============================================================================
-- 5. OUTLIERS DE PECAS E O PROBLEMA DO DENOMINADOR
--    Preco por peca e uma razao: se o denominador for lixo, a metrica e lixo.
-- =============================================================================
SELECT
  COUNT(*)                                        AS n_com_pecas,
  MIN(CAST(pieces AS INTEGER))                    AS minimo,
  ROUND(AVG(CAST(pieces AS INTEGER)), 1)          AS media,
  MAX(CAST(pieces AS INTEGER))                    AS maximo,
  SUM(CASE WHEN CAST(pieces AS INTEGER) = 0 THEN 1 ELSE 0 END) AS pecas_zero,
  SUM(CASE WHEN CAST(pieces AS INTEGER) = 1 THEN 1 ELSE 0 END) AS pecas_um
FROM stg_lego_sets
WHERE TRIM(COALESCE(pieces,'')) <> '';
-- RESULTADO: n=14533 | min 0 | media 226,5 | max 11695 | zero 16 | uma peca 309

-- Quem sao os sets com preco por peca absurdo?
SELECT
  set_id, name, year, theme, category, pieces, US_retailPrice,
  ROUND(CAST(US_retailPrice AS REAL) / CAST(pieces AS INTEGER), 2) AS preco_por_peca
FROM stg_lego_sets
WHERE category = 'Normal'
  AND TRIM(COALESCE(US_retailPrice,'')) <> ''
  AND CAST(pieces AS INTEGER) > 0
  AND CAST(US_retailPrice AS REAL) / CAST(pieces AS INTEGER) > 2
ORDER BY preco_por_peca DESC
LIMIT 8;
-- RESULTADO: EV3 Intelligent Brick (1 peca, 224,95) | NXT Intelligent Brick (1, 169,99)
--            Powered Up Large Hub (2, 249,99) | Technic Hub (1, 89,99) ...
-- Sao COMPONENTES ELETRONICOS vendidos avulsos, nao sets de construcao. Distorcem
-- qualquer media de preco por peca.

-- Efeito de um corte minimo de pecas sobre a metrica (Normal, com preco, 2007+).
-- ATENCAO as duas colunas de ppp: elas NAO medem a mesma coisa.
--   "media das razoes" = AVG(preco/pecas)  -- errada para pricing, cada set pesa igual
--   "razao dos totais" = SUM(preco)/SUM(pecas) -- a metrica do projeto
--             sets   media das razoes   razao dos totais   ppp max
--   sem corte 4984             0,6385             0,1105    224,95
--   >= 10 pc  4783             0,1885             0,1090      3,00
--   >= 20 pc  4626             0,1657             0,1082      2,53
--   >= 50 pc  4203             0,1354             0,1058      2,53
-- A distancia entre as duas colunas e a razao pela qual preco por peca NAO vai
-- pre-calculado na fato (ver sql/02-modelo-estrela.sql e docs/dicionario-de-dados.md).
-- DECISAO: corte em 20 pecas. Preserva 93% do universo analisavel e elimina a cauda
-- de eletronicos. Ir a 50 ja comeca a cortar set pequeno legitimo.


-- =============================================================================
-- 6. CATEGORIAS: o que e set de construcao e o que e mercadoria
-- =============================================================================
SELECT
  category AS categoria,
  COUNT(*) AS sets,
  SUM(CASE WHEN TRIM(COALESCE(pieces,'')) = '' OR CAST(pieces AS INTEGER) = 0
           THEN 1 ELSE 0 END) AS sem_contagem_de_pecas,
  SUM(CASE WHEN TRIM(COALESCE(US_retailPrice,'')) <> ''
            AND TRIM(COALESCE(pieces,'')) <> ''
            AND CAST(pieces AS INTEGER) > 0 THEN 1 ELSE 0 END) AS analisavel
FROM stg_lego_sets
GROUP BY categoria
ORDER BY analisavel DESC;
-- RESULTADO: Normal 12757 sets / 216 sem pecas / 5164 analisaveis
--            Extended 501 / 58 / 118 | Collection 578 / 67 / 14 | Other 1094 / 149 / 12
--            Book 631 / 566 / 11 | Random 64 / 52 / 0 | Gear 2832 / 2832 / 0
-- 'Gear' (2.832 sets: relogios, chaveiros, mochilas) NAO TEM PECA NENHUMA. E merchandise,
-- nao set de construcao. Entra no mix de portfolio, mas nunca em preco por peca.
-- DECISAO: escopo de unit economics = category 'Normal'.


-- =============================================================================
-- 7. TEMA E GRUPO DE TEMA: a hierarquia e limpa?
-- =============================================================================
SELECT
  COUNT(DISTINCT theme)                      AS temas,
  COUNT(DISTINCT themeGroup)                 AS grupos,
  COUNT(DISTINCT theme || '|' || themeGroup) AS pares_distintos
FROM stg_lego_sets;
-- RESULTADO: 154 temas | 17 grupos | 154 pares distintos.
-- temas = pares => cada tema pertence a exatamente um grupo. Hierarquia 1:N limpa,
-- dim_tema pode ser desnormalizada sem risco de duplicar linha no JOIN.

SELECT theme, COUNT(DISTINCT themeGroup) AS grupos
FROM stg_lego_sets GROUP BY theme HAVING grupos > 1;
-- RESULTADO: nenhuma linha. Confirma a checagem acima.

SELECT set_id, name, year, theme, category
FROM stg_lego_sets WHERE TRIM(COALESCE(themeGroup,'')) = '';
-- RESULTADO: 2 linhas, ambas do tema 'LEGO Universe' (2010). Grupo ausente na origem.
-- Tratamento: rotulo explicito 'Nao informado' na dimensao, nunca NULL silencioso.


-- =============================================================================
-- 8. ESCOPO ANALITICO FINAL DE PRICING
--    Todo numero de preco por peca deste projeto sai deste universo.
-- =============================================================================
SELECT
  COUNT(*)                     AS sets_no_escopo,
  MIN(CAST(year AS INTEGER))   AS ano_inicial,
  MAX(CAST(year AS INTEGER))   AS ano_final,
  COUNT(DISTINCT theme)        AS temas
FROM stg_lego_sets
WHERE category = 'Normal'
  AND TRIM(COALESCE(US_retailPrice,'')) <> ''
  AND TRIM(COALESCE(pieces,'')) <> ''
  AND CAST(pieces AS INTEGER) >= 20
  AND CAST(year AS INTEGER) >= 2007;
-- RESULTADO: 4626 sets | 2007 a 2022 | 96 temas.
-- 4.626 de 18.457 linhas (25,1%). E um quarto do catalogo, mas e o quarto sobre o
-- qual da para afirmar alguma coisa. As perguntas de MIX e COBERTURA, que nao
-- dependem de preco, continuam rodando sobre as 18.457.
