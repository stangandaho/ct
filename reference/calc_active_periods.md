# Calculate active periods for camera trap data

Internal helper function to calculate continuous active periods based on
gap detection.

## Usage

``` r
calc_active_periods(data, threshold, time_unit)
```

## Arguments

- data:

  A data frame containing the datetime column.

- threshold:

  A numeric value indicating the minimum gap to be considered a break
  (default is 10).

- time_unit:

  The unit for the threshold. Supported values include "secs", "mins",
  "hours", "days", and "weeks".

## Value

A tibble with period_start and period_end columns.
