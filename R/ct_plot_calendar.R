#' Plot a calendar heatmap of daily camera trap activity
#'
#' Visualises a year of camera-trap records as a calendar heatmap.
#' Tiles are shaded by the number of
#' records per day, or by the summed value of a chosen column. A count
#' distribution can optionally be fitted to the daily values and used for the
#' shading.
#'
#' @param data A data frame of records, one row per detection.
#' @param datetime Column holding the date or date-time of each record.
#' @param format Optional date format(s) passed to [as.Date()] via `tryFormats`.
#'   If `NULL` (default), a set of common date and date-time formats is tried.
#' @param size_column Optional column whose values are summed per day, for
#'   example the number of individuals recorded in each detection. If omitted,
#'   the number of records (detections) per day is used instead.
#' @param only_month Optional integer vector of month numbers (1 to 12) to keep,
#'   for example `3:5`. Records outside these months are dropped and only those
#'   month panels are drawn. Default `NULL` (the whole year).
#' @param fit_distribution Logical. If `TRUE`, a count distribution is fitted to
#'   the records per day over the displayed period (days with no record count as
#'   zeros) with [ct_fit_distribution()], and the fitted distribution is reported
#'   in the plot subtitle. Tiles are then shaded by the fitted density, that is
#'   the probability of each day's count under the model. The calendar therefore
#'   becomes a typicality map, not an activity map: the brightest tiles are the
#'   most probable days under the fitted distribution, which for zero-heavy
#'   camera-trap data are usually the days with no detection, while busier days
#'   carry rarer counts and appear darker. See Details. Default `FALSE`.
#' @param abbreviate_month_name Logical. Use three-letter month names. Ignored
#'   when `month_name` is supplied. Default `FALSE`.
#' @param month_name Optional length-12 character vector of month labels, for
#'   localisation. Defaults to the English month names.
#' @param day_name Optional length-7 character vector of weekday labels, Monday
#'   first. Defaults to `c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")`.
#' @param number_of_column Number of month panels per row. Default `4`.
#' @param low,high Optional start and end colours for a two-colour gradient
#'   fill. When both are supplied they override `palette`.
#' @param palette Optional fill palette. Either a single viridis option letter
#'   (for example `"C"`), or a vector of two or more colours for a custom
#'   gradient. Default `NULL` (viridis option C).
#' @param na_value Fill colour for days with no records. Default `"grey95"`.
#' @param show_day_number Logical. Print the day number inside each tile.
#'   Default `TRUE`.
#' @param title Optional plot title. Generated automatically when `NULL`.
#'
#' @details
#' With `fit_distribution = FALSE` the calendar is an activity map: tiles are
#' shaded by the records per day (or the summed `size_column`), so busier days
#' are brighter.
#'
#' With `fit_distribution = TRUE` the calendar is instead a typicality map. A
#' single distribution is fitted to the whole displayed period, and each tile is
#' shaded by the fitted probability of that day's count. Because most days have
#' no detection, the count of zero is the most probable value, so empty days
#' receive the highest density and the brightest colour, while the rarer busy
#' days appear darker. The map highlights how typical or
#' unusual each day is under the model, rather than how much activity occurred.
#' Use `fit_distribution = FALSE` if you want activity intensity instead.
#'
#' @return A [ggplot2::ggplot] object.
#'
#' @seealso [ct_fit_distribution()], [ct_plot_camtrap_activity()]
#'
#' @examples
#' library(dplyr)
#' data(ACBR)
#'
#' # The calendar covers one year at a time, so keep a single year.
#' d2024 <- ACBR$acbr_data %>%
#'   # Filter to independent (10min separated) detections
#'   ct_independence(species_column = species,
#'                   datetime = datetime,
#'                   format = "%Y-%m-%d %H:%M:%S",
#'                   threshold = 10*60
#'   ) %>%
#'   # Select data for 2025 year
#'   filter(lubridate::year(datetime) == 2025)
#'
#' ct_plot_calendar(d2024, datetime = datetime,
#'                  size_column = count,
#'                  low = "gray", high = "red"
#' )
#' #'
#' @importFrom rlang .data
#' @export
ct_plot_calendar <- function(data,
                             datetime,
                             format = NULL,
                             size_column = NULL,
                             only_month = NULL,
                             fit_distribution = FALSE,
                             abbreviate_month_name = FALSE,
                             month_name = NULL,
                             day_name = NULL,
                             number_of_column = 4,
                             low = NULL,
                             high = NULL,
                             palette = NULL,
                             na_value = "grey95",
                             show_day_number = TRUE,
                             title = NULL) {

  format <- if (is.null(format)) try_formats else format

  # resolve columns via tidy-select (bare name, string, or position)
  datetime_col <- names(dplyr::select(data, {{ datetime }}))
  if (length(datetime_col) != 1)
    cli::cli_abort("{.arg datetime} must select exactly one column.")

  size_quo <- rlang::enquo(size_column)
  has_size <- !rlang::quo_is_null(size_quo)
  size_col <- if (has_size) names(dplyr::select(data, !!size_quo)) else NULL

  # parse the date and require a single year
  dttime <- tryCatch(
    as.Date(as.character(data[[datetime_col]]), tryFormats = format),
    error = function(e)
      cli::cli_abort("{.arg format} could not parse column {.field {datetime_col}}.",
                     call = NULL)
  )
  if (all(is.na(dttime)))
    cli::cli_abort("No value in {.field {datetime_col}} could be parsed as a date.")

  years <- sort(unique(stats::na.omit(lubridate::year(dttime))))
  if (length(years) > 1)
    cli::cli_abort(c(
      "One year is required, but {.field {datetime_col}} spans {.val {years}}.",
      "i" = "Filter to a single year, for example with dplyr::filter()."
    ))

  # optional restriction to a subset of months
  if (!is.null(only_month)) {
    only_month <- as.integer(only_month)
    if (anyNA(only_month) || any(only_month < 1 | only_month > 12))
      cli::cli_abort("{.arg only_month} must be month numbers between 1 and 12.")
  }

  # daily values: summed size_column, else number of records
  daily <- dplyr::tibble(
    doy = dttime,
    val = if (has_size) as.numeric(data[[size_col]]) else 1
  )
  daily <- daily %>% dplyr::filter(!is.na(.data$doy))
  if (!is.null(only_month))
    daily <- daily %>% dplyr::filter(lubridate::month(.data$doy) %in% only_month)
  daily <- daily %>%
    dplyr::group_by(.data$doy) %>%
    dplyr::summarise(daily_effort = sum(.data$val, na.rm = TRUE), .groups = "drop")

  # calendar skeleton (days with no record become NA), restricted to only_month
  all_days <- seq.Date(as.Date(sprintf("%d-01-01", years[1])),
                       as.Date(sprintf("%d-12-31", years[1])), by = "day")
  if (!is.null(only_month))
    all_days <- all_days[lubridate::month(all_days) %in% only_month]
  cal <- dplyr::tibble(doy = all_days) %>%
    dplyr::left_join(daily, by = "doy")

  legend_name <- "Daily effort"

  # Optional distribution fit. The model is fitted to the records per day over
  # the displayed period (days with no record count as genuine zeros), tiles are
  # then shaded by the fitted density of each day's count, and the fitted
  # distribution is also reported in the subtitle. The distribution is chosen
  # from the data: binomial when the daily counts are all 0/1, negative binomial
  # when they are overdispersed (variance-to-mean ratio above 1.5), else Poisson.
  # This is intentionally a typicality map: zero is the most probable count, so
  # empty days carry the highest density and the brightest colour.
  fit_subtitle <- NULL
  if (fit_distribution) {
    counts <- ifelse(is.na(cal$daily_effort), 0, cal$daily_effort)
    distribution <- if (all(counts %in% c(0, 1))) {
      "binomial"
    } else if (stats::var(counts) / mean(counts) > 1.5) {
      "nbinomial"
    } else {
      "poisson"
    }
    fit <- ct_fit_distribution(count = counts, distribution = distribution)
    cal$daily_effort <- switch(distribution,
      binomial  = stats::dbinom(counts, size = 1, prob = fit[["prob"]]),
      nbinomial = stats::dnbinom(counts, size = fit[["size"]], prob = fit[["prob"]]),
      poisson   = stats::dpois(counts, lambda = fit[["lambda"]])
    )
    fit_subtitle <- switch(distribution,
      binomial  = sprintf("Fitted Bernoulli: p = %.3f", fit[["prob"]]),
      nbinomial = sprintf("Fitted negative binomial: size = %.2f, mu = %.2f",
                          fit[["size"]], fit[["mu"]]),
      poisson   = sprintf("Fitted Poisson: lambda = %.2f", fit[["lambda"]])
    )
    legend_name <- "Probability"
  }

  # calendar geometry
  if (is.null(month_name))
    month_name <- if (abbreviate_month_name) month.abb else month.name
  if (length(month_name) != 12) cli::cli_abort("{.arg month_name} must have length 12.")
  if (is.null(day_name)) day_name <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  if (length(day_name) != 7) cli::cli_abort("{.arg day_name} must have length 7.")

  cal <- cal %>%
    dplyr::mutate(
      day = lubridate::day(.data$doy),
      month = factor(month_name[lubridate::month(.data$doy)], levels = month_name),
      wday = factor(lubridate::wday(.data$doy, week_start = 1), levels = 1:7),
      week = (.data$day +
                 (lubridate::wday(lubridate::floor_date(.data$doy, "month"),
                                  week_start = 1) - 1) - 1) %/% 7 + 1
    )

  # fill scale
  fill_scale <- if (!is.null(low) && !is.null(high)) {
    ggplot2::scale_fill_gradient(low = low, high = high, na.value = na_value,
                                 name = legend_name)
  } else if (!is.null(palette) && length(palette) > 1) {
    ggplot2::scale_fill_gradientn(colours = palette, na.value = na_value,
                                  name = legend_name)
  } else {
    ggplot2::scale_fill_viridis_c(option = if (is.null(palette)) "C" else palette,
                                  na.value = na_value, name = legend_name)
  }

  if (is.null(title)) title <- sprintf("%s | %d", legend_name, years[1])

  # build the plot
  p <- ggplot2::ggplot(cal, ggplot2::aes(x = .data$wday, y = .data$week,
                                         fill = .data$daily_effort)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.4)

  if (show_day_number)
    p <- p + ggplot2::geom_text(ggplot2::aes(label = .data$day),
                                size = 2.5, color = "grey30")

  p +
    ggplot2::facet_wrap(~ month, ncol = number_of_column) +
    ggplot2::scale_y_reverse(breaks = NULL) +
    ggplot2::scale_x_discrete(labels = day_name, drop = FALSE) +
    fill_scale +
    ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = fit_subtitle) +
    ggplot2::coord_equal() +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid  = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(size = 7),
      strip.text  = ggplot2::element_text(face = "bold")
    )
}


#' Fit a count distribution by maximum likelihood
#'
#' Fits a Poisson, negative binomial, or binomial distribution to a vector of
#' counts and returns the parameter estimates together with the log-likelihood,
#' AIC and BIC.
#'
#' @param count Numeric vector of non-negative counts. For
#'   `distribution = "binomial"` it must contain only 0 and 1.
#' @param distribution One of `"poisson"`, `"nbinomial"` or `"binomial"`.
#'
#' @return A one-row [tibble][dplyr::tibble] with the fitted parameter(s), their
#'   standard error(s), the log-likelihood, AIC, BIC and sample size.
#'
#' @seealso [ct_plot_calendar()]
#'
#' @examples
#' set.seed(1)
#' ct_fit_distribution(stats::rpois(100, 3), "poisson")
#' ct_fit_distribution(stats::rnbinom(100, size = 1, mu = 4), "nbinomial")
#'
#' @export
ct_fit_distribution <- function(count, distribution) {
  distribution <- rlang::arg_match(distribution, c("poisson", "nbinomial", "binomial"))
  switch(distribution,
         poisson = fit_poisson(count),
         nbinomial = fit_nbinomial(count),
         binomial = fit_binomial(count))
}

#' Poisson maximum-likelihood fit
#' @keywords internal
#' @noRd
fit_poisson <- function(counts) {
  counts <- ifelse(is.na(counts), 0, counts)
  lambda_hat <- mean(counts)
  n <- length(counts)
  loglik <- sum(stats::dpois(counts, lambda_hat, log = TRUE))
  aic <- -2 * loglik + 2
  bic <- -2 * loglik + log(n)
  dplyr::tibble(lambda = lambda_hat, lambda_se = sqrt(lambda_hat / n),
                loglik = loglik, aic = aic, bic = bic, n = n,
                distribution = "poisson")
}

#' Negative binomial maximum-likelihood fit
#' @keywords internal
#' @noRd
fit_nbinomial <- function(counts) {
  counts <- ifelse(is.na(counts), 0, counts)
  n <- length(counts)
  m <- mean(counts)
  # mu has a closed form (the sample mean); size (theta) is found numerically.
  negloglik <- function(log_theta)
    -sum(stats::dnbinom(counts, size = exp(log_theta), mu = m, log = TRUE))
  v <- stats::var(counts)
  theta_start <- if (v > m) m^2 / (v - m) else 10
  opt <- stats::optim(par = log(theta_start), fn = negloglik,
                      method = "BFGS", hessian = TRUE)
  theta_hat <- exp(opt$par)
  loglik <- -opt$value
  var_log_theta <- tryCatch(1 / opt$hessian[1, 1], error = function(e) NA_real_)
  aic <- -2 * loglik + 4
  bic <- -2 * loglik + log(n) * 2
  dplyr::tibble(size = theta_hat, mu = m, prob = theta_hat / (theta_hat + m),
                theta_se = sqrt(var_log_theta) * theta_hat,
                loglik = loglik, aic = aic, bic = bic, n = n,
                distribution = "nbinomial")
}

#' Binomial (presence/absence) maximum-likelihood fit
#' @keywords internal
#' @noRd
fit_binomial <- function(x) {
  x <- ifelse(is.na(x), 0, x)
  if (!all(x %in% c(0, 1))) cli::cli_abort("{.arg count} must contain only 0 and 1.")
  if (length(x) == 0) cli::cli_abort("{.arg count} is empty.")
  n <- length(x)
  k <- sum(x)
  p_hat <- k / n
  loglik <- sum(stats::dbinom(x, size = 1, prob = p_hat, log = TRUE))
  aic <- -2 * loglik + 2
  bic <- -2 * loglik + log(n)
  dplyr::tibble(prob = p_hat, prob_se = sqrt(p_hat * (1 - p_hat) / n),
                loglik = loglik, aic = aic, bic = bic, n = n, successes = k,
                distribution = "binomial")
}
