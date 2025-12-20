# Fit activity model to time-of-day data

Fits kernel density to radian time-of-day data and estimates activity
level from this distribution. Optionally: 1. bootstraps the
distribution, in which case SEs and confidence limits are also stored
for activity level and PDF; 2. weights the distribution; 3. truncates
the distribution at given times.

## Usage

``` r
ct_fit_activity(
  time_of_day,
  weights = NULL,
  n_bootstrap = 1000,
  bandwidth = NULL,
  adjustment = 1,
  sample = c("none", "data", "model"),
  bounds = NULL,
  show = TRUE
)
```

## Arguments

- time_of_day:

  A numeric vector of radian time-of-day data

- weights:

  A numeric vector of weights for each dat value.

- n_bootstrap:

  Number of bootstrap iterations to perform. Ignored if sample=="none"

- bandwidth:

  Numeric value for kernel bandwidth. If NULL, calculated internally.

- adjustment:

  Numeric bandwidth adjustment multiplier.

- sample:

  Character string defining sampling method for bootstrapping errors
  (see details).

- bounds:

  A two-element vector defining radian bounds at which to truncate.

- show:

  Logical whether or not to show a progress bar while bootstrapping.

## Value

A list

## Details

When no `bounds` are given (default), a circular kernel distribution is
fitted using `dvmkern`. Otherwise, a normal kernel distribution is used,
truncated at the values of `bounds`, using `density2`.

The bandwidth adjustment multiplier `adj` is provided to allow
exploration of the effect of adjusting the internally calculated
bandwidth on accuracy of activity level estimates.

The alternative bootstrapping methods defined by `sample` are:

- `"none"`: no bootstrapping

- `"data"`: sample from the data

- `"model"`: sample from the fitted probability density distribution

It's generally better to sample from the data, but sampling from the
fitted distribution can sometimes provide more sensible confidence
intervals when the number of observations is very small.

## Examples

``` r
data("ctdp")
observations <- ctdp$data$observations %>%
  dplyr::filter(scientificName == "Vulpes vulpes") %>%
  # Add time of day
  ct_to_radian(times = timestamp)


fit_act <- ct_fit_activity(time_of_day = observations$time_radian,
                           sample = "model", n_bootstrap = 100)

# Access activity level estimation
fit_act$activity
#> # A tibble: 1 × 4
#>     act     se lower_ci upper_ci
#>   <dbl>  <dbl>    <dbl>    <dbl>
#> 1 0.243 0.0812    0.168    0.460
```
