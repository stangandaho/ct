# Get core tables

Acess table like observations, deployement, and media from data package.

## Usage

``` r
ct_dp_table(
  package,
  table = c("observations", "deployments", "media", "events", "taxa")
)
```

## Arguments

- package:

  Camera trap data package object, as returned by ct_read_dp().

- table:

  Character indicating the table to read - one "observations",
  "deployments", or "media"

## Value

A tibble of table specified

## Examples

``` r
# \donttest{
dp <- ct_dp_example()
ct_dp_table(dp, "deployments")
#> # A tibble: 4 × 24
#>   deploymentID locationID locationName  latitude longitude coordinateUncertainty
#>   <chr>        <chr>      <chr>            <dbl>     <dbl>                 <dbl>
#> 1 00a2c20d     e254a13c   B_HS_val 2_p…     51.5      4.77                   187
#> 2 29b7d356     2df5259b   B_DL_val 5_b…     51.2      5.66                   187
#> 3 577b543a     ff1535c0   B_DL_val 3_d…     51.2      5.66                   187
#> 4 62c200a9     ce943ced   B_DM_val 4_'…     50.7      4.01                   187
#> # ℹ 18 more variables: deploymentStart <dttm>, deploymentEnd <dttm>,
#> #   setupBy <chr>, cameraID <chr>, cameraModel <chr>, cameraDelay <dbl>,
#> #   cameraHeight <dbl>, cameraDepth <dbl>, cameraTilt <dbl>,
#> #   cameraHeading <dbl>, detectionDistance <dbl>, timestampIssues <lgl>,
#> #   baitUse <lgl>, featureType <fct>, habitat <chr>, deploymentGroups <chr>,
#> #   deploymentTags <chr>, deploymentComments <chr>
# }
```
