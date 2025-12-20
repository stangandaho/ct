# Estimate overlap coefficients for multiple species

This function calculates pairwise overlap coefficients for activity
patterns of multiple species using their time data.

## Usage

``` r
ct_overlap_matrix(
  data,
  species_column,
  time_column,
  convert_time = FALSE,
  format = "%H:%M:%S",
  fill_na = NULL,
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

- ...:

  Additional arguments passed to
  [`overlap::overlapEst()`](https://rdrr.io/pkg/overlap/man/overlapEst.html)\`
  for overlap estimation.

## Value

A square matrix of pairwise overlap coefficients, where rows and columns
represent species.

## Details

The function calculates pairwise overlap coefficients for all species in
the dataset. The overlap coefficients are estimated using the `overlap`
package:

- For species pairs with sample sizes of at least 50 observations each,
  the `Dhat4` estimator is used.

- For smaller sample sizes, the `Dhat1` estimator is used (Schmid &
  Schmidt, 2006).

## References

Schmid & Schmidt (2006) Nonparametric estimation of the coefficient of
overlapping - theory and empirical application, Computational Statistics
and Data Analysis, 50:1583-1596.

## See also

[`overlap::overlapEst()`](https://rdrr.io/pkg/overlap/man/overlapEst.html)
for overlap coefficient estimation.

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

# Fill missing values in the matrix with 0
overlap_matrix_filled <- ct_overlap_matrix(
  data = data,
  species_column = species,
  time_column = time,
  convert_time = TRUE,
  fill_na = 0
)
```
