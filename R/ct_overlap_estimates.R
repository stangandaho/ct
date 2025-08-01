#'Estimates of coefficient of overlapping
#' @inheritParams ct_plot_overlap
#' @inheritParams overlap::overlapEst
#' @param type the name of the estimator to use: Dhat4 is recommended if both
#' samples are larger than 50, otherwise use Dhat1. See Details.
#' The default is "all" for compatibility with older versions.
#'
#' @inherit overlap::overlapEst details
#'
#' @examples
#'
#'set.seed(42)
#' species_A <- runif(100, 1.2, 2 * pi)
#' species_B <- runif(100, 0.23, 2 * pi)
#' ct_overlap_estimates(species_A, species_B)
#' ct_overlap_estimates(species_A, species_B, type = "Dhat4")
#'
#'@export

ct_overlap_estimates <- function(A,
                                 B,
                                 kmax = 3,
                                 adjust=c(0.8, 1, 4),
                                 n_grid = 128,
                                 type=c("all", "Dhat1", "Dhat4", "Dhat5")
                                 ) {

  out <- overlap::overlapEst(A,
                             B,
                             kmax = 3,
                             adjust=c(0.8, 1, 4),
                             n.grid = n_grid,
                             type=type)

  return(out)
}
