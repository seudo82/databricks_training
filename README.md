# Databricks Training

Hands-on training materials for a 3-hour Databricks overview session.  
Dataset: `samples.wanderbricks` — a built-in fictional travel booking platform available in all Databricks workspaces.

---

## Session Outline

| # | Section | Notebook | Duration |
|---|---|---|---|
| 1 | Databricks Fundamentals | — | ~30 min |
| 2 | Data Analyst Overview | — | ~30 min |
| 3 | Data Engineer Overview | — | ~30 min |
| 4 | **ML Engineer Overview** | `04_ML_Cancellation_Predictor.ipynb` | ~40 min |
| 5 | GenAI Engineer Overview | — | ~20 min |

---

## ML Notebook

**`04_ML_Cancellation_Predictor.ipynb`**

Business story: *Predict whether a Wanderbricks booking will be cancelled, so the ops team can intervene early.*

Covers:
- Feature engineering with Apache Spark (joins, `withColumn`, `datediff`)
- Binary classification with scikit-learn `RandomForestClassifier`
- Experiment tracking with MLflow autologging
- MLflow Experiment UI walkthrough
- Model save and load via MLflow run URI
- CI/CD conceptual overview (Databricks Asset Bundles, GitHub Actions)

### Slides

`slides_ml_section.md` — Marp-format presentation slides for the ML section.  
Open with the [Marp for VS Code](https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode) extension or export to PDF/PPTX via the Marp CLI.

---

## Requirements

- Databricks Individual (free) edition or higher
- Databricks Runtime 11.x or later (MLflow pre-installed, no `%pip install` needed)
- `samples.wanderbricks` catalog (available by default in Databricks workspaces)

---

## How to Import the Notebook into Databricks

1. In Databricks, click **Workspace** in the left sidebar
2. Right-click your target folder → **Import**
3. Select **File** and upload `04_ML_Cancellation_Predictor.ipynb`
4. Attach to a running cluster
5. Run all cells top-to-bottom

> **Important:** Start your cluster *before* the session — free edition clusters take a few minutes to start and auto-terminate when idle.

---

## Known Limitations (Free Edition)

| Feature | Free Edition | Paid / Trial |
|---|---|---|
| MLflow experiment tracking | Yes | Yes |
| MLflow model registry (Unity Catalog) | No | Yes |
| Multi-environment CI/CD deployment | No | Yes |
| Databricks Repos (Git integration) | Limited | Full |
| Databricks Workflows / Jobs | Limited | Full |

Steps marked **Paid feature** in the notebook describe what you would do in a paid or trial workspace.
