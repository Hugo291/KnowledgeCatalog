-- =====================================================================
-- POC Dataplex -> Agent conversationnel
-- 01 - Schéma en ÉTOILE (star schema) retail + DESCRIPTIONS (catalogue)
-- =====================================================================
-- Grain de la table de faits : 1 ligne = 1 ligne de commande (produit x commande)
--
--                    dim_date
--                       |
--   dim_client ---- fact_ventes ---- dim_produit
--                       |
--                   dim_magasin
--
-- ⭐ Les descriptions (OPTIONS(description=...)) sont posées DIRECTEMENT dans
-- le CREATE : c'est le "catalogue" que l'agent lit, et ça évite la limite de
-- débit BigQuery sur les mises à jour de métadonnées (1 seule opération/table).
--
-- Remplace ${PROJECT_ID} et ${DATASET} avant exécution (les scripts le font).
-- =====================================================================

-- ------- DIMENSION DATE -------------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_date`
(
  date_key      INT64   NOT NULL OPTIONS(description="Clé calendrier au format entier AAAAMMJJ."),
  full_date     DATE             OPTIONS(description="Date réelle (type DATE)."),
  annee         INT64            OPTIONS(description="Année (ex: 2025)."),
  trimestre     INT64            OPTIONS(description="Trimestre 1 à 4."),
  mois          INT64            OPTIONS(description="Numéro de mois 1 à 12."),
  mois_nom      STRING           OPTIONS(description="Nom du mois."),
  jour_semaine  STRING           OPTIONS(description="Jour de la semaine."),
  est_weekend   BOOL             OPTIONS(description="Vrai si le jour est un samedi ou dimanche.")
)
OPTIONS(description="Dimension DATE (calendrier). Une ligne par jour de 2024 à 2025. Jointure via date_key = fact_ventes.date_key.");

-- ------- DIMENSION CLIENT -----------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_client`
(
  client_key  INT64  NOT NULL OPTIONS(description="Clé de substitution (surrogate key) du client."),
  client_id   STRING NOT NULL OPTIONS(description="Identifiant métier du client (ex: CLI00042)."),
  nom         STRING          OPTIONS(description="Raison sociale du client."),
  segment     STRING          OPTIONS(description="Segment commercial: Particulier, PME ou Grand Compte."),
  ville       STRING          OPTIONS(description="Ville du client."),
  pays        STRING          OPTIONS(description="Pays du client."),
  statut      STRING          OPTIONS(description="Statut du client. Valeurs possibles: A = actif, I = inactif, P = prospect. UN CLIENT ACTIF a statut = 'A'.")
)
OPTIONS(description="Dimension CLIENT. Une ligne par client. Jointure via client_key = fact_ventes.client_key.");

-- ------- DIMENSION PRODUIT ----------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_produit`
(
  produit_key       INT64  NOT NULL OPTIONS(description="Clé de substitution du produit."),
  produit_id        STRING NOT NULL OPTIONS(description="Identifiant métier du produit (ex: PRD0012)."),
  libelle           STRING          OPTIONS(description="Libellé commercial du produit."),
  categorie         STRING          OPTIONS(description="Catégorie: Informatique, Mobilier ou Fournitures."),
  sous_categorie    STRING          OPTIONS(description="Sous-catégorie produit."),
  marque            STRING          OPTIONS(description="Marque du produit."),
  prix_unitaire_ref NUMERIC         OPTIONS(description="Prix catalogue HT de référence en EUR (avant remise).")
)
OPTIONS(description="Dimension PRODUIT (catalogue). Une ligne par produit. Jointure via produit_key = fact_ventes.produit_key.");

-- ------- DIMENSION MAGASIN ----------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.dim_magasin`
(
  magasin_key   INT64  NOT NULL OPTIONS(description="Clé de substitution du magasin."),
  magasin_id    STRING NOT NULL OPTIONS(description="Identifiant métier du magasin (ex: MAG003)."),
  nom           STRING          OPTIONS(description="Nom du point de vente."),
  region        STRING          OPTIONS(description="Région administrative du magasin."),
  type_magasin  STRING          OPTIONS(description="Canal: Physique (boutique) ou Online (site web).")
)
OPTIONS(description="Dimension MAGASIN / canal de vente. Une ligne par point de vente. Jointure via magasin_key = fact_ventes.magasin_key.");

-- ------- FAIT : VENTES --------------------------------------------------
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.fact_ventes`
(
  vente_id      STRING NOT NULL OPTIONS(description="Identifiant unique de la ligne de commande."),
  date_key      INT64  NOT NULL OPTIONS(description="Clé étrangère vers dim_date. Format entier AAAAMMJJ."),
  client_key    INT64  NOT NULL OPTIONS(description="Clé étrangère vers dim_client."),
  produit_key   INT64  NOT NULL OPTIONS(description="Clé étrangère vers dim_produit."),
  magasin_key   INT64  NOT NULL OPTIONS(description="Clé étrangère vers dim_magasin."),
  quantite      INT64           OPTIONS(description="Nombre d'unités vendues sur la ligne."),
  mnt_ht        NUMERIC         OPTIONS(description="Montant Hors Taxe de la ligne en EUR, remise déduite. LE CHIFFRE D'AFFAIRES (CA) = SUM(mnt_ht)."),
  remise_pct    NUMERIC         OPTIONS(description="Taux de remise appliqué, entre 0 et 1 (0.15 = 15%)."),
  mnt_tva       NUMERIC         OPTIONS(description="Montant de TVA de la ligne en EUR (taux 20%)."),
  mnt_ttc       NUMERIC         OPTIONS(description="Montant Toutes Taxes Comprises de la ligne en EUR = mnt_ht + mnt_tva.")
)
OPTIONS(description="Table de FAITS des ventes. Grain: 1 ligne = 1 ligne de commande (un produit dans une commande). Table centrale du schéma en étoile. Métriques additives: quantite, mnt_ht, mnt_tva, mnt_ttc. Se joint aux dimensions via les clés *_key.");
