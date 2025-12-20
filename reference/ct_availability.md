# Temporal availability adjustment

Calculates availability correction factors by accounting for temporal
variation in animal activity patterns and camera deployment effort. The
availability rate represents the proportion of time animals are
available for detection (Rowcliffe, et al., 2014; Howe et al., 2017)
given their activity patterns and camera sampling effort.

## Usage

``` r
ct_availability(
  times,
  format = NULL,
  sample = c("data", "model"),
  n_bootstrap = 1000,
  cam_daily_effort = 24,
  ...
)
```

## Arguments

- times:

  Vector of detection times, either in radians (0 - \\2\*pi\\) or
  formatted times (see `format` parameter).

- format:

  Time format string (e.g., "%H:%M:%S", "%H:%M") if times need
  conversion to radians. Set to NULL if times are already in radians.

- sample:

  Character string defining sampling method for bootstrapping errors
  (see details).

- n_bootstrap:

  Number of bootstrap iterations to perform. Ignored if sample=="none"

- cam_daily_effort:

  Daily operational hours of cameras (default = 24 for continuous
  operation).

- ...:

  Arguments passed on to
  [`ct_fit_activity`](https://stangandaho.github.io/ct/reference/ct_fit_activity.md)

  `weights`

  :   A numeric vector of weights for each dat value.

  `bandwidth`

  :   Numeric value for kernel bandwidth. If NULL, calculated
      internally.

  `adjustment`

  :   Numeric bandwidth adjustment multiplier.

  `bounds`

  :   A two-element vector defining radian bounds at which to truncate.

  `show`

  :   Logical whether or not to show a progress bar while bootstrapping.

## Value

A list containing data frame with:

- `rate`: Estimated availability rate (0-1)

- `SE`: Standard error of the availability rate

## References

Howe, E. J., Buckland, S. T., Després-Einspenner, M. L., & Kühl, H. S.
(2017). Distance sampling with camera traps. Methods in Ecology and
Evolution, 8(11), 1558-1565.
[doi:10.1111/2041-210X.12790](https://doi.org/10.1111/2041-210X.12790)

Rowcliffe, J. M., Kays, R., Kranstauber, B., Carbone, C., & Jansen, P.
A. (2014). Quantifying levels of animal activity using camera trap data.
Methods in Ecology and Evolution, 5(11), 1170-1179.
[doi:10.1111/2041-210X.12278](https://doi.org/10.1111/2041-210X.12278)

## See also

[`ct_fit_activity()`](https://stangandaho.github.io/ct/reference/ct_fit_activity.md)

## Examples

``` r
# \donttest{
# Example with times already in radians
radian_times <- c(1.2, 3.4, 5.1, 0.5, 2.8)
ct_availability(radian_times, sample = "data")
#> Warning: max(dat) < 1, expecting radian data
#> Warning: max(dat) < 1, expecting radian data
#> $creation
#>        rate         SE
#> 1 0.4614052 0.08683349
#> 

# Example with formatted times
time_strings <- c("06:30", "18:15", "12:00", "23:45")
ct_availability(time_strings, sample = "data", format = "%H:%M")
#> $creation
#>        rate        SE
#> 1 0.9499413 0.2171634
#> 

# With bootstrap resampling
ct_availability(radian_times, sample = "data", n_bootstrap = 100)
#> $creation
#>        rate         SE
#> 1 0.4614052 0.07927602
#> 
# }
```
