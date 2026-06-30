# Fit a count distribution by maximum likelihood

Fits a Poisson, negative binomial, or binomial distribution to a vector
of counts and returns the parameter estimates together with the
log-likelihood, AIC and BIC.

## Usage

``` r
ct_fit_distribution(count, distribution)
```

## Arguments

- count:

  Numeric vector of non-negative counts. For `distribution = "binomial"`
  it must contain only 0 and 1.

- distribution:

  One of `"poisson"`, `"nbinomial"` or `"binomial"`.

## Value

A one-row [tibble](https://dplyr.tidyverse.org/reference/reexports.html)
with the fitted parameter(s), their standard error(s), the
log-likelihood, AIC, BIC and sample size.

## See also

[`ct_plot_calendar()`](https://stangandaho.github.io/ct/reference/ct_plot_calendar.md)

## Examples

``` r
set.seed(1)
ct_fit_distribution(stats::rpois(100, 3), "poisson")
#> # A tibble: 1 × 7
#>   lambda lambda_se loglik   aic   bic     n distribution
#>    <dbl>     <dbl>  <dbl> <dbl> <dbl> <int> <chr>       
#> 1   3.05     0.175  -181.  364.  367.   100 poisson     
ct_fit_distribution(stats::rnbinom(100, size = 1, mu = 4), "nbinomial")
#> # A tibble: 1 × 9
#>    size    mu  prob theta_se loglik   aic   bic     n distribution
#>   <dbl> <dbl> <dbl>    <dbl>  <dbl> <dbl> <dbl> <int> <chr>       
#> 1 0.873  3.66 0.193    0.164  -242.  488.  493.   100 nbinomial   
```
