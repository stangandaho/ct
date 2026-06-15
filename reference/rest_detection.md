# Simulated camera-trap detections for the REST / RAD-REST workflow

A small simulated dataset illustrating the inputs needed by
[`ct_fit_rest()`](https://stangandaho.github.io/ct/reference/ct_fit_rest.md)
and the `ct_rest_*` preparation helpers. It contains detections of a
focal species (`"Red duiker"`) recorded at 8 stations over roughly one
month, together with two background species.

## Usage

``` r
rest_detection
```

## Format

A tibble with one row per video (detection) and columns:

- `Station`: Camera station ID.

- `Species`: Detected species name.

- `DateTime`: Capture time as a `"YYYY-MM-DD HH:MM:SS"` string.

- `y`: Number of passes through the focal area in that video (`NA` for
  background species).

- `Stay`: Staying time within the focal area in seconds (`NA` when the
  animal did not enter).

- `Cens`: Right-censoring flag for `Stay` (1 = censored, 0 = observed).

## See also

[rest_station](https://stangandaho.github.io/ct/reference/rest_station.md),
[`ct_fit_rest()`](https://stangandaho.github.io/ct/reference/ct_fit_rest.md)

## Examples

``` r
data(rest_detection)
head(rest_detection)
#> # A tibble: 6 × 6
#>   Station Species    DateTime                y  Stay  Cens
#>   <chr>   <chr>      <chr>               <int> <dbl> <int>
#> 1 ST01    Red duiker 2022-03-01 22:35:51     1   5.4     0
#> 2 ST01    Red duiker 2022-03-02 14:03:35     1   2.6     0
#> 3 ST01    Red duiker 2022-03-03 11:44:17     1   3.9     0
#> 4 ST01    Red duiker 2022-03-04 00:55:27     1   6       0
#> 5 ST01    Red duiker 2022-03-04 19:37:00     3   2.5     0
#> 6 ST01    Red duiker 2022-03-05 02:33:33     1   7.3     0
```
