# Package index

## Data examples

- [`pendjari`](https://stangandaho.github.io/ct/reference/pendjari.md) :
  Pendjari national park and surrounding areas
- [`ctdp`](https://stangandaho.github.io/ct/reference/ctdp.md) : Camera
  trap data package example
- [`duikers`](https://stangandaho.github.io/ct/reference/duikers.md) :
  Maxwell's duiker camera-trap distance & video-start data

## Process media (images) file

Functions reading and writing metadata

- [`ct_app()`](https://stangandaho.github.io/ct/reference/ct_app.md) :
  Run App
- [`ct_install_exiftool()`](https://stangandaho.github.io/ct/reference/ct_install_exiftool.md)
  : Install ExifTool, downloading (by default) the current version
- [`ct_read_metadata()`](https://stangandaho.github.io/ct/reference/ct_read_metadata.md)
  : Read Image Metadata
- [`ct_exiftool_call()`](https://stangandaho.github.io/ct/reference/ct_exiftool_call.md)
  : Call ExifTool
- [`ct_get_hs()`](https://stangandaho.github.io/ct/reference/ct_get_hs.md)
  : Retrieve hierarchical subject (hs) values from image metadata
- [`ct_create_hs()`](https://stangandaho.github.io/ct/reference/ct_create_hs.md)
  : Create or add hierarchical subject (hs) values in image metadata
- [`ct_remove_hs()`](https://stangandaho.github.io/ct/reference/ct_remove_hs.md)
  : Remove hierarchical subject (hs) values from image metadata
- [`ct_clone_dir()`](https://stangandaho.github.io/ct/reference/ct_clone_dir.md)
  : Clone directory structure

## Data processing

Functions for preparing and tansforming camera trap data

- [`ct_read()`](https://stangandaho.github.io/ct/reference/ct_read.md) :
  Read a delimited file into a tibble

- [`ct_stack_df()`](https://stangandaho.github.io/ct/reference/ct_stack_df.md)
  : Stack a list of data frame

- [`ct_check_location()`](https://stangandaho.github.io/ct/reference/ct_check_location.md)
  : Interactive camera trap location adjustment

- [`ct_survey_design()`](https://stangandaho.github.io/ct/reference/ct_survey_design.md)
  : Create a survey design for camera trap deployment

- [`ct_independence()`](https://stangandaho.github.io/ct/reference/ct_independence.md)
  : Evaluate independent detections

- [`ct_to_radian()`](https://stangandaho.github.io/ct/reference/ct_to_radian.md)
  : Convert time to radians

- [`ct_solartime()`](https://stangandaho.github.io/ct/reference/ct_solartime.md)
  : Transform time to solar time anchored to sunrise and sunset

- [`ct_to_time()`](https://stangandaho.github.io/ct/reference/ct_to_time.md)
  : Convert radian to time

- [`ct_to_community()`](https://stangandaho.github.io/ct/reference/ct_to_community.md)
  : Convert data to a community matrix

- [`ct_standardize()`](https://stangandaho.github.io/ct/reference/ct_standardize.md)
  : Standardize community data matrix

- [`ct_check_name()`](https://stangandaho.github.io/ct/reference/ct_check_name.md)
  : Check species name and retrieve Taxonomic Serial Number (TSN) from
  ITIS

- [`ct_to_occupancy()`](https://stangandaho.github.io/ct/reference/ct_to_occupancy.md)
  : Convert camera trap data to occupancy format

- [`ct_find_break()`](https://stangandaho.github.io/ct/reference/ct_find_break.md)
  : Detect time gaps in a datetime series

- [`ct_correct_datetime()`](https://stangandaho.github.io/ct/reference/ct_correct_datetime.md)
  : Correct camera trap datetime records

- [`ct_get_effort()`](https://stangandaho.github.io/ct/reference/ct_get_effort.md)
  : Calculate camera trap deployment effort

- [`ct_traprate_data()`](https://stangandaho.github.io/ct/reference/ct_traprate_data.md)
  : Prepare data for trap rate estimation

- [`ct_dp_read()`](https://stangandaho.github.io/ct/reference/ct_dp_read.md)
  : Read camera trap data package

- [`ct_dp_table()`](https://stangandaho.github.io/ct/reference/ct_dp_table.md)
  : Get core tables

- [`ct_dp_example()`](https://stangandaho.github.io/ct/reference/ct_dp_example.md)
  : Read the Camtrap DP example dataset

- [`ct_dp_version()`](https://stangandaho.github.io/ct/reference/ct_dp_version.md)
  :

  Get Camtrap DP version Extracts the version number used by a Camera
  Trap Data Package object. This version number indicates what version
  of the [Camtrap DP standard](https://camtrap-dp.tdwg.org) was used.

- [`ct_dp_filter()`](https://stangandaho.github.io/ct/reference/ct_dp_filter.md)
  : Filter camera trap data package

- [`ct_convert_unit()`](https://stangandaho.github.io/ct/reference/ct_convert_unit.md)
  : Convert values between different units

- [`ct_camera_day()`](https://stangandaho.github.io/ct/reference/ct_camera_day.md)
  : Calculate daily camera trap captures

- [`ct_camtrap_animal_distance()`](https://stangandaho.github.io/ct/reference/ct_camtrap_animal_distance.md)
  : Estimate distance from camera trap to animal

## Data analysis

Functions to run common camera trap data analysis

- [`ct_describe_df()`](https://stangandaho.github.io/ct/reference/ct_describe_df.md)
  : Descriptive statistic on dataset
- [`ct_plot_density()`](https://stangandaho.github.io/ct/reference/ct_plot_density.md)
  : Plot species' activity patterns
- [`ct_plot_overlap()`](https://stangandaho.github.io/ct/reference/ct_plot_overlap.md)
  : Plot overlap between two species' activity patterns
- [`ct_plot_overlap_coef()`](https://stangandaho.github.io/ct/reference/ct_plot_overlap_coef.md)
  : Plot overlap coefficient matrix
- [`ct_plot_rose_diagram()`](https://stangandaho.github.io/ct/reference/ct_plot_rose_diagram.md)
  : Plot a 24-hour rose diagram of daily activity
- [`ct_plot_camtrap_activity()`](https://stangandaho.github.io/ct/reference/ct_plot_camtrap_activity.md)
  : Plot camera trap activity over time
- [`ct_plot_inext()`](https://stangandaho.github.io/ct/reference/ct_plot_inext.md)
  : Plot diversity interploation and extrapolation
- [`ct_overlap_estimates()`](https://stangandaho.github.io/ct/reference/ct_overlap_estimates.md)
  : Estimates of coefficient of overlapping
- [`ct_bootstrap()`](https://stangandaho.github.io/ct/reference/bootstrap.md)
  [`ct_resample()`](https://stangandaho.github.io/ct/reference/bootstrap.md)
  [`ct_boot_estimates()`](https://stangandaho.github.io/ct/reference/bootstrap.md)
  : Generate bootstrap estimates of overlap
- [`ct_boot_ci()`](https://stangandaho.github.io/ct/reference/ct_boot_ci.md)
  : Bootstrap confidence intervals
- [`ct_ci()`](https://stangandaho.github.io/ct/reference/ct_ci.md) :
  Calculate confidence interval
- [`ct_overlap_matrix()`](https://stangandaho.github.io/ct/reference/ct_overlap_matrix.md)
  : Estimate overlap coefficients for multiple species
- [`ct_temporal_shift()`](https://stangandaho.github.io/ct/reference/ct_temporal_shift.md)
  : Calculate the temporal shift of one species' activity over two
  periods
- [`ct_alpha_diversity()`](https://stangandaho.github.io/ct/reference/ct_alpha_diversity.md)
  : Alpha diversity index
- [`ct_dissimilarity()`](https://stangandaho.github.io/ct/reference/ct_dissimilarity.md)
  : Calculate dissimilarity between communities
- [`ct_spatial_coverage()`](https://stangandaho.github.io/ct/reference/ct_spatial_coverage.md)
  : Calculate observed spatial coverage of species
- [`ct_summarise_camtrap_activity()`](https://stangandaho.github.io/ct/reference/ct_summarise_camtrap_activity.md)
  : Create activity summary statistics
- [`ct_traprate_estimate()`](https://stangandaho.github.io/ct/reference/ct_traprate_estimate.md)
  : Estimate trap rate
- [`ct_fit_activity()`](https://stangandaho.github.io/ct/reference/ct_fit_activity.md)
  : Fit activity model to time-of-day data
- [`ct_fit_speedmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_speedmodel.md)
  : Fit animal speed model
- [`ct_fit_detmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_detmodel.md)
  : Fit animal detection
- [`ct_fit_rem()`](https://stangandaho.github.io/ct/reference/ct_fit_rem.md)
  : Fit Random Encounter Model (REM)
- [`ct_availability()`](https://stangandaho.github.io/ct/reference/ct_availability.md)
  : Temporal availability adjustment
- [`ct_select_model()`](https://stangandaho.github.io/ct/reference/ct_select_model.md)
  : Model selection for Distance Sampling detection functions
- [`ct_QAIC()`](https://stangandaho.github.io/ct/reference/ct_QAIC.md) :
  Compute QAIC for a set of detection function models
- [`ct_chi2_select()`](https://stangandaho.github.io/ct/reference/ct_chi2_select.md)
  : Select best detection function model by Chi-squared Goodness-of-fit
- [`ct_fit_ds()`](https://stangandaho.github.io/ct/reference/ct_fit_ds.md)
  : Fit detection functions and estimate density/abundance
- [`ct_inext()`](https://stangandaho.github.io/ct/reference/ct_inext.md)
  : Interpolation and extrapolation of Hill number
