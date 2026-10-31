# Stack a list of data frame

The function takes a list of data frames and stacks them into a single
data frame. It ensures that all columns from the input data frames in
the list are included in the output, filling in missing columns with NA
values where necessary.

## Usage

``` r
ct_stack_df(df_list)
```

## Arguments

- df_list:

  list of data frame to be stacked

## Value

data frame

## Examples

``` r

x <- data.frame(age = 15, fruit = "Apple", weight = 12)
y <- data.frame(age = 51, fruit = "Tomato")
z <- data.frame(age = 26, fruit = "Lemo", weight = 12, height = 45)
alldf <- list(x,y,z)
ct_stack_df(alldf)
#> # A tibble: 3 × 4
#>   height fruit  weight   age
#>    <dbl> <chr>   <dbl> <dbl>
#> 1     NA Apple      12    15
#> 2     NA Tomato     NA    51
#> 3     45 Lemo       12    26
```
