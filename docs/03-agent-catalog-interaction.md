# 03 — Comment l'agent interagit *réellement* avec le catalogue

> La question la plus importante — et la plus mal comprise.

## Il n'y a PAS de tuyau magique

L'agent ne « fait pas un appel à Dataplex » à chaque question. Le mécanisme
réel tient en **deux plans** :

```
     TOI / Dataplex                          L'AGENT
  (plan de CONTRÔLE)                      (plan de LECTURE)
  ─────────────────────                   ──────────────────
  Tu édites descriptions,     écrit        L'agent lit le SCHÉMA
  glossaire, tags dans   ───────────────►  + DESCRIPTIONS des tables
  Dataplex Catalog          (write-back)   directement depuis BigQuery,
                                           au moment de générer le SQL
```

**Les descriptions ne vivent pas *dans* Dataplex** : elles vivent sur la table
BigQuery. Dataplex est la surface qui les écrit (write-back). L'agent lit les
métadonnées **BigQuery**. Donc documenter dans Dataplex = alimenter ce que
l'agent lira.

Ce que l'agent « voit » est littéralement ceci :

```sql
SELECT column_name, data_type, description
FROM `mon-projet.retail_poc`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS
WHERE table_name = 'fact_ventes';
```

Si `description` est vide → l'agent est aveugle. (C'est exactement ce que
lit notre `agent/build_context.py`.)

## Ce qui se passe à CHAQUE question

1. **Sélection des tables** — s'il y en a beaucoup, une étape de *retrieval*
   choisit les tables pertinentes (là, la recherche du catalogue peut servir).
2. **Lecture schéma + descriptions** des tables retenues (API BigQuery /
   `INFORMATION_SCHEMA`). ← *le vrai point de contact avec la « doc »*
3. **Assemblage du prompt** : `system_instruction` + schémas + descriptions +
   synonymes + valeurs d'exemple + golden queries.
4. **Gemini génère le SQL**.
5. **Validation** (dry-run) contre BigQuery.
6. **Exécution** + réponse en langage naturel (+ éventuel graphique).

## L'implication pratique (à retenir absolument)

> **Le canal automatique et fiable = la description sur la table/colonne
> BigQuery.** Le reste (glossaire, profiling, golden queries) doit être
> **recopié dans le contexte de l'agent** — ce n'est pas aspiré tout seul.

Donc :
- Ne mets pas ta doc *uniquement* dans un aspect/tag Dataplex en pensant que
  l'agent la lira. Mets l'essentiel dans la **description de colonne**
  (Dataplex le fait en un clic, write-back sur BigQuery).
- Enrichis le `system_instruction` de l'agent avec les règles métier fortes
  (« CA = SUM(mnt_ht) », « client actif = statut 'A' »), les jointures et
  quelques *golden queries*.

C'est précisément ce que fait ce POC :
`build_context.py` **lit les descriptions** (canal fiable) et **ajoute** les
règles métier + jointures dans la `system_instruction`.

## Deux façons de passer le contexte à l'agent

| Méthode | Quand | Dans le POC |
|---|---|---|
| **Agent persistant** (`create_data_agent`) | réutilisable, partageable, gouverné | `create_agent.py` |
| **Contexte inline** (`inline_context` du `chat`) | test rapide, une session | `ask.py --inline` |

→ Suite : [04-poc-guide.md](04-poc-guide.md)
