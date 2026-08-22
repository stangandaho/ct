#' Estimate overlap coefficients for multiple species
#'
#' This function calculates pairwise overlap coefficients for activity patterns of multiple species
#' using their time data, and optionally bootstrap confidence intervals for every pair.
#'
#' @param data A `data.frame` or `tibble` containing species and time information.
#' @param species_column A column in `data` indicating species names.
#' @param time_column A column in `data` containing time data (either as radians or in a time format to be converted).
#' @param convert_time Logical. If `TRUE`, the time data will be converted to radians using the `ct_to_radian` function.
#' @param format A character string specifying the time format (e.g., `"%H:%M:%S"`) if [ct_to_radian()] is `TRUE`. Defaults to `"%H:%M:%S"`.
#' @param fill_na Optional. A numeric value used to fill `NA` values in the overlap coefficient matrix. Defaults to `NULL` (does not fill `NA` values).
#' @param n_boot Integer. Number of bootstrap samples used to derive a confidence
#'   interval for each species pair. When `n_boot <= 1` (the default, `0`) no
#'   bootstrap is run and a single coefficient matrix is returned, preserving the
#'   original behaviour. When `n_boot > 1`, a list of matrices is returned (see
#'   Value).
#' @param conf Numeric scalar in `(0, 1)`. Confidence level for the bootstrap
#'   interval. Defaults to `0.95`.
#' @param ci_method Character. How to choose the confidence-interval type returned
#'   by [overlap::bootCI()] for each pair. `"auto"` (default) selects, per pair,
#'   between the two interval types appropriate for the uncorrected estimate
#'   reported in the matrix: `"norm0"` when the bootstrap estimates are
#'   approximately normal (Shapiro-Wilk `p >= 0.05`) and the skew-robust
#'   `"basic0"` otherwise. Alternatively, force a single type for all pairs with
#'   one of `"norm"`, `"norm0"`, `"basic"`, `"basic0"` or `"perc"`.
#' @param cores Integer. Number of cores passed to [ct_bootstrap()]. Defaults to `1`.
#' @param ... Additional arguments passed to [overlap::overlapEst()]` for overlap estimation.
#'
#' @details
#' The function calculates pairwise overlap coefficients for all species in the dataset.
#' The overlap coefficients are estimated using the `overlap` package:
#' - For species pairs with sample sizes of at least 50 observations each, the `Dhat4` estimator is used.
#' - For smaller sample sizes, the `Dhat1` estimator is used (Schmid & Schmidt, 2006).
#'
#' When `n_boot > 1`, each pair is bootstrapped with the same estimator used for
#' its point estimate, and a confidence interval is obtained through [ct_boot_ci()].
#' Because the coefficient stored in
#' the matrix is the uncorrected estimate, the `"auto"` selection restricts
#' itself to the interval types, namely `"norm0"` and
#' `"basic0"`; the choice between them is made per pair from a normality check on
#' the bootstrap estimates. Pairs for which the bootstrap or interval cannot be
#' computed receive `NA`.
#'
#' @return
#' If `n_boot <= 1`, a square numeric matrix of pairwise overlap coefficients,
#' where rows and columns represent species (the original return value).
#'
#' If `n_boot > 1`, a named list of matrices:
#' \describe{
#'   \item{`estimate`}{the square numeric matrix of overlap coefficients;}
#'   \item{`ci`}{a character matrix whose cells give the confidence interval as
#'     `"[lower ; upper]"`;}
#'   \item{`ci_method`}{a character matrix recording which [ct_boot_ci()]
#'     interval type was used for each cell if ci_method is `"auto"`;}
#' }
#'
#' @examples
#' # Example dataset
#' data <- data.frame(
#'   species = c("SpeciesA", "SpeciesA", "SpeciesB", "SpeciesB"),
#'   time = c("10:30:00", "11:45:00", "22:15:00", "23:30:00")
#' )
#'
#' # Calculate overlap coefficients with time conversion
#' overlap_matrix <- ct_overlap_matrix(
#'   data = data,
#'   species_column = species,
#'   time_column = time,
#'   convert_time = TRUE,
#'   format = "%H:%M:%S"
#' )
#'
#' \donttest{
#' # With bootstrap confidence intervals (returns a list of matrices)
#' overlap_ci <- ct_overlap_matrix(
#'   data = data,
#'   species_column = species,
#'   time_column = time,
#'   convert_time = TRUE,
#'   n_boot = 99,
#'   conf = 0.95
#' )
#' overlap_ci$estimate
#' overlap_ci$ci
#' overlap_ci$ci_method
#' }
#'
#'@references
#'Schmid & Schmidt (2006) Nonparametric estimation of the coefficient of
#'overlapping - theory and empirical application, Computational Statistics and
#'Data Analysis, 50:1583-1596.
#'
#' @seealso [overlap::overlapEst()] for overlap coefficient estimation;
#'   [ct_bootstrap()] and [ct_boot_ci()] for the bootstrap machinery.
#'
#' @export
#'
#'
ct_overlap_matrix <- function(data,
                              species_column,
                              time_column,
                              convert_time = FALSE,
                              format = "%H:%M:%S",
                              fill_na = NULL,
                              n_boot = 0,
                              conf = 0.95,
                              ci_method = c("auto", "norm", "norm0", "basic", "basic0", "perc"),
                              cores = 1,
                              ...){

  ci_method <- rlang::arg_match(ci_method, c("auto", "norm", "norm0", "basic", "basic0", "perc"))#match.arg(ci_method)

  sp_col_ <- paste0(dplyr::ensym(species_column))
  tm_col_ <- paste0(dplyr::ensym(time_column))

  if (!sp_col_%in% colnames(data) ) {
    cli::cli_abort(sprintf("%s not found in the data", sp_col_))
  }
  if (!tm_col_%in% colnames(data) ) {
    cli::cli_abort(sprintf("%s not found in the data", tm_col_))
  }

  if (convert_time) {
    data[[tm_col_]] <- ct_to_radian(times = data[[tm_col_]],
                                          format = format)
  }

  data <- data %>% dplyr::select(dplyr::all_of(c(sp_col_, tm_col_)))

  sp_tm <- list() # list to store species and time
  for(sp in unique(data[[sp_col_]])){

    each_sp <- data %>%
      dplyr::filter(!!dplyr::sym(sp_col_) == sp)

    sp_tm[[sp]] <- each_sp %>% dplyr::pull(tm_col_)

  }
  # Match length of items in the sp_tm list
  lens <- sapply(sp_tm, length)

  data <- lapply(sp_tm,
                    FUN = function(x){
                      c(x, rep(NA, max(lens) - length(x)))}
                 ) %>%
    dplyr::bind_cols()

  ## Create matrix to store coefficient
  coef_matrix <- matrix(data = rep(0, ncol(data)^2),
                        ncol = ncol(data), nrow = ncol(data))
  colnames(coef_matrix) <- colnames(data)
  rownames(coef_matrix) <- colnames(data)

  # select pair of column
  for (first_sp in colnames(data)) {
    for (second_sp in colnames(data)){

      if (first_sp != second_sp) {
        spA <- data[[first_sp]][!is.na(data[[first_sp]])]
        spB <- data[[second_sp]][!is.na(data[[second_sp]])]

        if ((length(spA) >= 50 ) && (length(spB) >= 50)) {
          overlap_coef <- overlap::overlapEst(A = spA,
                                              B = spB,
                                              type = "Dhat4",
                                              ...)
        }else{
          overlap_coef <- overlap::overlapEst(A = spA,
                                              B = spB,
                                              type = "Dhat1",
                                              ...)
        }

        coef_matrix[second_sp, first_sp] <- round(overlap_coef, 3)

      }
    }
  }

  if (!is.null(fill_na)) {
    if(! class(fill_na) %in% c("numeric", "double")){ cli::cli_abort("'fill_na' must be a numeric")}
    for (c_ in 1:ncol(coef_matrix)) {
      for (r_ in 1:nrow(coef_matrix)) {
        if (is.na(coef_matrix[c_, r_])) {
          coef_matrix[c_, r_] <- fill_na
        }
      }
    }
  }

  # Without bootstrap: preserve the original single-matrix return
  if (is.null(n_boot) || n_boot <= 1) {
    return(coef_matrix)
  }

  ## Bootstrap confidence intervals
  species <- colnames(data)
  ci_matrix <- matrix("", nrow = length(species), ncol = length(species),
                      dimnames = list(species, species))
  method_matrix <- ci_matrix

  # unordered pairs only; overlap coefficients are symmetric, so mirror the cells
  for (i in seq_along(species)) {
    for (j in seq_len(i - 1)) {
      spA <- data[[species[i]]][!is.na(data[[species[i]]])]
      spB <- data[[species[j]]][!is.na(data[[species[j]]])]
      type_ij <- if (length(spA) >= 50 && length(spB) >= 50) "Dhat4" else "Dhat1"
      t0 <- coef_matrix[species[j], species[i]]

      res <- tryCatch({
        bt <- ct_bootstrap(spA, spB, nb = n_boot, type = type_ij, cores = cores)
        .ct_overlap_ci(t0 = t0, bt = bt, conf = conf, ci_method = ci_method)
      }, error = function(e) list(method = NA_character_,
                                  lower = NA_real_, upper = NA_real_))

      cell_ci <- if (is.na(res$lower) || is.na(res$upper)) {
        NA_character_
      } else {
        sprintf("[%.3f ; %.3f]", res$lower, res$upper)
      }

      ci_matrix[species[j], species[i]] <- cell_ci
      ci_matrix[species[i], species[j]] <- cell_ci
      method_matrix[species[j], species[i]] <- res$method
      method_matrix[species[i], species[j]] <- res$method
    }
  }

  if (ci_method == "auto") {
    mt <- list(estimate = coef_matrix,
               ci = ci_matrix,
               ci_method = method_matrix)
  }else{
    mt <- list(estimate = coef_matrix, ci = ci_matrix)
  }

  return(mt)
}


# Internal: choose and extract a bootstrap confidence interval for one pair.
# The matrix reports the uncorrected estimate t0, so "auto" restricts itself to
# the interval types bootCI recommends for t0 ("norm0", "basic0") and picks
# between them from a normality check on the bootstrap estimates.
.ct_overlap_ci <- function(t0, bt, conf, ci_method = "auto") {
  bt <- bt[is.finite(bt)]
  if (length(bt) < 2L) {
    return(list(method = NA_character_, lower = NA_real_, upper = NA_real_))
  }

  ci <- ct_boot_ci(t0 = t0, bt = bt, conf = conf)

  if (ci_method == "auto") {
    method <- "basic0"
    if (length(bt) >= 3L && length(bt) <= 5000L && stats::sd(bt) > 0) {
      p <- tryCatch(stats::shapiro.test(bt)$p.value, error = function(e) NA_real_)
      if (!is.na(p) && p >= 0.05) method <- "norm0"
    }
  } else {
    method <- ci_method
  }

  if (!method %in% rownames(ci)) method <- rownames(ci)[1]

  lo <- ci[method, 1]
  up <- ci[method, 2]
  # an overlap coefficient is bounded in [0, 1]
  lo <- max(0, min(1, lo))
  up <- max(0, min(1, up))

  list(method = method, lower = lo, upper = up)
}
