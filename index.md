# Camera Trap R Package

## Overview

Camera traps are an essential tool for wildlife monitoring and
ecological research, especially for species identification, biodiversity
assessment, activity pattern analysis, occupancy modeling,
*density/abundance estimation*, and among other.

Processing and analyzing camera trap data in R often requires multiple
steps, from cleaning raw data to statistical modeling and visualization.
The **ct** R package addresses these challenges by providing a **modern,
tidyverse-friendly workflow**. It enables users to efficiently process
data, and estimate density or abundance with several (~6) documented
methods. Additionally, it integrates seamlessly with **ggplot2**,
allowing users to generate highly customizable visualizations.

## Key Features

The `ct` package provides a comprehensive suite of 60+ functions
covering the complete camera trap data analysis workflow. **Population
density estimation** is supported through Random Encounter Models,
(REM), Camera Trap Distance Sampling (CTDS) Time-To-Event (TTE),
Space-To-Event (STE), Instantaneous Sampling Estimator (ISE), and Random
Encounter and Staying Time (REST/RAD-REST). **Data management**
capabilities include filtering independent detections, timestamp
correction, and interactive spatial validation. **Community ecology**
functions enable activity pattern analysis, biodiversity index
assessment, and occupancy modeling input preparation. **Quality
control** tools include detecting temporal gaps, monitoring deployment
status, and taxonomic validation.

[![](https://raw.githubusercontent.com/stangandaho/ct/main/man/figures/ct_r_package_workflow.svg)](https://stangandaho.github.io/ct)

**For a full overview of all available functions, please visit the [ct
website](https://stangandaho.github.io/ct/reference/index.html)**

## Installation:

You can install *ct* directly from GitHub:

``` r

# Install pak firstly if not installed
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak", dependencies = TRUE)
}

# Install ct from GitHub
pak::pkg_install("stangandaho/ct")
```

## Code of conduct

Please note that this project is based on the [Contributor Covenant
v2.1](https://github.com/stangandaho/ct/blob/main/CODE_OF_CONDUCT.md).
By participating in this project you agree to abide by its terms.

## Getting help

If you encounter a clear bug, please file an
[issue](https://github.com/stangandaho/ct/issues) with a minimal
reproducible example. For questions and other discussion, please use
[relevant section](https://github.com/stangandaho/ct/discussions).

## Funding

The development of the ct package is supported by the R Consortium
Infrastructure Steering Committee (ISC) under grant 25-ISC-1-04. This
funding enables the creation of comprehensive statistical tools for
camera trap data analysis, including population density estimation
methods, and standardized data integration workflows.
