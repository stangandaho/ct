# Estimate abundance from Time-To-Event (TTE) Data

Estimate abundance from camera trap data using the Time-To-Event (TTE)
model.

## Usage

``` r
ct_fit_tte(
  data,
  deployment_data,
  viewshed_transit_time,
  periods_per_occasion,
  time_between_occasions,
  study_area,
  study_start = NULL,
  study_end = NULL,
  quiet = FALSE
)
```

## Arguments

- data:

  A tibble of camera trap detections. Must contain columns `cam`,
  `datetime`, and `count`.

- deployment_data:

  A tibble of camera deployments. Must contain columns `cam`, `start`,
  `end`, and `area`.

- viewshed_transit_time:

  Numeric. This is equal to the mean amount of time (in seconds)
  required for an animal to cross the average viewshed of a camera. It
  can be calculated in different ways depending on available
  information.

  For an animal with a movement speed of 30 m/hr passing through camera
  viewsheds of 300 m^2, 400 m^2, and 380 m^2, the sampling period can be
  approximated as:

  \$\$ \frac{\sqrt{\frac{1}{n}\sum\_{i=1}^{n} A_i}}{30/3600} \$\$

  where \\A_i\\ represents the camera viewshed areas (in m^2) and \\n\\
  is the number of cameras. The denominator is the animal speed
  converted from meters/hour to meters/second.

- periods_per_occasion:

  Numeric. Number of TTE sampling periods per sampling occasion.

- time_between_occasions:

  Numeric. Length of time between sampling occasions (in seconds),
  allowing animals to re-randomize.

- study_area:

  Numeric. The size of the total study area in the same units as the
  camera viewshed area.

- study_start:

  POSIXct. The start of the study. Defaults to the minimum start time in
  `deployment_data`.

- study_end:

  POSIXct. The end of the study. Defaults to the maximum end time in
  `deployment_data`.

- quiet:

  Logical. Suppress status messages? Defaults to FALSE.

## Value

A data.frame with the estimated abundance (`N`), its standard error
(`SE`), and confidence intervals.

## References

Moeller, A. K. and P. M. Lukacs. 2021. spaceNtime: an R package for
estimating abundance of unmarked animals using camera-trap photographs.
Mammalian Biology.
[doi:10.1007/s42991-021-00181-8](https://doi.org/10.1007/s42991-021-00181-8)

Moeller, A. K., P. M. Lukacs, and J. Horne. 2018. Three novel methods to
estimate abundance of unmarked animals using remote cameras. Ecosphere
9(8): e02331. [doi:10.1002/ecs2.2331](https://doi.org/10.1002/ecs2.2331)

## See also

[`ct_fit_ste()`](https://stangandaho.github.io/ct/reference/ct_fit_ste.md),
[`ct_fit_ise()`](https://stangandaho.github.io/ct/reference/ct_fit_ise.md)

## Examples

``` r
data <- dplyr::tibble(
  cam = c(1, 1, 2, 2, 2),
  datetime = as.POSIXct(
    c(
      "2026-01-02 12:00:00",
      "2026-01-03 13:12:00",
      "2026-01-02 12:00:00",
      "2026-01-02 14:00:00",
      "2026-01-03 16:53:42"
    ),
    tz = "Africa/Lagos"
  ),
  count = c(1, 0, 2, 1, 2)
)
deployment_data <- dplyr::tibble(
  cam = c(1, 2, 2, 2),
  start = as.POSIXct(
    c(
      "2025-12-01 15:00:00",
      "2025-12-08 00:00:00",
      "2026-01-01 00:00:00",
      "2026-01-02 00:00:00"
    ),
    tz = "Africa/Lagos"
  ),
  end = as.POSIXct(
    c(
      "2026-01-05 00:00:00",
      "2025-12-19 03:30:00",
      "2026-01-01 05:00:00",
      "2026-01-05 00:00:00"
    ),
    tz = "Africa/Lagos"
  ),
  area = c(300, 200, 200, 450)
)
ct_fit_tte(data,
       deployment_data,
       viewshed_transit_time = sqrt(mean(deployment_data$area))/(30/3600),
       periods_per_occasion = 24,
       time_between_occasions = 2 * 3600,
       study_area = 1e6)
#> 
#> ── Time-To-Event (TTE) Estimation ──────────────────────────────────────────────
#> ℹ Running data checks
#> [33ms]
#> 
#> ℹ Building sampling occasions...
#> ℹ Building encounter history...
#> ℹ Running data checks
#> ✔ Running data checks [35ms]
#> 
#> ℹ Building effort for each camera
#> ✔ Building effort for each camera [30ms]
#> 
#> ℹ Calculating TTE and censor
#> ✔ Calculating TTE and censor [29ms]
#> 
#> ℹ Fitting model...
#> ✔ Estimation complete!
#> # A tibble: 1 × 4
#>       N    SE   LCI   UCI
#>   <dbl> <dbl> <dbl> <dbl>
#> 1  4.03  2.33  1.41  11.5
```
