#' Estimate abundance from Instantaneous Sampling (ISE) Data
#'
#' Estimate abundance from camera trap data using Instantaneous Sampling / point counts.
#'
#' @param data A tibble of camera trap detections. Must contain columns `cam`, `datetime`, and `count`.
#' @param deployment_data A tibble of camera deployments. Must contain columns `cam`, `start`, `end`, and `area`.
#' @param sampling_frequency Numeric. The number of seconds between the start of each sampling occasion.
#' @param sampling_length Numeric. The number of seconds to sample at each sampling occasion.
#' @param study_start POSIXct. The start of the study. Defaults to the minimum start time in `deployment_data`.
#' @param study_end POSIXct. The end of the study. Defaults to the maximum end time in `deployment_data`.
#' @param study_area Numeric. The size of the total study area in the same units as the camera viewshed area.
#' @param quiet Logical. Suppress status messages? Defaults to FALSE.
#'
#' @return A data.frame with the estimated abundance (\code{N}), its standard error (\code{SE}), and confidence intervals.
#' @inheritSection ct_fit_tte References
#'
#' @seealso [ct_fit_tte()], [ct_fit_ste()]
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
#' )
#' ct_fit_ise(data, deployment_data,
#'        sampling_frequency = 3600,
#'        sampling_length = 10,
#'        study_area = 1e6)
#'
ct_fit_ise <- function(data, deployment_data, sampling_frequency, sampling_length, study_area, study_start = NULL, study_end = NULL, quiet = FALSE) {
  rlang::check_installed(c("MASS", "msm"), reason = "to estimate abundance.")

  if (!quiet) cli::cli_h1("Instantaneous Sampling (ISE) Estimation")

  if (!quiet) cli::cli_progress_step("Running data checks", msg_done = "")
  data <- validate_df(data)
  deployment_data <- validate_deploy(deployment_data)
  validate_df_deploy(data, deployment_data)
  if (!quiet) cli::cli_progress_done()

  if (is.null(study_start)) study_start <- min(deployment_data$start, na.rm = TRUE)
  if (is.null(study_end)) study_end <- max(deployment_data$end, na.rm = TRUE)

  if (!quiet) cli::cli_alert_info("Building sampling occasions...")
  occasion <- build_occ(samp_freq = sampling_frequency, samp_length = sampling_length, study_start = study_start, study_end = study_end)
  occasion <- validate_occ(occasion)

  # Step 1: Automatic data transformation
  if (!quiet) cli::cli_alert_info("Building encounter history...")
  encounter_history <- ise_build_eh(data, deployment_data, occasion, quiet = quiet)

  # Step 2: Estimation
  if (!quiet) cli::cli_alert_info("Calculating estimates...")

  # First, get rid of occasions where area = 0
  ise_eh2 <- encounter_history %>%
    dplyr::filter(area != 0) %>%
    # Take first picture in occasion
    dplyr::group_by(occ, cam) %>%
    dplyr::summarize(
      count = dplyr::first(count),
      area = dplyr::first(area),
      .groups = "drop"
    )

  Jai_ni <- ise_eh2 %>%
    dplyr::group_by(cam) %>%
    dplyr::summarise(
      Jai = sum(area),
      ni = sum(count),
      .groups = "drop"
    )

  n_L <- Jai_ni %>%
    dplyr::summarise(
      n = sum(ni),
      L = sum(Jai),
      .groups = "drop"
    )

  M <- length(unique(Jai_ni$cam))
  L <- n_L$L
  n <- n_L$n
  Jai <- Jai_ni$Jai
  ni <- Jai_ni$ni

  varD <- M / L^2 / (M - 1) * sum(Jai^2 * (ni / Jai - n / L)^2)
  form <- sprintf("~ %f * x1", study_area)

  ise_est <- ise_eh2 %>%
    dplyr::mutate(dens_ij = count / area) %>%
    dplyr::summarise(D = mean(dens_ij), .groups = "drop") %>%
    dplyr::mutate(
      N = D * study_area,
      varD = varD,
      SE = msm::deltamethod(stats::as.formula(form), D, varD)
    )

  CI <- logCI(ise_est$N, ise_est$SE)

  out <- ise_est %>%
    dplyr::select(N, SE) %>%
    dplyr::bind_cols(CI)

  cli::cli_end()
  if (!quiet) cli::cli_alert_success("Estimation complete!")


  return(out)
}


#' Build ISE encounter history
#'
#' @param df df object
#' @param deploy deploy object
#' @param occ occ object
#'
#' @return a data frame with encounter history for instantaneous sampling
#' @noRd
#'
ise_build_eh <- function(df, deploy, occ, ...){

  # Run all my data checks here
  df <- validate_df(df)
  deploy <- validate_deploy(deploy)
  occ <- validate_occ(occ)
  validate_df_deploy(df, deploy)

  # Forcing a data subset so I can validate df and deploy together.
  # Subset is not technically necessary because everything hinges on occ later.
  d1 <- min(occ$start)
  d2 <- max(occ$end)
  df_s <- study_subset(df, "datetime", NULL, d1, d2)
  deploy_s <- study_subset(deploy, "start", "end", d1, d2)

  # Then validate df and deploy together (should really do after subset)
  validate_df_deploy(df_s, deploy_s) # This one is weird because it doesn't return anything if all good...

  # Build effort for each cam at each occasion
  eff <- effort_fn(deploy_s, occ)

  ### All lines until here are same as in STE... think about new fn.
  # Build ISE EH
  ise <- eff %>%
    dplyr::left_join(., df_s, by = "cam") %>%
    dplyr::filter(datetime %within% int) %>%
    dplyr::select(occ, cam, count) %>%
    dplyr::left_join(eff, ., by = c("occ", "cam")) %>%
    dplyr::select(-int) %>%
    # as long as area >0, deploy said the camera was on. So we're going to fill in count = 0
    dplyr::mutate(count = replace(count, is.na(count) & area > 0, 0))

  return(ise)
}

