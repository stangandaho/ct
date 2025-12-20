# Fit detection functions and estimate density/abundance

`ct_fit_ds` fits detection functions to camera trap distance sampling
data and estimates animal density or abundance using bootstrap variance
estimation. Supports both single model fitting and automated model
selection procedures.

## Usage

``` r
ct_fit_ds(
  data,
  estimate = c("density", "abundance"),
  cutpoints = NULL,
  truncation = set_truncation(data = data, cutpoints = cutpoints),
  formula = ~1,
  key = c("hn", "hr", "unif"),
  adjustment = c("cos", "herm", "poly"),
  nadj = NULL,
  order = NULL,
  select_model = FALSE,
  model_params = list(key = list("hn", "hr", "unif"), adjustment = list("cos", "herm",
    "poly"), nadj = list(0, 1, 2), order = NULL),
  availability,
  n_bootstrap = 100,
  n_cores = 1,
  ...
)
```

## Arguments

- data:

  A data frame containing distance sampling observations. Must include
  following columns:

  - `distance`: the midpoint (m) of the assigned distance interval
    between animal and camera

  - `object`: a unique identifier for each observation

  - `Sample.Label`: identifier for the sample (transect id)

  - `Effort`: number of a given second (e.g 0.25, 2, or 3) time steps
    the camera operated (i.e. temporal effort)

  - `Region.Label`: label for a given stratum

  - `Area`: area of the strata⁠ in km^2

  - `fraction`: fraction of a full circle covered (field of view/360)
    Other columns could be used as covariate. Note that in the simplest
    case (one area surveyed only once) there is only one Region.Label
    and a single corresponding Area duplicated for each observation.

- estimate:

  Character string specifying the parameter to estimate. Either
  `"density"` (animals per km^2) or `"abundance"` (total number of
  animals). Default is `"density"`.

- cutpoints:

  if the data are binned, this vector gives the cutpoints of the bins.
  Supplying a distance column in your data and specifying cutpoints is
  the recommended approach for all standard binned analyses. Ensure that
  the first element is 0 (or the left truncation distance) and the last
  is the distance to the end of the furthest bin. (Default `NULL`, no
  binning.) If you have provided `distbegin` and `distend` columns in
  your data (note this should only be used when your cutpoints are not
  constant across all your data, e.g. planes flying at differing
  altitudes) then do not specify the cutpoints argument as this will
  cause the `distbegin` and `distend` columns in your data to be
  overwritten.

- truncation:

  either truncation distance (numeric, e.g. 5) or percentage (as a
  string, e.g. "15%"). Can be supplied as a `list` with elements `left`
  and `right` if left truncation is required (e.g.
  `list(left=1,right=20)` or `list(left="1%",right="15%")` or even
  `list(left="1",right="15%")`). By default for exact distances the
  maximum observed distance is used as the right truncation. When the
  data is binned, the right truncation is the largest bin end point.
  Default left truncation is set to zero.

- formula:

  formula for the scale parameter. For a CDS analysis leave this as its
  default `~1`.

- key:

  key function to use; `"hn"` gives half-normal (default), `"hr"` gives
  hazard-rate and `"unif"` gives uniform. Note that if uniform key is
  used, covariates cannot be included in the model.

- adjustment:

  adjustment terms to use; `"cos"` gives cosine (default), `"herm"`
  gives Hermite polynomial and `"poly"` gives simple polynomial. A value
  of `NULL` indicates that no adjustments are to be fitted.

- nadj:

  the number of adjustment terms to fit. In the absence of covariates in
  the formula, the default value (`NULL`) will select via AIC (using a
  sequential forward selection algorithm) up to `max.adjustment`
  adjustments (unless `order` is specified). When covariates are present
  in the model formula, the default value of `NULL` results in no
  adjustment terms being fitted in the model. A non-negative integer
  value will cause the specified number of adjustments to be fitted.
  Supplying an integer value will allow the use of adjustment terms in
  addition to specifying covariates in the model. The order of
  adjustment terms used will depend on the `key`and `adjustment`. For
  `key="unif"`, adjustments of order 1, 2, 3, ... are fitted when
  `adjustment = "cos"` and order 2, 4, 6, ... otherwise. For `key="hn"`
  or `"hr"` adjustments of order 2, 3, 4, ... are fitted when
  `adjustment = "cos"` and order 4, 6, 8, ... otherwise. See Buckland et
  al. (2001, p. 47) for details.

- order:

  order of adjustment terms to fit. The default value (`NULL`) results
  in `ds` choosing the orders to use - see `nadj`. Otherwise a scalar
  positive integer value can be used to fit a single adjustment term of
  the specified order, and a vector of positive integers to fit multiple
  adjustment terms of the specified orders. For simple and Hermite
  polynomial adjustments, only even orders are allowed. The number of
  adjustment terms specified here must match `nadj` (or `nadj` can be
  the default `NULL` value).

- select_model:

  Logical. If `TRUE`, performs automated model selection using the
  procedure in Howe et al. (2019). If `FALSE` (default), fits a single
  model with specified parameters. When `TRUE`, `model_param` defines
  the candidate model set.

- model_params:

  Named list defining candidate models for selection when
  `select_model = TRUE`. Elements can include:

  - `key` - List of key functions to test

  - `adjustment` - List of adjustment types

  - `nadj` - List of adjustment term numbers

  - `order` - List vector of adjustment orders (must match `nadj`)

- availability:

  A list containing availability rate corrections (output from
  [`ct_availability()`](https://stangandaho.github.io/ct/reference/ct_availability.md)).
  Must include elements availability rate (0-1) and/or standard error of
  availability rate

- n_bootstrap:

  Integer. Number of bootstrap replicates for variance estimation of
  density/abundance. Default is 100. Larger values provide more precise
  confidence intervals but increase computation time.

- n_cores:

  Integer. Number of CPU cores to use for parallel bootstrap
  computation. Default is 1.

- ...:

  Arguments passed on to
  [`Distance::ds`](https://rdrr.io/pkg/Distance/man/ds.html)

  `scale`

  :   the scale by which the distances in the adjustment terms are
      divided. Defaults to `"width"`, scaling by the truncation
      distance. If the key is uniform only `"width"` will be used. The
      other option is `"scale"`: the scale parameter of the detection

  `dht_group`

  :   should density abundance estimates consider all groups to be size
      1 (abundance of groups) `dht_group=TRUE` or should the abundance
      of individuals (group size is taken into account),
      `dht_group=FALSE`. Default is `FALSE` (abundance of individuals is
      calculated).

  `monotonicity`

  :   should the detection function be constrained for monotonicity
      weakly (`"weak"`), strictly (`"strict"`) or not at all (`"none"`
      or `FALSE`). See Monotonicity, below. (Default `"strict"`). By
      default it is on for models without covariates in the detection
      function, off when covariates are present.

  `method`

  :   optimization method to use (any method usable by
      [`optim`](https://rdrr.io/r/stats/optim.html) or
      [`optimx`](https://rdrr.io/pkg/optimx/man/optimx.html)). Defaults
      to `"nlminb"`.

  `mono_method`

  :   optimization method to use when monotonicity is enforced. Can be
      either `slsqp` or `solnp`. Defaults to `slsqp`.

  `initial_values`

  :   a `list` of named starting values, see
      [`mrds_opt`](https://rdrr.io/pkg/mrds/man/mrds_opt.html). Only
      allowed when AIC term selection is not used.

  `max_adjustments`

  :   maximum number of adjustments to try (default 5) only used when
      `order=NULL`.

  `er_method`

  :   encounter rate variance calculation: default = 2 gives the method
      of Innes et al, using expected counts in the encounter rate.
      Setting to 1 gives observed counts (which matches Distance for
      Windows) and 0 uses binomial variance (only useful in the rare
      situation where study area = surveyed area). See
      [`dht.se`](https://rdrr.io/pkg/mrds/man/dht.se.html) for more
      details.

  `dht_se`

  :   should uncertainty be calculated when using `dht`? Safe to leave
      as `TRUE`, used in `bootdht`.

  `optimizer`

  :   By default this is set to 'both'. In this case the R optimizer
      will be used and if present the MCDS optimizer will also be used.
      The result with the best likelihood value will be selected. To run
      only a specified optimizer set this value to either 'R' or 'MCDS'.
      See
      [`mcds_dot_exe`](https://rdrr.io/pkg/mrds/man/mcds_dot_exe.html)
      for setup instructions.

  `winebin`

  :   If you are trying to use our MCDS.exe optimizer on a non-windows
      system then you may need to specify the winebin. Please see
      [`mcds_dot_exe`](https://rdrr.io/pkg/mrds/man/mcds_dot_exe.html)
      for more details.

## Value

A named list containing: A list containing:

- `QAIC`: (Only if `select_model = TRUE`) QAIC comparison table.

- `Chi2`: (Only if `select_model = TRUE`) Chi-squared goodness-of-fit
  comparison.

- `best_model`: The best fitted detection function model selected.

- `rho`: Estimated effective detection radius (in meters).

- `density` or `abundance`: A tibble with density or abundance estimates
  containing: `median`, `mean`, `se`: standard error, `lcl`: lower
  confidence limit, `ucl`: upper confidence limit

## Truncation

The right truncation point is by default set to be largest observed
distance or bin end point. This is a default will not be appropriate for
all data and can often be the cause of model convergence failures. It is
recommended that one plots a histogram of the observed distances prior
to model fitting so as to get a feel for an appropriate truncation
distance. (Similar arguments go for left truncation, if appropriate).
Buckland et al (2001) provide guidelines on truncation.

When specified as a percentage, the largest `right` and smallest `left`
percent distances are discarded. Percentages cannot be supplied when
using binned data.

For left truncation, there are two options: (1) fit a detection function
to the truncated data as is (this is what happens when you set `left`).
This does not assume that g(x)=1 at the truncation point. (2) manually
remove data with distances less than the left truncation distance –
effectively move the centre line out to be the truncation distance (this
needs to be done before calling `ds`). This then assumes that detection
is certain at the left truncation distance. The former strategy has a
weaker assumption, but will give higher variance as the detection
function close to the line has no data to tell it where to fit – it will
be relying on the data from after the left truncation point and the
assumed shape of the detection function. The latter is most appropriate
in the case of aerial surveys, where some area under the plane is not
visible to the observers, but their probability of detection is certain
at the smallest distance.

## Monotonicity

When adjustment terms are used, it is possible for the detection
function to not always decrease with increasing distance. This is
unrealistic and can lead to bias. To avoid this, the detection function
can be constrained for monotonicity (and is by default for detection
functions without covariates).

Monotonicity constraints are supported in a similar way to that
described in Buckland et al (2001). 20 equally spaced points over the
range of the detection function (left to right truncation) are evaluated
at each round of the optimisation and the function is constrained to be
either always less than it's value at zero (`"weak"`) or such that each
value is less than or equal to the previous point (monotonically
decreasing; `"strict"`). See also
[`check.mono`](https://rdrr.io/pkg/mrds/man/check.mono.html).

Even with no monotonicity constraints, checks are still made that the
detection function is monotonic, see
[`check.mono`](https://rdrr.io/pkg/mrds/man/check.mono.html).

## Data format

One can supply `data` only to simply fit a detection function. However,
if abundance/density estimates are necessary further information is
required. Either the `region_table`, `sample_table` and `obs_table`
`data.frame`s can be supplied or all data can be supplied as a "flat
file" in the `data` argument. In this format each row in data has
additional information that would ordinarily be in the other tables.
This usually means that there are additional columns named:
`Sample.Label`, `Region.Label`, `Effort` and `Area` for each
observation. See
[`flatfile`](https://rdrr.io/pkg/Distance/man/flatfile.html) for an
example.

## Clusters/groups

Note that if the data contains a column named `size`, cluster size will
be estimated and density/abundance will be based on a clustered analysis
of the data. Setting this column to be `NULL` will perform a
non-clustered analysis (for example if "`size`" means something else in
your dataset).

## References

Buckland, S.T., Anderson, D.R., Burnham, K.P., Laake, J.L., Borchers,
D.L., and Thomas, L. (2001). Distance Sampling. Oxford University Press.
Oxford, UK.

Howe, E. J., Buckland, S. T., Després-Einspenner, M., & Kühl, H. S.
(2017). Distance sampling with camera traps. Methods in Ecology and
Evolution, 8(11), 1558-1565.
[doi:10.1111/2041-210X.12790](https://doi.org/10.1111/2041-210X.12790)

Howe, E. J., Buckland, S. T., Després-Einspenner, M., & Kühl, H. S.
(2019). Model selection with overdispersed distance sampling data.
Methods in Ecology and Evolution, 10(1), 38-47.
[doi:10.1111/2041-210X.13082](https://doi.org/10.1111/2041-210X.13082)

Rowcliffe, J. M., Kays, R., Kranstauber, B., Carbone, C., & Jansen, P.
A. (2014). Quantifying levels of animal activity using camera trap data.
Methods in Ecology and Evolution, 5(11), 1170-1179.
[doi:10.1111/2041-210X.12278](https://doi.org/10.1111/2041-210X.12278)

## See also

[`ct_availability()`](https://stangandaho.github.io/ct/reference/ct_availability.md),
[`ct_select_model()`](https://stangandaho.github.io/ct/reference/ct_select_model.md),
[`ct_QAIC()`](https://stangandaho.github.io/ct/reference/ct_QAIC.md),
[`ct_chi2_select()`](https://stangandaho.github.io/ct/reference/ct_chi2_select.md)

## Examples

``` r
if (FALSE) { # \dontrun{
data("duikers")

# Calculates animal availability adjustment factor
trigger_events <- duikers$VideoStartTimesFullDays
avail <- ct_availability(times = trigger_events$time,
                         format = "%H:%M", n_bootstrap = 100)

# Estimate density, building multiple models
flat_data <- duikers$DaytimeDistances %>%
  dplyr::rename(fraction = multiplier) %>%
  dplyr::slice_sample(prop = .2) # sample 20% of rows

duiker_density <- ct_fit_ds(data = flat_data,
                            estimate = "density",
                            select_model = TRUE,
                            model_params = list(key = list("hn", "hr"),
                                                adjustment = list("cos"),
                                                nadj = list(2, 3),
                                                order = NULL),
                            availability = avail,
                            truncation = list(left = 2, right = 15),
                            n_bootstrap = 2,
                            cutpoints = c(seq(2, 8, 1), 10, 12, 15)
)

# View density
duiker_density$density
} # }
```
