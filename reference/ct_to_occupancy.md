# Convert camera trap data to occupancy format

This function transforms camera trap detection data into an occupancy
format suitable for analysis. It aggregates detections into user-defined
time windows and optionally converts counts into presence-absence (0/1)
data.

## Usage

``` r
ct_to_occupancy(
  data,
  date_column,
  format = "%Y-%m-%d",
  site_column,
  species_column,
  size_column,
  by_day = 7,
  presence_absence = TRUE
)
```

## Arguments

- data:

  A data frame containing camera trap detection records.

- date_column:

  The name of the column containing detection dates.

- format:

  a character string. If not specified when converting from a character
  representation, it will try c("%Y-%m-%d", "%Y/%m/%d") one by one, and
  give an error if none works. Otherwise, the processing is via
  [`strptime()`](https://rdrr.io/r/base/strptime.html) whose help page
  describes available conversion specifications.

- site_column:

  The name of the column identifying sampling sites.

- species_column:

  The name of the column containing species names. Can be NULL if
  species information is not needed.

- size_column:

  The name of the column representing detection counts.

- by_day:

  An integer specifying the number of days per time window (default:
  `7`).

- presence_absence:

  Logical. If `TRUE`, converts counts to presence-absence data (1 =
  detected, 0 = not detected). Default is `TRUE`.

## Value

A wide-format data frame where rows represent sites (and optionally
species), and columns represent detection windows. Values indicate
either detection counts or presence-absence (0/1).

## See also

[`ct_to_community()`](https://stangandaho.github.io/ct/reference/ct_to_community.md)

## Examples

``` r
data <- data.frame(
  date = c("01-01-2023", "03-01-2023", "10-01-2023", "15-01-2023"),
  site = c("A", "A", "B", "B"),
  species = c("Tiger", "Tiger", "Deer", "Deer"),
  count = c(1, 2, 3, 1)
)

occupancy_data <- ct_to_occupancy(
  data,
  date_column = date,
  site_column = site,
  species_column = species,
  size_column = count,
  by_day = 7,
  presence_absence = TRUE
)

occupancy_data
#> # A tibble: 4 × 732
#>   site  species `1-01-20 to 1-01-26` `1-01-27 to 1-02-02` `1-02-03 to 1-02-09`
#>   <chr> <chr>                  <dbl>                <dbl>                <dbl>
#> 1 A     Deer                       0                    0                    0
#> 2 A     Tiger                      0                    0                    0
#> 3 B     Deer                       0                    0                    0
#> 4 B     Tiger                      0                    0                    0
#> # ℹ 727 more variables: `1-02-10 to 1-02-16` <dbl>, `1-02-17 to 1-02-23` <dbl>,
#> #   `1-02-24 to 1-03-02` <dbl>, `1-03-03 to 1-03-09` <dbl>,
#> #   `1-03-10 to 1-03-16` <dbl>, `1-03-17 to 1-03-23` <dbl>,
#> #   `1-03-24 to 1-03-30` <dbl>, `1-03-31 to 1-04-06` <dbl>,
#> #   `1-04-07 to 1-04-13` <dbl>, `1-04-14 to 1-04-20` <dbl>,
#> #   `1-04-21 to 1-04-27` <dbl>, `1-04-28 to 1-05-04` <dbl>,
#> #   `1-05-05 to 1-05-11` <dbl>, `1-05-12 to 1-05-18` <dbl>, …

```
