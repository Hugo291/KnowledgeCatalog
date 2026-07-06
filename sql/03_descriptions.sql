-- =====================================================================
-- 03 - DESCRIPTIONS (le "catalogue" métier)
-- =====================================================================
-- ⭐ FICHIER CLÉ DU POC ⭐
-- Ces descriptions vivent sur les métadonnées BigQuery. C'est EXACTEMENT
-- ce que l'agent conversationnel lit pour comprendre les tables.
-- Dataplex Universal Catalog est la surface qui permet de les gérer/
-- générer à l'échelle (write-back sur BigQuery), mais physiquement elles
-- sont ici. Sans elles, l'agent est "aveugle".
-- =====================================================================

-- ================= TABLES ==============================================
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes`
  SET OPTIONS (description = "Table de FAITS des ventes. Grain: 1 ligne = 1 ligne de commande (un produit dans une commande). Table centrale du schéma en étoile. Métriques additives: quantite, mnt_ht, mnt_tva, mnt_ttc. Se joint aux dimensions via les clés *_key.");

ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date`
  SET OPTIONS (description = "Dimension DATE (calendrier). Une ligne par jour de 2024 à 2025. Jointure via date_key = fact_ventes.date_key.");

ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_client`
  SET OPTIONS (description = "Dimension CLIENT. Une ligne par client. Jointure via client_key = fact_ventes.client_key.");

ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_produit`
  SET OPTIONS (description = "Dimension PRODUIT (catalogue). Une ligne par produit. Jointure via produit_key = fact_ventes.produit_key.");

ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_magasin`
  SET OPTIONS (description = "Dimension MAGASIN / canal de vente. Une ligne par point de vente. Jointure via magasin_key = fact_ventes.magasin_key.");

-- ================= fact_ventes : colonnes ==============================
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN vente_id    SET OPTIONS (description = "Identifiant unique de la ligne de commande.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN date_key    SET OPTIONS (description = "Clé étrangère vers dim_date. Format entier AAAAMMJJ.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN client_key  SET OPTIONS (description = "Clé étrangère vers dim_client.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN produit_key SET OPTIONS (description = "Clé étrangère vers dim_produit.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN magasin_key SET OPTIONS (description = "Clé étrangère vers dim_magasin.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN quantite    SET OPTIONS (description = "Nombre d'unités vendues sur la ligne.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN mnt_ht      SET OPTIONS (description = "Montant Hors Taxe de la ligne en EUR, remise déduite. LE CHIFFRE D'AFFAIRES (CA) = SUM(mnt_ht).");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN remise_pct  SET OPTIONS (description = "Taux de remise appliqué, entre 0 et 1 (0.15 = 15%).");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN mnt_tva     SET OPTIONS (description = "Montant de TVA de la ligne en EUR (taux 20%).");
ALTER TABLE `${PROJECT_ID}.${DATASET}.fact_ventes` ALTER COLUMN mnt_ttc     SET OPTIONS (description = "Montant Toutes Taxes Comprises de la ligne en EUR = mnt_ht + mnt_tva.");

-- ================= dim_client : colonnes ===============================
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_client` ALTER COLUMN client_key SET OPTIONS (description = "Clé de substitution (surrogate key) du client.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_client` ALTER COLUMN client_id  SET OPTIONS (description = "Identifiant métier du client (ex: CLI00042).");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_client` ALTER COLUMN nom        SET OPTIONS (description = "Raison sociale du client.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_client` ALTER COLUMN segment    SET OPTIONS (description = "Segment commercial: Particulier, PME ou Grand Compte.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_client` ALTER COLUMN ville      SET OPTIONS (description = "Ville du client.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_client` ALTER COLUMN pays       SET OPTIONS (description = "Pays du client.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_client` ALTER COLUMN statut     SET OPTIONS (description = "Statut du client. Valeurs possibles: A = actif, I = inactif, P = prospect. UN CLIENT ACTIF a statut = 'A'.");

-- ================= dim_produit : colonnes ==============================
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_produit` ALTER COLUMN produit_key       SET OPTIONS (description = "Clé de substitution du produit.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_produit` ALTER COLUMN produit_id        SET OPTIONS (description = "Identifiant métier du produit (ex: PRD0012).");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_produit` ALTER COLUMN libelle           SET OPTIONS (description = "Libellé commercial du produit.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_produit` ALTER COLUMN categorie         SET OPTIONS (description = "Catégorie: Informatique, Mobilier ou Fournitures.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_produit` ALTER COLUMN sous_categorie    SET OPTIONS (description = "Sous-catégorie produit.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_produit` ALTER COLUMN marque            SET OPTIONS (description = "Marque du produit.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_produit` ALTER COLUMN prix_unitaire_ref SET OPTIONS (description = "Prix catalogue HT de référence en EUR (avant remise).");

-- ================= dim_magasin : colonnes ==============================
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_magasin` ALTER COLUMN magasin_key  SET OPTIONS (description = "Clé de substitution du magasin.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_magasin` ALTER COLUMN magasin_id   SET OPTIONS (description = "Identifiant métier du magasin (ex: MAG003).");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_magasin` ALTER COLUMN nom          SET OPTIONS (description = "Nom du point de vente.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_magasin` ALTER COLUMN region       SET OPTIONS (description = "Région administrative du magasin.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_magasin` ALTER COLUMN type_magasin SET OPTIONS (description = "Canal: Physique (boutique) ou Online (site web).");

-- ================= dim_date : colonnes =================================
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date` ALTER COLUMN date_key     SET OPTIONS (description = "Clé calendrier au format entier AAAAMMJJ.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date` ALTER COLUMN full_date    SET OPTIONS (description = "Date réelle (type DATE).");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date` ALTER COLUMN annee        SET OPTIONS (description = "Année (ex: 2025).");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date` ALTER COLUMN trimestre    SET OPTIONS (description = "Trimestre 1 à 4.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date` ALTER COLUMN mois         SET OPTIONS (description = "Numéro de mois 1 à 12.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date` ALTER COLUMN mois_nom     SET OPTIONS (description = "Nom du mois.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date` ALTER COLUMN jour_semaine SET OPTIONS (description = "Jour de la semaine.");
ALTER TABLE `${PROJECT_ID}.${DATASET}.dim_date` ALTER COLUMN est_weekend  SET OPTIONS (description = "Vrai si le jour est un samedi ou dimanche.");
