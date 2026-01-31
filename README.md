# Spatial Epidemiology: Sub-national Hotspot Detection of Malaria in Tanzania

## Project Overview
This repository contains a full biostatistical pipeline for investigating the spatial heterogeneity of *Plasmodium falciparum* prevalence in Tanzania. By integrating raw survey data with administrative boundaries, I performed a **Local Indicators of Spatial Association (LISA)** analysis to identify statistically significant disease hotspots.

## Key Biostatistical Skills Demonstrated
* **Geospatial ETL:** Automated data retrieval using the `malariaAtlas` API and spatial cleaning in `sf`.
* **Spatial Topology:** Construction of a **Queen Contiguity** spatial weights matrix to model regional connectivity.
* **Inferential Statistics:** Application of **Global Moran’s I** and **Local Moran’s I (LISA)** for cluster detection.
* **Data Visualization:** Multi-layered mapping using `ggplot2` and `viridis` color scales.

---

## Final Analysis Result
![Malaria Hotspot Map](outputs/malaria_hotspot_map.png)
*Figure 1: Statistically significant malaria hotspots identified in Southern Tanzania (p <= 0.05).*

---

## Full Reproducible Code

```R
# 1. LOAD LIBRARIES
library(malariaAtlas)
library(sf)
library(tidyverse)
library(spdep)
library(ggthemes)

# 2. DATA ACQUISITION & CLEANING
tz_data <- getPR(ISO = "TZA", species = "Pf")
tz_shp <- getShp(ISO = "TZA", admin_level = "admin1")

# Clean data: Remove missing coordinates
tz_data_clean <- tz_data %>% filter(!is.na(longitude) & !is.na(latitude))
tz_sf_points <- st_as_sf(tz_data_clean, coords = c("longitude", "latitude"), crs = 4326)

# 3. SPATIAL AGGREGATION
points_with_districts <- st_join(tz_sf_points, st_as_sf(tz_shp))
summary_table <- points_with_districts %>%
  st_drop_geometry() %>%
  group_by(name_1) %>%
  summarize(avg_prevalence = mean(pr, na.rm = TRUE),
            sample_size = sum(examined, na.rm = TRUE))

final_spatial_data <- left_join(tz_shp, summary_table, by = "name_1") %>%
  filter(!is.na(avg_prevalence))

# 4. STATISTICAL ANALYSIS (LISA)
nb <- poly2nb(final_spatial_data, queen = TRUE) # Queen Contiguity
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)

lisa_results <- localmoran(final_spatial_data$avg_prevalence, lw, zero.policy = TRUE)
final_spatial_data$p_val <- lisa_results[,5]

# Scale data for Cluster Categorization
final_spatial_data$scaled_prev <- scale(final_spatial_data$avg_prevalence)
final_spatial_data$scaled_lag <- scale(lag.listw(lw, final_spatial_data$avg_prevalence))

final_spatial_data$cluster <- "Not Significant"
final_spatial_data$cluster[final_spatial_data$p_val <= 0.05 & final_spatial_data$scaled_prev > 0 & final_spatial_data$scaled_lag > 0] <- "High (Hotspot)"
final_spatial_data$cluster[final_spatial_data$p_val <= 0.05 & final_spatial_data$scaled_prev < 0 & final_spatial_data$scaled_lag < 0] <- "Low (Coldspot)"

# 5. VISUALIZATION
ggplot() +
  geom_sf(data = final_spatial_data, aes(fill = cluster), color = "white", alpha = 0.8) +
  geom_sf(data = tz_sf_points, aes(color = pr, size = examined), alpha = 0.5) +
  scale_fill_manual(values = c("High (Hotspot)" = "#d73027", "Low (Coldspot)" = "#4575b4", "Not Significant" = "grey90")) +
  scale_color_viridis_c(option = "magma") +
  theme_minimal() +
  labs(title = "Malaria Hotspot Detection: Tanzania")
