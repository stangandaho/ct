# Prepare activity (time-of-day) data for REST

Keeps independent detections of each species and converts their time of
day to radians for circular activity modelling.

## Usage

``` r
ct_rest_activity(
  detection_data,
  station_column = "Station",
  species_column = "Species",
  datetime_column = "DateTime",
  independence_minutes = 30
)
```

## Arguments

- detection_data:

  A data frame with one row per detection.

- station_column, datetime_column:

  Columns for the station ID and datetime in `detection_data`.

- species_column:

  Column for species in `detection_data`.

- independence_minutes:

  Minimum gap (minutes) between successive detections at a station for
  them to count as independent.

## Value

A tibble with columns `Species`, `Station`, `time` (radians).

## Examples

``` r
data(rest_detection)

activity <- ct_rest_activity(rest_detection, independence_minutes = 30)
head(activity)
#> # A tibble: 6 × 3
#>   Species    Station  time
#>   <chr>      <chr>   <dbl>
#> 1 Red duiker ST01    5.92 
#> 2 Red duiker ST01    3.68 
#> 3 Red duiker ST01    3.07 
#> 4 Red duiker ST01    0.242
#> 5 Red duiker ST01    5.14 
#> 6 Red duiker ST01    0.670
```
