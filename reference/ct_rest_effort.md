# Add camera-trapping effort (days) to formatted station data

Effort is approximated as the span between the first and last detection.
When `term_col` is given, effort is computed per survey term and summed
per station so inactive gaps between terms are not counted.

## Usage

``` r
ct_rest_effort(
  detection_data,
  station_data,
  station_column = "Station",
  datetime_column = "DateTime",
  term_column = NULL,
  plot = FALSE
)
```

## Arguments

- detection_data:

  A data frame with one row per detection.

- station_data:

  A data frame from
  [`ct_rest_passes()`](https://stangandaho.github.io/ct/reference/ct_rest_passes.md)
  (must have a `Station` column).

- station_column, datetime_column:

  Columns for the station ID and datetime in `detection_data`.

- term_column:

  Optional column identifying survey terms; `NULL` to ignore.

- plot:

  If `TRUE`, draw a Gantt-style plot of operation periods.

## Value

`station_data` with an added `Effort` column (days). Stations with no or
zero effort are dropped with a warning.

## Examples

``` r
data(rest_detection)
data(rest_station)

stations <- ct_rest_passes(rest_detection, rest_station, model = "REST")
ct_rest_effort(rest_detection, stations)
#> # A tibble: 24 × 5
#>    Station Species      Y Habitat Effort
#>    <chr>   <chr>    <dbl> <chr>    <dbl>
#>  1 ST01    Bushbuck     9 forest    28.5
#>  2 ST02    Bushbuck     5 forest    21.3
#>  3 ST03    Bushbuck    11 forest    27.5
#>  4 ST04    Bushbuck    11 savanna   27.9
#>  5 ST05    Bushbuck     7 forest    26.4
#>  6 ST06    Bushbuck     9 forest    27.0
#>  7 ST07    Bushbuck     9 forest    26.8
#>  8 ST08    Bushbuck     7 savanna   26.3
#>  9 ST01    Civet        8 forest    28.5
#> 10 ST02    Civet        8 forest    21.3
#> # ℹ 14 more rows
```
