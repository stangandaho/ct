# Bootstrap confidence intervals

Confidence interval calculation from bootstrap samples.

## Usage

``` r
ct_boot_ci(t0, bt, conf = 0.95)
```

## Arguments

- t0:

  the statistic estimated from the original sample, usually the output
  from
  [`ct_overlap_estimates()`](https://stangandaho.github.io/ct/reference/ct_overlap_estimates.md)

- bt:

  a vector of bootstrap statistics, usually the output from
  [`ct_boot_estimates()`](https://stangandaho.github.io/ct/reference/bootstrap.md)

- conf:

  a (single!) confidence interval to estimate.
