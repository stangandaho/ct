#' Generate bootstrap estimates of overlap
#'
#' @description
#' The function takes two sets of times of observations and calculates bootstrap
#' estimates of the chosen estimator of overlap. Alternatively, bootstrap
#' estimates can be calculated in a 2-stage process: (1) create a matrix of
#' bootstrap samples for each data set, using [ct_resample()]; (2) pass these
#' matrices to [ct_boot_estimates()] to obtain the bootstrap estimates.
#'
#' A vector of bootstrap estimates can then be used to produce confidence intervals
#' with [ct_boot_ci()].
#'
#' @return
#' The function [ct_bootstrap()] returns a vector of bootstrap estimates.
#' If estimation fails for a bootstrap sample, the corresponding value will be NA.
#'
#' The function [ct_resample()] returns a numeric matrix with each column corresponding
#' to a bootstrap sample. Times are in `radians`. It may return a matrix of NAs if
#' `smooth = TRUE` and bandwidth estimation fails.
#'
#' The Function [ct_boot_estimates()] with `type = "all"` returns a numeric matrix
#' with three columns, one for each estimator of overlap, otherwise a vector of
#' bootstrap estimates.
#'
#' @author Mike Meredith, Martin Ridout.
#'
#' @references Ridout & Linkie (2009) Estimating overlap of daily activity patterns
#' from camera trap data. Journal of Agricultural, Biological, and Environmental
#' Statistics 14:322-337
#'
#' @seealso [ct_boot_ci()]
#'
#' @rdname bootstrap
#' @inheritParams ct_plot_overlap
#' @param type the name of the estimator to use, or "all" to produce all three
#' estimates. See [ct_overlap_estimates()] for recommendations on which to use.
#' @inheritParams overlap::bootstrap
#' @examples
#'
#' # Generate random data for two species
#' set.seed(42)
#' species_A <- runif(100, 1.2, 2 * pi)
#' species_B <- runif(100, 0.23, 2 * pi)
#'
#' est <- ct_overlap_estimates(species_A, species_B, type="Dhat4")
#'
#' boots <- ct_bootstrap(species_A, species_B, 100, type="Dhat4", cores=1)
#' mean(boots)
#' hist(boots)
#' ct_boot_ci(est, boots)
#'
#' # alternatively:
#' species_A_gen <- ct_resample(species_A, 100)
#' species_B_gen <- ct_resample(species_B, 100)
#' boots <- ct_boot_estimates(species_A_gen, species_B_gen, type="Dhat4", cores=1)
#' mean(boots)
#'
#' @export
ct_bootstrap <- function(A,
                         B,
                         nb,
                         smooth = TRUE,
                         kmax = 3,
                         adjust = NA,
                         n_grid = 128,
                         type = c("Dhat1", "Dhat4", "Dhat5"),
                         cores = 1) {

  out <- overlap::bootstrap(A = A,
                            B = B,
                            nb = nb,
                            smooth = smooth,
                            kmax = kmax,
                            adjust = adjust,
                            n.grid = n_grid,
                            type = type,
                            cores = cores)

  return(out)
}

##################


#' @rdname bootstrap
#' @inheritParams overlap::resample
#' @inheritParams ct_plot_overlap
#' @export
ct_resample <- function(x,
                        nb,
                        smooth = TRUE,
                        kmax = 3,
                        adjust = 1,
                        n_grid = 512) {

  out <- overlap::resample(x = x,
                           nb = nb,
                           smooth = smooth,
                           kmax = kmax,
                           adjust = adjust,
                           n.grid = n_grid
  )

  return(out)
}

#######################


#' @rdname bootstrap
#' @inheritParams ct_plot_overlap
#' @param type the name of the estimator to use, or "all" to produce all three
#' estimates. See [ct_overlap_estimates()] for recommendations on which to use.
#' @inheritParams overlap::bootEst
#' @export
ct_boot_estimates <- function(Amat,
                              Bmat,
                              kmax = 3,
                              adjust=c(0.8, 1, 4),
                              n_grid = 128,
                              type=c("all", "Dhat1", "Dhat4", "Dhat5"),
                              cores=1) {

  out <- overlap::bootEst(Amat = Amat,
                          Bmat = Bmat,
                          kmax = kmax,
                          adjust= adjust,
                          n.grid = n_grid,
                          type=type,
                          cores=cores)

  return(out)
}
