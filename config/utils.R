check_dir <- function(dirpath){
  if (!dir.exists(dirpath)){
    dir.create(dirpath, recursive = TRUE)
  }
}

to_cache <- function(output, name, folder){
  path <- file.path(dir$cache, folder)
  check_dir(path)
  write_rds(output, file.path(path, paste0(name, '.RDS')))
}

from_cache <- function(name, folder){
  data <- read_rds(file.path(dir$cache, folder, paste0(name, '.RDS')))
  return(data)
}

to_output <- function(output, name, folder){
  path <- file.path(dir$output, folder)
  check_dir(path)
  write_rds(output, file.path(path, paste0(name, '.RDS')))
}

from_output <- function(name, folder){
  data <- read_rds(file.path(dir$output, folder, paste0(name, '.RDS')))
  return(data)
}


# removing outliers based on percentile
remove_outliers_percentile <- function(df, trim_pct) {
  
  # Identify numeric columns
  numeric_cols <- df %>% select(where(is.numeric)) %>% colnames()

    
  # Remove outliers only for non-normally distributed variables
  for (variable in numeric_cols) {
    lower_bound <- quantile(df[[variable]], trim_pct / 2, na.rm = TRUE)
    upper_bound <- quantile(df[[variable]], 1 - trim_pct / 2, na.rm = TRUE)
    
    # Filter data to exclude outliers for this column
    df <- df %>% filter(df[[variable]] >= lower_bound & df[[variable]] <= upper_bound)
  }
  
  return(df)
}


