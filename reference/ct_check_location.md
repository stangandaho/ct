# Interactive camera trap location adjustment

This function launches a shiny application that allows to visualize and
manually adjust the geographic coordinates of camera trap locations.

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

  Column name for longitude in the dataset.

- latitude:

  Column name for latitude in the dataset.

- location_name:

  Column name that identifies each camera-trap location.

- coord_system:

  A string specifying the coordinate system of the input data. Choices
  are `"geographic"` for longitude and latitude, or `"projected"` for
  projected coordinates.

- crs:

  An integer representing the coordinate reference system (CRS) in EPSG
  format. Required when `coord_system = "projected"`.

- new_data_name:

  A string specifying the name of the new dataset with updated
  coordinates to be created in the calling environment.

## Value

A shiny application object (see
[`shiny::shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html)). It
is called for its side effect: when run interactively it displays the
map and allows manual coordinate adjustments, and the modified dataset
is assigned in the calling environment under the name provided in
`new_data_name`.

## Examples

``` r
# Example dataset
camera_traps <- tibble::tibble(
  trap_id = c("Trap1", "Trap2", "Trap3"),
  lon = c(36.8, 36.9, 37.0),
  lat = c(-1.4, -1.5, -1.6)
)

# The function launches an interactive Shiny app, so it is only run in an
# interactive session.
if (interactive()) {
  # Launch the application
  ct_check_location(
    data = camera_traps,
    longitude = "lon",
    latitude = "lat",
    location_name = "trap_id",
    coord_system = "geographic",
    new_data_name = "updated_camera_traps"
  )
  # After adjustments, the updated dataset will be available in the calling
  # environment as `updated_camera_traps`.
}
```
