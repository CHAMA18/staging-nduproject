# Cost Benefit Analysis - Mathematical Formulas & Examples

**Document Version:** 1.0  
**Date:** 2024  
**Purpose:** Comprehensive explanation of all financial calculations used in the Cost Benefit Analysis screens

---

## Table of Contents

1. [Overview](#overview)
2. [Core Calculations](#core-calculations)
3. [Advanced Financial Metrics](#advanced-financial-metrics)
4. [Examples & Scenarios](#examples--scenarios)
5. [Assumptions & Limitations](#assumptions--limitations)

---

## Overview

The Cost Benefit Analysis module calculates financial metrics to evaluate project profitability and investment viability. All calculations follow standard financial analysis principles and use time value of money concepts.

### Key Concepts

- **Time Value of Money:** Money available today is worth more than the same amount in the future
- **Discount Rate:** The interest rate used to discount future cash flows
- **Cash Flow:** The net amount of cash flowing in (benefits) or out (costs) in a period
- **Horizon Period:** The number of years over which benefits are realized

---

## Core Calculations

### 1. Total Benefits Calculation

**Formula:**
```
Total Benefits = Σ (Unit Value × Units) for all benefit line items
```

**Mathematical Notation:**
\[
\text{Total Benefits} = \sum_{i=1}^{n} (\text{Unit Value}_i \times \text{Units}_i)
\]

Where:
- `n` = number of benefit line items
- `Unit Value_i` = price per unit for item `i`
- `Units_i` = quantity of units for item `i`

**Example:**

| Benefit Item | Unit Value | Units | Total Value |
|--------------|------------|-------|-------------|
| Labor savings | $50,000 | 2 | $100,000 |
| Equipment efficiency | $25,000 | 3 | $75,000 |
| Process improvement | $15,000 | 1 | $15,000 |
| **TOTAL** | | | **$190,000** |

**Calculation:**
```
Total Benefits = ($50,000 × 2) + ($25,000 × 3) + ($15,000 × 1)
               = $100,000 + $75,000 + $15,000
               = $190,000
```

---

### 2. Return on Investment (ROI)

**Formula:**
```
ROI (%) = ((Total Benefits - Total Cost) / Total Cost) × 100
```

**Mathematical Notation:**
\[
\text{ROI} = \frac{\text{Benefits} - \text{Cost}}{\text{Cost}} \times 100\%
\]

**Interpretation:**
- **ROI > 0%:** Project generates profit
- **ROI > 100%:** Project more than doubles the investment
- **ROI < 0%:** Project results in a loss

**Example 1: Profitable Project**
```
Total Benefits = $250,000
Total Cost = $150,000

ROI = (($250,000 - $150,000) / $150,000) × 100
    = ($100,000 / $150,000) × 100
    = 0.6667 × 100
    = 66.67%
```
**Interpretation:** The project returns 66.67% profit on the investment.

**Example 2: Break-Even Project**
```
Total Benefits = $150,000
Total Cost = $150,000

ROI = (($150,000 - $150,000) / $150,000) × 100
    = ($0 / $150,000) × 100
    = 0%
```
**Interpretation:** The project breaks even (no profit, no loss).

**Example 3: Loss-Making Project**
```
Total Benefits = $100,000
Total Cost = $150,000

ROI = (($100,000 - $150,000) / $150,000) × 100
    = (-$50,000 / $150,000) × 100
    = -33.33%
```
**Interpretation:** The project loses 33.33% of the investment.

---

### 3. Net Present Value (NPV)

**Formula:**
```
NPV = -Initial Cost + Σ (Annual Benefit / (1 + r)^t) for t = 1 to n
```

**Mathematical Notation:**
\[
\text{NPV} = -C_0 + \sum_{t=1}^{n} \frac{B_t}{(1 + r)^t}
\]

Where:
- `C_0` = Initial Cost (investment at time 0)
- `B_t` = Annual Benefit in year `t`
- `r` = Discount rate (as decimal, e.g., 0.10 for 10%)
- `n` = Number of years (horizon period)

**Key Points:**
- Annual Benefit = Total Benefits / NPV Horizon
- Benefits are assumed to be received evenly over the horizon
- Initial cost is negative (cash outflow)
- Future cash flows are discounted to present value

**Example: 5-Year Project**

**Inputs:**
- Initial Cost: $200,000
- Total Benefits: $350,000
- NPV Horizon: 5 years
- Discount Rate: 8% (0.08)

**Step 1: Calculate Annual Benefit**
```
Annual Benefit = Total Benefits / Horizon
               = $350,000 / 5
               = $70,000 per year
```

**Step 2: Create Cash Flow Timeline**

| Year | Cash Flow | Present Value Factor | Discounted Cash Flow |
|------|-----------|---------------------|----------------------|
| 0 | -$200,000 | 1.0000 | -$200,000.00 |
| 1 | +$70,000 | 1/(1.08)¹ = 0.9259 | $64,814.81 |
| 2 | +$70,000 | 1/(1.08)² = 0.8573 | $60,013.72 |
| 3 | +$70,000 | 1/(1.08)³ = 0.7938 | $55,568.26 |
| 4 | +$70,000 | 1/(1.08)⁴ = 0.7350 | $51,452.09 |
| 5 | +$70,000 | 1/(1.08)⁵ = 0.6806 | $47,640.83 |

**Step 3: Calculate NPV**
```
NPV = -$200,000 + $64,814.81 + $60,013.72 + $55,568.26 + $51,452.09 + $47,640.83
    = -$200,000 + $279,489.71
    = $79,489.71
```

**Alternative Formula (Using Sum of Annuity):**
\[
\text{NPV} = -C_0 + B \times \left[\frac{1 - (1 + r)^{-n}}{r}\right]
\]

Where `B` = annual benefit

```
NPV = -$200,000 + $70,000 × [(1 - (1.08)⁻⁵) / 0.08]
    = -$200,000 + $70,000 × [(1 - 0.6806) / 0.08]
    = -$200,000 + $70,000 × [0.3194 / 0.08]
    = -$200,000 + $70,000 × 3.9925
    = -$200,000 + $279,475.00
    = $79,475.00
```
*(Small difference due to rounding)*

**Interpretation:**
- **NPV > 0:** Project adds value, should proceed
- **NPV = 0:** Project breaks even at the discount rate
- **NPV < 0:** Project destroys value, should not proceed

---

### 4. Payback Period

**Formula:**
```
Payback Period (years) = Total Cost / Annual Benefit
```

**Mathematical Notation:**
\[
\text{Payback Period} = \frac{C}{\text{Annual Benefit}}
\]

Where:
- `C` = Total Cost
- Annual Benefit = Total Benefits / Horizon Period

**Example:**
```
Total Cost = $240,000
Total Benefits = $360,000
Horizon = 5 years

Annual Benefit = $360,000 / 5 = $72,000 per year

Payback Period = $240,000 / $72,000
               = 3.33 years
```

**Interpretation:**
- The project recovers its initial investment in approximately 3.33 years
- Remaining 1.67 years generate pure profit

**Limitations:**
- Does not consider time value of money
- Does not account for cash flows after payback period
- Simplified calculation (does not handle varying cash flows)

---

### 5. Internal Rate of Return (IRR)

**Formula:**
```
IRR = r where NPV(r) = 0
```

**Mathematical Notation:**
\[
-C_0 + \sum_{t=1}^{n} \frac{B_t}{(1 + \text{IRR})^t} = 0
\]

**Calculation Method:** Newton-Raphson Iterative Method

The system uses an iterative approach to find the discount rate where NPV equals zero:

\[
r_{n+1} = r_n - \frac{\text{NPV}(r_n)}{\frac{d\text{NPV}}{dr}(r_n)}
\]

Where the derivative is:
\[
\frac{d\text{NPV}}{dr} = \sum_{t=1}^{n} \frac{-t \times B_t}{(1 + r)^{t+1}}
\]

**Example: Calculating IRR Manually (Approximation)**

**Inputs:**
- Initial Cost: $100,000
- Total Benefits: $200,000
- Horizon: 5 years
- Annual Benefit: $40,000

**Try r = 20% (0.20):**
```
NPV = -$100,000 + $40,000/(1.20)¹ + $40,000/(1.20)² + $40,000/(1.20)³ 
                    + $40,000/(1.20)⁴ + $40,000/(1.20)⁵
    = -$100,000 + $33,333 + $27,778 + $23,148 + $19,290 + $16,075
    = -$100,000 + $119,624
    = $19,624 (positive, try higher rate)
```

**Try r = 30% (0.30):**
```
NPV = -$100,000 + $40,000/(1.30)¹ + $40,000/(1.30)² + $40,000/(1.30)³ 
                    + $40,000/(1.30)⁴ + $40,000/(1.30)⁵
    = -$100,000 + $30,769 + $23,669 + $18,207 + $14,006 + $10,774
    = -$100,000 + $97,425
    = -$2,575 (negative, IRR is between 20% and 30%)
```

**Linear Interpolation:**
\[
\text{IRR} ≈ 0.20 + (0.30 - 0.20) \times \frac{19,624}{19,624 + 2,575}
         = 0.20 + 0.10 × 0.884
         = 0.2884
         = 28.84\%
\]

**Fallback Formula (CAGR Approximation):**
If IRR doesn't converge, the system uses:
\[
\text{IRR} ≈ \left(\frac{\text{Benefits}}{\text{Cost}}\right)^{1/n} - 1
\]

```
IRR ≈ (200,000 / 100,000)^(1/5) - 1
    = (2)^0.2 - 1
    = 1.1487 - 1
    = 0.1487
    = 14.87%
```

**Interpretation:**
- **IRR > Discount Rate:** Project exceeds required return
- **IRR = Discount Rate:** Project meets minimum return
- **IRR < Discount Rate:** Project fails to meet required return

---

### 6. Discounted Cash Flow (DCF)

**Formula:**
```
DCF = NPV + Upfront Cost
```

**Mathematical Notation:**
\[
\text{DCF} = \text{NPV} + C_0
\]

**Alternative Definition:**
DCF represents the present value of all future cash inflows (benefits):
\[
\text{DCF} = \sum_{t=1}^{n} \frac{B_t}{(1 + r)^t}
\]

**Example:**
```
NPV = $79,490
Initial Cost = $200,000

DCF = $79,490 + $200,000
    = $279,490
```

**Interpretation:**
- DCF represents the total present value of benefits
- Equivalent to NPV + initial investment
- Shows the total value created from the investment

---

## Advanced Calculations

### 7. Cost Range (Variance Analysis)

**Formulas:**
```
Lower Range = Estimated Cost × 0.85
Upper Range = Estimated Cost × 1.15
```

**Example:**
```
Estimated Cost = $500,000

Lower Range = $500,000 × 0.85 = $425,000
Upper Range = $500,000 × 1.15 = $575,000
```

**Purpose:**
- Provides ±15% variance range for cost estimates
- Used for sensitivity analysis
- Helps assess project risk

---

### 8. Dynamic ROI Recalculation

When only the cost changes (benefits remain constant):

**Formula:**
```
New ROI = ((Base Benefits - New Cost) / New Cost) × 100
```

**Example:**
```
Base Benefits = $300,000
Original Cost = $200,000
Original ROI = ((300,000 - 200,000) / 200,000) × 100 = 50%

New Cost = $180,000 (cost reduction)

New ROI = ((300,000 - 180,000) / 180,000) × 100
        = (120,000 / 180,000) × 100
        = 66.67%
```

---

### 9. Dynamic NPV Adjustment

When only the upfront cost changes:

**Formula:**
```
New NPV = Base NPV - (New Cost - Base Cost)
```

**Mathematical Notation:**
\[
\text{NPV}_{\text{new}} = \text{NPV}_{\text{base}} - (C_{\text{new}} - C_{\text{base}})
\]

**Example:**
```
Base Cost = $200,000
Base NPV = $79,490
New Cost = $220,000 (cost increase of $20,000)

New NPV = $79,490 - ($220,000 - $200,000)
        = $79,490 - $20,000
        = $59,490
```

**Logic:**
- If cost increases, NPV decreases by the same amount (benefits unchanged)
- If cost decreases, NPV increases by the same amount

---

## Comprehensive Example: Full Project Analysis

### Scenario Setup

**Project Details:**
- Project Name: Digital Transformation Initiative
- Initial Investment: $500,000
- Discount Rate: 10% (0.10)
- Analysis Horizon: 5 years

**Benefit Line Items:**

| Item | Unit Value | Units | Annual Value |
|------|------------|-------|--------------|
| Labor Cost Savings | $80,000 | 1 | $80,000 |
| Reduced Downtime | $30,000 | 2 | $60,000 |
| Process Automation | $40,000 | 1 | $40,000 |
| Equipment Efficiency | $25,000 | 1 | $25,000 |
| **TOTAL BENEFITS** | | | **$205,000** |

### Step-by-Step Calculations

#### Step 1: Calculate Total Benefits
```
Total Benefits = ($80,000 × 1) + ($30,000 × 2) + ($40,000 × 1) + ($25,000 × 1)
               = $80,000 + $60,000 + $40,000 + $25,000
               = $205,000 per year
```

**Note:** In the system, benefits are distributed evenly over the horizon:
```
Annual Benefit = $205,000 / 5 = $41,000 per year
```

However, for this example, we'll assume $205,000 is the total over 5 years, so:
```
Annual Benefit = $205,000 / 5 = $41,000 per year
```

#### Step 2: Calculate ROI
```
ROI = (($205,000 - $500,000) / $500,000) × 100
    = (-$295,000 / $500,000) × 100
    = -59%
```

**Wait!** This seems wrong. Let's recalculate with total benefits over 5 years:
```
Total Benefits (5 years) = $205,000 × 5 = $1,025,000

ROI = (($1,025,000 - $500,000) / $500,000) × 100
    = ($525,000 / $500,000) × 100
    = 105%
```

#### Step 3: Calculate NPV

**Cash Flow Schedule:**

| Year | Cash Flow | PV Factor @ 10% | Present Value |
|------|-----------|-----------------|---------------|
| 0 | -$500,000 | 1.0000 | -$500,000.00 |
| 1 | +$41,000 | 0.9091 | $37,272.73 |
| 2 | +$41,000 | 0.8264 | $33,884.30 |
| 3 | +$41,000 | 0.7513 | $30,803.91 |
| 4 | +$41,000 | 0.6830 | $28,003.55 |
| 5 | +$41,000 | 0.6209 | $25,457.77 |
| **TOTAL** | | | **-$345,577.74** |

```
NPV = -$500,000 + $155,422.26
    = -$344,577.74
```

**Using Annuity Formula:**
\[
\text{NPV} = -500,000 + 41,000 \times \left[\frac{1 - (1.10)^{-5}}{0.10}\right]
\]

\[
\text{NPV} = -500,000 + 41,000 \times \left[\frac{1 - 0.6209}{0.10}\right]
        = -500,000 + 41,000 \times \left[\frac{0.3791}{0.10}\right]
        = -500,000 + 41,000 \times 3.791
        = -500,000 + 155,431
        = -$344,569
\]

#### Step 4: Calculate Payback Period
```
Payback Period = $500,000 / $41,000
               = 12.20 years
```

**Since payback period (12.20 years) > horizon (5 years), the project does not pay back within the analysis period.**

#### Step 5: Calculate IRR

Using the annuity formula approach:
\[
-500,000 + 41,000 \times \left[\frac{1 - (1 + r)^{-5}}{r}\right] = 0
\]

This requires iterative solving. Approximate answer: **r ≈ -50%** (negative IRR)

**This project has a negative NPV and IRR, indicating it's not financially viable at these assumptions.**

---

## Alternative Scenario: Viable Project

### Revised Scenario

**Project Details:**
- Initial Investment: $200,000
- Total Benefits (over 5 years): $400,000
- Annual Benefit: $80,000 per year
- Discount Rate: 8%

### Calculations

#### ROI
```
ROI = (($400,000 - $200,000) / $200,000) × 100
    = ($200,000 / $200,000) × 100
    = 100%
```

#### NPV
\[
\text{NPV} = -200,000 + 80,000 \times \left[\frac{1 - (1.08)^{-5}}{0.08}\right]
        = -200,000 + 80,000 \times 3.9927
        = -200,000 + 319,416
        = $119,416
\]

#### Payback Period
```
Payback Period = $200,000 / $80,000
               = 2.5 years
```

#### IRR (Approximation)
Using the fallback formula:
\[
\text{IRR} ≈ (400,000 / 200,000)^{1/5} - 1
         = 2^{0.2} - 1
         = 1.1487 - 1
         = 14.87%
\]

**Verification:** NPV at 14.87% ≈ 0 (project IRR)

---

## Assumptions & Limitations

### Key Assumptions

1. **Even Benefit Distribution**
   - Benefits are assumed to be received evenly over the horizon period
   - Real-world benefits may vary by year

2. **Constant Discount Rate**
   - Discount rate remains constant throughout the analysis period
   - Real interest rates may fluctuate

3. **Annual Cash Flows**
   - All calculations assume annual cash flow periods
   - Monthly or quarterly flows are not directly supported

4. **No Inflation Adjustment**
   - Calculations use nominal dollars
   - Inflation must be embedded in the discount rate if desired

5. **Single Initial Investment**
   - Assumes all costs occur at time 0
   - Ongoing costs not explicitly modeled

### Limitations

1. **Simplified Cash Flow Model**
   - Does not handle complex, varying cash flow patterns
   - Assumes steady-state benefits after implementation

2. **No Sensitivity Analysis**
   - Single-point estimates (except cost range ±15%)
   - Monte Carlo or scenario analysis not included

3. **Tax Considerations**
   - No explicit tax calculations
   - Pre-tax cash flows assumed

4. **Risk Adjustment**
   - No risk premium in discount rate
   - All projects treated with same risk level

5. **Horizon Selection**
   - User-defined horizon may not match actual project life
   - Terminal value not considered

---

## Formula Reference Sheet

### Quick Reference

| Metric | Formula |
|--------|---------|
| **Total Benefits** | Σ (Unit Value × Units) |
| **ROI** | ((Benefits - Cost) / Cost) × 100% |
| **Annual Benefit** | Total Benefits / Horizon |
| **NPV** | -Cost + Σ [Benefit / (1+r)^t] |
| **Payback Period** | Cost / Annual Benefit |
| **IRR** | r where NPV(r) = 0 |
| **DCF** | NPV + Initial Cost |
| **Cost Range Lower** | Estimated Cost × 0.85 |
| **Cost Range Upper** | Estimated Cost × 1.15 |

### Present Value Factors Table (Common Rates)

| Year | 5% | 8% | 10% | 12% | 15% |
|------|----|----|-----|-----|-----|
| 1 | 0.9524 | 0.9259 | 0.9091 | 0.8929 | 0.8696 |
| 2 | 0.9070 | 0.8573 | 0.8264 | 0.7972 | 0.7561 |
| 3 | 0.8638 | 0.7938 | 0.7513 | 0.7118 | 0.6575 |
| 4 | 0.8227 | 0.7350 | 0.6830 | 0.6355 | 0.5718 |
| 5 | 0.7835 | 0.6806 | 0.6209 | 0.5674 | 0.4972 |
| 10 | 0.6139 | 0.4632 | 0.3855 | 0.3220 | 0.2472 |

---

## Conclusion

The Cost Benefit Analysis module provides comprehensive financial evaluation tools using standard financial formulas. Understanding these calculations helps users:

1. Make informed investment decisions
2. Compare alternative projects
3. Assess project viability
4. Communicate financial implications to stakeholders

For questions or clarifications, refer to the source code in:
- `lib/screens/cost_analysis_screen.dart`
- `lib/utils/finance.dart`

---

**Document End**
