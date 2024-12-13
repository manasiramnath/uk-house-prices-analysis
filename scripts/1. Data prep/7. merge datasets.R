## merging datasets with LSOA granularity
## =====================================================================================================================
# median_price and ctsop_merged
median_price <- from_cache("median_price", "clean")
ctsop_merged <- from_cache("ctsop_merged", "clean")

ctsop_merged <- ctsop_merged |>
  rename(lsoa_code = ecode) |>
  mutate(lsoa_code = str_trim(lsoa_code)) |>  
  mutate(lsoa_code = toupper(lsoa_code))  

median_price <- median_price |>
  mutate(lsoa_code = str_trim(lsoa_code)) |>  
  mutate(lsoa_code = toupper(lsoa_code))
common_columns <- intersect(names(median_price), names(ctsop_merged))

ctsop_with_prices <- median_price |>
  inner_join(ctsop_merged, by = c("lsoa_code", "year"))

# ctsop_with_prices and journey_times
journey_times <- from_cache("journey_times", "clean")
ctsop_with_prices_journey <- ctsop_with_prices |>
  inner_join(journey_times, by = "lsoa_code") |>
  select(-c(la_name,la_code))

## merging datasets with LAD granularity
## =====================================================================================================================
# macro_data and population
macro <- from_cache("macro_data", "clean")
population <- from_cache("population", "clean")
population <- population |>
rename(lad = ladcode21) |>
mutate(year = as.character(year))

macro <- macro |>
filter(old_shp == 1) |>
select(-old_shp)

macro_pop <- population |>
left_join(macro, by = c("lad", "year"))

# mapping LSOA to LAD
codes <- from_cache("shp_lookup_old", "clean")
lsoa_lad <- codes |>
select(lsoa11cd, ladcd) |>
distinct()
# keep only matching LSOAs
macro_pop_lsoa <- lsoa_lad |>
  inner_join(macro_pop, by = c("ladcd" = "lad")) |>
  select(-ladcd, laname21) |>
  mutate(year = as.factor(year)) |>
  select(-c(area, laname21)) |>
  rename(lsoa_code = lsoa11cd)

## merging dataset with MSOA granularity
## ====================================================================================================================
# load hh_earnings data (MSOA level)
hh_earnings <- from_cache("hh_earnings", "clean")

# add lsoa to msoa lookup
lsoa_msoa <- codes |>
select(lsoa11cd, msoa11cd) |>
distinct()

# add lsoa to hh earnings
hh_earnings_with_lsoa <- hh_earnings |>
  left_join(lsoa_msoa, by = c("msoa_code" = "msoa11cd")) |>
  mutate(year = as.factor(year))  |>
  select(-c(msoa_code, msoa_name)) |>
  rename(lsoa_code = lsoa11cd)
# convert year to a factor in all datasets
ctsop_with_prices_journey <- ctsop_with_prices_journey |>
  mutate(year = as.factor(year))

final_merged_data <- ctsop_with_prices_journey |>
  left_join(hh_earnings_with_lsoa, by = c("lsoa_code", "year")) |>
  left_join(macro_pop_lsoa, by = c("lsoa_code", "year"))

# save to cache
to_cache(final_merged_data, "final_merged_data", "clean")
