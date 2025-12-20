# Estimate trap rate

Computes the estimated trap rate and uncertainty using bootstrapping,
with optional support for stratified estimation based on area-weighted
averaging.

## Usage

``` r
ct_traprate_estimate(data, strata = NULL, n_bootstrap = 1000)
```

## Arguments

- data:

  A data frame as returned by
  [`ct_traprate_data()`](https://stangandaho.github.io/ct/reference/ct_traprate_data.md)
  with columns `n` and `effort`.

- strata:

  Optional. A data frame defining strata, with columns `stratumID` and
  `area`.

- n_bootstrap:

  Number of bootstrap replicates to estimate uncertainty. Default is
  1000.

## Value

A data frame with the following columns:

- `estimate`: Trap rate estimate (e.g., detections per day)

- `se`: Standard error of the estimate

- `cv`: Coefficient of variation

- `lower_ci`: Lower bound of the 95\\

- `upper_ci`: Upper bound of the 95\\

- `n`: Number of deployments or observation used

- `unit`: Effort unit

## See also

[`ct_get_effort()`](https://stangandaho.github.io/ct/reference/ct_get_effort.md),
[`ct_traprate_data()`](https://stangandaho.github.io/ct/reference/ct_traprate_data.md)

## Examples

``` r
data("ctdp")
deployments <- ctdp$data$deployments
observations <- ctdp$data$observations %>%
                  dplyr::filter(scientificName == "Vulpes vulpes")

trap_rate <- ct_traprate_data(observation_data = observations,
                              deployment_data = deployments,
                              use_deployment = FALSE,
                              deployment_column = deploymentID,
                              datetime_column = timestamp,
                              start = start, end = 'end'
)

ct_traprate_estimate(data = trap_rate, n_bootstrap = 1000)
#>            estimate        se        cv  lower_ci upper_ci n   unit
#> trap_rate 0.6206041 0.1829947 0.2948655 0.2985075 1.020408 3 n/days
```
