# Measurement and econometric sensitivity for HEIS 1393 borrowing reports.
# Exports aggregate results only. This script does not change the baseline.
suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(survey)
})
source("code/durable_codes.R")
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=2L) stop("Usage: Rscript code/measurement_sensitivity.R INPUT_DIR OUTPUT_DIR")
input <- args[[1]]
output <- args[[2]]
dir.create(file.path(output,"tables"),recursive=TRUE,showWarnings=FALSE)
dir.create(file.path(output,"diagnostics"),recursive=TRUE,showWarnings=FALSE)
save <- function(d,path) write.csv(as.data.frame(d),file.path(output,path),
                                    row.names=FALSE,na="")
check <- function(condition,message) {
  if(!isTRUE(condition)) stop(message,call.=FALSE)
}
as_id <- function(x) {
  a <- trimws(as.character(x))
  a <- sub("\\.0+$","",a)
  a[is.na(x) | !nzchar(a)] <- NA_character_
  a
}
number <- function(x) suppressWarnings(as.numeric(as.character(x)))
read_hh <- function(prefix,residence) {
  path <- file.path(input,paste0(prefix,".xls"))
  needed <- c("ADDRESS","weight","GHazineh","VKhorak","C01","A01","A02","A03")
  cols <- names(read_excel(path,n_max=0))
  check(all(needed %in% cols),"Missing workbook variables")
  x <- read_excel(path,col_types=ifelse(cols %in% needed,"text","skip"))
  tibble(Address=as_id(x$ADDRESS),residence=residence,
         province=substr(Address,2,3),weight=number(x$weight),
         total=number(x$GHazineh),food=number(x$VKhorak),
         hhsize=number(x$C01),age=number(x$A02),
         gender=factor(x$A01,levels=c("1","2"),labels=c("Male","Female")),
         literacy=factor(x$A03,levels=c("1","2"),
                         labels=c("Literate","Illiterate")))
}
read_t13 <- function(prefix,residence) {
  x <- read.csv(file.path(input,paste0(prefix,"P3S13.csv")),
                colClasses="character",check.names=FALSE)
  check(all(c("Address","DYCOL01","DYCOL02","DYCOL03",
              "DYCOL04","DYCOL05") %in% names(x)),
        "Missing original Table 13 columns")
  x$residence <- residence
  x$Address <- as_id(x$Address)
  x
}
hh <- bind_rows(read_hh("R93","Rural"),read_hh("U93","Urban"))
raw <- bind_rows(read_t13("R93","Rural"),read_t13("U93","Urban"))
check(nrow(hh)==38275L && !anyNA(hh$Address) &&
      !anyDuplicated(hh[c("residence","Address")]),
      "Unexpected workbook sample or duplicate identifiers")
check(all(is.finite(hh$weight) & hh$weight>0),"Invalid survey weight")
loans <- raw %>%
  filter(DYCOL01 %in% c("126111","126112")) %>%
  transmute(Address,residence,loan_type=ifelse(DYCOL01=="126111",
                                               "Housing","Non-housing"),
            amount=number(DYCOL02),fee=number(DYCOL05),
            financing_source=trimws(coalesce(DYCOL03,"")))
check(nrow(loans)==6053L && all(is.finite(loans$amount) & loans$amount>0) &&
      all(is.finite(loans$fee) & loans$fee>0),
      "Loan table codes or amount fields have changed")

loan_hh <- loans %>%
  group_by(residence,Address) %>%
  summarise(housing=as.integer(any(loan_type=="Housing")),
            nonhousing=as.integer(any(loan_type=="Non-housing")),
            n_loan_entries=n(),.groups="drop")
check(nrow(loan_hh)==5848L,"Unexpected loan-reporting household count")
check(nrow(anti_join(loan_hh,hh,by=c("residence","Address")))==0L,
      "Reporting household lacks a workbook match")
base <- hh %>%
  left_join(loan_hh,by=c("residence","Address"),relationship="one-to-one") %>%
  mutate(housing=coalesce(housing,0L),
         nonhousing=coalesce(nonhousing,0L),
         n_loan_entries=coalesce(n_loan_entries,0L),
         any_loan=as.integer(housing==1L|nonhousing==1L),
         loan_group=case_when(
           housing==0L & nonhousing==0L ~ "No recorded entry",
           housing==1L & nonhousing==0L ~ "Housing only",
           housing==0L & nonhousing==1L ~ "Non-housing only",
           TRUE ~ "Both types"))
check(nrow(base)==38275L && sum(base$any_loan)==5848L,
      "Reported loan status merge failed")

# Exclusive status groups distinguish reporting categories; none of these
# measures is a population-level credit-access or outstanding-debt indicator.
loan_groups <- base %>%
  group_by(residence,loan_group) %>%
  summarise(households=n(),sum_household_weights=sum(weight),.groups="drop") %>%
  group_by(residence) %>%
  mutate(weighted_fraction=sum_household_weights/sum(sum_household_weights),
         unweighted_fraction=households/sum(households)) %>%
  ungroup()
save(loan_groups,"tables/exclusive_loan_reporting_groups.csv")
check(sum(loan_groups$households)==38275L,"Loan group counts do not reconcile")
save(loans %>%
  group_by(residence,loan_type) %>%
  summarise(records=n(),households=n_distinct(Address),
            median_reported_amount=median(amount),
            p25_reported_amount=as.numeric(quantile(amount,.25)),
            p75_reported_amount=as.numeric(quantile(amount,.75)),
            median_reported_fee=median(fee),
            source_nonempty_fraction=mean(nzchar(financing_source)),
            fraction_fee_ratio_near_025=mean(abs(fee/amount-.025)<.00001),
            .groups="drop"),
  "diagnostics/loan_type_field_audit.csv")
save(base %>%
  group_by(loan_group) %>%
  summarise(households=n(),mean_record_count=mean(n_loan_entries),
            households_with_multiple_entries=sum(n_loan_entries>1),
            .groups="drop"),
  "diagnostics/loan_entry_multiplicity.csv")

# Select only questionnaire-documented purchased annual durable categories.
# Total expenditure less these gross purchases is an accounting sensitivity,
# not a validated measure of disposable income or nondurable consumption.
broad_items <- raw %>%
  filter(substr(DYCOL01,1,3) %in% c("051","053","071"),
         DYCOL04=="1") %>%
  transmute(Address,residence,code=DYCOL01,prefix=substr(DYCOL01,1,3),
            amount=number(DYCOL05),
            selected=selected_durable_purchase(DYCOL01),
            classification=durable_exclusion_reason(DYCOL01))
check(!anyNA(broad_items$Address) &&
      all(is.finite(broad_items$amount) & broad_items$amount>0),
      "Invalid Table 13 durable-category records")
save(broad_items %>%
  group_by(residence,prefix,classification,selected) %>%
  summarise(records=n(),distinct_households=n_distinct(Address),
            nominal_total_rials=sum(amount),.groups="drop"),
  "diagnostics/selected_durable_item_code_audit.csv")
durable <- broad_items %>%
  filter(selected) %>%
  select(Address,residence,prefix,amount)
check(!anyNA(durable$Address) &&
      all(is.finite(durable$amount)&durable$amount>0),
      "Invalid annual purchased-durable observations")
durable_sum <- durable %>%
  group_by(residence,Address) %>%
  summarise(selected_durable_gross=sum(amount),.groups="drop")
sample <- base %>%
  left_join(durable_sum,by=c("residence","Address"),relationship="one-to-one") %>%
  mutate(
    selected_durable_gross=coalesce(selected_durable_gross,0),
    expenditure_less_selected=total-selected_durable_gross,
    expenditure_per_person=total/hhsize,
    expenditure_less_selected_per_person=expenditure_less_selected/hhsize,
    food_per_person=food/hhsize,
    valid_controls=is.finite(total) & total>0 & is.finite(hhsize) &
      hhsize>0 & is.finite(age) & age>=10 & age<=110 &
      !is.na(gender) & !is.na(literacy) &
      is.finite(weight) & weight>0,
    valid_leaveout=valid_controls & is.finite(expenditure_less_selected) &
      expenditure_less_selected>0
  )
check(nrow(sample)==38275L,"Durable-spending merge changed sample size")
save(sample %>% group_by(residence) %>%
       summarise(
         households=n(),
         valid_baseline_controls=sum(valid_controls),
         annual_durable_positive=sum(selected_durable_gross>0),
         nonfinite_expenditure=sum(!is.finite(total)),
         expenditure_less_selected_nonpositive=
           sum(is.finite(expenditure_less_selected) &
                 expenditure_less_selected<=0),
         leaveout_eligible=sum(valid_leaveout),
         weighted_fraction_leaveout_eligible=
           sum(weight[valid_leaveout])/sum(weight),
         .groups="drop"),
     "diagnostics/expenditure_leaveout_reconciliation.csv")
check(sum(sample$valid_leaveout)>=30000L,
      "Too few eligible observations for a comparable sensitivity analysis")

# All expenditure quartile controls for this sensitivity use exactly the
# same leaveout-eligible sample, avoiding sample-composition differences.
d <- sample %>% filter(valid_leaveout) %>%
  mutate(residence=factor(residence,levels=c("Rural","Urban")),
         log_household_size=log(hhsize))
weighted_quartile <- function(x,w) {
  check(all(is.finite(x) & is.finite(w) & w>0 & x>0),
        "Invalid inputs to weighted quartiles")
  o <- order(x)
  csum <- cumsum(w[o])/sum(w)
  boundaries <- vapply(c(.25,.5,.75),
                       function(p)x[o][which(csum>=p)[[1]]],numeric(1))
  check(length(unique(boundaries))==3L,"Tied quartile boundaries")
  list(boundaries=boundaries,
       factor=cut(x,breaks=c(-Inf,boundaries,Inf),
                  labels=paste0("Q",1:4),include.lowest=TRUE))
}
full_q <- weighted_quartile(d$expenditure_per_person,d$weight)
less_q <- weighted_quartile(d$expenditure_less_selected_per_person,d$weight)
d$q_full <- full_q$factor
d$q_leaveout <- less_q$factor
save(tibble(
  measure=rep(c("Total expenditure per person",
                "Total less selected durable purchases per person"),each=3),
  quartile_boundary=rep(c("Q1/Q2","Q2/Q3","Q3/Q4"),2),
  nominal_rials=c(full_q$boundaries,less_q$boundaries)),
  "diagnostics/alternative_expenditure_quartiles.csv")
save(d %>%
  count(q_full,q_leaveout,name="households") %>%
  arrange(q_full,q_leaveout),
  "diagnostics/alternative_rank_crosswalk.csv")
check(length(unique(d$province))==31L,
      "Unexpected number of provinces")

# Purchase outcome definitions use the same 12-month Table 13 reference
# period as the loan-related fees. The selected purchases need not have
# been financed by the recorded loans.
groups <- c("Furniture and furnishings","Household appliances",
            "Personal transport equipment","Any selected durable group")
prefix <- c("051","053","071",NA_character_)
purchase_keys <- lapply(seq_along(groups),function(i){
  keys <- durable
  if(!is.na(prefix[i])) keys <- keys[keys$prefix==prefix[i],]
  distinct(keys,residence,Address)
})
names(purchase_keys) <- groups

# Weighted logistic associations. Report province-clustered uncertainty for
# the leaveout-adjusted 'any loan' specification; this does not recover the
# official PSU/strata information. Models are cross-sectional associations.
fit_one <- function(data,outcome_name,specification,loan_selector,quartile) {
  ss <- data
  if(loan_selector=="nonhousing_only_vs_none") {
    ss <- ss %>% filter(loan_group %in%
                         c("No recorded entry","Non-housing only"))
    ss$loan_flag <- as.integer(ss$loan_group=="Non-housing only")
  } else if(loan_selector=="housing_only_vs_none") {
    ss <- ss %>% filter(loan_group %in%
                         c("No recorded entry","Housing only"))
    ss$loan_flag <- as.integer(ss$loan_group=="Housing only")
  } else {
    ss$loan_flag <- ss$any_loan
  }
  ss$q <- if(quartile=="full") ss$q_full else ss$q_leaveout
  check(nrow(ss)>1000L && sum(ss$loan_flag)>150L &&
        sum(ss$purchase)>100L && length(unique(ss$purchase))==2L,
        paste("Insufficient outcome support",outcome_name,specification))
  f <- purchase ~ loan_flag + q + residence + age + gender +
    literacy + log_household_size
  design <- svydesign(ids=~1,weights=~weight,data=ss)
  model <- svyglm(f,design=design,family=quasibinomial())
  co <- summary(model)$coefficients["loan_flag",]
  check(is.finite(co[[2]]) && co[[2]]>0,"Invalid model uncertainty")
  # Standardized predicted probability difference (percentage points), with
  # observed covariates fixed. Not a causal average treatment effect.
  ss1 <- ss
  ss0 <- ss
  ss1$loan_flag <- 1L
  ss0$loan_flag <- 0L
  p1 <- as.numeric(predict(model,newdata=ss1,type="response"))
  p0 <- as.numeric(predict(model,newdata=ss0,type="response"))
  check(all(is.finite(p1) & is.finite(p0)),"Non-finite predicted probability")
  ame_pp <- 100*weighted.mean(p1-p0,ss$weight)
  clustered_se <- NA_real_
  clustered_p <- NA_real_
  clustered_low <- NA_real_
  clustered_high <- NA_real_
  clustered_df <- NA_real_
  if(loan_selector=="any" && quartile=="leaveout") {
    pdesign <- svydesign(ids=~province,weights=~weight,data=ss)
    pmodel <- svyglm(f,design=pdesign,family=quasibinomial())
    pc <- summary(pmodel)$coefficients["loan_flag",]
    clustered_df <- df.residual(pmodel)
    check(is.finite(clustered_df) & clustered_df>0 &
          is.finite(pc[[2]]) & pc[[2]]>0,"Invalid clustered inference")
    critical <- qt(.975,df=clustered_df)
    clustered_se <- unname(pc[[2]])
    clustered_p <- unname(pc[[4]])
    clustered_low <- exp(unname(pc[[1]]-critical*pc[[2]]))
    clustered_high <- exp(unname(pc[[1]]+critical*pc[[2]]))
  }
  tibble(
    outcome=outcome_name,specification=specification,
    loan_comparison=loan_selector,quartile_measure=quartile,
    observations=nrow(ss),reporting_households=sum(ss$loan_flag),
    purchase_households=sum(ss$purchase),
    odds_ratio=exp(unname(co[[1]])),
    standard_error=unname(co[[2]]),
    ci95_lower=exp(unname(co[[1]]-1.96*co[[2]])),
    ci95_upper=exp(unname(co[[1]]+1.96*co[[2]])),
    p_value=unname(co[[4]]),
    standardized_probability_difference_pp=ame_pp,
    province_cluster_se=clustered_se,
    province_cluster_df=clustered_df,
    province_cluster_ci95_lower=clustered_low,
    province_cluster_ci95_upper=clustered_high,
    province_cluster_p_value=clustered_p)
}
results <- bind_rows(lapply(seq_along(groups),function(i){
  this <- d %>%
    left_join(purchase_keys[[i]] %>% mutate(purchase=1L),
              by=c("residence","Address"),relationship="one-to-one") %>%
    mutate(purchase=coalesce(purchase,0L))
  bind_rows(
    fit_one(this,groups[i],"Full-expenditure control; comparable sample",
            "any","full"),
    fit_one(this,groups[i],"Leave-out expenditure control",
            "any","leaveout"),
    fit_one(this,groups[i],"Non-housing-only reports vs no entry",
            "nonhousing_only_vs_none","leaveout"),
    fit_one(this,groups[i],"Housing-only reports vs no entry",
            "housing_only_vs_none","leaveout")
  )
}))
check(nrow(results)==16L,"Unexpected sensitivity model count")
save(results,"tables/borrowing_measurement_and_control_sensitivity.csv")

# A common four-outcome family for the primary leaveout, any-entry models.
primary <- results %>%
  filter(loan_comparison=="any" & quartile_measure=="leaveout") %>%
  mutate(province_cluster_BH_p=p.adjust(province_cluster_p_value,method="BH"))
check(nrow(primary)==4L &&
      all(is.finite(primary$province_cluster_BH_p)),
      "Invalid corrected clustered p-values")
save(primary,"tables/leaveout_primary_robustness.csv")
save(tibble(
  baseline_comparable_n=nrow(d),
  excluded_from_original_sample=nrow(base)-nrow(d),
  only_loan_reporting_records=nrow(loans),
  reporting_households=nrow(loan_hh),
  selected_durable_purchase_records=nrow(durable),
  interpretation=paste(
    "The leave-out measure is nominal annual total household expenditure",
    "minus documented purchases in 051/053/071 after excluding repair items.",
    "It is not validated income, wealth or exact nondurable expenditure.")
), "diagnostics/measurement_sensitivity_summary.csv")

writeLines(c(
  "Measurement and econometric sensitivity:",
  "Loan types: housing only / non-housing only / both / no recorded entry.",
  "Four purchase outcomes, four adjusted specifications per outcome.",
  "Expenditure covariate alternatives use an identical analytical sample.",
  "Leave-out spending excludes repair and rental codes from the durable subtraction;",
  "the source accounting identity is not independently validated.",
  "Province-clustered t-based confidence intervals use fitted residual df;",
  "neither weights-only nor province clustering reconstructs official HEIS design.",
  "Standardized probability differences are descriptive, not causal.",
  paste("Comparable sample:",nrow(d)),
  paste("Excluded due to leaveout or covariate criteria:",nrow(base)-nrow(d))
),file.path(output,"diagnostics","measurement_sensitivity_notes.txt"))
message("Loan reporting and leave-out expenditure sensitivities completed.")
