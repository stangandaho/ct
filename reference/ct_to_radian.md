# Convert time to radians

This function converts time values into radians, which is often used in
circular statistics and time-of-day analyses.

## Usage

``` r
ct_to_radian(data, times, format = "%H:%M:%S", time_zone = "UTC")
```

## Arguments

- data:

  A data frame containing a column with time values. Optional. If
  `NULL`, the `times` parameter is treated as a standalone vector.

- times:

  A column name in the `data` or a vector of time values to be
  converted. Time values should be in a format recognized by
  [`as.POSIXct()`](https://rdrr.io/r/base/as.POSIXlt.html).

- format:

  A string specifying the format of the time values, using the standard
  POSIX formatting syntax. Default is `"%H:%M:%S"`.

- time_zone:

  A string specifying the time zone for interpreting the time values.
  Default is `"UTC"`.

## Value

If `data` is provided, the function returns the input data frame with an
additional column named `time_radian`. If `data` is not provided, the
function returns a numeric vector of time values converted to radians.

## Details

This function converts time values into radians based on a 24-hour
clock:

- A full day (24 hours) corresponds to \\2\pi\\ radians.

- The fractional time of the day is calculated as: \$\$\text{Fraction of
  the day} = \frac{\text{hours}}{24} + \frac{\text{minutes}}{1440} +
  \frac{\text{seconds}}{86400}\$\$

For example, for a time of 23 hours, 6 minutes, and 12 seconds:
\$\$\text{Fraction of the day} = \frac{23}{24} + \frac{6}{1440} +
\frac{12}{86400}\$\$

To convert this fraction into radians: \$\$\text{Radians} =
\text{Fraction of the day} \times 2\pi\$\$

## Examples

``` r
if (FALSE) { # \dontrun{
  # Convert a standalone vector of time values
  times <- c("00:00:00", "06:00:00", "12:00:00", "18:00:00")
  ct_to_radian(times = times, format = "%H:%M:%S")

  # Convert a column of time values in a data frame
  data <- data.frame(times = c("00:00:00", "06:00:00", "12:00:00", "18:00:00"))
  ct_to_radian(data = data, times = times, format = "%H:%M:%S")
} # }
```
