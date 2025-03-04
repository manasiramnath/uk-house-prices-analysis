if (!requireNamespace("conflicted", quietly = TRUE)) install.packages("conflicted")
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
  ggplot2, Metrics, caret, gridExtra, foreach, plotly,
  sp, sf, tmap, RColorBrewer, stargazer
)

# install fe package
if (!requireNamespace("fe", quietly = TRUE)) {
  if (.Platform$OS.type == "unix") {
    install.packages("~/Z/Internal Projects/X-practice resources/fe_github_packages/fe_r", repos=NULL, type="source")
  } else {
    install.packages("Z:/Projects/Internal Projects/X-practice resources/fe_github_packages/fe_r", repos=NULL, type="source")
  }
}

library(fe)


