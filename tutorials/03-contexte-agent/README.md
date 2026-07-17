# Tutoriel 03 — Du catalogue au contexte de l'agent

⏱️ ~10 min · 🎯 Lire les descriptions et les transformer en cerveau de l'agent.

> ⭐ **Le tutoriel central.** C'est ici que « Dataplex » cesse d'être un outil de
> gouvernance abstrait et devient concrètement ce qui fait répondre juste l'agent.

## Objectif

Exécuter [`agent/build_context.py`](../../agent/build_context.py), qui :
1. **lit** les descriptions des tables/colonnes depuis BigQuery (= le catalogue),
2. **compose** une `system_instruction` (descriptions + règles métier + jointures),
3. **écrit** `agent/context.json`, consommé par les tutoriels 04 et 05.

## Prérequis

[Tutoriel 01](../01-schema-etoile/) terminé (les descriptions existent).

## Étapes

### 1. Installer les dépendances

```bash
cd agent
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Construire le contexte

```bash
python build_context.py
```

### 3. Comprendre ce qui se passe

Le cœur de `build_context.py` — il ne fait **aucun appel à Dataplex** :

```python
client = bigquery.Client(project=PROJECT_ID)
for tbl_item in client.list_tables(DATASET):
    table = client.get_table(tbl_item.reference)   # ← récupère description + schéma
    columns = [{"name": f.name, "type": f.field_type,
                "description": f.description or ""} for f in table.schema]
```

Puis il **ajoute** ce que les descriptions seules ne disent pas assez fort :

```python
BUSINESS_RULES = [
    "Le chiffre d'affaires (CA) se calcule TOUJOURS avec SUM(mnt_ht) (montant hors taxe).",
    "Un client actif est un client dont dim_client.statut = 'A'.",
    ...
]
RELATIONSHIPS = [
    "fact_ventes.client_key  = dim_client.client_key",
    ...
]
```

👉 **La leçon** : le catalogue fournit le *quoi* (le sens des colonnes) ; toi tu ajoutes
le *comment* (les règles de calcul, les jointures). Les deux ensemble = un agent fiable.

## Résultat attendu

```
✅ Toutes les colonnes ont une description (catalogue complet).
✅ Contexte écrit dans /…/agent/context.json

----- Aperçu de la system_instruction -----
Tu es un analyste de données retail. …

# Règles métier
- Le chiffre d'affaires (CA) se calcule TOUJOURS avec SUM(mnt_ht) (montant hors taxe).
- Un client actif est un client dont dim_client.statut = 'A'.

# Jointures (schéma en étoile)
- fact_ventes.client_key  = dim_client.client_key
…
# Tables et colonnes (issu du catalogue)
## dim_client — Dimension CLIENT. Une ligne par client. …
```

![Sortie de build_context.py : catalogue complet et system_instruction générée](../../assets/screenshots/04-build-context.png)

*Capture réelle. On voit le catalogue être lu (« ✅ Toutes les colonnes ont une
description ») puis transformé en `system_instruction` : règles métier, jointures, et
les descriptions issues du catalogue. **C'est le moment exact où Dataplex devient le
cerveau de l'agent.***

> ⚠️ Si tu vois `⚠️ N colonnes SANS description`, **reviens au tutoriel 01**. Chaque
> colonne non décrite est un angle mort pour l'agent.

## Vérifier

```bash
python -c "import json; c=json.load(open('context.json')); \
print(len(c['system_instruction']), 'caractères de contexte'); print(c['tables'])"
```

Tu dois voir tes 5 tables et un contexte de plusieurs milliers de caractères.

## Pièges connus

| Symptôme | Cause | Solution |
|---|---|---|
| `⚠️ N colonnes SANS description` | Descriptions manquantes | Refaire le [tutoriel 01](../01-schema-etoile/) |
| `DefaultCredentialsError` | Pas d'Application Default Credentials | `gcloud auth application-default login` (inutile en Cloud Shell) |
| `403 Access Denied` sur le dataset | Droits BigQuery | Rôle `BigQuery Data Viewer` minimum |

## Suite

➡️ [Tutoriel 04 — L'agent conversationnel](../04-agent-conversationnel/)
