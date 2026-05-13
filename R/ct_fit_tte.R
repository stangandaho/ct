#' Estimate abundance from Time-To-Event (TTE) Data
#'
#' Estimate abundance from camera trap data using the Time-To-Event (TTE) model.
#'
#' @param data A tibble of camera trap detections. Must contain columns
#' \code{cam}, \code{datetime}, and \code{count}.
#' @param deployment_data A tibble of camera deployments. Must contain columns
#' \code{cam}, \code{start}, \code{end}, and \code{area}.
#' @param viewshed_transit_time Numeric. This is equal to the mean amount of time
#' (in seconds) required for an animal to cross the average viewshed of a camera.
#' It can be calculated in different ways depending on available information.
#'
#' For an animal with a movement speed of 30 m/hr passing through camera
#' viewsheds of 300 m^2, 400 m^2, and 380 m^2, the sampling period can be
#' approximated as:
#'
#' \deqn{
#' \frac{\sqrt{\frac{1}{n}\sum_{i=1}^{n} A_i}}{30/3600}
#' }
#'
#' where \eqn{A_i} represents the camera viewshed areas (in m^2) and \eqn{n} is the
#' number of cameras. The denominator is the animal speed converted from meters/hour
#' to meters/second.
#'
#' @param periods_per_occasion Numeric. Number of TTE sampling periods per
#' sampling occasion.
#' @param time_between_occasions Numeric. Length of time between sampling
#' occasions (in seconds), allowing animals to re-randomize.
#' @param study_start POSIXct. The start of the study. Defaults to the minimum
#' start time in \code{deployment_data}.
#' @param study_end POSIXct. The end of the study. Defaults to the maximum end
#' time in \code{deployment_data}.
#' @param study_area Numeric. The size of the total study area in the same units
#' as the camera viewshed area.
#' @param quiet Logical. Suppress status messages? Defaults to FALSE.
#'
#' @return A data.frame with the estimated abundance (`N`), its standard error
#' (`SE`), and confidence intervals.
#'
#' @seealso [ct_fit_ste()], [ct_fit_ise()]
#'
#' @section References:
#' Moeller, A. K. and P. M. Lukacs. 2021. spaceNtime: an R package for
#' estimating abundance
#' of unmarked animals using camera-trap photographs. Mammalian Biology.
#' \doi{10.1007/s42991-021-00181-8}
#'
#'
#' Moeller, A. K., P. M. Lukacs, and J. Horne. 2018. Three novel methods
#' to estimate abundance of unmarked animals using remote cameras. Ecosphere 9(8):
#' e02331. \doi{10.1002/ecs2.2331}
#'
#' @export
#'
#' @examples
#' data <- dplyr::tibble(
#'   cam = c(1, 1, 2, 2, 2),
#'   datetime = as.POSIXct(
#'     c(
#'       "2026-01-02 12:00:00",
#'       "2026-01-03 13:12:00",
#'       "2026-01-02 12:00:00",
#'       "2026-01-02 14:00:00",
#'       "2026-01-03 16:53:42"
#'     ),
#'     tz = "Africa/Lagos"
#'   ),
#'   count = c(1, 0, 2, 1, 2)
#' )
#' deployment_data <- dplyr::tibble(
#'   cam = c(1, 2, 2, 2),
#'   start = as.POSIXct(
#'     c(
#'       "2025-12-01 15:00:00",
#'       "2025-12-08 00:00:00",
#'       "2026-01-01 00:00:00",
#'       "2026-01-02 00:00:00"
#'     ),
#'     tz = "Africa/Lagos"
#'   ),
#'   end = as.POSIXct(
#'     c(
#'       "2026-01-05 00:00:00",
#'       "2025-12-19 03:30:00",
#'       "2026-01-01 05:00:00",
#'       "2026-01-05 00:00:00"
#'     ),
#'     tz = "Africa/Lagos"
#'   ),
#'   area = c(300, 200, 200, 450)
#')
#' ct_fit_tte(data,
#'        deployment_data,
#'        viewshed_transit_time = sqrt(mean(deployment_data$area))/(30/3600),
#'        periods_per_occasion = 24,
#'        time_between_occasions = 2 * 3600,
#'        study_area = 1e6)
#'
ct_fit_tte <- function(data, deployment_data, viewshed_transit_time, periods_per_occasion,
                   time_between_occasions, study_area, study_start = NULL,
                   study_end = NULL, quiet = FALSE) {
  rlang::check_installed(c("MASS", "msm"), reason = "to estimate abundance.")

  if (!quiet) cli::cli_h1("Time-To-Event (TTE) Estimation")

  if (!quiet) cli::cli_progress_step("Running data checks", msg_done = "")
  data <- validate_df(data)
  deployment_data <- validate_deploy(deployment_data)
  validate_df_deploy(data, deployment_data)
  if (!quiet) cli::cli_progress_done()

  if (is.null(study_start)) study_start <- min(deployment_data$start, na.rm = TRUE)
  if (is.null(study_end)) study_end <- max(deployment_data$end, na.rm = TRUE)

  if (!quiet) cli::cli_alert_info("Building sampling occasions...")
  occasion <- tte_build_occ(per_length = viewshed_transit_time,
                            nper = periods_per_occasion,
                            time_btw = time_between_occasions,
                            study_start = study_start,
                            study_end = study_end)
  occasion <- validate_occ(occasion)

  # Step 1: Automatic data transformation
  if (!quiet) cli::cli_alert_info("Building encounter history...")
  encounter_history <- tte_build_eh(data, deployment_data, occasion,
                                    viewshed_transit_time, quiet = quiet)

  # Step 2: Estimation
  if (!quiet) cli::cli_alert_info("Fitting model...")

  dat <- list(
    toevent = matrix(encounter_history$TTE,
                     nrow = length(unique(encounter_history$cam))),
    censor = encounter_history$censor
  )

  opt <- suppressWarnings(
    stats::optim(log(1 / mean(dat$toevent, na.rm = TRUE)),
      exp_logl_fn,
      x = dat,
      control = list(fnscale = -1),
      hessian = TRUE
    )
  )

  # Estimate of lambda
  estlam <- exp(opt$par)

  # estlam is average density per m2
  estN <- estlam * study_area

  # Delta method for variance
  varB <- -1 * MASS::ginv(opt$hessian)
  form <- sprintf("~ %f * exp(x1)", study_area)
  SE_N <- msm::deltamethod(
    g = stats::as.formula(form),
    mean = opt$par,
    cov = varB,
    ses = TRUE
  )

  CI <- logCI(estN, SE_N)
  out <- dplyr::tibble(
    N = estN,
    SE = SE_N
  ) %>%
    dplyr::bind_cols(CI)

  if (!quiet) cli::cli_alert_success("Estimation complete!")
  return(out)
}
