# Validate aggregate results and source coverage after the analysis.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: Rscript code/validate.R OUTPUT_DIR")
out <- args[[1]]
required <- c(
  "RESULTS.md",
  "RESEARCH_NOTE.md",
  "tables/reported_loan_entries_by_residence.csv",
  "tables/reported_entries_by_expenditure_quartile.csv",
  "tables/budget_composition_by_reporting_status.csv",
  "tables/reported_loan_amounts.csv",
  "tables/regression_coefficients.csv",
  "diagnostics/source_loan_record_counts.csv",
  "diagnostics/sample_linkage.csv",
  "diagnostics/loan_field_diagnostics.csv",
  "diagnostics/analysis_sample_checks.csv",
  "diagnostics/model_sample_sizes.csv",
  "diagnostics/lender_source_heuristic.csv",
  "diagnostics/expenditure_quartile_boundaries.csv",
  "diagnostics/session_info.txt",
  "figures/reported_entries_by_expenditure_quartile.png",
  "figures/monthly_sector_purchase_participation.png",
  "tables/annual_durable_purchase_by_reporting_status.csv",
  "tables/annual_durable_purchase_associations.csv",
  "diagnostics/annual_durable_purchase_source_counts.csv",
  "figures/annual_durable_purchase_participation.png",
  "tables/financing_source_groups.csv",
  "tables/monthly_sector_spending_by_reporting_status.csv",
  "tables/monthly_sector_spending_differences.csv",
  "tables/sector_purchase_associations.csv",
  "tables/borrowing_measurement_and_control_sensitivity.csv",
  "tables/leaveout_primary_robustness.csv",
  "tables/loan_type_joint_contrast.csv",
  "tables/exclusive_loan_reporting_groups.csv",
  "diagnostics/loan_type_field_audit.csv",
  "diagnostics/loan_entry_multiplicity.csv",
  "diagnostics/expenditure_leaveout_reconciliation.csv",
  "diagnostics/alternative_expenditure_quartiles.csv",
  "diagnostics/alternative_rank_crosswalk.csv",
  "diagnostics/measurement_sensitivity_summary.csv",
  "diagnostics/measurement_sensitivity_notes.txt",
  "diagnostics/selected_durable_item_code_audit.csv",
  "diagnostics/sector_source_coverage.csv",
  "diagnostics/source_text_classification_coverage.csv",
  "diagnostics/extended_analysis_notes.txt"
)
paths <- file.path(out, required)
if (any(!file.exists(paths) | file.info(paths)$size <= 0L))
  stop("Missing or empty output: ", paste(required[!file.exists(paths) |
        file.info(paths)$size <= 0L], collapse = ", "))
s <- read.csv(file.path(out, "diagnostics/sample_linkage.csv"))
val <- function(name) s$count[match(name, s$scope)]
stopifnot(
  val("Full Access roster") == 39856,
  val("Source household workbooks") == 38275,
  val("Loan-related records") == 6053,
  val("Distinct reporting households") == 5848,
  val("Reporting households matched to workbooks") +
    val("Reporting households absent from workbooks") == 5848
)
rates <- read.csv(file.path(out, "tables/reported_loan_entries_by_residence.csv"))
stopifnot(nrow(rates) == 3L,
          all(is.finite(rates$reported_share_weighted)),
          all(rates$reported_share_weighted >= 0 & rates$reported_share_weighted <= 1))
loan <- read.csv(file.path(out, "diagnostics/loan_field_diagnostics.csv"))
stopifnot(sum(loan$records) == 6053,
          all(loan$median_amount_rials > 0),
          all(loan$median_charge_rials > 0))
co <- read.csv(file.path(out, "tables/regression_coefficients.csv"))
stopifnot(setequal(unique(co$model),
                   c("reported_entry_logit", "food_share_linear",
                     "reported_entry_province_FE", "nonhousing_entry_logit",
                     "food_share_province_FE")),
          !anyDuplicated(co[c("model", "term")]),
          all(is.finite(co$estimate)), all(is.finite(co$standard_error)),
          all(co$standard_error > 0), all(co$p_value >= 0 & co$p_value <= 1))
png <- readBin(file.path(out, "figures/reported_entries_by_expenditure_quartile.png"),
               "raw", 8)
stopifnot(identical(png, as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))))
source_groups <- read.csv(file.path(out, "tables/financing_source_groups.csv"))
stopifnot(sum(source_groups$records) == 6053,
          all(source_groups$share_within_purpose >= 0 &
              source_groups$share_within_purpose <= 1))
spending <- read.csv(file.path(out, "tables/monthly_sector_spending_by_reporting_status.csv"))
stopifnot(nrow(spending) == 24L,
          all(spending$households > 0),
          all(spending$weighted_purchase_incidence >= 0 &
              spending$weighted_purchase_incidence <= 1),
          all(spending$weighted_mean_monthly_purchase_rials >= 0))
purchase_models <- read.csv(file.path(out, "tables/sector_purchase_associations.csv"))
stopifnot(nrow(purchase_models) == 6L,
          all(purchase_models$n == 38275L |
              purchase_models$n == 38189L),
          all(is.finite(purchase_models$odds_ratio)),
          all(purchase_models$odds_ratio > 0),
          all(purchase_models$ci95_lower > 0),
          all(purchase_models$ci95_upper >= purchase_models$ci95_lower),
          all(purchase_models$fdr_bh_p_value >= 0 &
              purchase_models$fdr_bh_p_value <= 1))
annual_table <- read.csv(file.path(out,
                  "tables/annual_durable_purchase_by_reporting_status.csv"))
stopifnot(nrow(annual_table) == 12L,
          all(annual_table$households > 0),
          all(annual_table$weighted_purchase_incidence >= 0 &
              annual_table$weighted_purchase_incidence <= 1),
          all(annual_table$weighted_mean_annual_purchase_rials >= 0))
annual_models <- read.csv(file.path(out,
                    "tables/annual_durable_purchase_associations.csv"))
stopifnot(nrow(annual_models) == 4L,
          all(is.finite(annual_models$odds_ratio) &
              annual_models$odds_ratio > 0),
          all(annual_models$ci95_lower > 0 &
              annual_models$ci95_upper >= annual_models$ci95_lower),
          all(annual_models$fdr_bh_p_value >= 0 &
              annual_models$fdr_bh_p_value <= 1),
          all(annual_models$province_clusters == 31L),
          all(annual_models$province_cluster_residual_df > 0 &
              annual_models$province_cluster_residual_df <= 30),
          all(annual_models$province_cluster_standard_error > 0),
          all(annual_models$province_cluster_ci95_lower > 0 &
              annual_models$province_cluster_ci95_upper >=
              annual_models$province_cluster_ci95_lower),
          all(annual_models$province_cluster_fdr_bh_p >= 0 &
              annual_models$province_cluster_fdr_bh_p <= 1))
loan_groups <- read.csv(file.path(out,"tables/exclusive_loan_reporting_groups.csv"))
stopifnot(sum(loan_groups$households)==38275L,
          all(loan_groups$weighted_fraction>=0 &
              loan_groups$weighted_fraction<=1),
          all(abs(aggregate(weighted_fraction~residence,loan_groups,sum)$weighted_fraction-1)<1e-10))
loan_types <- read.csv(file.path(out,"diagnostics/loan_type_field_audit.csv"))
stopifnot(sum(loan_types$records)==6053L,
          all(loan_types$median_reported_amount>0),
          all(loan_types$source_nonempty_fraction>=0 &
              loan_types$source_nonempty_fraction<=1))
recon <- read.csv(file.path(out,"diagnostics/expenditure_leaveout_reconciliation.csv"))
stopifnot(sum(recon$households)==38275L,
          sum(recon$leaveout_eligible)>=30000L,
          all(recon$leaveout_eligible<=recon$households))
sensitivity <- read.csv(file.path(out,
 "tables/borrowing_measurement_and_control_sensitivity.csv"))
primary <- read.csv(file.path(out,"tables/leaveout_primary_robustness.csv"))
stopifnot(nrow(sensitivity)==16L,nrow(primary)==4L,
          setequal(unique(sensitivity$loan_comparison),
                   c("any","nonhousing_only_vs_none","housing_only_vs_none")),
          all(is.finite(sensitivity$odds_ratio)&sensitivity$odds_ratio>0),
          all(is.finite(sensitivity$standard_error)&sensitivity$standard_error>0),
          all(is.finite(sensitivity$standardized_probability_difference_pp)),
          all(sensitivity$ci95_lower>0 &
              sensitivity$ci95_upper>=sensitivity$ci95_lower),
          all(primary$observations==sum(recon$leaveout_eligible)),
          all(primary$province_cluster_df>0 &
              primary$province_cluster_df<=30),
          all(primary$province_cluster_ci95_lower>0 &
              primary$province_cluster_ci95_upper>=primary$province_cluster_ci95_lower),
          all(primary$province_cluster_BH_p>=0 &
              primary$province_cluster_BH_p<=1))
# Pin the published headline estimates to the checksum-verified source and lockfile.
# These are regression-test reference results, not additional statistical tests.
assert_estimate <- function(actual, expected, tolerance = 1e-5) {
  stopifnot(length(actual) == length(expected), !anyNA(actual),
            all(is.finite(actual)),
            all(abs(unname(actual) - unname(expected)) < tolerance))
}
# Pin the corrected purchase-code interpretation and numerical estimates
# to the checksum-verified survey inputs and dependency lockfile.
code_audit <- read.csv(file.path(out,
                     "diagnostics/selected_durable_item_code_audit.csv"))
stopifnot(all(code_audit$records>0),
          all(code_audit$nominal_total_rials>0),
          any(code_audit$selected),
          sum(code_audit$records[code_audit$selected])>0)
stopifnot(
  sum(code_audit$records[!code_audit$selected]) == 874L,
  sum(code_audit$records[code_audit$selected]) == 20569L,
  sum(primary$purchase_households[primary$outcome == "Any selected durable group"]) == 11486L,
  sum(recon$leaveout_eligible) == 38275L
)
expected_annual <- c(
  "Furniture and furnishings" = 1.44352455093663,
  "Household appliances" = 1.48841478039395,
  "Personal transport equipment" = 1.74015620813898,
  "Any selected durable group" = 1.55253750896737
)
stopifnot(setequal(annual_models$purchase_group, names(expected_annual)))
assert_estimate(annual_models$odds_ratio[
  match(names(expected_annual),annual_models$purchase_group)],
  expected_annual)
expected_leaveout <- c(
  "Furniture and furnishings" = 1.51484596902859,
  "Household appliances" = 1.53836642071245,
  "Personal transport equipment" = 2.08656293289689,
  "Any selected durable group" = 1.64376886493273
)
stopifnot(setequal(primary$outcome,names(expected_leaveout)))
assert_estimate(primary$odds_ratio[
  match(names(expected_leaveout),primary$outcome)],
  expected_leaveout)
expected_groups <- c(
  any = 1.64376886493273,
  nonhousing_only_vs_none = 1.70673854754212,
  housing_only_vs_none = 1.16311301911292
)
group_observed <- subset(sensitivity,
  outcome == "Any selected durable group" & quartile_measure == "leaveout")
stopifnot(setequal(group_observed$loan_comparison,names(expected_groups)))
assert_estimate(group_observed$odds_ratio[
  match(names(expected_groups),group_observed$loan_comparison)],
  expected_groups)
joint <- read.csv(file.path(out,"tables/loan_type_joint_contrast.csv"))
stopifnot(nrow(joint)==2L,
          setequal(joint$variance_method,c("Weights-only","Province-clustered")),
          all(joint$observations==38275L),
          all(joint$housing_only_n==556L),
          all(joint$nonhousing_only_n==5176L),
          all(joint$ci95_lower>0 & joint$ci95_upper>=joint$ci95_lower),
          all(joint$p_value>=0 & joint$p_value<=1))
assert_estimate(joint$odds_ratio_ratio, rep(1.46194188978319,2L))
assert_estimate(
  c(joint$ci95_lower[joint$variance_method=="Province-clustered"],
    joint$ci95_upper[joint$variance_method=="Province-clustered"]),
  c(1.16157293925257,1.83998267941581))
assert_estimate(rates$reported_share_weighted[rates$group == "All"],
                0.136942683409159, tolerance = 1e-8)
stopifnot(sum(loan_groups$households[loan_groups$loan_group == "Housing only"]) == 556L,
          sum(loan_groups$households[loan_groups$loan_group == "Non-housing only"]) == 5176L,
          sum(loan_groups$households[loan_groups$loan_group == "Both types"]) == 116L)


message("All output and source-coverage checks passed.")
