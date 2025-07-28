[![R-CMD-check](https://github.com/stangandaho/ct/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/stangandaho/ct/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/stangandaho/ct/graph/badge.svg?token=LDM57A3MWL)](https://codecov.io/gh/stangandaho/ct)

# Simplifying Camera Trap Data Analysis in R

## Introduction
Camera traps are an essential tool for wildlife monitoring and ecological research. 
They generate vast amounts of data that require careful processing, cleaning, and 
analysis to extract meaningful insights. Researchers use camera trap data for tasks 
such as species identification, biodiversity assessment, activity pattern analysis, 
and occupancy modeling. However, handling and analyzing this data can be complex 
and time-consuming.

## The Need for Simplification
Processing and analyzing camera trap data in R often requires multiple steps, 
from cleaning raw data to statistical modeling and visualization. The **ct** 
R package addresses these challenges by providing a **modern, tidyverse-friendly workflow** 
for camera trap data analysis. Using **tidy evaluation principles**, it enables 
users to efficiently manipulate and transform datasets. Additionally, it integrates 
seamlessly with **ggplot2**, allowing users to generate highly customizable 
visualizations.

## Key Features of maimer
- **Data Management & Standardization**: Functions like `ct_read()`, 
  `ct_standardize()`, and `ct_stack_df()` help streamline data preparation.
- **Manage media files**: The functions `ct_remove_hs()`, `ct_get_hs()`, 
  `ct_create_hs()`, `ct_app()`, etc help to read and write image metadata.
- **Data Cleaning & Validation**: Ensure data integrity with `ct_check_name()`, 
  `ct_check_location()`.
- **Flexible Data Transformation**: Convert raw camera trap data into formats 
  suited for different analyses (`ct_to_community()`, `ct_to_occupancy()`, `ct_to_time()`).
- **Ecological Analysis**:
  - **Diversity Metrics**: Calculate **alpha** and **beta diversity** with 
  `ct_alpha_diversity()` and `ct_dissimilarity()`, etc.
  - **Species Activity Overlap**: Estimate and visualize species overlap using 
  `ct_overlap_estimates()`, `ct_overlap_matrix()`, and `ct_plot_overlap()`.
  - **Temporal Analysis**: Explore species activity shifts over time with 
  `ct_temporal_shift()`.

**For a full overview of all available functions, please visit the [ct website](https://stangandaho.github.io/ct/reference/index.html)**

## Installation:
You can install 'ct' directly from GitHub:

```R
# Install pak firstly if not installed
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak", dependencies = TRUE)
}

# Install maimer from GitHub
remotes::install_github("stangandaho/ct")
```

## Code of conduct
Please note that this project is based on the [Contributor Covenant v2.1](https://github.com/stangandaho/ct/blob/main/CODE_OF_CONDUCT.md). 
By participating in this project you agree to abide by its terms.

## Getting help
If you encounter a clear bug, please file an [issue](https://github.com/stangandaho/ct/issues) with a minimal reproducible 
example. For questions and other discussion, please use [relevant section](https://github.com/stangandaho/ct/discussions).

## **Meta**
- I welcome [contributions](#) including bug reports.
- License: MIT
- Get [citation information](#) for maimer in R doing `citation("maimer")`.
- Please note that this project is released with a [Contributor Code of Conduct](#). By participating in this project you agree to abide by its terms.
