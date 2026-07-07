#' Bootstrap confidence intervals
#'
#' Confidence interval calculation from bootstrap samples.
#' @param t0 the statistic estimated from the original sample, usually the output from [ct_overlap_estimates()]
#' @param bt a vector of bootstrap statistics, usually the output from [ct_boot_estimates()]
#'
#' @inheritParams overlap::bootCI
#'
#' @return A numeric matrix of confidence limits, as returned by
#'   [overlap::bootCI()]. Each row corresponds to one of the estimators supplied
#'   in `t0` and the two columns give the lower and upper bounds of the
#'   confidence interval at the requested level (`conf`).
#'
#' @export

ct_boot_ci <- function(t0,
                       bt,
                       conf = 0.95
                       ) {

  out <- overlap::bootCI(t0 = t0, bt = bt,  conf = conf)

  return(out)

}
