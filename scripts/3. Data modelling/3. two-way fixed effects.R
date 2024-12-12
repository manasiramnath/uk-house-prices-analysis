# subset data to important features
non_zero_coefs <- read.csv('reg_non_zero_coefs.csv')
data <- read_rds('final_merged_data_cleaned.RDS')

impt_features <- non_zero_coefs |> 
  filter(term != '(Intercept)' & !grepl('year', term)
         & !grepl('region', term)) |>
  pull(term)

geog_cols <- c('local_authority_code', 'local_authority_code', 'lsoa_code', 'lsoa_name', 'region')
data <- data |> 
  select(all_of(impt_features), all_of(geog_cols), year, median_price)

# method of aggregation
sum_vars <- setdiff(
  colnames(data),
  c("gpp_tt", "hosp_p_tt", "food_walkt", "town_walkt", 
    "net_annual_income_before_housing_costs","median_price", 
    "avg_mortgage_fixed", "avg_bank_rate", "unemployment_rate", 
    "local_authority_code", "lsoa_code", "lsoa_name", "region", "year")
)

mean_vars <- c("median_price", "gpp_tt", "hosp_p_tt", "food_walkt", "town_walkt", 
               "net_annual_income_before_housing_costs")

aggregated_data <- data %>%
  group_by(local_authority_code, year) %>%
  summarise(
    across(all_of(sum_vars), sum, na.rm = TRUE),   # Sum for most variables
    across(all_of(mean_vars), mean, na.rm = TRUE) # Mean for specific variables
  ) %>%
  ungroup()

library(plm)

# fit fixed effects
# get all predictors except median, local_authority_code, year
predictors <- setdiff(
  colnames(aggregated_data),
  c("median_price", "local_authority_code", "year")
)

data_panel <- pdata.frame(aggregated_data, index = c("local_authority_code", "year"))
formula <- as.formula(
  paste("median_price ~", paste(predictors, collapse = " + "))
)

# Fit the two-way fixed effects model
twfe_model <- plm(
  formula,                # y = dependent variable, x1, x2 = independent variables
  data = data_panel,
  model = "within",           # "within" specifies fixed effects
  effect = "twoways"          # Two-way fixed effects (unit + time)
)

# Summary of the model
summary(twfe_model)

mod_fe <- plm(perc_lib ~ op + p_uni_degree + log_pop_denc + unemploy_rate + log_median_inc,data = s,
              index = c("master_id", "year"),
              effect = "twoways")


---
  title: "Seminar 9"
output:
  word_document: default
html_document: default
date: "2022-12-15"
---
  
  ```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

```{r}
setwd("/Users/manasi/Desktop/POLS0012")
```

```{r}
load(file = "Stokes_fe.Rda")
load(file = "malesky.Rda")
```

```{r}
library("lmtest")
library("multiwayvcov")
```

## Question 1

# a) Create a new dataset for the years 2008 and 2010 only

```{r}
m3 <- m[m$year>2006,]
```

In this dataset, create:
  
  ```{r}
# (i) a dummy variable called “time” equalling 1 if the year is 2010
m3$time <- ifelse(m3$year==2010,1,0)

# (ii) a variable for the interaction between time and treatment
m3$time_treat <- m3$time*m3$treatment
```

# b) Use the dataset and variables you created in a) to calculate a difference-in-difference estimate of the causal effect of centralisation on infrastructure investment. Interpret the resulting coefficient and its statistical significance.

```{r}
summary(lm(infra ~ time + treatment + time_treat,data=m3))
```

The estimated treatment effect is 0.27 with a p-value of 0.005, meaning that it is statistically significant at the 1% level. It implies that the centralisation of control over spending led to an increase of 0.27 in infrastructure investment, measured on a scale from 0 to 6.

# c) Repeat b), this time adding in a control for commune population. Why might it be sensible to include this control variable?
```{r}
model1 <- lm(infra ~ time + treatment + time_treat + lnpopden,data=m3)
summary(model1)
```

This gives a treatment effect of 0.25, slightly smaller than in (b). It is sensible to control for population because it is an obvious potential time-variable confounder. Infrastructure investment may increase in places experiencing rapid population growth. Controlling for it therefore helps make the parallel trends assumption more credible.

# d) Because the program was rolled out at the district level, there may be serial correlation in the standard errors across districts. To account for this, estimate cluster-robust standard errors for the model you estimated in c). How different is the estimated p-value for the difference-in-differences causal effect?

```{r}
library(lmtest)
library(multiwayvcov)
coeftest(model1, cluster.vcov(model1,m3$district))
```

The p-value increases more than five-fold from approximately 0.01 in part (c) to 0.055. This is very common when adjusting for clustering

# e) Difference-in-differences estimation relies on the ‘parallel trends’ assumption. Explain what that assumption means in this study.

It means that in the absence of treatment, the treated and untreated communes would have experienced the same changes infrastructure investment so that untreated communes provide a counterfactual (over time) for treated communes. Specifically, it requires that there be no time-varying confounders.

# f) Now, we’ll assess the parallel trends assumption graphically. Return to the full dataset and estimate means of the infra variable for 2006, 2008 and 2010 for both the treated and control groups (six means in total). Plot these means separately over time for the treated and control groups. Do you think that the parallel trends assumption is satisfied here?

```{r}
# means, treated
means.t <- c(mean(m$infra[m$year==2006&m$treatment==1]),
             mean(m$infra[m$year==2008&m$treatment==1]),
             mean(m$infra[m$year==2010&m$treatment==1]))
#means,control
means.c <- c(mean(m$infra[m$year==2006&m$treatment==0]),
             mean(m$infra[m$year==2008&m$treatment==0]),
             mean(m$infra[m$year==2010&m$treatment==0]))
# plot
plot(means.t,
     ylim=c(2.6,3.6),
     type="o",
     pch=16,
     col="red",
     xaxt="n",
     xlab="Year",
     ylab="Infrastructure Index")
lines(means.c,type="o",pch=15,col="blue")
3
axis(1,at=c(1,2,3),lab=c(2006,2008,2010))
legend("topleft",
       c("Treated","Control"),
       col=c("red","blue"),
       pch=c(16,15),
       lty=c(1,1))
```

Although not completely parallel, there is not much evidence of divergence between the treated and untreated groups prior to treatment. There is not much evidence
for a violation of the parallel trends assumption.

# g) Create a new dataset for the years 2006 and 2008 only, and use it to estimate a placebo difference-in-differences effect before the treatment occurred. What do you conclude about the parallel trends assumption?

Code Hints: You’ll need to create variables again. Don’t worry about cluster-robust standard errors (it is not possible because the authors don’t supply district IDs before 2008)

```{r}
m4 <- m[m$year<2010,]
m4$time <- ifelse(m4$year==2008,1,0)
m4$time_treat <- m4$time*m4$treatment
summary(lm(infra ~ time + treatment + time_treat + lnpopden ,data=m4))
```

The placebo treatment effect is close to zero and no longer statistically significant (with clustering the standard error probably be even larger). That is, there is no evidence that changes in the treatment group were statistically different to changes in the control group in the periods before the treatment took place. This is reassurring: it provides more formal statistical evidence in favour of the parallel trends assumption.

## Question 2
```{r}
library('plm')
```

# a) For this study, what is:
#i) The treatment?
op
#ii) The outcome?
perc_lib
#iii) The group variable for fixed effects?
master_id

# b) Using the framework of fixed effects estimation and the code provided in the slides/lecture notes, estimate a suitable model for the causal effect of wind farms on support for the incumbent party. Explain how you chose your model. Carefully interpret the resulting causal effect and its statistical significance

```{r}
mod_fe <- plm(perc_lib ~ op + p_uni_degree + log_pop_denc + unemploy_rate + log_median_inc,data = s,
              index = c("master_id", "year"),
              effect = "twoways")

library(lmtest)
coeftest(mod_fe, vcov=vcovHC(mod_fe, cluster="group", type="HC1"))

```

There is no good reason not to include all the time-varying controls, here, since they make the parallel trends assumption more plausible. The results suggest that a wind farm becoming operational in the district led to a 9 percentage-point drop in support for the incumbent party

# c) What is the key assumption needed for valid estimation of this causal effect? In theory (without doing any estimation), how reasonable do you think this assumption is?

The key assumption needed is parallel trends between areas that did and did not receive wind farms. This ensures that the untreated areas provide a valid counterfactual for the treated areas. It is difficult to say how plausible this assumption is without more formal tests, but it is certainly helped by the inclusion of a large number of time-varying confounders that probably have a strong impact on voting, like median income.

# d) Using a graphical approach, assess whether or not you think the assumption in c) is satisfied

Hint: Think carefully about what to use as your treatment variable
```{r}
# means, treated
means.t <- c(mean(s$perc_lib[s$year==2003&s$treat_o==1]),
             mean(s$perc_lib[s$year==2007&s$treat_o==1]),
             mean(s$perc_lib[s$year==2011&s$treat_o==1]))
#means,control
means.c <- c(mean(s$perc_lib[s$year==2003&s$treat_o==0]),
             mean(s$perc_lib[s$year==2007&s$treat_o==0]),
             mean(s$perc_lib[s$year==2011&s$treat_o==0]))
# plot
plot(means.t,
     ylim=c(0.2,0.6),
     type="o",
     pch=16,
     col="red",
     xaxt="n",
     xlab="Year",
     ylab="Incumbent Vote Share")
lines(means.c,type="o",pch=15,col="blue")
axis(1,at=c(1,2,3),lab=c(2003,2007,2011))
legend("topright",
       c("Treated","Control"),
       col=c("red","blue"),
       pch=c(16,15),
       lty=c(1,1))
```

The treated and untreated districts have near-perfect parallel trends in the outcome variable before treatment. Note that the treatment and control groups are defined for all periods of the data, so you need to use the treat o variable.
