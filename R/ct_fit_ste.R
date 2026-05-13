#' Estimate abundance from Space-To-Event (STE) Data
#'
#' Estimate abundance from camera trap data using the Space-To-Event (STE) model.
#'
#' @param data A tibble of camera trap detections. Must contain columns \code{cam}, \code{datetime}, and \code{count}.
#' @param deployment_data A tibble of camera deployments. Must contain columns \code{cam}, \code{start}, \code{end}, and \code{area}.
#' @param sampling_frequency Numeric. The number of seconds between the start of each sampling occasion.
#' @param sampling_length Numeric. The number of seconds to sample at each sampling occasion.
#' @param study_start POSIXct. The start of the study. Defaults to the minimum start time in \code{deployment_data}.
#' @param study_end POSIXct. The end of the study. Defaults to the maximum end time in \code{deployment_data}.
#' @param study_area Numeric. The size of the total study area in the same units as the camera viewshed area.
#' @param quiet Logical. Suppress status messages? Defaults to FALSE.
#'
#' @return A data.frame with the estimated abundance (\code{N}), its standard error (\code{SE}), and confidence intervals.
#'
#' @seealso [ct_fit_ise()], [ct_fit_tte()]
#'
#' @inheritSection ct_fit_tte References
#'
#' @export
#'
#' @examples
#' data <- dplyr::tibble(
#'   cam = c(1,1,2,2,2),
#'   datetime = as.POSIXct(c("2026-01-02 12:00:00",
#'                         "2026-01-03 13:12:00",
#'                         "2026-01-02 12:00:00",
#'                         "2026-01-02 14:00:00",
#'                         "2026-01-03 16:53:42"),
#'                       tz = "Africa/Lagos"),
#'   count = c(1, 0, 2, 1, 2)
#' )
#' deployment_data <- dplyr::tibble(
#'   cam = c(1, 2, 2, 2),
#'   start = as.POSIXct(c("2025-12-01 15:00:00",
#'                        "2025-12-08 00:00:00",
#'                        "2026-01-01 00:00:00",
#'                        "2026-01-02 00:00:00"),
#'                      tz = "Africa/Lagos"),
#'   end = as.POSIXct(c("2026-01-05 00:00:00",
#'                      "2025-12-19 03:30:00",
#'                      "2026-01-01 05:00:00",
#'                      "2026-01-05 00:00:00"),
#'                    tz = "Africa/Lagos"),
#'   area = c(300, 200, 200, 450)
#' )
#' ct_fit_ste(data,
#'        deployment_data,
#'        sampling_frequency = 3600,
#'        sampling_length = 10,
#'        study_area = 1e6)

ct_fit_ste <- function(data, deployment_data, sampling_frequency, sampling_length, study_area, study_start = NULL, study_end = NULL, quiet = FALSE) {
  rlang::check_installed(c("MASS", "msm"), reason = "to estimate abundance.")

  if (!quiet) cli::cli_h1("Space-To-Event (STE) Estimation")

  if (!quiet) cli::cli_progress_step("Running data checks", msg_done = "")
  data <- validate_df(data)
  deployment_data <- validate_deploy(deployment_data)
  validate_df_deploy(data, deployment_data)
  if (!quiet) cli::cli_progress_done()

  if (is.null(study_start)) study_start <- min(deployment_data$start, na.rm = TRUE)
  if (is.null(study_end)) study_end <- max(deployment_data$end, na.rm = TRUE)

  if (!quiet) cli::cli_alert_info("Building sampling occasions...")
  occasion <- build_occ(samp_freq = sampling_frequency,
                        samp_length = sampling_length, study_start = study_start,
                        study_end = study_end)
  occasion <- validate_occ(occasion)

  # Step 1: Automatic data transformation
  if (!quiet) cli::cli_alert_info("Building encounter history...")
  encounter_history <- ste_build_eh(data, deployment_data, occasion, quiet = quiet)

  # Step 2: Estimation
  if (!quiet) cli::cli_alert_info("Fitting model...")

  dat <- list(
    toevent = matrix(encounter_history$STE, nrow = 1),
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
  if (!quiet) cli::cli_end()

  return(out)
}
