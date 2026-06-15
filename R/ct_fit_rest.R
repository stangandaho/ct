#' Fit the Random Encounter and Staying Time (REST / RAD-REST) model
#'
#' @description
#' Estimates animal density from camera-trap data **without individual
#' recognition** using the Random Encounter and Staying Time (REST) model of
#' Nakashima, Fukasawa & Samejima (2018) and its RAD-REST extension
#' (Nakashima et al. 2026). Parameters are estimated in a Bayesian framework
#' by MCMC sampling with \pkg{nimble}.
#'
#' @details
#' ## The idea behind REST
#' A camera watches a small *focal area* of known size in front of the lens.
#' If we know (i) how often animals pass through that area, (ii) how long they
#' stay in it on average, and (iii) the fraction of the day they are active,
#' density follows from a simple flow argument. Intuitively, the expected
#' number of detected passes is
#'
#' \deqn{E[Y] = D \times S \times T \times p_{act} / \bar{t}}
#'
#' where \eqn{D} is density, \eqn{S} the focal-area size, \eqn{T} the survey
#' duration, \eqn{p_{act}} the activity proportion and \eqn{\bar{t}} the mean
#' staying time. Re-arranging gives the density estimator
#' \eqn{D = Y\,\bar{t} / (S\,T\,p_{act})}. `ct_fit_rest()` fits every piece of
#' this equation jointly so that uncertainty propagates into the density
#' estimate.
#'
#' Three sub-models are combined:
#' \itemize{
#'   \item **Staying time** (`stay_data`): a survival model. Animals still in
#'     the focal area when the video ends are *right-censored*; the chosen
#'     `stay_distribution` (lognormal/gamma/weibull/exponential) handles this.
#'   \item **Encounters** (`station_data`): the number of passes `Y` per station
#'     is modelled as negative-binomial (REST), or, for RAD-REST, the number of
#'     videos showing 0,1,2,... passes is modelled with a Dirichlet-multinomial
#'     so that miscounting of passes is accounted for.
#'   \item **Activity** (`activity_data`): the active fraction of the day,
#'     estimated either by kernel density (Rowcliffe et al. 2014) or a Bayesian
#'     von Mises mixture (Nakashima et al. 2026).
#' }
#'
#' @param stay_data Staying-time data, e.g. the output of [ct_rest_stay()], with
#'   columns `Station`, `Species`, `Stay` (seconds) and `Cens` (1 = censored,
#'   0 = fully observed).
#' @param station_data Per-station encounter and effort data, e.g. the output of
#'   [ct_rest_effort()]. For `model = "REST"` it must contain `Station`,
#'   `Species`, `Effort` (days) and `Y` (passes). For `model = "RAD-REST"` it
#'   must instead contain `N` (videos) and the `y_0`, `y_1`, ... pass-count
#'   columns.
#' @param activity_data Detection times in radians, e.g. the output of
#'   [ct_rest_activity()], with columns `Species` and `time`.
#' @param species Single species name to analyse (must appear in the data).
#' @param focal_area Focal-area size in square metres. Either a single number
#'   (the same area at every camera) or the name of a column in `station_data`
#'   giving a camera-specific focal area per station.
#' @param model Either `"REST"` or `"RAD-REST"`.
#' @param stay_formula Model formula for staying time. The left-hand side names
#'   the staying-time column, e.g. `Stay ~ 1` or `Stay ~ 1 + habitat`.
#' @param density_formula One-sided formula for density covariates, e.g. `~ 1`
#'   or `~ habitat`. Density is latent, so the left-hand side is omitted.
#' @param passes_formula One-sided formula for the number of passes. Used only
#'   when `model = "RAD-REST"`; ignored otherwise.
#' @param stay_random_effect Optional column in `stay_data` giving a random
#'   effect on staying time. Default `NULL` (no random effect).
#' @param stay_distribution Distribution for staying time: one of `"lognormal"`,
#'   `"gamma"`, `"weibull"` or `"exponential"`. Ideally chosen with
#'   [ct_rest_select_stay()].
#' @param activity_method How to estimate the activity proportion: `"kernel"`
#'   (fixed kernel density) or `"mixture"` (Bayesian von Mises mixture).
#' @param bandwidth_adjust Bandwidth multiplier for `activity_method = "kernel"`.
#' @param mixture_components Maximum number of von Mises components for
#'   `activity_method = "mixture"`.
#' @param compare_models If `TRUE`, fit every combination of the density
#'   covariates and rank them by WAIC. If `FALSE`, fit only `density_formula`.
#' @param iterations,burnin,thin,chains,cores MCMC settings: total iterations
#'   per chain, burn-in length, thinning interval, number of chains and CPU
#'   cores for parallel sampling.
#' @param quiet If `TRUE`, suppress progress messages.
#'
#' @return An object of class `ct_rest` (a list) with:
#' \describe{
#'   \item{`waic`}{A tibble ranking the candidate density models by WAIC.}
#'   \item{`summary`}{A tibble of posterior summaries for density (individuals
#'     per km^2), mean staying time and, for RAD-REST, the mean number of passes.}
#'   \item{`samples`}{A `coda::mcmc.list` of posterior draws for the best model.}
#'   \item{`activity_curve`}{(mixture only) the estimated activity density curve.}
#' }
#'
#' @references
#' Nakashima, Y., Fukasawa, K. & Samejima, H. (2018) Estimating animal density
#' without individual recognition using information derived from camera traps.
#' *Journal of Applied Ecology*, 55, 735-744.
#'
#' Nakashima, Y. et al. (2026) Reducing data-processing effort in camera-trap
#' density estimation: extending the REST model. *Methods in Ecology and
#' Evolution*.
#'
#' @seealso [ct_rest_stay()], [ct_rest_effort()], [ct_rest_activity()],
#'   [ct_rest_select_stay()]
#'
#' @export
#' @examples
#' data(rest_detection)
#' data(rest_station)
#'
#' # 1. Build the three inputs from raw detections (these steps run quickly)
#' stay <- ct_rest_stay(rest_detection, rest_station)
#' stations <- ct_rest_passes(rest_detection, rest_station, model = "REST")
#' stations <- ct_rest_effort(rest_detection, stations)
#' activity <- ct_rest_activity(rest_detection)
#'
#' \dontrun{
#' # 2. Fit REST for the focal species (requires the 'nimble' package)
#' fit <- ct_fit_rest(
#'   stay_data = stay,
#'   station_data  = stations,
#'   activity_data = activity,
#'   species = "Red duiker",
#'   focal_area = 3.0, # focal-area size in m^2
#'   model = "REST",
#'   stay_distribution = "lognormal",
#'   iterations = 3000, burnin = 1000, chains = 2, cores = 2
#' )
#' fit
#' fit$summary   # density (individuals per km^2) and mean staying time
#'
#' # RAD-REST instead: use pass-classified station data
#' stations_rad <- ct_rest_effort(
#'   detection_data = rest_detection,
#'   station_data = ct_rest_passes(rest_detection, rest_station, model = "RAD-REST")
#' )
#'
#' fit_rad <- ct_fit_rest(
#'   stay_data = stay,
#'   station_data  = stations_rad,
#'   activity_data = activity,
#'   species = "Red duiker",
#'   focal_area = 3.0,
#'   model = "RAD-REST"
#' )
#' }
#'
ct_fit_rest <- function(stay_data,
                        station_data,
                        activity_data,
                        species,
                        focal_area,
                        model = c("REST", "RAD-REST"),
                        stay_formula = Stay ~ 1,
                        density_formula = ~ 1,
                        passes_formula = ~ 1,
                        stay_random_effect = NULL,
                        stay_distribution = c("lognormal", "gamma", "weibull", "exponential"),
                        activity_method = c("kernel", "mixture"),
                        bandwidth_adjust = 1,
                        mixture_components = 10,
                        compare_models = FALSE,
                        iterations = 5000,
                        burnin = 1000,
                        thin = 2,
                        chains = 3,
                        cores = 3,
                        quiet = FALSE) {

  # --- Dependencies & argument matching ---------------------------------------
  # REST relies on heavy Bayesian machinery that is not part of ct's hard
  # dependencies. rlang::check_installed() prompts the user to install any that
  # are missing when the session is interactive.
  rlang::check_installed(c("nimble", "MCMCvis", "coda", "parallel"),
                         reason = "to fit the REST / RAD-REST model.")

  model <- match_arg(model, c("REST", "RAD-REST"))
  stay_distribution <- match_arg(stay_distribution,
                                 c("lognormal", "gamma", "weibull", "exponential"))
  activity_method <- match_arg(activity_method, c("kernel", "mixture"))

  # Resolve the random-effect column (string, bare name, or position) against
  # stay_data; NULL passes through unchanged (no random effect).
  stay_random_effect <- rest_pull_name(stay_data, rlang::enquo(stay_random_effect),
                                       "stay_random_effect")

  rest_check_inputs(stay_data, station_data, activity_data, species, focal_area,
                    model, stay_formula, density_formula)

  if (!quiet) cli::cli_h1("{model} density estimation")

  # --- 1. Staying-time data ---------------------------------------------------
  # Keep one species, attach station-level effort, and split the staying times
  # into observed vs. censored. Censored records (animal still present at the
  # end of the clip) are passed to nimble as NA with an interval-censoring bound.
  if (!quiet) cli::cli_progress_step("Preparing staying-time data")
  stay <- rest_prepare_stay(stay_data, station_data, species,
                            stay_formula, stay_random_effect, focal_area)

  # --- 2. Activity proportion -------------------------------------------------
  # The fraction of the day the species is active. With "kernel" we get a single
  # number now; with "mixture" we run a small MCMC and feed its posterior draws
  # into the main model as the activity prior.
  if (!quiet) cli::cli_progress_step("Estimating activity proportion ({activity_method})")
  activity <- rest_activity(activity_data, species, activity_method,
                            bandwidth_adjust, mixture_components,
                            iterations, burnin, thin, chains, cores)

  # --- 3. Candidate density formulas ------------------------------------------
  density_formulas <- if (compare_models) {
    rest_all_formulas(all.vars(density_formula))
  } else {
    list(density_formula)
  }

  # --- 4. Fit each candidate model --------------------------------------------
  if (!quiet) cli::cli_progress_step("Running MCMC ({chains} chains)", spinner = TRUE)
  fits <- lapply(density_formulas, function(fd) {
    rest_fit_one(model, stay, activity, station_data, species,
                 focal_area, fd, stay_formula, passes_formula,
                 stay_distribution, stay_random_effect,
                 iterations, burnin, thin, chains, cores)
  })
  if (!quiet) cli::cli_progress_done()

  # --- 5. Rank by WAIC and summarise the best model ---------------------------
  waic <- vapply(fits, `[[`, numeric(1), "waic")
  best <- which.min(waic)

  waic_tbl <- dplyr::tibble(
    model = vapply(density_formulas, function(f) paste(deparse(f), collapse = " "), character(1)),
    stay_random_effect = stay_random_effect %||% "none",
    WAIC = waic
  ) %>% dplyr::arrange(.data$WAIC)

  out <- rest_summarise(fits[[best]], density_formulas[[best]], stay_formula,
                        passes_formula, stay_random_effect, model, activity,
                        stay$station_id, species)
  out$waic <- waic_tbl
  if (activity_method == "mixture") out$activity_curve <- activity$curve
  class(out) <- "ct_rest"

  if (!quiet) cli::cli_alert_success("Done. Best model: {.val {waic_tbl$model[1]}}")
  out
}


# ----------------------------------------------------------------------------
# Internal helpers
# ----------------------------------------------------------------------------

#' Validate ct_fit_rest() inputs
#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
rest_check_inputs <- function(stay_data, station_data, activity_data, species,
                              focal_area, model, stay_formula, density_formula) {
  if (!is.data.frame(stay_data) || !is.data.frame(station_data) ||
      !is.data.frame(activity_data)) {
    cli_abort("{.arg stay_data}, {.arg station_data} and {.arg activity_data} must be data frames.")
  }
  if (!inherits(stay_formula, "formula") || !inherits(density_formula, "formula")) {
    cli_abort("{.arg stay_formula} and {.arg density_formula} must be formulas.")
  }
  if (!is.character(species) || length(species) != 1) {
    cli_abort("{.arg species} must be a single species name. Fit one species at a time.")
  }
  # focal_area is either a single positive number (same area at every camera) or
  # the name of a per-station column in station_data holding camera-specific areas.
  if (is.character(focal_area) && length(focal_area) == 1) {
    if (!focal_area %in% names(station_data)) {
      cli_abort("{.arg focal_area} column {.val {focal_area}} not found in {.arg station_data}.")
    }
    area_vals <- station_data[[focal_area]]
    if (!is.numeric(area_vals) || anyNA(area_vals) || any(area_vals <= 0)) {
      cli_abort("Focal-area column {.val {focal_area}} must be positive and free of missing values.")
    }
  } else if (!is.numeric(focal_area) || length(focal_area) != 1 || focal_area <= 0) {
    cli_abort("{.arg focal_area} must be a single positive number (square metres) or a column name in {.arg station_data}.")
  }
  need_stay <- c("Station", "Species", "Stay", "Cens")
  if (!all(need_stay %in% names(stay_data))) {
    cli_abort("{.arg stay_data} must contain columns {.val {need_stay}}.")
  }
  need_station <- if (model == "REST") c("Station", "Species", "Effort", "Y") else
    c("Station", "Species", "Effort", "N")
  if (!all(need_station %in% names(station_data))) {
    cli_abort("{.arg station_data} must contain columns {.val {need_station}} for {model}.")
  }
  # RAD-REST classifies videos by number of passes (y_0, y_1, ...). The
  # cut-point model needs at least three categories (e.g. y_0, y_1, y_2) to be
  # identifiable; with fewer, fall back to model = "REST".
  if (model == "RAD-REST") {
    n_group <- length(grep("^y_\\d+$", names(station_data)))
    if (n_group < 3) {
      cli_abort(c(
        "RAD-REST needs at least 3 pass-count columns ({.val y_0}, {.val y_1}, {.val y_2}, ...), but {.arg station_data} has {n_group}.",
        "i" = "With this few pass categories, use {.code model = \"REST\"} instead."
      ))
    }
  }
  if (!species %in% station_data$Species) {
    cli_abort("Species {.val {species}} not found in {.arg station_data}.")
  }
  invisible(TRUE)
}

#' Build the staying-time inputs shared by every candidate model
#' @keywords internal
#' @noRd
#' @importFrom rlang .data
rest_prepare_stay <- function(stay_data, station_data, species, stay_formula,
                              stay_random_effect, focal_area) {
  station <- dplyr::filter(station_data, .data$Species == species)

  joined <- stay_data %>%
    dplyr::filter(.data$Species == species) %>%
    dplyr::left_join(station, by = intersect(names(stay_data), names(station))) %>%
    dplyr::filter(!is.na(.data$Stay))

  stay <- joined$Stay
  censored <- joined$Cens

  # Interval-censoring bound for nimble's dinterval(): an observed value is known
  # exactly (bound just above it); a censored value is only known to exceed it.
  c_time <- stay
  c_time[censored == 0] <- c_time[censored == 0] + 1
  stay[censored == 1] <- NA

  # Design matrix for staying-time covariates.
  mf <- stats::model.frame(stay_formula, joined)
  X_stay <- stats::model.matrix(stats::as.formula(stay_formula), mf)

  n_levels <- if (!is.null(stay_random_effect))
    length(unique(joined[[stay_random_effect]])) else 0L
  group <- if (!is.null(stay_random_effect))
    as.numeric(factor(joined[[stay_random_effect]])) else NULL

  list(
    joined = joined,
    station = station,
    station_id = unique(station$Station),
    n_station = nrow(station),
    stay = stay,
    censored = censored,
    c_time = c_time,
    n_stay = length(stay),
    X_stay = X_stay,
    n_pred_stay = ncol(X_stay),
    n_levels = n_levels,
    group = group,
    # Per-station focal area in km^2 and effort in seconds, as the REST equation
    # expects. A scalar focal_area is recycled across stations; a column name is
    # pulled per station (in the same row order as n_period and the design matrices).
    S = (if (is.character(focal_area)) station[[focal_area]]
         else rep(focal_area, nrow(station))) * 1e-6,
    n_period = station$Effort * 60 * 60 * 24
  )
}

#' Estimate the activity proportion (kernel or Bayesian mixture)
#' @keywords internal
#' @noRd
#' @importFrom rlang .data
rest_activity <- function(activity_data, species, method, bandwidth_adjust,
                          mixture_components, iterations, burnin, thin, chains, cores) {
  times <- activity_data %>%
    dplyr::filter(.data$Species == species) %>%
    dplyr::pull(.data$time)

  if (method == "kernel") {
    # Rowcliffe et al. (2014): activity proportion = 1 / (2*pi * max kernel density).
    fit <- activity::fitact(times,
                            bw = bandwidth_adjust * activity::bwcalc(times, K = 3),
                            reps = 1)
    # With reps = 1 the @act slot holds the point estimate of the activity level.
    return(list(method = "kernel", proportion = as.numeric(fit@act)[1]))
  }

  # Mixture: a nonparametric von Mises mixture fitted by its own MCMC. Each chain
  # of posterior activity_proportion draws is later fed to one main-model chain.
  grid <- seq(0, 2 * pi, 0.02)
  constants <- list(N = length(times), C = mixture_components,
                    dens.x = grid, ndens = length(grid))
  per_chain <- lapply(seq_len(chains), function(i) list(
    seed = sample.int(9999, 1),
    inits = list(
      mu_mix = stats::runif(mixture_components, 0, 2 * pi),
      kappa_mix = stats::rgamma(mixture_components, 1, 0.01),
      group = sample.int(mixture_components, constants$N, replace = TRUE),
      v = stats::rbeta(mixture_components - 1, 1, 1),
      alpha = 1
    )
  ))

  chain_out <- rest_run_parallel(
    per_chain, rest_code_activity(), list(act_data = times), constants,
    params = c("activity_density", "activity_proportion", "loglike_obs_act"),
    worker_setup = rest_worker_setup(dirmnom = FALSE),
    iterations = iterations, burnin = burnin, thin = thin, cores = cores
  )

  curve <- MCMCvis::MCMCsummary(chain_out, round = 3) %>%
    as.data.frame() %>%
    tibble::rownames_to_column("variable") %>%
    dplyr::filter(startsWith(.data$variable, "activity_density")) %>%
    dplyr::mutate(x = grid) %>%
    dplyr::as_tibble()

  list(
    method = "mixture",
    # One matrix of activity_proportion draws per chain, used as an informative
    # prior for the main model.
    prior_draws = lapply(chain_out, function(m)
      as.matrix(m[, grep("activity_proportion", colnames(m))])),
    loglik = MCMCvis::MCMCchains(chain_out, params = "loglike_obs_act"),
    curve = curve
  )
}

#' Fit a single REST / RAD-REST model and return samples + WAIC
#' @keywords internal
#' @noRd
#' @importFrom rlang .data
rest_fit_one <- function(model, stay, activity, station_data, species,
                         focal_area, density_formula, stay_formula, passes_formula,
                         stay_distribution, stay_random_effect,
                         iterations, burnin, thin, chains, cores) {

  is_mixture <- activity$method == "mixture"
  mf_d <- stats::model.frame(density_formula, data = stay$station)
  X_density <- stats::model.matrix(stats::as.formula(density_formula), mf_d)

  # Constants are quantities nimble treats as fixed; data are observed nodes.
  constants <- list(
    N_station = stay$n_station, S = stay$S, N_period = stay$n_period,
    nPreds_stay = stay$n_pred_stay, N_stay = stay$n_stay, c_time = stay$c_time,
    nPreds_density = ncol(X_density), stay_family = stay_distribution,
    activity_estimation = activity$method, nLevels_stay = stay$n_levels
  )
  data <- list(stay = stay$stay, censored = stay$censored, X_density = X_density)

  if (!is_mixture) constants$activity_proportion <- activity$proportion
  if (stay$n_pred_stay > 1) data$X_stay <- stay$X_stay
  if (!is.null(stay_random_effect)) constants$group_stay <- stay$group

  # Model-specific data (the encounter sub-model) and BUGS code.
  if (model == "REST") {
    data$y <- stay$station$Y
    code <- rest_code(model = "REST")
    dirmnom <- FALSE
  } else {
    y <- as.matrix(dplyr::select(stay$station, dplyr::starts_with("y_")))
    X_enter <- stats::model.matrix(stats::as.formula(passes_formula),
                                   stats::model.frame(passes_formula, stay$station))
    data$y <- y
    data$N_detection <- stay$station$N
    data$N_judge <- rowSums(y)
    constants$N_group <- ncol(y)
    # Number of passes each y_* category represents: y_0 -> 0, y_1 -> 1, ...
    constants$pass_count <- 0:(ncol(y) - 1)
    constants$X_enter <- X_enter
    constants$nPreds_enter <- ncol(X_enter)
    code <- rest_code(model = "RAD-REST")
    dirmnom <- TRUE
  }

  # Parameters to monitor: staying-time scale, density, mean staying time and
  # the per-point log-likelihoods needed for WAIC.
  prms <- switch(stay_distribution,
                 exponential = c("scale", "mean_stay"),
                 lognormal   = c("meanlog", "sdlog", "mean_stay"),
                 c("scale", "shape", "mean_stay"))
  prms <- unique(c(prms, "density", "mean_stay", "size", "beta_stay", "beta_density"))
  if (model == "RAD-REST") prms <- c(prms, "mean_pass")
  if (is_mixture) prms <- c(prms, "activity_proportion")
  params <- c(prms, "loglike_obs_stay", "loglike_obs_y")

  # For the mixture, the number of main chains equals the number of activity
  # chains because each main chain consumes one activity posterior.
  n_chain <- if (is_mixture) length(activity$prior_draws) else chains
  per_chain <- lapply(seq_len(n_chain), function(i) list(
    seed = sample.int(9999, 1),
    inits = rest_inits(stay, ncol(X_density),
                       if (model == "RAD-REST") constants$nPreds_enter else 0L,
                       if (model == "RAD-REST") constants$N_group else 0L,
                       stay_random_effect, stay_distribution),
    actv_samples = if (is_mixture) activity$prior_draws[[i]] else NULL
  ))

  chain_out <- rest_run_parallel(
    per_chain, code, data, constants, params,
    worker_setup = rest_worker_setup(dirmnom = dirmnom),
    iterations = iterations, burnin = burnin, thin = thin,
    cores = cores, is_mixture = is_mixture
  )

  # WAIC from the joined per-point log-likelihoods (staying time + encounters,
  # plus activity for the mixture model).
  loglik <- cbind(
    MCMCvis::MCMCchains(chain_out, params = "loglike_obs_stay"),
    MCMCvis::MCMCchains(chain_out, params = "loglike_obs_y")
  )
  if (is_mixture) loglik <- cbind(loglik, activity$loglik)

  list(
    waic = rest_waic(loglik),
    samples = MCMCvis::MCMCchains(chain_out, mcmc.list = TRUE, params = prms)
  )
}

#' Generate MCMC initial values
#' @keywords internal
#' @noRd
rest_inits <- function(stay, n_pred_density, n_pred_enter, n_group,
                       stay_random_effect, stay_distribution) {
  inits <- list(
    beta_stay = stats::rnorm(stay$n_pred_stay, 0, 0.1),
    stay = ifelse(stay$censored == 0, NA, stay$c_time + stats::runif(stay$n_stay, 0.1, 2)),
    theta_stay = stats::runif(1, 0.8, 1.2),
    beta_density = stats::rnorm(n_pred_density, 0, 0.1),
    size = stats::runif(1, 0.8, 1.2)
  )
  inits$beta_stay[1] <- log(mean(stay$stay, na.rm = TRUE))
  inits$beta_density[1] <- log(5)

  if (n_group > 0) {
    inits$beta_enter <- rep(0, n_pred_enter)
    inits$theta_enter <- stats::runif(1, 5, 20)
    inits$cutpoint <- c(0, rep(NA, n_group - 2))
    if (n_group > 2) inits$delta <- rep(0.5, n_group - 2)
  }
  if (!is.null(stay_random_effect) && stay$n_levels > 0) {
    inits$random_effect_stay <- stats::runif(stay$n_levels, -0.1, 0.1)
    inits$sigma_stay <- stats::runif(1, 0.8, 1.5)
  }
  inits
}

#' Run one MCMC chain per worker in parallel
#' @keywords internal
#' @noRd
rest_run_parallel <- function(per_chain, code, data, constants, params,
                              worker_setup, iterations, burnin, thin, cores,
                              is_mixture = FALSE) {
  # Each worker compiles in its own temp directory to avoid C++ build clashes,
  # then (for the mixture) swaps the activity_proportion sampler for one that
  # draws from the pre-computed activity posterior.
  run_one <- function(info, code, data, constants, params, iterations, burnin,
                      thin, is_mixture) {
    dir <- file.path(tempdir(), paste0("nimble_", Sys.getpid()))
    dir.create(dir, showWarnings = FALSE)
    m  <- nimble::nimbleModel(code, data = data, constants = constants, inits = info$inits)
    cm <- nimble::compileNimble(m, dirName = dir)
    cfg <- nimble::configureMCMC(m, monitors = params)
    if (is_mixture) {
      cfg$removeSampler("activity_proportion")
      cfg$addSampler(target = "activity_proportion", type = "prior_samples",
                     control = list(samples = info$actv_samples))
    }
    mcmc  <- nimble::buildMCMC(cfg)
    cmcmc <- nimble::compileNimble(mcmc, project = m, dirName = dir)
    nimble::runMCMC(cmcmc, niter = iterations, nburnin = burnin, thin = thin,
                    nchains = 1, setSeed = info$seed, samplesAsCodaMCMC = TRUE)
  }

  cl <- parallel::makeCluster(min(cores, length(per_chain)))
  on.exit(try(parallel::stopCluster(cl), silent = TRUE), add = TRUE)
  parallel::clusterExport(cl, "run_one", envir = environment())
  # Define and register the custom nimble distributions inside each worker.
  parallel::clusterCall(cl, function(setup) eval(setup, envir = globalenv()), worker_setup)

  parallel::parLapply(cl, per_chain, run_one, code = code, data = data,
                      constants = constants, params = params,
                      iterations = iterations, burnin = burnin, thin = thin,
                      is_mixture = is_mixture)
}

#' WAIC with a numerically stable log-sum-exp
#' @keywords internal
#' @noRd
rest_waic <- function(loglik) {
  log_mean_exp <- function(x) {
    x <- x[is.finite(x)]
    if (!length(x)) return(NA_real_)
    mx <- max(x)
    mx + log(mean(exp(x - mx)))
  }
  safe_var <- function(x) { x <- x[is.finite(x)]; if (length(x) < 2) NA_real_ else stats::var(x) }
  lppd  <- sum(apply(loglik, 2, log_mean_exp), na.rm = TRUE)
  pwaic <- sum(apply(loglik, 2, safe_var),    na.rm = TRUE)
  -2 * lppd + 2 * pwaic
}

#' Summarise the best model's posterior into a tidy table
#' @keywords internal
#' @noRd
#' @importFrom rlang .data
rest_summarise <- function(fit, density_formula, stay_formula, passes_formula,
                           stay_random_effect, model, activity, station_id, species) {
  samples <- fit$samples

  # Append the mixture activity proportion to the kept samples if used.
  prms <- c("density", "mean_stay")
  if (model == "RAD-REST") prms <- c(prms, "mean_pass")
  if (activity$method == "mixture") prms <- c(prms, "activity_proportion")

  # A parameter is "global" (one value for the whole survey) when its formula
  # has no covariates; such rows are collapsed to a single "All" station.
  no_cov <- function(f) length(all.vars(f[[length(f)]])) == 0
  density_global <- no_cov(density_formula)
  stay_global    <- no_cov(stay_formula) && is.null(stay_random_effect)
  pass_global    <- if (model == "REST") density_global && stay_global else no_cov(passes_formula)

  summary <- MCMCvis::MCMCsummary(samples, params = prms, round = 3) %>%
    as.data.frame() %>%
    tibble::rownames_to_column("Variable") %>%
    tibble::as_tibble() %>%
    dplyr::rename(lower = `2.5%`, median = `50%`, upper = `97.5%`) %>%
    dplyr::mutate(
      cv = .data$sd / .data$mean,
      Species = species,
      base = sub("\\[.*\\]", "", .data$Variable),
      idx = suppressWarnings(as.integer(sub(".*\\[(\\d+)\\].*", "\\1", .data$Variable))),
      Station = ifelse(!is.na(.data$idx), station_id[.data$idx], "All")
    ) %>%
    dplyr::filter(
      !(.data$base == "density"   & density_global & !is.na(.data$idx) & .data$idx != 1),
      !(.data$base == "mean_stay" & stay_global    & !is.na(.data$idx) & .data$idx != 1),
      !(.data$base == "mean_pass" & pass_global    & !is.na(.data$idx) & .data$idx != 1)
    ) %>%
    dplyr::mutate(
      global = (.data$base == "density"   & density_global) |
               (.data$base == "mean_stay" & stay_global) |
               (.data$base == "mean_pass" & pass_global),
      Station  = ifelse(.data$global, "All", .data$Station),
      Variable = ifelse(.data$global, .data$base, .data$Variable)
    ) %>%
    dplyr::select(.data$Species, .data$Station, .data$Variable, .data$mean,
                  .data$sd, .data$lower, .data$median, .data$upper,
                  dplyr::any_of(c("Rhat", "n.eff")), .data$cv)

  list(summary = summary, samples = samples)
}

#' Enumerate every covariate combination as a density formula
#' @keywords internal
#' @noRd
rest_all_formulas <- function(vars) {
  if (!length(vars)) return(list(~ 1))
  combos <- unlist(lapply(0:length(vars), function(k) utils::combn(vars, k, simplify = FALSE)),
                   recursive = FALSE)
  lapply(combos, function(v)
    stats::as.formula(paste("~", if (length(v)) paste(v, collapse = " + ") else "1")))
}

#' Print method for ct_rest objects
#' @param x A `ct_rest` object.
#' @param ... Ignored.
#' @keywords internal
#' @exportS3Method print ct_rest
print.ct_rest <- function(x, ...) {
  cli::cli_h2("REST density estimate")
  cli::cli_text("Model ranking (WAIC):")
  print(x$waic)
  cli::cli_text("")
  cli::cli_text("Posterior summary:")
  print(x$summary)
  cli::cli_text("")
  cli::cli_alert_info("Full posterior draws are in {.code $samples} (use the MCMCvis package for trace plots).")
  invisible(x)
}
