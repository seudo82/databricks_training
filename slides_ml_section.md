---
marp: true
theme: default
paginate: true
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    font-size: 26px;
    padding: 48px;
  }
  h1 { color: #E55A2B; font-size: 2em; }
  h2 { color: #1C3D5A; border-bottom: 2px solid #E55A2B; padding-bottom: 8px; }
  h3 { color: #1C3D5A; }
  code { background: #f0f4f8; padding: 2px 8px; border-radius: 4px; font-size: 0.85em; }
  pre { background: #f0f4f8; border-left: 4px solid #E55A2B; padding: 16px; border-radius: 4px; }
  table { width: 100%; border-collapse: collapse; }
  th { background: #1C3D5A; color: white; padding: 8px 12px; }
  td { padding: 8px 12px; border-bottom: 1px solid #ddd; }
  blockquote { border-left: 4px solid #E55A2B; padding-left: 16px; color: #555; background: #fff8f6; margin: 16px 0; }
  .tag { background: #E55A2B; color: white; padding: 2px 10px; border-radius: 12px; font-size: 0.75em; }
---

# ML Engineer Overview
## Predicting Booking Cancellations with Databricks

**Wanderbricks Training Session — Module 4**

*Dataset: `samples.wanderbricks`*

---

## Agenda

1. The business problem
2. The Databricks ML lifecycle
3. Explore data in Unity Catalog
4. Feature engineering with Spark
5. Train with MLflow autologging
6. MLflow Experiment UI
7. Evaluate the model
8. Save and load the model
9. CI/CD in Databricks
10. Summary and next steps

*Estimated time: 35–40 minutes*

---

## The Business Problem

**Wanderbricks** — a fictional travel booking platform

> "The customer ops team has flagged rising cancellation rates.  
> Can we predict which new bookings are likely to cancel  
> so we can intervene early?"

**ML question:** Binary classification
- **Target:** `is_cancelled` (1 = cancelled, 0 = not cancelled)
- **Use case:** Score new bookings at time of booking, not after

**Business value:**
- Send early incentives or reminders to at-risk bookings
- Optimise inventory and revenue forecasting
- Reduce last-minute gaps in the calendar

---

## The Databricks ML Lifecycle

```
samples.wanderbricks        Feature           MLflow
    (Unity Catalog)    →  Engineering  →   Autologging
                           (Spark)          (tracking)
                              |                 |
                              v                 v
                          sklearn RF      Experiment UI
                          Classifier   (params, metrics,
                              |           artifacts)
                              v
                        Model saved      CI/CD Pipeline
                        to MLflow   →  (paid workspaces)
                        run URI
```

**Three platforms, one workflow:** Spark + MLflow + Unity Catalog

---

## The Dataset: `samples.wanderbricks`

Available in every Databricks workspace — no upload needed.

| Table | What it contains |
|---|---|
| `bookings` | Booking ID, status, dates, amount, guests |
| `users` | User profile, signup date, loyalty tier |
| `properties` | Property type, location, average rating |
| `payments` | Payment method, payment date |
| `reviews` | Guest reviews — **not used** (data leakage) |

```sql
-- Run in a %sql cell to see all tables
SHOW TABLES IN samples.wanderbricks
```

---

## Section 1: Explore the Data

```python
bookings_raw = spark.read.table('samples.wanderbricks.bookings')
display(bookings_raw)
```

**`display()` — not `.show()`**

| `.show()` | `display()` |
|---|---|
| Plain text output | Interactive table |
| Fixed rows | Sortable, filterable |
| No charts | Built-in chart builder |

```sql
%sql
SELECT status, COUNT(*) AS booking_count
FROM samples.wanderbricks.bookings
GROUP BY status ORDER BY booking_count DESC
```

> Always run `DESCRIBE TABLE` first to confirm column names before feature engineering.

---

## Section 2: Feature Engineering with Spark

**Join strategy — `bookings` is the anchor (LEFT JOINs):**

```
bookings → users      (user tenure, age, loyalty tier)
         → properties (property type, avg rating)
         → payments   (payment method, days to payment)
```

**Why LEFT JOIN?** Preserves all bookings even if payment record is missing.

**Why NOT join `reviews`?**
> Reviews are written *after* the stay.  
> Using them to predict cancellation = **data leakage**.

---

## Section 2: Derived Features

| Feature | Derivation | Signal |
|---|---|---|
| `is_cancelled` | `status == 'cancelled'` | **Target** |
| `lead_time_days` | `check_in - booking_date` | Long lead = higher risk |
| `length_of_stay` | `check_out - check_in` | Stay length pattern |
| `booking_month` | `month(booking_date)` | Seasonality |
| `user_tenure_days` | `booking - signup_date` | New user = higher risk |
| `days_to_payment` | `payment - booking_date` | Delay = cancel signal |
| `loyalty_tier` | Direct column | Loyal = lower risk |
| `property_type` | Direct column | Type-specific patterns |
| `payment_method` | Direct column | Method correlates with intent |

---

## Section 2: Spark → Pandas Handoff

```python
df_features = df.select(*feature_cols)

# Convert to Pandas for scikit-learn
df_pd = df_features.toPandas()

print('Cancellation rate: {:.1%}'.format(df_pd['is_cancelled'].mean()))
```

**Why this split?**

| Spark | Pandas + sklearn |
|---|---|
| Heavy lifting — joins, derivations | Familiar ML code |
| Scales to billions of rows | Simple `fit()` / `predict()` |
| Same code in production | Works on free edition |

In production: keep everything in Spark or use **Spark MLlib / MLflow with Spark UDFs**.

---

## Section 3: MLflow Autologging

```python
mlflow.set_experiment('/Users/wanderbricks_cancellation')

mlflow.sklearn.autolog(log_input_examples=True,
                       log_model_signatures=True)

with mlflow.start_run(run_name='rf_baseline_v1') as run:
    rf = RandomForestClassifier(
        n_estimators=100,
        max_depth=8,
        class_weight='balanced',  # minority class handling
        random_state=42
    )
    rf.fit(X_train, y_train)
    mlflow.log_metric('test_roc_auc', test_auc)
```

**`mlflow.sklearn.autolog()` captures automatically:**
- All hyperparameters
- Accuracy, F1, precision, recall
- Model artifact + feature importance plot

---

## Why `class_weight='balanced'`?

**The imbalanced class problem:**

```
All bookings:   ████████████████░░░░  (15% cancelled)

Without balance:  Model learns → always predict "not cancelled"
                  Accuracy = 85% ✓   AUC = 0.50 ✗  (useless)

With balanced:    Model learns the cancellation pattern
                  Accuracy = 79% ✓   AUC = 0.82 ✓  (useful)
```

> **Accuracy is misleading for imbalanced classes.**  
> AUC is the right metric — it measures ranking quality, not raw hit rate.

---

## Section 4: MLflow Experiment UI

> **Live demo — no new code**

Navigate: **Experiments** (left sidebar) → **wanderbricks_cancellation**

| Tab | What to show |
|---|---|
| **Parameters** | `n_estimators=100`, `max_depth=8`, `class_weight=balanced` |
| **Metrics** | accuracy, F1, precision, recall, `test_roc_auc` |
| **Artifacts** | Model file, `MLmodel` manifest, feature importance chart |

**Key insight:**

> This is your audit trail. Six months from now you know exactly  
> what data, code, and parameters produced this model —  
> without a spreadsheet.

**Try:** Run training again with `n_estimators=50` → **Compare runs**

---

## Section 5: Evaluate the Model

**Three outputs — no more:**

### 1. AUC Score
```
Test AUC: 0.84
```

### 2. Confusion Matrix
Shows true positives, false positives, true negatives, false negatives visually.

### 3. Feature Importance
Which features drove the prediction most — useful for business discussion.

**Not included (intentionally cut):**
ROC curve, SHAP values, calibration plots — valuable, but out of scope for this session.

---

## Section 6: Save and Load the Model

**Free edition — load from run URI:**

```python
model_uri = 'runs:/' + run_id + '/model'
loaded_model = mlflow.sklearn.load_model(model_uri)

predictions = loaded_model.predict(X_test.head(5))
```

**Paid workspace — Unity Catalog model registry:**

```python
mlflow.set_registry_uri('databricks-uc')
mlflow.register_model(model_uri, 'main.default.cancellation_predictor')

client.set_registered_model_alias(
    'main.default.cancellation_predictor', 'champion', version
)

# Stable production reference — never changes on version promotion
mlflow.pyfunc.load_model('models:/main.default.cancellation_predictor@champion')
```

---

## Section 7: CI/CD in Databricks

```
Developer pushes notebook to GitHub
         |
         v
GitHub Actions triggers on PR / merge
         |
         v
databricks bundle deploy  →  staging workspace
         |
         v
Databricks Workflow runs tests
(unit tests + model quality check)
         |
         v
Pass: @champion alias promoted in prod
         |
         v
Inference pipeline loads @champion  (no code changes)
```

---

## CI/CD: Key Tools

| Tool | Role |
|---|---|
| **Databricks Asset Bundles (DABs)** | Infrastructure-as-code — `databricks.yml` defines notebooks, jobs, clusters |
| **Databricks CLI** | Runs `databricks bundle deploy` from GitHub Actions |
| **MLflow Model Registry** | Versioning, aliases (`@champion`), lineage — *paid feature* |
| **Databricks Workflows** | Scheduled and event-triggered job orchestration |

**What you can do on free edition today:**
- Version this notebook in Git via **Repos** (workspace sidebar)
- Commit and push to GitHub
- The multi-environment deployment step needs a trial/paid workspace

---

## Summary

| Step | Tool | Key takeaway |
|---|---|---|
| Data access | `spark.read.table()` | No connection strings — governed by Unity Catalog |
| Feature engineering | PySpark `withColumn()` | Scales to any data size |
| Training | sklearn + `mlflow.autolog()` | One line = full experiment tracking |
| Experiment tracking | MLflow UI | Reproducible, auditable, comparable |
| Model saving | MLflow run URI | Portable; works on free edition |
| Model registry | Unity Catalog (paid) | Stable `@champion` alias for production |
| CI/CD | DABs + GitHub Actions | Automated, governed ML deployment |

---

## What to Try Next

**In the notebook (try these now):**
- Change `n_estimators` or `max_depth` → compare runs in the Experiment UI
- Remove `class_weight='balanced'` → watch accuracy rise but AUC fall
- Add more countries to the one-hot encoding

**Explore after this session:**
- **Databricks AutoML** — automated feature engineering + model selection
- **MLflow Model Registry** — versioning and `@champion` aliases (trial workspace)
- **Databricks Workflows** — schedule this notebook as an automated job
- **Feature Store** — centralised, reusable feature definitions

---

# Thank You

**Questions?**

*Module 4 — ML Engineer Overview*  
*Wanderbricks Training Session*

> Notebook: `04_ML_Cancellation_Predictor.ipynb`  
> Dataset: `samples.wanderbricks`  
> Workspace: Databricks Individual (free) edition
