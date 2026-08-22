# Fit a conditional encounter-response model for camera-trap events

Estimates whether encounters of a response species become more or less
likely in the minutes to hours after encounters of a trigger species at
the same camera. Unlike a diel overlap coefficient – which only compares
two species' marginal activity curves – this is a directed, time-lagged
association: it contrasts the response encounter rate in successive
windows after a trigger with that camera's expected rate at the same
time of day and month. It quantifies association, not causation.

## Usage

``` r
ct_fit_encounter_response(
  data,
  deployment,
  trigger,
  response,
  species_column,
  cam_column,
  datetime_column,
  start_column,
  end_column,
  interval = 15 * 60,
  lag_breaks = c(0, 30 * 60, 2 * 3600, 6 * 3600),
  independence = 2 * 60,
  engine = c("glm", "glmm"),
  n_boot = NULL,
  interval_sensitivity = NULL,
  seed = NULL
)
```

## Arguments

- data:

  A data frame with one row per camera-trap record (the observation
  data).

- deployment:

  A data frame of actual camera deployment intervals. It must contain
  the camera ID, start, and end columns. Intervals for the same camera
  may not overlap.

- trigger:

  Character scalar naming the species whose event initiates a response
  window.

- response:

  Character scalar naming the species whose encounter rate is modelled.

- species_column:

  Unquoted column in `data` giving the species name.

- cam_column:

  Unquoted column giving the camera ID. This column must be present,
  with the same name, in both `data` and `deployment` so that records
  can be matched to their deployment intervals.

- datetime_column:

  Unquoted column in `data` giving the event date-time.

- start_column, end_column:

  Unquoted columns in `deployment` giving the deployment interval start
  and end date-times respectively.

- interval:

  Width of analysis intervals in seconds. It must not exceed the
  narrowest response-lag window.

- lag_breaks:

  Numeric vector of lag boundaries in seconds. The default estimates
  associations for 0–30 minutes, 30 minutes–2 hours, and 2–6 hours after
  a trigger. Time after the final boundary is the reference.

- independence:

  Minimum number of seconds between retained records of the same species
  at the same camera. Defaults to 2 minutes; set to `0` to retain every
  record. See Details for why this default is smaller than the value
  used for activity-level estimation.

- engine:

  Fitting engine. `"glm"` (default) fits a camera-stratified
  quasi-Poisson GLM with camera fixed effects and a camera-block
  bootstrap. `"glmm"` fits a Poisson/negative-binomial mixed model with
  camera (and, where present, deployment) random intercepts, using
  glmmTMB if installed and otherwise lme4.

- n_boot:

  Number of camera-block bootstrap replicates used for percentile
  confidence intervals. If `NULL` (default) it is set to 199 for
  `engine = "glm"` and to 0 for `engine = "glmm"`. Set to `0` to return
  model-based intervals only.

- interval_sensitivity:

  Optional numeric vector of alternative `interval` widths (seconds).
  When supplied, the lag-specific rate ratios are refitted at each width
  and returned in `$sensitivity`, so the reader can judge how far the
  conclusion depends on the binning choice. Each value must not exceed
  the narrowest lag window.

- seed:

  Optional integer seed for the bootstrap.

## Value

An object of class `ct_encounter_response` containing the fitted model,
lag-specific rate ratios, analysis-interval data, an optional bin-width
sensitivity table, and settings. A rate ratio below one indicates fewer
response encounters than expected after a trigger, conditional on the
fitted baseline terms.

## Details

**What is being approximated.** The quantity of interest – "does an
encounter of species A raise or lower the short-term encounter intensity
of species B?" – is formally a *mutually exciting (Hawkes-type) point
process*. Fitting such a process directly is data-hungry and fragile
with sparse camera-trap detections, so this function uses a transparent
discrete-time approximation: camera uptime is sliced into short
intervals, the number of response detections per interval is modelled as
a count, and time-since-last-trigger is entered as a step function
(`lag_breaks`). Because it is an approximation, the interval width
matters – always inspect `interval_sensitivity` before interpreting an
effect.

**How confounders are handled.** Camera uptime enters as an offset so
unequal effort is accounted for; circular (harmonic) terms hold the
shared diel activity curve constant; a month factor absorbs broad
seasonal variation; and each camera contributes only *within-camera*
temporal contrasts, so time-invariant differences in habitat, placement
and baseline abundance are differenced out. With `engine = "glm"`
cameras are fixed effects; with `engine = "glmm"` they are random
intercepts (partial pooling), which is more efficient with many sparse
cameras and avoids the incidental-parameter problem of many fixed
effects.

**Inference.** Successive intervals at one camera are serially
correlated and response detections cluster in time. A quasi-Poisson
dispersion correction rescales for overdispersion but *not* for this
autocorrelation, so model-based intervals from `engine = "glm"` are
optimistic. The default inference is therefore a **camera-block
bootstrap** (`n_boot`), which resamples whole cameras and so respects
within-camera dependence; treat those intervals as the primary
uncertainty. With `engine = "glmm"` the camera random effect already
propagates between-camera variance, so the bootstrap is skipped.

**The dominant limitation – shared transient drivers.** The controls
above remove *stable* and *diel/seasonal* confounding, but they cannot
remove *episodic* shared drivers: a fruiting tree, a waterhole, a prey
pulse, moonlight or a weather front can draw both species independently
within the same hours and manufacture an apparent "response" with no
behavioural interaction whatsoever. Detection is also a thinned,
imperfect observation of presence, so a shift in detection rate need not
reflect a shift in true site use. For these reasons the result is an
*association conditional on the fitted baseline*, never evidence of a
direct behavioural or causal effect. Corroborate with randomization or
simulation checks, and never treat deployments reconstructed from
first/last detections as camera uptime.

**Independence filtering.** `independence` collapses repeat detections
of the same species at the same camera that fall within a short window –
these are usually one animal lingering in front of the sensor, i.e. one
biological event. Note the tension with this model: unlike
activity-level estimation (where 30 min is conventional), a long filter
here would erase exactly the rapid successive detections that a
short-term response would produce. The default is therefore deliberately
small (2 minutes): long enough to merge a single pass into one event,
short enough to preserve genuine reactivity in the first lag window. Set
`independence = 0` to keep every record.

## References

Hawkes, A. G. (1971). Spectra of some self-exciting and mutually
exciting point processes. *Biometrika*, 58(1), 83–90.
[doi:10.1093/biomet/58.1.83](https://doi.org/10.1093/biomet/58.1.83)

Ridout, M. S., & Linkie, M. (2009). Estimating overlap of daily activity
patterns from camera trap data. *Journal of Agricultural, Biological,
and Environmental Statistics*, 14(3), 322–337.
[doi:10.1198/jabes.2009.08038](https://doi.org/10.1198/jabes.2009.08038)

## Examples

``` r
if (FALSE) { # \dontrun{
data(ACBR)
fit <- ct_fit_encounter_response(
  data = ACBR$acbr_data,
  deployment = ACBR$deployment,
  trigger = "Cercopithecus mona", response = "Tragelaphus spekii",
  species_column = species, cam_column = cam, datetime_column = datetime,
  start_column = start, end_column = end
)
summary(fit)

# Random-effects engine plus a bin-width sensitivity check
fit_glmm <- ct_fit_encounter_response(
  data = ACBR$acbr_data,
  deployment = ACBR$deployment,
  trigger = "Cercopithecus mona", response = "Tragelaphus spekii",
  species_column = species, cam_column = cam, datetime_column = datetime,
  start_column = start, end_column = end,
  engine = "glmm",
  interval_sensitivity = c(5 * 60, 10 * 60, 30 * 60)
)
fit_glmm$sensitivity
} # }
```
