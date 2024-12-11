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

