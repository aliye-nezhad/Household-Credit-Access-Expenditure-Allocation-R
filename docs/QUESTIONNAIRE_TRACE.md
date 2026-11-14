# Questionnaire-to-code measurement audit

This note documents the observed-variable interpretation in
**Household Credit Access and Expenditure Allocation**.

## Sources and the scope of verification

The supplied **1392 HEIS questionnaire** was inspected directly.
Its relevant questions and layout were confirmed by the data provider
as unchanged in the 1393 round (2014–2015). An
[2014 survey catalog entry](https://catalog.ihsn.org/catalog/10341/related-materials)
also lists the 1393 questionnaire and codebook, but the year-specific
files were **not independently downloaded and compared** in this audit.

The page references below give PDF page followed by printed page.

| Location | Question / codes | Directly evidenced definition |
| --- | --- | --- |
| Part 3, Section 13, PDF p. 58 (printed 56) | 126111 | Fee paid on received housing-related loans (and reference to securities); separate fields for loan amount and loan source |
| Same page | 126112 | Fee paid on received non-housing loans; separate fields for loan amount and source |
| Section 13, PDF pp. 46–47 (printed 44–45) | 0511/0512 | Furniture and furnishings, carpets and floor coverings |
| PDF p. 47 (printed 45) | 0513 | Furniture repairs and cleaning, **not purchases of new durables** |
| PDF pp. 47–48 (printed 45–46) | 0531/0532 | Major and small household appliances |
| PDF p. 48 (printed 46) | 0533 | Appliance repair, installation and rental |
| PDF pp. 49–50 (printed 47–48) | 0711/0712/0713 | Cars, motorcycles, bicycles and tricycles |
| PDF p. 50 (printed 48) | 071314 | Bicycle repair, not a purchase |

The Section 13 heading states the **previous 12 months**. Sections
1–12 generally use previous-month recall, consistent with the
[HEIS survey guide](https://m-hoseini.github.io/HEIS/questionnaire-details.html).

## Source field interpretation

The raw Access tables are `R93P3S13` and `U93P3S13`.

| Field | Treatment in this project | Caveat |
| --- | --- | --- |
| `DYCOL01` = 126111/126112 | Housing/non-housing fee-linked loan item | Not all borrowing |
| `DYCOL02` on loan-code rows | Reported loan amount | Not verified new lending or outstanding debt |
| `DYCOL03` on loan-code rows | Reported loan source | Free-text response |
| `DYCOL05` on loan-code rows | Loan-related fee/expense | Not a contractual APR or interest rate |
| `DYCOL04` = 1 on durable-code rows | Purchased acquisition method | Other methods excluded |
| `DYCOL05` on durable-code rows | Gross recorded purchase amount | Not net of resale |
| `DYCOL06` on durable-code rows | Second-hand resale amount where recorded | Not subtracted from gross purchases |

The loan-amount/source boxes are specific to the loan rows: `DYCOL02`
does **not** mean loan amount across Table 13 generally. The exposure is
presence of a fee-linked 126111/126112 item, not credit eligibility,
loan approval, outstanding debt, borrowing constraints, or evidence
of when the household first obtained the loan. Absence of an entry does
**not** prove no borrowing.

## Durable-goods exclusion audit

The earlier broad three-digit selection incorrectly included repairs,
cleaning, installation, and rental items. The corrected predicate in
[code/durable_codes.R](../code/durable_codes.R) is applied consistently
by both annual-purchase analyses.

The [aggregate item-code audit](../outputs/diagnostics/selected_durable_item_code_audit.csv)
documents **874 excluded records**: 406 furniture repairs/cleaning,
236 appliance repair/installation/rental, and 232 bicycle repairs.
There are **20,569 retained purchased-goods records**, and **11,486
households** report at least one qualifying selected purchase.

## Expenditure units and accounting

The workbook variable `GHazineh` is used as nominal total annual
household expenditure, and Table 13 `DYCOL05` as nominal amounts in
rials. Nominal annual expenditure in rials is also described in
[HEIS research](https://pure.eur.nl/ws/files/46289719/manuscript_3_3_printed_61e0327950bc6.pdf).

**Compatible recall periods and units do not prove an accounting
identity.** The detailed construction of the workbook's `GHazineh`
has not been reconciled item by item. In particular,
[independent HEIS processing guidance](https://m-hoseini.github.io/HEIS/cleaning-data.html)
constructs net annual expenditure as cost minus second-hand sales,
while this project's leave-out exercise subtracts selected **gross**
purchases. The adjusted expenditure remains a **sensitivity proxy**,
not a verified nondurable-consumption measure.

[Sample checks](../outputs/diagnostics/expenditure_leaveout_reconciliation.csv)
retain all 38,275 households with positive leave-out expenditure.
[Quartile crosswalk](../outputs/diagnostics/alternative_rank_crosswalk.csv)
documents rank changes without interpreting them as a causal experiment.

## Sampling and identification

Household weights are used, but the original complete PSU and
stratum variables have not been verified. Province-clustered standard
errors are an alternative variance sensitivity, **not** a design-based
reconstruction of the full survey sampling procedure.
The [survey catalog](https://catalog.ihsn.org/catalog/10341)
describes a multi-stage stratified cluster design.

Separately estimated housing-only and non-housing-only coefficients
are **not directly compared by observing their individual intervals**.
The [joint model](../outputs/tables/loan_type_joint_contrast.csv)
uses one common sample and tests their coefficient difference directly.
All estimates remain observational.
