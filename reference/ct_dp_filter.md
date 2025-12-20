# Filter camera trap data package

Subsets observations in camera trap data package, retaining all rows
that satisfy the conditions.

## Usage

``` r
ct_dp_filter(package, table = c("observations", "deployments", "media"), ...)
```

## Arguments

- package:

  Camera trap data package object, as returned by ct_read_dp().

- table:

  Character indicating the table to read - one "observations",
  "deployments", or "media"

- ...:

  Filtering conditions, see dplyr::filter()

## Examples

``` r
# \donttest{
dp <- ct_dp_example()
ct_dp_filter(package = dp, table = "observation",
scientificName == "Vulpes vulpes", observationLevel == "event"
)
#> A Camera Trap Data Package "camtrap-dp-example-dataset" with 3 tables:
#> • deployments: 4 rows
#> • media: 10 rows
#> • observations: 1 rows
#> 
#> And 1 additional resource:
#> • individuals
#> Use `unclass()` to print the Data Package as a list.

ct_dp_filter(package = dp, table = "deployments",
             latitude > 51.0, longitude > 5.0)
#> A Camera Trap Data Package "camtrap-dp-example-dataset" with 3 tables:
#> • deployments: 2 rows
#> • media: 183 rows
#> • observations: 210 rows
#> 
#> And 1 additional resource:
#> • individuals
#> Use `unclass()` to print the Data Package as a list.


ct_dp_filter(package = dp, table = "media",
             captureMethod == "activityDetection", filePublic == FALSE
)
#> A Camera Trap Data Package "camtrap-dp-example-dataset" with 3 tables:
#> • deployments: 4 rows
#> • media: 60 rows
#> • observations: 62 rows
#> 
#> And 1 additional resource:
#> • individuals
#> Use `unclass()` to print the Data Package as a list.
# }
```
