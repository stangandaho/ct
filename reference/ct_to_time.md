# Convert radian to time

This function converts an angle in radians (representing a fraction of a
full circle) into a time in the format '%H:%M:%S'. The conversion
assumes that the radian value represents a fraction of a 24-hour day
(i.e., 0 radians is midnight and \\2\pi\\ radians is the next midnight).

## Usage

``` r
ct_to_time(radian)
```

## Arguments

- radian:

  A numeric value or vector representing an angle in radians. The value
  must lie within the range \\\[0, 2\pi\]\\, where 0 corresponds to
  midnight (00:00:00) and \\2\pi\\ corresponds to the next midnight
  (24:00:00).

## Value

A character string representing the time in the format '%H:%M:%S'.

## See also

[`ct_to_radian()`](https://stangandaho.github.io/ct/reference/ct_to_radian.md)

## Examples

``` r
# Convert 1.6 radians to time
ct_to_time(1.6)
#> [1] "06:06:42"
# Output: "06:06:42"
```
