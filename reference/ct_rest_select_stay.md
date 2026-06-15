# Choose a staying-time distribution for REST by WAIC

Fits the REST staying-time survival sub-model under one or more
candidate distributions (and, optionally, covariate combinations) and
ranks them by WAIC, with a Bayesian p-value as a goodness-of-fit check.
Use the winning `stay_distribution` in
[`ct_fit_rest()`](https://stangandaho.github.io/ct/reference/ct_fit_rest.md).

## Usage

``` r
ct_rest_select_stay(
  stay_data,
  species,
  stay_formula = Stay ~ 1,
  stay_distribution = c("lognormal", "gamma", "weibull", "exponential"),
  stay_random_effect = NULL,
  compare_models = FALSE,
  iterations = 5000,
  burnin = 1000,
  thin = 4,
  chains = 3,
  cores = 3,
  quiet = FALSE
)
```

## Arguments

- stay_data:

  Staying-time data from
  [`ct_rest_stay()`](https://stangandaho.github.io/ct/reference/ct_rest_stay.md).

- species:

  Single species name to analyse.

- stay_formula:

  Staying-time formula, e.g. `Stay ~ 1` or `Stay ~ 1 + habitat`.

- stay_distribution:

  One or more of `"lognormal"`, `"gamma"`, `"weibull"`, `"exponential"`
  to compare.

- stay_random_effect:

  Optional column in `stay_data` for a random effect on staying time.
  Tidy-selected (string, bare name, or position).

- compare_models:

  If `TRUE`, also compare every covariate combination of `stay_formula`.

- iterations, burnin, thin, chains, cores:

  MCMC settings.

- quiet:

  If `TRUE`, suppress progress messages.

## Value

An object of class `ct_rest_stay` with a `waic` ranking tibble, a
`summary` of the mean staying time for the best model, and its
`samples`.

## See also

[`ct_fit_rest()`](https://stangandaho.github.io/ct/reference/ct_fit_rest.md)

## Examples

``` r
data(rest_detection)
data(rest_station)

stay <- ct_rest_stay(rest_detection, rest_station)

if (FALSE) { # \dontrun{
# Compare candidate staying-time distributions by WAIC (requires 'nimble')
ct_rest_select_stay(
  stay, species = "Red duiker",
  stay_distribution = c("lognormal", "gamma", "weibull"),
  iterations = 3000, burnin = 1000, chains = 2, cores = 2
)
} # }
```
