#' Correct camera trap datetime records
#'
#' This function corrects datetime stamps in camera trap data using a reference
#' correction table. It applies time adjustments based on known timing errors
#' for each camera deployment.
#'
#' Two kinds of clock error are handled. A constant offset (a camera set to the
#' wrong date or time) is corrected from the true datetime of the first record
#' of each deployment. Clock drift (a camera that gains or loses time during the
#' deployment) is corrected when the true datetime of the last record is also
#' supplied: the correction then changes linearly with time, from the offset at
#' the first record to the offset at the last record.
#'
#' Camera clocks do not change for daylight saving time. Datetimes are therefore
#' parsed in the time zone given by `time_zone`, which defaults to `"UTC"` (no daylight
#' saving), so that recorded wall-clock times are kept as they are and no record
#' is shifted or lost at a daylight saving change.
#'
#' @param data A data.frame or tibble containing camera trap records with
#'   datetime information that needs correction.
#' @param datetime Column name (unquoted) in `data` containing the datetime
#'   values to be corrected. Can be character or POSIXct format.
#' @param deployment Column name (unquoted) in both `data` and
#'   \code{corrector} that identifies unique camera deployments (e.g., camera ID,
#'   site name, or deployment identifier).
#' @param corrector A data.frame containing correction information with columns:
#'   \itemize{
#'     \item deployment column matching the deployment parameter
#'     \item `sign` - character indicating correction direction ("+" or "-")
#'     \item `datetimes` - correct date-time of the first (earliest) record of
#'       the deployment
#'     \item `end_datetimes` - optional; correct date-time of the last (latest)
#'       record of the deployment. When present and not missing, the correction
#'       drifts linearly between the first and the last record.
#'   }
#' @param format Optional datetime format specification. Can be:
#'   \itemize{
#'     \item `NULL` (default) - attempts multiple common formats
#'     \item Single format string - used for both `data` and `corrector` datetimes
#'     \item Vector of 2 format strings - first for data, second for corrector
#'   }
#'
#'
#' @param time_zone Time zone used to parse the datetimes in `data` and `corrector`.
#'   Defaults to `"UTC"`, which has no daylight saving time and so keeps camera
#'   wall-clock times unchanged. Any time zone name accepted by [as.POSIXct()]
#'   can be used, for example `Sys.timezone()` for the computer's time zone
#'   when the deployment does not span a daylight-saving change.
#'
#' @return A data.frame with the original data plus additional columns:
#'   \itemize{
#'     \item \code{corrected_datetime} - corrected datetime as POSIXct
#'     \item \code{correction_applied} - sign of correction applied
#'     \item \code{time_offset_seconds} - magnitude of correction in seconds
#'       (varies between records when drift is corrected)
#'     \item \code{corrector_reference} - reference datetime used for correction
#'   }
#'
#' @examples
#' # Load camera trap data
#' library(dplyr)
#' data(penessoulou)
#'
#' camtrap_data <- penessoulou %>%
#'   dplyr::filter(project == "Last")
#'
#' # Create correction table
#' # CAMERA 1 was running slow (+), CAMERA 2 was running fast (-)
#' crtor <- data.frame(
#'   camera = c("CAMERA 1", "CAMERA 2"),
#'   sign = c("+", "-"),
#'   datetimes = c("2025-03-14 8:17:00", "2024-11-14 10:02:03")
#' )
#'
#' # Apply datetime corrections
#' ct_correct_datetime(
#'   data = camtrap_data,
#'   datetime = datetimes,
#'   deployment = camera,
#'   corrector = crtor
#' ) %>%
#'   dplyr::select(datetimes,
#'                 corrected_datetime,
#'                 time_offset_seconds) %>%
#'   dplyr::slice_head(n = 10)
#'
#' # Clock drift: CAMERA 1 also lost 90 s over the deployment, so the true time
#' # of its last record is 90 s later than the constant offset gives
#' crtor_drift <- crtor
#' crtor_drift$end_datetimes <- c("2025-04-16 01:16:15", NA)
#'
#' ct_correct_datetime(
#'   data = camtrap_data,
#'   datetime = datetimes,
#'   deployment = camera,
#'   corrector = crtor_drift
#' ) %>%
#'   dplyr::filter(camera == "CAMERA 1") %>%
#'   dplyr::select(datetimes, corrected_datetime, time_offset_seconds) %>%
#'   dplyr::slice_tail(n = 5)
#'
#' @export
ct_correct_datetime <- function(data,
                                datetime,
                                deployment,
                                corrector,
                                format = NULL,
                                time_zone = "UTC") {

  # Validate inputs
  if (!inherits(data, "data.frame")) {
    cli::cli_abort("{.strong {deparse(substitute(data))}} must be a {.cls data.frame} or {.cls tibble} object.")
  }

  if (!inherits(corrector, "data.frame")) {
    cli::cli_abort("{.strong {deparse(substitute(corrector))}} must be a {.cls data.frame} or {.cls tibble} object.")
  }

  # Check required columns in corrector
  required_cols <- c(deparse(substitute(deployment)), "sign", "datetimes")
  missing_cols <- setdiff(required_cols, names(corrector))
  if (length(missing_cols) > 0) {
    cli::cli_abort("{.strong {deparse(substitute(corrector))}} has {length(missing_cols)} missing required column{?s}: {.field {missing_cols}}")
  }

  # Get deployment identifiers
  deployment_col <- deparse(substitute(deployment))
  datetime_col <- deparse(substitute(datetime))

  # Check for unique deployments in corrector
  corrector_deployments <- corrector[[deployment_col]]
  if (length(unique(corrector_deployments)) != nrow(corrector)) {
    cli::cli_abort("{.strong {deparse(substitute(corrector))}} must have unique identifiers in {.field {deployment_col}} column.")
  }

  # Process each deployment
  corrected_data_list <- lapply(corrector_deployments, function(deploy_id) {

    # Filter data for current deployment
    current_data <- data %>%
      dplyr::filter(!!sym(deployment_col) == deploy_id)

    if (nrow(current_data) == 0) {
      cli::cli_warn("No data found for deployment: {.strong {deploy_id}}")
      return(NULL)
    }

    # Get correction info for this deployment
    correction_info <- corrector %>%
      dplyr::filter(!!sym(deployment_col) == deploy_id)

    # Parse datetime columns
    if (!is.null(format)) {
      if (length(format) == 1) {
        # Same format for both data and corrector
        data_datetime <- as.POSIXct(current_data[[datetime_col]], format = format, tz = time_zone)
        corrector_datetime <- as.POSIXct(correction_info$datetimes, format = format, tz = time_zone)
        corrector_fmt <- format
      } else if (length(format) == 2) {
        # Different formats for data and corrector
        data_datetime <- as.POSIXct(current_data[[datetime_col]], format = format[1], tz = time_zone)
        corrector_datetime <- as.POSIXct(correction_info$datetimes, format = format[2], tz = time_zone)
        corrector_fmt <- format[2]
      } else {
        cli::cli_abort("Format must be NULL, a single format string, or a vector of 2 format strings.")
      }
    } else {
      # Try multiple formats
      data_datetime <- as.POSIXct(current_data[[datetime_col]], tryFormats = try_formats, tz = time_zone)
      corrector_datetime <- as.POSIXct(correction_info$datetimes, tryFormats = try_formats, tz = time_zone)
      corrector_fmt <- NULL
    }

    # Check for parsing failures
    if (any(is.na(data_datetime))) {
      cli::cli_warn("Failed to parse some datetimes in data for deployment: {.strong {deploy_id}}")
    }
    if (any(is.na(corrector_datetime))) {
      cli::cli_warn("Failed to parse corrector datetime for deployment: {.strong {deploy_id}}")
    }

    # Calculate time difference (corrector shows what the correct time should be)
    correction_sign <- trimws(correction_info$sign)

    # Sort data_datetime to use earliest timestamp as reference point
    # This ensures consistent offset calculation regardless of data order
    sorted_datetime <- sort(data_datetime, na.last = TRUE)
    reference_datetime <- sorted_datetime[1]  # Use earliest timestamp

    # The corrector datetime represents the correct time at a reference point
    # Calculate the offset between actual camera time and correct time
    time_diff <- as.numeric(difftime(corrector_datetime, reference_datetime, units = "secs"))

    if (!correction_sign %in% c("+", "-")) {
      cli::cli_abort("Invalid sign '{.strong {correction_sign}}' for deployment {.strong {deploy_id}}.")
    }
    # Signed offset at the first record: "+" camera running slow, "-" fast
    offset_start <- if (correction_sign == "+") abs(time_diff) else -abs(time_diff)
    offset <- rep(offset_start, length(data_datetime))

    # Optional drift: the true time of the last record gives the offset at the
    # end, and the offset is interpolated linearly in between.
    end_value <- if ("end_datetimes" %in% names(correction_info)) correction_info$end_datetimes else NA
    if (length(end_value) == 1 && !is.na(end_value)) {
      end_true <- if (is.null(corrector_fmt)) {
        as.POSIXct(end_value, tryFormats = try_formats, tz = time_zone)
      } else {
        as.POSIXct(end_value, format = corrector_fmt, tz = time_zone)
      }
      last_datetime <- max(data_datetime, na.rm = TRUE)
      span <- as.numeric(difftime(last_datetime, reference_datetime, units = "secs"))
      if (is.na(end_true)) {
        cli::cli_warn("Failed to parse end datetime for deployment {.strong {deploy_id}}; constant offset applied.")
      } else if (span <= 0) {
        cli::cli_warn("Deployment {.strong {deploy_id}} has a single timestamp; drift cannot be estimated, constant offset applied.")
      } else {
        offset_end <- as.numeric(difftime(end_true, last_datetime, units = "secs"))
        elapsed <- as.numeric(difftime(data_datetime, reference_datetime, units = "secs"))
        offset <- offset_start + (offset_end - offset_start) * elapsed / span
      }
    }

    corrected_datetime <- data_datetime + offset
    time_offset <- abs(offset)

    # Add corrected datetime and metadata to data
    result <- current_data %>%
      dplyr::mutate(
        corrected_datetime = corrected_datetime,
        correction_applied = correction_sign,
        time_offset_seconds = time_offset,
        corrector_reference = corrector_datetime
      )

    return(result)
  })

  # Remove NULL results and combine
  corrected_data_list <- corrected_data_list[!sapply(corrected_data_list, is.null)]

  if (length(corrected_data_list) == 0) {
    cli::cli_warn("No corrections could be applied.")
    return(data)
  }

  # Combine all corrected data
  final_data <- bind_rows(corrected_data_list)

  return(final_data)
}
