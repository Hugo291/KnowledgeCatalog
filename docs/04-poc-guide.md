# 04 — Guide pas-à-pas du POC (+ captures d'écran à prendre)

> Suis les étapes ; à chaque 📸 prends la capture indiquée et range-la dans
> `assets/screenshots/` avec le nom suggéré. Tu obtiendras un dossier de preuve
> complet du POC.

## Prérequis

- Projet GCP avec **facturation activée**.
- **Google Cloud SDK** installé : `gcloud`, `bq`.
  - macOS : `brew install --cask google-cloud-sdk` puis `gcloud init` et `gcloud auth application-default login`.
- **Python 3.10+**.
- Rôles IAM utiles : `BigQuery Admin`, `Dataplex Editor`, `Gemini Data Analytics` (ou `Owner` pour un POC).

```bash
mkdir -p assets/screenshots
cp .env.example .env      # puis édite PROJECT_ID + régions
```

---

## Étape 1 — Créer le schéma en étoile + le catalogue

```bash
bash scripts/00_setup_env.sh     # APIs
bash scripts/01_bigquery.sh      # schéma + données + descriptions
```

📸 **`01_bigquery_schema.png`** — Console BigQuery, dataset `retail_poc`
déplié montrant `fact_ventes` + les `dim_*`.
🔗 `https://console.cloud.google.com/bigquery`

📸 **`02_table_descriptions.png`** — Onglet **Schema** de `fact_ventes` :
on voit la colonne **Description** remplie (mnt_ht = « … CA = SUM(mnt_ht) »).
👉 *C'est la preuve visuelle de ce que l'agent va lire.*

---

## Étape 2 — Lineage + Profiling + Qualité (Dataplex)

```bash
bash scripts/02_dataplex_scans.sh
```

📸 **`03_lineage.png`** — Sur `fact_ventes`, onglet **Lineage** : le graphe
montre `dim_produit → fact_ventes` (créé par le `JOIN` du chargement).
👉 *La « doc du code » générée automatiquement.*

📸 **`04_profiling.png`** — Dataplex > Profiling du scan `profile-fact-ventes` :
distribution de `mnt_ht`, `quantite`, valeurs de `statut`…
🔗 `https://console.cloud.google.com/dataplex/govern`

📸 **`05_quality.png`** — Résultat du scan `quality-fact-ventes` : règles
PASS/FAIL (unicité `vente_id`, `mnt_ht ≥ 0`, `remise_pct ∈ [0,1]`).

---

## Étape 3 — (Option) Enrichir dans la console

Deux gestes qui « vendent » bien Dataplex en démo :

1. **Génération de description par Gemini** : ouvre une table sans description,
   clique **Generate** (icône Gemini) → une description est proposée.
   📸 **`06_gemini_generate_metadata.png`**
2. **Glossaire métier** : Dataplex > Glossaire, crée un terme « Chiffre
   d'affaires » relié à `fact_ventes.mnt_ht`.
   📸 **`07_glossary_term.png`**

---

## Étape 4 — Construire le contexte depuis le catalogue

```bash
cd agent
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python build_context.py
```

📸 **`08_build_context.png`** — Le terminal : « ✅ Toutes les colonnes ont une
description » + l'aperçu de la `system_instruction`.
👉 *Preuve que le catalogue est bien lu et transformé en contexte d'agent.*

---

## Étape 5 — Créer l'agent et l'interroger

```bash
python create_agent.py
python ask.py "Quel est le CA des clients actifs en 2025 ?"
python ask.py "Top 5 des produits par CA sur le canal Online"
```

📸 **`09_agent_answer.png`** — Le terminal : la question, le **SQL généré**
(avec `SUM(mnt_ht)` et `statut='A'`), et la réponse en français.
👉 *La démonstration finale : le catalogue a produit le bon SQL.*

Astuce démo sans agent persistant :
```bash
python ask.py --inline "Compare le CA physique vs online par trimestre"
```

📸 **`10_console_agent.png`** *(optionnel)* — Le même agent depuis l'UI
**Conversational Analytics** (Looker / BigQuery Studio > « Chat with your data »),
pour montrer l'expérience produit.

---

## La preuve « avant / après » (le meilleur argument)

Pour montrer l'impact du catalogue :

1. Crée une copie d'une table **sans description** :
   `CREATE TABLE retail_poc.fact_ventes_nue AS SELECT * FROM retail_poc.fact_ventes;`
2. Pointe un agent inline dessus et demande le CA.
3. 📸 **`11_before_no_desc.png`** — l'agent hésite / se trompe de colonne.
4. Repointe sur `fact_ventes` (avec descriptions) → réponse juste.
   📸 **`12_after_with_desc.png`**

C'est LA slide qui convainc : *mêmes données, la différence = le catalogue.*

---

## Récapitulatif des captures

| Fichier | Montre |
|---|---|
| `01_bigquery_schema.png` | Le schéma en étoile |
| `02_table_descriptions.png` | Les descriptions (ce que l'agent lit) |
| `03_lineage.png` | Lineage auto = doc du code |
| `04_profiling.png` | Profiling |
| `05_quality.png` | Qualité |
| `06_gemini_generate_metadata.png` | Description auto par Gemini |
| `07_glossary_term.png` | Glossaire métier |
| `08_build_context.png` | Catalogue → contexte agent |
| `09_agent_answer.png` | Réponse + SQL généré |
| `10_console_agent.png` | Agent dans l'UI |
| `11_before_no_desc.png` / `12_after_with_desc.png` | Avant/après catalogue |
