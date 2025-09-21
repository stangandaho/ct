#' Calculate daily camera trap captures
#'
#' @description
#' Aggregates camera trap data into daily capture summaries.
#'
#' @param data A data frame containing camera trap observation data.
#'
#' @param datetime_column Column in `data` containing observation timestamps.
#' Can be supplied as a bare name, quoted string, or column position.
#'
#' @inheritParams ct_get_effort
#'
#' @inheritParams ct_to_community
#'
#' @param format Character string specifying the datetime format for parsing
#' `datetime_column`.
#'
#' @param deployment_format Character string specifying the datetime format for parsing
#' `start_column` and `end_column`. Defaults to the same format as `format`.
#'
#' @return A tibble with the following columns:
#'
#' - `deployment_column` (camera/location identifier)
#' - `date` (Date of observation)
#' - `species_column` (species name)
#' - `size_column` (daily count, `0` if no observations)
#' - `sampling_unit` (unique identifier for location × date combination)
#'
#' @examples
#' # Example observation data
#' obs <- data.frame(
#'   species = c("Deer", "Deer", "Fox", "Deer"),
#'   count = c(2, 1, 1, 3),
#'   datetime = c("2023-06-01 08:12:00", "2023-06-01 15:30:00",
#'                "2023-06-01 21:10:00", "2023-06-02 06:45:00"),
#'   location_id = c("Cam1", "Cam1", "Cam1", "Cam1"),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Example deployment data
#' dep <- data.frame(
#'   location_id = c("Cam1"),
#'   deploy_start = "2023-06-01 00:00:00",
#'   deploy_end = "2023-06-03 23:59:59",
#'   stringsAsFactors = FALSE
#' )
#'
#' ct_camera_day(
#'   data = obs,
#'   deployment_data = dep,
#'   datetime_column = "datetime",
#'   species_column = "species",
#'   size_column = "count",
#'   deployment_column = "location_id",
#'   format = "%Y-%m-%d %H:%M:%S",
#'   start_column = "deploy_start",
#'   end_column = "deploy_end"
#' )
#'
#' @seealso [ct_inext()], [ct_get_effort()]
#'
#' @export
ct_camera_day <- function(data,
                          deployment_data = NULL,
                          deployment_column,
                          datetime_column,
                          species_column,
                          size_column,
                          format,
                          start_column = NULL,
                          end_column = NULL,
                          deployment_format = format,
                          time_zone = ""
) {
  # Get column names as string if position, quote or unquoted column is supplied
  # get_column return error as dplyr::select function for wrong column supplied
  datetime_column <- data %>% dplyr::select({{datetime_column}}) %>% colnames()
  species_column <- data %>% dplyr::select({{species_column}}) %>% colnames()
  size_column <- data %>% dplyr::select({{size_column}}) %>% colnames()

  # Convert datetime column in observation data
  data[[datetime_column]] <- as.POSIXlt(data[[datetime_column]],
                                        format = format,
                                        tryFormats = try_formats,
                                        tz = time_zone)
  if (any(is.na(data[[datetime_column]]))) {
    cli::cli_warn("Some datetime values could not be parsed and will be removed.")
    data <- data[!is.na(data[[datetime_column]]), ]
  }

  # If deployment data is provided, validate and filter
  if (!is.null(deployment_data)) {
    if (is.null(start_column) || is.null(end_column)) {
      cli::cli_abort("If deployment_data is supplied, you must provide start_column and end_column.")
    }

    # Check and get required columns in deployment data
    start_column <- deployment_data %>% dplyr::select({{start_column}}) %>% colnames()
    end_column <- deployment_data %>% dplyr::select({{end_column}}) %>% colnames()
    deployment_column <- deployment_data %>% dplyr::select({{deployment_column}}) %>% colnames()

    # Convert deployment start/end datetimes
    deployment_data[[start_column]] <- as.POSIXlt(deployment_data[[start_column]],
                                                  format = deployment_format,
                                                  tryFormats = try_formats, tz = time_zone)
    deployment_data[[end_column]] <- as.POSIXlt(deployment_data[[end_column]],
                                                format = deployment_format,
                                                tryFormats = try_formats, tz = time_zone)

    # Merge observation data with deployment data
    data <- merge(data, deployment_data, by = deployment_column, all.x = TRUE)

    # Keep only records within deployment period
    in_deployment <- data[[datetime_column]] >= data[[start_column]] &
      data[[datetime_column]] <= data[[end_column]]
    data <- data[in_deployment, ]

    # Create a date column (24h grouping)
    data$date <- as.Date(data[[datetime_column]])

    # Aggregate data (species × location × date)
    agg <- aggregate(data[[size_column]],
                     by = list(location = data[[deployment_column]],
                               date = data$date,
                               species = data[[species_column]]),
                     FUN = sum, na.rm = TRUE)

    # Create complete date sequence for each deployment
    deployment_dates <- deployment_data %>%
      dplyr::select(dplyr::all_of(c(deployment_column, start_column, end_column))) %>%
      dplyr::rowwise() %>%
      dplyr::mutate(
        date = list(seq(as.Date(.data[[start_column]]),
                        as.Date(.data[[end_column]]),
                        by = "day"))
      ) %>%
      tidyr::unnest(date) %>%
      dplyr::select(dplyr::all_of(deployment_column), date)

    # Get all unique species from the aggregated data
    all_species <- unique(agg$species)

    # Create complete grid: all deployments × all dates × all species
    complete_grid <- tidyr::expand_grid(
      deployment_dates,
      species = all_species
    )
    names(complete_grid)[1] <- deployment_column
    names(complete_grid)[3] <- species_column

    # Merge with aggregated data to fill in counts (0 for missing combinations)
    names(agg)[1] <- deployment_column
    names(agg)[3] <- species_column
    names(agg)[4] <- size_column

    agg <- dplyr::left_join(complete_grid, agg,
                            by = c(deployment_column, "date", species_column)) %>%
      dplyr::mutate(!!size_column := tidyr::replace_na(.data[[size_column]], 0))

  } else {
    # When no deployment data is provided, create complete date coverage for entire sampling period
    # Create a date column (24h grouping)
    deployment_column <- data %>% dplyr::select({{deployment_column}}) %>% colnames()
    data$date <- as.Date(data[[datetime_column]])

    # Aggregate data (species × location × date)
    agg <- aggregate(data[[size_column]],
                     by = list(location = data[[deployment_column]],
                               date = data$date,
                               species = data[[species_column]]),
                     FUN = sum, na.rm = TRUE)

    # Create complete date sequence for each location (from min to max date observed)
    location_dates <- data %>%
      dplyr::group_by(.data[[deployment_column]]) %>%
      dplyr::summarise(
        min_date = min(date, na.rm = TRUE),
        max_date = max(date, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      dplyr::rowwise() %>%
      dplyr::mutate(
        date = list(seq(min_date, max_date, by = "day"))
      ) %>%
      tidyr::unnest(date) %>%
      dplyr::select(dplyr::all_of(deployment_column), date)

    # Get all unique species from the aggregated data
    all_species <- unique(agg$species)

    # Create complete grid: all locations × all dates × all species
    complete_grid <- tidyr::expand_grid(
      location_dates,
      species = all_species
    )
    names(complete_grid)[1] <- deployment_column
    names(complete_grid)[3] <- species_column

    # Merge with aggregated data to fill in counts (0 for missing combinations)
    names(agg)[1] <- deployment_column
    names(agg)[3] <- species_column
    names(agg)[4] <- size_column

    agg <- dplyr::left_join(complete_grid, agg,
                            by = c(deployment_column, "date", species_column)) %>%
      dplyr::mutate(!!size_column := tidyr::replace_na(.data[[size_column]], 0))
  }

  # Create sampling_unit column
  agg <- agg %>%
    dplyr::mutate(sampling_unit = gsub("-", "", paste0(.data[[deployment_column]], date)))

  return(agg %>% dplyr::as_tibble())
}

