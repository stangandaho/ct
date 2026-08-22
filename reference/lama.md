# Camera trap survey of the Lama Classified Forest

Detection-level camera-trap records and camera deployment intervals from
a multispecies survey of terrestrial mammals in the Lama Classified
Forest, a semi-deciduous forest remnant in the Dahomey Gap, southern
Benin. Twenty-three camera traps operated from June to December 2024
(about 4,256 trap-days), recording 18 mammal taxa. The survey was
designed for camera-trap distance sampling, so each detection carries a
radial `distance` and detection `angle` alongside station coordinates
and anthropogenic-gradient covariates.

## Usage

``` r
lama
```

## Format

A list with two tibbles that share the `camera` column:

- `observation`:

  One row per recorded image (7,963 rows, 11 columns): `camera` (station
  identifier), `species` (scientific name), `datetime` (detection
  date-time, UTC), `distance` (radial distance to the animal, m),
  `angle` (detection angle, degrees), `size` (group size), `x`/`y`
  (station coordinates, UTM zone 31N, EPSG:32631), `region` (survey
  stratum), `d_villages` and `d_track` (distance to the nearest village
  and track, m).

- `deployment`:

  One row per camera (23 rows, 11 columns): `camera`, `start` and `end`
  (install and pull-out date-times, UTC), `x`/`y`, `fov` (field of view,
  degrees), `radius` (maximum detection distance, m), `height` (camera
  height, m), `region`, `d_villages`, `d_track`.

## Source

Adounké, G.R.M., Lecompte, E., Gandaho, S.M., Toyi, M.S., Azihou, A.F.,
Hugueny, B., Sinsin, B.A., Gaubert, P., & Djagoun, C.A.M.S. (submitted).
Camera-trap distance sampling reveals density patterns and anthropogenic
drivers of terrestrial mammals in a remnant forest refuge in West
Africa. *Ecology and Evolution*.

## Examples

``` r
data(lama)
str(lama, max.level = 2)
#> List of 2
#>  $ observation: tibble [7,963 × 11] (S3: tbl_df/tbl/data.frame)
#>  $ deployment : tibble [23 × 11] (S3: tbl_df/tbl/data.frame)
sort(table(lama$observation$species), decreasing = TRUE)
#> 
#>                 Crossarchus platycephalus 
#>                                      1881 
#>                      Tragelaphus scriptus 
#>                                      1560 
#>                      Potamochoerus porcus 
#>                                      1081 
#>                       Philantomba walteri 
#>                                       985 
#>                        Cercopithecus mona 
#>                                       824 
#>                  Genetta pardina/maculata 
#>                                       627 
#>                          Xerus erythropus 
#>                                       374 
#>                               Praomys sp. 
#>                                       271 
#>                      Chlorocebus tantalus 
#>                                       173 
#>                       Atherurus africanus 
#>                                       109 
#> Cercopithecus erythrogaster erythrogaster 
#>                                        31 
#>                      Phataginus tricuspis 
#>                                        11 
#>                       Galagoides demidoff 
#>                                        10 
#>                         Nandinia binotata 
#>                                         8 
#>                      Cricetomys gambianus 
#>                                         6 
#>                   Thryonomys swinderianus 
#>                                         6 
#>                      Atelerix albiventris 
#>                                         4 
#>                        Colobus vellerosus 
#>                                         2 
```
