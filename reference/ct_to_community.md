# Convert data to a community matrix

The function transforms input data into a community matrix where rows
represent sites, columns represent species, and values indicate the
count or abundance of each species at each site.

## Usage

``` r
ct_to_community(
  data,
  site_column,
  species_column,
  size_column,
  values_fill = NULL
)
```

## Arguments

- data:

  A data frame containing the input data.

- site_column:

  The column in the data frame representing site identifiers. Can be
  specified as a string or unquoted column name.

- species_column:

  The column in the data frame representing species identifiers. Can be
  specified as a string or unquoted column name.

- size_column:

  (Optional) The column representing the size or abundance of the
  species at each site. If not provided, counts of species occurrences
  are calculated.

- values_fill:

  (Optional) A value to fill missing cells in the resulting community
  matrix. Defaults to `NULL`.

## Value

A tibble where rows represent sites, columns represent species, and
values represent the count or abundance of each species.

## Details

The function creates a site-by-species matrix suitable for ecological
analysis. If `size_column` is not provided, the function counts
occurrences of each species per site. If `size_column` is provided, its
values are used as the measure for species abundance.

## Examples

``` r
# Example data
df <- dplyr::tibble(
  site = c("A", "A", "B", "B", "C"),
  species = c("sp1", "sp2", "sp1", "sp3", "sp2"),
  abundance = c(5, 2, 3, 1, 4)
)

# Convert to community matrix with counts
ct_to_community(df, site_column = site, species_column = species)
#> # A tibble: 3 × 4
#>   site    sp1   sp2   sp3
#>   <chr> <int> <int> <int>
#> 1 A         1     1    NA
#> 2 B         1    NA     1
#> 3 C        NA     1    NA

# Convert to community matrix with abundance
ct_to_community(df, site_column = site, species_column = species, size_column = abundance)
#> # A tibble: 3 × 4
#>   site    sp1   sp2   sp3
#>   <chr> <dbl> <dbl> <dbl>
#> 1 A         5     2    NA
#> 2 B         3    NA     1
#> 3 C        NA     4    NA

# Fill missing cells with 0
ct_to_community(df, site_column = site, species_column = species, values_fill = 0)
#> # A tibble: 3 × 4
#>   site    sp1   sp2   sp3
#>   <chr> <int> <int> <int>
#> 1 A         1     1     0
#> 2 B         1     0     1
#> 3 C         0     1     0
```
