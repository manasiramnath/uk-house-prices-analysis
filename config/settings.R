if (.Platform$OS.type == "unix") {
  z_dir <- "~/Z/Intern Work Area"
} else {
  z_dir <- "Z:/Interns Work Area"
}


dir <- list(
  raw = file.path(z_dir, "Manasi Ramnath/UK House Prices/1. raw"),
  cache = file.path(z_dir, "Manasi Ramnath/UK House Prices/2. cache"),
  output = file.path(z_dir, "Manasi Ramnath/UK House Prices/3. output"),
  scripts = file.path("scripts")
)

rm(z_dir)
