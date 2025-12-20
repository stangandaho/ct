# Select best detection function model by Chi-squared Goodness-of-fit

Compares detection function models with different key functions using
the ratio of the chi-squared statistic to its degrees of freedom. This
method selects the best model among different key functions after the
best adjustment term model is chosen for each key function.

## Usage

``` r
ct_chi2_select(models)
```

## Arguments

- models:

  A list of fitted detection function models (objects returned by
  [`Distance::ds()`](https://rdrr.io/pkg/Distance/man/ds.html) or
  [`ct_fit_ds()`](https://stangandaho.github.io/ct/reference/ct_fit_ds.md)).

## Value

A tibble with one row per model containing:

- `key`: The key function of the model.

- `model`: The model name.

- `criteria`: The chi-squared goodness-of-fit statistic divided by its
  degrees of freedom, i.e. \\\chi^2/\mathrm{df}\\. Lower values indicate
  better fit.

## Details

If only one model is supplied, the function returns the chi-squared
goodness-of-fit ratio for that model and issues a warning that model
selection cannot be performed. For multiple models, each must have a
unique key function. This step is designed to be applied after selecting
the best model within each key function family using QAIC (see
[`ct_QAIC()`](https://stangandaho.github.io/ct/reference/ct_QAIC.md)).
The model with the smallest chi-squared/df ratio is typically preferred.

## References

Howe, E. J., Buckland, S. T., Després‐Einspenner, M., & Kühl, H. S.
(2019). Model selection with overdispersed distance sampling data.
**Methods in Ecology and Evolution**, 10(1), 38-47.
[doi:10.1111/2041-210X.13082](https://doi.org/10.1111/2041-210X.13082)

## Examples

``` r
# \donttest{
library(Distance)
library(dplyr)

data("duiker")
#> Warning: data set ‘duiker’ not found
duiker_data <- duikers$DaytimeDistances %>%
  dplyr::slice_sample(prop = .3) # sample 30% of rows
truncation <- list(left = 2, right = 15) # Keep only distance between 2-15 m

# fit hazard-rate key models
w3_hr0 <- ds(duiker_data, transect = "point", key = "hr", adjustment = NULL,
             truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting hazard-rate key function
#> AIC= 15043.592
w3_hr1 <- ds(duiker_data, transect = "point", key = "hr", adjustment = "cos",
             order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting hazard-rate key function with cosine(2) adjustments
#> AIC= 15042.128
w3_hr2 <- ds(duiker_data, transect = "point", key = "hr", adjustment = "cos",
             order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting hazard-rate key function with cosine(2,4) adjustments
#> AIC= 15038.234
# fit half-normal key models
w3_hn0 <- ds(duiker_data, transect = "point", key = "hn", adjustment = NULL,
             truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function
#> AIC= 15049.033
w3_hn1 <- ds(duiker_data, transect = "point", key = "hn", adjustment = "cos",
             order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function with cosine(2) adjustments
#> AIC= 15025.292
w3_hn2 <- ds(duiker_data, transect = "point", key = "hn", adjustment = "cos",
             order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function with cosine(2,4) adjustments
#> AIC= 15024.853
# fit uniform key models
w3_u0 <- ds(duiker_data, transect = "point", key = "unif", adjustment = NULL,
            truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function
#> AIC= 17395.584
w3_u1 <- ds(duiker_data, transect = "point", key = "unif", adjustment = "cos",
            order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function with cosine(2) adjustments
#> AIC= 17397.584
w3_u2 <- ds(duiker_data, transect = "point", key = "unif", adjustment = "cos",
            order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function with cosine(2,4) adjustments
#> Warning: Detection function is not weakly monotonic!
#> Warning: Detection function is greater than 1 at some distances
#> AIC= 17399.584
#> Warning: Detection function is not weakly monotonic!
#> Warning: Detection function is greater than 1 at some distances

# Create model list
model_list <- list(w3_hn0, w3_hn1, w3_hn2,
                   w3_hr0, w3_hr1, w3_hr2,
                   w3_u0, w3_u1, w3_u2)

# Compute model QAICs
ct_QAIC(list(w3_hr0, w3_hr1, w3_hr2)) # All key functions must be the same
#> # A tibble: 3 × 3
#>   model                                                    df  QAIC
#>   <chr>                                                 <int> <dbl>
#> 1 hazard-rate key function                                  2  52.2
#> 2 hazard-rate key function with cosine(2) adjustments       3  54.2
#> 3 hazard-rate key function with cosine(2,4) adjustments     4  56.2
ct_QAIC(list(w3_hn0, w3_hn1, w3_hn2)) # All key functions must be the same
#> # A tibble: 3 × 3
#>   model                                                    df  QAIC
#>   <chr>                                                 <int> <dbl>
#> 1 half-normal key function                                  1  51.3
#> 2 half-normal key function with cosine(2) adjustments       2  53.2
#> 3 half-normal key function with cosine(2,4) adjustments     3  55.2

# Compute Chi-squared Goodness-of-fit
ct_chi2_select(list(w3_hn0, w3_hr0, w3_u0)) # All key functions must be different
#> # A tibble: 3 × 3
#>   key         model                    criteria
#>   <chr>       <chr>                       <dbl>
#> 1 half-normal half-normal key function     309.
#> 2 hazard-rate hazard-rate key function     316.
#> 3 uniform     uniform key function         463.
ct_chi2_select(list(w3_hn2, w3_hr1, w3_u0)) # All key functions must be different
#> # A tibble: 3 × 3
#>   key         model                                                 criteria
#>   <chr>       <chr>                                                    <dbl>
#> 1 half-normal half-normal key function with cosine(2,4) adjustments     318.
#> 2 hazard-rate hazard-rate key function with cosine(2) adjustments       320.
#> 3 uniform     uniform key function                                      463.

# Two-step model selection
ct_select_model(model_list)
#> $QAIC
#> # A tibble: 9 × 6
#>      id key         model                                         df  QAIC best 
#>   <int> <chr>       <chr>                                      <int> <dbl> <lgl>
#> 1     1 half-normal half-normal key function                       1  51.3 TRUE 
#> 2     2 half-normal half-normal key function with cosine(2) a…     2  53.2 FALSE
#> 3     3 half-normal half-normal key function with cosine(2,4)…     3  55.2 FALSE
#> 4     4 hazard-rate hazard-rate key function                       2  52.2 TRUE 
#> 5     5 hazard-rate hazard-rate key function with cosine(2) a…     3  54.2 FALSE
#> 6     6 hazard-rate hazard-rate key function with cosine(2,4)…     4  56.2 FALSE
#> 7     7 uniform     uniform key function                           0  38.2 TRUE 
#> 8     8 uniform     uniform key function with cosine(2) adjus…     1  40.2 FALSE
#> 9     9 uniform     uniform key function with cosine(2,4) adj…     2  42.2 FALSE
#> 
#> $`Best QAIC models`
#> $`Best QAIC models`[[1]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Half-normal key function 
#> 
#> Estimated abundance in covered region: 11854.92 
#> 
#> $`Best QAIC models`[[2]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Hazard-rate key function 
#> 
#> Estimated abundance in covered region: 8219.799 
#> 
#> $`Best QAIC models`[[3]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Uniform key function 
#> 
#> Estimated abundance in covered region: 3141.855 
#> 
#> 
#> $Chi2
#> # A tibble: 3 × 4
#>   key         model                    criteria best 
#>   <chr>       <chr>                       <dbl> <lgl>
#> 1 half-normal half-normal key function     309. TRUE 
#> 2 hazard-rate hazard-rate key function     316. FALSE
#> 3 uniform     uniform key function         463. FALSE
#> 
#> $`Final model`
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Half-normal key function 
#> 
#> Estimated abundance in covered region: 11854.92 
#> 
# }
```
