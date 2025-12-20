# Model selection for Distance Sampling detection functions

Implements a two-step model selection procedure for distance sampling
detection functions following the approach of Howe et al (2019).

## Usage

``` r
ct_select_model(models, chat = NULL, k = 2)
```

## Arguments

- models:

  A list of fitted detection function models (objects returned by
  [`Distance::ds()`](https://rdrr.io/pkg/Distance/man/ds.html) or
  [`ct_fit_ds()`](https://stangandaho.github.io/ct/reference/ct_fit_ds.md)).

- chat:

  Optional numeric value of overdispersion (\\\hat{c}\\). If not
  provided, it is estimated from the most parameterised model in each
  key function set.

- k:

  Numeric. The penalty term used in QAIC (default is `2`).

## Value

A named list with the following elements:

- `QAIC`: A tibble summarizing QAIC results for each model within key
  function families.

- `Best QAIC models`: A subset of models, one per key function, that
  minimize QAIC.

- `Chiq2`: A tibble comparing the best models by chi-squared
  goodness-of-fit criteria.

- `Final model`: The selected detection function model with the lowest
  chi-squared/df.

## Details

**Step 1:** Within each key function family (e.g., half-normal,
hazard-rate), models are compared using the quasi-Akaike Information
Criterion (QAIC). Overdispersion (\\\hat{c}\\) is estimated if not
provided. The best model per key function family is identified as the
one with the lowest QAIC.

**Step 2:** The best models from each key function family are compared
using overall goodness-of-fit statistics based on chi-squared divided by
degrees of freedom (\\\chi^2 / df\\). The model with the lowest \\\chi^2
/ df\\ is selected as the final detection function model.

## References

Howe, E. J., Buckland, S. T., Després‐Einspenner, M., & Kühl, H. S.
(2019). Model selection with overdispersed distance sampling data.
**Methods in Ecology and Evolution**, 10(1), 38-47.
[doi:10.1111/2041-210X.13082](https://doi.org/10.1111/2041-210X.13082)

## See also

[`ct_QAIC()`](https://stangandaho.github.io/ct/reference/ct_QAIC.md),
[`ct_chi2_select()`](https://stangandaho.github.io/ct/reference/ct_chi2_select.md)

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
#> AIC= 15167.358
w3_hr1 <- ds(duiker_data, transect = "point", key = "hr", adjustment = "cos",
             order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting hazard-rate key function with cosine(2) adjustments
#> AIC= 15169.358
w3_hr2 <- ds(duiker_data, transect = "point", key = "hr", adjustment = "cos",
             order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting hazard-rate key function with cosine(2,4) adjustments
#> AIC= 15171.252
# fit half-normal key models
w3_hn0 <- ds(duiker_data, transect = "point", key = "hn", adjustment = NULL,
             truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function
#> AIC= 15185.938
w3_hn1 <- ds(duiker_data, transect = "point", key = "hn", adjustment = "cos",
             order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function with cosine(2) adjustments
#> AIC= 15164.566
w3_hn2 <- ds(duiker_data, transect = "point", key = "hn", adjustment = "cos",
             order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function with cosine(2,4) adjustments
#> AIC= 15163.643
# fit uniform key models
w3_u0 <- ds(duiker_data, transect = "point", key = "unif", adjustment = NULL,
            truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function
#> AIC= 17430.372
w3_u1 <- ds(duiker_data, transect = "point", key = "unif", adjustment = "cos",
            order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function with cosine(2) adjustments
#> AIC= 17432.372
w3_u2 <- ds(duiker_data, transect = "point", key = "unif", adjustment = "cos",
            order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function with cosine(2,4) adjustments
#> AIC= 17434.372

# Create model list
model_list <- list(w3_hn0, w3_hn1, w3_hn2,
                   w3_hr0, w3_hr1, w3_hr2,
                   w3_u0, w3_u1, w3_u2)

# Compute model QAICs
ct_QAIC(list(w3_hr0, w3_hr1, w3_hr2)) # All key functions must be the same
#> # A tibble: 3 × 3
#>   model                                                    df  QAIC
#>   <chr>                                                 <int> <dbl>
#> 1 hazard-rate key function                                  2  52.4
#> 2 hazard-rate key function with cosine(2) adjustments       3  54.4
#> 3 hazard-rate key function with cosine(2,4) adjustments     4  56.4
ct_QAIC(list(w3_hn0, w3_hn1, w3_hn2)) # All key functions must be the same
#> # A tibble: 3 × 3
#>   model                                                    df  QAIC
#>   <chr>                                                 <int> <dbl>
#> 1 half-normal key function                                  1  51.8
#> 2 half-normal key function with cosine(2) adjustments       2  53.7
#> 3 half-normal key function with cosine(2,4) adjustments     3  55.7

# Compute Chi-squared Goodness-of-fit
ct_chi2_select(list(w3_hn0, w3_hr0, w3_u0)) # All key functions must be different
#> # A tibble: 3 × 3
#>   key         model                    criteria
#>   <chr>       <chr>                       <dbl>
#> 1 half-normal half-normal key function     307.
#> 2 hazard-rate hazard-rate key function     314.
#> 3 uniform     uniform key function         452.
ct_chi2_select(list(w3_hn2, w3_hr1, w3_u0)) # All key functions must be different
#> # A tibble: 3 × 3
#>   key         model                                                 criteria
#>   <chr>       <chr>                                                    <dbl>
#> 1 half-normal half-normal key function with cosine(2,4) adjustments     318.
#> 2 hazard-rate hazard-rate key function with cosine(2) adjustments       320.
#> 3 uniform     uniform key function                                      452.

# Two-step model selection
ct_select_model(model_list)
#> $QAIC
#> # A tibble: 9 × 6
#>      id key         model                                         df  QAIC best 
#>   <int> <chr>       <chr>                                      <int> <dbl> <lgl>
#> 1     1 half-normal half-normal key function                       1  51.8 TRUE 
#> 2     2 half-normal half-normal key function with cosine(2) a…     2  53.7 FALSE
#> 3     3 half-normal half-normal key function with cosine(2,4)…     3  55.7 FALSE
#> 4     4 hazard-rate hazard-rate key function                       2  52.4 TRUE 
#> 5     5 hazard-rate hazard-rate key function with cosine(2) a…     3  54.4 FALSE
#> 6     6 hazard-rate hazard-rate key function with cosine(2,4)…     4  56.4 FALSE
#> 7     7 uniform     uniform key function                           0  39.2 TRUE 
#> 8     8 uniform     uniform key function with cosine(2) adjus…     1  41.2 FALSE
#> 9     9 uniform     uniform key function with cosine(2,4) adj…     2  43.2 FALSE
#> 
#> $`Best QAIC models`
#> $`Best QAIC models`[[1]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Half-normal key function 
#> 
#> Estimated abundance in covered region: 11568.28 
#> 
#> $`Best QAIC models`[[2]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Hazard-rate key function 
#> 
#> Estimated abundance in covered region: 8261.735 
#> 
#> $`Best QAIC models`[[3]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Uniform key function 
#> 
#> Estimated abundance in covered region: 3159.163 
#> 
#> 
#> $Chi2
#> # A tibble: 3 × 4
#>   key         model                    criteria best 
#>   <chr>       <chr>                       <dbl> <lgl>
#> 1 half-normal half-normal key function     307. TRUE 
#> 2 hazard-rate hazard-rate key function     314. FALSE
#> 3 uniform     uniform key function         452. FALSE
#> 
#> $`Final model`
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Half-normal key function 
#> 
#> Estimated abundance in covered region: 11568.28 
#> 
# }
```
