# Correct camera trap datetime records

This function corrects datetime stamps in camera trap data using a
reference correction table. It applies time adjustments based on known
timing errors for each camera deployment.

## Usage

``` r
ct_correct_datetime(
  data,
  datetime,
  deployment,
  corrector,
  format = NULL,
  time_zone = "UTC"
)
```

## Arguments

- data:

  A data.frame or tibble containing camera trap records with datetime
  information that needs correction.

- datetime:

  Column name (unquoted) in `data` containing the datetime values to be
  corrected. Can be character or POSIXct format.

- deployment:

  Column name (unquoted) in both `data` and `corrector` that identifies
  unique camera deployments (e.g., camera ID, site name, or deployment
  identifier).

- corrector:

  A data.frame containing correction information with columns:

  - deployment column matching the deployment parameter

  - `sign` - character indicating correction direction ("+" or "-")

  - `datetimes` - correct date-time of the first (earliest) record of
    the deployment

  - `end_datetimes` - optional; correct date-time of the last (latest)
    record of the deployment. When present and not missing, the
    correction drifts linearly between the first and the last record.

- format:

  Optional datetime format specification. Can be:

  - `NULL` (default) - attempts multiple common formats

  - Single format string - used for both `data` and `corrector`
    datetimes

  - Vector of 2 format strings - first for data, second for corrector

- time_zone:

  Time zone used to parse the datetimes in `data` and `corrector`.
  Defaults to `"UTC"`, which has no daylight saving time and so keeps
  camera wall-clock times unchanged. Any time zone name accepted by
  [`as.POSIXct()`](https://rdrr.io/r/base/as.POSIXlt.html) can be used,
  for example [`Sys.timezone()`](https://rdrr.io/r/base/timezones.html)
  for the computer's time zone when the deployment does not span a
  daylight-saving change.

## Value

A data.frame with the original data plus additional columns:

- `corrected_datetime` - corrected datetime as POSIXct

- `correction_applied` - sign of correction applied

- `time_offset_seconds` - magnitude of correction in seconds (varies
  between records when drift is corrected)

- `corrector_reference` - reference datetime used for correction

## Details

Two kinds of clock error are handled. A constant offset (a camera set to
the wrong date or time) is corrected from the true datetime of the first
record of each deployment. Clock drift (a camera that gains or loses
time during the deployment) is corrected when the true datetime of the
last record is also supplied: the correction then changes linearly with
time, from the offset at the first record to the offset at the last
record.

Camera clocks do not change for daylight saving time. Datetimes are
therefore parsed in the time zone given by `time_zone`, which defaults
to `"UTC"` (no daylight saving), so that recorded wall-clock times are
kept as they are and no record is shifted or lost at a daylight saving
change.

## Examples

``` r
# Load camera trap data
library(dplyr)
data(penessoulou)

camtrap_data <- penessoulou %>%
  dplyr::filter(project == "Last")

# Create correction table
# CAMERA 1 was running slow (+), CAMERA 2 was running fast (-)
crtor <- data.frame(
  camera = c("CAMERA 1", "CAMERA 2"),
  sign = c("+", "-"),
  datetimes = c("2025-03-14 8:17:00", "2024-11-14 10:02:03")
)

# Apply datetime corrections
ct_correct_datetime(
  data = camtrap_data,
  datetime = datetimes,
  deployment = camera,
  corrector = crtor
) %>%
  dplyr::select(datetimes,
                corrected_datetime,
                time_offset_seconds) %>%
  dplyr::slice_head(n = 10)
#> # A tibble: 10 × 3
#>    datetimes           corrected_datetime  time_offset_seconds
#>    <chr>               <dttm>                            <dbl>
#>  1 2024-03-24 8:03:07  2025-03-14 08:17:00            30672833
#>  2 2024-03-24 8:03:07  2025-03-14 08:17:00            30672833
#>  3 2024-03-24 8:03:08  2025-03-14 08:17:01            30672833
#>  4 2024-03-24 20:19:35 2025-03-14 20:33:28            30672833
#>  5 2024-03-24 20:19:35 2025-03-14 20:33:28            30672833
#>  6 2024-03-24 20:19:35 2025-03-14 20:33:28            30672833
#>  7 2024-03-24 20:20:02 2025-03-14 20:33:55            30672833
#>  8 2024-03-24 20:20:02 2025-03-14 20:33:55            30672833
#>  9 2024-03-24 20:20:03 2025-03-14 20:33:56            30672833
#> 10 2024-03-24 20:20:24 2025-03-14 20:34:17            30672833

# Clock drift: CAMERA 1 also lost 90 s over the deployment, so the true time
# of its last record is 90 s later than the constant offset gives
crtor_drift <- crtor
crtor_drift$end_datetimes <- c("2025-04-16 01:16:15", NA)

ct_correct_datetime(
  data = camtrap_data,
  datetime = datetimes,
  deployment = camera,
  corrector = crtor_drift
) %>%
  dplyr::filter(camera == "CAMERA 1") %>%
  dplyr::select(datetimes, corrected_datetime, time_offset_seconds) %>%
  dplyr::slice_tail(n = 5)
#> # A tibble: 5 × 3
#>   datetimes          corrected_datetime  time_offset_seconds
#>   <chr>              <dttm>                            <dbl>
#> 1 2024-04-26 1:00:21 2025-04-16 01:15:43           30672923.
#> 2 2024-04-26 1:00:21 2025-04-16 01:15:43           30672923.
#> 3 2024-04-26 1:00:51 2025-04-16 01:16:13           30672923.
#> 4 2024-04-26 1:00:52 2025-04-16 01:16:15           30672923 
#> 5 2024-04-26 1:00:52 2025-04-16 01:16:15           30672923 
```
