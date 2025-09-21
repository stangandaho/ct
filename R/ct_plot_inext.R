#' @title Plot diversity interploation and extrapolation
#'
#' @description
#' plot sample-size-based and coverage-based rarefaction/extrapolation curves along
#' with a bridging sample completeness curve
#'
#' @param inext_object an object as outputed by [ct_inext()]
#' @param type three types of plots:
#'
#' * `type = 1`: sample-size-based rarefaction/extrapolation curve
#' * `type = 2`: sample completeness curve
#' * `type = 3`: coverage-based rarefaction/extrapolation curve
#'
#' @param se a logical variable to display confidence interval
#' around the estimated sampling curve.
#'
#' @param facet_var create a separate plot for each value of a specified variable:
#'
#'  * `facet_var = "None"`: no separation
#'  * `facet_var = "Order.q"`: a separate plot for each diversity order
#'  * `facet_var = "Assemblage"`: a separate plot for each assemblage
#'  * `facet_var = "Both"`: a separate plot for each combination of order x assemblage
#'
#' @param color_var create curves in different colors for values of a
#' specified variable:
#'
#' * `color_var = "None"`: all curves are in the same color
#' * `color_var = "Order.q"`: use different colors for diversity orders
#' * `color_var = "Assemblage"`: use different colors for sites
#' * `color_var = "Both"`: use different colors for combinations of order x assemblage
#'
#' @param grey a logical variable to display grey and white ggplot2 theme
#'
#' @return a ggplot2 object
#'
#' @inherit ct_inext examples
#'
#' @export
ct_plot_inext <- function(inext_object,
                          type = 1,
                          se = TRUE,
                          facet_var = "None",
                          color_var = "Assemblage",
                          grey = FALSE
                          ) {

  # Check early iNEXT package
  #if (!checked_packages(c("iNEXT"))) {return(invisible(NULL))}

  p <- iNEXT::ggiNEXT(x = inext_object,
                 type = type,
                 se = se,
                 facet.var = facet_var,
                 color.var = color_var,
                 grey = grey
                 )
  if (facet_var != "None") {
    p <- p +
      ggplot2::facet_wrap(facets = facet_var, scales = "free")
  }

  return(p)
}

