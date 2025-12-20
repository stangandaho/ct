# Log-normal confidence interval

Calculates approximate log-normal confidence intervals given estimates
and their standard errors.

## Usage

``` r
lnorm_confint(estimate, se, percent = 95)
```

## Arguments

- estimate:

  Numeric estimate value(s)

- se:

  Standard error(s) of the estimate

- percent:

  Percentage confidence level

## Value

A dataframe with a row per estimate input, and columns `lcl` and `ucl`
(lower and upper confidence limits).
