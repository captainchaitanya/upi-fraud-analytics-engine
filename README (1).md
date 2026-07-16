# UPI Fraud Analytics Engine

A SQL + Power BI analytics pipeline that detects and profiles fraudulent transaction patterns using the IEEE-CIS Fraud Detection dataset (590K+ transactions), built to mirror a real BFSI/fintech fraud-analyst deliverable — from raw data to a decision-ready dashboard.

## Overview

This project analyzes transaction-level data to surface fraud signals across time, device, product, and behavioral dimensions, then flags high-risk transactions using two independent detection methods: a **rolling 30-day risk-scoring pipeline** and a **10-minute transaction-velocity anomaly detector** — both built entirely with SQL window functions, not black-box ML.

**Dataset:** [IEEE-CIS Fraud Detection](https://www.kaggle.com/c/ieee-fraud-detection) (Kaggle) — real anonymized transaction + identity data, ~590K rows.

## Tech Stack

- **PostgreSQL** — schema design, joins, aggregation, window functions, CTEs
- **Power BI** — interactive dashboard, KPI cards, trend/breakdown visuals, drill-down tables
- **SQL window functions** — `LAG`, rolling `SUM`/`COUNT` over time-based `RANGE` frames, for both risk scoring and velocity detection

## Repository Structure

```
upi-fraud-analytics-engine/
├── sql/
│   ├── 01_schema.sql                  # Table setup (identity table + notes on transactions table)
│   ├── 02_fraud_master_view.sql       # Joined transactions + identity view, with derived timestamps
│   ├── 03_fraud_rate_analysis.sql     # Fraud rate by card type, hour, device, email domain, amount bucket
│   ├── 04_risk_scoring_pipeline.sql   # 30-day rolling risk score + CRITICAL/HIGH/NORMAL tiering (CTE pipeline)
│   └── 05_velocity_anomalies.sql      # 10-minute rolling window transaction velocity detection
├── powerbi/
│   └── UPI_Fraud_Dashboard.pbix       # Full interactive Power BI dashboard
├── findings/
│   └── UPI_Fraud_Findings_Summary.docx # 1-page analyst findings summary + recommendations
└── README.md
```

## Key Findings

- **Time-of-day pattern:** Fraud volume dips through mid-morning (~9–11 AM) and climbs steadily through the evening, peaking around 6–8 PM — roughly a 2x swing across the day.
- **Email domain concentration:** gmail.com accounts for the largest share of fraud-flagged transactions by email domain, though this likely reflects its overall market share rather than being inherently riskier.
- **Risk tier distribution:** ~51.75% of flagged volume falls into the Critical tier, ~46.97% Normal, ~1.28% High — suggesting the tier thresholds may warrant recalibration in a production setting.
- **Product category skew:** Two of five anonymized product categories (`W`, `C`) account for the large majority of fraud cases.
- **Velocity anomalies:** Flagged cards average 6–7 transactions within a 10-minute window — a pattern consistent with automated/rapid-fire card testing rather than organic behavior.

Full write-up with methodology and recommendations: [`findings/UPI_Fraud_Findings_Summary.docx`](findings/UPI_Fraud_Findings_Summary.docx)

## Dashboard Preview

The Power BI dashboard includes:
- KPI summary cards (transaction value, fraud count, fraud rate, flagged transactions)
- Fraud trend by hour of day
- Breakdown charts: device type, email domain, amount bucket, product category
- Risk tier distribution (donut)
- Drill-down tables: critical transactions (amount-weighted) and velocity-flagged transactions

## Notes & Caveats

- The dataset's `ProductCD` field (categories `W`, `C`, `R`, `H`, `S`) is anonymized by the source provider with no disclosed category definitions — this analysis treats them as opaque labels and focuses on relative fraud concentration rather than interpreting what each code represents.
- `risk_score` in the risk-scoring pipeline is a small additive flag score (0–2), not a continuous severity metric — the Critical-tier drill-down table uses transaction amount, not risk_score, to prioritize rows within that tier.

## Author

**Chaitanya Raj** — B.Tech Electrical Engineering, NIT Agartala | Minor in Business Analytics, IIT Mandi
[LinkedIn](https://www.linkedin.com/in/chaitanya-raj-5c51) · [Portfolio](https://sites.google.com/view/productchaitanyaraj/)
