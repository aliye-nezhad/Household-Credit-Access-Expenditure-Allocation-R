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
