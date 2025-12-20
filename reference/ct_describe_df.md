# Descriptive statistic on dataset

This function provides a summary of a dataset, including both numeric
and non-numeric variables. For numeric variables, it calculates basic
descriptive statistics such as minimum, maximum, median, mean, and count
of non-missing values. Additionally, users can pass custom functions via
the `fn` argument to compute additional statistics for numeric
variables. For non-numeric variables, it provides frequency counts and
proportions for each unique value.

## Usage

``` r
ct_describe_df(data, ..., fn = NULL)
```

## Arguments

- data:

  A data frame containing the dataset to be summarized.

- ...:

  (Optional) Column to include in the summary. If no column is specifie,
  all columns in the data will be included.

- fn:

  A named list of functions to apply to numeric variables. Each function
  must accept `x` as a vector of numeric values and return a single
  value or a named vector. Additional arguments for these functions can
  be specified as a list. For example:
  `fn = list('sum' = list(na.rm = TRUE), 'sd')`.

## Value

A tibble

## See also

parse_list_fn

## Examples

``` r
ct_describe_df(data = data.frame(x = c(1:3, NA),
                                 y = c(3:4, NA, NA),
                                 z = c("A", "A", "B", "A")),
               y, x, z,
               fn = list('sum' = list(na.rm = TRUE), 'sd' = list(na.rm = TRUE))
              )
#> # A tibble: 4 × 12
#>   Group  Prop     N Variable   Max `CI Left`   Min Median  Mean     sd
#>   <chr> <dbl> <int> <chr>    <dbl>     <dbl> <dbl>  <dbl> <dbl>  <dbl>
#> 1 NA       NA     2 y            4    -2.85      3    3.5   3.5  0.707
#> 2 NA       NA     3 x            3    -0.484     1    2     2    1    
#> 3 A        75     3 z           NA    NA        NA   NA    NA   NA    
#> 4 B        25     1 z           NA    NA        NA   NA    NA   NA    
#> # ℹ 2 more variables: `CI Right` <dbl>, sum <int>
```
