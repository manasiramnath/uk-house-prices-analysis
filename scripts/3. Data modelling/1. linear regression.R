## script to run linear regression - base model

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

## function to set engine, recipe, and bundles it with a workflow to fit model
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

# load and prep data ------------------------------------------------------

data <- from_cache("final_merged_data_cleaned", "clean")
correlations <- read_csv(file.path(dir$output, 'desc', 'correlations.csv'))
# random sample of data
set.seed(123)
data_sample <- data |>
  group_by(year) |>
  sample_frac(0.01) |> 
  ungroup()


# run linear regression ---------------------------------------------------
# split data into train and test, with 'year' as strata
train_test_data <- split_data(data_sample, 'year')
data_train <- train_test_data$train_data
data_test <- train_test_data$test_data

# fit model 
lm_mod <- fit_lm('median_price', data_train)

# summary of model
lm_summary <- lm_mod |> 
  extract_fit_parsnip() |> 
  tidy()
#write.csv(lm_summary, file.path(dir$output, 'linear_reg', 'lm_summary.csv'))

# terms with significant p-values
key_terms <- lm_summary |> 
  # filter by significant p-value and terms that do not start with lsoa
  filter(term != '(Intercept)' & p.value < 0.05 & !grepl('lsoa', term) & !grepl('local', term)) |>
  arrange(desc(abs(estimate)))

# write.csv(key_terms, file.path(dir$output, 'linear_reg', 'lm_key_terms.csv'))


# evaluate model ----------------------------------------------------------
# predict on test data
results <- data_test |> 
  bind_cols(lm_mod |> 
  predict(new_data = data_test) |>
  rename(predictions = .pred))
results_metrics <- results |> 
  metrics(truth = median_price, estimate = predictions)
# write.csv(results_metrics, file.path(dir$output, 'linear_reg', 'lm_results_metrics.csv'))

