
# postcode to OA (2011) to LSOA to MSOA to LAD (Feb 2021) best fit lookup

lookup21 <- read_csv(file.path(dir$raw, 'shapefiles','PCD_OA_LSOA_MSOA_LAD_FEB21_UK_LU.csv'))|> clean_names()
lookup22 <- read_csv(file.path(dir$raw, 'shapefiles','PCD_OA_LSOA_MSOA_LAD_FEB22_UK_LU.csv'))|> clean_names()

# LAD to LSOA
lad_lsoa_21 <- lookup21 |>


