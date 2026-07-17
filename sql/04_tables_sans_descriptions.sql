-- =====================================================================
-- 04 - Tables SANS descriptions (démo avant/après)
-- =====================================================================
-- Objectif : prouver que la différence vient DU CATALOGUE, pas des données.
--
-- Astuce clé : un CREATE TABLE AS SELECT copie les données et les types,
-- mais PAS les descriptions de colonnes. On obtient donc des tables
-- strictement identiques… et totalement muettes.
--
-- À comparer : agent/ask.py (avec catalogue) vs agent/demo_sans_catalogue.py
-- =====================================================================

CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.fact_ventes_nue` AS
SELECT * FROM `${PROJECT_ID}.${DATASET}.fact_ventes`;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_client_nue` AS
SELECT * FROM `${PROJECT_ID}.${DATASET}.dim_client`;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_date_nue` AS
SELECT * FROM `${PROJECT_ID}.${DATASET}.dim_date`;

-- Vérification : ces descriptions doivent toutes être NULL/vides.
SELECT table_name, column_name, description
FROM `${PROJECT_ID}.${DATASET}`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS
WHERE table_name IN ('fact_ventes_nue', 'dim_client_nue')
ORDER BY table_name, column_name;
