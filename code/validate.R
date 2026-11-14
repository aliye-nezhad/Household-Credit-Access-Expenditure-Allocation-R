# Validate aggregate results and source coverage after the analysis.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: Rscript code/validate.R OUTPUT_DIR")
out <- args[[1]]
required <- c(
  "RESULTS.md",
  "tables/reported_loan_entries_by_residence.csv",
  "tables/reported_entries_by_expenditure_quartile.csv",
  "tables/budget_composition_by_reporting_status.csv",
  "tables/reported_loan_amounts.csv",
  "tables/regression_coefficients.csv",
  "diagnostics/source_loan_record_counts.csv",
  "diagnostics/sample_linkage.csv",
  "diagnostics/loan_field_diagnostics.csv",
  "diagnostics/analysis_sample_checks.csv",
  "diagnostics/lender_source_heuristic.csv",
  "diagnostics/expenditure_quartile_boundaries.csv",
  "diagnostics/session_info.txt",
  "figures/reported_entries_by_expenditure_quartile.png"
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
                   c("reported_entry_logit", "food_share_linear")),
          !anyDuplicated(co[c("model", "term")]),
          all(is.finite(co$estimate)), all(is.finite(co$standard_error)),
          all(co$standard_error > 0), all(co$p_value >= 0 & co$p_value <= 1))
png <- readBin(file.path(out, "figures/reported_entries_by_expenditure_quartile.png"),
               "raw", 8)
stopifnot(identical(png, as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))))
message("All output and source-coverage checks passed.")
