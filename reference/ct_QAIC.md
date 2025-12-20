# Compute QAIC for a set of detection function models

Calculates the quasi-Akaike Information Criterion (QAIC) for one or more
detection function models within the same key function family. If
multiple models are provided, all must have the same key function. This
function is typically used as the first step of a two-step model
selection approach (Howe et al., 2019).

## Usage

``` r
ct_QAIC(models, chat = NULL, k = 2)
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

A tibble with one row per model containing:

- `model`: The model name

- `df`: The degrees of freedom for the model.

- `QAIC`: The computed QAIC value.

## Details

If only one model is supplied and `chat` is not provided, the function
estimates \\\hat{c}\\ using the provided model and issues a warning that
model selection cannot be performed. For multiple models, All models
must use the same key function.

QAIC is calculated as: \$\$QAIC = -2 \times \log(L) / \hat{c} + 2k\$\$
where \\L\\ is the likelihood, \\\hat{c}\\ is the estimated
overdispersion, and \\k\\ is the number of parameters.

## References

Howe, E. J., Buckland, S. T., Després‐Einspenner, M., & Kühl, H. S.
(2019). Model selection with overdispersed distance sampling data.
**Methods in Ecology and Evolution**, 10(1), 38-47.
[doi:10.1111/2041-210X.13082](https://doi.org/10.1111/2041-210X.13082)

## Examples

``` r
# \donttest{
library(Distance)
#> Loading required package: mrds
#> This is mrds 3.0.1
#> Built: R 4.5.0; ; 2025-07-06 04:17:12 UTC; unix
#> 
#> Attaching package: ‘Distance’
#> The following object is masked from ‘package:mrds’:
#> 
#>     create.bins
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

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
#> AIC= 15007.689
w3_hr1 <- ds(duiker_data, transect = "point", key = "hr", adjustment = "cos",
             order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting hazard-rate key function with cosine(2) adjustments
#> AIC= 15009.689
w3_hr2 <- ds(duiker_data, transect = "point", key = "hr", adjustment = "cos",
             order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting hazard-rate key function with cosine(2,4) adjustments
#> AIC= 15011.693
# fit half-normal key models
w3_hn0 <- ds(duiker_data, transect = "point", key = "hn", adjustment = NULL,
             truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function
#> AIC= 15034.041
w3_hn1 <- ds(duiker_data, transect = "point", key = "hn", adjustment = "cos",
             order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function with cosine(2) adjustments
#> AIC= 15009.335
w3_hn2 <- ds(duiker_data, transect = "point", key = "hn", adjustment = "cos",
             order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting half-normal key function with cosine(2,4) adjustments
#> AIC= 15004.757
# fit uniform key models
w3_u0 <- ds(duiker_data, transect = "point", key = "unif", adjustment = NULL,
            truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function
#> AIC= 17311.325
w3_u1 <- ds(duiker_data, transect = "point", key = "unif", adjustment = "cos",
            order = 2, truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function with cosine(2) adjustments
#> AIC= 17313.325
w3_u2 <- ds(duiker_data, transect = "point", key = "unif", adjustment = "cos",
            order = c(2, 4), truncation = truncation)
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Warning: Unknown or uninitialised column: `distend`.
#> Warning: Unknown or uninitialised column: `distbegin`.
#> Fitting uniform key function with cosine(2,4) adjustments
#> AIC= 17315.325

# Create model list
model_list <- list(w3_hn0, w3_hn1, w3_hn2,
                   w3_hr0, w3_hr1, w3_hr2,
                   w3_u0, w3_u1, w3_u2)

# Compute model QAICs
ct_QAIC(list(w3_hr0, w3_hr1, w3_hr2)) # All key functions must be the same
#> # A tibble: 3 × 3
#>   model                                                    df  QAIC
#>   <chr>                                                 <int> <dbl>
#> 1 hazard-rate key function                                  2  52.3
#> 2 hazard-rate key function with cosine(2) adjustments       3  54.3
#> 3 hazard-rate key function with cosine(2,4) adjustments     4  56.3
ct_QAIC(list(w3_hn0, w3_hn1, w3_hn2)) # All key functions must be the same
#> # A tibble: 3 × 3
#>   model                                                    df  QAIC
#>   <chr>                                                 <int> <dbl>
#> 1 half-normal key function                                  1  51.7
#> 2 half-normal key function with cosine(2) adjustments       2  53.6
#> 3 half-normal key function with cosine(2,4) adjustments     3  55.6

# Compute Chi-squared Goodness-of-fit
ct_chi2_select(list(w3_hn0, w3_hr0, w3_u0)) # All key functions must be different
#> # A tibble: 3 × 3
#>   key         model                    criteria
#>   <chr>       <chr>                       <dbl>
#> 1 half-normal half-normal key function     305.
#> 2 hazard-rate hazard-rate key function     312.
#> 3 uniform     uniform key function         455.
ct_chi2_select(list(w3_hn2, w3_hr1, w3_u0)) # All key functions must be different
#> # A tibble: 3 × 3
#>   key         model                                                 criteria
#>   <chr>       <chr>                                                    <dbl>
#> 1 half-normal half-normal key function with cosine(2,4) adjustments     315.
#> 2 hazard-rate hazard-rate key function with cosine(2) adjustments       318.
#> 3 uniform     uniform key function                                      455.

# Two-step model selection
ct_select_model(model_list)
#> $QAIC
#> # A tibble: 9 × 6
#>      id key         model                                         df  QAIC best 
#>   <int> <chr>       <chr>                                      <int> <dbl> <lgl>
#> 1     1 half-normal half-normal key function                       1  51.7 TRUE 
#> 2     2 half-normal half-normal key function with cosine(2) a…     2  53.6 FALSE
#> 3     3 half-normal half-normal key function with cosine(2,4)…     3  55.6 FALSE
#> 4     4 hazard-rate hazard-rate key function                       2  52.3 TRUE 
#> 5     5 hazard-rate hazard-rate key function with cosine(2) a…     3  54.3 FALSE
#> 6     6 hazard-rate hazard-rate key function with cosine(2,4)…     4  56.3 FALSE
#> 7     7 uniform     uniform key function                           0  38.7 TRUE 
#> 8     8 uniform     uniform key function with cosine(2) adjus…     1  40.7 FALSE
#> 9     9 uniform     uniform key function with cosine(2,4) adj…     2  42.7 FALSE
#> 
#> $`Best QAIC models`
#> $`Best QAIC models`[[1]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Half-normal key function 
#> 
#> Estimated abundance in covered region: 11630.7 
#> 
#> $`Best QAIC models`[[2]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Hazard-rate key function 
#> 
#> Estimated abundance in covered region: 8213.104 
#> 
#> $`Best QAIC models`[[3]]
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Uniform key function 
#> 
#> Estimated abundance in covered region: 3133.71 
#> 
#> 
#> $Chi2
#> # A tibble: 3 × 4
#>   key         model                    criteria best 
#>   <chr>       <chr>                       <dbl> <lgl>
#> 1 half-normal half-normal key function     305. TRUE 
#> 2 hazard-rate hazard-rate key function     312. FALSE
#> 3 uniform     uniform key function         455. FALSE
#> 
#> $`Final model`
#> 
#> Distance sampling analysis object
#> 
#> Detection function:
#>  Half-normal key function 
#> 
#> Estimated abundance in covered region: 11630.7 
#> 
# }
```
