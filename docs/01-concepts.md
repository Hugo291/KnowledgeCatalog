# 01 — Dataplex Universal Catalog : les concepts

## Le point de vocabulaire

Google a fusionné l'ancien **Data Catalog** dans **Dataplex**. Le produit
unifié s'appelle **Dataplex Universal Catalog**. Ce n'est **pas** un outil
qui « documente du code ». C'est le **catalogue de métadonnées + la
gouvernance** de toute ta donnée Google Cloud (BigQuery, Cloud Storage…).

L'impression de « documentation » vient de 5 briques qui, ensemble, décrivent
tes données :

| Brique | Ce que ça fait | Angle « documentation » |
|---|---|---|
| **Catalog / métadonnées** | Récupère automatiquement toutes tes tables/colonnes et permet de les **décrire** (descriptions, synonymes) | Doc *sémantique* : que veut dire cette colonne |
| **Data Lineage** | Trace **automatiquement** que `C` vient de `A`+`B` via telle requête | Doc *du code* : d'où vient la donnée |
| **Data Profiling** | Analyse les valeurs réelles (min/max, % nulls, top valeurs) | Doc *statistique* |
| **Data Quality (AutoDQ)** | Règles de qualité (unicité, plages, fraîcheur) | Doc *de confiance* |
| **Business Glossary** | Dictionnaire de termes métier reliés aux colonnes | Pont métier ↔ technique |

## La brique « catalogue » en détail

- **Harvesting automatique** : dès qu'une table BigQuery existe, Dataplex la
  voit. Tu n'importes rien.
- **Descriptions** : sur la table et sur chaque colonne. Elles vivent sur les
  **métadonnées BigQuery** ; Dataplex est la surface qui permet de les créer,
  générer (via Gemini) et gouverner à l'échelle. → *C'est ce que l'agent lit.*
- **Aspects / Aspect types** (nouveau modèle de tags) : métadonnées structurées
  supplémentaires (propriétaire, sensibilité, domaine…). Utile pour la
  gouvernance/recherche ; **pas** injecté automatiquement dans l'agent.
- **Recherche** : moteur de recherche transverse sur tout le patrimoine data.

## La brique « lineage » = la « doc du code »

C'est souvent ce que les gens appellent « documenter le code réalisé » :

- Quand ton projet BI exécute `CREATE TABLE fact_ventes AS SELECT … FROM commandes JOIN clients`,
  Dataplex **enregistre tout seul** le graphe : `fact_ventes ← commandes + clients`.
- Aucune écriture manuelle : il suffit d'activer l'API `datalineage`.
- Résultat : un graphe visuel « qui alimente quoi », au niveau table (et colonne
  pour BigQuery), qui documente les transformations sans que tu rédiges quoi que ce soit.

## Ce que Dataplex N'EST PAS

- ❌ Un moteur de requêtes (c'est BigQuery).
- ❌ L'agent conversationnel (c'est la Conversational Analytics API / Gemini).
- ❌ Un outil qui « écrit ta doc à ta place » — il **facilite** et **génère des
  brouillons** (Gemini), mais la qualité métier reste ton travail.

→ Suite : [02-architecture.md](02-architecture.md)
