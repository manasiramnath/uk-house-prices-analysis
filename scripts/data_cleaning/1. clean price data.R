# load xls file

median_price <- read_xls(file.path(dir$raw, "median_price.xls"), 
sheet = "1a")  |>
clean_names() 
