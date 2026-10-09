"""
Synthetic Motor Insurance Claims Generator
-----------------------------------------
Generates insurance_claims.csv for the Insurance Claims Analytics &
Fraud Risk Dashboard project. ALL DATA IS SYNTHETIC - no real customers.

Design notes (worth knowing for interviews):
- Fraud is driven by SEVERAL factors (claim type, amount, prior claims,
  late reporting, new policy/young customer, channel), not just "big claim".
- Processing time depends on claim type, investigation, document
  completeness, handler experience, region and channel.
- The raw file is deliberately a little messy (duplicates, missing values,
  impossible values, inconsistent text) so the cleaning step is realistic.

Run:  python generate_claims_data.py
"""

import numpy as np
import pandas as pd

RNG = np.random.default_rng(42)
N = 15_000


def pick(options, probs, size):
    return RNG.choice(options, size=size, p=probs)


# ---------------------------------------------------------------- basics
claim_id = [f"CLM{i:06d}" for i in range(1, N + 1)]
policy_id = [f"POL{p:06d}" for p in RNG.integers(1, 9_000, N)]

# Incident dates 2024-01-01 .. 2025-12-31 with seasonality
# (more claims in monsoon Jul-Sep and winter Dec-Jan)
all_days = pd.date_range("2024-01-01", "2025-12-31", freq="D")
month_weight = {1: 1.15, 2: 0.95, 3: 0.9, 4: 0.9, 5: 0.95, 6: 1.0,
                7: 1.3, 8: 1.35, 9: 1.2, 10: 0.95, 11: 1.0, 12: 1.2}
w = np.array([month_weight[d.month] for d in all_days])
w = w / w.sum()
incident_date = pd.to_datetime(RNG.choice(all_days, size=N, p=w))

claim_type = pick(
    ["Collision", "Third-party", "Accidental damage", "Windscreen", "Theft", "Fire"],
    [0.35, 0.18, 0.17, 0.15, 0.08, 0.07], N)

region = pick(["North", "South", "East", "West", "Central"],
              [0.24, 0.22, 0.18, 0.21, 0.15], N)
channel = pick(["Online", "Phone", "Broker", "Mobile App", "Branch"],
               [0.28, 0.22, 0.18, 0.20, 0.12], N)
customer_segment = pick(["Standard", "Premium", "High Value"],
                        [0.65, 0.25, 0.10], N)
vehicle_type = pick(["Hatchback", "Sedan", "SUV", "MUV", "Luxury"],
                    [0.34, 0.26, 0.24, 0.10, 0.06], N)

customer_age = np.clip(RNG.normal(40, 12, N).round(), 18, 75).astype(int)
vehicle_age = np.clip(RNG.gamma(2.0, 2.5, N).round(), 0, 15).astype(int)
previous_claims = np.clip(RNG.poisson(0.8, N), 0, 9)
handler_experience_years = np.clip(RNG.gamma(2.0, 2.2, N).round(), 0, 20).astype(int)

# ---------------------------------------------------------------- severity
sev_levels = np.array(["Low", "Medium", "High", "Critical"])
sev_probs = {
    "Windscreen":        [0.70, 0.25, 0.05, 0.00],
    "Collision":         [0.30, 0.40, 0.22, 0.08],
    "Third-party":       [0.25, 0.40, 0.25, 0.10],
    "Accidental damage": [0.40, 0.40, 0.15, 0.05],
    "Theft":             [0.05, 0.25, 0.40, 0.30],
    "Fire":              [0.05, 0.20, 0.40, 0.35],
}
severity = np.array([RNG.choice(sev_levels, p=sev_probs[t]) for t in claim_type])

# ---------------------------------------------------------------- amount (INR)
type_base = {"Windscreen": 12_000, "Collision": 60_000, "Third-party": 85_000,
             "Accidental damage": 45_000, "Theft": 220_000, "Fire": 180_000}
sev_mult = {"Low": 0.5, "Medium": 1.0, "High": 1.9, "Critical": 3.2}
seg_mult = {"Standard": 1.0, "Premium": 1.35, "High Value": 2.1}
veh_mult = {"Hatchback": 0.8, "Sedan": 1.0, "SUV": 1.25, "MUV": 1.1, "Luxury": 2.2}

base_amt = np.array([type_base[t] * sev_mult[s] * seg_mult[g] * veh_mult[v]
                     for t, s, g, v in zip(claim_type, severity,
                                           customer_segment, vehicle_type)])
claim_amount = base_amt * RNG.lognormal(0, 0.35, N)

# ---------------------------------------------------------------- fraud (latent, multi-factor)
reporting_lag = RNG.geometric(0.45, N) - 1  # days between incident and claim
policy_tenure_months = np.clip(RNG.gamma(2.0, 18, N).round(), 1, 180).astype(int)

logit = -4.1
logit = logit + np.where(claim_type == "Theft", 1.3, 0)
logit = logit + np.where(claim_type == "Fire", 0.9, 0)
logit = logit + np.where(claim_type == "Windscreen", -1.0, 0)
logit = logit + 0.35 * np.clip(previous_claims, 0, 6)
logit = logit + np.where(policy_tenure_months <= 6, 1.0, 0)
logit = logit + np.where(customer_age < 25, 0.4, 0)
logit = logit + np.where(channel == "Broker", 0.35, 0)
logit = logit + np.where(region == "Central", 0.35, 0)
logit = logit + 0.5 * np.log1p(claim_amount / 100_000)
fraud_prob = 1 / (1 + np.exp(-logit))
fraud_flag = (RNG.random(N) < fraud_prob).astype(int)

# fraudulent claims tend to be inflated and reported later
claim_amount = np.where(fraud_flag == 1, claim_amount * RNG.uniform(1.2, 1.8, N), claim_amount)
reporting_lag = np.where(fraud_flag == 1, reporting_lag + RNG.integers(2, 12, N), reporting_lag)
claim_amount = (claim_amount / 100).round() * 100  # round to nearest 100
claim_date = incident_date + pd.to_timedelta(reporting_lag, unit="D")

# ---------------------------------------------------------------- investigation & documents
investigation_required = np.where(
    fraud_flag == 1, RNG.random(N) < 0.72, RNG.random(N) < 0.10).astype(int)

docs_req_map = {"Windscreen": 2, "Collision": 4, "Third-party": 5,
                "Accidental damage": 3, "Theft": 6, "Fire": 5}
documents_required = np.array([docs_req_map[t] for t in claim_type])
missing_docs = np.where(RNG.random(N) < np.where(fraud_flag == 1, 0.45, 0.18),
                        RNG.integers(1, 3, N), 0)
documents_submitted = np.clip(documents_required - missing_docs, 0, None)
docs_incomplete = documents_submitted < documents_required

# ---------------------------------------------------------------- status
status = np.empty(N, dtype=object)
r = RNG.random(N)
for i in range(N):
    if investigation_required[i]:
        opts, p = ["Under Investigation", "Closed/Rejected", "Settled"], [0.55, 0.30, 0.15]
        if fraud_flag[i]:
            p = [0.45, 0.45, 0.10]
    elif docs_incomplete[i]:
        opts, p = ["Pending Documents", "Settled", "Open", "Closed/Rejected"], [0.45, 0.35, 0.12, 0.08]
    else:
        opts, p = ["Settled", "Open", "Closed/Rejected", "Pending Documents"], [0.72, 0.12, 0.13, 0.03]
    status[i] = RNG.choice(opts, p=p)
claim_status = status

# ---------------------------------------------------------------- processing days
type_days = {"Windscreen": 1.5, "Collision": 3.5, "Third-party": 5.5,
             "Accidental damage": 3, "Theft": 8, "Fire": 7}
region_days = {"North": 0, "South": 0.5, "East": 2.5, "West": -0.5, "Central": 1.0}
channel_days = {"Online": -0.5, "Phone": 0.5, "Broker": 1.5, "Mobile App": -1.0, "Branch": 2.0}

proc = np.array([type_days[t] + region_days[rg] + channel_days[c]
                 for t, rg, c in zip(claim_type, region, channel)])
proc = proc + investigation_required * RNG.uniform(10, 25, N)
proc = proc + docs_incomplete * RNG.uniform(2, 7, N)
proc = proc + np.where(handler_experience_years <= 1, 2, 0)
proc = proc + np.where(np.isin(severity, ["High", "Critical"]), 1.5, 0)
processing_days = np.clip(proc * RNG.lognormal(0, 0.25, N), 1, 90).round().astype(int)

# ---------------------------------------------------------------- settlement
settle_ratio = np.clip(RNG.normal(0.86, 0.08, N), 0.5, 1.0)
settlement_amount = np.where(claim_status == "Settled",
                             (claim_amount * settle_ratio / 100).round() * 100, 0.0)

# ---------------------------------------------------------------- satisfaction (1-5)
sat = 4.3 - 0.06 * processing_days
sat = sat - np.where(claim_status == "Closed/Rejected", 1.2, 0)
sat = sat - np.where(channel == "Branch", 0.2, 0) + np.where(channel == "Mobile App", 0.2, 0)
customer_satisfaction = np.clip((sat + RNG.normal(0, 0.6, N)).round(), 1, 5).astype(float)
# survey not completed for ~10% of claims (natural missingness)
customer_satisfaction[RNG.random(N) < 0.10] = np.nan

# ---------------------------------------------------------------- assemble
df = pd.DataFrame({
    "claim_id": claim_id,
    "policy_id": policy_id,
    "claim_date": claim_date.strftime("%Y-%m-%d"),
    "incident_date": incident_date.strftime("%Y-%m-%d"),
    "claim_type": claim_type,
    "claim_status": claim_status,
    "customer_age": customer_age.astype(float),
    "customer_segment": customer_segment,
    "policy_tenure_months": policy_tenure_months,
    "vehicle_age": vehicle_age,
    "vehicle_type": vehicle_type,
    "region": region,
    "channel": channel,
    "claim_amount": claim_amount,
    "settlement_amount": settlement_amount,
    "processing_days": processing_days,
    "documents_submitted": documents_submitted,
    "documents_required": documents_required,
    "previous_claims": previous_claims,
    "fraud_flag": fraud_flag,
    "severity": severity,
    "handler_experience_years": handler_experience_years,
    "customer_satisfaction": customer_satisfaction,
    "investigation_required": investigation_required,
})

# ---------------------------------------------------------------- inject realistic data-quality issues
dirty = df.copy()
idx = lambda k: RNG.choice(dirty.index, size=k, replace=False)

dirty.loc[idx(220), "customer_age"] = np.nan                    # missing ages
dirty.loc[idx(6), "customer_age"] = RNG.choice([0, 150, 212, -3], 6)  # impossible ages
dirty.loc[idx(5), "claim_amount"] = -dirty["claim_amount"].sample(5, random_state=1).values  # negative amounts
bad_dates = idx(12)                                              # claim before incident
dirty.loc[bad_dates, "claim_date"] = (
    pd.to_datetime(dirty.loc[bad_dates, "incident_date"]) - pd.Timedelta(days=3)
).dt.strftime("%Y-%m-%d")
lower = idx(150)
dirty.loc[lower, "region"] = dirty.loc[lower, "region"].str.lower()           # casing issues
messy = idx(80)
dirty.loc[messy, "region"] = " " + dirty.loc[messy, "region"].astype(str) + " "  # stray whitespace
dirty.loc[idx(60), "channel"] = "mobile app"
dirty.loc[idx(40), "claim_type"] = "Third Party"                 # inconsistent label
dirty = pd.concat([dirty, dirty.sample(140, random_state=7)])    # duplicate rows
dirty = dirty.sample(frac=1, random_state=3).reset_index(drop=True)

dirty.to_csv("insurance_claims.csv", index=False)
print(f"Wrote insurance_claims.csv with {len(dirty):,} rows")
