# Fit the Random Encounter and Staying Time (REST / RAD-REST) model

Estimates animal density from camera-trap data **without individual
recognition** using the Random Encounter and Staying Time (REST) model
of Nakashima, Fukasawa & Samejima (2018) and its RAD-REST extension
(Nakashima et al. 2026). Parameters are estimated in a Bayesian
framework by MCMC sampling with nimble.

## Usage

``` r
ct_fit_rest(
  stay_data,
  station_data,
  activity_data,
  species,
  focal_area,
  model = c("REST", "RAD-REST"),
  stay_formula = Stay ~ 1,
  density_formula = ~1,
  passes_formula = ~1,
  stay_random_effect = NULL,
  stay_distribution = c("lognormal", "gamma", "weibull", "exponential"),
  activity_method = c("kernel", "mixture"),
  bandwidth_adjust = 1,
  mixture_components = 10,
  compare_models = FALSE,
  iterations = 5000,
  burnin = 1000,
  thin = 2,
  chains = 3,
  cores = 3,
  quiet = FALSE
)
```

## Arguments

- stay_data:

  Staying-time data, e.g. the output of
  [`ct_rest_stay()`](https://stangandaho.github.io/ct/reference/ct_rest_stay.md),
  with columns `Station`, `Species`, `Stay` (seconds) and `Cens` (1 =
  censored, 0 = fully observed).

- station_data:

  Per-station encounter and effort data, e.g. the output of
  [`ct_rest_effort()`](https://stangandaho.github.io/ct/reference/ct_rest_effort.md).
  For `model = "REST"` it must contain `Station`, `Species`, `Effort`
  (days) and `Y` (passes). For `model = "RAD-REST"` it must instead
  contain `N` (videos) and the `y_0`, `y_1`, ... pass-count columns.

- activity_data:

  Detection times in radians, e.g. the output of
  [`ct_rest_activity()`](https://stangandaho.github.io/ct/reference/ct_rest_activity.md),
  with columns `Species` and `time`.

- species:

  Single species name to analyse (must appear in the data).

- focal_area:

  Focal-area size in square metres. Either a single number (the same
  area at every camera) or the name of a column in `station_data` giving
  a camera-specific focal area per station.

- model:

  Either `"REST"` or `"RAD-REST"`.

- stay_formula:

  Model formula for staying time. The left-hand side names the
  staying-time column, e.g. `Stay ~ 1` or `Stay ~ 1 + habitat`.

- density_formula:

  One-sided formula for density covariates, e.g. `~ 1` or `~ habitat`.
  Density is latent, so the left-hand side is omitted.

- passes_formula:

  One-sided formula for the number of passes. Used only when
  `model = "RAD-REST"`; ignored otherwise.

- stay_random_effect:

  Optional column in `stay_data` giving a random effect on staying time.
  Default `NULL` (no random effect).

- stay_distribution:

  Distribution for staying time: one of `"lognormal"`, `"gamma"`,
  `"weibull"` or `"exponential"`. Ideally chosen with
  [`ct_rest_select_stay()`](https://stangandaho.github.io/ct/reference/ct_rest_select_stay.md).

- activity_method:

  How to estimate the activity proportion: `"kernel"` (fixed kernel
  density) or `"mixture"` (Bayesian von Mises mixture).

- bandwidth_adjust:

  Bandwidth multiplier for `activity_method = "kernel"`.

- mixture_components:

  Maximum number of von Mises components for
  `activity_method = "mixture"`.

- compare_models:

  If `TRUE`, fit every combination of the density covariates and rank
  them by WAIC. If `FALSE`, fit only `density_formula`.

- iterations, burnin, thin, chains, cores:

  MCMC settings: total iterations per chain, burn-in length, thinning
  interval, number of chains and CPU cores for parallel sampling.

- quiet:

  If `TRUE`, suppress progress messages.

## Value

An object of class `ct_rest` (a list) with:

- `waic`:

  A tibble ranking the candidate density models by WAIC.

- `summary`:

  A tibble of posterior summaries for density (individuals per km^2),
  mean staying time and, for RAD-REST, the mean number of passes.

- `samples`:

  A [`coda::mcmc.list`](https://rdrr.io/pkg/coda/man/mcmc.list.html) of
  posterior draws for the best model.

- `activity_curve`:

  (mixture only) the estimated activity density curve.

## Details

### The idea behind REST

A camera watches a small *focal area* of known size in front of the
lens. If we know (i) how often animals pass through that area, (ii) how
long they stay in it on average, and (iii) the fraction of the day they
are active, density follows from a simple flow argument. Intuitively,
the expected number of detected passes is

\$\$E\[Y\] = D \times S \times T \times p\_{act} / \bar{t}\$\$

where \\D\\ is density, \\S\\ the focal-area size, \\T\\ the survey
duration, \\p\_{act}\\ the activity proportion and \\\bar{t}\\ the mean
staying time. Re-arranging gives the density estimator \\D = Y\\\bar{t}
/ (S\\T\\p\_{act})\\. `ct_fit_rest()` fits every piece of this equation
jointly so that uncertainty propagates into the density estimate.

Three sub-models are combined:

- **Staying time** (`stay_data`): a survival model. Animals still in the
  focal area when the video ends are *right-censored*; the chosen
  `stay_distribution` (lognormal/gamma/weibull/exponential) handles
  this.

- **Encounters** (`station_data`): the number of passes `Y` per station
  is modelled as negative-binomial (REST), or, for RAD-REST, the number
  of videos showing 0,1,2,... passes is modelled with a
  Dirichlet-multinomial so that miscounting of passes is accounted for.

- **Activity** (`activity_data`): the active fraction of the day,
  estimated either by kernel density (Rowcliffe et al. 2014) or a
  Bayesian von Mises mixture (Nakashima et al. 2026).

## References

Nakashima, Y., Fukasawa, K. & Samejima, H. (2018) Estimating animal
density without individual recognition using information derived from
camera traps. *Journal of Applied Ecology*, 55, 735-744.

Nakashima, Y. et al. (2026) Reducing data-processing effort in
camera-trap density estimation: extending the REST model. *Methods in
Ecology and Evolution*.

## See also

[`ct_rest_stay()`](https://stangandaho.github.io/ct/reference/ct_rest_stay.md),
[`ct_rest_effort()`](https://stangandaho.github.io/ct/reference/ct_rest_effort.md),
[`ct_rest_activity()`](https://stangandaho.github.io/ct/reference/ct_rest_activity.md),
[`ct_rest_select_stay()`](https://stangandaho.github.io/ct/reference/ct_rest_select_stay.md)

## Examples

``` r
data(rest_detection)
data(rest_station)

# 1. Build the three inputs from raw detections (these steps run quickly)
stay <- ct_rest_stay(rest_detection, rest_station)
stations <- ct_rest_passes(rest_detection, rest_station, model = "REST")
stations <- ct_rest_effort(rest_detection, stations)
activity <- ct_rest_activity(rest_detection)

if (FALSE) { # \dontrun{
# 2. Fit REST for the focal species (requires the 'nimble' package)
fit <- ct_fit_rest(
  stay_data = stay,
  station_data  = stations,
  activity_data = activity,
  species = "Red duiker",
  focal_area = 3.0, # focal-area size in m^2
  model = "REST",
  stay_distribution = "lognormal",
  iterations = 3000, burnin = 1000, chains = 2, cores = 2
)
fit
fit$summary   # density (individuals per km^2) and mean staying time

# RAD-REST instead: use pass-classified station data
stations_rad <- ct_rest_effort(
  detection_data = rest_detection,
  station_data = ct_rest_passes(rest_detection, rest_station, model = "RAD-REST")
)

fit_rad <- ct_fit_rest(
  stay_data = stay,
  station_data  = stations_rad,
  activity_data = activity,
  species = "Red duiker",
  focal_area = 3.0,
  model = "RAD-REST"
)
} # }
```
