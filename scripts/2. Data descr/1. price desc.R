## script to describe house prices and preliminary EDA
## =====================================================================================================================
# set colour palette
region_cols = c(
  'East' = '#6BABB6',  
  'East Midlands' = "#003D4C",
  'London' =  "#B5394D",
  'North East' = "#DE7C00",
  'North West' = "#971B2F",
  'South East' = "#3D441E",
  'South West' = "#2F6F7A",
  'West Midlands' = '#5D295F',
  'Yorkshire and The Humber' = "#7B477D"
)

# load data
data <- from_cache("final_merged_data_cleaned", "clean")

## distribution of house prices
## =====================================================================================================================
# facet wrap median price before and after log median price

price_dist <- ggplot(data, aes(x = median_price)) +
  geom_histogram(fill = '#555599', color = "black", bins = 30) +
  labs(
       x = "Median Price",
       y = "Frequency") +
  theme_minimal() +
  theme(legend.position = "none",
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12),
        plot.title = element_text(size = 16, face = "bold"))

log_price_dist <- ggplot(data, aes(x = log(median_price))) +
  geom_histogram(fill = '#555599', color = "black", bins = 30) +
  labs(
       x = "Log Median Price",
       y = "Frequency") +
  theme_minimal() +
  theme(legend.position = "none",
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12),
        plot.title = element_text(size = 16, face = "bold"))
grid.arrange(price_dist, log_price_dist, ncol=2, top = "Distribution of median house prices are more normally distributed after log transformation")
## house prices over time
## =====================================================================================================================

agg_data <- data |>
  group_by(year) |>
  summarise(avg_median_price = mean(median_price, na.rm = TRUE), .groups = "drop")

price_over_time_plot <- ggplot(agg_data, aes(x = factor(year), y = avg_median_price)) +
  geom_bar(stat = "identity", fill = "#568E99", color = "black", width = 0.7) +
  labs(title = "House prices have been rising steadily over the years",
       x = "Year",
       y = "Average Median Price") +
  theme_minimal() +
  theme(legend.position = "none",
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12),
        plot.title = element_text(size = 16, face = "bold"))

price_over_time_plot <- ggplotly(price_over_time_plot)
price_over_time_plot <- price_over_time_plot |>
  layout(
    title = list(text = "House prices have been rising steadily over the years", font = list(size = 20)),
    xaxis = list(title = "Year", tickfont = list(size = 14)),
    yaxis = list(title = "Average Median Price", tickfont = list(size = 14)),
    margin = list(t = 50, b = 50, l = 50, r = 50) # Adjust margins for better spacing
  )

price_over_time_plot

# get table of house prices over time
price_over_time_table <- data |>
  group_by(year) |>
  summarise(avg_median_price = mean(median_price, na.rm = TRUE)) |>
  arrange(year)
#write_csv(price_over_time_table, file.path(dir$output, desc, 'price_over_time_table.csv'))
## =====================================================================================================================
price_region <- data |>
  group_by(region, year) |>
  summarise(avg_median_price = mean(median_price, na.rm = TRUE)) |>
  ungroup()

price_region_plot <- ggplot(price_region, aes(x = year, y = avg_median_price, color = region, group = region)) +
  geom_line(size = 1.2) +  # Line graph with a thicker line
  geom_point(size = 3) +    # Add points to the line
  scale_color_manual(values = region_cols) +  # Set the custom colors
  labs(title = "Average Median Price Over Time by Region",
       x = "Year",
       y = "Average Median Price") +
  theme_minimal() + 
  theme(
    legend.position = "bottom",   # Place legend at the bottom
    axis.title = element_text(size = 14),  # Increase axis title size
    axis.text = element_text(size = 12),   # Increase axis text size
    plot.title = element_text(size = 16, face = "bold")  # Increase plot title size
  )

price_region_plot <- ggplotly(price_region_plot)

price_region_plot
# get table of house prices over time by region
price_region_table <- data |>
  group_by(region, year) |>
  summarise(avg_median_price = mean(median_price, na.rm = TRUE)) |>
  arrange(region, year)

#write.csv(price_region_table, file.path(dir$output, 'desc', "price_region_table.csv"))
## visualising correlations with price 
## ===============================================================================

all_corr <- read_csv('allcorrelations.csv')  |>
filter(corr < 0.7)  |>
arrange(desc(corr))

# filter median price
median_corr <- all_corr  |>
filter(var1 == 'median_price')  |>
arrange(desc(corr))

# pull variables that have abs corr > 0.2
vars_corr <- median_corr  |>
mutate(corr_int = ifelse(abs(corr) >= 0.2, 1, 0))  |>
filter(corr_int == 1)

#write.csv(vars_corr, file.path(dir$output, 'desc', 'vars_corr_price.csv'))))

## plotting relationship between annual income and median price
## ====================================================================
price_income <- ggplot(data, aes(x = net_annual_income_before_housing_costs, y = median_price)) +
  geom_point(color = '#16469E') +  
  # add a trend line
  geom_smooth(method = "lm", se = FALSE, color = "#CC7F0C") +
  labs(title = "Moderate Positive Correlation Between Median Price and \nHousehold Earnings",
       x = "Annual Income",
       y = "Median Price") +
  theme_minimal() +
  # remove grid
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
price_income


## plotting relationship between median price and unemployment rate
## ====================================================================
price_unemployment <- ggplot(data, aes(x = unemployment_rate, y = median_price)) +
  geom_point(color = '#428F51') +  
  # add a trend line
  geom_smooth(method = "lm", se = FALSE, color = "#C94D2F") +
  labs(title = "Small Negative Correlation Between Median Price and \nUnemployment Rates",
       x = "Employment Rate",
       y = "Median Price") +
  theme_minimal() +
  # remove grid
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

price_unemployment
