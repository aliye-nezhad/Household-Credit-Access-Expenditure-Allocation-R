# Validated aggregate results

This directory contains a version-controlled **aggregate snapshot** produced by
the successful reproduction workflow. It does not include household-level
observations, survey addresses, the original Access database, or raw survey files.

- [Research note](RESEARCH_NOTE.md): question, design, main estimates, limitations.
- [Run summary](RESULTS.md): source counts and measurement safeguards.
- [Measurement and econometric sensitivity](tables/borrowing_measurement_and_control_sensitivity.csv): comparable spending controls, separated loan types, and adjusted probabilities.
- [Exclusive loan-type groups](tables/exclusive_loan_reporting_groups.csv): weighted descriptive classifications.
- [Model and descriptive tables](tables/): regression and descriptive CSV outputs.
- [Figures](figures/): reproducible annual and monthly comparisons.
- [Diagnostics](diagnostics/): source counts, model samples and input hashes.

For a fresh execution, use `pixi run --locked reproduce` and inspect
the resulting `reproduced/run-*/` directory. The committed snapshot is
refreshed only after successful verification, analysis, and validation.
See [methodology](../docs/METHODOLOGY.md) for inference limits.

The outputs do not establish universal credit access, loan-financed
purchases, or causal effects.
