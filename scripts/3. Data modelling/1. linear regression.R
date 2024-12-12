## function to split data into train and test sets
split_data <- function(data, s, seed = 123) {
  # split into train and test
  set.seed(seed)
  
  data_split <- initial_split(data, prop=0.8, strata = s)
  train_data <- training(data_split)
  test_data <- testing(data_split)
  
  return(list(train_data = train_data,
              test_data = test_data)
  )
}

# fit workflow
fit_lm <- function(y,  data) {
  lm_spec <- linear_reg() |>
    set_engine("lm") |>
    set_mode("regression")
  
  lm_recipe <- recipe(as.formula(paste(y, '~ .')), data = data) |>
    step_zv(all_predictors())  # remove zero variance predictors

  # bundles model and recipe with a workflow
  lm_wf <- workflow() |>
    add_recipe(lm_recipe) |>
    add_model(lm_spec)
  
  # fit data
  lm_mod <- fit(lm_wf, data)
  
  return(lm_mod)
}

data <- read_rds('final_merged_data_cleaned.RDS')
correlations <- read.csv('allcorrelations.csv')
# random sample of data
set.seed(123)
data_sample <- data %>%
  group_by(year) %>%
  sample_frac(0.01) %>% # sample 10% from each year
  ungroup()

train_test_data <- split_data(data_sample, 'year')
data_train <- train_test_data$train_data
data_test <- train_test_data$test_data
 
lm_mod <- fit_lm('median_price', data_train)
lm_summary <- lm_mod |> 
  extract_fit_parsnip() |> 
  tidy()
write.csv(lm_summary, 'lm_summary.csv')

key_terms <- lm_summary |> 
  # filter by significant p-value and terms that do not start with lsoa
  filter(term != '(Intercept)' & p.value < 0.05 & !grepl('lsoa', term) & !grepl('local', term)) |>
  arrange(desc(abs(estimate)))
write.csv(key_terms, 'lm_key_terms.csv')

results <- data_test |> 
  bind_cols(lm_mod |> 
  predict(new_data = data_test) |>
  rename(predictions = .pred))
results_metrics <- results |> 
  metrics(truth = median_price, estimate = predictions)
write.csv(results_metrics, 'lm_results_metrics.csv')

# ------------------------------------------------------------------------------

# Load necessary libraries
library(tidymodels)
library(car)  # For vif function

# Function to split data into train and test sets
split_data <- function(data, s, seed = 123) {
  set.seed(seed)
  data_split <- initial_split(data, prop = 0.8, strata = s)
  train_data <- training(data_split)
  test_data <- testing(data_split)
  
  return(list(train_data = train_data, test_data = test_data))
}

# Fit linear model and handle multicollinearity
fit_lm <- function(y, data) {
  lm_spec <- linear_reg() |>
    set_engine("lm") |>
    set_mode("regression")
  
  # Recipe with steps to remove zero variance predictors and check correlations
  lm_recipe <- recipe(as.formula(paste(y, '~ .')), data = data) |>
    step_dummy(all_nominal_predictors()) %>%  # convert nominal predictors to dummy variables
    step_zv(all_predictors()) %>%  # remove zero variance predictors
    step_corr(all_predictors(), threshold = 0.9)  # remove highly correlated predictors (correlation > 0.9)
  
  # Bundling model and recipe into a workflow
  lm_wf <- workflow() |>
    add_recipe(lm_recipe) |>
    add_model(lm_spec)
  
  # Fit the model
  lm_mod <- fit(lm_wf, data)
  
  # Extract the fitted linear model (lm object) from the workflow
  lm_fit <- lm_mod$fit$fit
  
  # Check VIF after fitting model to assess multicollinearity
  vif_results <- vif(lm_fit)
  print(vif_results)  # Print VIF values for each predictor
  
  # Remove predictors with VIF > 10 (indicative of multicollinearity)
  high_vif_vars <- names(vif_results)[which(vif_results > 10)]
  if (length(high_vif_vars) > 0) {
    cat("Removing highly collinear predictors with VIF > 10:", high_vif_vars, "\n")
    # Modify recipe to remove predictors with high VIF
    lm_recipe <- lm_recipe |>
      step_select(all_of(setdiff(names(data), high_vif_vars)))
    lm_wf <- workflow() |>
      add_recipe(lm_recipe) |>
      add_model(lm_spec)
    
    # Refit the model after removing collinear predictors
    lm_mod <- fit(lm_wf, data)
  }
  
  return(lm_mod)
}

# Read the dataset
data <- read_rds('final_merged_data_cleaned.RDS')

# Sample a random fraction of data by year
set.seed(123)
data_sample <- data %>%
  group_by(year) %>%
  sample_frac(0.01) %>% # sample 1% from each year
  ungroup()

# Split the data into training and test sets
train_test_data <- split_data(data_sample, 'year')
data_train <- train_test_data$train_data
data_test <- train_test_data$test_data

# Fit the linear model with the sample data
lm_model <- fit_lm("median_price", data_train)



lm_fit <- lm(median_price ~ ., data = data_train)
vif(lm_fit)
# get names of non-numeric columns
non_numeric_cols <- data_train |> 
  select_if(~!is.numeric(.)) |> 
  names()
cor_matrix <- cor(data_train[, -which(names(data_train) %in% non_numeric_cols)], use = "complete.obs")
cor_df <- as.data.frame(as.table(cor_matrix))

vars_to_drop <- c(starts_with("cpi"), )
high_cor_pairs <- which(abs(cor_matrix) > 0.7, arr.ind = TRUE)
high_cor_pairs <- high_cor_pairs[high_cor_pairs[, 1] != high_cor_pairs[, 2], ]
high_cor_variable_pairs <- apply(high_cor_pairs, 1, function(x) {
  colnames(cor_matrix)[x]
})
high_cor_variable_pairs


