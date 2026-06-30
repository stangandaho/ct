# Detect time gaps in a datetime series

Identifies breaks in a sequence of datetime observations based on a
specified time threshold.

## Usage

``` r
ct_find_break(
  data,
  datetime_column,
  format,
  threshold = 10,
  time_unit = "hours"
)
```

## Arguments

- data:

  A data frame containing the datetime column.

- datetime_column:

  The datetime column.

- format:

  Optional. A character string specifying the datetime format, passed to
  `as.POSIXlt`.

- threshold:

  A numeric value indicating the minimum gap to be considered a break
  (default is 10).

- time_unit:

  The unit for the threshold. Supported values include "secs", "mins",
  "hours", "days", and "weeks".

## Value

A tibble with columns `start`, `end`, and `duration` showing the start
and end of each break and its length.

## Examples

``` r
library(dplyr)
data(penessoulou)

pene <- penessoulou %>%
  dplyr::filter(project == "Last")


set_cam <- pene %>%
  dplyr::filter(camera == "CAMERA 3")

ct_find_break(data = pene, datetime_column = "datetimes",
threshold = 5, time_unit = "days")
#> Warning: No deployment has a gap exceeding 5 days.
```
