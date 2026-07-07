# Introduction to data preparation

Most camera-trap analyses in `ct` share the same first steps: read the
raw image records, inspect them, and reduce the stream of photographs to
a set of *independent* detection events before any activity, diversity,
or density method is applied. This vignette walks through that
preparation using the bundled `penessoulou` dataset, a year of
camera-trap records from the Penessoulou Classified Forest in Benin.

``` r

library(ct)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

## The raw records

`penessoulou` holds one row per recorded image, with the species seen,
the camera that took it, and the capture date-time (as a
`"YYYY-MM-DD HH:MM:SS"` string).

``` r

data(penessoulou)

dim(penessoulou)
#> [1] 4724   12

penessoulou %>%
  select(project, camera, species, number, datetimes) %>%
  head()
#> # A tibble: 6 × 5
#>   project camera species              number datetimes          
#>   <chr>   <chr>  <chr>                 <int> <chr>              
#> 1 First   1G1    Tragelaphus scriptus      1 2024-06-07 09:44:44
#> 2 First   1G1    Tragelaphus scriptus      1 2024-06-07 09:44:46
#> 3 First   1G1    Tragelaphus scriptus      1 2024-06-07 09:44:47
#> 4 First   1G1    Canis adustus             1 2024-05-28 05:03:52
#> 5 First   1G1    Canis adustus             1 2024-05-28 05:03:53
#> 6 First   1G1    Canis adustus             1 2024-05-28 05:03:54
```

A quick tally shows how the raw images are distributed across species.
At this stage every photograph counts, so a single animal lingering in
front of a camera can inflate these numbers.

``` r

penessoulou %>%
  count(species, sort = TRUE)
#> # A tibble: 19 × 2
#>    species                     n
#>    <chr>                   <int>
#>  1 Erythrocebus patas       1590
#>  2 Syncerus caffer          1145
#>  3 Tragelaphus scriptus      796
#>  4 Cercopithecus aethiops    427
#>  5 Canis adustus             223
#>  6 Cephalophus grimmia       187
#>  7 Xerus erythropus          159
#>  8 Atilax paludinosus         37
#>  9 Civettictis civetta        36
#> 10 Genetta genetta            26
#> 11 Cephalophus rufilatus      24
#> 12 Tragelaphus rufilatus      24
#> 13 Thryonomys swinderianus    16
#> 14 Cricetomys gambianus        9
#> 15 Sylvicapra grimmia          9
#> 16 Lepus crawshayi             6
#> 17 Chlorocebus aethiops        4
#> 18 Manis gigantea              3
#> 19 Mellivora capensis          3
```

## Filtering independent detections

Consecutive photographs of the same species at the same camera within a
short time window are not statistically independent (Ridout & Linkie,
2009). The
[`ct_independence()`](https://stangandaho.github.io/ct/reference/ct_independence.md)
function collapses such bursts, keeping detections only when the gap
since the previous record of that species at that camera meets a chosen
`threshold` (in seconds). Here we use a 30-minute (1800 s) window,
assessed separately per species and per camera.

``` r

independent <- penessoulou %>%
  ct_independence(
    datetime = datetimes,
    format = "%Y-%m-%d %H:%M:%S",
    species_column = "species",
    site_column = "camera",
    threshold = 1800
  )

nrow(penessoulou)
#> [1] 4724
nrow(independent)
#> [1] 640
```

Filtering removes the redundant burst photographs, leaving fewer,
independent events. The same species tally now reflects independent
detections rather than raw image counts:

``` r

independent %>%
  count(species, sort = TRUE)
#> # A tibble: 19 × 2
#>    species                     n
#>    <chr>                   <int>
#>  1 Erythrocebus patas        192
#>  2 Syncerus caffer            96
#>  3 Tragelaphus scriptus       90
#>  4 Cercopithecus aethiops     74
#>  5 Canis adustus              55
#>  6 Xerus erythropus           38
#>  7 Cephalophus grimmia        36
#>  8 Civettictis civetta        14
#>  9 Atilax paludinosus         10
#> 10 Cephalophus rufilatus       9
#> 11 Genetta genetta             9
#> 12 Thryonomys swinderianus     4
#> 13 Cricetomys gambianus        3
#> 14 Tragelaphus rufilatus       3
#> 15 Chlorocebus aethiops        2
#> 16 Lepus crawshayi             2
#> 17 Manis gigantea              1
#> 18 Mellivora capensis          1
#> 19 Sylvicapra grimmia          1
```

## Where to go next

The independent detections produced here are the common input to the
rest of the package, for example:

- [`ct_fit_activity()`](https://stangandaho.github.io/ct/reference/ct_fit_activity.md)
  and
  [`ct_overlap_estimates()`](https://stangandaho.github.io/ct/reference/ct_overlap_estimates.md)
  for activity patterns and temporal overlap between species,
- [`ct_camera_day()`](https://stangandaho.github.io/ct/reference/ct_camera_day.md)
  together with
  [`ct_alpha_diversity()`](https://stangandaho.github.io/ct/reference/ct_alpha_diversity.md)
  or
  [`ct_inext()`](https://stangandaho.github.io/ct/reference/ct_inext.md)
  for diversity and rarefaction,
- the density estimators
  ([`ct_fit_ds()`](https://stangandaho.github.io/ct/reference/ct_fit_ds.md),
  [`ct_fit_rest()`](https://stangandaho.github.io/ct/reference/ct_fit_rest.md),
  [`ct_fit_tte()`](https://stangandaho.github.io/ct/reference/ct_fit_tte.md),
  [`ct_fit_ste()`](https://stangandaho.github.io/ct/reference/ct_fit_ste.md)).

Each of these is covered in its own article on the [package
website](https://stangandaho.github.io/ct/).

## References

Ridout, M. S., & Linkie, M. (2009). Estimating overlap of daily activity
patterns from camera trap data. *Journal of Agricultural, Biological,
and Environmental Statistics*, 14(3), 322-337.
