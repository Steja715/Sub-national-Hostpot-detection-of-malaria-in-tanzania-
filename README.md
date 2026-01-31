# Spatial Epidemiology: Hotspot Detection of Malaria in Tanzania

## Project Overview
This project investigates the sub-national spatial heterogeneity of *Plasmodium falciparum* prevalence in Tanzania. By integrating raw survey data with administrative boundaries, I performed a Local Indicators of Spatial Association (LISA) analysis to identify statistically significant disease hotspots.

## Key Biostatistical Skills Demonstrated
* **Geospatial ETL:** Automated data retrieval using the `malariaAtlas` API and spatial data cleaning in `sf`.
* **Spatial Topology:** Construction of a Queen Contiguity spatial weights matrix.
* **Inferential Statistics:** Application of Global Moran’s I and Local Moran’s I (LISA) for cluster detection.
* **Data Visualization:** Multi-layered mapping using `ggplot2` and `viridis` color scales.

## Methodology
1. **Data:** Survey point data (Parasite Rate) from the Malaria Atlas Project.
2. **Aggregation:** Points were spatially joined to Admin-1 (Regional) polygons.
3. **Clustering:** Significant hotspots were defined as regions with $p \le 0.05$ using a row-standardized weights matrix.

## Results
![Malaria Hotspot Map](outputs/malaria_hotspot_map.png)

The analysis identified distinct "High-High" clusters (Hotspots) in the [Mention Region, e.g., North-West], suggesting areas for prioritized public health intervention.

## Requirements
To reproduce this analysis, you will need the following R packages:
`malariaAtlas`, `sf`, `spdep`, `tidyverse`, `ggthemes`
