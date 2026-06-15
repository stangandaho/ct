# Prepare staying-time data for REST

Selects and standardises the staying-time and censoring columns from a
detection table and attaches per-station covariates.

## Usage

``` r
ct_rest_stay(
  detection_data,
  station_data,
  station_column = "Station",
  species_column = "Species",
  stay_column = "Stay",
  censor_column = "Cens"
)
```

## Arguments

- detection_data:

  A data frame with one row per video / detection.

- station_data:

  A data frame with one row per camera station.

- station_column, species_column:

  Columns giving the station ID and species in `detection_data`.

- stay_column:

  Column holding the staying time in seconds.

- censor_column:

  Column holding the censoring flag (1 = censored, 0 = fully observed).

## Value

A tibble with columns `Station`, `Species`, `Stay`, `Cens` plus any
station covariates, ready for
[`ct_fit_rest()`](https://stangandaho.github.io/ct/reference/ct_fit_rest.md).

## Examples

``` r
data(rest_detection)
data(rest_station)

# Column names can be strings, bare names, or positions:
stay <- ct_rest_stay(rest_detection, rest_station, stay_column = Stay)
head(stay)
#> # A tibble: 6 × 5
#>   Station Species     Stay  Cens Habitat
#>   <chr>   <chr>      <dbl> <int> <chr>  
#> 1 ST01    Red duiker   5.4     0 forest 
#> 2 ST01    Red duiker   2.6     0 forest 
#> 3 ST01    Red duiker   3.9     0 forest 
#> 4 ST01    Red duiker   6       0 forest 
#> 5 ST01    Red duiker   2.5     0 forest 
#> 6 ST01    Red duiker   7.3     0 forest 
```
