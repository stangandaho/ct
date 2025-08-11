[![R-CMD-check](https://github.com/stangandaho/ct/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/stangandaho/ct/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/stangandaho/ct/graph/badge.svg?token=EPD6MHT0SG)](https://app.codecov.io/gh/stangandaho/ct)

<a href="https://stangandaho.github.io/ct/"><img src="man/figures/logo.png" align="right" height="139" alt="ct website" /></a>

# ct R package

Camera traps are an essential tool for wildlife monitoring and ecological research. 
They generate vast amounts of data that require careful processing, cleaning, and 
analysis to extract meaningful insights. Researchers use camera trap data for tasks 
such as species identification, biodiversity assessment, activity pattern analysis, 
and occupancy modeling.

Processing and analyzing camera trap data in R often requires multiple steps, 
from cleaning raw data to statistical modeling and visualization. The **ct** 
R package addresses these challenges by providing a **modern, tidyverse-friendly workflow** 
for camera trap data analysis. Using **tidy evaluation principles**, it enables 
users to efficiently manipulate and transform datasets. Additionally, it integrates 
seamlessly with **ggplot2**, allowing users to generate highly customizable 
visualizations.

## Key Features

The `ct` package provides a comprehensive suite of 55+ functions covering the 
complete camera trap data analysis workflow. **Population density estimation** 
is supported through `ct_fit_ds()` for distance sampling with automated model 
selection, `ct_fit_rem()` for Random Encounter Models, and `ct_traprate_estimate()` 
for trap rate calculations. **Data management** capabilities include `ct_independence()` 
for filtering independent detections, `ct_correct_datetime()` for timestamp correction, 
and `ct_check_location()` for interactive spatial validation. **Community ecology** 
functions enable activity pattern analysis with `ct_plot_density()` and 
`ct_overlap_estimates()`, biodiversity assessment through `ct_alpha_diversity()` 
and `ct_to_community()`, and occupancy modeling via `ct_to_occupancy()`. 
**Quality control** tools include `ct_find_break()` for detecting temporal gaps, 
`ct_plot_camtrap_activity()` for monitoring deployment status, and `ct_check_name()` 
for taxonomic validation. The package also features Camera Trap Data Package integration, 
survey design tools with `ct_survey_design()`, and more.

**For a full overview of all available functions, please visit the [ct website](https://stangandaho.github.io/ct/reference/index.html)**

## Installation:
You can install *ct* directly from GitHub:

```R
# Install pak firstly if not installed
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak", dependencies = TRUE)
}

# Install maimer from GitHub
pak::pkg_install("stangandaho/ct")
```

## Code of conduct
Please note that this project is based on the [Contributor Covenant v2.1](https://github.com/stangandaho/ct/blob/main/CODE_OF_CONDUCT.md). 
By participating in this project you agree to abide by its terms.

## Getting help
If you encounter a clear bug, please file an [issue](https://github.com/stangandaho/ct/issues) with a minimal reproducible 
example. For questions and other discussion, please use [relevant section](https://github.com/stangandaho/ct/discussions).

## Funding
The development of the ct package is supported by the R Consortium Infrastructure 
Steering Committee (ISC) under grant 25-ISC-1-04. This funding enables the creation 
of comprehensive statistical tools for camera trap data analysis, including population 
density estimation methods, and standardized data integration workflows. 
