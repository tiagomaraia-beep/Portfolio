-- Carga das duas stagings a partir dos CSV de data/. Rodar de dentro de data/:
--   sqlite3 lego.db < ../sql/00-carga.sql
-- Tudo entra como TEXT de proposito (ver 01-qualidade-do-dado.sql, secao 0).
DROP TABLE IF EXISTS stg_lego_sets;
CREATE TABLE stg_lego_sets (
  set_id TEXT, name TEXT, year TEXT, theme TEXT, subtheme TEXT,
  themeGroup TEXT, category TEXT, pieces TEXT, minifigs TEXT,
  agerange_min TEXT, US_retailPrice TEXT, bricksetURL TEXT,
  thumbnailURL TEXT, imageURL TEXT);
DROP TABLE IF EXISTS stg_cpi;
CREATE TABLE stg_cpi (ano TEXT, cpi_u_media_anual TEXT,
                      fator_deflator_base2022 TEXT, cpi_toys_media_anual TEXT);
.mode csv
.import --skip 1 lego_sets.csv stg_lego_sets
.import --skip 1 cpi_us_anual.csv stg_cpi
