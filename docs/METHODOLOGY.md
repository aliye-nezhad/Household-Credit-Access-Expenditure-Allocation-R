# Research design and measurement

## Question

How do the household and geographic characteristics of survey respondents who
report a housing- or non-housing-loan-related financial-service entry differ from
those who do not report such an entry? How does observed expenditure composition
vary with that reported status?

The analysis is descriptive and based on a single survey wave: HEIS 1393 (2014–15).

## Loan measures

The original Access database contains rural and urban Part 3 Table 13 records
(R93P3S13 and U93P3S13). The candidate loan-related item codes are:

- 126111: housing-loan-related financial-service charge.
- 126112: non-housing-loan-related financial-service charge.

The supplied 1392 questionnaire has the same relevant questions and layout as
the 1393 questionnaire, as confirmed for this project. The Table 13 loan-item
fields are mapped accordingly: DYCOL02 is the reported loan amount, DYCOL03
is the reported financing source, and DYCOL05 is the financial-service charge.
These mappings are also consistent with the observed 1393 Access table structure
and value patterns. The form does not establish that every household borrowing
transaction is captured by these two item codes.

The binary outcome is **presence of at least one of these two Table 13 entries**.
A zero means no recorded entry of this kind. It does not establish that a
household did not borrow, lacked credit access, or had no outstanding debt.
Reported loan amounts are not necessarily new lending in 1393 or outstanding
principal at the interview date. They cannot be summed into a reliable stock
of household debt. Reported entry amounts are described separately, while
maximum and sum fields are retained only for the internal household aggregation.

About 90% of loan-charge records have a charge-to-amount ratio of 2.5%.
These charges must not be interpreted as loan interest rates or contractual APRs.
Financing-source groups are conservative text-derived diagnostics, not validated
banking-sector identifiers.

## Samples and joining

Raw survey roster: 39,856 household keys (20,100 rural and 19,756 urban).
Two source household workbooks: 38,275 records (19,390 rural; 18,885 urban).
Loan-related Table 13 observations: 6,053 records, 5,848 distinct households.
The analysis reports loan-to-roster and loan-to-workbook matches separately.
Sample exclusions for positive weights, valid spending, food shares, and
controls are explicitly recorded.

Loan records are linked using the residence label and the original
11-digit household Address. No row-level survey data are published.

## Expenditure measures

The household workbook's GHazineh and VKhorak are treated as annual nominal
total and food expenditure. Food share is VKhorak / GHazineh; nonfood share
is its accounting complement. Food shares are restricted to [0, 1].
Expenditure position is estimated using weighted quartiles of annual total
expenditure divided by household size. This is **not an income ranking**.
The ambiguous C11 and C11New fields are deliberately not used.

Food expenditure is not necessarily independent of borrowing, so differences
in food shares by borrowing-report status are not causal effects.

## Estimation

Descriptives use positive household sampling weights. The regression for
reporting a loan-related entry is a survey-weighted quasibinomial GLM;
a second weighted linear model describes conditional food-budget-share
differences. Controls are residence, expenditure quartile, household-head
age, gender, literacy, and household size.

The available source does not establish the actual survey PSUs and strata.
Variance estimates use a weights-only independent-household approximation
and are not advertised as fully design-consistent. No causal identification
strategy or policy-shock variation is claimed.

## Annual durable purchases, aligned to the loan reporting period

The questionnaire's Part 3 Table 13 uses a **previous 12-month**
reference period. It includes selected durable purchases alongside other
annual expenses and loan-related financial-service entries. We use
DYCOL01 prefixes **051** (furniture and furnishings), **053**
(household appliances), and **071** (personal transport equipment).
For these records, DYCOL04 = 1 identifies purchased items, and DYCOL05
is the nominal gross purchase amount. Second-hand resale (DYCOL06)
is not subtracted; a separate net-purchase analysis would answer a
different question. We do not include the 1261 loan-fee items in durable
spending.

We construct purchase participation and weighted mean nominal spending
within each selected category, by reported loan-related entry and residence.
Three weighted logistic regressions examine whether the co-occurrence of a
loan-related entry and a purchase persists conditional on expenditure
quartile, residence, household-head demographics, and household size.
An additional model describes purchase participation in **any** of these
three groups. False discovery rate adjustment is shown for these four
exploratory outcomes as a family.

For each annual outcome, an additional variance sensitivity treats the
31 provinces as clusters, using t-based intervals based on the fitted
regression residual degrees of freedom. This is **not** the official HEIS complex design or a guarantee
of design-consistent inference. Both uncertainty approaches are reported.

The identical 12-month recall periods are a major improvement over
comparing current monthly expenditure with annual loan entries, but they
do not establish the temporal ordering, loan purpose, or whether a
specific loan financed a specific purchase. Neither the regressions nor
their precision can be given a causal interpretation.

## Loan-type measurement and expenditure-control sensitivity

Loan reporting is classified into four **mutually exclusive** groups:
no entry of either type, housing only, non-housing only, and both types.
The first group means no recorded entry in the two fee-linked questions,
not necessarily no loans or credit access. A household with both types
must not silently be counted as a housing-only or non-housing-only reporter.
The exclusive groups and their weighted shares are audited separately.
The financing-source field is still free text and does not establish
bank approval, borrowing terms, or debt balances.

**Expenditure-control endogeneity.** The original annual durable-purchase
logistic models control for a weighted quartile of total annual household
expenditure per person. That total can incorporate the very purchases
used to define the dependent variable. It is therefore an imperfect
covariate for a conditional association. An explicit robustness exercise
constructs:

```text
alternative annual expenditure
  = GHazineh
  - gross purchases in Table 13 groups 051, 053, and 071
```

Weighted per-person expenditure quartiles are recalculated on this
alternative amount. Because the workbook's precise accounting
crosswalk has not been independently validated, the resulting
measure is an **accounting leave-out proxy**, not verified income,
wealth, or nondurable consumption. It is not an instrumental
variable or a pre-borrowing measure.

Four matched-sample outcome models compare the original total-expenditure
control with the leave-out control. Further models contrast **non-housing
only** and **housing only**, each against households with no recorded
loan-related entry, excluding the other reporting categories. These are
different descriptive populations, not mutually interchangeable
causal comparisons. The sample reconciliation checks whether removing
the selected purchases creates nonpositive residual expenditure.

The sensitivity analysis also reports standardized *predicted-probability
differences* from fitted weighted logit models. These are model-based
descriptive percentage-point contrasts, not treatment effects; the
reported intervals relate to odds ratios, not to these probability
differences. For the four leave-out any-entry outcomes, a further
province-clustered uncertainty sensitivity and Benjamini-Hochberg
adjustment are shown. The original complex sample design remains
unverified.

The completed 1393 audit retains all 38,275 households for the matched
total-versus-leave-out comparison. The **any selected durable purchase**
model changes from OR 1.49 with the original control to OR 1.58 using
the leave-out control (province-clustered 95% interval 1.26–1.98).
The non-housing-only comparison has OR 1.64 (weights-only 95% interval
1.50–1.81), while the housing-only comparison is OR 1.08
(weights-only 95% interval 0.82–1.42). This difference does not
establish that non-housing loans financed the observed purchases.

Full aggregate results are in
[`borrowing_measurement_and_control_sensitivity.csv`](../outputs/tables/borrowing_measurement_and_control_sensitivity.csv).
Loan-type counts and sample diagnostics are in the results folder.
The original baseline remains unchanged and reproducible.

## Additional monthly expenditure categories

The supplied questionnaire labels Part 3 Sections 03 (clothing and footwear),
05 (furnishings and household equipment), 07 (transport), 08
(communications), 09 (recreation and culture), and 11 (prepared food and
accommodation) as **previous-month** expenditure modules. In these tables
DYCOL01 is the expenditure-item code, DYCOL02 is the acquisition method,
and DYCOL03 is the reported nominal amount. Purchased entries have
DYCOL02 = 1. We retain all source household keys and then left-join
aggregated purchased spending to the expenditure-workbook sample.

For each of these six categories, the supplemental analysis reports the
share of households with positive purchased spending in the reference month,
and the weighted mean nominal monthly amount, separately by residence and
loan-entry status. Zero purchased entries are coded as zero **recorded
spending in the particular module**, not as absence of consumption.
Noncash acquisition methods are excluded from the purchased-spending
measure. Source rows and unmatched households are diagnosed in the run.

These sections do not constitute an exhaustive consumption basket.
Large occasional purchases also make month-of-interview observations noisy.
Thus we do not multiply monthly durable-goods purchases by twelve or
claim these are annual household budget allocations. Associations with
loan-report status are cross-sectional and may reflect income, preferences,
wealth, or other unobserved variables. Six additional weighted logit models
describe purchase participation conditional on expenditure-per-person
quartile, residence and observed demographics; their exploratory p-values
are additionally adjusted using Benjamini-Hochberg across the six outcomes.

## Financing-source interpretation

The source of a loan is a free-text response. Distinguishing explicitly named
banks, recognizable bank name shorthand, loan funds/institutions, and ambiguous
responses requires an explicitly documented heuristic classification.
It must not be interpreted as verified lender market share or complete
coverage of formal lending.

## Reproducibility

The project retrieves three specific survey archives from the unchanged
source repository at commit 92c5f6162323eb08cee9d51463814542f9a12367.
Each downloaded archive is checked against the known SHA-256 checksum.
A locked Linux environment runs the scripts, validates count invariants,
and retains aggregate CSVs and a figure as CI artifacts.
