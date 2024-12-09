if (.Platform$OS.type == "unix") {
  z_dir <- "~/Z/Intern Work Area"
} else {
  z_dir <- "Z:/Interns Work Area"
}


dir <- list(
  raw = file.path(z_dir, "Manasi Ramnath/interview/1. raw"),
  cache = file.path(z_dir, "Manasi Ramnath/interview/2. cache"),
  output = file.path(z_dir, "Manasi Ramnath/interview/3. output"),
  scripts = file.path(z_dir, "Manasi Ramnath/repos/uk-house-prices-analysis/scripts")
)

rm(z_dir)