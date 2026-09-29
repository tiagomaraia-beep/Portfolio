-- Pergunta: as cinco perguntas de pricing analytics do catalogo, respondidas em SQL.
-- Fonte: esquema estrela em data/lego.db, criado por sql/02-modelo-estrela.sql. Dialeto: SQLite.
--
-- AVISO QUE VALE PARA TODO O ARQUIVO: vl_preco_usd e preco de lancamento em USD
-- corrente, SEM correcao por inflacao. Toda serie temporal de preco aqui e nominal.
-- Escopo de preco: flag_escopo_pricing = 1 (categoria Normal, >= 20 pecas, com preco,
-- ano >= 2007). 4.626 sets. Justificativa em sql/01-qualidade-do-dado.sql.


-- #############################################################################
-- PERGUNTA 1 -- PRECO POR PECA: como evoluiu o unit economics do catalogo?
-- #############################################################################
WITH base_pricing AS (
  SELECT f.sk_ano AS ano, f.vl_preco_usd, f.qt_pecas
  FROM fato_sets AS f
  WHERE f.flag_escopo_pricing = 1
),
agregado_ano AS (
  SELECT
    ano,
    COUNT(*)                                  AS sets,
    SUM(vl_preco_usd)                         AS receita_lista_usd,
    SUM(qt_pecas)                             AS pecas,
    -- razao dos totais, nao media das razoes: um set de 7.541 pecas deve pesar mais
    -- que um de 30 no preco por peca do catalogo.
    ROUND(SUM(vl_preco_usd) / SUM(qt_pecas), 4) AS preco_por_peca,
    ROUND(AVG(vl_preco_usd), 2)               AS preco_medio_set,
    ROUND(AVG(CAST(qt_pecas AS REAL)), 0)     AS pecas_media_set
  FROM base_pricing
  GROUP BY ano
)
SELECT
  ano, sets, preco_por_peca, preco_medio_set, pecas_media_set,
  ROUND(100.0 * (preco_por_peca / LAG(preco_por_peca) OVER (ORDER BY ano) - 1), 1) AS var_yoy_pct,
  ROUND(100.0 * preco_por_peca / FIRST_VALUE(preco_por_peca) OVER (ORDER BY ano), 1) AS indice_base_2007
FROM agregado_ano
ORDER BY ano;
-- RESULTADO (apurado 2026-09-20): a serie e plana em USD NOMINAL.
--   2007 ppp 0,0986 | set medio 38,89 | 394 pecas | indice 100,0
--   2013 ppp 0,1340 (pico)            | 348 pecas | indice 136,0
--   2021 ppp 0,0964 (fundo)           | 609 pecas | indice  97,8
--   2022 ppp 0,1025 | set medio 67,96 | 663 pecas | indice 103,9
-- Periodo: 4.626 sets | 214.853,10 de lista | 1.986.433 pecas | ppp 0,1082.
-- LEITURA: em 15 anos o preco por peca andou 4% (nominal), mas o set medio subiu
-- 74,8% (38,89 -> 67,96) e ganhou 68,3% de pecas (394 -> 663). O aumento do preco
-- de tabela e TAMANHO, nao margem por peca.
-- LAG(preco_por_peca) OVER (ORDER BY ano): sem PARTITION BY, a janela e a serie inteira;
-- ORDER BY ano faz o LAG puxar o valor do ano imediatamente anterior, dando a variacao
-- ano a ano. FIRST_VALUE com o mesmo ORDER BY fixa o primeiro ano da serie (2007) como
-- base 100, transformando a serie num indice comparavel ponta a ponta.


-- #############################################################################
-- PERGUNTA 2 -- PREMIO DE LICENCA: tema licenciado cobra mais a pecas comparaveis?
--   Comparar licenciado x proprio na media geral seria armadilha: os licenciados
--   podem ser sistematicamente maiores ou menores. Por isso a comparacao e DENTRO
--   de faixas de tamanho de set.
-- #############################################################################
WITH base_licenca AS (
  SELECT
    t.flag_licenciado,
    f.vl_preco_usd,
    f.qt_pecas,
    CASE
      WHEN f.qt_pecas <  100 THEN '1. ate 99 pecas'
      WHEN f.qt_pecas <  250 THEN '2. 100 a 249'
      WHEN f.qt_pecas <  500 THEN '3. 250 a 499'
      WHEN f.qt_pecas < 1000 THEN '4. 500 a 999'
      ELSE                        '5. 1000 ou mais'
    END AS faixa_tamanho
  FROM fato_sets AS f
  INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
  WHERE f.flag_escopo_pricing = 1
),
ppp_por_faixa AS (
  SELECT
    faixa_tamanho,
    flag_licenciado,
    COUNT(*)                                    AS sets,
    SUM(vl_preco_usd) / SUM(qt_pecas)           AS preco_por_peca
  FROM base_licenca
  GROUP BY faixa_tamanho, flag_licenciado
)
SELECT
  faixa_tamanho,
  MAX(CASE WHEN flag_licenciado = 1 THEN sets END)                        AS sets_licenciados,
  MAX(CASE WHEN flag_licenciado = 0 THEN sets END)                        AS sets_proprios,
  ROUND(MAX(CASE WHEN flag_licenciado = 1 THEN preco_por_peca END), 4)    AS ppp_licenciado,
  ROUND(MAX(CASE WHEN flag_licenciado = 0 THEN preco_por_peca END), 4)    AS ppp_proprio,
  ROUND(100.0 * (MAX(CASE WHEN flag_licenciado = 1 THEN preco_por_peca END)
               / MAX(CASE WHEN flag_licenciado = 0 THEN preco_por_peca END) - 1), 1) AS premio_pct
FROM ppp_por_faixa
GROUP BY faixa_tamanho
ORDER BY faixa_tamanho;
-- RESULTADO: ate 99 pc -36,4% | 100-249 -12,9% | 250-499 -1,8% | 500-999 -1,1%
--            1000+ +22,9%
-- Os DOIS extremos sao artefato de mix e estao controlados logo abaixo (2a-bis) e
-- na analise de 2021-22: o -36,4% e Duplo; o +22,9% e a linha adulta PROPRIA
-- (Art ppp 0,0325 / Icons 0,0787 / Creator Expert 0,0796) barateando o denominador.

-- 2a-bis. CONTROLE OBRIGATORIO: o resultado da faixa "ate 99 pecas" e real ou e Duplo?
--   Duplo tem 273 sets no escopo e peca fisicamente muito maior que a peca System.
--   Comparar preco por peca entre Duplo e um set licenciado e comparar coisas diferentes.
WITH pequenos AS (
  SELECT t.flag_licenciado, t.grupo_tema, f.vl_preco_usd, f.qt_pecas
  FROM fato_sets AS f
  INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
  WHERE f.flag_escopo_pricing = 1 AND f.qt_pecas < 100
)
SELECT 'Com pré-escolar' AS cenario,
  ROUND(SUM(CASE WHEN flag_licenciado=1 THEN vl_preco_usd END)
      / SUM(CASE WHEN flag_licenciado=1 THEN qt_pecas END), 4) AS ppp_licenciado,
  ROUND(SUM(CASE WHEN flag_licenciado=0 THEN vl_preco_usd END)
      / SUM(CASE WHEN flag_licenciado=0 THEN qt_pecas END), 4) AS ppp_proprio
FROM pequenos
UNION ALL
SELECT 'Sem pré-escolar/júnior',
  ROUND(SUM(CASE WHEN flag_licenciado=1 THEN vl_preco_usd END)
      / SUM(CASE WHEN flag_licenciado=1 THEN qt_pecas END), 4),
  ROUND(SUM(CASE WHEN flag_licenciado=0 THEN vl_preco_usd END)
      / SUM(CASE WHEN flag_licenciado=0 THEN qt_pecas END), 4)
FROM pequenos WHERE grupo_tema NOT IN ('Pre-school','Junior');
-- RESULTADO: com pre-escolar 0,1662 vs 0,2613 (licenciado 36% MAIS BARATO).
--            sem pre-escolar 0,1662 vs 0,1638 (licenciado 1,5% mais caro).
-- O "desconto de licenca" em sets pequenos era inteiramente Duplo. Some com o controle.

-- 2a-ter. O numero agregado, que e a resposta honesta a pergunta
SELECT
  CASE WHEN t.flag_licenciado = 1 THEN 'Licenciado' ELSE 'Próprio' END AS tipo,
  COUNT(*)                                        AS sets,
  ROUND(SUM(f.vl_preco_usd) / SUM(f.qt_pecas), 4) AS preco_por_peca,
  ROUND(AVG(f.vl_preco_usd), 2)                   AS preco_medio_set,
  ROUND(AVG(CAST(f.qt_pecas AS REAL)), 0)         AS pecas_medias
FROM fato_sets AS f
INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
WHERE f.flag_escopo_pricing = 1
GROUP BY tipo;
-- RESULTADO: Licenciado 1484 sets | ppp 0,1084 | US$ 52,01/set | 480 pecas
--            Proprio    3142 sets | ppp 0,1080 | US$ 43,82/set | 406 pecas
-- O set licenciado custa 18,7% mais caro -- e tem 18,2% mais pecas. Por peca o premio
-- e 0,4%: ruido. O premio de licenca NAO esta no preco unitario, esta no TAMANHO.

-- 2d. Se o premio nao esta no preco por peca, esta na entrega de minifig? (2018-2022)
SELECT
  CASE WHEN t.flag_licenciado = 1 THEN 'Licenciado' ELSE 'Próprio' END AS tipo,
  ROUND(AVG(CAST(f.qt_minifigs AS REAL)), 2)                       AS minifigs_medias,
  ROUND(1.0 * SUM(f.qt_minifigs) / SUM(f.qt_pecas) * 1000, 2)      AS minifigs_por_1000_pecas
FROM fato_sets AS f
INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
WHERE f.flag_escopo_pricing = 1 AND f.sk_ano >= 2018
GROUP BY tipo;
-- RESULTADO: Licenciado 2,83 minifigs/set e 5,97 por mil pecas
--            Proprio    2,40 minifigs/set e 4,06 por mil pecas
-- O set licenciado entrega 47% mais minifig por peca. A licenca se paga em densidade
-- de personagem, nao em preco por tijolo.

-- 2b. O premio de licenca mudou ao longo do tempo?
WITH ppp_ano_licenca AS (
  SELECT
    f.sk_ano AS ano,
    t.flag_licenciado,
    SUM(f.vl_preco_usd) / SUM(f.qt_pecas) AS preco_por_peca,
    COUNT(*) AS sets
  FROM fato_sets AS f
  INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
  WHERE f.flag_escopo_pricing = 1
  GROUP BY ano, t.flag_licenciado
)
SELECT
  ano,
  MAX(CASE WHEN flag_licenciado = 1 THEN sets END)                     AS sets_licenciados,
  MAX(CASE WHEN flag_licenciado = 0 THEN sets END)                     AS sets_proprios,
  ROUND(MAX(CASE WHEN flag_licenciado = 1 THEN preco_por_peca END), 4) AS ppp_licenciado,
  ROUND(MAX(CASE WHEN flag_licenciado = 0 THEN preco_por_peca END), 4) AS ppp_proprio,
  ROUND(100.0 * (MAX(CASE WHEN flag_licenciado = 1 THEN preco_por_peca END)
               / MAX(CASE WHEN flag_licenciado = 0 THEN preco_por_peca END) - 1), 1) AS premio_pct
FROM ppp_ano_licenca
GROUP BY ano
ORDER BY ano;
-- RESULTADO: premio negativo ate 2018 (2013 -24,2%; 2017 -10,3%), vira positivo em
-- 2019 (+3,6%) e dispara em 2021 (+24,5%) e 2022 (+17,5%).
-- CONTROLE: em 2021-22, licenciado 0,1121 x proprio 0,0929 (+20,7%). Mas 38 sets de
-- Art/Icons/Creator Expert/Advanced models concentram 109.845 das 314.460 pecas dos
-- proprios (34,9% do denominador, a 0,0640/peca). Sem eles, proprio = 0,1084 e o
-- premio cai para +3,4%. O premio recente e EFEITO DE MIX, nao pricing de licenca.

-- 2c. Os grandes temas licenciados, individualmente (>= 40 sets no escopo)
WITH ppp_tema AS (
  SELECT
    t.tema, t.grupo_tema, t.flag_licenciado,
    COUNT(*)                              AS sets,
    SUM(f.vl_preco_usd) / SUM(f.qt_pecas) AS preco_por_peca,
    AVG(f.vl_preco_usd)                   AS preco_medio_set
  FROM fato_sets AS f
  INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
  WHERE f.flag_escopo_pricing = 1
  GROUP BY t.tema, t.grupo_tema, t.flag_licenciado
  HAVING COUNT(*) >= 40
)
SELECT
  tema, grupo_tema,
  CASE WHEN flag_licenciado = 1 THEN 'Licenciado' ELSE 'Próprio' END AS tipo,
  sets,
  ROUND(preco_por_peca, 4)   AS preco_por_peca,
  ROUND(preco_medio_set, 2)  AS preco_medio_set,
  RANK() OVER (ORDER BY preco_por_peca DESC) AS posicao_ppp
FROM ppp_tema
ORDER BY posicao_ppp;
-- RANK() OVER (ORDER BY preco_por_peca DESC): ranqueia os temas do mais caro por peca
-- ao mais barato. Sem PARTITION BY porque o ranking e global -- a pergunta e "quem cobra
-- mais caro no catalogo inteiro", nao "dentro do seu grupo". RANK (e nao ROW_NUMBER)
-- porque empate deve receber a mesma posicao.


-- #############################################################################
-- PERGUNTA 3 -- ESCADA DE PRECOS: o mix migrou para faixas mais altas?
--
-- >>> SUPERADA POR sql/04-deflacao-e-serie-real.sql, SECAO 3. <<<
-- As duas queries abaixo filtram "categoria Normal + flag_tem_preco", que NAO e o
-- escopo oficial do projeto (flag_escopo_pricing, que tambem exige >= 20 pecas).
-- Divergencia medida: 168 sets em 2007 aqui contra 153 no escopo oficial; a mediana
-- de 2007 sai 24,99 aqui e 29,99 no oficial, e a variacao 2007->2022 vai de +60,0%
-- para +33,3%. A conclusao qualitativa nao muda, a magnitude quase dobra.
-- Ficam aqui como registro do erro e da correcao. Para citar numero, usar o 04.
-- #############################################################################
WITH sets_com_preco AS (
  SELECT f.sk_ano AS ano, p.faixa_preco, p.ordem_faixa
  FROM fato_sets AS f
  INNER JOIN dim_faixa_preco AS p ON p.sk_faixa_preco = f.sk_faixa_preco
  WHERE f.flag_tem_preco = 1
    AND f.sk_ano >= 2007
    AND f.sk_categoria = (SELECT sk_categoria FROM dim_categoria WHERE categoria = 'Normal')
),
contagem AS (
  SELECT ano, faixa_preco, ordem_faixa, COUNT(*) AS sets
  FROM sets_com_preco
  GROUP BY ano, faixa_preco, ordem_faixa
)
SELECT
  ano, faixa_preco, sets,
  ROUND(100.0 * sets / SUM(sets) OVER (PARTITION BY ano), 1) AS share_pct
FROM contagem
ORDER BY ano, ordem_faixa;
-- RESULTADO (share por faixa): a escada migrou inteira para cima.
--   ate US$ 9,99 : 26,2% em 2007 -> 13,9% em 2022
--   US$ 100+     :  3,6% em 2007 -> 13,9% em 2022
--   US$ 50+      : 16,1% em 2007 -> 36,3% em 2022
--   ate US$ 20   : 47,6% em 2007 -> 33,8% em 2022
-- SUM(sets) OVER (PARTITION BY ano): PARTITION BY ano reinicia a soma a cada ano, de
-- modo que o denominador e o total daquele ano e nao do periodo todo -- e o que faz o
-- share fechar 100% dentro de cada ano. Sem ORDER BY porque nao e soma acumulada: a
-- janela precisa enxergar o ano inteiro de uma vez.

-- 3b. Resumo da migracao: share das faixas altas (US$ 100+) e preco mediano por ano
WITH sets_com_preco AS (
  SELECT f.sk_ano AS ano, f.vl_preco_usd, p.ordem_faixa
  FROM fato_sets AS f
  INNER JOIN dim_faixa_preco AS p ON p.sk_faixa_preco = f.sk_faixa_preco
  WHERE f.flag_tem_preco = 1 AND f.sk_ano >= 2007
    AND f.sk_categoria = (SELECT sk_categoria FROM dim_categoria WHERE categoria = 'Normal')
),
ordenado AS (
  SELECT
    ano, vl_preco_usd, ordem_faixa,
    ROW_NUMBER() OVER (PARTITION BY ano ORDER BY vl_preco_usd) AS posicao,
    COUNT(*)     OVER (PARTITION BY ano)                       AS total_ano
  FROM sets_com_preco
)
-- ROW_NUMBER com PARTITION BY ano ORDER BY preco numera os sets do mais barato ao mais
-- caro DENTRO de cada ano; COUNT(*) OVER (PARTITION BY ano) da o tamanho daquele ano.
-- As duas juntas permitem pegar a linha do meio -- a mediana -- sem funcao de percentil
-- (que o SQLite nao tem).
SELECT
  ano,
  MAX(total_ano)                                                                  AS sets_com_preco,
  ROUND(AVG(CASE WHEN posicao IN ((total_ano+1)/2, (total_ano+2)/2) THEN vl_preco_usd END), 2) AS preco_mediano,
  ROUND(100.0 * SUM(CASE WHEN ordem_faixa >= 5 THEN 1 ELSE 0 END) / MAX(total_ano), 1) AS share_100_mais_pct,
  ROUND(100.0 * SUM(CASE WHEN ordem_faixa <= 2 THEN 1 ELSE 0 END) / MAX(total_ano), 1) AS share_ate_20_pct
FROM ordenado
GROUP BY ano
ORDER BY ano;
-- RESULTADO: mediana 24,99 (2007) -> 19,99 (2012) -> 29,99 (2017) -> 39,99 (2022).
--            media   36,97 (2007) -> 65,70 (2022), +77,7%.
-- LEITURA: nao houve reprecificacao -- 98,8% dos precos terminam em .99 e existem so
-- 141 pontos de preco distintos. Houve RECOMPOSICAO DE PORTFOLIO: menos produto de
-- entrada, mais produto grande. Subir ticket medio sem mexer na tabela.


-- #############################################################################
-- PERGUNTA 4 -- MIX DE PORTFOLIO: concentracao por tema e grupo ao longo do tempo
--   Esta pergunta NAO depende de preco, entao roda sobre as 18.457 linhas.
-- #############################################################################
WITH sets_por_grupo_ano AS (
  SELECT c.decada, t.grupo_tema, COUNT(*) AS sets
  FROM fato_sets AS f
  INNER JOIN dim_tema       AS t ON t.sk_tema = f.sk_tema
  INNER JOIN dim_calendario AS c ON c.sk_ano  = f.sk_ano
  GROUP BY c.decada, t.grupo_tema
)
SELECT
  decada, grupo_tema, sets,
  ROUND(100.0 * sets / SUM(sets) OVER (PARTITION BY decada), 1) AS share_pct,
  RANK() OVER (PARTITION BY decada ORDER BY sets DESC)          AS posicao_na_decada
FROM sets_por_grupo_ano
WHERE decada >= 2000
ORDER BY decada, posicao_na_decada;
-- RESULTADO: 'Miscellaneous' aparece como maior grupo dos anos 2010 (42,5%) -- mas e
-- CATCH-ALL: 48,1% dele e Gear (merchandise sem peca), 13,1% Collectable Minifigures,
-- 10,7% Books, 10,0% Promotional, 6,6% Service Packs. Nao e categoria de produto.
-- Filtrando categoria 'Normal', quem lidera os anos 2010 e LICENSED (24,8%).
-- Share de Licensed sobre sets 'Normal' por decada:
--   1990s 0,7% | 2000s 9,6% | 2010s 24,8% | 2020s 36,9%  <- a mudanca estrutural.
-- PARTITION BY decada em ambas as janelas: o share e o ranking sao calculados DENTRO de
-- cada decada, independentes umas das outras. Sem isso, o RANK compararia grupos de
-- decadas diferentes e o share usaria o total de 53 anos como denominador.

-- 4b. Top 8 temas de cada ano e sua concentracao
WITH sets_tema_ano AS (
  SELECT f.sk_ano AS ano, t.tema, t.flag_licenciado, COUNT(*) AS sets
  FROM fato_sets AS f
  INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
  WHERE f.sk_ano >= 2007
  GROUP BY ano, t.tema, t.flag_licenciado
),
ranqueado AS (
  SELECT
    ano, tema, flag_licenciado, sets,
    ROW_NUMBER() OVER (PARTITION BY ano ORDER BY sets DESC, tema) AS posicao,
    ROUND(100.0 * sets / SUM(sets) OVER (PARTITION BY ano), 1)    AS share_pct
  FROM sets_tema_ano
)
-- ROW_NUMBER com PARTITION BY ano ORDER BY sets DESC: o "top-N por grupo" classico.
-- Reinicia a contagem a cada ano e ordena por volume, entao filtrar posicao <= 8 devolve
-- os 8 maiores temas DE CADA ANO. Desempate por tema para o resultado ser deterministico.
SELECT ano, posicao, tema,
       CASE WHEN flag_licenciado = 1 THEN 'Lic.' ELSE 'Próp.' END AS tipo,
       sets, share_pct
FROM ranqueado
WHERE posicao <= 8 AND ano IN (2007, 2012, 2017, 2022)
ORDER BY ano, posicao;

-- 4c. Concentracao: quanto pesam os 10 maiores temas de cada ano
--     HHI = soma dos quadrados dos shares (escala 0-10.000). Abaixo de 1.500 = pulverizado.
WITH sets_tema_ano AS (
  SELECT f.sk_ano AS ano, t.tema, COUNT(*) AS sets
  FROM fato_sets AS f
  INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
  WHERE f.sk_ano >= 2007
  GROUP BY ano, t.tema
),
com_share AS (
  SELECT ano, tema, sets,
         100.0 * sets / SUM(sets) OVER (PARTITION BY ano) AS share,
         ROW_NUMBER() OVER (PARTITION BY ano ORDER BY sets DESC) AS posicao
  FROM sets_tema_ano
)
SELECT
  ano,
  COUNT(*)                                                       AS temas_ativos,
  SUM(sets)                                                      AS sets_lancados,
  ROUND(SUM(CASE WHEN posicao <= 10 THEN share ELSE 0 END), 1)   AS share_top10_pct,
  ROUND(SUM(share * share), 0)                                   AS hhi
FROM com_share
GROUP BY ano
ORDER BY ano;
-- RESULTADO: 2007 HHI 1.898, top5 65,9%, 27 temas, 449 lancamentos
--            2018 HHI   561, top5 41,6%, 37 temas, 829 lancamentos  <- minimo
--            2022 HHI   996, top5 48,1%, 35 temas, 967 lancamentos
-- O portfolio dobrou de tamanho e se pulverizou ate 2018; de 2019 em diante volta a
-- concentrar. Gear sozinho e 27,3% dos lancamentos de 2022.

-- 4d. Entradas e saidas de tema: quem estreou e quem encerrou em cada ano
WITH tema_ano AS (
  SELECT DISTINCT t.tema, f.sk_ano AS ano
  FROM fato_sets AS f
  INNER JOIN dim_tema AS t ON t.sk_tema = f.sk_tema
),
ciclo_de_vida AS (
  SELECT tema, MIN(ano) AS ano_estreia, MAX(ano) AS ano_encerramento
  FROM tema_ano GROUP BY tema
),
estreias AS (
  SELECT ano_estreia AS ano, COUNT(*) AS temas
  FROM ciclo_de_vida WHERE ano_estreia >= 2007 GROUP BY ano_estreia
),
encerramentos AS (
  -- 2022 e o ultimo ano da base: tema ativo em 2022 nao "encerrou", so nao tem futuro
  -- observado. Excluir evita ler fim de base como descontinuacao.
  SELECT ano_encerramento AS ano, COUNT(*) AS temas
  FROM ciclo_de_vida WHERE ano_encerramento >= 2007 AND ano_encerramento < 2022
  GROUP BY ano_encerramento
),
anos AS (SELECT ano FROM dim_calendario WHERE ano >= 2007)
SELECT
  a.ano,
  COALESCE(e.temas, 0) AS temas_que_estrearam,
  COALESCE(x.temas, 0) AS temas_que_encerraram,
  COALESCE(e.temas, 0) - COALESCE(x.temas, 0) AS saldo_liquido,
  SUM(COALESCE(e.temas,0) - COALESCE(x.temas,0)) OVER (ORDER BY a.ano) AS saldo_acumulado
FROM anos AS a
LEFT JOIN estreias      AS e ON e.ano = a.ano
LEFT JOIN encerramentos AS x ON x.ano = a.ano
ORDER BY a.ano;
-- RESULTADO: ~5 estreias e ~4,5 encerramentos por ano; saldo acumulado em 16 anos
-- de apenas +6 temas (27 ativos em 2007 -> 35 em 2022), enquanto os lancamentos
-- anuais dobraram (449 -> 967). O portfolio GIRA MUITO E CRESCE POUCO: cada tema
-- passou a carregar mais SKU. Adensamento de linha, nao expansao de linha.
-- SUM(...) OVER (ORDER BY a.ano): com ORDER BY e sem PARTITION BY, a janela vai da
-- primeira linha ate a linha atual -- e a forma canonica do acumulado. Mostra se a
-- renovacao de portfolio esta expandindo ou apenas repondo o que sai.

-- #############################################################################
-- PERGUNTA 5 -- COBERTURA DE PORTFOLIO: onde o catalogo e ralo?
--   Cruzamento faixa de preco x faixa etaria, sobre os anos recentes (2018-2022),
--   que e a janela em que uma decisao de portfolio hoje faria sentido.
-- #############################################################################
WITH base_recente AS (
  SELECT f.sk_faixa_preco, f.sk_faixa_etaria
  FROM fato_sets AS f
  WHERE f.flag_tem_preco = 1
    AND f.sk_ano BETWEEN 2018 AND 2022
    AND f.sk_categoria = (SELECT sk_categoria FROM dim_categoria WHERE categoria = 'Normal')
    AND f.sk_faixa_etaria > 0
),
matriz AS (
  SELECT
    e.faixa_etaria, e.ordem_faixa AS ordem_idade,
    p.faixa_preco,  p.ordem_faixa AS ordem_preco,
    COUNT(*) AS sets
  FROM base_recente AS b
  INNER JOIN dim_faixa_etaria AS e ON e.sk_faixa_etaria = b.sk_faixa_etaria
  INNER JOIN dim_faixa_preco  AS p ON p.sk_faixa_preco  = b.sk_faixa_preco
  GROUP BY e.faixa_etaria, e.ordem_faixa, p.faixa_preco, p.ordem_faixa
)
SELECT
  faixa_etaria, faixa_preco, sets,
  ROUND(100.0 * sets / SUM(sets) OVER (PARTITION BY faixa_etaria), 1) AS share_na_idade_pct
FROM matriz
ORDER BY ordem_idade, ordem_preco;
-- RESULTADO (2018-2022, sets por celula): nucleo em 7-9 anos (639 sets) e 4-6 anos
-- (488, dos quais 58% abaixo de US$ 20). Os vazios sao o achado:
--   14-17 anos: 34 sets em cinco anos, e 32 deles custam US$ 50+  -> sem impulso
--   18+      : ZERO abaixo de US$ 20 e so 5 entre 20 e 50, contra 68 acima de 100
--   7-9 anos : ZERO acima de US$ 200 -> nao existe premium infantil
-- RESSALVA: agerange_min falta em 63,2% do catalogo e a cobertura oscila entre
-- 69,7% (2019) e 91,0% (2015) mesmo em sets 'Normal'. Celula vazia pode ser ausencia
-- de PRODUTO ou ausencia de DADO -- este dataset nao distingue. Ver docs/qualidade-do-dado.md.

-- 5b. Onde nao ha oferta nenhuma: combinacoes vazias (CROSS JOIN das duas dimensoes)
WITH grade AS (
  SELECT e.faixa_etaria, e.ordem_faixa AS ordem_idade,
         p.faixa_preco,  p.ordem_faixa AS ordem_preco
  FROM dim_faixa_etaria AS e
  CROSS JOIN dim_faixa_preco AS p
  WHERE e.sk_faixa_etaria > 0 AND p.sk_faixa_preco > 0
),
ofertado AS (
  SELECT f.sk_faixa_etaria, f.sk_faixa_preco, COUNT(*) AS sets
  FROM fato_sets AS f
  WHERE f.flag_tem_preco = 1 AND f.sk_ano BETWEEN 2018 AND 2022
    AND f.sk_categoria = (SELECT sk_categoria FROM dim_categoria WHERE categoria = 'Normal')
  GROUP BY 1, 2
)
SELECT g.faixa_etaria, g.faixa_preco, COALESCE(o.sets, 0) AS sets
FROM grade AS g
LEFT JOIN dim_faixa_etaria AS e ON e.faixa_etaria = g.faixa_etaria
LEFT JOIN dim_faixa_preco  AS p ON p.faixa_preco  = g.faixa_preco
LEFT JOIN ofertado         AS o ON o.sk_faixa_etaria = e.sk_faixa_etaria
                               AND o.sk_faixa_preco  = p.sk_faixa_preco
WHERE COALESCE(o.sets, 0) <= 5
ORDER BY g.ordem_idade, g.ordem_preco;
