# Data-preparation helpers for the REST / RAD-REST workflow. Each turns a raw
# detection / station table into the tidy input expected by ct_fit_rest().

#' Prepare staying-time data for REST
#'
#' Selects and standardises the staying-time and censoring columns from a
#' detection table and attaches per-station covariates.
#'
#' @param detection_data A data frame with one row per video / detection.
#' @param station_data A data frame with one row per camera station.
#' @param station_column,species_column Columns giving the station ID and species
#'   in `detection_data`.
#' @param stay_column Column holding the staying time in seconds.
#' @param censor_column Column holding the censoring flag (1 = censored,
#'   0 = fully observed).
#'
#' @return A tibble with columns `Station`, `Species`, `Stay`, `Cens` plus any
#'   station covariates, ready for [ct_fit_rest()].
#' @export
#' @importFrom rlang .data
#' @examples
#' data(rest_detection)
#' data(rest_station)
#'
#' # Column names can be strings, bare names, or positions:
#' stay <- ct_rest_stay(rest_detection, rest_station, stay_column = Stay)
#' head(stay)
ct_rest_stay <- function(detection_data, station_data,
                         station_column = "Station", species_column = "Species",
                         stay_column = "Stay", censor_column = "Cens") {

  rest_assert_df(detection_data, "detection_data")
  rest_assert_df(station_data, "station_data")

  station_column <- rest_pull_name(detection_data, rlang::enquo(station_column), "station_column")
  species_column <- rest_pull_name(detection_data, rlang::enquo(species_column), "species_column")
  stay_column    <- rest_pull_name(detection_data, rlang::enquo(stay_column), "stay_column")
  censor_column  <- rest_pull_name(detection_data, rlang::enquo(censor_column), "censor_column")

  rest_assert_cols(station_data, station_column, "station_data")
  rest_assert_unique_station(station_data, station_column)

  stay <- detection_data %>%
    dplyr::transmute(
      Station = as.character(.data[[station_column]]),
      Species = as.character(.data[[species_column]]),
      Stay = as.numeric(.data[[stay_column]]),
      Cens = as.integer(.data[[censor_column]])
    ) %>%
    dplyr::filter(!is.na(.data$Stay), !is.na(.data$Cens))

  if (!all(stay$Cens %in% c(0L, 1L))) {
    cli::cli_abort("Censoring column {.val {censor_column}} must contain only 0 and 1.")
  }

  stay %>%
    dplyr::left_join(rest_clean_station(station_data, station_column,
                                        drop = c("Species", "Stay", "Cens")),
                     by = "Station") %>%
    dplyr::arrange(.data$Species, .data$Station)
}

#' Aggregate the number of animal passes per station for REST / RAD-REST
#'
#' @inheritParams ct_rest_stay
#' @param passes_column Column holding the number of passes per video.
#' @param model Either `"REST"` (totals as `Y`) or `"RAD-REST"` (per-video pass
#'   counts spread into `y_0`, `y_1`, ... plus the video total `N`).
#'
#' @return A tibble with one row per station x species, ready for [ct_rest_effort()].
#'
#' @export
#' @importFrom rlang .data
#' @examples
#' data(rest_detection)
#' data(rest_station)
#'
#' # Original REST: total passes (Y) per station
#' ct_rest_passes(rest_detection, rest_station, model = "REST")
#'
#' # RAD-REST: videos split by number of passes (y_0, y_1, ...)
#' ct_rest_passes(rest_detection, rest_station, model = "RAD-REST")
#'
ct_rest_passes <- function(detection_data, station_data,
                           station_column = "Station", species_column = "Species",
                           passes_column = "y", model = c("REST", "RAD-REST")) {

  model <- match_arg(model, c("REST", "RAD-REST"))
  rest_assert_df(detection_data, "detection_data")
  rest_assert_df(station_data, "station_data")

  station_column <- rest_pull_name(detection_data, rlang::enquo(station_column), "station_column")
  species_column <- rest_pull_name(detection_data, rlang::enquo(species_column), "species_column")
  passes_column  <- rest_pull_name(detection_data, rlang::enquo(passes_column), "passes_column")

  rest_assert_cols(station_data, station_column, "station_data")
  rest_assert_unique_station(station_data, station_column)

  det <- detection_data %>%
    dplyr::transmute(
      Station = as.character(.data[[station_column]]),
      Species = as.character(.data[[species_column]]),
      y = as.numeric(.data[[passes_column]])
    ) %>%
    dplyr::filter(!is.na(.data$Species))

  station <- rest_clean_station(station_data, station_column,
                                drop_regex = "^(Species|Y|N|y|y_\\d+)$")

  # Every station x observed-species cell, so absences become explicit zeros.
  grid <- tidyr::crossing(Station = unique(station$Station),
                          Species = unique(det$Species))

  if (model == "REST") {
    passes <- det %>%
      dplyr::mutate(y = tidyr::replace_na(.data$y, 1)) %>%
      dplyr::group_by(.data$Station, .data$Species) %>%
      dplyr::summarise(Y = sum(.data$y), .groups = "drop")
    passes <- grid %>%
      dplyr::left_join(passes, by = c("Station", "Species")) %>%
      dplyr::mutate(Y = tidyr::replace_na(.data$Y, 0))
  } else {
    n_videos <- det %>%
      dplyr::group_by(.data$Station, .data$Species) %>%
      dplyr::summarise(N = dplyr::n(), .groups = "drop")
    by_pass <- det %>%
      dplyr::filter(!is.na(.data$y)) %>%
      dplyr::count(.data$Station, .data$Species, .data$y) %>%
      tidyr::pivot_wider(names_from = .data$y, values_from = .data$n,
                         names_prefix = "y_", values_fill = 0)
    passes <- grid %>%
      dplyr::left_join(n_videos, by = c("Station", "Species")) %>%
      dplyr::left_join(by_pass, by = c("Station", "Species")) %>%
      dplyr::mutate(dplyr::across(dplyr::starts_with("y_") | dplyr::any_of("N"),
                                  ~ tidyr::replace_na(.x, 0)))
    passes <- rest_fill_pass_columns(passes)
  }

  passes %>%
    dplyr::left_join(station, by = "Station") %>%
    dplyr::arrange(.data$Species, .data$Station)
}

#' Add camera-trapping effort (days) to formatted station data
#'
#' Effort is approximated as the span between the first and last detection. When
#' `term_col` is given, effort is computed per survey term and summed per station
#' so inactive gaps between terms are not counted.
#'
#' @param detection_data A data frame with one row per detection.
#' @param station_data A data frame from [ct_rest_passes()] (must have a
#'   `Station` column).
#' @param station_column,datetime_column Columns for the station ID and datetime
#'   in `detection_data`.
#' @param term_column Optional column identifying survey terms;
#'   `NULL` to ignore.
#' @param plot If `TRUE`, draw a Gantt-style plot of operation periods.
#'
#' @return `station_data` with an added `Effort` column (days). Stations with no
#'   or zero effort are dropped with a warning.
#' @export
#' @importFrom rlang .data
#' @examples
#' data(rest_detection)
#' data(rest_station)
#'
#' stations <- ct_rest_passes(rest_detection, rest_station, model = "REST")
#' ct_rest_effort(rest_detection, stations)
#'
ct_rest_effort <- function(detection_data, station_data,
                           station_column = "Station", datetime_column = "DateTime",
                           term_column = NULL, plot = FALSE) {

  rest_assert_df(detection_data, "detection_data")
  rest_assert_df(station_data, "station_data")

  station_column  <- rest_pull_name(detection_data, rlang::enquo(station_column), "station_column")
  datetime_column <- rest_pull_name(detection_data, rlang::enquo(datetime_column), "datetime_column")
  term_column     <- rest_pull_name(detection_data, rlang::enquo(term_column), "term_column")

  rest_assert_cols(station_data, "Station", "station_data")

  select_map <- c(Station = station_column, DateTime = datetime_column)
  if (!is.null(term_column)) select_map <- c(select_map, Term = term_column)

  det <- detection_data %>%
    dplyr::select(dplyr::all_of(select_map)) %>%
    dplyr::mutate(Station = as.character(.data$Station))

  if (!inherits(det$DateTime, "POSIXt")) {
    det <- dplyr::mutate(det, DateTime = lubridate::parse_date_time(
      as.character(.data$DateTime), orders = c("Ymd HMS", "Ymd HM", "Ymd H", "Ymd")))
  }
  if (anyNA(det$DateTime)) {
    cli::cli_abort("Could not parse some datetimes in {.val {datetime_column}}. Use a 'YYYY-MM-DD HH:MM:SS'-like format.")
  }

  group_vars <- if (!is.null(term_column)) c("Station", "Term") else "Station"
  by_group <- det %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      Start = min(.data$DateTime, na.rm = TRUE),
      End = max(.data$DateTime, na.rm = TRUE),
      effort = as.numeric(difftime(.data$End, .data$Start, units = "days")),
      .groups = "drop"
    )

  effort <- by_group %>%
    dplyr::group_by(.data$Station) %>%
    dplyr::summarise(Effort = sum(.data$effort, na.rm = TRUE), .groups = "drop")

  out <- station_data %>%
    dplyr::select(-dplyr::any_of("Effort")) %>%
    dplyr::left_join(effort, by = "Station")

  dropped <- out %>%
    dplyr::filter(is.na(.data$Effort) | .data$Effort == 0) %>%
    dplyr::pull(.data$Station) %>% unique()
  if (length(dropped)) {
    cli::cli_warn("Dropping station(s) with zero/no effort: {.val {dropped}}.")
  }
  out <- dplyr::filter(out, !is.na(.data$Effort), .data$Effort > 0)

  if (plot) print(rest_effort_plot(by_group, term_column))
  out
}

#' Prepare activity (time-of-day) data for REST
#'
#' Keeps independent detections of each species and converts their time of day
#' to radians for circular activity modelling.
#'
#' @inheritParams ct_rest_effort
#' @param species_column Column for species in `detection_data`.
#' @param independence_minutes Minimum gap (minutes) between successive
#'   detections at a station for them to count as independent.
#'
#' @return A tibble with columns `Species`, `Station`, `time` (radians).
#' @export
#' @importFrom rlang .data
#' @examples
#' data(rest_detection)
#'
#' activity <- ct_rest_activity(rest_detection, independence_minutes = 30)
#' head(activity)
#'
ct_rest_activity <- function(detection_data,
                             station_column = "Station", species_column = "Species",
                             datetime_column = "DateTime", independence_minutes = 30) {

  rest_assert_df(detection_data, "detection_data")

  station_column  <- rest_pull_name(detection_data, rlang::enquo(station_column), "station_column")
  species_column  <- rest_pull_name(detection_data, rlang::enquo(species_column), "species_column")
  datetime_column <- rest_pull_name(detection_data, rlang::enquo(datetime_column), "datetime_column")

  det <- detection_data %>%
    dplyr::rename(Station = dplyr::all_of(station_column),
                  Species = dplyr::all_of(species_column),
                  DateTime = dplyr::all_of(datetime_column))

  if (!inherits(det$DateTime, "POSIXt")) {
    det <- dplyr::mutate(det, DateTime = lubridate::parse_date_time(
      as.character(.data$DateTime), orders = c("Ymd HMS", "Ymd HM", "Ymd H", "Ymd")))
  }
  if (anyNA(det$DateTime)) {
    cli::cli_abort("Could not parse some datetimes in {.val {datetime_column}}. Use a 'YYYY-MM-DD HH:MM:SS'-like format.")
  }

  det %>%
    dplyr::arrange(.data$Station, .data$DateTime) %>%
    dplyr::group_by(.data$Species, .data$Station) %>%
    dplyr::mutate(independent = is.na(dplyr::lag(.data$DateTime)) |
      difftime(.data$DateTime, dplyr::lag(.data$DateTime), units = "mins") > independence_minutes) %>%
    dplyr::filter(.data$independent) %>%
    # Seconds since midnight scaled to the [0, 2*pi] circle.
    dplyr::mutate(time = 2 * pi * (lubridate::hour(.data$DateTime) * 3600 +
      lubridate::minute(.data$DateTime) * 60 + lubridate::second(.data$DateTime)) / 86400) %>%
    dplyr::select(.data$Species, .data$Station, .data$time) %>%
    dplyr::ungroup()
}


# --- shared internal utilities ----------------------------------------------

#' Resolve a single column given as a string, bare name, or position index
#'
#' Uses tidy-selection so users can write `"Stay"`, `Stay`, or `3`. Returns the
#' resolved column name as a string, or `NULL` when the argument itself is `NULL`
#' (for optional columns such as the survey term).
#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
rest_pull_name <- function(data, var, arg) {
  if (rlang::quo_is_null(var)) return(NULL)
  tryCatch(
    tidyselect::vars_pull(names(data), !!var),
    error = function(e) cli_abort(
      c("{.arg {arg}} must select a single existing column in {.arg detection_data}.",
        "x" = conditionMessage(e)),
      call = NULL)
  )
}

#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
rest_assert_df <- function(x, name) {
  if (!is.data.frame(x)) cli_abort("{.arg {name}} must be a data frame.")
}

#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
rest_assert_cols <- function(data, cols, name) {
  cols <- cols[!is.null(cols)]
  missing <- setdiff(cols, names(data))
  if (length(missing)) cli_abort("{.arg {name}} is missing column(s): {.val {missing}}.")
}

#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
rest_assert_unique_station <- function(station_data, station_col) {
  if (any(duplicated(station_data[[station_col]]))) {
    cli_abort("{.arg station_data} must have one row per station; duplicate IDs in {.val {station_col}}.")
  }
}

#' Standardise a station table: rename ID to Station, drop clashing columns
#' @keywords internal
#' @noRd
#' @importFrom rlang .data
rest_clean_station <- function(station_data, station_col, drop = NULL, drop_regex = NULL) {
  out <- station_data
  if (station_col != "Station" && "Station" %in% names(out)) {
    out <- dplyr::select(out, -dplyr::any_of("Station"))
  }
  out <- out %>%
    dplyr::rename(Station = dplyr::all_of(station_col)) %>%
    dplyr::mutate(Station = as.character(.data$Station))
  if (!is.null(drop)) out <- dplyr::select(out, -dplyr::any_of(drop))
  if (!is.null(drop_regex)) {
    clash <- setdiff(grep(drop_regex, names(out), value = TRUE), "Station")
    out <- dplyr::select(out, -dplyr::any_of(clash))
  }
  out
}

#' Ensure RAD-REST pass-count columns are contiguous (y_0 .. y_max) and ordered
#' @keywords internal
#' @noRd
rest_fill_pass_columns <- function(passes) {
  y_cols <- grep("^y_\\d+$", names(passes), value = TRUE)
  idx <- as.integer(sub("^y_", "", y_cols))
  for (missing in setdiff(0:max(c(0, idx)), idx)) passes[[paste0("y_", missing)]] <- 0
  ordered <- paste0("y_", 0:max(c(0, idx)))
  dplyr::select(passes, dplyr::any_of(c("Station", "Species", "N")), dplyr::all_of(ordered))
}

#' Gantt-style plot of camera operation periods
#' @keywords internal
#' @noRd
#' @importFrom rlang .data
rest_effort_plot <- function(by_group, term_col) {
  label_size <- max(5, 12 - nrow(by_group) / 10)
  aes_seg <- if (!is.null(term_col)) {
    ggplot2::aes(x = .data$Start, xend = .data$End, y = .data$Station,
                 yend = .data$Station, colour = .data$Term)
  } else {
    ggplot2::aes(x = .data$Start, xend = .data$End, y = .data$Station, yend = .data$Station)
  }
  ggplot2::ggplot(by_group) +
    ggplot2::geom_segment(aes_seg, alpha = 0.5, linewidth = 2.5) +
    ggplot2::geom_point(ggplot2::aes(x = .data$Start, y = .data$Station),
                        shape = 4, colour = "red", alpha = 0.8) +
    ggplot2::geom_point(ggplot2::aes(x = .data$End, y = .data$Station),
                        shape = 4, colour = "blue", alpha = 0.8) +
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = label_size)) +
    ggplot2::labs(x = "Survey period", y = "Station", title = "Camera operation periods")
}
