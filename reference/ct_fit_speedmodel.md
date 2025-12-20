# Fit animal speed model

Fits a statistical model to estimate average movement speed of animals.
Used in the REM density estimation.

## Usage

``` r
ct_fit_speedmodel(
  formula = speed ~ 1,
  data,
  newdata = NULL,
  distance_unit = c("m", "km", "cm"),
  time_unit = c("second", "minute", "hour", "day"),
  ...
)
```

## Arguments

- formula:

  A formula indicating how speed should be modeled (e.g., `speed ~ 1`).

- data:

  A data frame containing speed observations.

- newdata:

  Optional new data to use for prediction.

- distance_unit:

  Unit of distance. One of `"m"`, `"km"`, `"cm"`.

- time_unit:

  Unit of time. One of `"second"`, `"minute"`, `"hour"`, `"day"`.

- ...:

  Additional arguments passed to
  [`sbd::sbm()`](https://rdrr.io/pkg/sbd/man/sbm.html).

## Value

An object of class `sbm`, with an additional `unit` attribute indicating
the speed unit.

## See also

[`ct_fit_rem()`](https://stangandaho.github.io/ct/reference/ct_fit_rem.md),
[`ct_fit_detmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_detmodel.md),
[`ct_fit_activity()`](https://stangandaho.github.io/ct/reference/ct_fit_activity.md)

## Examples

``` r
data("ctdp")
observations <- ctdp$data$observations %>%
  dplyr::filter(scientificName == "Vulpes vulpes")

ct_fit_speedmodel(speed ~ 1, data = observations)
#> Call:
#> speed ~ 1
#> 
#> Probability distribution:
#> none
#> 
#> Estimates:
#>         est        se       lcl     ucl
#> 1 0.8553514 0.2123973 0.4390527 1.27165
```
