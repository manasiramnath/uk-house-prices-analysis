
# postcode to OA (2011) to LSOA to MSOA to LAD (Feb 2021) best fit lookup

lookup_old <- read_csv(file.path(dir$raw, 'shapefiles','NSPCL_NOV19_UK_LU.csv'))|> clean_names()
lookup_new <- read_csv(file.path(dir$raw, 'shapefiles','PCD_OA_LSOA_MSOA_LAD_FEB22_UK_LU.csv'))|> clean_names()
names(lookup_old)
# LAD to LSOA
# get unique LSOAs and their LADs
shp_lookup_old <- lookup_old  |>
    select(oa11cd, msoa11cd, msoa11nm, lsoa11cd, lsoa11nm, ladcd, ladnm)  |>
    distinct()

shp_lookup_new <- lookup_new  |>
    select(oa11cd, msoa11cd, msoa11nm, lsoa11cd, lsoa11nm, ladcd, ladnm)  |>
    distinct()

# save to cache
to_cache(shp_lookup_old, "shp_lookup_old", "clean")
to_cache(shp_lookup_new, "shp_lookup_new", "clean")
    



