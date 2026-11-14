# Survey fields and analytical constructs

The study uses the 1393 HEIS household workbooks and original Access
database. The supplied 1392 questionnaire uses the same relevant
questions and layout as 1393, as confirmed for this project.

## Input linkage and units

| Source | Fields | Interpretation | Recall period |
| --- | --- | --- | --- |
| Rural/urban workbook: R93.xls, U93.xls | ADDRESS | 11-digit household key | Household record |
| Household workbooks | weight | Household survey weight | Survey weight |
| Household workbooks | GHazineh, VKhorak | Nominal total and food expenditures | Annual |
| Household workbooks | C01, A01, A02, A03 | Household size, head gender, head age, head literacy | Survey characteristics |
| Access R93P3S13 / U93P3S13 | DYCOL01=126111,126112 | Housing / non-housing loan-related fee item | Previous 12 months |
| Access P3S13 loan items | DYCOL02 | Recorded loan amount in rials | Previous 12 months |
| Access P3S13 loan items | DYCOL03 | Free-text reported financing source | Previous 12 months |
| Access P3S13 loan items | DYCOL05 | Loan-related financial-service fee in rials | Previous 12 months |
| Access P3S13 durable item prefixes 051,053,071 | DYCOL04=1 and DYCOL05 | Purchased durable goods; nominal gross purchase amounts | Previous 12 months |
| Access P3S03, S05, S07, S08, S09, S11 | DYCOL02=1 and DYCOL03 | Purchased items in selected spending sectors | Previous month |

Table 13 serves multiple functions, so the same DYCOL field may have
different meanings conditional on the item code. In particular, **DYCOL02**
is a loan amount for the 126111/126112 records and an acquisition-method
field for many monthly expenditure modules. The study does not pool their
values indiscriminately.

## Primary derived outcomes

- **Loan-entry reporting:** household with at least one 126111/126112 record.
  An absent record means no observed entry of this type, not verified
  absence of credit, outstanding debt, or rejected loan applications.
- **Housing / non-housing entry:** separate indicators for those item codes.
- **Durable purchase participation:** positive purchase recorded under
  051 (furniture and furnishings), 053 (appliances), or 071 (personal
  transport equipment) during the preceding 12 months.
- **Any selected durable purchase:** union of those three annual outcomes.
- **Expenditure quartile:** survey-weighted quartile of annual total
  household expenditure divided by household size, not income or wealth.
- **Food budget share:** annual food expenditure / annual total
  expenditure; valid ratios are restricted to [0,1].
- **Monthly sector participation:** positive purchased spending in one
  of the six selected sections during the prior month, not a measure
  of annual category shares.

## Measurement sensitivity constructs

- **Exclusive loan status:** no recorded loan-fee entry, housing only,
  non-housing only, or both. A household in the 'both' group is excluded
  from the corresponding single-type-versus-no-entry comparison.
- **Selected annual gross durable purchases:** household sum of purchased
  Table 13 items within prefixes 051, 053, and 071, excluding the
  loan-related fee codes. These amounts are not necessarily net expenditure.
- **Leave-out annual expenditure:** `GHazineh` minus the selected annual
  gross durable purchases. This is a **constructed sensitivity measure**,
  not validated disposable income or nondurable spending.
- **Leave-out quartile:** survey-weighted quartile of leave-out expenditure
  per household member, constructed on the same eligible households
  as the comparable total-expenditure quartile.
- **Standardized probability difference:** weighted average of two
  predicted purchase probabilities from the same fitted model,
  changing the observed entry indicator while holding measured
  covariates fixed. It is not an estimated causal effect.

The matched-sample specifications use all 38,275 workbook households,
and no nonpositive leave-out totals were detected. The housing-only
group contains 556 households, the non-housing-only group 5,176,
and the group reporting both types 116. These figures describe
the narrow Table 13 loan-related measure, not comprehensive borrowing.

## Eligibility and limitations

Access roster: 39,856 household keys; workbooks: 38,275 households.
Loan-associated transactions: 6,053 across 5,848 households, all linked
to the distributed workbooks. The primary annual durable models use
38,275 households. The baseline loan-report and food-share models
exclude 86 records with unusable food expenditure, leaving 38,189.

Default standard errors use a weights-only independent-household design;
annual durable models also report province-cluster sensitivity using 31
clusters. Neither recovers the official original PSU/strata information.
All models are descriptive associations, not causal effects.

Raw household microdata and identifiable records must never be committed
to the output directories. Source archives are read-only and checksum-pinned.
