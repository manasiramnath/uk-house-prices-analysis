## cleaning script for household characteristics
## data sources:
## 1. housing stock
    # - count of properties by type
    # - build period
## 2. household earnings
    # - annual weekly household income before housing costs by MSOA
keep <- ls()
## unzipping files needed
## =====================================================================================================================

all_zips <- list.files(file.path(dir$raw, "hh_stock"), full.names = TRUE, pattern = "\\.zip$")

for (z in all_zips) {
    cat(paste0("Unzipping ", z, "\n"))
    files <- zip_list(z)$filename
    # unzip only relevant years
    files <- files[grepl("20(1[4-9]|2[0-3])", files)]

    target_dir <- file.path(dir$raw, "hh_stock", "unzipped")
    files <- files[!file.exists(file.path(target_dir, files))]

    if(length(files) == 0) {
        cat(paste0("All files already unzipped for ", z, "\n"))
        next
    } else {
        cat(paste0("Unzipping ", length(files), " files\n"))
            zip::unzip(z, 
            files = files, 
            exdir = file.path(dir$raw, "hh_stock", "unzipped"), 
            overwrite = TRUE)
    }
}


## load and organise data
## =====================================================================================================================
unzipped_path <- file.path(dir$raw, "hh_stock", "unzipped")
files <- list.files(unzipped_path)
ctsop3_1_list <- list()
ctsop4_1_list <- list()

for (f in files) {
    cat(paste0("Processing ", f, "\n"))
    
    # Get full paths to files in the subdirectories
    data <- read_csv(file.path(unzipped_path, f))
    data <- data  |>
        clean_names() |>
        mutate(year = as.numeric(str_extract(f, "\\d{4}")))

    if (grepl("CTSOP3_1", f)) {ctsop3_1_list[[f]] <- data}
    if (grepl("CTSOP4_1", f)) {ctsop4_1_list[[f]] <- data}

}
ctsop3_1_filtered <- lapply(ctsop3_1_list, function(df) {
    df |>
        filter(band == 'All') |>
        filter(geography == 'LSOA')  |>
        select(-c(band, geography, ba_code, area_name))  |>
        #replace - with 0
        mutate(across(!c(ecode, year), ~replace(., . == "-", 0))) |>
        mutate(across(!c(ecode, year), as.numeric))
})

ctsop4_1_filtered <- lapply(ctsop4_1_list, function(df) {
    df %>% 
        filter(band == 'All') |>
        filter(geography == 'LSOA') |>
        select(-c(band, geography, ba_code, area_name)) |>
        mutate(across(!c(ecode, year), as.character)) |>
        #replace - with 0
        mutate(across(!c(ecode, year), ~replace(., . == "-", 0))) |>
        mutate(across(!c(ecode, year), as.numeric))
})

ctsop3_1_colnames <- lapply(ctsop3_1_filtered, colnames)
ctsop4_1_colnames <- lapply(ctsop4_1_filtered, colnames)

ctsop3_1_unique_cols <- Reduce(intersect, ctsop3_1_colnames)
ctsop4_1_unique_cols <- Reduce(intersect, ctsop4_1_colnames)

setdiff(ctsop3_1_unique_cols, ctsop4_1_unique_cols) # columns unique to ctsop3_1
setdiff(ctsop4_1_unique_cols, ctsop3_1_unique_cols) # columns unique to ctsop4_1

# bind  rows
ctsop3_1 <- bind_rows(ctsop3_1_filtered) |> select(-all_properties)
ctsop4_1 <- bind_rows(ctsop4_1_filtered)
# merge ctsop3_1_cleaned and ctsop4_1_cleaned
cols_to_merge <- intersect(names(ctsop3_1), names(ctsop4_1))
ctsop_merged <- ctsop3_1 |>
left_join(ctsop4_1, by = cols_to_merge, suffix = c("_ctsop3", "_ctsop4"))

skimr::skim(ctsop_merged)

# save to cache
to_cache(ctsop3_1, "ctsop3_1", "clean")
to_cache(ctsop4_1, "ctsop4_1", "clean")
to_cache(ctsop_merged, "ctsop_merged", "clean")

## clean environment
rm(list=setdiff(setdiff(ls(), keep), lsf.str())); gc()


