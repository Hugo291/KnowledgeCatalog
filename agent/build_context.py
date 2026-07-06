#!/usr/bin/env python3
"""
build_context.py
================================================================
Construit le CONTEXTE de l'agent conversationnel À PARTIR du catalogue.

C'est ici que se matérialise le mécanisme "agent <-> Dataplex" :
Dataplex gère les descriptions des tables/colonnes, mais celles-ci
vivent sur les métadonnées BigQuery. Ce script les LIT depuis BigQuery
(exactement ce que l'agent fait au moment de générer le SQL) et en
compose une "system_instruction" claire + la liste des tables.

Sortie : context.json (réutilisé par create_agent.py et ask.py).
================================================================
"""
import json
import os
import pathlib

from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv(pathlib.Path(__file__).resolve().parent.parent / ".env")

PROJECT_ID = os.environ["PROJECT_ID"]
DATASET = os.environ["DATASET"]

# Règles métier qu'on veut GARANTIR à l'agent (ce que les descriptions
# seules ne disent pas toujours assez fort). C'est le "plus" que tu
# ajoutes au catalogue brut.
BUSINESS_RULES = [
    "Le chiffre d'affaires (CA) se calcule TOUJOURS avec SUM(mnt_ht) (montant hors taxe).",
    "Un client actif est un client dont dim_client.statut = 'A'.",
    "Pour filtrer par période, joins fact_ventes.date_key à dim_date et filtre sur dim_date.annee / trimestre / mois.",
    "Les clés *_key servent UNIQUEMENT aux jointures, jamais aux agrégats.",
]

# Jointures du schéma en étoile (aide l'agent à écrire les JOIN)
RELATIONSHIPS = [
    "fact_ventes.date_key    = dim_date.date_key",
    "fact_ventes.client_key  = dim_client.client_key",
    "fact_ventes.produit_key = dim_produit.produit_key",
    "fact_ventes.magasin_key = dim_magasin.magasin_key",
]


def read_catalog() -> list[dict]:
    """Lit tables + descriptions + colonnes depuis BigQuery (= le catalogue)."""
    client = bigquery.Client(project=PROJECT_ID)
    tables = []
    for tbl_item in client.list_tables(DATASET):
        table = client.get_table(tbl_item.reference)  # récupère description + schéma
        columns = [
            {
                "name": f.name,
                "type": f.field_type,
                "description": f.description or "",
            }
            for f in table.schema
        ]
        tables.append(
            {
                "table_id": table.table_id,
                "description": table.description or "",
                "num_rows": table.num_rows,
                "columns": columns,
            }
        )
    return tables


def render_system_instruction(tables: list[dict]) -> str:
    """Transforme le catalogue en instructions lisibles par l'agent."""
    lines = [
        "Tu es un analyste de données retail. Tu réponds en langage naturel",
        "en générant du SQL BigQuery correct sur le schéma en étoile ci-dessous.",
        "",
        "# Règles métier",
    ]
    lines += [f"- {r}" for r in BUSINESS_RULES]
    lines += ["", "# Jointures (schéma en étoile)"]
    lines += [f"- {r}" for r in RELATIONSHIPS]
    lines += ["", "# Tables et colonnes (issu du catalogue)"]
    for t in tables:
        lines.append(f"\n## {t['table_id']} — {t['description']}")
        for c in t["columns"]:
            desc = f" : {c['description']}" if c["description"] else ""
            lines.append(f"- {c['name']} ({c['type']}){desc}")
    return "\n".join(lines)


def main() -> None:
    tables = read_catalog()

    missing = [
        f"{t['table_id']}.{c['name']}"
        for t in tables
        for c in t["columns"]
        if not c["description"]
    ]
    if missing:
        print(f"⚠️  {len(missing)} colonnes SANS description "
              f"(l'agent sera moins précis dessus) : {missing[:8]}…")
    else:
        print("✅ Toutes les colonnes ont une description (catalogue complet).")

    context = {
        "project_id": PROJECT_ID,
        "dataset": DATASET,
        "system_instruction": render_system_instruction(tables),
        "tables": [t["table_id"] for t in tables],
    }
    out = pathlib.Path(__file__).resolve().parent / "context.json"
    out.write_text(json.dumps(context, ensure_ascii=False, indent=2))
    print(f"✅ Contexte écrit dans {out}")
    print("\n----- Aperçu de la system_instruction -----")
    print(context["system_instruction"][:900] + "\n[…]")


if __name__ == "__main__":
    main()
