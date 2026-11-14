# Supplemental expenditure modules and financing-source classifications.
# Input tables are extracted from the unchanged, checksum-pinned HEIS archive.
# Only aggregate tabulations and model summaries leave the temporary workspace.
suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(ggplot2)
  library(survey)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript code/extended_analysis.R INPUT_DIR OUTPUT_DIR")
input_dir <- args[[1]]
output_dir <- args[[2]]
dir.create(file.path(output_dir, "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "diagnostics"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "figures"), recursive = TRUE, showWarnings = FALSE)
save_csv <- function(x, path) {
  write.csv(as.data.frame(x), file.path(output_dir, path),
            row.names = FALSE, na = "")
}
household_id <- function(x) {
  out <- trimws(as.character(x))
  out <- sub("\\.0+$", "", out)
  out[is.na(x) | !nzchar(out)] <- NA_character_
  out
}
numeric_value <- function(x) suppressWarnings(as.numeric(as.character(x)))
check <- function(condition, message) if (!isTRUE(condition)) stop(message, call. = FALSE)

read_household <- function(prefix, residence) {
  path <- file.path(input_dir, paste0(prefix, ".xls"))
  needed <- c("ADDRESS", "weight", "GHazineh", "C01", "A01", "A02", "A03")
  header <- names(read_excel(path, n_max = 0))
  check(all(needed %in% header), paste("Missing fields in", path))
  d <- read_excel(path, col_types = ifelse(header %in% needed, "text", "skip"))
  tibble(
    Address = household_id(d$ADDRESS), residence = residence,
    province = substr(Address, 2, 3),
    weight = numeric_value(d$weight),
    annual_expenditure = numeric_value(d$GHazineh),
    household_size = numeric_value(d$C01),
    gender = factor(d$A01, levels = c("1","2"), labels=c("Male","Female")),
    literacy = factor(d$A03, levels=c("1","2"),
                      labels=c("Literate","Illiterate")),
    age = numeric_value(d$A02)
  )
}
households <- bind_rows(read_household("R93", "Rural"),
                        read_household("U93", "Urban"))
check(nrow(households) == 38275L, "Unexpected household workbook size")
check(!anyNA(households$Address) &&
      !anyDuplicated(households[c("residence","Address")]),
      "Household identifiers are invalid or duplicated")
check(all(is.finite(households$weight) & households$weight > 0),
      "Non-positive survey weight in household workbook")

read_loans <- function(prefix, residence) {
  d <- read.csv(file.path(input_dir, paste0(prefix, "P3S13.csv")),
                colClasses = "character", check.names = FALSE)
  check(all(c("Address","DYCOL01","DYCOL03") %in% names(d)),
        "Loan table required columns absent")
  d %>% filter(DYCOL01 %in% c("126111","126112")) %>%
    transmute(Address=household_id(Address), residence=residence,
              purpose=ifelse(DYCOL01=="126111","Housing","Non-housing"),
              source=trimws(coalesce(DYCOL03,"")))
}
loans <- bind_rows(read_loans("R93","Rural"),read_loans("U93","Urban"))
check(nrow(loans)==6053L,"Loan source row total changed")
check(nrow(distinct(loans,residence,Address))==5848L,
      "Household loan-entry count changed")

# Source is a free-text answer (where loan obtained). Avoid describing this
# exploratory classification as an official lender taxonomy.
normalize_persian <- function(x) {
  x <- gsub("\u064a", "\u06cc", x, fixed=TRUE)
  x <- gsub("\u0643", "\u06a9", x, fixed=TRUE)
  x <- gsub("\u200c", " ", x, fixed=TRUE)
  x <- gsub("[[:space:]]+", " ", trimws(x))
  x
}
source <- normalize_persian(loans$source)
funds <- grepl("قرض|صندوق|موسسه|مؤسسه|کمیته|بنیاد|محل کار|بازنشستگی",source)
explicit_bank <- grepl("بانک",source)
bank_short <- grepl(
  "ملی|کشاورزی|صادرات|ملت|تجارت|رفاه|سپه|انصار|مسکن|قوامین|مهر اقتصاد|رسالت|پست بانک|اقتصاد نوین|سینا|توسعه تعاون|کوثر|پاسارگاد|سامان|پارسیان|شهر|آینده|گردشگری",
  source
)
loans$source_group <- case_when(
  !nzchar(source) ~ "Missing",
  explicit_bank ~ "Explicit bank",
  funds ~ "Fund / other institution",
  bank_short ~ "Recognizable bank shorthand",
  TRUE ~ "Unclassified / ambiguous"
)
save_csv(loans %>% count(residence,purpose,source_group,name="records") %>%
           group_by(residence,purpose) %>%
           mutate(share_within_purpose=records/sum(records)) %>%
           ungroup(),
         "tables/financing_source_groups.csv")
save_csv(loans %>% group_by(source_group) %>%
           summarise(records=n(),unique_source_strings=n_distinct(source),
                     .groups="drop"),
         "diagnostics/source_text_classification_coverage.csv")


# The questionnaire's Part 3 Table 13 measures annual purchases/transfers.
# Distinguish selected durable-goods groups by item-code prefix. These are
# nominal PURCHASE amounts (DYCOL05), not net of used-item resale (DYCOL06).
# Codes 051: furniture/furnishings; 053: household appliances;
# 071: personal transport equipment. The last is not transport services.
read_annual_durable <- function(prefix, residence) {
  d <- read.csv(file.path(input_dir,paste0(prefix,"P3S13.csv")),
                colClasses="character",check.names=FALSE)
  needed <- c("Address","DYCOL01","DYCOL04","DYCOL05")
  check(all(needed %in% names(d)),"Missing Table 13 durable-item columns")
  d <- d %>%
    filter(substr(DYCOL01,1,3) %in% c("051","053","071"),
           DYCOL04=="1") %>%
    transmute(Address=household_id(Address),residence=residence,
              purchase_group=case_when(
                substr(DYCOL01,1,3)=="051" ~ "Furniture and furnishings",
                substr(DYCOL01,1,3)=="053" ~ "Household appliances",
                TRUE ~ "Personal transport equipment"),
              amount_rials=numeric_value(DYCOL05))
  check(!anyNA(d$Address) && all(is.finite(d$amount_rials) &
                                d$amount_rials>0),
        paste("Invalid annual purchase records:",prefix))
  d
}
durable_rows <- bind_rows(read_annual_durable("R93","Rural"),
                         read_annual_durable("U93","Urban"))
durable_aggregate <- durable_rows %>%
  group_by(residence,Address,purchase_group) %>%
  summarise(annual_purchase_rials=sum(amount_rials),.groups="drop")
check(!anyDuplicated(durable_aggregate[c("residence","Address","purchase_group")]),
      "Duplicate aggregated annual durable purchases")
save_csv(durable_rows %>%
  group_by(purchase_group,residence) %>%
  summarise(purchased_item_records=n(),
            households_with_purchases=n_distinct(Address),.groups="drop"),
  "diagnostics/annual_durable_purchase_source_counts.csv")

# Questionnaire Part 3 sections 03, 05, 07, 08, 09 and 11 all use
# previous-month recall. Each has item code DYCOL01, acquisition method
# DYCOL02 and nominal expenditure DYCOL03 (purchased items: method 1).
# They do NOT together provide the full household consumption basket.
categories <- tibble(
  section=c("03","05","07","08","09","11"),
  sector=c("Clothing and footwear",
           "Furnishings and household equipment",
           "Transport","Communications",
           "Recreation and culture","Prepared food and accommodation")
)
read_sector <- function(prefix, residence, section, sector) {
  path <- file.path(input_dir, paste0(prefix,"P3S",section,".csv"))
  d <- read.csv(path,colClasses="character",check.names=FALSE)
  check(all(c("Address","DYCOL01","DYCOL02","DYCOL03") %in% names(d)),
        paste("Missing expected columns in",basename(path)))
  check(nrow(d)>100L,paste("Empty expenditure module:",basename(path)))
  addresses <- household_id(d$Address)
  check(!anyNA(addresses),paste("Missing Address in",basename(path)))
  check(all(d$DYCOL02 %in% as.character(1:8)),
        paste("Unknown acquisition method in", basename(path)))
  purchased <- d$DYCOL02=="1"
  spend <- numeric_value(d$DYCOL03[purchased])
  check(all(is.finite(spend) & spend >= 0),
        paste("Invalid nominal purchase amount in",basename(path)))
  x <- tibble(Address=addresses[purchased],amount=spend) %>%
    group_by(Address) %>%
    summarise(monthly_purchases_rials=sum(amount),.groups="drop")
  x$sector <- sector
  x$residence <- residence
  x
}
purchases <- bind_rows(lapply(seq_len(nrow(categories)), function(i) {
  bind_rows(read_sector("R93","Rural",categories$section[i],categories$sector[i]),
            read_sector("U93","Urban",categories$section[i],categories$sector[i]))
}))
check(!anyDuplicated(purchases[c("Address","residence","sector")]),
      "Spending categories did not aggregate to unique households")
not_in_workbooks <- anti_join(purchases,households,by=c("Address","residence"))
# These records may belong to Access-roster households excluded from
# the distributed workbook sample. Report counts and do not merge them.
save_csv(purchases %>% group_by(sector) %>%
           summarise(purchased_record_households=n(),
                     households_absent_from_workbooks=
                       sum(!paste(residence,Address) %in%
                             paste(households$residence,households$Address)),
                     .groups="drop"),
         "diagnostics/sector_source_coverage.csv")

reported <- loans %>% distinct(residence,Address) %>%
  mutate(reported_entry=1L)
base <- households %>%
  left_join(reported,by=c("residence","Address"),relationship="one-to-one") %>%
  mutate(reported_entry=coalesce(reported_entry,0L))

durable_categories <- c("Furniture and furnishings","Household appliances",
                        "Personal transport equipment")
durable_data <- bind_rows(lapply(durable_categories,function(cat){
  x <- durable_aggregate %>%
    filter(purchase_group==cat) %>%
    select(residence,Address,annual_purchase_rials)
  base %>%
    left_join(x,by=c("residence","Address"),relationship="one-to-one") %>%
    mutate(annual_purchase_rials=coalesce(annual_purchase_rials,0),
           purchase_incidence=as.integer(annual_purchase_rials>0),
           purchase_group=cat)
}))
check(nrow(durable_data)==38275L*length(durable_categories),
      "Annual purchase module produced unexpected household rows")
durable_summary <- durable_data %>%
  group_by(purchase_group,residence,reported_entry) %>%
  summarise(households=n(),
            positive_purchase_households=sum(purchase_incidence),
            weighted_purchase_incidence=weighted.mean(purchase_incidence,weight),
            weighted_mean_annual_purchase_rials=
              weighted.mean(annual_purchase_rials,weight),
            .groups="drop")
save_csv(durable_summary,"tables/annual_durable_purchase_by_reporting_status.csv")
sectors <- bind_rows(lapply(categories$sector,function(k){
  x <- purchases %>% filter(sector==k) %>%
    select(Address,residence,monthly_purchases_rials)
  merged <- base %>%
    left_join(x,by=c("residence","Address"),relationship="one-to-one") %>%
    mutate(monthly_purchases_rials=coalesce(monthly_purchases_rials,0),
           purchase_incidence=as.integer(monthly_purchases_rials>0),
           sector=k)
  check(nrow(merged)==38275L,"Sector merge lost or duplicated household keys")
  merged
}))
summary <- sectors %>%
  group_by(sector,residence,reported_entry) %>%
  summarise(
    households=n(),
    weighted_purchase_incidence=weighted.mean(purchase_incidence,weight),
    weighted_mean_monthly_purchase_rials=weighted.mean(monthly_purchases_rials,weight),
    .groups="drop")
save_csv(summary,"tables/monthly_sector_spending_by_reporting_status.csv")
without <- summary %>%
  filter(reported_entry == 0L) %>%
  transmute(
    sector,residence,
    weighted_purchase_incidence_entry0=weighted_purchase_incidence,
    weighted_mean_monthly_purchase_rials_entry0=weighted_mean_monthly_purchase_rials)
with <- summary %>%
  filter(reported_entry == 1L) %>%
  transmute(
    sector,residence,
    weighted_purchase_incidence_entry1=weighted_purchase_incidence,
    weighted_mean_monthly_purchase_rials_entry1=weighted_mean_monthly_purchase_rials)
diff <- inner_join(without,with,by=c("sector","residence"),
                   relationship="one-to-one") %>%
  mutate(
    purchase_incidence_difference_pp=100*(weighted_purchase_incidence_entry1-
                                           weighted_purchase_incidence_entry0),
    mean_monthly_purchase_difference_rials=
      weighted_mean_monthly_purchase_rials_entry1-
      weighted_mean_monthly_purchase_rials_entry0)
save_csv(diff,"tables/monthly_sector_spending_differences.csv")

# Six exploratory weighted reporting-status associations, conditional on
# observed household characteristics and expenditure rank. They are NOT
# causal and BH correction applies across these six sector outcomes only.
model_frame <- base %>%
  mutate(residence=factor(residence,levels=c("Rural","Urban")),
         expenditure_per_person=annual_expenditure/household_size) %>%
  filter(is.finite(expenditure_per_person) & expenditure_per_person>0,
         is.finite(age) & age>=10 & age<=110,
         !is.na(gender),!is.na(literacy),household_size>0)
ordered <- order(model_frame$expenditure_per_person)
cumulative_w <- cumsum(model_frame$weight[ordered])/sum(model_frame$weight)
quantiles <- vapply(c(.25,.5,.75),function(p){
  model_frame$expenditure_per_person[ordered][which(cumulative_w>=p)[1]]
},numeric(1))
check(length(unique(quantiles))==3L, "Nonunique weighted quartile boundaries")
model_frame$expenditure_quartile <- cut(
  model_frame$expenditure_per_person,breaks=c(-Inf,quantiles,Inf),
  labels=paste0("Q",1:4),include.lowest=TRUE)
model_frame$log_household_size <- log(model_frame$household_size)
coef <- bind_rows(lapply(categories$sector,function(k){
  purchases_here <- purchases %>%
    filter(sector==k & monthly_purchases_rials>0) %>%
    distinct(residence,Address) %>% mutate(purchase_incidence=1L)
  d <- model_frame %>%
    mutate(residence=as.character(residence)) %>%
    left_join(purchases_here,by=c("residence","Address"),relationship="one-to-one") %>%
    mutate(purchase_incidence=coalesce(purchase_incidence,0L),
           residence=factor(residence,levels=c("Rural","Urban")))
  design <- svydesign(ids=~1, weights=~weight, data=d)
  model <- svyglm(
    purchase_incidence ~ reported_entry + expenditure_quartile + residence +
      age + gender + literacy + log_household_size,
    design=design,family=quasibinomial())
  cc <- summary(model)$coefficients
  term <- cc["reported_entry",]
  tibble(sector=k,n=nrow(d),reporting_households=sum(d$reported_entry),
         purchase_incidence_n=sum(d$purchase_incidence),
         adjusted_log_odds=unname(term[1]),
         standard_error=unname(term[2]),
         odds_ratio=exp(unname(term[1])),
         ci95_lower=exp(unname(term[1]-1.96*term[2])),
         ci95_upper=exp(unname(term[1]+1.96*term[2])),
         p_value=unname(term[4]))
}))
coef$fdr_bh_p_value <- p.adjust(coef$p_value,method="BH")
save_csv(coef,"tables/sector_purchase_associations.csv")

# Three pre-specified annual durable groups, plus an indicator for any
# of the groups, use the same 12-month horizon as Table 13 loan entries.
annual_model_categories <- c(durable_categories,"Any selected durable group")
annual_models <- bind_rows(lapply(annual_model_categories,function(cat){
  positive <- durable_aggregate %>%
    filter(cat=="Any selected durable group" | purchase_group==cat) %>%
    distinct(residence,Address) %>%
    mutate(purchase_incidence=1L)
  d <- model_frame %>%
    mutate(residence=as.character(residence)) %>%
    left_join(positive,by=c("residence","Address"),relationship="one-to-one") %>%
    mutate(purchase_incidence=coalesce(purchase_incidence,0L),
           residence=factor(residence,levels=c("Rural","Urban")))
  form <- purchase_incidence ~ reported_entry + expenditure_quartile +
    residence + age + gender + literacy + log_household_size
  design <- svydesign(ids=~1,weights=~weight,data=d)
  model <- svyglm(form,design=design,family=quasibinomial())
  fit <- summary(model)$coefficients["reported_entry",]

  # Treat the 31 provinces as clusters in a separate sensitivity exercise.
  # This is NOT a substitute for unavailable official HEIS PSUs and strata.
  province_clusters <- length(unique(d$province))
  check(province_clusters == 31L,
        "Unexpected province count for cluster-variance sensitivity")
  clustered_design <- svydesign(ids=~province,weights=~weight,data=d)
  clustered_model <- svyglm(form,design=clustered_design,family=quasibinomial())
  clustered_fit <- summary(clustered_model)$coefficients["reported_entry",]
  residual_df <- stats::df.residual(clustered_model)
  check(is.finite(residual_df) && residual_df > 0,
        "Invalid province-cluster regression degrees of freedom")
  tcrit <- qt(.975,df=residual_df)
  check(is.finite(tcrit) & is.finite(clustered_fit[2]) &
        clustered_fit[2] > 0,"Invalid province cluster sensitivity estimate")
  tibble(
    purchase_group=cat,observations=nrow(d),
    reporting_households=sum(d$reported_entry),
    households_with_purchase=sum(d$purchase_incidence),
    adjusted_log_odds=unname(fit[1]),
    standard_error=unname(fit[2]),
    odds_ratio=exp(unname(fit[1])),
    ci95_lower=exp(unname(fit[1]-1.96*fit[2])),
    ci95_upper=exp(unname(fit[1]+1.96*fit[2])),
    p_value=unname(fit[4]),
    province_clusters=province_clusters,
    province_cluster_residual_df=residual_df,
    province_cluster_standard_error=unname(clustered_fit[2]),
    province_cluster_ci95_lower=exp(unname(clustered_fit[1]-tcrit*clustered_fit[2])),
    province_cluster_ci95_upper=exp(unname(clustered_fit[1]+tcrit*clustered_fit[2])),
    province_cluster_p_value=unname(clustered_fit[4]))
}))
annual_models$fdr_bh_p_value <- p.adjust(annual_models$p_value,method="BH")
annual_models$province_cluster_fdr_bh_p <- p.adjust(
  annual_models$province_cluster_p_value,method="BH")
save_csv(annual_models,"tables/annual_durable_purchase_associations.csv")

annual_fig <- ggplot(durable_summary,
   aes(x=purchase_group,y=100*weighted_purchase_incidence,
       fill=factor(reported_entry,levels=c(0,1),
                   labels=c("No loan-related entry","Loan-related entry")))) +
  geom_col(position=position_dodge(width=.75),width=.65) +
  facet_wrap(~residence,ncol=2) + coord_flip() +
  labs(x=NULL,y="Positive purchases in previous 12 months (%)",
       fill="Table 13 status") +
  theme_minimal(base_size=11) +
  theme(legend.position="bottom")
ggsave(file.path(output_dir,"figures","annual_durable_purchase_participation.png"),
       annual_fig,width=10.5,height=5.1,units="in",dpi=160)

# Visualize observed purchase participation. The monthly module figures
# are not annual expenditure shares or consumption responses to credit.
fig <- ggplot(summary,
  aes(x=reorder(sector,weighted_purchase_incidence),y=100*weighted_purchase_incidence,
      fill=factor(reported_entry,labels=c("No entry","Loan-related entry")))) +
  geom_col(position=position_dodge(width=.75),width=.67) +
  coord_flip() +
  facet_wrap(~residence,ncol=2) +
  labs(x=NULL,y="Households with positive purchased spending last month (%)",
       fill="Table 13 status") +
  theme_minimal(base_size=11) +
  theme(legend.position="bottom")
ggsave(file.path(output_dir,"figures","monthly_sector_purchase_participation.png"),
       fig,width=11,height=5.8,units="in",dpi=160)

writeLines(c(
  "Supplementary financial-source and sector-spending analysis",
  "Six monthly expenditure modules: 03, 05, 07, 08, 09, 11.",
  "Selected annual durable purchase groups from Table 13: 051, 053, 071.",
  "Table 13 purchased amounts are gross purchases over the preceding 12 months.",
  "Amounts are purchases in the month before interview. These are NOT annualized.",
  "Not all household consumption sectors are covered by this analysis.",
  "Loan presence means Table 13 fee-linked entry, not universal credit access.",
  "Free-text lender groupings are exploratory and are not official classifications.",
  "The six association models are observational, with independent-household",
  "weights-only variance approximations and BH-adjusted exploratory p-values.",
  paste("Household workbook rows:",nrow(households)),
  paste("Module-by-household matched observations:",nrow(sectors))
),file.path(output_dir,"diagnostics","extended_analysis_notes.txt"))
message("Extended six-sector analysis complete.")
