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
ct_describe_df(data, ..., fn = NULL, by_group = TRUE)
```

## Arguments

- data:

  A data frame containing the dataset to be summarized.

- ...:

  (Optional) Columns to include in the summary. If no column is
  specified, all columns in the data will be included.

- fn:

  A list of functions to apply to numeric variables. Each function must
  accept `x` as a vector of numeric values and return a single value or
  a named vector. Additional arguments for these functions can be
  specified as a list. For example:
  `fn = list('sum' = list(na.rm = TRUE), 'sd')`.

- by_group:

  Logical, default `TRUE`. When `TRUE` and both categorical and numeric
  variables are selected, each numeric variable is summarised within the
  groups defined by the categorical variable(s). When `FALSE`, numeric
  and categorical variables are summarised independently and stacked
  into a single table. If only one variable type is present, `by_group`
  has no effect.

## Value

A tibble whose shape depends on `by_group`.

With `by_group = TRUE` (and at least one categorical and one numeric
variable), the data are grouped by the selected categorical variable(s)
and each numeric variable is summarised within every group. The result
has one row per numeric variable and group combination, with columns:

- `Variable`:

  Name of the numeric variable being summarised.

- grouping column(s):

  One column per selected categorical variable, each holding the group
  value.

- `N`:

  Number of non-missing values of `Variable` in the group.

- `Min`, `Max`, `Median`, `Mean`:

  Descriptive statistics of `Variable` within the group.

- `CI Left`, `CI Right`:

  Lower and upper bounds of the 95% t-based confidence interval for the
  group mean (see
  [`ct_ci()`](https://stangandaho.github.io/ct/reference/ct_ci.md)).

With `by_group = FALSE` (also used as a fallback when only numeric or
only categorical variables are selected), numeric and categorical
summaries are stacked into one tibble with one row per numeric variable
and one row per distinct value of each categorical variable; columns
that do not apply to a row are `NA`:

- `Variable`:

  Name of the summarised column.

- `Group`:

  For a categorical variable, the distinct value described; `NA` for
  numeric variables.

- `Prop`:

  For a categorical variable, the percentage of its non-missing records
  falling in `Group`; `NA` for numeric variables.

- `N`:

  Non-missing count: values for a numeric variable, or records in
  `Group` for a categorical variable.

- `Min`, `Max`, `Median`, `Mean`:

  Numeric statistics; `NA` for categorical variables.

- `CI Left`, `CI Right`:

  95% t-based confidence interval bounds for the mean (see
  [`ct_ci()`](https://stangandaho.github.io/ct/reference/ct_ci.md));
  `NA` for categorical variables.

In both modes, supplying `fn` appends one extra column per named
function, holding that statistic for each numeric variable (or group).

## See also

parse_list_fn

## Examples

``` r
df <- data.frame(x = c(1:3, NA),
                 y = c(3:4, NA, NA),
                 z = c("A", "A", "B", "A"))

# Numeric variables summarised within each group of the categorical variable
ct_describe_df(df, y, x, z)
#> # A tibble: 4 × 9
#>   Variable z         N   Min   Max Median  Mean `CI Left` `CI Right`
#>   <chr>    <chr> <int> <dbl> <dbl>  <dbl> <dbl>     <dbl>      <dbl>
#> 1 y        A         2     3     4    3.5   3.5     -2.85       9.85
#> 2 y        B         0    NA    NA   NA   NaN       NA         NA   
#> 3 x        A         2     1     2    1.5   1.5     -4.85       7.85
#> 4 x        B         1     3     3    3     3       NA         NA   

# Summarise every variable independently
ct_describe_df(df, y, x, z, by_group = FALSE)
#> # A tibble: 4 × 10
#>   Group  Prop     N Variable  Mean `CI Right`   Min   Max Median `CI Left`
#>   <chr> <dbl> <int> <chr>    <dbl>      <dbl> <dbl> <dbl>  <dbl>     <dbl>
#> 1 NA       NA     2 y          3.5       9.85     3     4    3.5    -2.85 
#> 2 NA       NA     3 x          2         4.48     1     3    2      -0.484
#> 3 A        75     3 z         NA        NA       NA    NA   NA      NA    
#> 4 B        25     1 z         NA        NA       NA    NA   NA      NA    

# Add custom statistics for the numeric variables
ct_describe_df(df, y, x, z,
               fn = list('sum' = list(na.rm = TRUE), 'sd' = list(na.rm = TRUE)))
#> # A tibble: 4 × 11
#>   Variable z         N   Min   Max Median  Mean `CI Left` `CI Right`   sum
#>   <chr>    <chr> <int> <dbl> <dbl>  <dbl> <dbl>     <dbl>      <dbl> <int>
#> 1 y        A         2     3     4    3.5   3.5     -2.85       9.85     7
#> 2 y        B         0    NA    NA   NA   NaN       NA         NA        0
#> 3 x        A         2     1     2    1.5   1.5     -4.85       7.85     3
#> 4 x        B         1     3     3    3     3       NA         NA        3
#> # ℹ 1 more variable: sd <dbl>
```
