#' @inherit activity::fitact title
#'
#' @inherit activity::fitact description
#'
#' @param time_of_day A numeric vector of radian time-of-day data
#' @param weights A numeric vector of weights for each dat value.
#' @param n_bootstrap Number of bootstrap iterations to perform. Ignored if sample=="none"
#' @param bandwidth Numeric value for kernel bandwidth. If NULL, calculated internally.
#' @param adjustment Numeric bandwidth adjustment multiplier.
#'
#' @inheritParams activity::fitact
#'
#' @inherit activity::fitact details
#'
#' @return A list
#'
#' @examples
#' data("ctdp")
#' observations <- ctdp$data$observations %>%
#'   dplyr::filter(scientificName == "Vulpes vulpes") %>%
#'   # Add time of day
#'   ct_to_radian(times = timestamp)
#'
#'
#' fit_act <- ct_fit_activity(time_of_day = observations$time_radian,
#'                            sample = "model", n_bootstrap = 100)
#'
#' # Access activity level estimation
#' fit_act$activity
#'
#' @export
ct_fit_activity <- function(time_of_day,
                            weights = NULL,
                            n_bootstrap = 1000,
                            bandwidth  = NULL,
                            adjustment = 1,
                            sample = c("none", "data", "model"),
                            bounds = NULL,
                            show = TRUE
                            ) {
  sample <- match_arg(sample, choices = c("none", "data", "model"))

  fit_act <- activity::fitact(dat = time_of_day,
                              wt = weights,
                              reps = n_bootstrap,
                              bw = bandwidth,
                              adj = adjustment,
                              sample = sample,
                              bounds = bounds,
                              show = show)

  return(list(
    data = dplyr::tibble(time_of_day = fit_act@data),
    weight = fit_act@wt,
    bandwidth = fit_act@bw,
    adjustement = fit_act@adj,
    pdf = dplyr::as_tibble(fit_act@pdf),
    activity = {
      act <- t(fit_act@act) %>%
        as.data.frame() %>% dplyr::as_tibble()
      if (any(grepl('lcl', names(act)))) {
        act <- act %>% dplyr::rename(lower_ci = 3, upper_ci = 4)
      }
    }
  ))
}

