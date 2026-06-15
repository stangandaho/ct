# Camera-station table for the REST / RAD-REST example

Per-station information to accompany
[rest_detection](https://stangandaho.github.io/ct/reference/rest_detection.md),
with one row per station and a habitat covariate that can be used in
`density_formula` or `stay_formula`.

## Usage

``` r
rest_station
```

## Format

A tibble with one row per station and columns:

- `Station`: Camera station ID.

- `Habitat`: Habitat type at the station (`"forest"` or `"savanna"`).

## See also

[rest_detection](https://stangandaho.github.io/ct/reference/rest_detection.md),
[`ct_fit_rest()`](https://stangandaho.github.io/ct/reference/ct_fit_rest.md)

## Examples

``` r
data(rest_station)
rest_station
#> # A tibble: 8 × 2
#>   Station Habitat
#>   <chr>   <chr>  
#> 1 ST01    forest 
#> 2 ST02    forest 
#> 3 ST03    forest 
#> 4 ST04    savanna
#> 5 ST05    forest 
#> 6 ST06    forest 
#> 7 ST07    forest 
#> 8 ST08    savanna
```
