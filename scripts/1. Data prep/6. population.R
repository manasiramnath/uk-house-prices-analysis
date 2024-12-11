## cleaning population scripts

keep <- ls()

# Annual midyear population estimates by local authority, sex and age
# ---------------------------------------------------------------------

data <- read_xlsx(file.path(dir$raw, "population", "myebtablesenglandwales20112022v3.xlsx"), sheet = "MYEB1 (2021 Geography)", skip = 1) |>
  clean_names() |>  
select(ladcode21, laname21, sex, population_2011:population_2022) |>
pivot_longer(cols = starts_with("population"), names_to = "year", values_to = "pop_est") |>
mutate(year = as.numeric(str_extract(year, "\\d{4}")))  |>
filter(year >= 2014)  |>
  group_by(ladcode21, laname21, year) |>   
  summarise(total_population = sum(pop_est, na.rm = TRUE)) |>  # Summing population
  ungroup()

# save to cache
to_cache(data, "population", "clean")

## clean environment
rm(list=setdiff(setdiff(ls(), keep), lsf.str())); gc()