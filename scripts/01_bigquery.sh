#!/usr/bin/env bash
# =====================================================================
# 01 - Crée le dataset, le schéma en étoile, les données ET les descriptions
# =====================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; source "$HERE/.env"; set +a

echo "▶ Création du dataset $DATASET dans $BQ_LOCATION (si absent)…"
bq --location="$BQ_LOCATION" mk --dataset --force "$PROJECT_ID:$DATASET" 2>/dev/null || true

run_sql () {
  local file="$1"
  echo "  → $file"
  # Substitue ${PROJECT_ID} et ${DATASET} puis envoie à BigQuery
  sed -e "s/\${PROJECT_ID}/$PROJECT_ID/g" -e "s/\${DATASET}/$DATASET/g" "$HERE/$file" \
    | bq query --use_legacy_sql=false --project_id="$PROJECT_ID"
}

echo "▶ 1/2 Schéma en étoile + descriptions (catalogue)…" ; run_sql sql/01_create_star_schema.sql
echo "▶ 2/2 Données de démo…"                             ; run_sql sql/02_load_sample_data.sql

echo "✅ BigQuery prêt. Vérifie : https://console.cloud.google.com/bigquery?project=$PROJECT_ID"
