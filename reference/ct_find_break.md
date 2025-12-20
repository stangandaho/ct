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
pene <- read.csv(ct:::table_files()[1])

set_cam <- pene %>%
  dplyr::filter(camera == "CAMERA 3")

ct_find_break(data = pene, datetime_column = "datetimes",
threshold = 5, time_unit = "days")
#> # A tibble: 3 × 3
#>   start               end                 duration
#>   <dttm>              <dttm>                 <dbl>
#> 1 2019-01-24 06:05:52 2023-09-20 16:15:28  1700.  
#> 2 2023-09-21 13:33:27 2024-03-02 22:32:10   163.  
#> 3 2024-03-02 22:33:06 2024-03-10 10:21:56     7.49
```
