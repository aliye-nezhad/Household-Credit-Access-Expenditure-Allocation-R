# Research results

This directory contains a validated, version-controlled **aggregate results
snapshot**. It excludes household-level records and original survey files.
To reproduce the results, run `pixi run --locked reproduce` and inspect
`reproduced/run-*/`. The [GitHub Actions workflow](../.github/workflows/reproduce.yml)
checks the same analysis and updates the committed snapshot after successful
validation.

## Research outputs

- [Research note](RESEARCH_NOTE.md): findings, interpretation, and limitations.
- [Run summary](RESULTS.md): dataset coverage and measurement safeguards.
- [Methodology](../docs/METHODOLOGY.md) and
  [variable map](../docs/VARIABLE_MAP.md): definitions and inference assumptions.

## Principal tables

- [Loan-report groups](tables/exclusive_loan_reporting_groups.csv)
- [Loan-field audit](diagnostics/loan_type_field_audit.csv)
- [Annual purchase models](tables/annual_durable_purchase_associations.csv)
- [Preferred leave-out sensitivity](tables/leaveout_primary_robustness.csv)
- [Full alternative specifications](tables/borrowing_measurement_and_control_sensitivity.csv)
- [Monthly sector associations](tables/sector_purchase_associations.csv)
- [Lender-source classifications](tables/financing_source_groups.csv)

## Figures and checks

- [Annual durable-purchase participation](figures/annual_durable_purchase_participation.png)
- [Monthly spending participation](figures/monthly_sector_purchase_participation.png)
- [Expenditure-quartile comparisons](figures/reported_entries_by_expenditure_quartile.png)
- [Household linkage](diagnostics/sample_linkage.csv)
- [Expenditure reconciliation](diagnostics/expenditure_leaveout_reconciliation.csv)
- [Input hashes](diagnostics/input_hashes.txt)

All findings are descriptive and do not establish comprehensive credit access,
verified loan-financed purchases, or causal effects.
