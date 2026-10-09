"""
Builds a star schema for Power BI from the cleaned claims data.

    DimDate ─┐
  DimRegion ─┤
 DimChannel ─┼── FactClaims
DimClaimType ┤
 DimSegment ─┘

Run from the project root:  python powerbi/build_powerbi_tables.py
"""
import os
import pandas as pd

OUT = "powerbi/model"
os.makedirs(OUT, exist_ok=True)

df = pd.read_csv("data/insurance_claims_clean.csv", parse_dates=["claim_date", "incident_date"])


def make_dim(col, key, order=None):
    values = order if order else sorted(df[col].dropna().unique())
    dim = pd.DataFrame({key: range(1, len(values) + 1), col: values})
    return dim


dim_region = make_dim("region", "region_key", ["North", "South", "East", "West", "Central"])
dim_channel = make_dim("channel", "channel_key", ["Online", "Phone", "Mobile App", "Broker", "Branch"])
dim_type = make_dim("claim_type", "claim_type_key",
                    ["Collision", "Third-party", "Accidental damage", "Windscreen", "Theft", "Fire"])
dim_segment = make_dim("customer_segment", "segment_key", ["Standard", "Premium", "High Value"])

# Date dimension covering every claim date
dates = pd.date_range(df["claim_date"].min(), df["claim_date"].max(), freq="D")
dim_date = pd.DataFrame({
    "date": dates,
    "year": dates.year,
    "quarter": "Q" + dates.quarter.astype(str),
    "month_num": dates.month,
    "month_name": dates.strftime("%b"),
    "year_month": dates.strftime("%Y-%m"),
})

fact = (df
        .merge(dim_region, on="region")
        .merge(dim_channel, on="channel")
        .merge(dim_type, on="claim_type")
        .merge(dim_segment, on="customer_segment"))

fact_cols = [
    "claim_id", "policy_id", "claim_date", "incident_date",
    "region_key", "channel_key", "claim_type_key", "segment_key",
    "claim_status", "severity", "vehicle_type", "vehicle_age", "customer_age",
    "policy_tenure_months", "claim_amount", "settlement_amount", "settlement_ratio",
    "processing_days", "sla_status", "documents_submitted", "documents_required",
    "doc_status", "previous_claims", "handler_experience_years",
    "customer_satisfaction", "investigation_required", "fraud_flag",
    "value_band", "reporting_lag_days", "risk_score", "risk_level",
]
fact = fact[fact_cols].sort_values("claim_id")
assert len(fact) == len(df), "Row count changed while joining dimensions"

for name, table in {
    "FactClaims": fact, "DimDate": dim_date, "DimRegion": dim_region,
    "DimChannel": dim_channel, "DimClaimType": dim_type, "DimSegment": dim_segment,
}.items():
    table.to_csv(f"{OUT}/{name}.csv", index=False, date_format="%Y-%m-%d")
    print(f"{name:13s} {len(table):>6,} rows")
