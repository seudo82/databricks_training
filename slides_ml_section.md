---
marp: true
theme: default
paginate: false
style: |
  /* ── base (dark) ── */
  section {
    background: #1C1C1E;
    color:      #F5F5F7;
    font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
    font-size: 26px;
    padding: 72px 80px;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }

  /* ── light variant ── */
  section.light {
    background: #FFFFFF;
    color: #1C1C1E;
  }

  /* ── hero: big centered text ── */
  section.hero {
    text-align: center;
    align-items: center;
  }

  /* ── typography ── */
  h1 {
    font-size: 3.4em;
    font-weight: 800;
    letter-spacing: -2px;
    line-height: 1.05;
    color: #F5F5F7;
    margin: 0 0 20px 0;
  }
  section.light h1 { color: #1C1C1E; }
  section.hero  h1 { color: #F5F5F7; }

  h2 {
    font-size: 1.5em;
    font-weight: 700;
    color: #E55A2B;
    margin: 0 0 28px 0;
    letter-spacing: -0.5px;
  }
  section.light h2 { color: #1C3D5A; }

  p  { line-height: 1.55; margin: 6px 0; }
  strong { color: #E55A2B; }
  em     { color: #8E8E93; font-style: normal; }

  /* ── code ── */
  code {
    font-family: 'Cascadia Code', 'Courier New', monospace;
    font-size: 0.80em;
    background: rgba(255,255,255,0.09);
    color: #FFB340;
    padding: 2px 8px;
    border-radius: 4px;
  }
  section.light code {
    background: #F0F4F8;
    color: #1C3D5A;
  }
  pre {
    background: rgba(255,255,255,0.05);
    border-left: 3px solid #E55A2B;
    padding: 20px 24px;
    border-radius: 0 8px 8px 0;
    font-size: 0.78em;
    line-height: 1.6;
  }
  section.light pre {
    background: #F4F6F9;
    border-left: 3px solid #E55A2B;
  }
  pre code { background: transparent; color: #F5F5F7; padding: 0; }
  section.light pre code { color: #1C3D5A; }

  /* ── tables ── */
  table { width: 100%; border-collapse: collapse; }
  th {
    background: #E55A2B;
    color: #FFFFFF;
    padding: 12px 18px;
    font-weight: 700;
    text-align: left;
  }
  td {
    padding: 10px 18px;
    border-bottom: 1px solid rgba(255,255,255,0.08);
  }
  section.light td { border-bottom: 1px solid #EBEBEB; }

  /* ── blockquote ── */
  blockquote {
    border: none;
    border-left: 3px solid #E55A2B;
    padding: 4px 0 4px 28px;
    font-size: 1.25em;
    font-weight: 600;
    line-height: 1.55;
    color: #F5F5F7;
    margin: 16px 0;
  }
  section.light blockquote { color: #1C1C1E; }
---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 1 — COVER                        ║
  ╚══════════════════════════════════════════╝
-->
<!-- _class: hero -->

# ML Engineer Overview

**Predicting Booking Cancellations**

*Module 4 · Wanderbricks Training Session*

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 2 — THE CHALLENGE                ║
  ╚══════════════════════════════════════════╝
-->

## The Challenge

> "Rising cancellation rates are hurting revenue.  
> Can we predict which bookings will cancel  
> before they do?"

Binary classification. Early intervention. Real business impact.

**Target:** `is_cancelled` — scored at booking time, not after.

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 3 — THE DATA                     ║
  ╚══════════════════════════════════════════╝
-->
<!-- _class: light -->

## Zero Setup. Five Tables.

`samples.wanderbricks` is built into every Databricks workspace.

| Table | Key signal |
|---|---|
| `bookings` | Dates, amount, status → **target** |
| `users` | Tenure, loyalty tier → commitment |
| `properties` | Type, rating → quality signal |
| `payments` | Method, timing → intent signal |

*`reviews` excluded — post-stay data is leakage.*

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 4 — FEATURE ENGINEERING          ║
  ╚══════════════════════════════════════════╝
-->

## 4 Tables. 13 Features. 1 Spark Job.

```python
df = (
    bookings
    .join(users,      on='user_id',     how='left')
    .join(properties, on='property_id', how='left')
    .join(payments,   on='booking_id',  how='left')
    .withColumn('lead_time_days',   datediff('check_in_date', 'booking_date'))
    .withColumn('user_tenure_days', datediff('booking_date',  'signup_date'))
    .withColumn('is_cancelled',     when(col('status') == 'cancelled', 1).otherwise(0))
)
```

Same code. Any cluster size. Any data volume.

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 5 — MLFLOW HERO                  ║
  ╚══════════════════════════════════════════╝
-->
<!-- _class: hero -->

# One line.
# Everything tracked.

```python
mlflow.sklearn.autolog()
```

Parameters · Metrics · Model artifact · Feature importance  
*Automatically.*

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 6 — THE RESULT                   ║
  ╚══════════════════════════════════════════╝
-->
<!-- _class: light hero -->

## The Result

# AUC 0.84

A model that always predicts *"not cancelled"* scores AUC **0.50**.  
Ours scores **0.84** — it actually learned something.

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 7 — EXPERIMENT UI                ║
  ╚══════════════════════════════════════════╝
-->
<!-- _class: light -->

## Every Run, Fully Audited

Navigate: **Experiments → wanderbricks_cancellation**

| Captured automatically | How |
|---|---|
| `n_estimators`, `max_depth`, `class_weight` | `autolog()` |
| accuracy, F1, precision, recall | `autolog()` |
| Model artifact + feature importance plot | `autolog()` |
| `test_roc_auc` | One `mlflow.log_metric()` call |

*Six months from now, you'll know exactly what produced this model.*

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 8 — SAVE & DEPLOY                ║
  ╚══════════════════════════════════════════╝
-->

## Save. Load. Promote.

**Free edition** — load directly from the run
```python
mlflow.sklearn.load_model('runs:/' + run_id + '/model')
```

**Paid workspace** — stable alias, never change pipeline code
```python
mlflow.pyfunc.load_model(
    'models:/main.default.cancellation_predictor@champion'
)
# Promote a new version? Move the alias. Done.
```

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 9 — CI/CD                        ║
  ╚══════════════════════════════════════════╝
-->

## From Notebook to Production

```
Push to GitHub
      ↓
GitHub Actions  →  databricks bundle deploy  →  staging workspace
      ↓
Automated tests pass  →  @champion alias promoted in prod
      ↓
Inference pipeline loads @champion  —  no code changes ever
```

*Git versioning works today on free edition.  
Multi-environment CI/CD requires a trial or paid workspace.*

---

<!--
  ╔══════════════════════════════════════════╗
  ║   SLIDE 10 — CLOSE                       ║
  ╚══════════════════════════════════════════╝
-->
<!-- _class: hero -->

**Spark** handles the data at any scale.

**MLflow** tracks every experiment automatically.

**Unity Catalog** governs model versions in production.

<br>

*Notebook: `04_ML_Cancellation_Predictor.ipynb`*
