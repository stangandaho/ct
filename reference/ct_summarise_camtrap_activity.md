# Create activity summary statistics

Calculates summary statistics for camera trap activity periods.

## Usage

``` r
ct_summarise_camtrap_activity(
  data,
  deployment_column,
  datetime_column,
  threshold = 5,
  time_unit = "days",
  format = NULL
)
```

## Arguments

- data:

  A data frame containing the datetime column.

- deployment_column:

  Character. Column name for deployment identifiers.

- datetime_column:

  The datetime column.

- threshold:

  A numeric value indicating the minimum gap to be considered a break
  (default is 10).

- time_unit:

  The unit for the threshold. Supported values include "secs", "mins",
  "hours", "days", and "weeks".

- format:

  Optional. A character string specifying the datetime format, passed to
  `as.POSIXlt`.

## Value

A tibble with activity summary statistics for each deployment.

## Examples

``` r
# Get activity summary
camtrap_data <- read.csv(ct:::table_files()[1]) %>%
dplyr::filter(project == "Last")

  ct_summarise_camtrap_activity(data = camtrap_data,
                                deployment_column = "camera",
                                datetime_column = datetimes,
                                threshold = 15,
                                time_unit = "days")
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> Warning: No deployment has a gap exceeding 15 days.
#> # A tibble: 11 × 11
#>    camera       n_records first_record        last_record         total_duration
#>    <chr>            <int> <dttm>              <dttm>                       <dbl>
#>  1 CAMERA 10          724 2024-03-10 20:09:27 2024-05-09 22:43:34          60.1 
#>  2 CAMERA 3             8 2024-03-12 00:07:36 2024-04-01 13:09:35          20.5 
#>  3 CAMERA 5           202 2024-03-12 02:54:31 2024-05-02 05:33:28          51.1 
#>  4 CAMERA 8           113 2024-03-21 03:52:51 2024-05-10 20:07:12          50.7 
#>  5 CAMERA 2            14 2024-03-23 12:36:25 2024-04-01 01:22:52           8.53
#>  6 CAMERA 1           264 2024-03-24 08:03:07 2024-04-26 01:00:52          32.7 
#>  7 CAMERA 12            3 2024-03-25 09:43:58 2024-03-25 09:43:59           0   
#>  8 CAMERA 4            21 2024-03-27 09:33:07 2024-04-05 00:14:29           8.61
#>  9 CAMERA 11            3 2024-04-04 21:58:33 2024-04-04 21:58:33           0   
#> 10 CAMERA 3 - …         4 2024-04-27 23:00:05 2024-05-12 23:30:09          15.0 
#> 11 CAMERA 1 - …        31 2024-05-05 03:46:58 2024-05-07 00:00:37           1.84
#> # ℹ 6 more variables: active_duration <dbl>, break_duration <dbl>,
#> #   activity_rate <dbl>, n_breaks <dbl>, n_active_periods <int>,
#> #   avg_break_duration <dbl>
```
