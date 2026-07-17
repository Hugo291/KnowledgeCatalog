# Tutoriel 05 — Maintenir le catalogue (et nettoyer)

⏱️ ~10 min · 🎯 Comprendre snapshot vs live, savoir quand rafraîchir, et supprimer les ressources.

## Objectif

Un catalogue qui vieillit produit un agent qui se trompe. Ce tutoriel répond à
**« comment ça marche au quotidien ? »**.

## Le piège à connaître : deux canaux, deux fraîcheurs

À chaque question, l'agent mobilise deux canaux — et **aucun n'est un appel à Dataplex** :

| Canal | Contenu | Fraîcheur |
|---|---|---|
| **A — Contexte stocké** | La `system_instruction` figée dans l'agent au tutoriel 04 | 🧊 **Gelé** jusqu'au prochain `update` |
| **B — Schéma live** | Nom, type **et description actuelle** des tables, relus à chaque génération de SQL | ♻️ **Frais** |

```
Dataplex (gouvernance)  ──écrit──►  BigQuery (métadonnées)
                                   ┌──────┴───────┐
                    (au build, 1×) │              │ (à chaque question)
                                   ▼              ▼
                        system_instruction   schéma live
                            (Canal A)         (Canal B)
                                   └──────┬───────┘
                                          ▼
                                  AGENT → SQL → réponse
```

> **En une phrase** : Dataplex n'est pas dans la boucle d'**exécution** de l'agent,
> il est dans la boucle de **préparation**.

## Exercice : voir le décalage

### 1. Change une description

```sql
ALTER TABLE `ton-projet.retail_poc.dim_client`
  ALTER COLUMN statut SET OPTIONS (
    description = "Statut du client. A = actif, I = inactif, P = prospect, S = suspendu (NOUVEAU). Un client actif a statut = 'A'."
  );
```

### 2. Constate que le Canal A n'a pas bougé

```bash
cd agent && source .venv/bin/activate
python -c "import json; print('suspendu' in json.load(open('context.json'))['system_instruction'])"
# → False   (le contexte de l'agent ignore encore la nouveauté)
```

### 3. Rafraîchis

```bash
python build_context.py   # relit le catalogue → nouveau context.json
python create_agent.py    # bascule en update : pousse le nouveau contexte
python -c "import json; print('suspendu' in json.load(open('context.json'))['system_instruction'])"
# → True
```

👉 **C'est tout le mode opératoire quotidien** : le Canal B suit tout seul, le Canal A
demande un rafraîchissement explicite.

## Le rythme en production

1. **En continu** — les équipes maintiennent descriptions / glossaire / qualité dans Dataplex.
2. **Automatiquement** — Dataplex écrit les descriptions sur BigQuery (write-back).
3. **Périodiquement** (ou à chaque changement de schéma) — on rejoue
   `build_context.py` + `create_agent.py`. C'est **2 lignes dans un cron ou une CI**.
4. **Chaque jour** — les utilisateurs posent leurs questions.

> 💡 Mets l'étape 3 dans ta CI, déclenchée quand `sql/` change ou une fois par nuit.
> C'est la seule chose qui empêche l'agent de dériver.

## Bonnes pratiques de description

Ce qui distingue une description utile d'une description décorative :

| ❌ Faible | ✅ Utile |
|---|---|
| « Montant » | « Montant Hors Taxe en EUR, remise déduite. **LE CA = SUM(mnt_ht)**. » |
| « Statut » | « A = actif, I = inactif, P = prospect. **Un client actif a statut = 'A'**. » |
| « Clé » | « Clé étrangère vers `dim_date`. Format entier AAAAMMJJ. » |

**Règle** : écris la description en pensant à la question que posera l'utilisateur.
Énumère les **valeurs possibles**, donne la **formule**, nomme l'**unité**.

## Nettoyer (fin du POC)

```bash
set -a; source .env; set +a

# 1) Le dataset et ses tables
bq rm -r -f --dataset "$PROJECT_ID:$DATASET"

# 2) Les scans Dataplex
gcloud dataplex datascans delete profile-fact-ventes --location="$DPLX_LOCATION" --quiet
gcloud dataplex datascans delete quality-fact-ventes --location="$DPLX_LOCATION" --quiet

# 3) L'agent
python - <<'EOF'
import os
from google.cloud import geminidataanalytics
c = geminidataanalytics.DataAgentServiceClient()
c.delete_data_agent(name=f"projects/{os.environ['PROJECT_ID']}/locations/"
                         f"{os.environ.get('AGENT_LOCATION','global')}/dataAgents/"
                         f"{os.environ.get('AGENT_ID','agent-ventes-poc')}")
print("agent supprimé")
EOF

# 4) (optionnel) délier la facturation — retour en sandbox
gcloud billing projects unlink "$PROJECT_ID"
```

## Pour aller plus loin

- [docs/01-concepts.md](../../docs/01-concepts.md) — ce qu'est vraiment Dataplex
- [docs/03-agent-catalog-interaction.md](../../docs/03-agent-catalog-interaction.md) — le mécanisme en détail
- [docs/RUN-REEL-2026-07-07.md](../../docs/RUN-REEL-2026-07-07.md) — le run réel, pièges compris

## Fin

🎉 Tu sais maintenant **pourquoi** un agent conversationnel BigQuery répond juste : pas
par magie, mais parce qu'un humain a documenté ses colonnes — et que Dataplex est
l'outil qui rend ce travail tenable à l'échelle.
