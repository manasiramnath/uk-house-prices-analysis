# cleans median price data
## unzip data 
## =====================================================================================================================
median_raw <- read_xls(file.path(dir$raw, "median_price.xls"), sheet = "1a", skip = 5)|>
  clean_names()

## clean data
## =====================================================================================================================
data <- median_raw  |>
# pivot year to column as a variable
pivot_longer(cols = starts_with("year"), names_to = "year", values_to = "median_price")  |>
# filter to only end of financial year
filter(str_detect(year, "mar"))  |>
# create just year column which is the numeric part of the year column
mutate(year = as.numeric(str_extract(year, "\\d+"))) |>
# take last 10 years
filter(year >= 2014) |>
# label NAs
mutate(median_price = ifelse(median_price == ":", NA, median_price)) |>
# convert to numeric
mutate(median_price = as.numeric(median_price),
       year = as.factor(year))

skimr::skim(data)

## =====================================================================================================================
## save to cache
to_cache(data, "median_price", "clean")