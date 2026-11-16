# Household Credit Access and Expenditure Allocation

*Evidence from Loan-Related Transactions in the 2014–2015 Household Survey*

An empirical **R** study using the 2014–2015 Household Expenditure and Income Survey (HEIS). It examines household reports of housing- and non-housing-loan-related financial-service transactions and their association with purchases of selected durable goods.

**Research question:** How are these two categories of loan-related reports distributed across households, and how do they co-occur with purchases of furnishings, household appliances, and personal transport equipment?

**Scope:** The measure records specific financial-service entries, **not** comprehensive credit access, outstanding debt, or verified loan-financed purchases. Estimates describe associations, not causal effects.

## Data and sample 

The analysis joins the original survey's Access tables with rural and urban household workbooks.

| Measure | Count |
| --- | ---: |
| Households in expenditure workbooks | 38,275 |
| Loan-related financial-service records | 6,053 |
| Households with at least one such record | 5,848 |
| Housing-only reporting households | 556 |
| Non-housing-only reporting households | 5,176 |
| Households reporting both categories | 116 |

The survey-weighted reporting rate in the 38,275-household workbook sample is **13.69%**. Loan-related items **126111** (housing) and **126112** (non-housing) come from Part 3, Table 13. The selected annual goods-purchase items fall within **051**, **053**, and **071**, with repairs and services excluded (874 excluded source records). Six other expenditure categories are examined separately using their previous-month recall periods.

Data are downloaded from a [fixed revision of the companion HEIS repository](https://github.com/aliye-nezhad/household-catastrophic-health-expenditure-R/tree/92c5f6162323eb08cee9d51463814542f9a12367/data/raw) with SHA-256 checks. Source survey files are not duplicated in this repository.

[Data provenance](data/README.md) · [Questionnaire-to-code audit](docs/QUESTIONNAIRE_TRACE.md) · [Variable definitions](docs/VARIABLE_MAP.md)

## Main results

The models use survey weights and control for household expenditure position, rural/urban residence, household-head age, gender and literacy, and household size.

| Specification | Adjusted odds ratio: any selected durable purchase |
| --- | ---: |
| Loan-related report, total-expenditure quartiles | 1.55 |
| Loan-related report, leave-out expenditure quartiles | **1.64** |
| Non-housing-only report versus no recorded entry | 1.71 |
| Housing-only report versus no recorded entry | 1.16 |

The leave-out specification subtracts selected goods purchases from annual total expenditure before ranking households. On the **same 38,275-household sample**, the combined adjusted odds ratio is **1.64** (province-clustered 95% interval **1.24–2.17**). The non-housing-only and housing-only comparisons have weights-only 95% intervals of **1.55–1.87** and **0.88–1.53**, respectively.

A direct test in a **single model** gives a non-housing-versus-housing odds-ratio ratio of **1.46** (province-clustered 95% interval **1.16–1.84**, p = **0.0026**). This establishes a conditional association difference within the model, not loan-financed purchases or a causal effect. No reported entry does not establish no borrowing.

[Research note](outputs/RESEARCH_NOTE.md) · [Main robustness table](outputs/tables/leaveout_primary_robustness.csv) · [Joint loan-type contrast](outputs/tables/loan_type_joint_contrast.csv) · [All model comparisons](outputs/tables/borrowing_measurement_and_control_sensitivity.csv) · [Results index](outputs/README.md)

## Methods and limitations

The analysis includes survey-weighted descriptive statistics and logistic models, alternative expenditure controls, mutually exclusive loan-report groups, province-adjusted specifications, and province-clustered variance sensitivities. Source record counts, household joins, model samples, and reported output values are checked against documented expectations.

The study is a single cross-section. Unobserved household characteristics, simultaneous financial decisions, and incomplete credit coverage restrict interpretation. The original survey PSU and strata definitions are not verified; province-clustered intervals do **not** reconstruct its complete sampling design. No causal effects or monetary-policy transmission estimates are claimed.

[Methods and identification limits](docs/METHODOLOGY.md)

## Reproducibility

The project runs in a locked **R 4.4.3** environment managed by [Pixi](https://pixi.sh/). On x86-64 Linux (or Windows through WSL2), install Pixi and run this from the repository root:

~~~text
pixi run --locked reproduce
~~~

This downloads and verifies pinned source files, processes the required survey tables, estimates the models, validates aggregate outputs, and writes a dated run under `reproduced/run-*/`. GitHub Actions applies the same checks. Validated aggregate tables and figures are available under [outputs/](outputs/README.md).

## Repository structure

~~~text
├── docs/
│   ├── METHODOLOGY.md
│   ├── QUESTIONNAIRE_TRACE.md
│   └── VARIABLE_MAP.md
├── .github/
│   └── workflows/
│       └── reproduce.yml
├── code/
│   ├── analysis.R
│   ├── durable_codes.R
│   ├── extended_analysis.R
│   ├── measurement_sensitivity.R
│   ├── validate.R
│   └── write_research_note.R
├── data/
│   ├── README.md
│   └── source_sha256.txt
├── scripts/
│   └── reproduce.R
├── outputs/
│   ├── diagnostics/
│   │   ├── alternative_expenditure_quartiles.csv
│   │   ├── alternative_rank_crosswalk.csv
│   │   ├── analysis_sample_checks.csv
│   │   ├── annual_durable_purchase_source_counts.csv
│   │   ├── expenditure_leaveout_reconciliation.csv
│   │   ├── expenditure_quartile_boundaries.csv
│   │   ├── input_hashes.txt
│   │   ├── loan_entry_multiplicity.csv
│   │   ├── loan_field_diagnostics.csv
│   │   ├── loan_type_field_audit.csv
│   │   ├── measurement_sensitivity_notes.txt
│   │   ├── measurement_sensitivity_summary.csv
│   │   ├── model_sample_sizes.csv
│   │   ├── sample_linkage.csv
│   │   ├── sector_source_coverage.csv
│   │   ├── selected_durable_item_code_audit.csv
│   │   ├── source_loan_record_counts.csv
│   │   └── source_text_classification_coverage.csv
│   ├── figures/
│   │   ├── annual_durable_purchase_participation.png
│   │   ├── monthly_sector_purchase_participation.png
│   │   └── reported_entries_by_expenditure_quartile.png
│   ├── tables/
│   │   ├── annual_durable_purchase_associations.csv
│   │   ├── annual_durable_purchase_by_reporting_status.csv
│   │   ├── borrowing_measurement_and_control_sensitivity.csv
│   │   ├── budget_composition_by_reporting_status.csv
│   │   ├── exclusive_loan_reporting_groups.csv
│   │   ├── financing_source_groups.csv
│   │   ├── leaveout_primary_robustness.csv
│   │   ├── loan_type_joint_contrast.csv
│   │   ├── monthly_sector_spending_by_reporting_status.csv
│   │   ├── monthly_sector_spending_differences.csv
│   │   ├── regression_coefficients.csv
│   │   ├── reported_entries_by_expenditure_quartile.csv
│   │   ├── reported_loan_amounts.csv
│   │   ├── reported_loan_entries_by_residence.csv
│   │   └── sector_purchase_associations.csv
│   ├── README.md
│   ├── RESEARCH_NOTE.md
│   └── RESULTS.md
├── .gitattributes
├── .gitignore
├── CITATION.cff
├── pixi.toml
├── pixi.lock
├── LICENSE
└── README.md
~~~

## Author

**Aliye Nezhad** · [GitHub profile](https://github.com/aliye-nezhad)

## License

The R analysis code and documentation are available under the [MIT License](LICENSE). Underlying household survey datasets remain subject to their original distribution and use terms and are **not** licensed by this repository.
