# Insurance Claims Analytics & Fraud Risk Dashboard

> 🚧 **Work in progress.** Data preparation and initial SQL analysis are complete; advanced SQL, Python visualisations and the Power BI dashboard are being added.

## Overview

An end-to-end insurance claims analytics project that uses **Python**, **SQL** and **Power BI** to analyse claims performance, operational efficiency, settlement patterns and potential fraud risk in motor insurance claims.

The project is informed by my experience as a Motor Claims Handler (credit hire, third-party and total loss claims), applied to a fully synthetic dataset.

## Business Problem

Insurance claims teams need to monitor:

- How many claims are received, and what they cost
- How long claims take to process, and how many miss the target turnaround time (SLA)
- Which claim types, regions and channels create the most operational pressure
- Which claim characteristics are associated with potentially fraudulent claims

This project turns raw claims data into answers to those questions.

## Dataset

- **Synthetic** motor insurance claims dataset: **no real customer data is used**
- 15,140 raw records → **14,983 claims** after cleaning, 24 original columns
- Generated with [`data/generate_claims_data.py`](data/generate_claims_data.py), with fraud driven by several factors (claim type, prior claims, policy tenure, reporting delay, channel), not just claim size
- The raw file deliberately contains realistic data-quality issues to clean

## Tools

Python (Pandas, NumPy) · SQL (SQLite) · Power BI · DAX · Git/GitHub

## Project Structure

```
insurance-claims-analytics/
├── data/
│   ├── insurance_claims.csv          # raw synthetic data
│   ├── insurance_claims_clean.csv    # cleaned + engineered features
│   ├── insurance_claims.db           # SQLite database
│   └── generate_claims_data.py       # data generator
├── sql/
│   └── 01_basic_analysis.sql
├── insurance_claims_analysis.ipynb   # cleaning, feature engineering, analysis
└── README.md
```

## Progress

- [x] Synthetic dataset generation
- [x] Data cleaning (8 data-quality issues identified and resolved)
- [x] Feature engineering (SLA status, settlement ratio, documentation status, reporting lag, risk score)
- [x] Basic SQL analysis
- [ ] Intermediate SQL (CTEs, window functions)
- [ ] Python visualisations
- [ ] Power BI dashboard
- [ ] Final business recommendations

## Data Cleaning

| Issue | Records | Action |
|---|---|---|
| Duplicate rows | 140 | Removed |
| Missing customer age | 222 | Filled with median |
| Impossible ages (e.g. 0, 212) | 6 | Set to missing, then median |
| Negative claim amounts | 5 | Removed |
| Inconsistent region labels | 233 | Standardised |
| Inconsistent channel labels | 61 | Standardised |
| Inconsistent claim type labels | 40 | Standardised |
| Claim date before incident date | 12 | Removed |

Missing satisfaction scores (1,578) were **kept as missing**, as they represent unanswered surveys.

## Exploratory Fraud-Risk Score

A rule-based score used to identify patterns associated with potentially suspicious claims. **This is exploratory analysis, not a production fraud detection model.**

| Rule | Points |
|---|---|
| Claim amount ≥ ₹200,000 | +2 |
| 3+ previous claims | +2 |
| Investigation required | +2 |
| Processing time > 14 days | +1 |
| Incomplete documents | +1 |
| High/Critical severity | +1 |

**0–2 = Low · 3–5 = Medium · 6+ = High**

## Key Findings (so far)

1. **Risk concentration:** High-risk claims make up ~4.4% of claim volume but ~18% of total claim value, with a fraud rate (~55%) roughly 50x that of low-risk claims.
2. **SLA performance:** 43.6% of claims exceeded the 7-day processing target.
3. **Claim type:** Theft claims have the highest average value (~₹6.76 lakh) and take nearly 3x longer to process than windscreen claims (15.9 vs 5.7 days).
4. **Unresolved workload:** 27.4% of claims remain unresolved (Open, Pending Documents or Under Investigation).

*More findings and business recommendations will be added as the analysis progresses.*

## Author

**Suditi Sharma**, MSc Advanced Computer Science with Data Science (University of Strathclyde)
[GitHub](https://github.com/SuditiSharma)
