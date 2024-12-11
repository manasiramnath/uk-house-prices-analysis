## household earnings
## =====================================================================================================================
# data from 2016, 2018, 2020 
# filepath
path <- file.path(dir$raw, "hh_earnings")
files <- list.files(path)

# read in data
hh_earnings_list <- list()
for (f in files) {
    data <- read_excel(file.path(path, f), sheet = 'Net income before housing costs', skip = 4)  |>
        clean_names() |>
        mutate(year = as.numeric(str_extract(f, "\\d{4}")))
    hh_earnings_list[[f]] <- data
}

# bind rows
hh_earnings <- bind_rows(hh_earnings_list)
hh_earnings <- hh_earnings  |>
    select(msoa_code, msoa_name, year, net_annual_income_before_housing_costs)

skimr::skim(hh_earnings)
# save to cache
to_cache(hh_earnings, "hh_earnings", "clean")

## clean environment
rm(list=setdiff(setdiff(ls(), keep), lsf.str())); gc()