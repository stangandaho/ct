# Estimate overlap coefficients for multiple species

This function calculates pairwise overlap coefficients for activity
patterns of multiple species using their time data, and optionally
bootstrap confidence intervals for every pair.

## Usage

``` r
ct_overlap_matrix(
  data,
  species_column,
  time_column,
  convert_time = FALSE,
  format = "%H:%M:%S",
  fill_na = NULL,
  n_boot = 0,
  conf = 0.95,
  ci_method = c("auto", "norm", "norm0", "basic", "basic0", "perc"),
  cores = 1,
  ...
)
```

## Arguments

- data:

  A `data.frame` or `tibble` containing species and time information.

- species_column:

  A column in `data` indicating species names.

- time_column:

  A column in `data` containing time data (either as radians or in a
  time format to be converted).

- convert_time:

  Logical. If `TRUE`, the time data will be converted to radians using
  the `ct_to_radian` function.

- format:

  A character string specifying the time format (e.g., `"%H:%M:%S"`) if
  [`ct_to_radian()`](https://stangandaho.github.io/ct/reference/ct_to_radian.md)
  is `TRUE`. Defaults to `"%H:%M:%S"`.

- fill_na:

  Optional. A numeric value used to fill `NA` values in the overlap
  coefficient matrix. Defaults to `NULL` (does not fill `NA` values).

- n_boot:

  Integer. Number of bootstrap samples used to derive a confidence
  interval for each species pair. When `n_boot <= 1` (the default, `0`)
  no bootstrap is run and a single coefficient matrix is returned,
  preserving the original behaviour. When `n_boot > 1`, a list of
  matrices is returned (see Value).

- conf:

  Numeric scalar in `(0, 1)`. Confidence level for the bootstrap
  interval. Defaults to `0.95`.

- ci_method:

  Character. How to choose the confidence-interval type returned by
  [`overlap::bootCI()`](https://rdrr.io/pkg/overlap/man/bootCI.html) for
  each pair. `"auto"` (default) selects, per pair, between the two
  interval types appropriate for the uncorrected estimate reported in
  the matrix: `"norm0"` when the bootstrap estimates are approximately
  normal (Shapiro-Wilk `p >= 0.05`) and the skew-robust `"basic0"`
  otherwise. Alternatively, force a single type for all pairs with one
  of `"norm"`, `"norm0"`, `"basic"`, `"basic0"` or `"perc"`.

- cores:

  Integer. Number of cores passed to
  [`ct_bootstrap()`](https://stangandaho.github.io/ct/reference/bootstrap.md).
  Defaults to `1`.

- ...:

  Additional arguments passed to
  [`overlap::overlapEst()`](https://rdrr.io/pkg/overlap/man/overlapEst.html)\`
  for overlap estimation.

## Value

If `n_boot <= 1`, a square numeric matrix of pairwise overlap
coefficients, where rows and columns represent species (the original
return value).

If `n_boot > 1`, a named list of matrices:

- `estimate`:

  the square numeric matrix of overlap coefficients;

- `ci`:

  a character matrix whose cells give the confidence interval as
  `"[lower ; upper]"`;

- `ci_method`:

  a character matrix recording which
  [`ct_boot_ci()`](https://stangandaho.github.io/ct/reference/ct_boot_ci.md)
  interval type was used for each cell if ci_method is `"auto"`;

## Details

The function calculates pairwise overlap coefficients for all species in
the dataset. The overlap coefficients are estimated using the `overlap`
package:

- For species pairs with sample sizes of at least 50 observations each,
  the `Dhat4` estimator is used.

- For smaller sample sizes, the `Dhat1` estimator is used (Schmid &
  Schmidt, 2006).

When `n_boot > 1`, each pair is bootstrapped with the same estimator
used for its point estimate, and a confidence interval is obtained
through
[`ct_boot_ci()`](https://stangandaho.github.io/ct/reference/ct_boot_ci.md).
Because the coefficient stored in the matrix is the uncorrected
estimate, the `"auto"` selection restricts itself to the interval types,
namely `"norm0"` and `"basic0"`; the choice between them is made per
pair from a normality check on the bootstrap estimates. Pairs for which
the bootstrap or interval cannot be computed receive `NA`.

## References

Schmid & Schmidt (2006) Nonparametric estimation of the coefficient of
overlapping - theory and empirical application, Computational Statistics
and Data Analysis, 50:1583-1596.

## See also

[`overlap::overlapEst()`](https://rdrr.io/pkg/overlap/man/overlapEst.html)
for overlap coefficient estimation;
[`ct_bootstrap()`](https://stangandaho.github.io/ct/reference/bootstrap.md)
and
[`ct_boot_ci()`](https://stangandaho.github.io/ct/reference/ct_boot_ci.md)
for the bootstrap machinery.

## Examples

``` r
# Example dataset
data <- data.frame(
  species = c("SpeciesA", "SpeciesA", "SpeciesB", "SpeciesB"),
  time = c("10:30:00", "11:45:00", "22:15:00", "23:30:00")
)

# Calculate overlap coefficients with time conversion
overlap_matrix <- ct_overlap_matrix(
  data = data,
  species_column = species,
  time_column = time,
  convert_time = TRUE,
  format = "%H:%M:%S"
)

# \donttest{
# With bootstrap confidence intervals (returns a list of matrices)
overlap_ci <- ct_overlap_matrix(
  data = data,
  species_column = species,
  time_column = time,
  convert_time = TRUE,
  n_boot = 99,
  conf = 0.95
)
overlap_ci$estimate
#>          SpeciesA SpeciesB
#> SpeciesA        0        0
#> SpeciesB        0        0
overlap_ci$ci
#>          SpeciesA          SpeciesB         
#> SpeciesA ""                "[0.000 ; 0.000]"
#> SpeciesB "[0.000 ; 0.000]" ""               
overlap_ci$ci_method
#>          SpeciesA SpeciesB
#> SpeciesA ""       "basic0"
#> SpeciesB "basic0" ""      
# }
```
