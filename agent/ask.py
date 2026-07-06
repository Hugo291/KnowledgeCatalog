#!/usr/bin/env python3
"""
ask.py — pose une question en langage naturel à l'agent
================================================================
  python ask.py "Quel est le CA des clients actifs en 2025 ?"
  python ask.py --inline "Top 5 des produits par CA"   # sans agent persistant
  DEBUG=1 python ask.py "..."                           # dump brut du flux

L'agent renvoie un FLUX d'événements : texte, SQL généré, données, etc.
On affiche le texte + le SQL généré (la preuve qu'il a bien compris le
catalogue).
================================================================
"""
import json
import os
import pathlib
import sys

from dotenv import load_dotenv
from google.cloud import geminidataanalytics

ROOT = pathlib.Path(__file__).resolve().parent
load_dotenv(ROOT.parent / ".env")

PROJECT_ID = os.environ["PROJECT_ID"]
LOCATION = os.environ.get("AGENT_LOCATION", "global")
AGENT_ID = os.environ.get("AGENT_ID", "agent-ventes-poc")
DEBUG = os.environ.get("DEBUG") == "1"


def render(resp) -> None:
    """Affiche defensivement les parties utiles d'un événement du flux."""
    if DEBUG:
        print("\n===== ÉVÉNEMENT BRUT =====\n" + str(resp))
        return
    m = getattr(resp, "system_message", None)
    if m is None:
        return
    # Texte en langage naturel
    if getattr(m, "text", None) and getattr(m.text, "parts", None):
        print("".join(m.text.parts), end="", flush=True)
    # SQL généré (preuve que le catalogue a été utilisé)
    sql = getattr(getattr(m, "data", None), "generated_sql", "")
    if sql:
        print("\n\n--- SQL généré par l'agent ---\n" + sql + "\n")


def build_request(question: str, inline: bool) -> geminidataanalytics.ChatRequest:
    parent = f"projects/{PROJECT_ID}/locations/{LOCATION}"
    msg = geminidataanalytics.Message()
    msg.user_message.text = question

    req = geminidataanalytics.ChatRequest(parent=parent, messages=[msg])

    if inline:
        # Contexte "inline" : on passe le catalogue directement, sans agent persistant
        ctx = json.loads((ROOT / "context.json").read_text())
        datasources = geminidataanalytics.DatasourceReferences()
        datasources.bq.table_references = [
            geminidataanalytics.BigQueryTableReference(
                project_id=PROJECT_ID, dataset_id=ctx["dataset"], table_id=t
            )
            for t in ctx["tables"]
        ]
        inline_ctx = geminidataanalytics.Context()
        inline_ctx.system_instruction = ctx["system_instruction"]
        inline_ctx.datasource_references = datasources
        req.inline_context = inline_ctx
    else:
        # Référence l'agent persistant créé par create_agent.py
        agent_ctx = geminidataanalytics.DataAgentContext()
        agent_ctx.data_agent = f"{parent}/dataAgents/{AGENT_ID}"
        req.data_agent_context = agent_ctx
    return req


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--inline"]
    inline = "--inline" in sys.argv
    if not args:
        print('Usage: python ask.py [--inline] "ta question"')
        sys.exit(1)
    question = " ".join(args)

    print(f"❓ {question}\n")
    client = geminidataanalytics.DataChatServiceClient()
    for resp in client.chat(request=build_request(question, inline)):
        render(resp)
    print()


if __name__ == "__main__":
    main()
