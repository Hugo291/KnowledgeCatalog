-- =====================================================================
-- 02 - Données de démonstration (générées procéduralement)
-- =====================================================================
-- Objectif : avoir un jeu de données réaliste sans fichier externe.
-- ~5 000 lignes de ventes sur 2024-2025, réparties sur les dimensions.
-- =====================================================================

-- ------- dim_date : tout 2024 + 2025 -----------------------------------
INSERT INTO `${PROJECT_ID}.${DATASET}.dim_date`
SELECT
  CAST(FORMAT_DATE('%Y%m%d', d) AS INT64)                     AS date_key,
  d                                                           AS full_date,
  EXTRACT(YEAR    FROM d)                                     AS annee,
  EXTRACT(QUARTER FROM d)                                     AS trimestre,
  EXTRACT(MONTH   FROM d)                                     AS mois,
  FORMAT_DATE('%B', d)                                        AS mois_nom,
  FORMAT_DATE('%A', d)                                        AS jour_semaine,
  EXTRACT(DAYOFWEEK FROM d) IN (1, 7)                         AS est_weekend
FROM UNNEST(GENERATE_DATE_ARRAY('2024-01-01', '2025-12-31')) AS d;

-- ------- dim_client ----------------------------------------------------
INSERT INTO `${PROJECT_ID}.${DATASET}.dim_client`
SELECT
  k                                                           AS client_key,
  FORMAT('CLI%05d', k)                                        AS client_id,
  ['Durand SA','Martin & Fils','Petit Bureau','Groupe Lefort','Rey Solutions',
   'Atelier Nord','Cabinet Ober','Studio Vasseur','Mairie de Lys','Ecole Ampère'][OFFSET(MOD(k, 10))] AS nom,
  ['Particulier','PME','Grand Compte'][OFFSET(MOD(k, 3))]     AS segment,
  ['Paris','Lyon','Lille','Bordeaux','Nantes','Toulouse'][OFFSET(MOD(k, 6))] AS ville,
  'France'                                                    AS pays,
  ['A','A','A','I','P'][OFFSET(MOD(k, 5))]                    AS statut  -- majoritairement actifs
FROM UNNEST(GENERATE_ARRAY(1, 200)) AS k;

-- ------- dim_produit ---------------------------------------------------
INSERT INTO `${PROJECT_ID}.${DATASET}.dim_produit`
SELECT
  k                                                           AS produit_key,
  FORMAT('PRD%04d', k)                                        AS produit_id,
  CONCAT(['Ordinateur','Écran','Chaise','Bureau','Stylo','Ramette','Casque','Clavier'][OFFSET(MOD(k, 8))],
         ' modèle ', CAST(k AS STRING))                       AS libelle,
  ['Informatique','Informatique','Mobilier','Mobilier','Fournitures','Fournitures','Informatique','Informatique'][OFFSET(MOD(k, 8))] AS categorie,
  ['Portables','Périphériques','Sièges','Plans de travail','Écriture','Papier','Audio','Saisie'][OFFSET(MOD(k, 8))] AS sous_categorie,
  ['Dell','LG','Steelcase','IKEA','Bic','Clairefontaine','Sony','Logitech'][OFFSET(MOD(k, 8))] AS marque,
  CAST(ROUND(10 + MOD(k * 37, 900), 2) AS NUMERIC)           AS prix_unitaire_ref
FROM UNNEST(GENERATE_ARRAY(1, 80)) AS k;

-- ------- dim_magasin ---------------------------------------------------
INSERT INTO `${PROJECT_ID}.${DATASET}.dim_magasin`
SELECT
  k                                                           AS magasin_key,
  FORMAT('MAG%03d', k)                                        AS magasin_id,
  ['Boutique Paris Centre','Boutique Lyon Part-Dieu','Boutique Lille Grand Place',
   'Entrepôt Web FR','Boutique Bordeaux Lac','Boutique Nantes Atlantis'][OFFSET(MOD(k, 6))] AS nom,
  ['Île-de-France','Auvergne-Rhône-Alpes','Hauts-de-France','National','Nouvelle-Aquitaine','Pays de la Loire'][OFFSET(MOD(k, 6))] AS region,
  IF(MOD(k, 6) = 3, 'Online', 'Physique')                    AS type_magasin
FROM UNNEST(GENERATE_ARRAY(1, 6)) AS k;

-- ------- fact_ventes : ~5000 lignes ------------------------------------
INSERT INTO `${PROJECT_ID}.${DATASET}.fact_ventes`
WITH gen AS (
  SELECT
    i,
    -- FK pseudo-aléatoires mais déterministes
    1 + MOD(ABS(FARM_FINGERPRINT(CAST(i AS STRING))),        200) AS client_key,
    1 + MOD(ABS(FARM_FINGERPRINT(CAST(i+7 AS STRING))),       80) AS produit_key,
    1 + MOD(ABS(FARM_FINGERPRINT(CAST(i+13 AS STRING))),       6) AS magasin_key,
    DATE_ADD('2024-01-01', INTERVAL MOD(ABS(FARM_FINGERPRINT(CAST(i+3 AS STRING))), 730) DAY) AS d,
    1 + MOD(ABS(FARM_FINGERPRINT(CAST(i+5 AS STRING))),       10) AS quantite,
    ROUND(MOD(ABS(FARM_FINGERPRINT(CAST(i+9 AS STRING))), 30) / 100, 2) AS remise
  FROM UNNEST(GENERATE_ARRAY(1, 5000)) AS i
)
SELECT
  FORMAT('V%08d', i)                                          AS vente_id,
  CAST(FORMAT_DATE('%Y%m%d', d) AS INT64)                     AS date_key,
  client_key,
  produit_key,
  magasin_key,
  quantite,
  CAST(ROUND(p.prix_unitaire_ref * quantite * (1 - remise), 2) AS NUMERIC)     AS mnt_ht,
  CAST(remise AS NUMERIC)                                      AS remise_pct,
  CAST(ROUND(p.prix_unitaire_ref * quantite * (1 - remise) * 0.20, 2) AS NUMERIC) AS mnt_tva,
  CAST(ROUND(p.prix_unitaire_ref * quantite * (1 - remise) * 1.20, 2) AS NUMERIC) AS mnt_ttc
FROM gen
JOIN `${PROJECT_ID}.${DATASET}.dim_produit` p USING (produit_key);
