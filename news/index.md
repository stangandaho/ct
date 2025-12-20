# Changelog

## ct 0.3.0

### 2025-08-09

- Added Distance Sampling functions:
  - [`ct_fit_ds()`](https://stangandaho.github.io/ct/reference/ct_fit_ds.md)
    for fitting detection functions and estimating density/abundance.
  - [`ct_availability()`](https://stangandaho.github.io/ct/reference/ct_availability.md)
    for temporal availability corrections.
  - [`ct_QAIC()`](https://stangandaho.github.io/ct/reference/ct_QAIC.md),
    [`ct_chi2_select()`](https://stangandaho.github.io/ct/reference/ct_chi2_select.md),
    and
    [`ct_select_model()`](https://stangandaho.github.io/ct/reference/ct_select_model.md)
    for automated two-stage model selection.
- Added Camera Trap Data Package (Camtrap DP) integration:
  - [`ct_dp_read()`](https://stangandaho.github.io/ct/reference/ct_dp_read.md)
    to load Camtrap DP datasets from local files or URLs.
  - [`ct_dp_table()`](https://stangandaho.github.io/ct/reference/ct_dp_table.md)
    to access specific tables (`observations`, `deployments`, `media`,
    `events`, `taxa`).
  - [`ct_dp_example()`](https://stangandaho.github.io/ct/reference/ct_dp_example.md)
    to load example dataset.
  - [`ct_dp_version()`](https://stangandaho.github.io/ct/reference/ct_dp_version.md)
    to retrieve dataset standard version.
  - [`ct_dp_filter()`](https://stangandaho.github.io/ct/reference/ct_dp_filter.md)
    to subset tables using `dplyr`-style filtering.

## ct 0.2.0

### 2025-07-29

Improved
[`ct_stack_df()`](https://stangandaho.github.io/ct/reference/ct_stack_df.md) -
C++ implementation for stacking a list of data frames.

### 2025-07-10

Added new functions to support trap rate and REM-based density
estimation workflows:
[`ct_traprate_estimate()`](https://stangandaho.github.io/ct/reference/ct_traprate_estimate.md)
estimates trap rates from detection data;
[`ct_fit_activity()`](https://stangandaho.github.io/ct/reference/ct_fit_activity.md)
models diel activity patterns;
[`ct_fit_speedmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_speedmodel.md)
fits animal movement speed models;
[`ct_fit_detmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_detmodel.md)
estimates detection probability functions;
[`ct_fit_rem()`](https://stangandaho.github.io/ct/reference/ct_fit_rem.md)
applies the Random Encounter Model (REM) to estimate animal density;
[`ct_get_effort()`](https://stangandaho.github.io/ct/reference/ct_get_effort.md)
calculates sampling effort metrics such as camera-days; and
[`ct_traprate_data()`](https://stangandaho.github.io/ct/reference/ct_traprate_data.md)
prepares detection and effort data for further analysis.

### 2025-06-26

- [`ct_correct_datetime()`](https://stangandaho.github.io/ct/reference/ct_correct_datetime.md)
  to correct datetime stamps in camera trap datasets using a
  deployment-specific correction table. Supports multiple datetime
  formats, offset directions.

### 2025-06-25

- [`ct_plot_camtrap_activity()`](https://stangandaho.github.io/ct/reference/ct_plot_camtrap_activity.md)
  function to visualize camera trap deployment activity with optional
  gap indicators.
- [`ct_summarise_camtrap_activity()`](https://stangandaho.github.io/ct/reference/ct_summarise_camtrap_activity.md)
  function to compute summary statistics for camera trap deployment
  activity, including active durations, gaps, and activity rates, etc.

### 2025-06-24

- Improved handling of non-numeric variables in
  [`ct_describe_df()`](https://stangandaho.github.io/ct/reference/ct_describe_df.md).
- Added support for detecting sampling breaks using
  [`ct_find_break()`](https://stangandaho.github.io/ct/reference/ct_find_break.md).
- Added function to compute confidence intervals
  ([`ct_ci()`](https://stangandaho.github.io/ct/reference/ct_ci.md) and
  `ct_lognorm_ci()`)
- Fixed NSE-related warnings

### First Release Highlights

- Initial release of **maimer**
- Provides **tidyverse-friendly** functions for data cleaning,
  transformation, and visualization.
- Includes support for **alpha & beta diversity**, **species activity
  overlap**, and **temporal analysis**.
- Integrates with **ggplot2** for customizable visualizations.
- Features an interactive **Shiny app** for image metadata handling
