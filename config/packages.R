library(conflicted)
# conflicted packcages
conflicts_prefer(dplyr::filter,
                 dplyr::select,
                 plotly::layout,
                 dplyr::recode)

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  readODS, installr, tidyverse, zip, janitor, readxl, writexl, openxlsx,
  haven, labelled, collinear, missForest, car, e1071, tidymodels,
  readr, broom.mixed, dotwhisker, poissonreg, reshape2, grf, AER,
  ranger, pscl, glmmTMB, tidypredict, fe, ggplot2,
  Metrics, caret, gridExtra, foreach, doParallel, plotly,
  sp, sf, tmap, RColorBrewer, reticulate
)




