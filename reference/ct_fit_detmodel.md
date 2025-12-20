# Fit animal detection

Fits a detection function (either point or line transect) to model
detection radius or angle.

## Usage

``` r
ct_fit_detmodel(
  formula,
  data,
  newdata = NULL,
  unit = c("m", "km", "cm", "degree", "radian"),
  ...
)
```

## Arguments

- formula:

  A formula specifying the response (e.g., `radius ~ 1` or
  `angle ~ covariate`).

- data:

  A data frame containing detection observations.

- newdata:

  Optional new data frame with covariate values for prediction.

- unit:

  Unit of the detection variable. One of `"m"`, `"km"`, `"cm"` for
  distance, or `"degree"`, `"radian"` for angle.

- ...:

  Additional arguments passed to
  [`Distance::ds()`](https://rdrr.io/pkg/Distance/man/ds.html).

## Value

a list with elements:

- `ddf` a detection function model object.

- `dht` abundance/density information (if survey region data was
  supplied, else `NULL`)

## See also

[`ct_fit_rem()`](https://stangandaho.github.io/ct/reference/ct_fit_rem.md),
[`ct_fit_speedmodel()`](https://stangandaho.github.io/ct/reference/ct_fit_speedmodel.md),
[`ct_fit_activity()`](https://stangandaho.github.io/ct/reference/ct_fit_activity.md)

## Examples

``` r
data("ctdp")
observations <- ctdp$data$observations %>%
  dplyr::filter(scientificName == "Vulpes vulpes")

ct_fit_detmodel(radius ~ 1, data = observations)
#> Error in -lt$value : invalid argument to unary operator
#> 
#> Distance sampling analysis object
#> 
#> Summary for ds object
#> Number of observations :  5 
#> Distance range         :  0  -  7.226863 
#> AIC                    :  22.73211 
#> Optimisation           :  mrds (nlminb) 
#> 
#> Detection function:
#>  Half-normal key function 
#> 
#> Detection function parameters 
#> Scale coefficient(s): 
#>             estimate        se
#> (Intercept) 1.722192 0.6432342
#> 
#>                      Estimate        SE        CV
#> Average p           0.6783846 0.3138098 0.4625839
#> N in covered region 7.3704500 3.8882665 0.5275481
#> EDR                 5.9523416 1.3767287 0.2312920

# For angle
ct_fit_detmodel(angle ~ 1, data = observations)
#> Error in -lt$value : invalid argument to unary operator
#> 
#> Distance sampling analysis object
#> 
#> Summary for ds object
#> Number of observations :  5 
#> Distance range         :  0  -  0.5841587 
#> AIC                    :  0.3802033 
#> Optimisation           :  mrds (nlminb) 
#> 
#> Detection function:
#>  Half-normal key function 
#> 
#> Detection function parameters 
#> Scale coefficient(s): 
#>              estimate        se
#> (Intercept) -1.606023 0.1353736
#> 
#>                      Estimate          SE        CV
#> Average p            0.232632  0.05906989 0.2539199
#> N in covered region 21.493176 10.03408954 0.4668500
#> EDR                  0.281751  0.03577110 0.1269600
```
