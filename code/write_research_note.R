# Generate a short evidence-based research note from validated aggregate CSVs.
# No household-level microdata are written to the note.
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=1L) stop("Usage: Rscript code/write_research_note.R OUTPUT_DIR")
out <- args[[1]]
read_table <- function(path) read.csv(file.path(out,path),check.names=FALSE,
                                     stringsAsFactors=FALSE)
rates <- read_table("tables/reported_loan_entries_by_residence.csv")
annual <- read_table("tables/annual_durable_purchase_by_reporting_status.csv")
annual_m <- read_table("tables/annual_durable_purchase_associations.csv")
model <- read_table("tables/regression_coefficients.csv")
fin <- read_table("tables/financing_source_groups.csv")
source <- read_table("diagnostics/sample_linkage.csv")
fee <- read_table("diagnostics/loan_field_diagnostics.csv")
sz <- read_table("diagnostics/model_sample_sizes.csv")
sector <- read_table("tables/sector_purchase_associations.csv")
loan_types <- read_table("tables/exclusive_loan_reporting_groups.csv")
sensitivity <- read_table("tables/borrowing_measurement_and_control_sensitivity.csv")
leaveout <- read_table("tables/leaveout_primary_robustness.csv")
reconciliation <- read_table("diagnostics/expenditure_leaveout_reconciliation.csv")


cell <- function(x) sprintf("%.2f",x)
pct <- function(x) sprintf("%.2f%%",100*x)
nfmt <- function(x) format(x,big.mark=",",scientific=FALSE,trim=TRUE)
ptext <- function(p) ifelse(p<0.001,"<0.001",sprintf("%.3f",p))
get <- function(label) {
 v <- source$count[source$scope==label]
 if(length(v)!=1L) stop("Missing source count: ",label)
 v
}
extract <- function(m,t) {
 d <- subset(model,model==m & term==t)
 if(nrow(d)!=1L) stop("Missing model coefficient ",m,":",t)
 d
}
baseline_q4 <- extract("reported_entry_logit","expenditure_quartileQ4")
province_q4 <- extract("reported_entry_province_FE","expenditure_quartileQ4")
food_baseline <- extract("food_share_linear","reported_entry")
food_fe <- extract("food_share_province_FE","reported_entry")

rows <- c(
 "# Household Borrowing Reports and Durable-Goods Purchases",
 "",
 "## Abstract",
 "",
 paste0(
  "Using the 1393 Household Expenditure and Income Survey (2014–15), ",
  "we examine household reports of loan-related financial-service entries ",
  "and the relationship with expenditures on selected durable goods. ",
  "The underlying expenditure workbooks contain ",nfmt(get("Source household workbooks")),
  " households, of which ",nfmt(get("Distinct reporting households")),
  " have at least one loan-related Table 13 entry. ",
  "The survey-weighted reporting rate in the household-workbook sample is ",
  pct(rates$reported_share_weighted[rates$group=="All"]),
  ". Loan-entry reporting and purchases of furnishings, appliances, and ",
  "personal transport equipment are positively associated conditional ",
  "on expenditure position and observed household characteristics. ",
  "These results are descriptive; loan reports do not measure all credit ",
  "access, and the analysis cannot identify financing or causal effects."
 ),
 "",
 "## 1. Survey data and measurement",
 "",
 paste0(
  "The original Access roster includes ",nfmt(get("Full Access roster")),
  " household records, while the corresponding distributed rural and urban ",
  "summary workbooks contain ",nfmt(get("Source household workbooks")),
  ". The survey's Part 3, Table 13 includes ",
  nfmt(get("Loan-related records")),
  " loan-associated financial-service records for ",
  nfmt(get("Distinct reporting households")),
  " distinct households. Every such household matches the expenditure ",
  "workbooks. The source is pinned to a fixed Git commit and SHA-256 hashes."
 ),
 "",
 "The two loan-related item codes are **126111** (housing) and **126112** ",
 "(non-housing). The survey records a loan amount, a free-text financing ",
 "source, and a financial-service charge. We define **loan-entry reporting** ",
 "as the presence of at least one such item. No entry means no recorded ",
 "**entry of this type**, not necessarily no borrowing or outstanding debt.",
 "",
 "Our principal expenditure outcomes use Table 13 purchases recorded over ",
 "the **previous 12 months**: code families **051** (furniture and furnishings), ",
 "**053** (household appliances), and **071** (personal transport equipment). ",
 "Purchased records have acquisition method 1, and reported gross nominal ",
 "purchase amounts are not netted against sales of used items. The shared ",
 "recall window is preferable to comparing an annual loan report directly ",
 "with one month of occasional durable purchases.",
 "",
 "## 2. Descriptive results",
 "",
 "### Loan-related reporting",
 "",
 "| Residence | Households | Reporting households | Weighted reporting rate |",
 "| --- | ---: | ---: | ---: |"
)
for(i in seq_len(nrow(rates))) {
 d <- rates[i,]
 rows <- c(rows,sprintf("| %s | %s | %s | %s |",d$group,
                       nfmt(d$households),nfmt(d$reporting_households),
                       pct(d$reported_share_weighted)))
}
rows <- c(rows,
 "",
 "### Durable-purchase participation over the previous 12 months",
 "",
 "The next table reports weighted percentages of households with positive ",
 "gross purchases. The two groups are households **without** and **with** ",
 "a recorded loan-related financial-service entry.",
 "",
 "| Category | Residence | No entry | Entry | Difference (pp) |",
 "| --- | --- | ---: | ---: | ---: |"
)
for(cat in unique(annual$purchase_group)) {
 for(res in c("Rural","Urban")) {
  a <- subset(annual,purchase_group==cat & residence==res & reported_entry==0)
  b <- subset(annual,purchase_group==cat & residence==res & reported_entry==1)
  if(nrow(a)!=1L||nrow(b)!=1L) stop("Missing annual durable group")
  rows <- c(rows,sprintf("| %s | %s | %s | %s | %s |",
                         cat,res,pct(a$weighted_purchase_incidence),
                         pct(b$weighted_purchase_incidence),
                         cell(100*(b$weighted_purchase_incidence-
                                   a$weighted_purchase_incidence))))
 }
}
rows <- c(rows,
 "",
 "![Selected durable purchases, by residence and reporting status](figures/annual_durable_purchase_participation.png)",
 "",
 "## 3. Conditional associations",
 "",
 "We estimate survey-weighted logistic models for the presence of each ",
 "selected annual purchase category and for any such purchase. These models ",
 "adjust for weighted quartiles of annual expenditure per household member, ",
 "rural/urban residence, household-head age, gender, literacy, and the ",
 "logarithm of household size. The adjusted odds ratios for loan-entry ",
 "reporting are:",
 "",
 "| Annual purchase outcome | Odds ratio | 95% interval (weights-only) | 95% interval (province clusters) | Cluster BH-adjusted p |",
 "| --- | ---: | ---: | ---: | ---: |"
)
for(i in seq_len(nrow(annual_m))) {
 a <- annual_m[i,]
 rows <- c(rows,sprintf("| %s | %s | %s–%s | %s–%s | %s |",
                       a$purchase_group,cell(a$odds_ratio),
                       cell(a$ci95_lower),cell(a$ci95_upper),
                       cell(a$province_cluster_ci95_lower),
                       cell(a$province_cluster_ci95_upper),
                       ptext(a$province_cluster_fdr_bh_p)))
}
rows <- c(rows,
 "",
 "These province-clustered intervals treat provinces as clusters and",
 "use t-based critical values with the fitted model residual degrees",
 "of freedom. The estimates are a variance sensitivity check rather than",
 "an official reconstruction of the HEIS sampling design.",
 "",
 paste0(
 "The baseline weighted logit for loan-entry reporting itself finds a ",
 "positive conditional association for the highest versus lowest ",
 "expenditure-per-person quartile (OR ",
 cell(exp(baseline_q4$estimate)),
 ", 95% interval ",
 cell(exp(baseline_q4$estimate-1.96*baseline_q4$standard_error)),
 "–",cell(exp(baseline_q4$estimate+1.96*baseline_q4$standard_error)),
 "). A province-adjusted version gives OR ",
 cell(exp(province_q4$estimate)),
 ". These are distinct adjusted specifications, not a causal gradient."
 ),
 "",
 paste0(
 "In a secondary weighted linear model, reported loan-entry status is ",
 "associated with a food budget share ",
 cell(100*food_baseline$estimate),
 " percentage points lower conditional on the baseline controls; the ",
 "province-adjusted specification gives ",
 cell(100*food_fe$estimate),
 " percentage points. Food share and total expenditure are mechanically ",
 "related, and both may be endogenous to household financial decisions."
 ),
 "",
 "### Measurement and expenditure-control sensitivity",
 "",
 "Because annual total expenditure includes some of the purchases being",
 "modeled, the baseline quartile control may mechanically overlap with",
 "the dependent variable. An additional specification subtracts gross",
 "purchases in code families 051, 053, and 071 before computing weighted",
 "expenditure-per-person quartiles. This is an accounting sensitivity,",
 "not a validated measure of nondurable expenditure, income, or wealth.",
 "The same eligible households are used to compare the total and",
 "leave-out expenditure controls.",
 "",
 paste0(
 "The leave-out comparison retains ",
 nfmt(sum(reconciliation$leaveout_eligible)),
 " households; ",
 nfmt(sum(reconciliation$households)-sum(reconciliation$leaveout_eligible)),
 " are excluded by the leave-out or control-variable requirements."
 ),
 "",
 "| Annual outcome | Total-expenditure OR (same sample) | Leave-out OR | Province-clustered 95% interval (leave-out) |",
 "| --- | ---: | ---: | ---: |"
)
for(cat in leaveout$outcome) {
 full <- subset(sensitivity,outcome==cat & loan_comparison=="any" &
                quartile_measure=="full")
 alt <- subset(leaveout,outcome==cat)
 if(nrow(full)!=1L || nrow(alt)!=1L)
   stop("Missing matched expenditure-control sensitivity for ",cat)
 rows <- c(rows,sprintf("| %s | %s | %s | %s–%s |",
                        cat,cell(full$odds_ratio),cell(alt$odds_ratio),
                        cell(alt$province_cluster_ci95_lower),
                        cell(alt$province_cluster_ci95_upper)))
}
rows <- c(rows,
 "",
 "As a distinct measurement check, households are classified into four",
 "mutually exclusive groups: no loan-related entry, housing-only,",
 "non-housing-only, or both types. Housing-only and non-housing-only",
 "associations are estimated separately against households without an",
 "entry. These are not comparisons with verified nonborrowers.",
 "",
 "| Residence | Reported loan-item group | Households | Weighted group share |",
 "| --- | --- | ---: | ---: |"
)
for(i in seq_len(nrow(loan_types))) {
 x <- loan_types[i,]
 rows <- c(rows,sprintf("| %s | %s | %s | %s |",
                        x$residence,x$loan_group,
                        nfmt(x$households),pct(x$weighted_fraction)))
}
rows <- c(rows,
 "",
 "For the combined durable-purchase outcome, the alternative comparisons are:",
 "",
 "| Loan-report comparison | Leave-out adjusted OR | 95% interval (weights-only) |",
 "| --- | ---: | ---: |"
)
for(k in c("nonhousing_only_vs_none","housing_only_vs_none")) {
 x <- subset(sensitivity,outcome=="Any selected durable group" &
             loan_comparison==k & quartile_measure=="leaveout")
 if(nrow(x)!=1L) stop("Missing loan-type comparison: ",k)
 label <- if(k=="nonhousing_only_vs_none") "Non-housing only vs no entry" else
                                           "Housing only vs no entry"
 rows <- c(rows,sprintf("| %s | %s | %s–%s |",
                        label,cell(x$odds_ratio),
                        cell(x$ci95_lower),cell(x$ci95_upper)))
}
rows <- c(rows,
 "",
 "The control-substitution exercise does not remove selection bias,",
 "prove that a loan paid for a purchase, or identify a causal effect.",
 "Province clustering remains a sensitivity approximation rather than",
 "the official survey design.",
 "",
 "### Additional monthly purchase categories",
 "",
 "The questionnaire separately records previous-month spending on clothing ",
 "and footwear, furnishings, transport, communications, recreation and ",
 "culture, and prepared food and accommodation. The repo reports weighted ",
 "participation and expenditure for each. These **monthly** observations ",
 "are neither an exhaustive annual consumption basket nor a decomposition ",
 "of full annual expenditures.",
 "",
 "![Previous-month purchase participation](figures/monthly_sector_purchase_participation.png)",
 "",
 "## 4. Financial intermediation and measurement issues",
 "",
 paste0(
 "The loan-record financing-source field is nonempty in approximately ",
 pct(1-sum(fin$records[fin$source_group=="Missing"])/sum(fin$records)),
 " of records. An exploratory text rule identifies explicit bank names, ",
 "recognizable bank shorthand, funds/other institutions, and ambiguous ",
 "responses. This is not a verified market-share classification."
 ),
 "",
 paste0(
 "The two loan-charge types have a notable concentration of the ",
 "reported charge-to-amount ratio at **2.5%** ",
 "(for the dominant share of records), so these charges must not ",
 "be interpreted as contractual loan interest rates, APRs, or effective ",
 "borrowing costs. The original questionnaire is the interpretive basis ",
 "for the relevant item codes and fields."
 ),
 "",
 "## 5. Design limitations",
 "",
 "1. The credit variable records a particular annual fee-linked loan item, ",
 "**not complete credit access, outstanding debt, loan origination, or approval**.",
 "2. The data are a single cross-section. Credit selection, omitted wealth ",
 "and preferences, and simultaneity prevent causal interpretation.",
 "3. A positive annual durable-purchase record cannot be linked to a ",
 "particular loan or lender, even when the household reports both.",
 "4. Sample weights are applied, but the original stratification and ",
 "PSU structure have not been established. Reported regression standard ",
 "errors and 95% intervals use a **weights-only, independent-household** ",
 "approximation and are not fully design-consistent.",
 "5. The questionnaire's 12-month and monthly components are reported ",
 "separately. Monthly purchases, especially infrequent durables, must ",
 "not be annualized mechanically.",
 "6. Financial-source coding uses free text and transparent heuristics.",
 "",
 "## 6. Reproducibility",
 "",
 "The analysis retrieves the three pinned survey archives from the ",
 "unchanged companion repository, checks their SHA-256 hashes, validates ",
 "survey record counts, and runs in a locked Pixi/R environment. ",
 "The GitHub Actions workflow re-estimates the models and verifies that ",
 "all aggregate figures and tables exist. No record-level identifiers ",
 "or household microdata are published in the results.",
 "",
 "- [Detailed methodology](../docs/METHODOLOGY.md)",
 "- [Reproducibility instructions](../README.md)",
 "- [Aggregate model coefficients](tables/regression_coefficients.csv)",
 "- [Annual durable outcomes](tables/annual_durable_purchase_associations.csv)",
 "- [Comparable expenditure-control sensitivities](tables/borrowing_measurement_and_control_sensitivity.csv)",
 "- [Exclusive loan-report classifications](tables/exclusive_loan_reporting_groups.csv)",
 "- [Monthly sector outcomes](tables/sector_purchase_associations.csv)",
 "- [Financing-source diagnostics](tables/financing_source_groups.csv)",
 "",
 "*Note: This is a descriptive empirical research sample, not an estimate ",
 "of the causal effects of borrowing or monetary policy.*"
)
writeLines(rows,file.path(out,"RESEARCH_NOTE.md"),useBytes=TRUE)
message("Wrote research note: ",file.path(out,"RESEARCH_NOTE.md"))
