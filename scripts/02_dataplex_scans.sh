#!/usr/bin/env bash
# =====================================================================
# 02 - Dataplex : lineage (auto) + scan de PROFILING + scan de QUALITÉ
# =====================================================================
# - Lineage BigQuery : automatique dès que datalineage.googleapis.com est
#   activé (fait en 00). Aucune commande par table nécessaire ; il se
#   remplit à mesure que des requêtes CREATE TABLE ... AS tournent.
# - Profiling : statistiques par colonne (min/max, nulls, valeurs top).
# - Qualité   : règles de dq_spec.yaml.
# =====================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; source "$HERE/.env"; set +a

FACT="//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/$DATASET/tables/fact_ventes"

echo "▶ Scan de PROFILING sur fact_ventes…"
gcloud dataplex datascans create data-profile profile-fact-ventes \
  --location="$DPLX_LOCATION" \
  --project="$PROJECT_ID" \
  --data-source-resource="$FACT" 2>/dev/null || echo "  (scan déjà existant, on continue)"
gcloud dataplex datascans run profile-fact-ventes --location="$DPLX_LOCATION" --project="$PROJECT_ID"

echo "▶ Scan de QUALITÉ sur fact_ventes (règles dq_spec.yaml)…"
gcloud dataplex datascans create data-quality quality-fact-ventes \
  --location="$DPLX_LOCATION" \
  --project="$PROJECT_ID" \
  --data-source-resource="$FACT" \
  --data-quality-spec-file="$HERE/scripts/dq_spec.yaml" 2>/dev/null || echo "  (scan déjà existant, on continue)"
gcloud dataplex datascans run quality-fact-ventes --location="$DPLX_LOCATION" --project="$PROJECT_ID"

cat <<EOF
✅ Scans lancés. À voir dans la console :
   Profiling & Qualité : https://console.cloud.google.com/dataplex/govern/data-profiling?project=$PROJECT_ID
   Lineage (ouvre fact_ventes > onglet "Lineage") :
     https://console.cloud.google.com/bigquery?project=$PROJECT_ID
EOF
