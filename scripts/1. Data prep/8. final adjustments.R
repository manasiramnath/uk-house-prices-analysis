
## scripts to explore the data and make adjustments
## =====================================================================================================================

# loading merged data
data <- from_cache("final_merged_data", "clean")
original_data <- data

# skim the data
#data_skimmed <- skimr::skim(data)

## missing values
## =====================================================================================================================
missings_vars <- data |>
  mutate_all(~as.character(.)) |>
  pivot_longer(!c(local_authority_code, local_authority_name, lsoa_code, lsoa_name, year),
               names_to = 'variable') |>
  filter(is.na(value))

cat('missing values: \n')
print(missings_vars)
unique(missings_vars$variable)

# impute missing values with median from the same year and local authority
data <- data  |>
group_by(local_authority_code, year) |>
mutate(median_price = ifelse(is.na(median_price), median(median_price, na.rm = TRUE), median_price)) |>
ungroup()

# divide median price by 1000
data <- data  |>
mutate(median_price = round(median_price / 1000))

# calculate missingness by year for the selected variables
missingness_by_year <- data |>
  # select the relevant columns (net_annual_income, total_population, unemployment_rate, and variables starting with 'cpi')
  select(year, total_population, net_annual_income_before_housing_costs, unemployment_rate) |>
  group_by(year) |>
  # summarise all by calculating the number of missing values
  summarise(across(everything(), ~sum(is.na(.)))) |>
  # convert the counts to percentages of missing values
  mutate(across(-year, ~(. / n()) * 100)) |>
  pivot_longer(cols = -year, names_to = "variable", values_to = "missingness")

# use linear interpolation to fill missing income values
data <- data  |>
group_by(local_authority_code) |>
mutate(net_annual_income_before_housing_costs = na.approx(net_annual_income_before_housing_costs, rule = 2)) |>
ungroup()

# replace na in "avg_mortgage_var"   "avg_mortgage_fixed" "avg_bank_rate"  with mean
data <- data |>
  mutate(avg_mortgage_var = as.numeric(avg_mortgage_var)) |>
  mutate(avg_mortgage_fixed = as.numeric(avg_mortgage_fixed)) |>
  mutate(avg_bank_rate = as.numeric(avg_bank_rate)) |>
  mutate(avg_mortgage_var = ifelse(is.na(avg_mortgage_var), mean(avg_mortgage_var, na.rm = TRUE), avg_mortgage_var)) |>
  mutate(avg_mortgage_fixed = ifelse(is.na(avg_mortgage_fixed), mean(avg_mortgage_fixed, na.rm = TRUE), avg_mortgage_fixed)) |>
  mutate(avg_bank_rate = ifelse(is.na(avg_bank_rate), mean(avg_bank_rate, na.rm = TRUE), avg_bank_rate))

# replace missing unemployment rate with the mean
data <- data |>
  mutate(unemployment_rate = as.numeric(unemployment_rate)) |>
  mutate(unemployment_rate = ifelse(is.na(unemployment_rate), mean(unemployment_rate, na.rm = TRUE), unemployment_rate))

# drop cpi variables
data <- data  |>
  select(-starts_with('cpi'))

# drop total_population
data <- data  |>
  select(-total_population)

## variables with no variance
## =====================================================================================================================
cat('variables with no variance: \n')
# get column names with no variance
no_variance <- data |>
  select(where(~ length(unique(.)) == 1)) |>
  colnames()
print(no_variance)
data <- data |>
  select(where(~ length(unique(.)) > 1))


## calculate spearman correlation
## =====================================================================================================================
# random 10% sample (computational issues)
# data_subset <- data |> sample_frac(0.1)
# 
# print('Calculating spearman correlation')
# spearman_test <- function(x, y) {
#   result <- cor.test(x, y, method = "spearman")
#   list(corr = result$estimate, p_value = result$p.value)
# }
# 
# data_num <- data_subset |> select_if(is.numeric)
# 
# correlations <- combn(
#  names(data_num),
#  2, simplify = FALSE) |>
#  map_dfr(~ {
#    test_result <- spearman_test(data_num[[.x[1]]], data_num[[.x[2]]])
#    tibble(
#      var1 = .x[1],
#      var2 = .x[2],
#      corr = test_result$corr,
#      p_value = test_result$p_value
#    )
#  })
# 
# # subset to variables with correlation > 0.7
# cor_var <- correlations |>
#  filter(corr > 0.7) |>
#  select(-p_value)

#write correlations to csv
#write_csv(correlations, file.path(dir$output, 'desc', 'allcorrelations.csv'))
#write_csv(cor_var, file.path(dir$output, 'desc', 'correlations.csv'))
# read high correlations
cor_var <- read_csv(file.path(dir$output, 'desc', 'correlations.csv'))

vars_to_drop <- c("bungalow_total", "flat_mais_total", "house_detached_total", 
                  "house_semi_total", "house_terraced_total", "unknown", "house_detached_3", 
                  "avg_mortgage_var", "bp_unkw", "ss_cart", "ss_walkt", "ss_cyct", 
                  "town_cart", "town_walkt", "town_cyct", "hosp_cart", "hosp_walkt", "hosp_cyct", 
                  "food_cyct", "food_cart", "food_walkt", "gp_cart", "gp_walkt", "gp_cyct")

data <- data |>
  select(-all_of(vars_to_drop))


final_merged_data_cleaned <- data

# save to cache
to_cache(final_merged_data_cleaned, "final_merged_data_cleaned", "clean")
