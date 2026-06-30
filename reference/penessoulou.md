# Camera-trap detections from the Penessoulou Classified Forest

Camera-trap image records in the Penessoulou Classified Forest, Benin.
One row per recorded image in 2024.

## Usage

``` r
penessoulou
```

## Format

A tibble with 4724 rows and 12 columns, including:

- `project`:

  Survey/project name.

- `image_name`:

  Source image file name.

- `camera`:

  Camera station identifier.

- `make`, `model`:

  Camera mak and mode

- `species`:

  Recorded species name.

- `number`:

  Number of individuals in the record.

- `dates`, `times`:

  Date and time parts of the record.

- `datetimes`:

  Record date-time as a `"YYYY-MM-DD HH:MM:SS"` string.

- `longitude`, `latitude`:

  Station coordinates in decimal degrees.

## Source

Ayegnon, D.T.D., Nobimè, G., Azihou, F., Houinato, M., & Djagoun,
C.A.M.S. (2026). Seasonal variation in the diversity, abundance, and
spatial distribution of terrestrial mammals in the Pénéssoulou
Classified Forest. *Wild*, 3(1), 2.
[doi:10.3390/wild3010002](https://doi.org/10.3390/wild3010002)

## Examples

``` r
head(penessoulou)
#> # A tibble: 6 × 12
#>   project image_name   camera make  model species   number dates times datetimes
#>   <chr>   <chr>        <chr>  <chr> <chr> <chr>      <int> <chr> <chr> <chr>    
#> 1 First   IMAG0008.jpg 1G1    NA    NA    Tragelap…      1 2024… 09:4… 2024-06-…
#> 2 First   IMAG0009.jpg 1G1    NA    NA    Tragelap…      1 2024… 09:4… 2024-06-…
#> 3 First   IMAG0010.jpg 1G1    NA    NA    Tragelap…      1 2024… 09:4… 2024-06-…
#> 4 First   IMAG0000.jpg 1G1    NA    NA    Canis ad…      1 2024… 05:0… 2024-05-…
#> 5 First   IMAG0001.jpg 1G1    NA    NA    Canis ad…      1 2024… 05:0… 2024-05-…
#> 6 First   IMAG0002.jpg 1G1    NA    NA    Canis ad…      1 2024… 05:0… 2024-05-…
#> # ℹ 2 more variables: longitude <int>, latitude <int>
```
