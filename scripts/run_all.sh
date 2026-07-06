#!/usr/bin/env bash
# =====================================================================
# Orchestration complète du POC (partie infrastructure/données)
# =====================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/00_setup_env.sh"
bash "$HERE/01_bigquery.sh"
bash "$HERE/02_dataplex_scans.sh"

cat <<'EOF'

============================================================
 Infra + données + catalogue : OK ✅
 Étape suivante = l'AGENT (voir dossier agent/) :

   cd agent
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt

   python build_context.py     # lit les descriptions -> genere le contexte
   python create_agent.py      # cree l'agent conversationnel
   python ask.py "Quel est le CA des clients actifs en 2025 ?"
============================================================
EOF
