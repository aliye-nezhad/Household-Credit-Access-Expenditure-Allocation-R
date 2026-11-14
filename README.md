# Household Borrowing and Durable-Goods Purchases

An empirical **R** study using the 1393 Household Expenditure and Income Survey (HEIS, 2014–15). It examines household reports of housing- and non-housing-loan-related financial-service transactions and their association with purchases of selected durable goods.

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

The survey-weighted reporting rate is **13.69%**. Loan-related items **126111** (housing) and **126112** (non-housing) come from Part 3, Table 13. The selected annual durable-purchase codes are **051**, **053**, and **071**. Six other expenditure categories are examined separately using their previous-month recall periods.

Data are downloaded from a [fixed revision of the companion HEIS repository](https://github.com/aliye-nezhad/household-catastrophic-health-expenditure-R/tree/92c5f6162323eb08cee9d51463814542f9a12367/data/raw) with SHA-256 checks. Source survey files are not duplicated in this repository.

[Data provenance](data/README.md) · [Variable definitions](docs/VARIABLE_MAP.md)

## Main results

The models use survey weights and control for household expenditure position, rural/urban residence, household-head age, gender and literacy, and household size.

| Specification | Adjusted odds ratio: any selected durable purchase |
| --- | ---: |
| Loan-related report, total-expenditure quartiles | 1.49 |
| Loan-related report, leave-out expenditure quartiles | **1.58** |
| Non-housing-only report versus no recorded entry | 1.64 |
| Housing-only report versus no recorded entry | 1.08 |

The leave-out specification subtracts selected gross durable purchases from annual total expenditure before ranking households. On the **same 38,275-household sample**, the combined adjusted odds ratio is **1.58** (province-clustered 95% interval **1.26–1.98**). The non-housing-only and housing-only comparisons have weights-only 95% intervals of **1.50–1.81** and **0.82–1.42**, respectively.

The positive association is more evident for non-housing reports, but the data cannot establish that a loan paid for a durable purchase. The absence of a loan-related entry does not prove that a household had no borrowing.

[Research note](outputs/RESEARCH_NOTE.md) · [Main robustness table](outputs/tables/leaveout_primary_robustness.csv) · [All model comparisons](outputs/tables/borrowing_measurement_and_control_sensitivity.csv) · [Results index](outputs/README.md)

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
├── code/
│   ├── analysis.R
│   ├── extended_analysis.R
│   ├── measurement_sensitivity.R
│   ├── write_research_note.R
│   └── validate.R
├── data/
│   ├── README.md
│   └── source_sha256.txt
├── docs/
│   ├── METHODOLOGY.md
│   └── VARIABLE_MAP.md
├── outputs/
│   ├── RESEARCH_NOTE.md
│   ├── RESULTS.md
│   ├── tables/
│   ├── figures/
│   └── diagnostics/
├── scripts/reproduce.R
├── .github/workflows/reproduce.yml
├── .gitattributes
├── pixi.toml
├── pixi.lock
├── CITATION.cff
└── LICENSE
~~~

## Author

**Aliye Nezhad** · [GitHub profile](https://github.com/aliye-nezhad)

## License

The R analysis code and documentation are available under the [MIT License](LICENSE). Underlying household survey datasets remain subject to their original distribution and use terms and are **not** licensed by this repository.
