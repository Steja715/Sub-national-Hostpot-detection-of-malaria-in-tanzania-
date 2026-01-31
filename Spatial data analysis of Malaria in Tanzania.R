# 1. LOAD LIBRARIES
library(malariaAtlas)
library(sf)
library(tidyverse)
library(spdep)
library(ggthemes)

# 2. DATA ACQUISITION & CLEANING
# Get malaria survey points and country boundaries
tz_data <- getPR(ISO = "TZA", species = "Pf")
tz_shp <- getShp(ISO = "TZA", admin_level = "admin1")

# Clean data: Remove missing coordinates
tz_data_clean <- tz_data %>%
  filter(!is.na(longitude) & !is.na(latitude))

# Convert to spatial object
tz_sf_points <- st_as_sf(tz_data_clean, coords = c("longitude", "latitude"), crs = 4326)

# 3. SPATIAL AGGREGATION
# Spatial Join: Assign points to districts
points_with_districts <- st_join(tz_sf_points, st_as_sf(tz_shp))

# Summarize prevalence by Region for the polygon map
summary_table <- points_with_districts %>%
  st_drop_geometry() %>%
  group_by(name_1) %>%
  summarize(
    avg_prevalence = mean(pr, na.rm = TRUE),
    sample_size = sum(examined, na.rm = TRUE)
  )

# Join summary back to polygons and remove regions with no data
final_spatial_data <- left_join(tz_shp, summary_table, by = "name_1") %>%
  filter(!is.na(avg_prevalence))

# 4. STATISTICAL ANALYSIS (LISA)
# Define neighbors and weights
nb <- poly2nb(final_spatial_data, queen = TRUE)
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)

# Calculate Local Moran's I
lisa_results <- localmoran(final_spatial_data$avg_prevalence, lw, zero.policy = TRUE)
final_spatial_data$p_val <- lisa_results[,5]

# Scale data to identify High-High vs Low-Low clusters
final_spatial_data$scaled_prev <- scale(final_spatial_data$avg_prevalence)
final_spatial_data$scaled_lag <- scale(lag.listw(lw, final_spatial_data$avg_prevalence))

# Categorize clusters
final_spatial_data$cluster <- "Not Significant"
final_spatial_data$cluster[final_spatial_data$p_val <= 0.05 & final_spatial_data$scaled_prev > 0 & final_spatial_data$scaled_lag > 0] <- "High (Hotspot)"
final_spatial_data$cluster[final_spatial_data$p_val <= 0.05 & final_spatial_data$scaled_prev < 0 & final_spatial_data$scaled_lag < 0] <- "Low (Coldspot)"

# 5. FINAL VISUALIZATION
ggplot() +
  # Layer 1: Regions colored by Cluster type
  geom_sf(data = final_spatial_data, aes(fill = cluster), color = "white", alpha = 0.8) +
  
  # Layer 2: Raw Survey Points (Size scaled by people examined)
  geom_sf(data = tz_sf_points, aes(color = pr, size = examined), alpha = 0.5) +
  
  # Styling
  scale_fill_manual(values = c("High (Hotspot)" = "#d73027", 
                               "Low (Coldspot)" = "#4575b4", 
                               "Not Significant" = "grey90"),
                    name = "Statistical Cluster") +
  scale_color_viridis_c(option = "magma", name = "Raw Parasite Rate") +
  scale_size_continuous(range = c(1, 4), name = "Sample Size") +
  
  labs(title = "Spatial Epidemiology of Malaria: Tanzania",
       subtitle = "Sub-national Hotspot Detection using Local Moran's I",
       caption = "Data: Malaria Atlas Project | Analysis: [Your Name]") +
  theme_minimal()

# 6. SAVE OUTPUT
ggsave("malaria_analysis_tanzania.png", width = 10, height = 8, dpi = 300)