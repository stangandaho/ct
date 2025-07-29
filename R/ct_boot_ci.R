#' Bootstrap confidence intervals
#'
#' Confidence interval calculation from bootstrap samples.
#' @param t0 the statistic estimated from the original sample, usually the output from [ct_overlap_estimates()]
#' @param bt a vector of bootstrap statistics, usually the output from [ct_boot_estimates()]
#'
#' @inheritParams overlap::bootCI
#'
#' @export

ct_boot_ci <- function(t0,
                       bt,
                       conf = 0.95
                       ) {

  out <- overlap::bootCI(t0 = t0, bt = bt,  conf = conf)

  return(out)

}
