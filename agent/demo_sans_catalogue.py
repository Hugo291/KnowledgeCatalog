#!/usr/bin/env python3
"""
demo_sans_catalogue.py — le test A/B du POC
================================================================
Pose la MÊME question que ask.py, sur les MÊMES données, mais :
  - sur les tables *_nue (créées par sql/04, donc SANS descriptions)
  - avec une system_instruction vide de tout savoir métier

Tout le reste est identique (même modèle, même API, mêmes lignes).
La seule variable, c'est le CATALOGUE.

  python demo_sans_catalogue.py                      # question par défaut
  python demo_sans_catalogue.py "ta question"

À comparer avec :
  python ask.py "Quel est le CA des clients actifs en 2025 ?"
================================================================
"""
import os
import pathlib
import sys

from dotenv import load_dotenv
from google.cloud import geminidataanalytics

ROOT = pathlib.Path(__file__).resolve().parent
load_dotenv(ROOT.parent / ".env")

PROJECT_ID = os.environ["PROJECT_ID"]
DATASET = os.environ["DATASET"]
LOCATION = os.environ.get("AGENT_LOCATION", "global")

# Les mêmes données que fact_ventes / dim_client / dim_date, sans une seule description
TABLES = ["fact_ventes_nue", "dim_client_nue", "dim_date_nue"]

QUESTION = " ".join(sys.argv[1:]) or "Quel est le CA des clients actifs en 2025 ?"


def main() -> None:
    parent = f"projects/{PROJECT_ID}/locations/{LOCATION}"

    datasources = geminidataanalytics.DatasourceReferences()
    datasources.bq.table_references = [
        geminidataanalytics.BigQueryTableReference(
            project_id=PROJECT_ID, dataset_id=DATASET, table_id=t
        )
        for t in TABLES
    ]

    context = geminidataanalytics.Context()
    # Volontairement nu : aucune règle métier, aucune jointure, aucun glossaire.
    context.system_instruction = "Tu es un analyste de données. Réponds à la question."
    context.datasource_references = datasources

    message = geminidataanalytics.Message()
    message.user_message.text = QUESTION
    request = geminidataanalytics.ChatRequest(
        parent=parent, messages=[message], inline_context=context
    )

    print("=" * 70)
    print("  SANS CATALOGUE — tables *_nue, aucune description, aucune règle")
    print("=" * 70)
    print(f"\n❓ {QUESTION}\n")

    client = geminidataanalytics.DataChatServiceClient()
    for resp in client.chat(request=request):
        m = getattr(resp, "system_message", None)
        if m is None:
            continue
        if getattr(m, "text", None) and getattr(m.text, "parts", None):
            print("".join(m.text.parts), end="", flush=True)
        sql = getattr(getattr(m, "data", None), "generated_sql", "")
        if sql:
            print("\n\n--- SQL généré SANS catalogue ---\n" + sql + "\n")
    print()


if __name__ == "__main__":
    main()
