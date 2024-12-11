## merging datasets with LSOA granularity
## =====================================================================================================================
# 1. median_price and ctsop_merged
median_price <- from_cache("median_price", "clean")
ctsop_merged <- from_cache("ctsop_merged", "clean")

ctsop_merged <- ctsop_merged |>
rename(lsoa_code = ecode)

data1 <- median_price |>
left_join(ctsop_merged, by = c("lsoa_code", "year"))

# 2. data1 and journey_times
journey_times <- from_cache("journey_times", "clean")
data2 <- data1 |>
left_join(journey_times, by = "lsoa_code")
rm(data1)
## merging datasets with LAD granularity
## =====================================================================================================================
# 3. macro_data and population
macro <- from_cache("macro_data", "clean")
population <- from_cache("population", "clean")
population <- population |>
rename(lad = ladcode21) |>
mutate(year = as.character(year))

macro <- macro |>
filter(old_shp == 1)

data3 <- population |>
left_join(macro, by = c("lad", "year"))

# mapping LSOA to LAD
codes <- from_cache("shp_lookup_old", "clean")
lsoa_lad <- codes |>
select(lsoa11cd, ladcd) |>
distinct()
# keep only matching LSOAs
data3_with_lsoa <- lsoa_lad |>
  left_join(data3, by = c("ladcd" = "lad")) |>
  select(-ladcd, laname21) |>
  mutate(year = as.factor(year))

## merging dataset with MSOA granularity
## ====================================================================================================================
# load hh_earnings data (MSOA level)
hh_earnings <- from_cache("hh_earnings", "clean")

# add lsoa to msoa lookup
lsoa_msoa <- codes |>
select(lsoa11cd, msoa11cd) |>
distinct()

# add lsoa to hh earnings
data4 <- data2 |>
left_join(hh_earnings, by = c("lsoa_code" = "msoa_code", "year" = "year")) |>
mutate(year = as.factor(year))
rm(data2)

# merge data3_with_lsoa and data4
merged_data <- data4 |>
left_join(data3_with_lsoa, by = c("lsoa_code" = "lsoa11cd", "year"))


merged_data_5y <- merged_data |>
filter(year %in% c('2019', '2020', '2021', '2022', '2023'))


to_cache(merged_data, "final_merged_data", "clean")
to_cache(merged_data_5y, "final_merged_data_5y", "clean")


from_cache("final_merged_data", "clean") |> skimr::skim()
