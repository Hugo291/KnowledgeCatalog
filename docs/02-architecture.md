# 02 — Architecture de bout en bout

## Le flux

```
┌─────────────────────┐
│  Projet BI           │  dbt / Dataform / requêtes SQL planifiées
│  (transformations)   │
└──────────┬───────────┘
           │ CREATE TABLE … AS SELECT …
           ▼
┌─────────────────────┐        ┌──────────────────────────────────┐
│  BigQuery            │◄───────│  Dataplex Universal Catalog       │
│  schéma en étoile    │ write- │  • descriptions (Gemini)          │
│  fact_ventes         │ back   │  • lineage (auto)                 │
│  dim_client/produit… │        │  • profiling + qualité (scans)    │
└──────────┬───────────┘        │  • glossaire métier               │
           │ schéma + descriptions      └──────────────┬───────────┘
           │ (lus au moment de la question)            │ tu recopies
           ▼                                           │ glossaire/valeurs
┌──────────────────────────────────────────┐          │ dans le contexte
│  Agent conversationnel                     │◄─────────┘
│  (Conversational Analytics API / Gemini)   │
│  question FR → SQL → exécution → réponse    │
└────────────────────────────────────────────┘
```

## Les 3 plans à distinguer

1. **Plan de production** (ton projet BI) — fabrique les tables. Le lineage s'y
   accroche automatiquement.
2. **Plan de gouvernance** (Dataplex) — enrichit/valide les métadonnées.
   *Surface d'édition*, mais les descriptions atterrissent sur BigQuery.
3. **Plan de consommation** (l'agent) — lit le schéma + descriptions BigQuery,
   plus le contexte que tu lui donnes, pour générer du SQL.

## Où chaque brique Dataplex atteint l'agent

| Brique Dataplex | Canal vers l'agent | Automatique ? |
|---|---|---|
| Descriptions table/colonne | write-back BigQuery → lu à la génération SQL | ✅ oui |
| Data Profiling | valeurs d'exemple recopiées dans le contexte | ➖ semi (tu l'injectes) |
| Business Glossary | synonymes recopiés dans le contexte | ➖ manuel |
| Data Lineage | t'aide à choisir/valider la table | ❌ non (humain) |
| Catalog search | étape de *retrieval* si beaucoup de tables | ➖ selon setup |

## Le POC mappé sur cette archi

| Étape POC | Fichier | Plan |
|---|---|---|
| Schéma en étoile + données | `sql/01`, `sql/02` | Production |
| Descriptions (catalogue) | `sql/03` | Gouvernance |
| Lineage + profiling + qualité | `scripts/02_dataplex_scans.sh` | Gouvernance |
| Lecture catalogue → contexte | `agent/build_context.py` | Consommation |
| Création de l'agent | `agent/create_agent.py` | Consommation |
| Question NL | `agent/ask.py` | Consommation |

→ Suite : [03-agent-catalog-interaction.md](03-agent-catalog-interaction.md)
