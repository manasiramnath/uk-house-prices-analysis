# load data

data <- from_cache("final_merged_data_cleaned", "clean")
shp <- read_sf(file.path(dir$raw, "shapefiles", "shapefiles_11", "LSOA_Dec_2011_PWC_in_England_and_Wales.shp"))

## =====================================================================================================================
## overview of prices over time (2014-2021)
## =====================================================================================================================
price_data <- data  |>
select(lsoa_code, region, year, median_price) |>
# round to nearest 1000
mutate(median_price = round(median_price / 1000))

map_data_sf <- shp |>
inner_join(price_data, by = c("lsoa11cd" = "lsoa_code")) |>
st_as_sf()

map_data_sf <- map_data_sf %>%
  mutate(centroid = st_centroid(geometry)) %>%
  st_as_sf()

map_data_sf <- map_data_sf %>%
  mutate(longitude = st_coordinates(centroid)[, 1],
         latitude = st_coordinates(centroid)[, 2])

ggplot() +
  # Plot the shapefile
  geom_sf(data = map_data_sf, fill = "lightgray", color = "black") +
  # Plot points with median prices (or another attribute)
  geom_point(data = map_data_sf, aes(x = longitude, y = latitude, color = median_price), size = 3) +
    scale_color_viridis_c() +
  theme_minimal() +
  labs(title = "Median Prices by LSOA",
       subtitle = "Price Data Mapped to Centroids of LSOAs")

hist(data$median_price, breaks = 50, main = "Histogram of Median Prices", xlab = "Median Price")

