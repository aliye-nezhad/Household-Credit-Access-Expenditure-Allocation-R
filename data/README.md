# Data provenance

The Statistical Center of Iran conducted the 1393 Household Expenditure and Income Survey (HEIS, 2014–15). [Survey background](https://m-hoseini.github.io/HEIS/introduction.html). This repository does not duplicate the
original binary survey files. It retrieves three archives from the
[companion HEIS repository](https://github.com/aliye-nezhad/household-catastrophic-health-expenditure-R)
at commit `92c5f6162323eb08cee9d51463814542f9a12367`:

| Archive | Contents |
| --- | --- |
| `93.rar` | Original Access database, household roster and Table 13 |
| `R93.rar` | Rural household summary workbook |
| `U93.rar` | Urban household summary workbook |

Input hashes are pinned in [source_sha256.txt](source_sha256.txt).
Working files are extracted in temporary, ignored directories. Published
outputs contain aggregate statistics, not household identifiers or raw
survey observations.

The supplied 1392 questionnaire uses the same relevant questions and layout
as the 1393 survey, as confirmed for this project. The fields are interpreted
together with the observed 1393 records; the scope and limitations are stated
in the [methodology](../docs/METHODOLOGY.md) and
[variable map](../docs/VARIABLE_MAP.md).
