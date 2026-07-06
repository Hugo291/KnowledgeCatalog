#!/usr/bin/env python3
"""
create_agent.py
================================================================
Crée l'agent conversationnel (Conversational Analytics API / Gemini
Data Analytics) à partir du contexte produit par build_context.py.

Ce qu'on fournit à l'agent :
  1. datasource_references : les tables BigQuery du schéma en étoile
  2. system_instruction    : les descriptions du catalogue + règles métier

⚠️ L'API geminidataanalytics est récente : si un nom de champ a changé
dans ta version, adapte-le (message d'erreur explicite le cas échéant).
================================================================
"""
import json
import os
import pathlib

from dotenv import load_dotenv
from google.api_core.exceptions import AlreadyExists
from google.cloud import geminidataanalytics

ROOT = pathlib.Path(__file__).resolve().parent
load_dotenv(ROOT.parent / ".env")

PROJECT_ID = os.environ["PROJECT_ID"]
LOCATION = os.environ.get("AGENT_LOCATION", "global")
AGENT_ID = os.environ.get("AGENT_ID", "agent-ventes-poc")


def main() -> None:
    ctx = json.loads((ROOT / "context.json").read_text())
    dataset = ctx["dataset"]

    # 1) Les tables sur lesquelles l'agent a le droit de générer du SQL
    table_refs = [
        geminidataanalytics.BigQueryTableReference(
            project_id=PROJECT_ID, dataset_id=dataset, table_id=t
        )
        for t in ctx["tables"]
    ]
    datasources = geminidataanalytics.DatasourceReferences()
    datasources.bq.table_references = table_refs

    # 2) Le contexte "publié" : instructions issues du catalogue
    published = geminidataanalytics.Context()
    published.system_instruction = ctx["system_instruction"]
    published.datasource_references = datasources

    agent = geminidataanalytics.DataAgent()
    agent.data_analytics_agent.published_context = published
    agent.display_name = "Agent Ventes (POC Dataplex)"

    client = geminidataanalytics.DataAgentServiceClient()
    parent = f"projects/{PROJECT_ID}/locations/{LOCATION}"

    try:
        client.create_data_agent(
            request=geminidataanalytics.CreateDataAgentRequest(
                parent=parent, data_agent_id=AGENT_ID, data_agent=agent
            )
        )
        print(f"✅ Agent créé : {parent}/dataAgents/{AGENT_ID}")
    except AlreadyExists:
        # Met à jour le contexte si l'agent existe déjà
        agent.name = f"{parent}/dataAgents/{AGENT_ID}"
        client.update_data_agent(
            request=geminidataanalytics.UpdateDataAgentRequest(data_agent=agent)
        )
        print(f"♻️  Agent mis à jour : {agent.name}")

    print("→ Teste-le :  python ask.py \"Quel est le CA des clients actifs en 2025 ?\"")


if __name__ == "__main__":
    main()
