# ct 0.3.0

## 2025-08-09
- Added Distance Sampling functions:
  - `ct_fit_ds()` for fitting detection functions and estimating density/abundance.
  - `ct_availability()` for temporal availability corrections.
  - `ct_QAIC()`, `ct_chi2_select()`, and `ct_select_model()` for automated two-stage model selection.

- Added Camera Trap Data Package (Camtrap DP) integration:
  - `ct_dp_read()` to load Camtrap DP datasets from local files or URLs.
  - `ct_dp_table()` to access specific tables (`observations`, `deployments`, `media`, `events`, `taxa`).
  - `ct_dp_example()` to load example dataset.
  - `ct_dp_version()` to retrieve dataset standard version.
  - `ct_dp_filter()` to subset tables using `dplyr`-style filtering.

# ct 0.2.0

## 2025-07-29
Improved `ct_stack_df()` - C++ implementation for stacking a list of data 
frames.

## 2025-07-10
Added new functions to support trap rate and REM-based density estimation workflows: 
`ct_traprate_estimate()` estimates trap rates from detection data; `ct_fit_activity()` 
models diel activity patterns; `ct_fit_speedmodel()` fits animal movement speed 
models; `ct_fit_detmodel()` estimates detection probability functions; `ct_fit_rem()` 
applies the Random Encounter Model (REM) to estimate animal density; `ct_get_effort()` 
calculates sampling effort metrics such as camera-days; and `ct_traprate_data()` 
prepares detection and effort data for further analysis.

## 2025-06-26
- `ct_correct_datetime()` to correct datetime stamps in camera trap datasets 
using a deployment-specific correction table. Supports multiple datetime formats, 
offset directions.

## 2025-06-25
- `ct_plot_camtrap_activity()` function to visualize camera trap deployment 
activity with optional gap indicators.
- `ct_summarise_camtrap_activity()` function to compute summary statistics for camera 
trap deployment activity, including active durations, gaps, and activity rates, etc.


## 2025-06-24
- Improved handling of non-numeric variables in `ct_describe_df()`.
- Added support for detecting sampling breaks using `ct_find_break()`.
- Added function to compute confidence intervals (`ct_ci()` and `ct_lognorm_ci()`)
- Fixed NSE-related warnings

## First Release Highlights
- Initial release of **maimer**
- Provides **tidyverse-friendly** functions for data cleaning, transformation, and visualization.
- Includes support for **alpha & beta diversity**, **species activity overlap**, and **temporal analysis**.
- Integrates with **ggplot2** for customizable visualizations.
- Features an interactive **Shiny app** for image metadata handling
