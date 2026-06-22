# Estimate abundance from Space-To-Event (STE) Data

Estimate abundance from camera trap data using the Space-To-Event (STE)
model.

## Usage

``` r
ct_fit_ste(
  data,
  deployment_data,
  sampling_frequency,
  sampling_length,
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

- sampling_frequency:

  Numeric. The number of seconds between the start of each sampling
  occasion.

- sampling_length:

  Numeric. The number of seconds to sample at each sampling occasion.

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

[`ct_fit_ise()`](https://stangandaho.github.io/ct/reference/ct_fit_ise.md),
[`ct_fit_tte()`](https://stangandaho.github.io/ct/reference/ct_fit_tte.md)

## Examples

``` r
data <- dplyr::tibble(
  cam = c(1,1,2,2,2),
  datetime = as.POSIXct(c("2026-01-02 12:00:00",
                        "2026-01-03 13:12:00",
                        "2026-01-02 12:00:00",
                        "2026-01-02 14:00:00",
                        "2026-01-03 16:53:42"),
                      tz = "Africa/Lagos"),
  count = c(1, 0, 2, 1, 2)
)
deployment_data <- dplyr::tibble(
  cam = c(1, 2, 2, 2),
  start = as.POSIXct(c("2025-12-01 15:00:00",
                       "2025-12-08 00:00:00",
                       "2026-01-01 00:00:00",
                       "2026-01-02 00:00:00"),
                     tz = "Africa/Lagos"),
  end = as.POSIXct(c("2026-01-05 00:00:00",
                     "2025-12-19 03:30:00",
                     "2026-01-01 05:00:00",
                     "2026-01-05 00:00:00"),
                   tz = "Africa/Lagos"),
  area = c(300, 200, 200, 450)
)
ct_fit_ste(data,
       deployment_data,
       sampling_frequency = 3600,
       sampling_length = 10,
       study_area = 1e6)
#> 
#> ── Space-To-Event (STE) Estimation ─────────────────────────────────────────────
#> ℹ Running data checks
#> [33ms]
#> 
#> ℹ Building sampling occasions...
#> ℹ Building encounter history...
#> ℹ Running data checks
#> ✔ Running data checks [35ms]
#> 
#> ℹ Building effort for each camera
#> ✔ Building effort for each camera [31ms]
#> 
#> ℹ Calculating censors
#> ✔ Calculating censors [19ms]
#> 
#> ℹ Calculating STE at each occasion
#> ✔ Calculating STE at each occasion [102ms]
#> 
#> ℹ Fitting model...
#> ✔ Estimation complete!
#> # A tibble: 1 × 4
#>       N    SE   LCI   UCI
#>   <dbl> <dbl> <dbl> <dbl>
#> 1  5.97  4.22  1.71  20.8
```
