-- Pergunta: o preco do catalogo subiu de verdade, ou so acompanhou a inflacao?
-- Fonte: esquema estrela em data/lego.db + data/cpi_us_anual.csv (BLS, CUUR0000SA0 e
--        CUUR0000SERE01, media anual). Dialeto: SQLite.
--
-- Este arquivo refaz em DOLARES CONSTANTES DE 2022 toda serie de preco que os arquivos
-- 01 a 03 responderam em dolar corrente. A coluna nominal fica sempre ao lado: a
-- comparacao nominal x real E o achado, nao uma substituicao.
--
-- COMO A DEFLACAO FOI FEITA -- a decisao importante:
--   fato_sets.vl_preco_usd_2022 = vl_preco_usd * dim_calendario.fator_deflator_base2022
--   calculado LINHA A LINHA, na carga, pelo fator do ano de lancamento do proprio set.
--   Nao e uma medida: e um fato aditivo expresso em outra unidade, igual a guardar um
--   valor em moeda local e em moeda de reporte. Deflacionar linha a linha importa porque
--   SUM(preco * fator) != SUM(preco) * AVG(fator) -- a secao 1c abaixo mede o erro.
--   fator_deflator_base2022 = CPI-U de 2022 / CPI-U do ano. Em 2022 o fator e 1,0 e o
--   preco real e identico ao nominal, o que serve de checagem.


-- #############################################################################
-- 0. CARGA DO CPI E EXTENSAO DA DIMENSAO DE TEMPO
-- #############################################################################
-- CREATE TABLE stg_cpi (ano TEXT, cpi_u_media_anual TEXT,
--                       fator_deflator_base2022 TEXT, cpi_toys_media_anual TEXT);
-- .mode csv
-- .import --skip 1 data/cpi_us_anual.csv stg_cpi

-- Checagem de cobertura ANTES de juntar: todo ano do calendario tem CPI e vice-versa?
SELECT
  (SELECT COUNT(*) FROM stg_cpi)                                                    AS linhas_cpi,
  (SELECT COUNT(*) FROM dim_calendario)                                             AS anos_calendario,
  (SELECT COUNT(*) FROM dim_calendario c
     LEFT JOIN stg_cpi p ON CAST(p.ano AS INTEGER)=c.ano WHERE p.ano IS NULL)       AS ano_sem_cpi,
  (SELECT COUNT(*) FROM stg_cpi p
     LEFT JOIN dim_calendario c ON c.ano=CAST(p.ano AS INTEGER) WHERE c.ano IS NULL) AS cpi_sem_ano;
-- RESULTADO: 53 | 53 | 0 | 0. Casamento 1:1 perfeito, nenhum LEFT JOIN vira NULL.

-- O fator entregue pela fonte confere com CPI(2022)/CPI(ano)?
SELECT COUNT(*) AS anos_com_fator_divergente
FROM dim_calendario
WHERE ABS(fator_deflator_base2022
        - (SELECT cpi_u_media_anual FROM dim_calendario WHERE ano=2022) / cpi_u_media_anual) > 0.00001;
-- RESULTADO: 0. O fator nao foi aceito de boca: foi recalculado e bateu nos 53 anos.
-- Referencia: CPI-U 2007 = 207,342 e 2022 = 292,655, logo fator 2007 = 1,41146.


-- #############################################################################
-- 1. PERGUNTA 1 REFEITA -- PRECO POR PECA, NOMINAL x REAL
--    Escopo oficial: flag_escopo_pricing = 1 (Normal, com preco, >= 20 pecas, 2007+).
-- #############################################################################
WITH agregado_ano AS (
  SELECT
    f.sk_ano                                   AS ano,
    COUNT(*)                                   AS sets,
    SUM(f.vl_preco_usd)      / SUM(f.qt_pecas) AS ppp_nominal,
    SUM(f.vl_preco_usd_2022) / SUM(f.qt_pecas) AS ppp_real,
    AVG(f.vl_preco_usd)                        AS set_nominal,
    AVG(f.vl_preco_usd_2022)                   AS set_real,
    AVG(CAST(f.qt_pecas AS REAL))              AS pecas_medias
  FROM fato_sets AS f
  WHERE f.flag_escopo_pricing = 1
  GROUP BY f.sk_ano
)
SELECT
  ano, sets,
  ROUND(ppp_nominal, 4) AS ppp_nominal,
  ROUND(ppp_real,    4) AS ppp_real,
  ROUND(100.0 * ppp_nominal / FIRST_VALUE(ppp_nominal) OVER (ORDER BY ano), 1) AS indice_nominal,
  ROUND(100.0 * ppp_real    / FIRST_VALUE(ppp_real)    OVER (ORDER BY ano), 1) AS indice_real,
  ROUND(set_nominal, 2) AS set_medio_nominal,
  ROUND(set_real,    2) AS set_medio_real,
  ROUND(pecas_medias, 0) AS pecas_medias
FROM agregado_ano
ORDER BY ano;
-- FIRST_VALUE(...) OVER (ORDER BY ano): sem PARTITION BY a janela e a serie inteira e o
-- ORDER BY fixa 2007 como base 100 das DUAS series, que e o que permite le-las no mesmo
-- grafico. As duas usam a mesma janela; so muda a coluna de dentro.
--
-- RESULTADO (apurado 2026-09-20) -- a virada da leitura:
--   ano    ppp nom  ppp real  idx nom  idx real  set nom  set real  pecas
--   2007    0,0986    0,1392    100,0     100,0    38,89     54,89    394
--   2013    0,1340    0,1684    136,0     121,0    46,67     58,63    348
--   2017    0,1045    0,1248    106,0      89,6    46,98     56,09    450
--   2021    0,0964    0,1042     97,8      74,8    58,73     63,43    609
--   2022    0,1025    0,1025    103,9      73,6    67,96     67,96    663
-- Em nominal o preco por peca sobe 3,9% em 15 anos. Em dolares de 2022 ele CAI 26,4%.
-- O set medio sobe 74,8% nominal mas so 23,8% real (54,89 -> 67,96) -- e ganha 68,3%
-- de pecas. LEITURA: o comprador de 2022 paga 24% mais em poder de compra por um set
-- 68% maior. O tijolo ficou mais barato; a cesta ficou maior.

-- 1b. Agregado do periodo inteiro
SELECT
  COUNT(*)                                          AS sets,
  ROUND(SUM(vl_preco_usd),      2)                  AS lista_nominal,
  ROUND(SUM(vl_preco_usd_2022), 2)                  AS lista_real_2022,
  ROUND(SUM(vl_preco_usd)      / SUM(qt_pecas), 4)  AS ppp_nominal,
  ROUND(SUM(vl_preco_usd_2022) / SUM(qt_pecas), 4)  AS ppp_real,
  ROUND(AVG(vl_preco_usd),      2)                  AS set_medio_nominal,
  ROUND(AVG(vl_preco_usd_2022), 2)                  AS set_medio_real
FROM fato_sets
WHERE flag_escopo_pricing = 1;
-- RESULTADO: 4626 sets | lista 214.853,10 nominal / 255.395,21 em USD de 2022
--            ppp 0,1082 nominal / 0,1286 real | set medio 46,44 / 55,21

-- 1c. POR QUE DEFLACIONAR LINHA A LINHA, e nao no fim
--     Dentro de UM ano o fator e constante, entao tanto faz. No AGREGADO de varios
--     anos, nao: aplicar um fator medio ao total nominal da numero errado.
SELECT
  ROUND(SUM(vl_preco_usd_2022) / SUM(qt_pecas), 4)  AS certo_linha_a_linha,
  ROUND(SUM(vl_preco_usd)      / SUM(qt_pecas), 4)  AS nominal,
  ROUND( (SUM(vl_preco_usd) / SUM(qt_pecas))
       * (SELECT AVG(fator_deflator_base2022) FROM dim_calendario WHERE ano BETWEEN 2007 AND 2022), 4)
                                                    AS errado_fator_medio
FROM fato_sets
WHERE flag_escopo_pricing = 1;
-- RESULTADO: certo 0,1286 | nominal 0,1082 | errado 0,1333 -- 3,7% de erro.
-- E a mesma familia de erro de "media das razoes": a media do fator ignora que os anos
-- tem pesos diferentes no total. Por isso a deflacao mora na FATO, nao numa medida DAX.


-- #############################################################################
-- 2. ANALISE SECUNDARIA -- LEGO CONTRA O CPI DE BRINQUEDOS
--    LER A RESSALVA em docs/qualidade-do-dado.md antes de citar este numero.
-- #############################################################################
WITH ppp AS (
  SELECT f.sk_ano AS ano,
         SUM(f.vl_preco_usd)      / SUM(f.qt_pecas) AS nominal,
         SUM(f.vl_preco_usd_2022) / SUM(f.qt_pecas) AS real_2022
  FROM fato_sets AS f WHERE f.flag_escopo_pricing = 1 GROUP BY f.sk_ano
),
pontas AS (
  SELECT
    (SELECT nominal   FROM ppp WHERE ano=2007) AS n07, (SELECT nominal   FROM ppp WHERE ano=2022) AS n22,
    (SELECT real_2022 FROM ppp WHERE ano=2007) AS r07, (SELECT real_2022 FROM ppp WHERE ano=2022) AS r22,
    (SELECT cpi_toys_media_anual FROM dim_calendario WHERE ano=2007) AS t07,
    (SELECT cpi_toys_media_anual FROM dim_calendario WHERE ano=2022) AS t22,
    (SELECT cpi_u_media_anual    FROM dim_calendario WHERE ano=2007) AS c07,
    (SELECT cpi_u_media_anual    FROM dim_calendario WHERE ano=2022) AS c22
)
SELECT
  ROUND(100.0 * (c22/c07 - 1), 1)                       AS cpi_geral_pct,
  ROUND(100.0 * (n22/n07 - 1), 1)                       AS lego_ppp_nominal_pct,
  ROUND(100.0 * (r22/r07 - 1), 1)                       AS lego_ppp_real_pct,
  ROUND(100.0 * (t22/t07 - 1), 1)                       AS cpi_brinquedos_nominal_pct,
  ROUND(100.0 * ((t22/t07)/(c22/c07) - 1), 1)           AS cpi_brinquedos_real_pct,
  ROUND(100.0 * ((n22/n07)/(t22/t07) - 1), 1)           AS lego_vs_brinquedos_nominal_pct,
  ROUND(100.0 * ((r22/r07)/((t22/t07)/(c22/c07)) - 1), 1) AS lego_vs_brinquedos_real_pct
FROM pontas;
-- RESULTADO 2007->2022: CPI geral +41,1% | LEGO ppp +3,9% nominal e -26,4% real
--                       CPI brinquedos -57,9% nominal e -70,2% real
--                       LEGO x brinquedos: +147,2% -- IDENTICO nas duas bases, porque
--                       o CPI-U cancela na razao. Isso e checagem, nao coincidencia.
-- LEITURA: a LEGO barateou 26% em poder de compra, mas a categoria barateou 70%. Contra
-- a propria categoria a LEGO ENCARECEU cerca de 147%.
-- RESSALVA OBRIGATORIA: o CPI de brinquedos (CUUR0000SERE01) e ajustado hedonicamente e
-- e dominado por eletronico e videogame, cuja qualidade por dolar explodiu no periodo.
-- Ele cobre "brinquedos" em geral, nao set de construcao. Nosso "preco por peca" e uma
-- correcao de qualidade tosca (peca como proxy) e NAO e a mesma coisa que hedonia do BLS.
-- O numero indica direcao, nao magnitude. Ver docs/qualidade-do-dado.md secao 11.

-- 2b. As quatro curvas indexadas em 2007 = 100 (insumo do grafico de linha)
WITH ppp AS (
  SELECT f.sk_ano AS ano, SUM(f.vl_preco_usd)/SUM(f.qt_pecas) AS nominal
  FROM fato_sets AS f WHERE f.flag_escopo_pricing = 1 GROUP BY f.sk_ano
)
SELECT
  p.ano,
  ROUND(100.0 * p.nominal / (SELECT nominal FROM ppp WHERE ano=2007), 1)                       AS lego_nominal,
  ROUND(100.0 * (p.nominal * c.fator_deflator_base2022)
              / ((SELECT nominal FROM ppp WHERE ano=2007)
                 * (SELECT fator_deflator_base2022 FROM dim_calendario WHERE ano=2007)), 1)    AS lego_real,
  ROUND(100.0 * c.cpi_toys_media_anual
              / (SELECT cpi_toys_media_anual FROM dim_calendario WHERE ano=2007), 1)           AS cpi_brinquedos,
  ROUND(100.0 * c.cpi_u_media_anual
              / (SELECT cpi_u_media_anual FROM dim_calendario WHERE ano=2007), 1)              AS cpi_geral
FROM ppp AS p
INNER JOIN dim_calendario AS c ON c.sk_ano = p.ano
ORDER BY p.ano;
-- RESULTADO (pontas): 2007 todas em 100,0
--   2022: LEGO nominal 103,9 | LEGO real 73,6 | CPI brinquedos 42,1 | CPI geral 141,1


-- #############################################################################
-- 3. PERGUNTA 3 REFEITA -- ESCADA DE PRECOS
--    CORRECAO DE ESCOPO: a versao anterior de docs/achados.md respondeu esta pergunta
--    sobre "categoria Normal + com preco" (168 sets em 2007), enquanto o resto da peca
--    usa flag_escopo_pricing (153 sets em 2007). Diferenca: os sets de menos de 20 pecas.
--    A partir daqui vale o ESCOPO OFICIAL. A comparacao entre os dois esta em 3a.
-- #############################################################################

-- 3a. O tamanho exato da divergencia de escopo
WITH escopo_antigo AS (
  SELECT f.sk_ano AS ano, f.vl_preco_usd AS v,
         ROW_NUMBER() OVER (PARTITION BY f.sk_ano ORDER BY f.vl_preco_usd) AS pos,
         COUNT(*)     OVER (PARTITION BY f.sk_ano)                         AS tot
  FROM fato_sets AS f
  WHERE f.flag_tem_preco = 1 AND f.sk_ano >= 2007
    AND f.sk_categoria = (SELECT sk_categoria FROM dim_categoria WHERE categoria='Normal')
),
escopo_oficial AS (
  SELECT f.sk_ano AS ano, f.vl_preco_usd AS v,
         ROW_NUMBER() OVER (PARTITION BY f.sk_ano ORDER BY f.vl_preco_usd) AS pos,
         COUNT(*)     OVER (PARTITION BY f.sk_ano)                         AS tot
  FROM fato_sets AS f WHERE f.flag_escopo_pricing = 1
)
SELECT 'Normal + com preco (ANTIGO)' AS escopo,
       (SELECT MAX(tot) FROM escopo_antigo WHERE ano=2007) AS sets_2007,
       (SELECT ROUND(AVG(CASE WHEN pos IN ((tot+1)/2,(tot+2)/2) THEN v END),2) FROM escopo_antigo WHERE ano=2007) AS mediana_2007,
       (SELECT MAX(tot) FROM escopo_antigo WHERE ano=2022) AS sets_2022,
       (SELECT ROUND(AVG(CASE WHEN pos IN ((tot+1)/2,(tot+2)/2) THEN v END),2) FROM escopo_antigo WHERE ano=2022) AS mediana_2022
UNION ALL
SELECT 'flag_escopo_pricing (OFICIAL)',
       (SELECT MAX(tot) FROM escopo_oficial WHERE ano=2007),
       (SELECT ROUND(AVG(CASE WHEN pos IN ((tot+1)/2,(tot+2)/2) THEN v END),2) FROM escopo_oficial WHERE ano=2007),
       (SELECT MAX(tot) FROM escopo_oficial WHERE ano=2022),
       (SELECT ROUND(AVG(CASE WHEN pos IN ((tot+1)/2,(tot+2)/2) THEN v END),2) FROM escopo_oficial WHERE ano=2022);
-- RESULTADO: ANTIGO  168 sets em 2007, mediana 24,99 -> 388 sets em 2022, mediana 39,99 (+60,0%)
--            OFICIAL 153 sets em 2007, mediana 29,99 -> 373 sets em 2022, mediana 39,99 (+33,3%)
-- A conclusao qualitativa (a mediana subiu) nao muda; a magnitude quase dobra. Os 15
-- sets de 2007 que o escopo antigo incluia sao de menos de 20 pecas -- baratos por
-- construcao, e o mesmo lixo de denominador que o corte de pecas existe para remover.

-- 3b. Mediana e media por ano, nominal x real, escopo oficial
WITH ordenado AS (
  SELECT f.sk_ano AS ano, f.vl_preco_usd AS v, f.vl_preco_usd_2022 AS r,
         ROW_NUMBER() OVER (PARTITION BY f.sk_ano ORDER BY f.vl_preco_usd) AS pos,
         COUNT(*)     OVER (PARTITION BY f.sk_ano)                         AS tot
  FROM fato_sets AS f WHERE f.flag_escopo_pricing = 1
)
-- Deflacionar preserva a ORDEM dentro de um ano (o fator e o mesmo para todos os sets
-- daquele ano), entao a linha do meio e a mesma nas duas series -- e correto reusar a
-- mesma posicao para achar a mediana nominal e a real.
SELECT
  ano, MAX(tot) AS sets,
  ROUND(AVG(CASE WHEN pos IN ((tot+1)/2,(tot+2)/2) THEN v END), 2) AS mediana_nominal,
  ROUND(AVG(CASE WHEN pos IN ((tot+1)/2,(tot+2)/2) THEN r END), 2) AS mediana_real,
  ROUND(AVG(v), 2) AS media_nominal,
  ROUND(AVG(r), 2) AS media_real
FROM ordenado GROUP BY ano ORDER BY ano;
-- RESULTADO (pontas): 2007 mediana 29,99 nominal / 42,33 real | media 38,89 / 54,89
--                     2022 mediana 39,99 / 39,99              | media 67,96 / 67,96
-- LEITURA: em poder de compra a mediana CAIU 5,5% (42,33 -> 39,99) enquanto a media
-- SUBIU 23,8%. O set tipico nao ficou mais caro: a cauda de cima e que engordou.

-- 3c. Escada NOMINAL -- a arquitetura de precos como o comprador via na epoca
WITH faixas AS (
  SELECT f.sk_ano AS ano, p.ordem_faixa AS ordem
  FROM fato_sets AS f
  INNER JOIN dim_faixa_preco AS p ON p.sk_faixa_preco = f.sk_faixa_preco
  WHERE f.flag_escopo_pricing = 1
),
contagem AS (
  SELECT ano, ordem, COUNT(*) AS sets, SUM(COUNT(*)) OVER (PARTITION BY ano) AS total_ano
  FROM faixas GROUP BY ano, ordem
)
SELECT
  ano, MAX(total_ano) AS sets,
  MAX(CASE WHEN ordem=1 THEN ROUND(100.0*sets/total_ano,1) END) AS ate_10,
  MAX(CASE WHEN ordem=2 THEN ROUND(100.0*sets/total_ano,1) END) AS f10_20,
  MAX(CASE WHEN ordem=3 THEN ROUND(100.0*sets/total_ano,1) END) AS f20_50,
  MAX(CASE WHEN ordem=4 THEN ROUND(100.0*sets/total_ano,1) END) AS f50_100,
  MAX(CASE WHEN ordem=5 THEN ROUND(100.0*sets/total_ano,1) END) AS f100_200,
  MAX(CASE WHEN ordem=6 THEN ROUND(100.0*sets/total_ano,1) END) AS f200_mais
FROM contagem GROUP BY ano ORDER BY ano;
-- SUM(COUNT(*)) OVER (PARTITION BY ano): agregacao dentro de janela -- o COUNT(*) roda
-- primeiro (GROUP BY ano, ordem) e a janela soma esses COUNTs dentro do ano, dando o
-- denominador correto sem uma segunda passada na fato.
-- RESULTADO: ate US$ 9,99 26,8% (2007) -> 11,3% (2022)
--            US$ 100+     4,0% (2007) -> 14,5% (2022)
--            US$ 50+     17,7% (2007) -> 37,8% (2022)

-- 3d. Escada REAL -- as mesmas faixas aplicadas ao preco em USD de 2022
WITH faixas_reais AS (
  SELECT f.sk_ano AS ano,
    CASE
      WHEN f.vl_preco_usd_2022 <  10 THEN 1 WHEN f.vl_preco_usd_2022 <  20 THEN 2
      WHEN f.vl_preco_usd_2022 <  50 THEN 3 WHEN f.vl_preco_usd_2022 < 100 THEN 4
      WHEN f.vl_preco_usd_2022 < 200 THEN 5 ELSE 6
    END AS ordem
  FROM fato_sets AS f WHERE f.flag_escopo_pricing = 1
),
contagem AS (
  SELECT ano, ordem, COUNT(*) AS sets, SUM(COUNT(*)) OVER (PARTITION BY ano) AS total_ano
  FROM faixas_reais GROUP BY ano, ordem
)
SELECT
  ano, MAX(total_ano) AS sets,
  MAX(CASE WHEN ordem=1 THEN ROUND(100.0*sets/total_ano,1) END) AS ate_10,
  MAX(CASE WHEN ordem=2 THEN ROUND(100.0*sets/total_ano,1) END) AS f10_20,
  MAX(CASE WHEN ordem=3 THEN ROUND(100.0*sets/total_ano,1) END) AS f20_50,
  MAX(CASE WHEN ordem=4 THEN ROUND(100.0*sets/total_ano,1) END) AS f50_100,
  MAX(CASE WHEN ordem=5 THEN ROUND(100.0*sets/total_ano,1) END) AS f100_200,
  MAX(CASE WHEN ordem=6 THEN ROUND(100.0*sets/total_ano,1) END) AS f200_mais
FROM contagem GROUP BY ano ORDER BY ano;
-- RESULTADO: ate US$ 9,99 de 2022  9,8% (2007) -> 11,3% (2022)  -- praticamente estavel
--            US$ 100+ de 2022     10,5% (2007) -> 14,5% (2022)
--            US$ 50+  de 2022     38,6% (2007) -> 37,8% (2022)  -- ESTAVEL
-- LEITURA: a migracao da escada NOMINAL (17,7% -> 37,8% acima de US$ 50) desaparece
-- quase por inteiro quando se mede em poder de compra constante (38,6% -> 37,8%).
-- Em 2007, um set de US$ 35 ja era um set de US$ 50 de hoje. O que mudou foi o NUMERO
-- na etiqueta, nao a posicao do produto na carteira do comprador.
-- QUAL DAS DUAS VALE: as duas, para perguntas diferentes.
--   - arquitetura de preco / ponto psicologico .99  -> escada NOMINAL (ninguem
--     deflaciona uma etiqueta; 98,8% dos precos terminam em .99 em dolar corrente)
--   - o produto ficou mais caro para o comprador?   -> escada REAL


-- #############################################################################
-- 4. PERGUNTA 2 REFEITA -- PREMIO DE LICENCA usando dim_faixa_tamanho
--    A faixa de tamanho agora e dimensao conformada, nao CASE repetido em cada query
--    nem coluna derivada no Power Query.
-- #############################################################################
WITH ppp_faixa AS (
  SELECT
    d.faixa_tamanho, d.ordem_faixa, t.flag_licenciado,
    COUNT(*)                                  AS sets,
    SUM(f.vl_preco_usd_2022)/SUM(f.qt_pecas)  AS ppp_real
  FROM fato_sets AS f
  INNER JOIN dim_tema          AS t ON t.sk_tema          = f.sk_tema
  INNER JOIN dim_faixa_tamanho AS d ON d.sk_faixa_tamanho = f.sk_faixa_tamanho
  WHERE f.flag_escopo_pricing = 1
  GROUP BY d.faixa_tamanho, d.ordem_faixa, t.flag_licenciado
)
SELECT
  faixa_tamanho,
  MAX(CASE WHEN flag_licenciado=1 THEN sets END)                     AS sets_licenciados,
  MAX(CASE WHEN flag_licenciado=0 THEN sets END)                     AS sets_proprios,
  ROUND(MAX(CASE WHEN flag_licenciado=1 THEN ppp_real END), 4)       AS ppp_real_licenciado,
  ROUND(MAX(CASE WHEN flag_licenciado=0 THEN ppp_real END), 4)       AS ppp_real_proprio,
  ROUND(100.0 * (MAX(CASE WHEN flag_licenciado=1 THEN ppp_real END)
               / MAX(CASE WHEN flag_licenciado=0 THEN ppp_real END) - 1), 1) AS premio_pct
FROM ppp_faixa
GROUP BY faixa_tamanho, ordem_faixa
ORDER BY ordem_faixa;
-- RESULTADO -- premio nominal x real por faixa:
--   faixa                 nominal   real
--   Ate 99 pecas           -36,4%  -39,2%
--   100 a 249              -12,9%  -16,5%
--   250 a 499               -1,8%   -4,7%
--   500 a 999               -1,1%   -3,1%
--   1.000 ou mais          +22,9%  +23,8%
--
-- POR QUE O REAL DIFERE DO NOMINAL AQUI -- e o cuidado mais fino do arquivo.
-- DENTRO DE UM UNICO ANO o premio e identico nas duas bases, porque os dois lados
-- levam o mesmo fator e ele cancela na razao. Conferido:
--   2013 -24,2% / -24,2% | 2017 -10,3% / -10,3% | 2021 +24,5% / +24,5% | 2022 +17,5% / +17,5%
-- Mas estas faixas agregam 16 ANOS, e os dois lados nao tem a mesma distribuicao no
-- tempo: o set licenciado e sistematicamente MAIS NOVO (ano medio 2016,3 a 2017,4)
-- que o proprio (2014,3 a 2015,5). Deflacionar levanta mais o lado velho, entao o
-- "desconto" do licenciado aprofunda. A excecao prova a regra: na faixa de 1.000+
-- pecas os anos medios praticamente empatam (2017,0 x 2017,1) e o premio quase nao
-- se move (22,9% -> 23,8%).
-- CONCLUSAO PRATICA: deflacionar NAO altera comparacao entre grupos no MESMO ano; altera
-- qualquer agregado multi-ano em que os grupos tenham composicao temporal diferente.
-- Todo numero de premio citado fora de um ano especifico precisa dizer em que base esta.


-- #############################################################################
-- 5. flag_preco_99 -- o ponto psicologico como numero vivo, nao como frase
-- #############################################################################
SELECT
  c.rotulo_decada,
  SUM(f.flag_tem_preco)                                                    AS sets_com_preco,
  SUM(f.flag_preco_99)                                                     AS termina_em_99,
  ROUND(100.0 * SUM(f.flag_preco_99) / NULLIF(SUM(f.flag_tem_preco),0), 1) AS pct_99,
  COUNT(DISTINCT f.vl_preco_usd)                                           AS pontos_de_preco
FROM fato_sets AS f
INNER JOIN dim_calendario AS c ON c.sk_ano = f.sk_ano
GROUP BY c.decada, c.rotulo_decada
HAVING SUM(f.flag_tem_preco) > 0
ORDER BY c.decada;
-- RESULTADO: decada   com preco  termina .99   pct    pontos de preco
--            1990s           15           14   93,3%          9
--            2000s        1.115        1.080   96,9%         63
--            2010s        4.318        4.295   99,5%         98
--            2020s        1.534        1.508   98,3%         82
-- Catalogo inteiro: 6.897 de 6.982 (98,8%) e apenas 141 pontos de preco distintos.
-- A disciplina de ponto psicologico AUMENTOU com o tempo (96,9% -> 99,5%), o que
-- reforca a leitura de que a escada NOMINAL e a arquitetura deliberada.
