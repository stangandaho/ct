# Transform time to solar time anchored to sunrise and sunset

This function converts local time to solar time based on the sunrise and
sunset times for a given location. Solar time is a timekeeping system
where the day is defined by the position of the sun in the sky, with
sunrise marking the start of the day and sunset marking the end.

## Usage

``` r
ct_solartime(
  data = NULL,
  date,
  longitude,
  latitude,
  crs = NULL,
  format,
  time_zone,
  ...
)
```

## Arguments

- data:

  A data frame containing the date, longitude, and latitude columns. If
  `NULL`, the function will use the `date`, `longitude`, and `latitude`
  parameters directly. Default is `NULL`.

- date:

  A vector of date-time values or a column name in `data` representing
  the date-time values to be converted to solar time. This can be a
  character vector or a `POSIXlt` object.

- longitude:

  A numeric vector or a column name in `data` representing the longitude
  of the location(s). Longitude should be in decimal degrees.

- latitude:

  A numeric vector or a column name in `data` representing the latitude
  of the location(s). Latitude should be in decimal degrees.

- crs:

  A coordinate reference system (CRS) string or object specifying the
  current CRS of the input coordinates. If provided, the function will
  transform the coordinates to longitude and latitude (WGS84). This is
  useful when the input coordinates are in a projected system (e.g.,
  UTM). Default is `NULL`.

- format:

  character string giving a date-time format as used by
  [`strptime()`](https://rdrr.io/r/base/strptime.html).

- time_zone:

  A numeric vector representing the time zone offset(s) from UTC (in
  hours). If `data` is provided, this should match the number of unique
  locations in the data.

- ...:

  Additional arguments passed to `as.POSIXlt` for date parsing.

## Value

A tibble with the following columns:

- `input`: The original date-time values.

- `clock`: The local clock time.

- `solar`: The calculated solar time.

If `data` is provided, the tibble will also include the longitude and
latitude columns.

## Details

The function calculates solar time by first determining the sunrise and
sunset times for the given location(s) and date(s). It then uses these
times to anchor the solar time calculation. The solar time is computed
by transforming the local clock time based on the position of the sun in
the sky.

If `data` is provided, the function will process each unique location in
the data and return a tibble with the solar time for each date-time
value. If `data` is `NULL`, the function will process the `date`,
`longitude`, and `latitude` parameters directly.

## References

Rowcliffe, M. (2023). activity: Animal Activity Statistics. R package
version 1.3.4. https://CRAN.R-project.org/package=activity

## Examples

``` r
library(dplyr)

read.csv(system.file("penessoulou_season1.csv", package = "ct")) %>%
 dplyr::filter(species == "Erythrocebus patas") %>%
 # Select independent events based on a given threshold
 ct::ct_independence(species_column = species,
                          datetime = datetimes, threshold = 60*5, # 5 minutes
                          format = "%Y-%m-%d %H:%M:%S"
                          ) %>%
 # Transform Time to Solar Time
 ct_solartime(data = ., date = datetime, longitude = longitude, latitude = latitude,
               crs = "EPSG:32631", time_zone = 1)
#> # A tibble: 77 × 5
#>    longitude latitude datetime            clock solar
#>        <dbl>    <dbl> <dttm>              <dbl> <dbl>
#>  1      1.57     9.28 2024-03-17 15:14:29  3.99  3.97
#>  2      1.57     9.28 2024-03-20 11:32:33  3.02  3.00
#>  3      1.57     9.28 2024-03-21 14:34:27  3.82  3.80
#>  4      1.57     9.28 2024-03-21 14:54:21  3.90  3.89
#>  5      1.57     9.28 2024-03-22 14:23:41  3.77  3.75
#>  6      1.57     9.28 2024-03-22 14:51:09  3.89  3.88
#>  7      1.57     9.28 2024-03-25 13:38:37  3.57  3.56
#>  8      1.57     9.28 2024-03-25 13:50:19  3.62  3.61
#>  9      1.57     9.28 2024-03-28 17:06:38  4.48  4.48
#> 10      1.57     9.28 2024-03-29 11:22:19  2.98  2.97
#> # ℹ 67 more rows
```
