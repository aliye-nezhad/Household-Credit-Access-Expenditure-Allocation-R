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
              annual_models$fdr_bh_p_value <= 1))
message("All output and source-coverage checks passed.")
