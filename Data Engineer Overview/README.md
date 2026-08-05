# Databricks Pipeline
 
A demo data engineering pipeline built on Databricks, using the **Wanderbricks** simulated travel booking dataset. The project walks through ingesting raw booking data and transforming it through a structured pipeline — suitable as a learning reference or a starting point for production lakehouse patterns.
 
---
 
## Overview
 
The pipeline uses the [Wanderbricks dataset](https://docs.databricks.com/aws/en/discover/wanderbricks-dataset), Databricks' built-in sample dataset that models a vacation rental marketplace. It covers users, hosts, property listings, bookings, payments, reviews, and clickstream activity.
 
This repo contains:
 
- `wanderbricks_bookings_demo.csv` — a 55-row sample extract of the bookings table, usable without Unity Catalog access
- `Demo Pipeline/` — Databricks notebooks implementing the pipeline logic
---
 
## Dataset
 
The Wanderbricks `bookings` table includes the following key fields:
 
| Field | Description |
|---|---|
| `booking_id` | Unique booking identifier |
| `user_id` | Guest who made the booking |
| `property_id` | Property being booked |
| `check_in` | Check-in date |
| `check_out` | Check-out date |
| `guest_count` | Number of guests |
| `total_amount` | Total booking value |
| `status` | Booking status (e.g. confirmed, cancelled) |
 
The full Wanderbricks schema also includes related tables — `users`, `hosts`, `properties`, `payments`, `booking_updates`, `reviews`, `clickstream`, `pageviews`, `support_logs`, and `destinations` — which can be accessed via `samples.wanderbricks.*` in any Unity Catalog-enabled Databricks workspace.
 
---
## Pipeline Structure
 
The `Demo Pipeline/` folder contains notebooks that implement the pipeline stages:
 
```
Demo Pipeline/
├── 1_Ingest        # Load raw CSV / source table into the Bronze layer
├── 2_Transform     # Clean and enrich data into the Silver layer
└── 3_Aggregate     # Build analytics-ready Gold layer tables
```
 
Each notebook is self-contained and can be run individually or chained as a Databricks Workflow.
 
---