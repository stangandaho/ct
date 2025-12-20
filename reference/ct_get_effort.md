# Calculate camera trap deployment effort

Computes the monitoring effort (e.g., in days) for each camera
deployment based on start and end timestamps.

## Usage

``` r
ct_get_effort(
  deployment_data,
  start_column,
  end_column,
  deployment_column,
  format = "%Y-%m-%d %H:%M:%OS",
  time_zone = "",
  time_unit = "days"
)
```

## Arguments

- deployment_data:

  A data frame containing camera trap deployment records.

- start_column:

  The column name (unquoted or as a string) indicating deployment start
  datetime.

- end_column:

  The column name (unquoted or as a string) indicating deployment end
  datetime.

- deployment_column:

  The column name (unquoted or as a string) that uniquely identifies the
  deployment (e.g., camera ID).

- format:

  A character string specifying the format of the datetime columns.
  Default is `"%Y-%m-%d %H:%M:%OS"`.

- time_zone:

  The time zone used to parse the datetime columns. Default is `""`
  (i.e., system time zone).

- time_unit:

  The unit in which to compute the effort duration. Can be `"secs"`,
  `"mins"`, `"hours"`, `"days"`, or `"weeks"`. Default is `"days"`.

## Value

A data frame with columns:

- `deployment_column`: Deployment identifier

- `effort`: Numeric value of monitoring effort

- `effort_unit`: The time unit used

## See also

[`ct_traprate_data()`](https://stangandaho.github.io/ct/reference/ct_traprate_data.md)

## Examples

``` r
data("ctdp")
deployments <- ctdp$data$deployments
ct_get_effort(deployment_data = deployments,
              deployment_column = deploymentID,
              start_column = start,
              end_column = end)
#> # A tibble: 4 × 3
#>   deploymentID                         effort effort_unit
#>   <chr>                                 <dbl> <chr>      
#> 1 0d620d0e-5da8-42e6-bcf2-56c11fb3d08e  10.0  days       
#> 2 6c920a31-cf07-496f-aa4f-846a428f450a   6.76 days       
#> 3 c95a566f-e75e-4e7b-a905-0479c8770da3   4.55 days       
#> 4 d6d42e25-be43-4820-909d-708e42219a86  12.6  days       
```
