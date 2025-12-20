# Calculate confidence interval

Calculates the confidence interval for the mean of a numeric vector
using the t-distribution.

## Usage

``` r
ct_ci(x, alpha = 0.05, side = "all")
```

## Arguments

- x:

  A numeric vector of data values.

- alpha:

  Significance level for the confidence interval. Default is 0.05 (for
  95% confidence).

- side:

  A character string indicating the type of interval:

  "all"

  :   Two-sided confidence interval (default).

  "left"

  :   One-sided lower bound.

  "right"

  :   One-sided upper bound.

## Value

A numeric vector containing the confidence interval bounds:

- If `side = "all"`, returns a vector of length 2: `c(lower, upper)`.

- If `side = "left"` or `"right"`, returns a single numeric value.

## Examples

``` r
x <- c(10, 12, 11, 14, 13, 15)
ct_ci(x)
#> [1] 10.53669 14.46331
ct_ci(x, alpha = 0.01)
#> [1]  9.4204 15.5796
ct_ci(x, side = "left")
#> [1] 10.53669
```
