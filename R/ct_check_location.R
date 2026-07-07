#' Interactive camera trap location adjustment
#'
#' This function launches a shiny application that allows to visualize
#' and manually adjust the geographic coordinates of camera trap locations.
#'
#' @param data A data frame containing the camera trap data to be processed.
#' @param longitude Column name for longitude in the dataset.
#' @param latitude Column name for latitude in the dataset.
#' @param location_name Column name that identifies each camera-trap location.
#' @param coord_system A string specifying the coordinate system of
#' the input data. Choices are `"geographic"` for longitude and latitude,
#' or `"projected"` for projected coordinates.
#' @param crs An integer representing the coordinate reference system (CRS)
#' in EPSG format. Required when `coord_system = "projected"`.
#' @param new_data_name A string specifying the name of the new dataset with
#' updated coordinates to be created in the calling environment.
#'
#' @return A shiny application object (see [shiny::shinyApp()]). It is called
#'   for its side effect: when run interactively it displays the map and allows
#'   manual coordinate adjustments, and the modified dataset is assigned in the
#'   calling environment under the name provided in `new_data_name`.
#'
#' @examples
#' # Example dataset
#' camera_traps <- tibble::tibble(
#'   trap_id = c("Trap1", "Trap2", "Trap3"),
#'   lon = c(36.8, 36.9, 37.0),
#'   lat = c(-1.4, -1.5, -1.6)
#' )
#'
#' # The function launches an interactive Shiny app, so it is only run in an
#' # interactive session.
#' if (interactive()) {
#'   # Launch the application
#'   ct_check_location(
#'     data = camera_traps,
#'     longitude = "lon",
#'     latitude = "lat",
#'     location_name = "trap_id",
#'     coord_system = "geographic",
#'     new_data_name = "updated_camera_traps"
#'   )
#'   # After adjustments, the updated dataset will be available in the calling
#'   # environment as `updated_camera_traps`.
#' }
#'
#' @export
ct_check_location <- function(data,
                              longitude,
                              latitude,
                              location_name,
                              coord_system = c("geographic", "projected"),
                              crs,
                              new_data_name) {

  rlang::check_installed(c("shiny", "leaflet"), reason = "launch the app")

  target_env <- parent.frame()

  data_copy <- data
  coord_system <- match.arg(coord_system, choices = c("geographic", "projected"))
  lon_ <- paste0(dplyr::ensym(longitude))
  lat_ <- paste0(dplyr::ensym(latitude))
  plc_ <- paste0(dplyr::ensym(location_name))
  if (plc_ == "") {
    cli::cli_abort("location_name can not be empty")
  }

  # Keep only rows with usable coordinates.
  keep <- data %>%
    dplyr::filter(!is.na(.data[[lon_]]) & !is.na(.data[[lat_]]))
  if (nrow(keep) == 0) {
    cli::cli_abort("No rows with non-missing {.field {lon_}}/{.field {lat_}} coordinates.")
  }

  # Display coordinates in geographic (EPSG:4326) space, transforming from the
  # supplied projected CRS when needed.
  if (coord_system == "projected") {
    if (!methods::hasArg(crs)) cli::cli_abort("Specify the crs")
    xy <- keep %>%
      sf::st_as_sf(coords = c(lon_, lat_), crs = crs) %>%
      sf::st_transform(crs = 4326) %>%
      sf::st_coordinates() %>%
      as.data.frame()
  } else {
    xy <- data.frame(X = keep[[lon_]], Y = keep[[lat_]])
  }

  locations <- dplyr::tibble(location_name = keep[[plc_]], X = xy$X, Y = xy$Y) %>%
    dplyr::distinct(.data$location_name, .keep_all = TRUE)

  if (!hasArg(new_data_name)) {
    new_data_name <- paste0("data_updated_", gsub("\\.|\\-|\\:|\\s", "", paste0(Sys.time())))
  }

  build_updated <- function(locs) {
    updated <- locs
    names(updated) <- c(plc_, lon_, lat_)
    data_copy %>%
      dplyr::select(-dplyr::all_of(c(lon_, lat_))) %>%
      dplyr::left_join(updated, by = plc_)
  }

  # shiny
  ui <- leaflet::leafletOutput("map", width = "100%", height = "100vh")#,  # The map output
  server <- function(input, output, session) {
    # Current per-location coordinates; updated as markers are dragged.
    location_coords <- shiny::reactiveVal(locations)

    # Render the leaflet map with one draggable marker per location.
    output$map <- leaflet::renderLeaflet({
      locs <- shiny::isolate(location_coords())
      leaflet::leaflet() %>%
        leaflet::addTiles(attribution = "Maimer") %>%
        leaflet::addProviderTiles("OpenStreetMap.Mapnik", group = "OSM") %>%
        leaflet::addProviderTiles("OpenStreetMap.France", group = "OSM France") %>%
        leaflet::addProviderTiles("Esri.WorldImagery", group = "Natural") %>%
        leaflet::addProviderTiles("OpenTopoMap", group = "OpenTopoMap") %>%
        leaflet::addLayersControl(
          baseGroups = c("OSM", "OSM France", "Natural", "OpenTopoMap"),
          options = leaflet::layersControlOptions(collapsed = T)
        ) %>%
        leaflet::addMarkers(lng = locs$X,
                            lat = locs$Y,
                            layerId = locs$location_name,
                            options = leaflet::markerOptions(draggable = TRUE),
                            popup = locs$location_name) %>%
        leaflet::setView(lng = locs$X[1], lat = locs$Y[1], zoom = 8)
    })

    # Capture the updated coordinates after a marker drag event.
    shiny::observeEvent(input$map_marker_dragend, {
      new_coords <- input$map_marker_dragend  # Coordinates from the dragged marker

      # Update the single row for the dragged location.
      locs <- location_coords()
      hit <- locs$location_name == new_coords$id
      locs$X[hit] <- new_coords$lng
      locs$Y[hit] <- new_coords$lat
      location_coords(locs)

      assign(new_data_name, build_updated(locs), envir = target_env)
    })
  }
  # shiny end

  # Run the application
  return(shiny::shinyApp(ui = ui, server = server))
}
