# Data provenance

The source data are the 1393 Household Expenditure and Income Survey
(HEIS, 2014–15) conducted in Iran. This repository intentionally does not duplicate the large
binary source files. It downloads these files read-only from
[the source study](https://github.com/aliye-nezhad/household-catastrophic-health-expenditure-R)
at commit 92c5f6162323eb08cee9d51463814542f9a12367:

- 93.rar: original Access 93.mdb (household roster and Table 13 records).
- R93.rar: rural summary workbook.
- U93.rar: urban summary workbook.

Their SHA-256 hashes are pinned in source_sha256.txt. Working copies are
stored under ignored, temporary directories; raw or household-level records
are not published as results. The source repository is never modified.

The supplied 1392 questionnaire uses the same relevant questions and layout as
the 1393 questionnaire, as confirmed for this project. Its Table 13 definitions
are used with the 1393 Access source records. See
[the methodology](../docs/METHODOLOGY.md) for the limits of these measures.
