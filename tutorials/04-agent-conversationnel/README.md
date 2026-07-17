# Tutoriel 04 — L'agent conversationnel

⏱️ ~15 min · 🎯 Créer l'agent, lui poser une question en français, et voir qu'il utilise le catalogue.

## Objectif

La récompense. Tu crées un agent (Conversational Analytics API) avec le contexte du
tutoriel 03, tu lui demandes le CA, et tu constates qu'il génère le **bon SQL** —
parce qu'il a lu tes descriptions.

## Prérequis

[Tutoriel 03](../03-contexte-agent/) terminé (`agent/context.json` existe, venv actif).

## Étapes

### 1. Créer l'agent

```bash
python create_agent.py
```

Ce que fait [`create_agent.py`](../../agent/create_agent.py) : il donne à l'agent
**deux choses**, et rien d'autre.

```python
# 1) Sur quelles tables il a le droit de générer du SQL
datasources.bq.table_references = table_refs

# 2) Le contexte issu du catalogue
published.system_instruction = ctx["system_instruction"]
published.datasource_references = datasources
```

### 2. Poser une question

```bash
python ask.py "Quel est le CA des clients actifs en 2025 ?"
```

### 3. D'autres questions à essayer

```bash
python ask.py "Top 5 des produits par CA sur le canal Online"
python ask.py "Combien de clients actifs par segment ?"
python ask.py --inline "Compare le CA physique vs online par trimestre"
```

`--inline` passe le contexte directement, sans agent persistant — pratique pour itérer.

## Résultat attendu

Résultat **réel** obtenu le 7 juillet 2026 :

```
--- SQL généré par l'agent ---
SELECT
  SUM(fact_ventes.mnt_ht) AS chiffre_affaires
FROM `…retail_poc.fact_ventes` AS fact_ventes
INNER JOIN `…retail_poc.dim_client` AS dim_client
  ON fact_ventes.client_key = dim_client.client_key
INNER JOIN `…retail_poc.dim_date` AS dim_date
  ON fact_ventes.date_key = dim_date.date_key
WHERE dim_client.statut = 'A'
  AND dim_date.annee = 2025;

### Analyse du Chiffre d'Affaires 2025
En 2025, le chiffre d'affaires total réalisé auprès des clients actifs s'élève à
**2 864 226,45 € HT**. …
```

![L'agent répond dans Cloud Shell : SQL généré + réponse en français](../../assets/screenshots/03-agent-reponse.png)

*Capture réelle (re-run du 17 juillet 2026). On y voit le SQL généré par l'agent puis sa
réponse : « le Chiffre d'Affaires (CA) réalisé par les clients actifs s'élève à
**2 864 226,45 €** HT ».*

> 💡 **Détail instructif** : ce re-run, 10 jours après le premier, redonne **exactement
> le même montant** — mais écrit le SQL autrement (alias `ventes`/`client`/`calendrier`,
> et `LOWER(client.statut) = 'a'` au lieu de `statut = 'A'`). L'agent n'est **pas
> déterministe dans la forme**, mais le catalogue le contraint sur le **sens** : bonne
> colonne, bon filtre, bon résultat. C'est exactement ce qu'on attend d'un bon contexte.
>
> Amusant : dans son raisonnement interne (en anglais), il traduit « CA » par *« Customer
> Acquisition cost »* — mais son SQL et sa réponse française restent justes, parce que la
> **description de `mnt_ht`** lui donne la formule sans ambiguïté. La description ancre
> le modèle même quand sa prose dérive.

## 🔍 La preuve — l'agent cite le catalogue

Dans son raisonnement, l'agent a écrit (verbatim) :

> *"I've also double-checked the specific rules provided: **'Le chiffre d'affaires (CA)
> se calcule TOUJOURS avec SUM(mnt_ht)'** — this crucial metadata dictates how the
> revenue is calculated. **'Un client actif est un client dont dim_client.statut = A'**
> — this definition is fundamental […] and was correctly applied."*

👉 Trois choses à remarquer dans le SQL :
1. `SUM(mnt_ht)` et pas `mnt_ttc` → il a lu la description de `mnt_ht`.
2. `statut = 'A'` → il a lu la description de `statut`.
3. Les `INNER JOIN` corrects → il a lu les jointures du contexte.

**Rien de tout ça n'est deviné.** Tout vient du catalogue.

## Vérifier — le test A/B « sans catalogue »

Le seul test qui prouve quelque chose : **mêmes données, catalogue en moins**.

```bash
# 1) Des copies SANS descriptions (un CTAS ne copie PAS les descriptions)
bash -c 'set -a; source ../.env; set +a; \
  sed -e "s/\${PROJECT_ID}/$PROJECT_ID/g" -e "s/\${DATASET}/$DATASET/g" \
  ../sql/04_tables_sans_descriptions.sql | bq query --use_legacy_sql=false'

# 2) La même question, sur les tables nues, sans aucune règle métier
python demo_sans_catalogue.py
```

La requête de vérification de `sql/04` le confirme : toutes les descriptions des tables
`*_nue` sont **`NULL`**.

### Le résultat réel — attention, il surprend

![L'agent sans catalogue : deux chiffres et une hypothèse](../../assets/screenshots/08-agent-sans-catalogue.png)

**L'agent sans catalogue ne s'est PAS planté.** Il a même retrouvé le bon montant. Mais
regarde *comment* :

| | **Avec** catalogue | **Sans** catalogue |
|---|---|---|
| Réponse | **un** chiffre : 2 864 226,45 € | **deux** chiffres : 2 864 226,45 € HT **et** 3 437 071,65 € TTC |
| « CA » | **su** (description de `mnt_ht`) | **deviné** — dans le doute, il calcule les deux |
| « client actif » | **su** (`statut='A'`) | **supposé** — il infère que « A » = « Actif » |
| Le filtre métier | `WHERE statut = 'A'` appliqué | **pas appliqué** — il fait un `GROUP BY statut` et te laisse trancher |

Ses propres mots (verbatim) :

> *"I will proceed with the **assumption** that 'active clients' exclusively refers to
> those with `statut = 'A'` […] I intend to clearly state this **assumption** […]"*

### La vraie leçon (plus nuancée que « ça marche pas »)

> Le catalogue ne fait pas la différence entre **juste et faux**.
> Il fait la différence entre **savoir et supposer**.

Trois conséquences concrètes :

1. **L'ambiguïté remonte à l'utilisateur.** Deux chiffres au lieu d'un : c'est à
   l'humain d'arbitrer HT vs TTC. Dans un rapport automatisé, c'est inexploitable.
2. **L'hypothèse peut être silencieusement fausse.** Ici « A » = Actif, bravo. Mais si
   « A » avait voulu dire *Archivé* ou *Annulé*, l'agent aurait produit un chiffre
   faux — avec la même assurance. Rien ne l'aurait signalé.
3. **Notre schéma est trop gentil.** `mnt_ht`, `mnt_ttc`, `statut`, `annee`, valeurs
   `A`/`I`/`P` : des noms français explicites et des valeurs lisibles. Gemini a
   rétro-conçu le sens. **Sur un vrai schéma BI** (`cust_st`, `mt_1`, `flag_3`, codes
   `1`/`2`/`9`), il n'a plus rien à quoi se raccrocher — et là, il invente.

C'est donc un argument **plus solide** que « sans catalogue ça plante » : le catalogue
achète de la **reproductibilité** et de l'**auditabilité**. Sans lui, ta réponse dépend
d'une devinette qui, un jour, sera fausse sans prévenir.

## Pièges connus

| Symptôme | Cause | Solution |
|---|---|---|
| `PermissionDenied` / `403` sur `geminidataanalytics` | API non activée ou facturation absente | [Tutoriel 00](../00-prerequis/) |
| `AlreadyExists` | L'agent existe déjà | Normal : `create_agent.py` bascule en `update` |
| Sortie vide de `ask.py` | Noms de champs de l'API modifiés | `DEBUG=1 python ask.py "…"` pour voir le flux brut |
| L'agent répond à côté | Descriptions trop vagues | Enrichis les descriptions ([tutoriel 01](../01-schema-etoile/)) puis **rejoue le [tutoriel 03](../03-contexte-agent/)** |

## Suite

➡️ [Tutoriel 05 — Maintenir le catalogue](../05-maintenir-le-catalogue/) — parce qu'un
catalogue qui vieillit produit un agent qui se trompe.
