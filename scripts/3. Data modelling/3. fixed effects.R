## fixed effects

# aggregating data to local authority -------------------------------------
# rationale: too many groups if by LSOA, but we still want to see geographic variation

# subset data to important features
non_zero_coefs <- read.csv(file.path(dir$output, 'reg', 'reg_non_zero_coefs.csv'))
data <- from_cache("final_merged_data_clean", "clean")

impt_features <- non_zero_coefs |> 
  filter(term != '(Intercept)' & !grepl('year', term)
         & !grepl('region', term)) |>
  pull(term)

geog_cols <- c('local_authority_code', 'local_authority_name', 'lsoa_code', 'lsoa_name', 'region')
data <- data |> 
  select(all_of(impt_features), all_of(geog_cols), year, median_price)

# method of aggregation
sum_vars <- setdiff(
  colnames(data),
  c("ssp_tt", "hosp_p_tt", "food_p_tt", "town_p_tt", 
    "net_annual_income_before_housing_costs","median_price", 
    "avg_mortgage_fixed", "unemployment_rate", 
    "local_authority_code", "lsoa_code", "lsoa_name", "region", "year", geog_cols)
)

mean_vars <- c("median_price", "ssp_tt", "hosp_p_tt", "food_p_tt", "town_p_tt", 
               "net_annual_income_before_housing_costs", 'avg_mortgage_fixed', 'unemployment_rate')

.groups = "keep" # Preserves the grouping in summarise
aggregated_data <- data |>
  group_by(region, local_authority_name, year) |>
  summarise(
    across(all_of(sum_vars), sum, na.rm = TRUE),
    across(all_of(mean_vars), mean, na.rm = TRUE),
    total_lsoas = n(), # Add this line for total LSOA count
    .groups = "drop"  # Ensure ungrouping if not using ungroup()
  ) 

# fixed effects -----------------------------------------------------------
# Hausman test 
# choosing between fixed and random effects
panel_data <- pdata.frame(aggregated_data, index = c("local_authority_name", "year"))
fixed_model <- plm(median_price ~ . - local_authority_name - year -region, data = panel_data, model = "within")
random_model <- plm(median_price ~ . - local_authority_name - year -region, data = panel_data, model = "random")
hausman_test <- phtest(fixed_model, random_model)
print(hausman_test)


# two-way: unit (local authority) and time (year) fixed effects
# use all predictors except the dependent variable and identifiers
predictors <- setdiff(
  colnames(aggregated_data),
  c("median_price", "local_authority_name", "region", "year")
)

# write formula
formula <- as.formula(
  paste("median_price ~", paste(predictors, collapse = " + "))
)

# run model
fe_m <- plm(formula, 
            data = panel_data, model = "within",
            effect = "twoways")
summary(fe_m)
stargazer(fe_m, type = "html", out = file.path(dir$output, "fe", "fe_output.html"))

# clustering standard errors 
# Heteroscedasticity-consistent estimation of 
# the covariance matrix of the coefficient estimates
clustered_se <- vcovHC(fe_m, type = "HC1", cluster = "group")

# apply clustered standard errors
clustered_fe_m <- coeftest(fe_m, vcov = clustered_se)

clustered_fe_m

## visualising residuals
## =============================================================================
# get residuals from the fixed effects model
residuals_fe_m <- resid(fe_m)

# get fitted values
fitted_values_fe_m <- fitted(fe_m)

# plot residuals vs. fitted values (for heteroscedasticity or non-linearity)
ggplot(data.frame(fitted = fitted_values_fe_m, residuals = residuals_fe_m), aes(x = fitted, y = residuals)) +
  geom_point(color = "#4A3A3A") +
  geom_hline(yintercept = 0, color = "#CF4C4C", linetype = "dashed") +
  labs(title = "Residuals vs Fitted Values",
       x = "Fitted Values",
       y = "Residuals") +
  theme_minimal()

# histogram of residuals (for normality check)
ggplot(data.frame(residuals = residuals_fe_m), aes(x = residuals)) +
  geom_histogram(bins = 30, color = "black", fill = "#568E99") +
  labs(title = "Histogram of Residuals",
       x = "Residuals",
       y = "Frequency") +
  theme_minimal()

# QQ plot (for normality check)
qqnorm(residuals_fe_m)
qqline(residuals_fe_m, col = "#CF4C4C")

## interactions with region to show drivers by geography
# =============================================================================

# set colour palette
region_cols = c(
  'East' = '#6BABB6',  
  'East Midlands' = "#003D4C",
  'London' =  "#B5394D",
  'North East' = "#DE7C00",
  'North West' = "#971B2F",
  'South East' = "#3D441E",
  'South West' = "#2F6F7A",
  'West Midlands' = '#5D295F',
  'Yorkshire and The Humber' = "#7B477D"
)

# select signifcant terms from the fixed effects model to interact with region
fe_interaction_model <- plm(
  median_price ~ all_properties * region + bp_1983_1992 * region + bp_1900_1918 * region + net_annual_income_before_housing_costs * region + 
    house_terraced_6 * region + unemployment_rate * region,
  data = panel_data, model = "within", effect = "twoways"
)
summary(fe_interaction_model)
coef_interactions <- summary(fe_interaction_model)$coefficients
region_interactions <- coef_interactions[grep("region", rownames(coef_interactions)), ]
print(region_interactions)

## 1. all properties vs house prices by region
# extract all properties interactions
all_properties_interactions <- region_interactions[grep("all_properties:region", rownames(region_interactions)), ]
all_properties_df <- data.frame(
  Region = rownames(all_properties_interactions),
  Coefficient = all_properties_interactions[, "Estimate"]
) |>
  mutate(Region = gsub("all_properties:region", "", Region))

# plot the interaction effect
ggplot(all_properties_df, aes(x = Coefficient, y = Region, fill = Region)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  scale_fill_manual(values = region_cols) +  
  theme_minimal() +
  theme(
    axis.text.x = element_text(size = 12, color = "black"),  
    axis.text.y = element_text(size = 10, color = "black"),  
    axis.title.x = element_text(size = 14, face = "bold", color = "black"),  
    axis.title.y = element_text(size = 14, face = "bold", color = "black"),  
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5)  
  ) +
  scale_x_continuous(expand = c(0.005, 0.005)) +  
  labs(
    title = "Effect of All Properties on House Prices by Region",
    x = "Coefficient Estimate",
    y = "Region"
  )

## 2. net income coefficients
net_income_interactions <- region_interactions[grep(":net_annual_income_before_housing_costs", rownames(region_interactions)), ]
net_income_interactions_df <- data.frame(
  Region = rownames(net_income_interactions),
  Coefficient = net_income_interactions[, "Estimate"]
) |>
  mutate(Region = gsub(":net_annual_income_before_housing_costs", "", Region)) |>
  mutate(Region = gsub("region", "", Region))

# plot net income coefficients
ggplot(net_income_interactions_df, aes(x = Coefficient, y = Region, fill = Region)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  scale_fill_manual(values = region_cols) +  # Apply manual colors
  theme_minimal() +
  theme(
    axis.text.x = element_text(size = 12, color = "black"),  # Adjust x-axis text size and color
    axis.text.y = element_text(size = 12, color = "black"),  # Adjust y-axis text size and color
    axis.title.x = element_text(size = 14, face = "bold", color = "black"),  # Bold x-axis title
    axis.title.y = element_text(size = 14, face = "bold", color = "black"),  # Bold y-axis title
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5)  # Centered title
  ) +
  labs(
    title = "Effect of Net Annual Income on House Prices \nby Region",
    x = "Coefficient Estimate",
    y = "Region"
  )

## 3. unemployment rate
unemployment_interactions <- region_interactions[grep(":unemployment_rate", rownames(region_interactions)), ]
unemployment_interactions_df <- data.frame(
  Region = rownames(unemployment_interactions),
  Coefficient = unemployment_interactions[, "Estimate"]
) |>
  mutate(Region = gsub(":unemployment_rate", "", Region)) |>
  mutate(Region = gsub("region", "", Region))

# plot unemployment rate coefficients
ggplot(unemployment_interactions_df, aes(x = Coefficient, y = Region, fill = Region)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  scale_fill_manual(values = region_cols) +  # Apply manual colors
  theme_minimal() +
  theme(
    axis.text.x = element_text(size = 12, color = "black"),  # Adjust x-axis text size and color
    axis.text.y = element_text(size = 12, color = "black"),  # Adjust y-axis text size and color
    axis.title.x = element_text(size = 14, face = "bold", color = "black"),  # Bold x-axis title
    axis.title.y = element_text(size = 14, face = "bold", color = "black"),  # Bold y-axis title
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5)  # Centered title
  ) +
  labs(
    title = "Effect of Unemployment Rate on House Prices \nby Region",
    x = "Coefficient Estimate",
    y = "Region")
