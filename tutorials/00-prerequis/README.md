# Tutoriel 00 — Prérequis & mise en route

⏱️ ~10 min · 🎯 Avoir un projet GCP prêt, les APIs activées et le `.env` renseigné.

## Objectif

Poser les fondations. À la fin, `bash scripts/00_setup_env.sh` se termine par
« ✅ Environnement prêt » et tu peux enchaîner sur le [tutoriel 01](../01-schema-etoile/).

## Prérequis

- Un **projet GCP** et un **compte de facturation**.
- Soit **Cloud Shell** (le plus simple : `gcloud`, `bq`, `git`, `python` déjà installés
  et authentifiés), soit le **Google Cloud SDK** en local
  (`brew install --cask google-cloud-sdk`, puis `gcloud init` et
  `gcloud auth application-default login`).

## Étapes

### 1. Cloner le repo

```bash
git clone https://github.com/Hugo291/KnowledgeCatalog.git
cd KnowledgeCatalog
```

### 2. ⚠️ Vérifier que la facturation est activée

**C'est LE point bloquant.** Un projet BigQuery en mode *sandbox* (sans facturation)
refuse les requêtes DML, les scans Dataplex et l'agent Gemini.

```bash
# Ton projet a-t-il la facturation ?
gcloud billing projects describe TON_PROJET --format='value(billingEnabled)'
```

- Si ça affiche `True` → parfait, passe à l'étape 3.
- Si ça affiche `False` (ou rien) → liste tes comptes de facturation puis lie-en un :

```bash
gcloud billing accounts list          # récupère l'ACCOUNT_ID (format 01ABCD-...)
gcloud billing projects link TON_PROJET --billing-account=TON_ACCOUNT_ID
```

Tu dois voir `billingEnabled: true`.

### 3. Renseigner le `.env`

```bash
cp .env.example .env
```

Édite `.env` (ou en une ligne : `sed -i 's/mon-projet-gcp/TON_PROJET/' .env`) :

```bash
export PROJECT_ID="ton-projet"     # ← le seul champ vraiment obligatoire
export DATASET="retail_poc"
export BQ_LOCATION="EU"            # multirégion BigQuery (EU ou US)
export DPLX_LOCATION="europe-west1" # région Dataplex des scans
export AGENT_LOCATION="global"
export AGENT_ID="agent-ventes-poc"
```

> ⚠️ `BQ_LOCATION` et `DPLX_LOCATION` doivent être **cohérents** : un dataset en `EU`
> se scanne depuis une région européenne (`europe-west1`).

### 4. Activer les APIs

```bash
bash scripts/00_setup_env.sh
```

## Résultat attendu

```
▶ Projet : ton-projet  |  Dataset : retail_poc (EU)  |  Dataplex : europe-west1
▶ Activation des APIs nécessaires (peut prendre 1-2 min la 1re fois)…
Operation "operations/acat.p2-..." finished successfully.
✅ Environnement prêt.
```

## Vérifier

```bash
gcloud services list --enabled | grep -E 'bigquery|dataplex|datalineage|geminidataanalytics'
```
Les 4 APIs doivent apparaître.

## Pièges connus

| Symptôme | Cause | Solution |
|---|---|---|
| `Billing has not been enabled for this project. DML queries are not allowed in the free tier.` | Projet en **sandbox** | Lier un compte de facturation (étape 2) |
| `Regional Access Boundary HTTP request failed … Account not found for email` | Avertissement `gcloud` bénin | **Ignorer** : l'opération se termine quand même par `finished successfully` |
| `PERMISSION_DENIED` sur `services enable` | Droits insuffisants | Rôle `Owner` (ou `Service Usage Admin`) sur le projet |

## Suite

➡️ [Tutoriel 01 — Le schéma en étoile + les descriptions](../01-schema-etoile/)
