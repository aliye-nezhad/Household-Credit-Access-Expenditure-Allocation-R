# Data provenance

The source data are the 1393 (2014–15) Iranian Household Expenditure and
Income Survey. This repository intentionally does not duplicate the large
binary source files. It downloads these files read-only from
[the source study](https://github.com/aliye-nezhad/household-catastrophic-health-expenditure-R)
at commit 92c5f6162323eb08cee9d51463814542f9a12367:

- 93.rar: original Access 93.mdb (household roster and Table 13 records).
- R93.rar: rural summary workbook.
- U93.rar: urban summary workbook.

Their SHA-256 hashes are pinned in source_sha256.txt. Working copies are
stored under ignored, temporary directories; raw or household-level records
are not published as results. The source repository is never modified.

The uploaded 1392 questionnaire supports a provisional interpretation of
Table 13 loan-related questions, not an official 1393 codebook. Consult
docs/METHODOLOGY.md before interpreting figures.
