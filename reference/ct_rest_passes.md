# Aggregate the number of animal passes per station for REST / RAD-REST

Aggregate the number of animal passes per station for REST / RAD-REST

## Usage

``` r
ct_rest_passes(
  detection_data,
  station_data,
  station_column = "Station",
  species_column = "Species",
  passes_column = "y",
  model = c("REST", "RAD-REST")
)
```

## Arguments

- detection_data:

  A data frame with one row per video / detection.

- station_data:

  A data frame with one row per camera station.

- station_column, species_column:

  Columns giving the station ID and species in `detection_data`.

- passes_column:

  Column holding the number of passes per video.

- model:

  Either `"REST"` (totals as `Y`) or `"RAD-REST"` (per-video pass counts
  spread into `y_0`, `y_1`, ... plus the video total `N`).

## Value

A tibble with one row per station x species, ready for
[`ct_rest_effort()`](https://stangandaho.github.io/ct/reference/ct_rest_effort.md).

## Examples

``` r
data(rest_detection)
data(rest_station)

# Original REST: total passes (Y) per station
ct_rest_passes(rest_detection, rest_station, model = "REST")
#> # A tibble: 24 × 4
#>    Station Species      Y Habitat
#>    <chr>   <chr>    <dbl> <chr>  
#>  1 ST01    Bushbuck     9 forest 
#>  2 ST02    Bushbuck     5 forest 
#>  3 ST03    Bushbuck    11 forest 
#>  4 ST04    Bushbuck    11 savanna
#>  5 ST05    Bushbuck     7 forest 
#>  6 ST06    Bushbuck     9 forest 
#>  7 ST07    Bushbuck     9 forest 
#>  8 ST08    Bushbuck     7 savanna
#>  9 ST01    Civet        8 forest 
#> 10 ST02    Civet        8 forest 
#> # ℹ 14 more rows

# RAD-REST: videos split by number of passes (y_0, y_1, ...)
ct_rest_passes(rest_detection, rest_station, model = "RAD-REST")
#> # A tibble: 24 × 9
#>    Station Species      N   y_0   y_1   y_2   y_3   y_4 Habitat
#>    <chr>   <chr>    <int> <int> <int> <int> <int> <int> <chr>  
#>  1 ST01    Bushbuck     9     0     0     0     0     0 forest 
#>  2 ST02    Bushbuck     5     0     0     0     0     0 forest 
#>  3 ST03    Bushbuck    11     0     0     0     0     0 forest 
#>  4 ST04    Bushbuck    11     0     0     0     0     0 savanna
#>  5 ST05    Bushbuck     7     0     0     0     0     0 forest 
#>  6 ST06    Bushbuck     9     0     0     0     0     0 forest 
#>  7 ST07    Bushbuck     9     0     0     0     0     0 forest 
#>  8 ST08    Bushbuck     7     0     0     0     0     0 savanna
#>  9 ST01    Civet        8     0     0     0     0     0 forest 
#> 10 ST02    Civet        8     0     0     0     0     0 forest 
#> # ℹ 14 more rows
```
