# Prepare data for trap rate estimation

Calculates observation counts and associated monitoring effort per
deployment to support trap rate estimation.

## Usage

``` r
ct_traprate_data(
  observation_data,
  use_deployment = TRUE,
  deployment_data = NULL,
  deployment_column,
  start_column = NULL,
  end_column = NULL,
  datetime_column = NULL,
  format = NULL,
  time_zone = "",
  time_unit = "days"
)
```

## Arguments

- observation_data:

  A data frame of detection records (e.g., camera trap images or
  events).

- use_deployment:

  Logical. If `TRUE` (default), effort is derived from deployment data.
  If `FALSE`, effort is estimated from observation timestamps.

- deployment_data:

  Optional. A data frame of deployment metadata; required if
  `use_deployment = TRUE`.

- deployment_column:

  The column name (unquoted or as a string) that uniquely identifies the
  deployment (e.g., camera ID).

- start_column:

  Optional. Start datetime column in the deployment data. Required if
  `use_deployment = TRUE`.

- end_column:

  Optional. End datetime column in the deployment data. Required if
  `use_deployment = TRUE`.

- datetime_column:

  Optional. The datetime column in `observation_data`; used if
  `use_deployment = FALSE`.

- format:

  A character string specifying the format of the datetime columns. If
  `NULL`, defaults to ISO 8601 format.

- time_zone:

  The time zone used to parse datetime values. Default is `""` (i.e.,
  system time zone).

- time_unit:

  Unit of time to compute effort and trap rate. One of `"secs"`,
  `"mins"`, `"hours"`, `"days"`, or `"weeks"`. Default is `"days"`.

## Value

A data frame with columns:

- `deployment_column`: Deployment identifier

- `n`: Number of observations per deployment

- `effort`: Monitoring duration

- `effort_unit`: Time unit used for effort

## See also

[`ct_get_effort()`](https://stangandaho.github.io/ct/reference/ct_get_effort.md)

## Examples

``` r
data("ctdp")
deployments <- ctdp$data$deployments
observations <- ctdp$data$observations %>%
                  dplyr::filter(scientificName == "Vulpes vulpes")

ct_traprate_data(observation_data = observations,
                 deployment_data = deployments,
                 use_deployment = TRUE,
                 deployment_column = deploymentID,
                 datetime_column = timestamp,
                 start = start, end = 'end'
                 )
#> # A tibble: 3 × 4
#>   deploymentID                             n effort effort_unit
#>   <chr>                                <int>  <dbl> <chr>      
#> 1 0d620d0e-5da8-42e6-bcf2-56c11fb3d08e     3  10.0  days       
#> 2 c95a566f-e75e-4e7b-a905-0479c8770da3     2   4.55 days       
#> 3 d6d42e25-be43-4820-909d-708e42219a86    10  12.6  days       
```
