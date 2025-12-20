# Fit Random Encounter Model (REM)

Fits a random encounter model using observed data and trap rate
information. Automatically estimates detection radius, detection angle,
animal speed, and activity pattern models if not provided.

## Usage

``` r
ct_fit_rem(
  data,
  traprate_data,
  radius_model = NULL,
  angle_model = NULL,
  speed_model = NULL,
  activity_model = NULL,
  strata = NULL,
  time_of_day,
  n_bootstrap = 1000
)
```

## Arguments

- data:

  A data frame of observations, including distance, angle, speed, and
  time-of-day (in radians).

- traprate_data:

  A data frame created by
  [`ct_traprate_data()`](https://stangandaho.github.io/ct/reference/ct_traprate_data.md).

- radius_model:

  Optional. A detection function model for radius (distance) fitted
  using
  [`ct_fit_detmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_detmodel.md).

- angle_model:

  Optional. A detection function model for angle fitted using
  [`ct_fit_detmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_detmodel.md).

- speed_model:

  Optional. A model for movement speed fitted using
  [`ct_fit_speedmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_speedmodel.md).

- activity_model:

  Optional. An activity model fitted with
  [`activity::fitact()`](https://rdrr.io/pkg/activity/man/fitact.html).

- strata:

  Optional. A data frame of stratification information with columns
  `stratumID` and `area`.

- time_of_day:

  The column name (unquoted or as a string) representing time-of-day in
  radians.

- n_bootstrap:

  Number of bootstrap replicates for uncertainty estimation. Default is
  1000.

## Value

A data frame with columns:

- `parameters`: Model parameter name

- `estimate`: Estimated value

- `se`: Standard error

- `cv`: Coefficient of variation

- `lower_ci`: Lower bound of 95% confidence interval

- `upper_ci`: Upper bound of 95% confidence interval

## See also

[`ct_fit_speedmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_speedmodel.md),
[`ct_fit_detmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_detmodel.md),
[`ct_fit_activity()`](https://stangandaho.github.io/ct/reference/ct_fit_activity.md)

## Examples

``` r
# \donttest{
data("ctdp")
deployments <- ctdp$data$deployments
observations <- ctdp$data$observations %>%
  dplyr::filter(scientificName == "Vulpes vulpes") %>%
  # Add time of day
  dplyr::mutate(time_of_day = ct_to_radian(times = timestamp))

# Prepare trap rate data
trap_rate <- ct_traprate_data(observation_data = observations,
                              deployment_data = deployments,
                              deployment_column = deploymentID,
                              datetime_column = timestamp,
                              start = start, end = 'end'
)


# Fit REM
ct_fit_rem(data = observations,
           traprate_data = trap_rate,
           time_of_day = time_of_day)
#> ℹ Fitting radius model
#> ✔ Fitting radius model ... done
#> 
#> ℹ Fitting angle model
#> ✔ Fitting angle model ... done
#> 
#> ℹ Fitting speed model
#> ✔ Fitting speed model ... done
#> 
#> ℹ Fitting activity model
#> ✔ Fitting activity model ... done
#> 
#> ℹ Calculating density
#> ✔ Calculating density ... done
#> 
#> 
#> # A tibble: 7 × 8
#>   parameters     estimate     se    cv lower_ci upper_ci     n unit   
#>   <chr>             <dbl>  <dbl> <dbl>    <dbl>    <dbl> <int> <chr>  
#> 1 radius            4.18   0.886 0.212    2.44     5.91      4 m      
#> 2 angle            44.4   11.3   0.254    0.39     1.16      5 degree 
#> 3 active_speed      3.08   0.765 0.248    0.439    1.27      4 km/hour
#> 4 activity_level    0.243  0.076 0.313    0.094    0.392    15 none   
#> 5 overall_speed    17.9    7.17  0.4      0.045    0.37     NA km/day 
#> 6 trap_rate         0.441  0.119 0.271    0.239    0.635     3 n/day  
#> 7 density           6.66   3.54  0.532    2.50    17.7      NA n/km2  
# }
```
