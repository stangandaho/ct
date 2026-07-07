#' Choose a staying-time distribution for REST by WAIC
#'
#' @description
#' Fits the REST staying-time survival sub-model under one or more candidate
#' distributions (and, optionally, covariate combinations) and ranks them by
#' WAIC, with a Bayesian p-value as a goodness-of-fit check. Use the winning
#' `stay_distribution` in [ct_fit_rest()].
#'
#' @param stay_data Staying-time data from [ct_rest_stay()].
#' @param species Single species name to analyse.
#' @param stay_formula Staying-time formula, e.g. `Stay ~ 1` or `Stay ~ 1 + habitat`.
#' @param stay_distribution One or more of `"lognormal"`, `"gamma"`, `"weibull"`,
#'   `"exponential"` to compare.
#' @param stay_random_effect Optional column in `stay_data` for a random effect
#'   on staying time. Tidy-selected (string, bare name, or position).
#' @param compare_models If `TRUE`, also compare every covariate combination of
#'   `stay_formula`.
#' @param iterations,burnin,thin,chains,cores MCMC settings.
#' @param quiet If `TRUE`, suppress progress messages.
#'
#' @return An object of class `ct_rest_stay` with a `waic` ranking tibble, a
#'   `summary` of the mean staying time for the best model, and its `samples`.
#'
#' @seealso [ct_fit_rest()]
#' @export
#' @importFrom rlang .data
#' @examples
#' data(rest_detection)
#' data(rest_station)
#'
#' stay <- ct_rest_stay(rest_detection, rest_station)
#'
#' \dontrun{
#' # Compare candidate staying-time distributions by WAIC (requires 'nimble')
#' ct_rest_select_stay(
#'   stay, species = "Red duiker",
#'   stay_distribution = c("lognormal", "gamma", "weibull"),
#'   iterations = 3000, burnin = 1000, chains = 2, cores = 2
#' )
#' }
ct_rest_select_stay <- function(stay_data, species,
                                stay_formula = Stay ~ 1,
                                stay_distribution = c("lognormal", "gamma", "weibull", "exponential"),
                                stay_random_effect = NULL,
                                compare_models = FALSE,
                                iterations = 5000, burnin = 1000, thin = 4,
                                chains = 3, cores = 3, quiet = FALSE) {

  rlang::check_installed(c("nimble", "MCMCvis", "coda", "parallel"),
                         reason = "to select a staying-time distribution.")
  # Unlike ct_fit_rest(), several distributions may be compared at once.
  stay_distribution <- unique(stay_distribution)
  invalid <- setdiff(stay_distribution, c("lognormal", "gamma", "weibull", "exponential"))
  if (length(invalid)) {
    cli::cli_abort("Unknown {.arg stay_distribution}: {.val {invalid}}.")
  }

  # Resolve the random-effect column (string, bare name, or position); NULL
  # passes through unchanged.
  stay_random_effect <- rest_pull_name(stay_data, rlang::enquo(stay_random_effect),
                                       "stay_random_effect")

  if (!quiet) cli::cli_h1("Staying-time model selection")

  prep <- rest_stay_only(stay_data, species, stay_random_effect)
  formulas <- if (compare_models) rest_all_stay_formulas(stay_formula) else list(stay_formula)

  # Fit every (distribution x formula) candidate.
  grid <- expand.grid(family = stay_distribution, fi = seq_along(formulas),
                      stringsAsFactors = FALSE)
  if (!quiet) cli::cli_progress_step("Fitting {nrow(grid)} candidate model(s)", spinner = TRUE)
  fits <- Map(function(family, fi) {
    rest_fit_stay(prep, formulas[[fi]], family, stay_random_effect,
                  iterations, burnin, thin, chains, cores)
  }, grid$family, grid$fi)
  if (!quiet) cli::cli_progress_done()

  waic_tbl <- dplyr::tibble(
    model = vapply(grid$fi, function(i) paste(deparse(formulas[[i]]), collapse = " "), character(1)),
    family = grid$family,
    random_effect = stay_random_effect %||% "none",
    WAIC = vapply(fits, `[[`, numeric(1), "waic"),
    bayes_p = vapply(fits, `[[`, numeric(1), "bayes_p")
  ) %>% dplyr::arrange(.data$WAIC)

  best <- fits[[which.min(vapply(fits, `[[`, numeric(1), "waic"))]]
  summary <- MCMCvis::MCMCsummary(best$samples, params = "mean_stay", round = 2) %>%
    as.data.frame() %>%
    tibble::rownames_to_column("Variable") %>%
    tibble::as_tibble() %>%
    dplyr::rename(lower = `2.5%`, median = `50%`, upper = `97.5%`)

  if (!quiet) cli::cli_alert_success("Best: {.val {waic_tbl$family[1]}} {waic_tbl$model[1]}")

  structure(list(waic = waic_tbl, summary = summary, samples = best$samples),
            class = "ct_rest_stay")
}


# --- internals --------------------------------------------------------------

#' Build staying-time vectors (no station/effort needed)
#' @keywords internal
#' @noRd
#' @importFrom rlang .data
rest_stay_only <- function(stay_data, species, stay_random_effect) {
  d <- stay_data %>%
    dplyr::filter(.data$Species == species) %>%
    dplyr::arrange(.data$Station)

  stay <- d$Stay
  censored <- d$Cens
  c_time <- stay
  c_time[censored == 0] <- c_time[censored == 0] + 1
  stay[censored == 1] <- NA

  list(
    data = d, stay = stay, censored = censored, c_time = c_time,
    n_stay = length(stay), n_station = length(unique(d$Station)),
    n_levels = if (!is.null(stay_random_effect)) length(unique(d[[stay_random_effect]])) else 0L,
    group = if (!is.null(stay_random_effect)) as.numeric(factor(d[[stay_random_effect]])) else NULL
  )
}

#' Fit one staying-time candidate; return WAIC, Bayesian p-value and samples
#' @keywords internal
#' @noRd
rest_fit_stay <- function(prep, formula, family, stay_random_effect,
                          iterations, burnin, thin, chains, cores) {

  X_stay <- stats::model.matrix(stats::as.formula(formula),
                                stats::model.frame(formula, prep$data))
  n_pred <- ncol(X_stay)

  constants <- list(N_stay = prep$n_stay, nPreds_stay = n_pred,
                    N_station = prep$n_station, c_time = prep$c_time,
                    stay_family = family, nLevels_stay = prep$n_levels)
  data <- list(stay = prep$stay, censored = prep$censored)
  if (n_pred > 1) data$X_stay <- X_stay
  if (!is.null(stay_random_effect)) constants$group_stay <- prep$group

  prms <- switch(family,
                 exponential = c("scale", "mean_stay"),
                 lognormal   = c("meanlog", "sdlog", "mean_stay"),
                 c("scale", "shape", "mean_stay"))
  params <- c(prms, "beta_stay", "loglike_obs_stay",
              "deviance_obs", "deviance_pred")

  per_chain <- lapply(seq_len(chains), function(i) list(
    seed = sample.int(9999, 1),
    inits = {
      v <- list(beta_stay = stats::runif(n_pred, -0.1, 0.1),
                stay = ifelse(prep$censored == 0, NA, prep$c_time + stats::runif(prep$n_stay, 0.1, 1)),
                theta_stay = stats::runif(1, 0.2, 2),
                scale = stats::runif(prep$n_stay, 0.2, 2))
      if (!is.null(stay_random_effect)) {
        v$random_effect_stay <- stats::runif(prep$n_levels, -1, 1)
        v$sigma_stay <- stats::runif(1, 0.5, 2.5)
      }
      v
    }
  ))

  chain_out <- rest_run_parallel(
    per_chain, rest_code_stay(), data, constants, params,
    worker_setup = quote({
      if (!"package:nimble" %in% search()) {
        requireNamespace("nimble", quietly = TRUE)
        attachNamespace("nimble")
      }
    }),
    iterations = iterations, burnin = burnin, thin = thin, cores = cores
  )

  loglik <- MCMCvis::MCMCchains(chain_out, params = "loglike_obs_stay")
  dev <- MCMCvis::MCMCchains(chain_out, params = c("deviance_obs", "deviance_pred"))

  list(
    waic = rest_waic(loglik),
    bayes_p = mean(dev[, "deviance_pred"] > dev[, "deviance_obs"]),
    samples = MCMCvis::MCMCchains(chain_out, mcmc.list = TRUE, params = prms)
  )
}

#' Staying-time-only model code (shared block + deviance summaries)
#' @keywords internal
#' @noRd
rest_code_stay <- function() {
  rest_combine(rest_block_stay(), quote({
    # Deviance of observed vs. replicated data, for the Bayesian p-value.
    sum_loglike_obs  <- sum(loglike_obs_stay[1:N_stay])
    sum_loglike_pred <- sum(loglike_pred_stay[1:N_stay])
    deviance_obs  <- -2 * sum_loglike_obs
    deviance_pred <- -2 * sum_loglike_pred
  }))
}

#' Enumerate covariate combinations of a two-sided staying-time formula
#' @keywords internal
#' @noRd
rest_all_stay_formulas <- function(stay_formula) {
  vars <- all.vars(stay_formula)
  response <- vars[1]
  preds <- vars[-1]
  if (!length(preds)) return(list(stay_formula))
  combos <- unlist(lapply(0:length(preds), function(k) utils::combn(preds, k, simplify = FALSE)),
                   recursive = FALSE)
  lapply(combos, function(v)
    stats::as.formula(paste(response, "~", if (length(v)) paste(c("1", v), collapse = " + ") else "1")))
}

#' Print method for ct_rest_stay objects
#' @param x A `ct_rest_stay` object.
#' @param ... Ignored.
#' @return `x`, invisibly. Called for its side effect of printing the WAIC
#'   ranking of the candidate staying-time distributions and the mean
#'   staying-time summary for the best model to the console.
#' @keywords internal
#' @exportS3Method print ct_rest_stay
print.ct_rest_stay <- function(x, ...) {
  cli::cli_h2("Staying-time model selection")
  print(x$waic)
  cli::cli_text("")
  cli::cli_text("Mean staying time (best model):")
  print(x$summary)
  invisible(x)
}
