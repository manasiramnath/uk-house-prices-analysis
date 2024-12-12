# subset data to important features
non_zero_coefs <- read.csv('reg_non_zero_coefs.csv')
data <- read_rds('final_merged_data_cleaned.RDS')

impt_features <- non_zero_coefs |> 
  filter(term != '(Intercept)' & !grepl('year', term)
         & !grepl('region', term)) |>
  pull(term)

geog_cols <- c('local_authority_code', 'local_authority_code', 'lsoa_code', 'lsoa_name', 'region')
data <- data |> 
  select(all_of(impt_features), all_of(geog_cols), year)

# aggregate data by lsoa
data_agg <- data |>
  group_by(local_authority_code, local_authority_code, year) |> 
  # summarise mean across numeric cols
  summarise(across(where(is.numeric), mean, na.rm = TRUE))

# fixed effects with varied intercepts for year and lsoa
