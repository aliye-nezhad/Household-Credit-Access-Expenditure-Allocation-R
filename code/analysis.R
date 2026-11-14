# Reported household borrowing and expenditure patterns, HEIS 1393.
# Outputs contain aggregate statistics only; no household-level records.
suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(ggplot2)
  library(survey)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript code/analysis.R INPUT_DIR OUTPUT_DIR")
input_dir <- normalizePath(args[[1]], mustWork = TRUE)
output_dir <- args[[2]]
dir.create(file.path(output_dir, "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "diagnostics"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "figures"), recursive = TRUE, showWarnings = FALSE)

write_table <- function(df, filename, group = "tables") {
  write.csv(as.data.frame(df), file.path(output_dir, group, filename),
            row.names = FALSE, na = "")
}
as_id <- function(x) {
  y <- trimws(as.character(x))
  y <- sub("\\.0+$", "", y)
  y[is.na(x) | !nzchar(y)] <- NA_character_
  y
}
as_num <- function(x) suppressWarnings(as.numeric(trimws(as.character(x))))
stop_if <- function(condition, message) {
  if (isTRUE(condition)) stop(message, call. = FALSE)
}

read_households <- function(residence) {
  path <- file.path(input_dir, paste0(if (residence == "Rural") "R93" else "U93", ".xls"))
  required <- c("ADDRESS", "A01", "A02", "A03", "C01",
                "GHazineh", "VKhorak", "weight")
  header <- names(read_excel(path, n_max = 0))
  absent <- setdiff(required, header)
  stop_if(length(absent) > 0L,
          paste("Missing household workbook fields:", paste(absent, collapse = ", ")))
  data <- read_excel(path, col_types = ifelse(header %in% required, "text", "skip"))
  names(data)[names(data) == "ADDRESS"] <- "Address"
  data <- data %>%
    mutate(
      Address = as_id(Address),
      residence = residence,
      province = substr(Address, 2, 3),
      gender = factor(A01, levels = c("1", "2"),
                      labels = c("Male", "Female")),
      literacy = factor(A03, levels = c("1", "2"),
                        labels = c("Literate", "Illiterate")),
      age = as_num(A02),
      household_size = as_num(C01),
      annual_expenditure = as_num(GHazineh),
      annual_food_expenditure = as_num(VKhorak),
      weight = as_num(weight)
    ) %>%
    select(Address, residence, province, gender, literacy, age,
           household_size, annual_expenditure, annual_food_expenditure, weight)
  stop_if(anyNA(data$Address) || anyDuplicated(data$Address) > 0L,
          paste("Duplicate or missing household identifier in", residence))
  stop_if(any(!grepl("^[12][0-9]{10}$", data$Address)),
          paste("Unexpected household identifier in", residence))
  data
}

read_loan_records <- function(residence) {
  prefix <- if (residence == "Rural") "R93" else "U93"
  path <- file.path(input_dir, paste0(prefix, "P3S13.csv"))
  tab <- read.csv(path, colClasses = "character", check.names = FALSE,
                  fileEncoding = "UTF-8")
  needed <- c("Address", paste0("DYCOL0", 1:6))
  stop_if(length(setdiff(needed, names(tab))) > 0L,
          paste("Missing Table 13 columns in", basename(path)))
  tab %>%
    filter(DYCOL01 %in% c("126111", "126112")) %>%
    transmute(
      Address = as_id(Address), residence = residence,
      item_code = DYCOL01,
      loan_purpose = ifelse(item_code == "126111", "Housing", "Non-housing"),
      reported_amount_rials = as_num(DYCOL02),
      reported_financing_source = trimws(coalesce(DYCOL03, "")),
      acquisition_method = trimws(coalesce(DYCOL04, "")),
      reported_charge_rials = as_num(DYCOL05),
      resale_rials = as_num(DYCOL06)
    )
}
households <- bind_rows(read_households("Rural"), read_households("Urban"))
loans <- bind_rows(read_loan_records("Rural"), read_loan_records("Urban"))

stop_if(nrow(households) != 38275L, "Unexpected household workbook sample size")
stop_if(nrow(loans) != 6053L, "Loan-related source record count differs from audit")
stop_if(anyNA(loans$Address) || any(!is.finite(loans$reported_amount_rials)) ||
          any(loans$reported_amount_rials <= 0),
        "Loan identifiers or amount fields do not match the audited source")
stop_if(any(!is.finite(loans$reported_charge_rials)) ||
          any(loans$reported_charge_rials <= 0),
        "Financial-service charge fields differ from the audited source")

# Verify source records against the original household roster, not only the
# subset retained in the separately distributed household workbooks.
raw_roster <- bind_rows(lapply(c("Rural", "Urban"), function(res) {
  prefix <- if (res == "Rural") "R93" else "U93"
  x <- read.csv(file.path(input_dir, paste0(prefix, "Data.csv")),
                colClasses = "character", check.names = FALSE)
  stop_if(!"Address" %in% names(x), paste("Roster lacks Address:", prefix))
  tibble(Address = as_id(x$Address), residence = res)
}))
stop_if(anyDuplicated(raw_roster[c("residence", "Address")]) > 0L,
        "Duplicated survey-roster keys")
stop_if(nrow(raw_roster) != 39856L, "Unexpected raw roster size")
orphaned <- anti_join(loans, raw_roster, by = c("residence", "Address"))
stop_if(nrow(orphaned) > 0L, "Loan records fail to match the Access roster")

# A report indicates a fee-linked Table 13 entry, not necessarily the
# origination of a loan in the interview year or outstanding household debt.
loan_household <- loans %>%
  group_by(residence, Address) %>%
  summarise(
    reported_entry = 1L,
    housing_entry = as.integer(any(item_code == "126111")),
    nonhousing_entry = as.integer(any(item_code == "126112")),
    loan_entry_count = n(),
    maximum_reported_amount = max(reported_amount_rials),
    sum_of_reported_amount_fields = sum(reported_amount_rials),
    .groups = "drop"
  )
stop_if(nrow(loan_household) != 5848L, "Unexpected distinct loan-entry household count")
matched <- semi_join(loan_household, households, by = c("residence", "Address"))
unmatched <- anti_join(loan_household, households, by = c("residence", "Address"))
summary_rows <- bind_rows(
  loans %>% count(residence, loan_purpose, name = "records"),
  loans %>% count(residence, name = "records") %>%
    mutate(loan_purpose = "All loan-related")
)
write_table(summary_rows, "source_loan_record_counts.csv", "diagnostics")
write_table(
  tibble(
    scope = c("Full Access roster", "Source household workbooks",
              "Loan-related records", "Distinct reporting households",
              "Reporting households matched to workbooks",
              "Reporting households absent from workbooks"),
    count = c(nrow(raw_roster), nrow(households), nrow(loans),
              nrow(loan_household), nrow(matched), nrow(unmatched))
  ), "sample_linkage.csv", "diagnostics"
)
write_table(
  loans %>%
    group_by(residence, loan_purpose) %>%
    summarise(records = n(), distinct_households = n_distinct(Address),
              median_amount_rials = median(reported_amount_rials),
              p25_amount_rials = as.numeric(quantile(reported_amount_rials, .25)),
              p75_amount_rials = as.numeric(quantile(reported_amount_rials, .75)),
              median_charge_rials = median(reported_charge_rials),
              source_reported_fraction = mean(nzchar(reported_financing_source)),
              fraction_acquisition_method_1 = mean(acquisition_method == "1"),
              fraction_charge_exactly_2_5_percent =
                mean(abs(reported_charge_rials / reported_amount_rials - .025) < 1e-10),
              .groups = "drop"),
  "loan_field_diagnostics.csv", "diagnostics"
)

# Exploratory source categories. Text classification is intentionally
# conservative and is not a verified classification of formal credit.
clean_source <- function(x) {
  x <- gsub("\u064a", "\u06cc", x, fixed = TRUE)
  x <- gsub("\u0643", "\u06a9", x, fixed = TRUE)
  x
}
source_text <- clean_source(loans$reported_financing_source)
loans$lender_group <- ifelse(
  !nzchar(source_text), "Not reported",
  ifelse(grepl("بانک", source_text), "Explicit bank name",
         ifelse(grepl("صندوق|قرض", source_text), "Fund / qard al-hasanah",
                "Other or ambiguous"))
)
write_table(loans %>%
              count(residence, loan_purpose, lender_group, name = "records") %>%
              group_by(residence, loan_purpose) %>%
              mutate(share_of_records = records / sum(records)) %>%
              ungroup(),
            "lender_source_heuristic.csv", "diagnostics")

# Retain the entire household workbook sample for reporting-entry rates.
# No entry is coded as zero *reported transactions*, not zero borrowing.
hh <- households %>%
  left_join(loan_household, by = c("residence", "Address"),
            relationship = "one-to-one") %>%
  mutate(
    reported_entry = coalesce(reported_entry, 0L),
    housing_entry = coalesce(housing_entry, 0L),
    nonhousing_entry = coalesce(nonhousing_entry, 0L),
    loan_entry_count = coalesce(loan_entry_count, 0L),
    residence = factor(residence, levels = c("Rural", "Urban")),
    food_share = ifelse(is.finite(annual_expenditure) & annual_expenditure > 0 &
                            is.finite(annual_food_expenditure),
                        annual_food_expenditure / annual_expenditure, NA_real_),
    nonfood_share = 1 - food_share,
    spending_per_person = annual_expenditure / household_size
  )
stop_if(nrow(hh) != nrow(households), "Household merge changed sample size")

# Conservative analytical-sample filters are explicitly diagnosed.
hh$valid_weight <- is.finite(hh$weight) & hh$weight > 0
hh$valid_food_share <- is.finite(hh$food_share) & hh$food_share >= 0 &
  hh$food_share <= 1
hh$valid_spending <- is.finite(hh$spending_per_person) & hh$spending_per_person > 0
hh$valid_controls <- !is.na(hh$gender) & !is.na(hh$literacy) &
  is.finite(hh$age) & hh$age >= 10 & hh$age <= 110 &
  is.finite(hh$household_size) & hh$household_size > 0

write_table(hh %>%
              group_by(residence) %>%
              summarise(
                workbook_n = n(),
                reported_entry_n = sum(reported_entry),
                weight_valid_n = sum(valid_weight),
                expenditure_valid_n = sum(valid_spending),
                food_share_valid_n = sum(valid_food_share),
                controls_valid_n = sum(valid_controls),
                .groups = "drop"),
            "analysis_sample_checks.csv", "diagnostics")

weighted_rate <- function(data, field) {
  x <- data[[field]]
  w <- data$weight
  ok <- is.finite(w) & w > 0 & !is.na(x)
  if (!any(ok)) return(NA_real_)
  weighted.mean(x[ok], w[ok])
}
rate_group <- function(x) {
  x %>%
    summarise(
      households = n(),
      reporting_households = sum(reported_entry),
      reported_share_unweighted = mean(reported_entry),
      reported_share_weighted = weighted_rate(pick(everything()), "reported_entry"),
      housing_share_weighted = weighted_rate(pick(everything()), "housing_entry"),
      nonhousing_share_weighted = weighted_rate(pick(everything()), "nonhousing_entry"),
      .groups = "drop"
    )
}
valid_weight <- hh %>% filter(valid_weight)
write_table(bind_rows(
  valid_weight %>% group_by(residence) %>% rate_group() %>%
    mutate(group = as.character(residence)) %>% select(-residence),
  rate_group(valid_weight) %>% mutate(group = "All")
) %>% select(group, everything()), "reported_loan_entries_by_residence.csv")

# Create weighted quartiles of annual expenditure per household member.
# Quartiles are descriptive, not a verified income or wealth ranking.
ranked <- valid_weight %>% filter(valid_spending)
o <- order(ranked$spending_per_person)
cumw <- cumsum(ranked$weight[o]) / sum(ranked$weight[o])
cuts <- vapply(c(.25, .50, .75), function(p)
  ranked$spending_per_person[o][which(cumw >= p)[[1]]], numeric(1))
stop_if(length(unique(cuts)) != 3L, "Expenditure quartile boundaries are tied")
ranked$expenditure_quartile <- cut(
  ranked$spending_per_person, breaks = c(-Inf, cuts, Inf),
  include.lowest = TRUE, labels = paste0("Q", 1:4)
)
write_table(tibble(quartile = c("Q1 upper limit", "Q2 upper limit", "Q3 upper limit"),
                   annual_per_capita_rials = cuts),
            "expenditure_quartile_boundaries.csv", "diagnostics")
quartile_rates <- ranked %>%
  group_by(expenditure_quartile, residence) %>%
  rate_group()
write_table(quartile_rates, "reported_entries_by_expenditure_quartile.csv")

# Food/nonfood shares are directly supported by the household workbooks.
food <- ranked %>% filter(valid_food_share)
spending_groups <- food %>%
  group_by(reported_entry, residence) %>%
  summarise(
    households = n(),
    weighted_food_share = weighted.mean(food_share, weight),
    weighted_nonfood_share = weighted.mean(nonfood_share, weight),
    weighted_annual_total_expenditure = weighted.mean(annual_expenditure, weight),
    .groups = "drop"
  )
write_table(spending_groups, "budget_composition_by_reporting_status.csv")
write_table(
  loans %>%
    group_by(loan_purpose, residence) %>%
    summarise(records = n(),
              median_reported_amount_rials = median(reported_amount_rials),
              p25 = as.numeric(quantile(reported_amount_rials, .25)),
              p75 = as.numeric(quantile(reported_amount_rials, .75)),
              .groups = "drop"),
  "reported_loan_amounts.csv"
)

# Weighted pseudo-likelihood regressions. An ids=~1 design does not identify
# the official survey strata or PSUs. Interpret as descriptive associations.
model_data <- ranked %>%
  filter(valid_food_share, valid_controls) %>%
  mutate(expenditure_quartile = relevel(expenditure_quartile, "Q1"),
         log_household_size = log(household_size))
stop_if(nrow(model_data) < 1000L, "Insufficient complete observations for models")
design <- svydesign(ids = ~1, weights = ~weight, data = model_data)
m_entry <- svyglm(
  reported_entry ~ expenditure_quartile + residence + age + gender +
    literacy + log_household_size,
  design = design, family = quasibinomial()
)
m_food <- svyglm(
  food_share ~ reported_entry + expenditure_quartile + residence + age +
    gender + literacy + log_household_size,
  design = design
)
coef_data <- function(model, name, scale) {
  c <- summary(model)$coefficients
  tibble(model = name, term = rownames(c), estimate = unname(c[, 1]),
         standard_error = unname(c[, 2]), statistic = unname(c[, 3]),
         p_value = unname(c[, 4]), scale = scale, observations = nobs(model))
}
write_table(bind_rows(
  coef_data(m_entry, "reported_entry_logit", "log_odds"),
  coef_data(m_food, "food_share_linear", "fraction_of_budget")
), "regression_coefficients.csv")

p <- ggplot(quartile_rates, aes(x = expenditure_quartile,
                               y = 100 * reported_share_weighted,
                               group = residence, colour = residence)) +
  geom_line(linewidth = .8) + geom_point(size = 2.4) +
  labs(x = "Weighted quartile of household expenditure per person",
       y = "Households with a reported loan-related entry (%)",
       colour = "Residence") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "figures", "reported_entries_by_expenditure_quartile.png"),
       p, width = 8, height = 5, units = "in", dpi = 160)

report <- c(
  "# Reported borrowing entries and household expenditure: 1393 HEIS",
  "",
  paste0("The original Access roster contains ", nrow(raw_roster),
         " households. The distributed expenditure workbooks contain ",
         nrow(households), " households."),
  paste0("Part 3 Table 13 contains ", nrow(loans),
         " loan-charge records for ", nrow(loan_household),
         " distinct households; ", nrow(matched),
         " reporting households match the expenditure workbooks."),
  "",
  "The rate estimates measure the presence of a specific loan-related financial-service entry,",
  "**not** comprehensive access to credit, outstanding debt, or loan originations.",
  "Reported amounts are transaction-field values, not verified outstanding principal.",
  "The charge/principal ratio is not interpreted as a contractual interest rate.",
  "",
  "The cross-sectional models describe conditional correlations, not causal borrowing effects.",
  "The nominal survey weights inform point estimates, but the official PSU/stratum design",
  "has not been established; reported standard errors use a weights-only approximation.",
  "",
  "All output tables are aggregate, and the source microdata are not redistributed."
)
writeLines(report, file.path(output_dir, "RESULTS.md"))
writeLines(capture.output(sessionInfo()),
           file.path(output_dir, "diagnostics", "session_info.txt"))
message("Analysis completed. Aggregate results in: ", output_dir)
