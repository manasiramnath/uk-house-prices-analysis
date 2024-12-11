
# cleaning script for data on the economy by year
# data sources:
# 1. bank of england bank &  mortgage rates
# 2. unemployment rate
# 3. consumer price index


keep <- ls()

## bank of england bank & mortgage rates
## =====================================================================================================================
rates_raw <- read_xlsx(file.path(dir$raw, 'macro', 'rates.xlsx'), skip = 4) |> clean_names()

# cleaning
rates_cleaned <- rates_raw  |>
rename(mortgage_var = mortgages_of_which_variable_rate,
       mortgage_fixed = mortgages_of_which_fixed_rate) |>
# convert date to date type
mutate(date = as.Date(date, format = '%d/%m/%Y')) |>
# filter dates before 31st Mar 2014
filter(date >= '2014-03-31') |>
# extract just year  |>
mutate(year = year(date)) |> 
# get average mortgage rates and bank rate by year
group_by(year) |>
summarise(avg_mortgage_var = mean(mortgage_var, na.rm = TRUE),
          avg_mortgage_fixed = mean(mortgage_fixed, na.rm = TRUE),
          avg_bank_rate = mean(bank_rate, na.rm = TRUE)) |>
          select(year, avg_mortgage_var, avg_mortgage_fixed, avg_bank_rate) |>
          # make year a factor
            mutate(year = as.factor(year))

skimr::skim(rates_cleaned)

## unemployment rate
## =====================================================================================================================
unemployment_raw <- read.csv(file.path(dir$raw, 'macro', 'unemployment_rates.csv')) |> clean_names()

# cleaning
unemployment_cleaned <- unemployment_raw |>
# remove first 5 rows and 7th row
slice(-c(1:5, 7)) |>
# set 6th row as column names 
set_names(unemployment_raw[6, ]) |>
clean_names() |>
# remove original row
slice(-1) |>
# shp indicator: if 19 is in area column then it is old
mutate(old_shp = ifelse(str_detect(area, '19'), 1, 0)) |> 
rename(lad = mnemonic) |>
# drop columns
select(-starts_with('conf'), -starts_with('numerator'), -starts_with('denominator')) |> 
# convert to long format
pivot_longer(cols = -c(area, lad, old_shp),
names_to = 'year', values_to = 'unemployment_rate') |>
# make year variable
mutate(year = as.factor(str_sub(year, -4))) |>
# remove everything before and including ':' in area column
mutate(area = str_remove(area, '.*:')) |>
# remove leading and trailing white spaces
mutate(area = str_trim(area))

skimr::skim(unemployment_cleaned)

## consumer price index
## =====================================================================================================================
# loading CPIH detailed indices annual averages: 2008 to 2023
cpi_raw <- read_xlsx(file.path(dir$raw, 'macro', 'cpi.xlsx'), sheet ='Table 9', skip = 5, col_names = FALSE) |> clean_names()

# cleaning
cpi_cleaned <- cpi_raw |>
slice(2:14)  |>
# set column names
set_names(c('code', 'indicator', 2008:2023)) |>
# convert to long format
pivot_longer(cols = -c(code, indicator),
names_to = 'year', values_to = 'cpi') |>
select(-code) |>
pivot_wider(
    names_from = indicator,
    values_from = cpi
) |>
clean_names() |> 
# replace columns starting with x and number with cpi
rename_with(~str_replace(., '^x\\d+', 'cpi')) |>
# keep only 2014 onwards
filter(year >= 2014)

skimr::skim(cpi_cleaned)

## merging macro data
## =====================================================================================================================
# merge on year
macro_data <- rates_cleaned |>
left_join(unemployment_cleaned, by = c('year')) |>
left_join(cpi_cleaned, by = c('year'))


## =====================================================================================================================
## save to cache
to_cache(macro_data, "macro_data", "clean")

## clean environment
rm(list=setdiff(setdiff(ls(), keep), lsf.str())); gc()
