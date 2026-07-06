-- =====================================================================
-- POC Dataplex -> Agent conversationnel
-- 01 - Schéma en ÉTOILE (star schema) retail
-- =====================================================================
-- Grain de la table de faits : 1 ligne = 1 ligne de commande (produit x commande)
--
--                    dim_date
--                       |
--   dim_client ---- fact_ventes ---- dim_produit
--                       |
--                   dim_magasin
--
-- Remplace ${PROJECT_ID} et ${DATASET} avant exécution (les scripts le font via bq --parameter / sed).
-- =====================================================================

-- ------- DIMENSION DATE -------------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_date`
(
  date_key      INT64   NOT NULL,   -- clé technique AAAAMMJJ (ex: 20250131)
  full_date     DATE    NOT NULL,
  annee         INT64,
  trimestre     INT64,
  mois          INT64,
  mois_nom      STRING,
  jour_semaine  STRING,
  est_weekend   BOOL
);

-- ------- DIMENSION CLIENT -----------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_client`
(
  client_key    INT64  NOT NULL,   -- clé de substitution (surrogate key)
  client_id     STRING NOT NULL,   -- identifiant métier
  nom           STRING,
  segment       STRING,            -- Particulier / PME / Grand Compte
  ville         STRING,
  pays          STRING,
  statut        STRING             -- A=actif, I=inactif, P=prospect
);

-- ------- DIMENSION PRODUIT ----------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_produit`
(
  produit_key       INT64  NOT NULL,
  produit_id        STRING NOT NULL,
  libelle           STRING,
  categorie         STRING,        -- Informatique / Mobilier / Fournitures
  sous_categorie    STRING,
  marque            STRING,
  prix_unitaire_ref NUMERIC        -- prix catalogue HT de référence en EUR
);

-- ------- DIMENSION MAGASIN ----------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_magasin`
(
  magasin_key   INT64  NOT NULL,
  magasin_id    STRING NOT NULL,
  nom           STRING,
  region        STRING,
  type_magasin  STRING             -- Physique / Online
);

-- ------- FAIT : VENTES --------------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.fact_ventes`
(
  vente_id      STRING NOT NULL,   -- identifiant ligne de commande
  date_key      INT64  NOT NULL,   -- FK -> dim_date.date_key
  client_key    INT64  NOT NULL,   -- FK -> dim_client.client_key
  produit_key   INT64  NOT NULL,   -- FK -> dim_produit.produit_key
  magasin_key   INT64  NOT NULL,   -- FK -> dim_magasin.magasin_key
  quantite      INT64,
  mnt_ht        NUMERIC,           -- montant HT de la ligne (EUR)
  remise_pct    NUMERIC,           -- taux de remise appliqué (0..1)
  mnt_tva       NUMERIC,           -- montant TVA (EUR)
  mnt_ttc       NUMERIC            -- montant TTC (EUR)
);
