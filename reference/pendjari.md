# Pendjari national park and surrounding areas

A dataset containing spatial boundaries of Pendjari National Park and
its surrounding hunting zones in Benin.

## Usage

``` r
pendjari
```

## Format

A tibble with 3 rows and 2 columns:

- `NOM`: The name of the protected area or hunting zone.

- `geometry`: The spatial geometry of the area, stored in decimal
  degrees (EPSG:4326).

## Examples

``` r
# Load the dataset
data("pendjari")

# Plot the data
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
plot(pendjari, main = "Pendjari National Park and Surrounding Areas")
legend("topright", legend = pendjari$NAME, fill = c("gray10", "gray50", "gray90"))

```
