#' Interpolation and extrapolation of Hill number
#'
#' @description
#' Computes incidence-based species diversity estimates (Hill numbers) from camera trap data.
#' This is a wrapper around iNEXT package (Chao et al., 2014; Hsieh, Ma, & Chao, 2016).
#'
#' @param data A data frame, preferably the output of [ct_camera_day()].
#'
#' @inheritParams ct_to_community
#'
#' @param strata_column Optional column name for a grouping variable (e.g. habitat, treatment).
#' If provided, estimates are computed separately for each stratum.
#'
#' @param diversity_order Numeric specifying the order of diversity (q) for Hill numbers.
#' Common values:
#' * `0` = species richness,
#' * `1` = Shannon diversity (exponential of Shannon entropy),
#' * `2` = Simpson diversity (inverse of Simpson index).
#' Defaults to `0`.
#'
#' @param sample_size Optional numeric vector specifying sample sizes for interpolation/extrapolation.
#'
#' @param endpoint Optional numeric specifying the maximum sample size for extrapolation.
#' If NULL, endpoint is the double of the current sample size
#'
#' @param knots Integer specifying the number of equally spaced knots for rarefaction/extrapolation.
#' Default is `40`.
#'
#' @param n_bootstrap Number of bootstrap replications for estimating confidence intervals.
#' Default is `100`.
#'
#' @details
#' This function converts the input data into an **incidence-frequency vector**.
#' The first element of the vector is the number of sampling units, followed by species frequencies.
#' If `strata_column` is provided, the conversion is done separately for each stratum.
#'
#' @return
#' A list containing:
#'
#' - `DataInfo`: Summary statistics of input data.
#' - `iNextEst`: Rarefaction/extrapolation results for specified diversity order.
#' - `AsyEst`: Asymptotic diversity estimates.
#'
#' @examples
#' if (requireNamespace("iNEXT", quietly = TRUE)) {
#' ## Import example data
#' camdata1 <- read.csv(ct:::table_files()[1]) %>%
#'   dplyr::mutate(site = "pene") %>%
#'   # remove consecutive entry of the same species at the same location within 60s
#'   ct_independence(species_column = species,
#'                   site_column = camera,
#'                   datetime = datetimes,
#'                   threshold = 60, format = "%Y-%m-%d %H:%M:%S"
#'                   )
#' head(camdata1)
#'
#' # Prepare sampling data (camera-day)
#' camday <- ct_camera_day(
#'   data = camdata1,
#'   deployment_column = camera,
#'   datetime_column = datetime,
#'   species_column = species,
#'   size_column = number
#' )
#'
#' # RAREFACTION/EXTRAPOLATION
#' int_ext <- ct_inext(data = camday,
#'                     diversity_order = c(0, 1, 2),
#'                     species_column = species,
#'                     site_column = sampling_unit,
#'                     size_column = number,
#'                     n_bootstrap = 50)
#' int_ext
#'
#' # plot with curves colored by order
#' ct_plot_inext(int_ext, type = 1, color_var = "Order.q")
#'
#' # plot with curves faceted by order
#' ct_plot_inext(int_ext, type = 1, facet_var = "Order.q")
#'  }
#' @seealso [ct_camera_day()] for preparing sampling data (camera-day).
#'
#' @references
#' Chao, A., Gotelli, N. J., Hsieh, T. C., Sander, E. L., Ma, K. H., Colwell,
#' R. K., & Ellison, A. M. (2014). Rarefaction and extrapolation with
#' Hill numbers: a framework for sampling and estimation in species diversity
#' studies. Ecological Monographs, 84, 45–67.
#' \doi{https://doi.org/https://doi.org/10.1890/13-0133.1}
#'
#' Hsieh, T. C., Ma, K. H., & Chao, A. (2016). iNEXT: an R package for
#' rarefaction and extrapolation of species diversity (Hill numbers).
#'  Methods in Ecology and Evolution, 7(12), 1451–1456.
#'  \doi{https://doi.org/10.1111/2041-210X.12613}
#'
#' @export
ct_inext <- function(data,
                     species_column,
                     site_column,
                     size_column,
                     strata_column = NULL,
                     diversity_order = 0,
                     sample_size = NULL,
                     endpoint = NULL,
                     knots = 40,
                     n_bootstrap = 100) {

  # Check early iNEXT package
  if (!checked_packages(c("iNEXT"))) {return(invisible(NULL))}

  # Convert site_column and species_column to symbols, handling both quoted and unquoted input

  site_col <- data %>% dplyr::select({{site_column}}) %>% colnames()
  species_col <- data %>% dplyr::select({{species_column}}) %>% colnames()
  size_col <- data %>% dplyr::select({{size_column}}) %>% colnames()
  strat_col <- data %>% dplyr::select({{strata_column}}) %>% colnames()


  ifrequencer <- function(x){
    incidence_matrix <- ct_to_community(data = x,
                                        size_column = size_col,
                                        species_column = species_col,
                                        site_column = site_col,
                                        values_fill = 0
                                        )

    incidence_matrix <- incidence_matrix[, -1] %>% as.matrix()
    incidence_matrix[incidence_matrix > 0] <- 1
    ifreq <- c(nrow(incidence_matrix), as.numeric(colSums(incidence_matrix)))
    return(ifreq)
  }

  if (length(strat_col) != 0) {
    strata <- data %>% dplyr::select(strat_col) %>% dplyr::pull(1) %>% unique()
    incidence_freq <- lapply(strata, function(x){
      xdata <- data %>% dplyr::filter(!!dplyr::ensym(strat_col) == x)
      ifrequencer(xdata)
    })
    names(incidence_freq) <- strata
  }else{
    incidence_freq <- ifrequencer(data)
  }

  re <- iNEXT::iNEXT(x = incidence_freq,
                     q = diversity_order,
                     datatype = "incidence_freq",
                     size = sample_size,
                     endpoint = endpoint,
                     knots = knots,
                     se = TRUE,
                     conf = 0.95,
                     nboot = n_bootstrap)

  return(re)
}

