# Tutoriel 01 — Le schéma en étoile + les descriptions

⏱️ ~10 min · 🎯 Créer `fact_ventes` + 4 dimensions, **avec leurs descriptions**, et 5 000 lignes.

## Objectif

Construire le socle : un schéma en étoile classique **dont chaque colonne porte une
description**. Ces descriptions sont **le catalogue** — la matière que l'agent lira au
tutoriel 04. C'est le tutoriel le plus important après le 03.

```
                 dim_date
                    |
 dim_client ---- fact_ventes ---- dim_produit
                    |
                dim_magasin
```

## Prérequis

[Tutoriel 00](../00-prerequis/) terminé (`.env` rempli, « ✅ Environnement prêt »).

## Étapes

### 1. Lancer la création

```bash
bash scripts/01_bigquery.sh
```

Le script fait 2 choses :
1. `sql/01_create_star_schema.sql` → les 5 tables **avec les descriptions inline**
2. `sql/02_load_sample_data.sql` → 5 000 lignes de ventes générées sur 2024-2025

### 2. Comprendre le point clé

Regarde [`sql/01_create_star_schema.sql`](../../sql/01_create_star_schema.sql) : les
descriptions sont posées **dans le `CREATE TABLE`**, pas après coup :

```sql
mnt_ht NUMERIC OPTIONS(description="Montant Hors Taxe de la ligne en EUR, remise
  déduite. LE CHIFFRE D'AFFAIRES (CA) = SUM(mnt_ht)."),
...
statut STRING OPTIONS(description="Statut du client. Valeurs possibles: A = actif,
  I = inactif, P = prospect. UN CLIENT ACTIF a statut = 'A'.")
```

👉 Ces deux descriptions sont exactement celles que l'agent citera au tutoriel 04 pour
écrire son SQL. **Écris tes descriptions en pensant aux questions qu'on posera.**

## Résultat attendu

```
▶ Création du dataset retail_poc dans EU (si absent)…
▶ 1/2 Schéma en étoile + descriptions (catalogue)…
   Replaced ton-projet.retail_poc.fact_ventes
▶ 2/2 Données de démo…
   Number of affected rows: 5000
✅ BigQuery prêt.
```

## Vérifier

Dans la console BigQuery, ouvre `retail_poc > fact_ventes > onglet Schema`. La colonne
**Description** doit être remplie sur chaque champ :

![Schéma fact_ventes avec descriptions](../../assets/screenshots/01-bigquery-schema-descriptions.png)

Ou en SQL — c'est **littéralement** ce que l'agent lira :

```sql
SELECT column_name, data_type, description
FROM `ton-projet.retail_poc`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS
WHERE table_name = 'fact_ventes';
```

Aucune `description` ne doit être vide.

## Pièges connus

| Symptôme | Cause | Solution |
|---|---|---|
| `Query column 7 has type FLOAT64 which cannot be inserted into column prix_unitaire_ref, which has type NUMERIC` | BigQuery **ne convertit pas** FLOAT64 → NUMERIC implicitement | `CAST(... AS NUMERIC)` sur toute valeur monétaire (déjà corrigé dans `sql/02`) |
| `Exceeded rate limits: too many table update operations for this table` | Trop d'`ALTER TABLE SET OPTIONS` d'affilée sur la même table | Poser les descriptions **inline dans le `CREATE TABLE`** (1 seule opération/table) — c'est pourquoi il n'y a plus de `sql/03` |
| `Billing has not been enabled` | Projet sandbox | Voir [tutoriel 00](../00-prerequis/) |

> 💡 **Pourquoi inline plutôt qu'`ALTER` ?** BigQuery limite les mises à jour de
> métadonnées par table et par fenêtre de temps. `fact_ventes` a 10 colonnes → 11
> `ALTER` d'affilée = dépassement garanti. Le `CREATE` fait tout d'un coup.

## Suite

➡️ [Tutoriel 02 — Dataplex : lineage, profiling, qualité](../02-dataplex-scans/)
