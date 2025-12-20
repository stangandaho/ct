# Calculate daily camera trap captures

Aggregates camera trap data into daily capture summaries.

## Usage

``` r
ct_camera_day(
  data,
  deployment_data = NULL,
  deployment_column,
  datetime_column,
  species_column,
  size_column,
  format,
  start_column = NULL,
  end_column = NULL,
  deployment_format = format,
  time_zone = ""
)
```

## Arguments

- data:

  A data frame containing camera trap observation data.

- deployment_data:

  A data frame containing camera trap deployment records.

- deployment_column:

  The column name (unquoted or as a string) that uniquely identifies the
  deployment (e.g., camera ID).

- datetime_column:

  Column in `data` containing observation timestamps. Can be supplied as
  a bare name, quoted string, or column position.

- species_column:

  The column in the data frame representing species identifiers. Can be
  specified as a string or unquoted column name.

- size_column:

  (Optional) The column representing the size or abundance of the
  species at each site. If not provided, counts of species occurrences
  are calculated.

- format:

  Character string specifying the datetime format for parsing
  `datetime_column`.

- start_column:

  The column name (unquoted or as a string) indicating deployment start
  datetime.

- end_column:

  The column name (unquoted or as a string) indicating deployment end
  datetime.

- deployment_format:

  Character string specifying the datetime format for parsing
  `start_column` and `end_column`. Defaults to the same format as
  `format`.

- time_zone:

  The time zone used to parse the datetime columns. Default is `""`
  (i.e., system time zone).

## Value

A tibble with the following columns:

- `deployment_column` (camera/location identifier)

- `date` (Date of observation)

- `species_column` (species name)

- `size_column` (daily count, `0` if no observations)

- `sampling_unit` (unique identifier for location × date combination)

## See also

[`ct_inext()`](https://stangandaho.github.io/ct/reference/ct_inext.md),
[`ct_get_effort()`](https://stangandaho.github.io/ct/reference/ct_get_effort.md)

## Examples

``` r
# Example observation data
obs <- data.frame(
  species = c("Deer", "Deer", "Fox", "Deer"),
  count = c(2, 1, 1, 3),
  datetime = c("2023-06-01 08:12:00", "2023-06-01 15:30:00",
               "2023-06-01 21:10:00", "2023-06-02 06:45:00"),
  location_id = c("Cam1", "Cam1", "Cam1", "Cam1"),
  stringsAsFactors = FALSE
)

# Example deployment data
dep <- data.frame(
  location_id = c("Cam1"),
  deploy_start = "2023-06-01 00:00:00",
  deploy_end = "2023-06-03 23:59:59",
  stringsAsFactors = FALSE
)

ct_camera_day(
  data = obs,
  deployment_data = dep,
  datetime_column = "datetime",
  species_column = "species",
  size_column = "count",
  deployment_column = "location_id",
  format = "%Y-%m-%d %H:%M:%S",
  start_column = "deploy_start",
  end_column = "deploy_end"
)
#> # A tibble: 6 × 5
#>   location_id date       species count sampling_unit
#>   <chr>       <date>     <chr>   <dbl> <chr>        
#> 1 Cam1        2023-06-01 Deer        3 Cam120230601 
#> 2 Cam1        2023-06-01 Fox         1 Cam120230601 
#> 3 Cam1        2023-06-02 Deer        3 Cam120230602 
#> 4 Cam1        2023-06-02 Fox         0 Cam120230602 
#> 5 Cam1        2023-06-03 Deer        0 Cam120230603 
#> 6 Cam1        2023-06-03 Fox         0 Cam120230603 
```
