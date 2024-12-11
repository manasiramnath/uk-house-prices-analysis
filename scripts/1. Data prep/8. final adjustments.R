
## scripts to explore the data and make adjustments
## =====================================================================================================================

# loading merged data
#data <- from_cache("final_merged_data", "clean")
data <- final_merged_data
original_data <- data

# skim the data
data_skimmed <- skimr::skim(data)

## missing values
## =====================================================================================================================
missings_vars <- data %>%
  mutate_all(~as.character(.)) %>%
  pivot_longer(!c(local_authority_code, local_authority_name, lsoa_code, lsoa_name, year),
               names_to = 'variable') %>%
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

# impute variables starting with cpi with mean 
cpi_vars <- data %>%
  select(starts_with('cpi')) %>%
  colnames()
data <- data  |>
mutate(across(all_of(cpi_vars), ~ifelse(is.na(.), mean(., na.rm = TRUE), .)))

# Calculate missingness by year for the selected variables
missingness_by_year <- data %>%
  # Select the relevant columns (net_annual_income, total_population, unemployment_rate, and variables starting with 'cpi')
  select(year, net_annual_income_before_housing_costs, total_population, unemployment_rate, starts_with('cpi')) %>%
  group_by(year) %>%
  # Summarise all by calculating the number of missing values
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  # Convert the counts to percentages of missing values
  mutate(across(-year, ~(. / n()) * 100)) %>%
  # Reshape the data to long format (gather the variables)
  pivot_longer(cols = -year, names_to = "variable", values_to = "missingness")

# replace remaining missing values with mean
data <- data  |>
mutate(across(where(is.numeric), ~ifelse(is.na(.), mean(., na.rm = TRUE), .)))

data <- data %>%
  mutate(unemployment_rate = as.numeric(unemployment_rate)) %>%
  mutate(unemployment_rate = ifelse(is.na(unemployment_rate), mean(unemployment_rate, na.rm = TRUE), unemployment_rate))

sum(is.na(data))


## variables with no variance
## =====================================================================================================================
cat('variables with no variance: \n')
# get column names with no variance
no_variance <- data %>%
  select(where(~ length(unique(.)) == 1)) %>%
  colnames()
print(no_variance)
data <- data %>%
  select(where(~ length(unique(.)) > 1))


## calculate spearman correlation
## =====================================================================================================================
# random 10% sample
data_subset <- data %>% sample_frac(0.1)

print('Calculating spearman correlation')
spearman_test <- function(x, y) {
  result <- cor.test(x, y, method = "spearman")
  list(corr = result$estimate, p_value = result$p.value)
}

data_num <- data_subset %>% select_if(is.numeric)

#correlations <- combn(
#  names(data_num), 
#  2, simplify = FALSE) %>%
#  map_dfr(~ {
#    test_result <- spearman_test(data_num[[.x[1]]], data_num[[.x[2]]])
#    tibble(
#      var1 = .x[1],
#      var2 = .x[2],
#      corr = test_result$corr,
#      p_value = test_result$p_value
#    )
#  })

# subset to variables with correlation > 0.7
# cor_var <- correlations %>%
#  filter(corr > 0.7) %>% 
#  select(-p_value)

# write correlations to csv
#write_csv(correlations, file.path(dir$output, 'allcorrelations.csv'))
#write_csv(cor_var, file.path(dir$output, 'correlations.csv'))
# read high correlations
cor_var <- read_csv(file.path(dir$output, 'correlations.csv'))

# drop var1
dropped <- cor_var %>%
  select(var1) %>%
  distinct() %>%
  pull()

data <- data %>%
  select(-all_of(dropped))

final_merged_data_cleaned <- data

# save to cache
to_cache(final_merged_data_cleaned, "final_merged_data_cleaned", "clean")
