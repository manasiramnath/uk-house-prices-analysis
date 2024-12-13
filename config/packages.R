library(conflicted)
# conflicted packcages
conflicts_prefer(dplyr::filter,
                 dplyr::select,
                 plotly::layout,
                 dplyr::recode)

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  readODS, installr, tidyverse, zip, janitor, readxl, writexl, openxlsx,
  car, tidymodels, plm, readr, broom.mixed, lmtest, multiwayvcov, tidypredict, 
  fe, ggplot2, Metrics, caret, gridExtra, foreach, plotly,
  sp, sf, tmap, RColorBrewer, stargazer
)




