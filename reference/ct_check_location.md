# Interactive camera trap location adjustment

This function launches a shiny application that allows users to
visualize and manually adjust the geographic coordinates of camera trap
locations. Users can drag points on an interactive map to update the
positions of camera traps, and the updated dataset is saved to the
global environment.

## Usage

``` r
ct_check_location(
  data,
  longitude,
  latitude,
  location_name,
  coord_system = c("geographic", "projected"),
  crs,
  new_data_name
)
```

## Arguments

- data:

  A data frame containing the camera trap data to be processed.

- longitude:

  A string representing the column name for longitude in the dataset.

- latitude:

  A string representing the column name for latitude in the dataset.

- location_name:

  A string representing the column name for the location name or unique
  identifier for each camera trap point.

- coord_system:

  A string specifying the coordinate system of the input data. Choices
  are `"geographic"` for longitude and latitude, or `"projected"` for
  projected coordinates.

- crs:

  An integer representing the coordinate reference system (CRS) in EPSG
  format. Required when `coord_system = "projected"`.

- new_data_name:

  A string specifying the name of the new dataset with updated
  coordinates to be created in the global environment.

## Value

A shiny application is launched to display the map and allow manual
coordinate adjustments. The modified dataset is saved to the global
environment under the name provided in `new_data_name`.

## Examples
