# DAX Measures

All measures live in the **FactClaims** table. Create each one with **Home → New measure**, paste the code, then set the format shown.

## Volume & value

```dax
Total Claims = COUNTROWS ( FactClaims )
```
Format: Whole number, thousands separator

```dax
Total Claim Value = SUM ( FactClaims[claim_amount] )
```
Format: Currency ₹, 0 decimals (or display units: Lakhs/Millions)

```dax
Total Settlement Value = SUM ( FactClaims[settlement_amount] )
```

```dax
Average Claim Amount = AVERAGE ( FactClaims[claim_amount] )
```

## Operations & SLA

```dax
Avg Processing Days = AVERAGE ( FactClaims[processing_days] )
```
Format: Decimal, 1 place

```dax
SLA Breaches =
CALCULATE ( [Total Claims], FactClaims[processing_days] > 7 )
```

```dax
SLA Breach % = DIVIDE ( [SLA Breaches], [Total Claims], 0 )
```
Format: Percentage, 1 decimal

```dax
Open Claims =
CALCULATE (
    [Total Claims],
    FactClaims[claim_status] IN { "Open", "Pending Documents", "Under Investigation" }
)
```

```dax
Pending Documentation =
CALCULATE ( [Total Claims], FactClaims[claim_status] = "Pending Documents" )
```

```dax
Avg Settlement Ratio =
CALCULATE (
    AVERAGE ( FactClaims[settlement_ratio] ),
    FactClaims[claim_status] = "Settled"
)
```
Format: Percentage, 1 decimal

```dax
Avg Satisfaction = AVERAGE ( FactClaims[customer_satisfaction] )
```
Format: Decimal, 2 places (blank survey responses are ignored automatically)

## Fraud & risk

```dax
Fraudulent Claims = CALCULATE ( [Total Claims], FactClaims[fraud_flag] = 1 )
```

```dax
Fraud Rate = DIVIDE ( [Fraudulent Claims], [Total Claims], 0 )
```
Format: Percentage, 1 decimal

```dax
Fraudulent Claim Value =
CALCULATE ( [Total Claim Value], FactClaims[fraud_flag] = 1 )
```

```dax
High Risk Claims = CALCULATE ( [Total Claims], FactClaims[risk_level] = "High" )
```

```dax
High Risk % of Value =
DIVIDE (
    CALCULATE ( [Total Claim Value], FactClaims[risk_level] = "High" ),
    CALCULATE ( [Total Claim Value], ALL ( FactClaims[risk_level] ) ),
    0
)
```
Format: Percentage, 1 decimal

```dax
Avg Claim (Fraud) = CALCULATE ( [Average Claim Amount], FactClaims[fraud_flag] = 1 )
```

```dax
Avg Claim (Non-Fraud) = CALCULATE ( [Average Claim Amount], FactClaims[fraud_flag] = 0 )
```

## Expected values (no filters applied)

Use these to check your measures are correct:

| Measure | Expected |
|---|---|
| Total Claims | 14,983 |
| Total Claim Value | ₹2,534,311,500 (≈ ₹253.4 crore) |
| Total Settlement Value | ₹1,158,423,500 |
| Average Claim Amount | ≈ ₹169,146 |
| SLA Breach % | 43.6% |
| Open Claims | 4,088 |
| Pending Documentation | 1,402 |
| Fraud Rate | 5.6% |
| High Risk Claims | 664 |
| High Risk % of Value | 18.3% |
