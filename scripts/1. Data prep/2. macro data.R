
# cleaning script for data on the economy
# data sources:
# 1. consumer price index
# 2. bank of england bank &  mortgage rates
# 3. unemployment rate

keep <- ls()

## bank of england bank & mortgage rates
## =====================================================================================================================
rates_raw <- read_xlsx(file.path(dir$raw, 'macro', 'rates.xlsx'), skip = 4) |> clean_names()


## consumer price index
## =====================================================================================================================
# loading CPIH detailed indices annual averages: 2008 to 2023
#cpi_raw <- read_xlsx(file.path(dir$raw, 'macro', 'cpi.xlsx'), sheet ='Table 9', skip = 5) |> clean_names()
