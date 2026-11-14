# Reported Household Borrowing and Expenditure Allocation

An empirical R project using the **1393 Household Expenditure and Income
Survey (HEIS, 2014–15)**. It examines which households report housing- and
non-housing-loan-linked financial-service transactions, how reported amounts
and financing sources are distributed, and how household spending composition
varies with reporting status.

**The outcome is the presence of a recorded loan-related financial-service
entry, not comprehensive credit access or outstanding debt.** The estimates
describe associations rather than causal effects of borrowing.

## Data and measures

The project uses the original survey Access archive and rural/urban household
workbooks, available in the
[related HEIS R repository](https://github.com/aliye-nezhad/household-catastrophic-health-expenditure-R).
The borrowing indicators derive from Part 3 Table 13 codes 126111 (housing)
and 126112 (non-housing). The 1393 archive contains 6,053 corresponding
records for 5,848 distinct households in the full 39,856-household Access
roster. The separate analysis workbooks contain 38,275 households; exact
matches and analytical exclusions are reported by the reproducibility run.

The analysis uses nominal annual total and food expenditure (GHazineh and
VKhorak) and household demographics from the workbooks. The project does
not interpret ambiguous economic-rank fields as verified income deciles.

The source data are pinned to a fixed commit, checked against SHA-256 hashes,
and processed without modifying the related repository.

## Empirical approach

1. Audit and link loan-related records to household identifiers.
2. Estimate weighted reported-entry rates by residence and quartiles of
   expenditure per household member.
3. Describe reported amount distributions and conservatively categorized
   financing-source text.
4. Compare **12-month furniture, appliance, and vehicle purchases** across
   reporting groups. These annual measures use the same reference period
   as the loan-related financial-service items.
5. Examine six additional previous-month expenditure categories separately.
6. Estimate weighted logit models of loan-entry status and annual durable
   purchases, plus exploratory monthly spending models and a linear food-share model.
7. Apply province fixed-effect and non-housing-only sensitivity specifications,
   and report exploratory financing-source classifications.

The six additional expenditure sections measure purchases during the
**previous month**, not full-year spending. Their participation results
are not interpreted as causal consumption responses to credit.

The survey's full sampling design is not established here; reported regression
standard errors use a weights-only approximation. This is not a study of
monetary-policy transmission or a causal estimate of the impact of credit.

## Initial reproduced findings

The first successful complete run on November 14, 2026 links **all 5,848**
households with candidate loan-related records to the **38,275** households
in the rural and urban expenditure workbooks. The complete-case model sample
contains **38,189** households.

| Sample | Reported-entry households | Survey-weighted entry rate |
| --- | ---: | ---: |
| Rural (n = 19,390) | 2,530 | 11.29% |
| Urban (n = 18,885) | 3,318 | 14.55% |
| All households (n = 38,275) | 5,848 | 13.69% |

The model with household characteristics and expenditure quartiles finds a
positive association between higher expenditure per person and reporting
loan-related entries. The weighted food share is lower among households
with such entries; the baseline adjusted food-share coefficient is
approximately **-0.0119** (a 1.19 percentage-point difference), conditional
on the stated controls. These are contemporaneous *associations*.

The research workflow includes additional province fixed-effect and
non-housing-only sensitivity specifications. The latest aggregate regression
tables and figure are available as downloadable artifacts of
[GitHub Actions runs](https://github.com/aliye-nezhad/Household-Credit-Access-Expenditure-Allocation-R/actions). The first validated run is
[November 14, 2026](https://github.com/aliye-nezhad/Household-Credit-Access-Expenditure-Allocation-R/actions/runs/43565878556).


## Repository structure

- code/analysis.R: dataset linkage, weighted descriptives, models, and figure.
- code/extended_analysis.R: detailed monthly spending and lender-source groups.
- code/validate.R: source-count and output checks.
- scripts/reproduce.sh: isolated download, verification, and execution.
- docs/METHODOLOGY.md: constructs, identification limits, and inference.
- data/source_sha256.txt: pinned source archive hashes.
- data/README.md: survey provenance.
- .github/workflows/reproduce.yml: automated locked execution.

Generated aggregate tables and figures are delivered as GitHub Actions
artifacts rather than committing unpublished household-level data.

## Reproduction

On x86-64 Linux (or WSL2 with Linux tooling), install
[Pixi](https://pixi.sh/) and run:

    pixi run --locked reproduce

The task downloads only the required survey archives from the public source
repository, validates their checksums, extracts temporary working copies,
and writes a new validated run to reproduced/run-*/. GitHub Actions performs
the same procedure and uploads its outputs as a downloadable artifact.

The first run requires internet access to retrieve the pinned source inputs
and conda-forge packages.

## Scope

This repository is a distinct household-finance study. It does not change
the companion catastrophic-health-expenditure repository. The supplied 1392
questionnaire uses the same relevant questions and layout as the 1393 survey,
as confirmed for this project. The loan-item definitions are applied to the
1393 Access records, with the interpretation restricted to reported loan-related
financial-service entries.

## License

Code and documentation: MIT License. The underlying household survey
files are separate source data and are not covered by this license.
