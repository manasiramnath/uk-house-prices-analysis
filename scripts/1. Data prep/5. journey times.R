## journey times data
## =====================================================================================================================
keep <- ls()

# function to extract the ods file and take relevant columns
extract_journey_times <- function(file_path, skip, col_prefix) {
  # read the data
  raw_data <- read_ods(file_path, sheet = '2019', skip = skip)
  
  # clean and select relevant columns
  cleaned_data <- raw_data |>
    clean_names() |>
    select(lsoa_code, region, la_code, la_name, 
    paste0(col_prefix, "p_tt"), # travel time by public transport
    paste0(col_prefix, "_cyct"), # cycling time
    paste0(col_prefix, "_cart"), # car time
    paste0(col_prefix, "_walkt")) # walking time
  
  return(cleaned_data)
}

## load and clean data
## =====================================================================================================================
# 1. Secondary schools

sec_sch_raw <- read_ods(file.path(dir$raw, "transport", "jts0503.ods"), sheet = "2019", skip = 6)
sec_sch_clean <- sec_sch_raw |>
  clean_names() |>
  select(lsoa_code, region, la_code, la_name, ssp_tt, ss_cyct, ss_cart, ss_walkt)

# 2. GPs 
gp_raw <- read_ods(file.path(dir$raw, "transport", "jts0505.ods"), sheet = "2019", skip = 6)
gp_clean <- gp_raw |>
  clean_names() |>
  select(lsoa_code, region, la_code, la_name, gpp_tt, gp_cyct, gp_cart, gp_walkt)

# 3. Hospitals
hosp_raw <- read_ods(file.path(dir$raw, "transport", "jts0506.ods"), sheet = "2019", skip = 7)
hosp_clean <- hosp_raw |>
  clean_names() |>
  select(lsoa_code, region, la_code, la_name, hosp_p_tt, hosp_cyct, hosp_cart, hosp_walkt)

# 4. Food stores
food_raw <- read_ods(file.path(dir$raw, "transport", "jts0507.ods"), sheet = "2019", skip = 6)
food_clean <- food_raw |>
  clean_names() |>
  select(lsoa_code, region, la_code, la_name, food_p_tt, food_cyct, food_cart, food_walkt)

# 5. Town centres
town_raw <- read_ods(file.path(dir$raw, "transport", "jts0508.ods"), sheet = "2019", skip = 6)
town_clean <- town_raw |>
  clean_names() |>
  select(lsoa_code, region, la_code, la_name, town_p_tt, town_cyct, town_cart, town_walkt)

# merge all clean journey time data
journey_times <- sec_sch_clean |>
  full_join(gp_clean, by = c("lsoa_code", "region", "la_code", "la_name")) |>
  full_join(hosp_clean, by = c("lsoa_code", "region", "la_code", "la_name")) |>
  full_join(food_clean, by = c("lsoa_code", "region", "la_code", "la_name")) |>
  full_join(town_clean, by = c("lsoa_code", "region", "la_code", "la_name"))

# save to cache
to_cache(journey_times, "journey_times", "clean")

## clean environment
rm(list=setdiff(setdiff(ls(), keep), lsf.str())); gc()
