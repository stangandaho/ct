#' Calculate the temporal shift of one species' activity over two periods
#'
#' Estimates and analyzes the temporal shift in the activity of a species between
#' two time periods using kernel density estimation. The activity distributions are
#' compared and the magnitude, direction, and (optionally) a bootstrap confidence
#' interval for the shift size are returned.
#'
#' @param first_period A numeric vector of activity times in radians for the first period.
#' @param second_period A numeric vector of activity times in radians for the second period.
#' @param convert_time Logical. If `TRUE`, converts times to radians before analysis.
#' @inheritParams ct_plot_overlap
#' @param width_at Numeric. Fraction of peak density at which the activity window width
#'   is measured (default `0.5`, i.e. half-maximum).
#' @param format Character. Input time format (default `"%H:%M:%S"`).
#'   Only used when `convert_time = TRUE`.
#' @param time_zone Character. Time zone for conversion. Required when `convert_time = TRUE`.
#' @param n_boot Integer. Number of bootstrap resamples used to compute a confidence interval
#'   for the shift size. Set to `0` to skip bootstrapping (default `999`).
#' @param boot_ci Numeric. Confidence level for the bootstrap CI, strictly between 0 and 1
#'   (default `0.95`).
#' @param plot Logical. If `TRUE`, prints and returns a ggplot comparing the activity
#'   distributions of the two periods.
#' @param linestyle_1 List. Line style for the first period's density curve.
#'   Accepts: `linetype`, `linewidth`, `color`.
#' @param linestyle_2 List. Line style for the second period's density curve.
#'   Accepts: `linetype`, `linewidth`, `color`.
#' @param posestyle_1 List. Marker style for the first period's activity-range indicator.
#'   Accepts: `shape`, `size`, `color`, `alpha`.
#' @param posestyle_2 List. Marker style for the second period's activity-range indicator.
#'   Accepts: `shape`, `size`, `color`, `alpha`.
#' @param period_names Character vector of length 2 giving the legend labels for the
#'   first and second periods (default `c("First period", "Second period")`). For
#'   example, `c("Dry", "Rainy")`.
#' @param legend_title Character. Title shown above the period legend (default `"Period"`).
#' @param ... Additional arguments (currently unused).
#'
#' @return When `plot = FALSE`: a tibble. When `plot = TRUE`: a list whose first element
#'   is the tibble and whose `$plot` element is a `ggplot2` object. The tibble contains:
#'   \describe{
#'     \item{`First period range`}{Start and end of the active window for the first period.}
#'     \item{`Second period range`}{Start and end of the active window for the second period.}
#'     \item{`Shift size (in hour)`}{Absolute difference in activity-window duration between periods.}
#'     \item{`Displacement (in hour)`}{Signed shift of the activity window along the day,
#'       measured at its midpoint: positive means the second period is active later,
#'       negative earlier. Unlike `Shift size` (a duration change), this captures a pure
#'       time shift, so a window that slides without changing length has
#'       `Shift size` near 0 but a non-zero `Displacement`.}
#'     \item{`Shift CI lower (XX%)`/`Shift CI upper (XX%)`}{Bootstrap CI bounds
#'       (only when `n_boot > 0`).}
#'     \item{`Move`}{Direction/type of shift: `"Forward"`, `"Backward"`, `"Enlarged"`,
#'       `"Contracted"`, `"Constant"`, `"Forward Edge"`, `"Backward Edge"`,
#'       `"Contracted Edge (Max)"`, `"Contracted Edge (Min)"`, or `"Undefined"`.}
#'   }
#'
#' @examples
#' library(ggplot2)
#'
#' # Using radians as input
#' first_period  <- c(1.3, 2.3, 2.5, 5.2, 6.1, 2.3)
#' second_period <- c(1.8, 2.2, 2.5)
#' result <- ct_temporal_shift(
#'   first_period, second_period, plot = TRUE, xcenter = "noon", n_boot = 100,
#'   linestyle_1 = list(color = "gray10", linetype = 1, linewidth = 1),
#'   posestyle_1 = list(color = "gray10"),
#'
#'   linestyle_2 = list(color = "#b70000", linetype = 5, linewidth = 0.5),
#'   posestyle_2 = list(color = "#b70000")
#' )
#'
#' result
#'
#' # Customize the returned plot
#' result$plot + theme(legend.position = "top")
#'
#' # Using time strings as input
#' first_period  <- c("12:03:05", "13:10:09", "14:08:10", "14:18:30", "18:22:11")
#' second_period <- c("13:00:20", "14:20:10", "15:55:20", "16:03:01", "16:47:00")
#' result <- ct_temporal_shift(
#'   first_period, second_period,
#'   convert_time = TRUE, format = "%H:%M:%S", time_zone = "UTC"
#' )
#'
#' @import dplyr ggplot2
#'
#' @export
ct_temporal_shift <- function(first_period,
                              second_period,
                              convert_time = FALSE,
                              xscale = 24,
                              xcenter = c("noon", "midnight"),
                              n_grid = 128,
                              kmax = 3,
                              adjust = 1,
                              width_at = 1/2,
                              format = "%H:%M:%S",
                              time_zone,
                              n_boot = 999,
                              boot_ci = 0.95,
                              plot = TRUE,
                              linestyle_1 = list(),
                              linestyle_2 = list(),
                              posestyle_1 = list(),
                              posestyle_2 = list(),
                              period_names = c("First period", "Second period"),
                              legend_title = "Period",
                              ...) {

  if (length(period_names) != 2 || !is.character(period_names))
    rlang::abort("`period_names` must be a character vector of length 2.")
  p1 <- period_names[1]; p2 <- period_names[2]

  if (convert_time) {
    first_period  <- ct_to_radian(times = first_period,  format = format, time_zone = time_zone)
    second_period <- ct_to_radian(times = second_period, format = format, time_zone = time_zone)
  }

  if (width_at < 0 || width_at > 1)
    rlang::abort(sprintf("width_at = %f is outside [0, 1]", width_at))

  if (n_boot > 0 && (boot_ci <= 0 || boot_ci >= 1))
    rlang::abort("`boot_ci` must be strictly between 0 and 1.")

  check_density_input(first_period)
  check_density_input(second_period)

  xcenter <- match.arg(xcenter)
  isMidnt <- xcenter == "midnight"

  bwA <- overlap::getBandWidth(first_period,  kmax = kmax) / adjust
  bwB <- overlap::getBandWidth(second_period, kmax = kmax) / adjust
  if (is.na(bwA) || is.na(bwB))
    rlang::abort("Bandwidth estimation failed.", call = NULL)

  xsc   <- if (is.na(xscale)) 1 else xscale / (2 * pi)
  xxRad <- seq(0, 2 * pi, length.out = n_grid)
  if (isMidnt) xxRad <- xxRad - pi
  xx <- xxRad * xsc

  kde_times1 <- overlap::densityFit(first_period,  xxRad, bwA)
  kde_times2 <- overlap::densityFit(second_period, xxRad, bwB)

  above1 <- kde_times1 > max(kde_times1) * width_at
  above2 <- kde_times2 > max(kde_times2) * width_at

  fwhm_range1 <- range(xx[above1])
  fwhm_range2 <- range(xx[above2])

  times_min1 <- fwhm_range1[1]; times_max1 <- fwhm_range1[2]
  times_min2 <- fwhm_range2[1]; times_max2 <- fwhm_range2[2]

  ytime1 <- min(kde_times1[above1])
  ytime2 <- min(kde_times2[above2])

  fp   <- ct_to_time(abs(c(times_min1, times_max1)) / xsc)
  fp_h <- convert_to_hour(fp)
  sp   <- ct_to_time(abs(c(times_min2, times_max2)) / xsc)
  sp_h <- convert_to_hour(sp)

  shift_size <- round(abs((fp_h[2] - fp_h[1]) - (sp_h[2] - sp_h[1])), 3)

  # Temporal displacement: how far the activity window slid along the day,
  # measured at its midpoint. Positive = the second period is active later,
  # negative = earlier. Complements `shift_size`, which only captures a change in
  # the window's duration (so a pure time shift has shift_size 0 but displacement != 0).
  displacement <- round(mean(sp_h) - mean(fp_h), 2)

  # Bootstrap CI for shift size
  if (n_boot > 0) {
    .boot_shift <- function(fp_data, sp_data) {
      bw_fp <- tryCatch(
        overlap::getBandWidth(fp_data, kmax = kmax) / adjust,
        error = function(e) NA_real_
      )
      bw_sp <- tryCatch(
        overlap::getBandWidth(sp_data, kmax = kmax) / adjust,
        error = function(e) NA_real_
      )
      if (anyNA(c(bw_fp, bw_sp))) return(NA_real_)

      k_fp <- overlap::densityFit(fp_data, xxRad, bw_fp)
      k_sp <- overlap::densityFit(sp_data, xxRad, bw_sp)

      ab_fp <- k_fp > max(k_fp) * width_at
      ab_sp <- k_sp > max(k_sp) * width_at
      if (sum(ab_fp) < 2 || sum(ab_sp) < 2) return(NA_real_)

      r_fp <- range(xx[ab_fp])
      r_sp <- range(xx[ab_sp])

      h_fp <- convert_to_hour(ct_to_time(abs(r_fp) / xsc))
      h_sp <- convert_to_hour(ct_to_time(abs(r_sp) / xsc))
      abs((h_fp[2] - h_fp[1]) - (h_sp[2] - h_sp[1]))
    }

    boot_vals <- vapply(seq_len(n_boot), function(i) {
      .boot_shift(
        sample(first_period,  replace = TRUE),
        sample(second_period, replace = TRUE)
      )
    }, numeric(1))

    boot_vals <- boot_vals[!is.na(boot_vals)]
    alpha_b <- 1 - boot_ci
    ci <- stats::quantile(boot_vals, probs = c(alpha_b / 2, 1 - alpha_b / 2), names = FALSE)
  }

  # Shift direction
  shift <- if (times_max2 > times_max1 && times_min2 > times_min1) "Forward"
            else if (times_max2 < times_max1 && times_min2 < times_min1) "Backward"
            else if (times_max2 > times_max1 && times_min2 < times_min1) "Enlarged"
            else if (times_max2 < times_max1 && times_min2 > times_min1) "Contracted"
            else if (times_max2 == times_max1 && times_min2 == times_min1) "Constant"
            else if (times_max2 > times_max1 && times_min2 == times_min1) "Forward Edge"
            else if (times_max2 == times_max1 && times_min2 < times_min1) "Backward Edge"
            else if (times_max2 < times_max1 && times_min2 == times_min1) "Contracted Edge (Max)"
            else if (times_max2 == times_max1 && times_min2 > times_min1) "Contracted Edge (Min)"
            else "Undefined"

  temporal_shift <- list(
    `First period range`     = paste0(fp, collapse = " - "),
    `Second period range`    = paste0(sp, collapse = " - "),
    `Shift size (in hour)`   = shift_size,
    `Displacement (in hour)` = displacement
  )

  if (n_boot > 0) {
    ci_tag <- sprintf("%d%%", round(boot_ci * 100))
    temporal_shift[[paste0("Shift CI lower (", ci_tag, ")")]] <- round(ci[1], 2)
    temporal_shift[[paste0("Shift CI upper (", ci_tag, ")")]] <- round(ci[2], 2)
  }

  temporal_shift[["Move"]] <- shift

  # Resolve style defaults
  ls1 <- list(
    linetype  = ifelse(!is.null(linestyle_1$linetype),  linestyle_1$linetype,  1),
    linewidth = ifelse(!is.null(linestyle_1$linewidth), linestyle_1$linewidth, 1),
    color = ifelse(!is.null(linestyle_1$color), linestyle_1$color, "#c90026")
  )
  ls2 <- list(
    linetype  = ifelse(!is.null(linestyle_2$linetype), linestyle_2$linetype,  3),
    linewidth = ifelse(!is.null(linestyle_2$linewidth), linestyle_2$linewidth, 1),
    color = ifelse(!is.null(linestyle_2$color), linestyle_2$color, "gray10")
  )
  ps1 <- list(
    shape = ifelse(!is.null(posestyle_1$shape), posestyle_1$shape, 19),
    size  = ifelse(!is.null(posestyle_1$size),  posestyle_1$size,  3),
    color = ifelse(!is.null(posestyle_1$color), posestyle_1$color, "#c90026"),
    alpha = ifelse(!is.null(posestyle_1$alpha), posestyle_1$alpha, 1)
  )
  ps2 <- list(
    shape = ifelse(!is.null(posestyle_2$shape), posestyle_2$shape, 19),
    size  = ifelse(!is.null(posestyle_2$size),  posestyle_2$size, 3),
    color = ifelse(!is.null(posestyle_2$color), posestyle_2$color, "gray10"),
    alpha = ifelse(!is.null(posestyle_2$alpha), posestyle_2$alpha, 1)
  )

  # Build plot data. Column names (and hence legend labels) come from period_names.
  plot_tbl <- dplyr::tibble(Time = xx, kde1 = kde_times1, kde2 = kde_times2)
  names(plot_tbl) <- c("Time", p1, p2)
  plot_data <- tidyr::pivot_longer(
    plot_tbl, cols = -Time, names_to = "Period", values_to = "Density"
  )
  plot_data$Period <- factor(plot_data$Period, levels = c(p1, p2))

  pose_data <- dplyr::tibble(
    times_min1 = times_min1, times_max1 = times_max1,
    times_min2 = times_min2, times_max2 = times_max2,
    ytime1 = ytime1, ytime2 = ytime2
  )

  # Construct ggplot
  # Mapping color, linetype, and linewidth to the same variable causes ggplot2 to
  # merge all three into a single legend that draws keys as styled line segments.
  p <- ggplot2::ggplot(data = plot_data) +
    ggplot2::geom_line(
      ggplot2::aes(
        x = Time, y = Density,
        color = Period, linetype = Period, linewidth = Period
      )
    ) +
    ggplot2::scale_color_manual(
      name = legend_title,
      values = stats::setNames(c(ls1$color, ls2$color), c(p1, p2))
    ) +
    ggplot2::scale_linetype_manual(
      name = legend_title,
      values = stats::setNames(c(ls1$linetype, ls2$linetype), c(p1, p2))
    ) +
    ggplot2::scale_linewidth_manual(
      name = legend_title,
      values = stats::setNames(c(ls1$linewidth, ls2$linewidth), c(p1, p2))
    ) +
    # Merge color + linetype into one legend; normalize key linewidth for readability.
    ggplot2::guides(
      color = ggplot2::guide_legend(override.aes = list(linewidth = 1)),
      linewidth = "none"
    ) +
    # Range markers - first period
    ggplot2::geom_point(
      data = pose_data,
      ggplot2::aes(x = times_min1, y = ytime1),
      size = ps1$size, color = ps1$color, shape = ps1$shape, alpha = ps1$alpha
    ) +
    ggplot2::geom_point(
      data = pose_data,
      ggplot2::aes(x = times_max1, y = ytime1),
      size = ps1$size, color = ps1$color, shape = ps1$shape, alpha = ps1$alpha
    ) +
    ggplot2::geom_segment(
      data = pose_data,
      ggplot2::aes(x = times_min1, xend = times_max1, y = ytime1, yend = ytime1),
      linetype = ls1$linetype, linewidth = ls1$linewidth, color = ls1$color
    ) +
    # Range markers - second period
    ggplot2::geom_point(
      data = pose_data,
      ggplot2::aes(x = times_min2, y = ytime2),
      size = ps2$size, color = ps2$color, shape = ps2$shape, alpha = ps2$alpha
    ) +
    ggplot2::geom_point(
      data = pose_data,
      ggplot2::aes(x = times_max2, y = ytime2),
      size = ps2$size, color = ps2$color, shape = ps2$shape, alpha = ps2$alpha
    ) +
    ggplot2::geom_segment(
      data = pose_data,
      ggplot2::aes(x = times_min2, xend = times_max2, y = ytime2, yend = ytime2),
      linetype = ls2$linetype, linewidth = ls2$linewidth, color = ls2$color
    ) +
    ggplot2::scale_x_continuous(
      breaks = if (xcenter == "noon") seq(0, 24, 2) else seq(-12, 12, 2),
      labels = function(x) {
        x <- ifelse(x < 0, 24 + x, x)
        sprintf("%02d:00", floor(x) %% 24)
      }
    ) +
    ggplot2::theme_minimal()

  if (plot) {
    print(p)
    return(invisible(list(dplyr::bind_cols(temporal_shift), plot = p)))
  }

  dplyr::bind_cols(temporal_shift)
}
