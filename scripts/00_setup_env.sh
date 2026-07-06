#!/usr/bin/env bash
# =====================================================================
# 00 - Prérequis : charge .env, vérifie les outils, active les APIs
# =====================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$HERE/.env" ]]; then
  echo "❌ Fichier .env manquant. Fais : cp .env.example .env puis édite-le." >&2
  exit 1
fi
set -a; source "$HERE/.env"; set +a

command -v gcloud >/dev/null || { echo "❌ gcloud introuvable (installe le Google Cloud SDK)"; exit 1; }
command -v bq     >/dev/null || { echo "❌ bq introuvable (fait partie du Cloud SDK)"; exit 1; }

echo "▶ Projet : $PROJECT_ID  |  Dataset : $DATASET ($BQ_LOCATION)  |  Dataplex : $DPLX_LOCATION"
gcloud config set project "$PROJECT_ID" >/dev/null

echo "▶ Activation des APIs nécessaires (peut prendre 1-2 min la 1re fois)…"
gcloud services enable \
  bigquery.googleapis.com \
  dataplex.googleapis.com \
  datalineage.googleapis.com \
  geminidataanalytics.googleapis.com \
  cloudaicompanion.googleapis.com

echo "✅ Environnement prêt."
