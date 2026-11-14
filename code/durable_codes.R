# Table 13 annual durable purchases: exclude repair and rental services.
# The supplied 1392 questionnaire is assumed to have the same relevant
# questions and item codes as the 1393 survey, as confirmed by the data provider.
selected_durable_purchase <- function(code) {
  x <- trimws(as.character(code))
  keep <- substr(x,1L,4L) %in% c(
    "0511","0512", # Furniture / carpets
    "0531","0532", # Major / small household appliances
    "0711","0712","0713" # Vehicles, motorcycles, bicycles
  ) & x != "071314" # Bicycle repairs
  keep[is.na(keep)] <- FALSE
  keep
}
durable_exclusion_reason <- function(code) {
  x <- trimws(as.character(code))
  ifelse(selected_durable_purchase(x),"Selected durable purchase",
  ifelse(substr(x,1L,4L)=="0513","Furniture repair or cleaning",
  ifelse(substr(x,1L,4L)=="0533","Appliance repair installation or rental",
  ifelse(x=="071314","Bicycle repair","Other or unverified item"))))
}
