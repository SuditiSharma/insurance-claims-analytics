# Insurance Claims Analytics & Fraud Risk Dashboard

> 🚧 **Work in progress.** Data preparation, SQL analysis and Python visualisations are complete; the Power BI dashboard is being built.

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

Python (Pandas, NumPy, Matplotlib) · SQL (SQLite) · Power BI · DAX · Git/GitHub

## Project Structure

```
insurance-claims-analytics/
├── data/
│   ├── insurance_claims.csv          # raw synthetic data
│   ├── insurance_claims_clean.csv    # cleaned + engineered features
│   ├── insurance_claims.db           # SQLite database
│   └── generate_claims_data.py       # data generator
├── sql/
│   ├── 01_basic_analysis.sql         # headline KPIs
│   ├── 02_claims_performance.sql     # trends, seasonality, regional SLA
│   ├── 03_fraud_analysis.sql         # fraud patterns and risk concentration
│   └── 04_operational_analysis.sql   # bottlenecks, documents, handlers, channels
├── powerbi/
│   ├── build_powerbi_tables.py       # builds the star schema for Power BI
│   └── dax_measures.md               # DAX measures used in the report
├── charts/                           # charts exported from the notebook
├── insurance_claims_analysis.ipynb        # cleaning, feature engineering, risk score
├── insurance_claims_visualisations.ipynb  # 9 charts with business insights
└── README.md
```

## Progress

- [x] Synthetic dataset generation
- [x] Data cleaning (8 data-quality issues identified and resolved)
- [x] Feature engineering (SLA status, settlement ratio, documentation status, reporting lag, risk score)
- [x] Basic SQL analysis
- [x] Intermediate SQL (CTEs, window functions, joins, subqueries)
- [x] Python visualisations (9 charts with business insights)
- [ ] Power BI dashboard
- [x] Business recommendations

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

## SQL Techniques Used

Aggregations · `CASE` · CTEs (`WITH`) · subqueries · `HAVING` · `UNION ALL` · `JOIN` to a lookup table · date functions (`strftime`) · window functions: `LAG`, running `SUM() OVER`, `RANK`, `ROW_NUMBER() OVER (PARTITION BY ...)`, `AVG() OVER (PARTITION BY ...)`

## Key Findings (so far)

**Fraud & risk**
1. **Risk concentration:** High-risk claims make up 4.4% of claim volume but 18.3% of total claim value, with a fraud rate (55.1%) roughly 50x that of low-risk claims (1.1%).
2. **Late reporting is the strongest fraud signal:** claims reported 8+ days after the incident have a 78.1% fraud rate, compared with 0% for same-day reports.
3. **Claim type:** Theft (20.1%) and fire (14.4%) claims have far higher fraud rates than windscreen claims (1.1%).
4. **New policies:** policies held 6 months or less have more than double the fraud rate of established policies (11.7% vs 5.3%).

**Operations**

5. **SLA performance:** 43.6% of claims exceeded the 7-day processing target; the East region performs worst (59.8% breach rate vs 36.5% in the West).
6. **Documentation:** claims with incomplete documents have a 78.9% SLA breach rate vs 34.9% for complete claims, and take 14.2 vs 8.1 days on average.
7. **A single SLA misrepresents complex claims:** 89.5% of theft claims breach the 7-day target, but only 20.9% breach a realistic 21-day theft-specific target.
8. **Channels:** Mobile App claims are processed fastest (8.1 days) with the highest satisfaction (3.84/5); Branch claims are slowest (10.9 days) with the lowest satisfaction (3.30/5).
9. **Unresolved workload:** 27.4% of claims remain unresolved (Open, Pending Documents or Under Investigation).

## Visual Highlights

| Fraud rate by reporting delay | Risk score distribution |
|---|---|
| ![Fraud by reporting delay](charts/09_fraud_by_reporting_delay.png) | ![Risk distribution](charts/08_risk_distribution.png) |

| Processing time vs 7-day SLA | Monthly claim volume |
|---|---|
| ![Processing by type](charts/04_processing_by_type.png) | ![Claims by month](charts/01_claims_by_month.png) |

All 9 charts, each with a written insight, are in [`insurance_claims_visualisations.ipynb`](insurance_claims_visualisations.ipynb).

## Business Recommendations

1. **Fast-track late-reported claims for review.** Claims reported 8+ days after the incident had a 78% fraud rate. A simple reporting-delay rule at first notification of loss would flag most suspicious claims early, at almost no cost.
2. **Use the risk score to prioritise investigator workload.** The 4.4% of claims scored high risk hold 18% of claim value and over half of all fraud, so investigation capacity should be focused there first.
3. **Introduce automated document completeness checks at claim intake.** Incomplete documentation more than doubles the SLA breach rate (78.9% vs 34.9%); chasing missing documents up front would remove a major source of delay.
4. **Replace the single 7-day SLA with claim-type-specific targets.** Theft and fire claims cannot realistically be settled in 7 days; type-specific targets give managers a fairer and more actionable view of performance.
5. **Review processes in the East region.** It has mid-level claim volume but the worst SLA performance (59.8% breach rate), which suggests a process or capacity issue rather than workload.
6. **Encourage digital claim submission.** Mobile App claims are the fastest to process and have the highest customer satisfaction; Branch claims are the slowest and least satisfied.
7. **Plan staffing for seasonal peaks.** Claim volume rises every July–September and again in December–January.

*These recommendations are based on a synthetic dataset and are intended to demonstrate the analytical approach.*

## Author

**Suditi Sharma**, MSc Advanced Computer Science with Data Science (University of Strathclyde)
[GitHub](https://github.com/SuditiSharma)
