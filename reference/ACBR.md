# Camera trap dataset from Agonve Community Wetland Reserve (ACBR)

A curated camera trap dataset from the Agonve Community Wetland Reserve
in West Africa, adapted from Gandaho et al. (2026). The dataset contains
wildlife camera trap observations and associated deployment metadata.

## Format

A named list with two tibbles:

- `acbr_data`:

  Camera trap observations.

- `deployment`:

  Deployment metadata.

## Details

The object is provided as a named list with two elements:

- `acbr_data`:

  A tibble containing camera trap observations.

  Variables include:

  `image`

  :   Image file name.

  `deployment`

  :   Deployment identifier.

  `cam`

  :   Camera station identifier.

  `model`

  :   Camera model (`RD1003L` or `TC302445`).

  `dates`

  :   Observation date.

  `times`

  :   Observation time.

  `species`

  :   Recorded species name.

  `count`

  :   Number of individuals detected.

  `datetime`

  :   Combined date-time in POSIX format.

- `deployment`:

  A tibble containing deployment-level metadata.

  Variables include:

  `deployment`

  :   Deployment identifier.

  `cam`

  :   Camera station identifier.

  `model`

  :   Camera model.

  `start`

  :   Deployment start date-time.

  `end`

  :   Deployment end date-time.

  `radius`

  :   Camera detection radius (meters).

  `angle`

  :   Camera detection angle (degrees).

  `area`

  :   Estimated detection area (square meters).

The deployment table was reconstructed from the observation data using
the first and last timestamps recorded for each deployment.

## References

Gandaho, S. M., Agossou, H., Madokoun, D. L., Hounnouvi, E. F. K.,
Oussoukpevi, S. J. K., Akpona, H. A., Thompson, L., & Djagoun, C. A. M.
S. (2026). Habitat loss and species diel ecology in a West African
community wetland reserve. Zenodo.
[doi:10.5281/zenodo.19662320](https://doi.org/10.5281/zenodo.19662320)

## Examples

``` r
data(ACBR)

# Access observation data
head(ACBR$acbr_data)
#> # A tibble: 6 × 9
#>   image     deployment cam   model dates times species count datetime           
#>   <chr>     <chr>      <chr> <chr> <chr> <chr> <chr>   <int> <dttm>             
#> 1 IMAG0016… Deploymen… cam0… RD10… 2025… 18:3… Cercop…     1 2025-04-28 18:38:59
#> 2 IMAG0017… Deploymen… cam0… RD10… 2025… 18:3… Cercop…     1 2025-04-28 18:39:01
#> 3 IMAG0018… Deploymen… cam0… RD10… 2025… 18:3… Cercop…     1 2025-04-28 18:39:02
#> 4 IMAG0000… Deploymen… cam0… RD10… 2025… 9:53… Tragel…     1 2025-03-30 09:53:55
#> 5 IMAG0001… Deploymen… cam0… RD10… 2025… 9:53… Tragel…     1 2025-03-30 09:53:56
#> 6 IMAG0002… Deploymen… cam0… RD10… 2025… 9:53… Tragel…     1 2025-03-30 09:53:57

# Access deployment metadata
head(ACBR$deployment)
#> # A tibble: 6 × 8
#>   deployment   cam    model start               end                 radius angle
#>   <chr>        <chr>  <chr> <dttm>              <dttm>               <dbl> <dbl>
#> 1 Deployment 1 cam03… RD10… 2025-04-28 17:38:59 2025-04-28 17:39:02   18.3    60
#> 2 Deployment 1 cam06… RD10… 2025-03-30 08:53:55 2025-03-30 08:54:31   18.3    60
#> 3 Deployment 2 cam03… RD10… 2025-03-28 00:57:56 2025-04-09 21:46:38   18.3    60
#> 4 Deployment 3 cam02… TC30… 2025-05-11 21:13:09 2025-05-15 23:18:10   19.8   120
#> 5 Deployment 3 cam03… RD10… 2025-06-03 17:36:27 2025-06-03 17:36:30   18.3    60
#> 6 Deployment 3 cam03… TC30… 2025-05-13 11:50:26 2025-05-16 18:47:54   19.8   120
#> # ℹ 1 more variable: area <dbl>
```
