# Tutoriels — de zéro à un agent conversationnel BigQuery

Six tutoriels courts, à faire **dans l'ordre**. À la fin, tu poses une question en
français à un agent qui répond avec le bon SQL, parce qu'il s'appuie sur le catalogue.

> Chaque tutoriel est autonome : **objectif, prérequis, étapes, résultat attendu,
> vérification, pièges**. Les pièges listés sont ceux réellement rencontrés lors du
> [run du 7 juillet 2026](../docs/RUN-REEL-2026-07-07.md).

| # | Tutoriel | Tu apprends à… | Durée |
|---|---|---|---|
| 00 | [Prérequis & mise en route](00-prerequis/) | Préparer le projet GCP, la facturation, les APIs, le `.env` | 10 min |
| 01 | [Le schéma en étoile + les descriptions](01-schema-etoile/) | Créer `fact_ventes` + `dim_*` **avec le catalogue** | 10 min |
| 02 | [Dataplex : lineage, profiling, qualité](02-dataplex-scans/) | Faire tourner les scans et lire le lineage | 15 min |
| 03 | [Du catalogue au contexte de l'agent](03-contexte-agent/) | Lire les descriptions et en faire un contexte | 10 min |
| 04 | [L'agent conversationnel](04-agent-conversationnel/) | Créer l'agent et l'interroger en français | 15 min |
| 05 | [Maintenir le catalogue](05-maintenir-le-catalogue/) | Comprendre snapshot vs live, et rafraîchir | 10 min |

## Le fil rouge

Une seule idée traverse les six tutoriels :

> **L'agent n'appelle jamais Dataplex.** Il lit les **descriptions** (que Dataplex
> gère et pose sur BigQuery) + le **contexte** qu'on en a extrait. Dataplex est dans
> la boucle de *préparation*, pas d'*exécution*.

Si tu ne dois retenir qu'un tutoriel, c'est le [03](03-contexte-agent/) : c'est là que
le catalogue devient concrètement le cerveau de l'agent.

## Avant de commencer

- Un projet GCP **avec facturation activée** (voir [tutoriel 00](00-prerequis/)).
- Le repo cloné (ou Cloud Shell, qui a déjà `gcloud`, `bq`, `git`, `python`).
- Comprendre la théorie d'abord ? Lis [docs/01-concepts.md](../docs/01-concepts.md)
  et [docs/03-agent-catalog-interaction.md](../docs/03-agent-catalog-interaction.md).

## Coût

L'ensemble coûte **quelques centimes** (requêtes BigQuery minuscules, 2 scans
Dataplex à la demande, quelques appels Gemini). Le [tutoriel 05](05-maintenir-le-catalogue/)
explique comment tout supprimer à la fin.
