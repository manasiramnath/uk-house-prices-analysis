## script to run regularised regression (elastic net)
# - feature importance
# - feature selection

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

# function to fit regularised regression model with tuning
fit_reg <- function(y,
                    s, # specify strata for cross-validation
                    data,
                    mixture_range, # proportion of L1 regularization
                    penalty_range, # strength of regularization
                    seed = 123) {
  set.seed(seed)
  # create k-fold cross validation set on training with 10 folds
  data_folds <- vfold_cv(data, v=10, strata = s)
  
  if (length(mixture_range) == 1) { # if strictly lasso (1) or ridge (0)
    reg_spec <- linear_reg(penalty = tune(), mixture = mixture_range) |>
      set_mode('regression') |>
      set_engine('glmnet')
  } else { # tune regularization
    reg_spec <-
      linear_reg(penalty = tune(), mixture = tune()) |>
      set_mode('regression') |>
      set_engine('glmnet')
  }
  
  reg_recipe <- recipe(as.formula(paste(y, '~ .')), data = data) |>
    # assign id cols
    update_role(all_of(geog_cols), new_role = 'id') |>
    step_dummy(all_nominal_predictors()) |>
    step_center(all_predictors()) |>
    step_scale(all_predictors())
  
  # bundles model and recipe with a workflow
  reg_wf <- workflow() |>
    add_recipe(reg_recipe) |>
    add_model(reg_spec)
  
  if (length(mixture_range)==1) {
    search_space <- grid_random(
      penalty(range = penalty_range),
      size = 50
    )
  } else {
    
    # random search over penalty and mixture
    search_space <- grid_random(
      penalty(range=penalty_range),
      mixture(range = mixture_range),
      size = 50
    )
  }
  
  # perform tuning
  tune_res <- tune_grid(
    reg_wf,
    resamples = data_folds,
    grid = search_space
  )
  
  # select best hyperparameters with rmse
  best_params <- select_best(tune_res, metric = "rmse")
  
  # refit final model with best params
  reg_final <- finalize_workflow(reg_wf, best_params)
  reg_final_fit <- fit(reg_final, data = data)
  
  return(list(tune_res,
              reg_final_fit,
              best_params)
  )
}


# load data ---------------------------------------------------------------
data <- from_cache("final_merged_data_clean", "clean")
# geog_cols 
geog_cols <- c('local_authority_code', 'local_authority_name', 'lsoa_code', 'lsoa_name')

# random sample of data
set.seed(123)
data_sample <- data |>
  group_by(year) |>
  sample_frac(0.01) |> # sample 10% from each year
  ungroup()

# split into train and test
train_test_data <- split_data(data_sample, 'year')
data_train <- train_test_data$train_data
data_test <- train_test_data$test_data


# fit model ---------------------------------------------------------------
# fit model with tuning
reg_mod <- fit_reg('median_price', 'year', 
                   data_train,
                   mixture_range = c(0,1),
                   penalty_range = c(1e-6, 0.1))

# extract results
tune_res <- reg_mod[[1]]
reg_mod_fit <- reg_mod[[2]]
best_params <- reg_mod[[3]]

# 1. RMSE plot
tune_res |> 
  collect_metrics() |> 
  filter(.metric == 'rmse') |>
  select(mean, penalty, mixture) |> 
  pivot_longer(penalty:mixture, names_to = 'parameter', values_to = 'value') |>
  ggplot(aes(x = value, y = mean, color = parameter)) +
  geom_point(show.legend = FALSE, size = 2) +  
  facet_wrap(~parameter, scales = 'free_x', 
             labeller = as_labeller(c(penalty = "Proportion of penalty", 
                                      mixture = "Proportion of L1 regularisation"))) +
  labs(x = NULL, y = 'RMSE', 
       title = "Tuning Results: RMSE vs Parameters") +
  scale_color_manual(values = c("penalty" = "#C43535", "mixture" = "#66BBBB")) +  
  theme(strip.text = element_text(size = 11, face = "bold")) 


# 2. Get non-zero coefficients  
non_zero_coefs <- tidy(reg_mod_fit) |> filter(abs(estimate) > 0)
#write_csv(non_zero_coefs, file.path(dir$output, 'reg', 'reg_non_zero_coefs.csv'))

# plot non-zero coefficients
important_features <- non_zero_coefs |>
  filter(term != '(Intercept)') |>
  ggplot(aes(x = reorder(term, estimate), y = estimate)) +
  geom_col(fill = '#569997') +
  coord_flip() +
  labs(x = NULL, y = 'Coefficient', 
       title = "Important features in predicting house prices",
       subtitle = "Housing stock dominates features driving property prices") +
  # make grid blank and white background
  theme(panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank()) +
  theme(axis.text.y = element_text(size = 6))


important_features


# evaluation --------------------------------------------------------------
# predict on test set
predictions <- predict(reg_mod_fit, data_test) |>
  bind_cols(data_test) |>
  select(median_price, .pred) |>
  mutate(median_price = exp(median_price),
         .pred = exp(.pred))

test_predictions <- augment(reg_mod_fit, data_test)
# extract evaluation metrics
evaluation_metrics <- test_predictions |>
  metrics(truth = median_price, estimate = .pred)

#write_csv(evaluation_metrics, file.path(dir$output, 'reg', 'reg_evaluation_metrics.csv'))
