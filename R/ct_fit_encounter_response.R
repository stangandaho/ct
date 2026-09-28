#' Fit a conditional encounter-response model for camera-trap events
#'
#' Estimates whether encounters of a response species become more or less likely
#' in the minutes to hours after encounters of a trigger species at the same
#' camera. Unlike a diel overlap coefficient -- which only compares two species'
#' marginal activity curves -- this is a directed, time-lagged association: it
#' contrasts the response encounter rate in successive windows after a trigger
#' with that camera's expected rate at the same time of day and month. It
#' quantifies association, not causation.
#'
#' @details
#' **What is being approximated.** The quantity of interest -- "does an encounter
#' of species A raise or lower the short-term encounter intensity of species B?"
#' -- is formally a *mutually exciting (Hawkes-type) point process*. Fitting such
#' a process directly is data-hungry and fragile with sparse camera-trap
#' detections, so this function uses a transparent discrete-time approximation:
#' camera uptime is sliced into short intervals, the number of response
#' detections per interval is modelled as a count, and time-since-last-trigger is
#' entered as a step function (`lag_breaks`). Because it is an approximation, the
#' interval width matters -- always inspect `interval_sensitivity` before
#' interpreting an effect.
#'
#' **How confounders are handled.** Camera uptime enters as an offset so unequal
#' effort is accounted for; circular (harmonic) terms hold the shared diel
#' activity curve constant; a month factor absorbs broad seasonal variation; and
#' each camera contributes only *within-camera* temporal contrasts, so
#' time-invariant differences in habitat, placement and baseline abundance are
#' differenced out. With `engine = "glm"` cameras are fixed effects; with
#' `engine = "glmm"` they are random intercepts (partial pooling), which is more
#' efficient with many sparse cameras and avoids the incidental-parameter problem
#' of many fixed effects.
#'
#' **Inference.** Successive intervals at one camera are serially correlated and
#' response detections cluster in time. A quasi-Poisson dispersion correction
#' rescales for overdispersion but *not* for this autocorrelation, so model-based
#' intervals from `engine = "glm"` are optimistic. The default inference is
#' therefore a **camera-block bootstrap** (`n_boot`), which resamples whole
#' cameras and so respects within-camera dependence; treat those intervals as the
#' primary uncertainty. With `engine = "glmm"` the camera random effect already
#' propagates between-camera variance, so the bootstrap is skipped.
#'
#' **The dominant limitation -- shared transient drivers.** The controls above
#' remove *stable* and *diel/seasonal* confounding, but they cannot remove
#' *episodic* shared drivers: a fruiting tree, a waterhole, a prey pulse,
#' moonlight or a weather front can draw both species independently within the
#' same hours and manufacture an apparent "response" with no behavioural
#' interaction whatsoever. Detection is also a thinned, imperfect observation of
#' presence, so a shift in detection rate need not reflect a shift in true site
#' use. For these reasons the result is an *association conditional on the fitted
#' baseline*, never evidence of a direct behavioural or causal effect. Corroborate
#' with randomization or simulation checks, and never treat deployments
#' reconstructed from first/last detections as camera uptime.
#'
#' **Independence filtering.** `independence` collapses repeat detections of the
#' same species at the same camera that fall within a short window -- these are
#' usually one animal lingering in front of the sensor, i.e. one biological
#' event. Note the tension with this model: unlike activity-level estimation
#' (where 30 min is conventional), a long filter here would erase exactly the
#' rapid successive detections that a short-term response would produce. The
#' default is therefore deliberately small (2 minutes): long enough to merge a
#' single pass into one event, short enough to preserve genuine reactivity in the
#' first lag window. Set `independence = 0` to keep every record.
#'
#' @param data A data frame with one row per camera-trap record (the observation
#'   data).
#' @param deployment A data frame of actual camera deployment intervals. It must
#'   contain the camera ID, start, and end columns. Intervals for the same camera
#'   may not overlap.
#' @param trigger Character scalar naming the species whose event initiates a
#'   response window.
#' @param response Character scalar naming the species whose encounter rate is
#'   modelled.
#' @param species_column Unquoted column in `data` giving the species name.
#' @param cam_column Unquoted column giving the camera ID. This column must be
#'   present, with the same name, in both `data` and `deployment` so that records
#'   can be matched to their deployment intervals.
#' @param datetime_column Unquoted column in `data` giving the event date-time.
#' @param start_column,end_column Unquoted columns in `deployment` giving the
#'   deployment interval start and end date-times respectively.
#' @param interval Width of analysis intervals in seconds. It must not exceed the
#'   narrowest response-lag window.
#' @param lag_breaks Numeric vector of lag boundaries in seconds. The default
#'   estimates associations for 0--30 minutes, 30 minutes--2 hours, and 2--6
#'   hours after a trigger. Time after the final boundary is the reference.
#' @param independence Minimum number of seconds between retained records of the
#'   same species at the same camera. Defaults to 2 minutes; set to `0` to retain
#'   every record. See Details for why this default is smaller than the value used
#'   for activity-level estimation.
#' @param engine Fitting engine. `"glm"` (default) fits a camera-stratified
#'   quasi-Poisson GLM with camera fixed effects and a camera-block bootstrap.
#'   `"glmm"` fits a Poisson/negative-binomial mixed model with camera (and, where
#'   present, deployment) random intercepts, using \pkg{glmmTMB} if installed and
#'   otherwise \pkg{lme4}.
#' @param n_boot Number of camera-block bootstrap replicates used for percentile
#'   confidence intervals. If `NULL` (default) it is set to 199 for
#'   `engine = "glm"` and to 0 for `engine = "glmm"`. Set to `0` to return
#'   model-based intervals only.
#' @param interval_sensitivity Optional numeric vector of alternative `interval`
#'   widths (seconds). When supplied, the lag-specific rate ratios are refitted at
#'   each width and returned in `$sensitivity`, so the reader can judge how far the
#'   conclusion depends on the binning choice. Each value must not exceed the
#'   narrowest lag window.
#' @param seed Optional integer seed for the bootstrap.
#'
#' @return An object of class `ct_encounter_response` containing the fitted model,
#'   lag-specific rate ratios, analysis-interval data, an optional bin-width
#'   sensitivity table, and settings. A rate ratio below one indicates fewer
#'   response encounters than expected after a trigger, conditional on the fitted
#'   baseline terms.
#'
#' @references
#' Hawkes, A. G. (1971). Spectra of some self-exciting and mutually exciting point
#' processes. \emph{Biometrika}, 58(1), 83--90. \doi{10.1093/biomet/58.1.83}
#'
#' Ridout, M. S., & Linkie, M. (2009). Estimating overlap of daily activity
#' patterns from camera trap data. \emph{Journal of Agricultural, Biological, and
#' Environmental Statistics}, 14(3), 322--337. \doi{10.1198/jabes.2009.08038}
#'
#' @examples
#' \dontrun{
#' data(ACBR)
#' fit <- ct_fit_encounter_response(
#'   data = ACBR$acbr_data,
#'   deployment = ACBR$deployment,
#'   trigger = "Cercopithecus mona", response = "Tragelaphus spekii",
#'   species_column = species, cam_column = cam, datetime_column = datetime,
#'   start_column = start, end_column = end
#' )
#' summary(fit)
#'
#' # Random-effects engine plus a bin-width sensitivity check
#' fit_glmm <- ct_fit_encounter_response(
#'   data = ACBR$acbr_data,
#'   deployment = ACBR$deployment,
#'   trigger = "Cercopithecus mona", response = "Tragelaphus spekii",
#'   species_column = species, cam_column = cam, datetime_column = datetime,
#'   start_column = start, end_column = end,
#'   engine = "glmm",
#'   interval_sensitivity = c(5 * 60, 10 * 60, 30 * 60)
#' )
#' fit_glmm$sensitivity
#' }
#'
#' @export
ct_fit_encounter_response <- function(data,
                                      deployment,
                                      trigger,
                                      response,
                                      species_column,
                                      cam_column,
                                      datetime_column,
                                      start_column,
                                      end_column,
                                      interval = 15 * 60,
                                      lag_breaks = c(0, 30 * 60, 2 * 3600, 6 * 3600),
                                      independence = 2 * 60,
                                      engine = c("glm", "glmm"),
                                      n_boot = NULL,
                                      interval_sensitivity = NULL,
                                      seed = NULL) {
  engine <- match.arg(engine)
  if (!is.data.frame(data) || !is.data.frame(deployment)) {
    cli::cli_abort("`data` and `deployment` must both be data frames.")
  }
  if (!is.character(trigger) || length(trigger) != 1 ||
      !is.character(response) || length(response) != 1 || trigger == response) {
    cli::cli_abort("`trigger` and `response` must be distinct character scalars.")
  }
  if (!is.numeric(interval) || length(interval) != 1 || interval <= 0 ||
      !is.numeric(independence) || length(independence) != 1 || independence < 0) {
    cli::cli_abort("`interval` must be positive and `independence` must be non-negative.")
  }
  if (!is.numeric(lag_breaks) || length(lag_breaks) < 2 || lag_breaks[1] != 0 ||
      any(!is.finite(lag_breaks)) || any(diff(lag_breaks) <= 0)) {
    cli::cli_abort("`lag_breaks` must be increasing, finite, and start at 0.")
  }
  if (interval > min(diff(lag_breaks))) {
    cli::cli_abort("`interval` must not exceed the narrowest lag window.")
  }
  if (!is.null(interval_sensitivity)) {
    if (!is.numeric(interval_sensitivity) || any(!is.finite(interval_sensitivity)) ||
        any(interval_sensitivity <= 0)) {
      cli::cli_abort("`interval_sensitivity` must be a vector of positive, finite seconds.")
    }
    if (any(interval_sensitivity > min(diff(lag_breaks)))) {
      cli::cli_abort("Every `interval_sensitivity` value must not exceed the narrowest lag window.")
    }
  }

  # Resolve inference defaults: bootstrap is primary for the fixed-effects GLM,
  # while the mixed model carries between-camera uncertainty in its random effect.
  if (is.null(n_boot)) n_boot <- if (engine == "glm") 199L else 0L
  if (!is.numeric(n_boot) || length(n_boot) != 1 || n_boot < 0 || n_boot != as.integer(n_boot)) {
    cli::cli_abort("`n_boot` must be a non-negative integer.")
  }
  n_boot <- as.integer(n_boot)
  if (engine == "glmm") {
    if (!requireNamespace("glmmTMB", quietly = TRUE) &&
        !requireNamespace("lme4", quietly = TRUE)) {
      cli::cli_abort(c(
        "Package {.pkg glmmTMB} or {.pkg lme4} is required for {.code engine = \"glmm\"}.",
        "i" = "Install one, e.g. {.code install.packages(\"glmmTMB\")}."
      ))
    }
    if (n_boot > 0) {
      cli::cli_inform("Ignoring {.code n_boot} for {.code engine = \"glmm\"}; the camera random effect already propagates between-camera uncertainty.")
      n_boot <- 0L
    }
  }

  # Resolve column names from unquoted arguments. `cam_column` is shared: it must
  # name the same camera-ID column in both `data` and `deployment`.
  if (missing(species_column) || missing(cam_column) || missing(datetime_column)) {
    cli::cli_abort("`species_column`, `cam_column`, and `datetime_column` must be supplied as unquoted columns of `data`.")
  }
  if (missing(start_column) || missing(end_column)) {
    cli::cli_abort("`start_column` and `end_column` must be supplied as unquoted columns of `deployment`.")
  }
  species_col <- rlang::as_name(rlang::ensym(species_column))
  camera_col <- rlang::as_name(rlang::ensym(cam_column))
  datetime_col <- rlang::as_name(rlang::ensym(datetime_column))
  start_col <- rlang::as_name(rlang::ensym(start_column))
  end_col <- rlang::as_name(rlang::ensym(end_column))
  required_data <- c(species_col, camera_col, datetime_col)
  required_deployment <- c(camera_col, start_col, end_col)
  missing_data <- setdiff(required_data, names(data))
  missing_deployment <- setdiff(required_deployment, names(deployment))
  if (length(missing_data)) {
    cli::cli_abort("`data` is missing column{?s} {.val {missing_data}}.")
  }
  if (length(missing_deployment)) {
    cli::cli_abort("`deployment` is missing column{?s} {.val {missing_deployment}}.")
  }

  events <- data.frame(
    camera_id = as.character(data[[camera_col]]),
    species = as.character(data[[species_col]]),
    time = as.POSIXct(data[[datetime_col]], tz = "UTC"),
    stringsAsFactors = FALSE
  )
  events <- events[events$species %in% c(trigger, response) &
                   !is.na(events$camera_id) & !is.na(events$time), , drop = FALSE]
  if (!all(c(trigger, response) %in% events$species)) {
    cli::cli_abort("Both `trigger` and `response` must occur in `data`.")
  }

  deployments <- data.frame(
    camera_id = as.character(deployment[[camera_col]]),
    start = as.POSIXct(deployment[[start_col]], tz = "UTC"),
    end = as.POSIXct(deployment[[end_col]], tz = "UTC"),
    stringsAsFactors = FALSE
  )
  deployments <- deployments[!is.na(deployments$camera_id) & !is.na(deployments$start) &
                               !is.na(deployments$end), , drop = FALSE]
  if (!nrow(deployments) || any(deployments$end <= deployments$start)) {
    cli::cli_abort("Deployment intervals must have non-missing starts and ends with `end > start`.")
  }
  deployments <- deployments[order(deployments$camera_id, deployments$start), , drop = FALSE]
  for (cam in unique(deployments$camera_id)) {
    x <- deployments[deployments$camera_id == cam, , drop = FALSE]
    if (nrow(x) > 1 && any(x$start[-1] < x$end[-nrow(x)])) {
      cli::cli_abort("Deployment intervals overlap for camera {.val {cam}}.")
    }
  }
  if (engine == "glmm" && length(unique(deployments$camera_id)) < 2 &&
      nrow(deployments) < 2) {
    cli::cli_abort("{.code engine = \"glmm\"} needs more than one camera or deployment to estimate a random effect.")
  }

  events <- .ct_independent_encounters(events, independence)
  deployments$deployment_id <- seq_len(nrow(deployments))
  lag_labels <- .ct_encounter_lag_labels(lag_breaks)

  interval_data <- .ct_encounter_prepare(events, deployments, trigger, response,
                                          interval, lag_breaks, lag_labels)
  if (!any(interval_data$count > 0)) {
    cli::cli_abort("No independent response events fall within the supplied deployment intervals.")
  }
  if (!any(interval_data$lag_group != "No recent trigger")) {
    cli::cli_abort("No trigger events fall within the supplied deployment intervals.")
  }

  fit <- .ct_encounter_fit(interval_data, engine)
  estimates <- .ct_encounter_estimates(fit, lag_labels)
  lag_diagnostics <- stats::aggregate(
    cbind(n_response_events = count, exposure_seconds = exposure_seconds) ~ lag_group,
    data = interval_data, FUN = sum
  )
  diagnostic_index <- match(estimates$lag, lag_diagnostics$lag_group)
  estimates$n_response_events <- lag_diagnostics$n_response_events[diagnostic_index]
  estimates$exposure_hours <- lag_diagnostics$exposure_seconds[diagnostic_index] / 3600
  estimates <- .ct_encounter_mask_empty(estimates)
  empty_lags <- estimates$lag[!is.na(estimates$n_response_events) &
                                estimates$n_response_events == 0 &
                                estimates$lag != "No recent trigger"]
  if (length(empty_lags)) {
    warning("Lag window(s) with zero response events carry no information on the rate ratio and were set to NA: ",
            paste(empty_lags, collapse = ", "), ".", call. = FALSE)
  }
  sparse_lags <- !is.na(estimates$n_response_events) & estimates$n_response_events > 0 &
    estimates$n_response_events < 5 & estimates$lag != "No recent trigger"
  if (any(sparse_lags)) {
    warning("At least one lag window has fewer than five response events; treat its estimate as exploratory.",
            call. = FALSE)
  }
  estimable <- !is.na(estimates$rate_ratio)
  estimable[1] <- FALSE
  if (any(estimable & (!is.finite(estimates$lower) | !is.finite(estimates$upper)))) {
    warning("A lag estimate has an unbounded confidence interval, indicating sparse data or separation; do not interpret its point estimate alone.",
            call. = FALSE)
  }

  if (n_boot > 0 && nrow(interval_data) > 20000) {
    cli::cli_inform(c(
      "Running {n_boot} camera-block bootstrap refits over {nrow(interval_data)} intervals; this can be slow with {.code engine = \"glm\"}.",
      "i" = "Consider {.code engine = \"glmm\"}, whose random-effect standard errors need no bootstrap."
    ))
  }
  if (n_boot > 0) {
    if (!is.null(seed)) set.seed(seed)
    cameras <- levels(interval_data$camera_id)
    boot <- matrix(NA_real_, nrow = n_boot, ncol = length(lag_labels),
                   dimnames = list(NULL, lag_labels))
    # A camera drawn k times contributes k copies of its block, each with its
    # own camera and deployment effects. With camera fixed effects this gives
    # the same coefficients as fitting the camera once with prior weight k, so
    # each replicate is one weighted fit on the design matrix built once.
    # Rows with the same covariate pattern (camera, deployment, month, time
    # slot, lag window) are merged by summing counts and exposures, which leaves
    # the Poisson estimating equations, and hence the coefficients, unchanged.
    X <- stats::model.matrix(fit)
    off <- if (is.null(fit$offset)) rep(0, nrow(X)) else fit$offset
    cam_row <- match(as.character(interval_data$camera_id), cameras)
    key <- drop(X %*% (1 / sqrt(seq_len(ncol(X)) + pi))) + cam_row * (ncol(X) + 1)
    grp <- match(key, unique(key))
    first <- !duplicated(grp)
    y <- rowsum(fit$y, grp, reorder = FALSE)[, 1]
    off <- log(rowsum(exp(off), grp, reorder = FALSE)[, 1])
    X <- X[first, , drop = FALSE]
    cam_row <- cam_row[first]
    lag_cols <- grep("^lag_group", colnames(X))
    lag_names <- sub("^lag_group", "", colnames(X)[lag_cols])
    for (b in seq_len(n_boot)) {
      sampled <- sample(cameras, length(cameras), replace = TRUE)
      w <- tabulate(match(sampled, cameras), nbins = length(cameras))[cam_row]
      beta <- tryCatch(.ct_encounter_irls(X, y, w, off, start = stats::coef(fit)),
                       error = function(e) NULL)
      if (!is.null(beta)) {
        boot[b, lag_names] <- exp(beta[lag_cols])
      }
    }
    estimates$bootstrap_lower <- c(1, apply(boot, 2, stats::quantile, probs = 0.025,
                                             na.rm = TRUE, names = FALSE))
    estimates$bootstrap_upper <- c(1, apply(boot, 2, stats::quantile, probs = 0.975,
                                             na.rm = TRUE, names = FALSE))
    estimates <- .ct_encounter_mask_empty(estimates)
  }

  sensitivity <- NULL
  if (!is.null(interval_sensitivity)) {
    grid_iv <- sort(unique(c(interval, interval_sensitivity)))
    sens_rows <- lapply(grid_iv, function(iv) {
      id <- .ct_encounter_prepare(events, deployments, trigger, response,
                                  iv, lag_breaks, lag_labels)
      if (!any(id$count > 0) || !any(id$lag_group != "No recent trigger")) return(NULL)
      f <- tryCatch(.ct_encounter_fit(id, engine), error = function(e) NULL)
      if (is.null(f)) return(NULL)
      est <- .ct_encounter_estimates(f, lag_labels)
      n_by_lag <- tapply(id$count, id$lag_group, sum)
      est$n_response_events <- as.numeric(n_by_lag[est$lag])
      est <- .ct_encounter_mask_empty(est)
      data.frame(interval = iv, lag = est$lag, rate_ratio = est$rate_ratio,
                 lower = est$lower, upper = est$upper, stringsAsFactors = FALSE)
    })
    sensitivity <- do.call(rbind, sens_rows)
    if (!is.null(sensitivity)) {
      sensitivity$lag <- factor(sensitivity$lag,
                                levels = c("No recent trigger", lag_labels))
      sensitivity <- tibble::as_tibble(sensitivity)
    }
  }

  out <- list(
    estimates = estimates,
    model = fit,
    engine = engine,
    dispersion = .ct_encounter_dispersion(fit),
    intervals = interval_data,
    sensitivity = sensitivity,
    settings = list(trigger = trigger, response = response, interval = interval,
                    lag_breaks = lag_breaks, independence = independence,
                    engine = engine, n_boot = n_boot,
                    columns = list(species = species_col, camera = camera_col,
                                   datetime = datetime_col, start = start_col,
                                   end = end_col)),
    call = match.call()
  )
  class(out) <- "ct_encounter_response"
  out
}

# Weighted Poisson log-link fit by iteratively reweighted least squares, used
# for the camera-block bootstrap. Same estimating equations as glm.fit() (the
# quasi-Poisson dispersion does not affect coefficients), solved through the
# small p x p cross-product matrix, which is much faster than the QR of the
# n x p design when n is large. Columns that the resample cannot identify
# (cameras not drawn) are returned as NA. Convergence follows glm.fit().
.ct_encounter_irls <- function(X, y, w, offset, start = NULL,
                               epsilon = 1e-8, maxit = 50) {
  beta <- if (is.null(start)) rep(0, ncol(X)) else start
  beta[is.na(beta)] <- 0
  eta <- drop(X %*% beta) + offset
  mu <- exp(eta)
  dev_fun <- function(mu) 2 * sum(w * (ifelse(y > 0, y * log(y / mu), 0) - (y - mu)))
  dev_old <- dev_fun(mu)
  aliased <- rep(FALSE, ncol(X))
  for (it in seq_len(maxit)) {
    z <- (eta - offset) + (y - mu) / mu
    W <- w * mu
    XtWX <- crossprod(X, W * X)
    XtWz <- crossprod(X, W * z)
    q <- qr(XtWX, tol = 1e-10)
    b_new <- qr.coef(q, XtWz)[, 1]
    aliased <- is.na(b_new)
    b_new[aliased] <- 0
    eta <- drop(X %*% b_new) + offset
    mu <- exp(eta)
    dev <- dev_fun(mu)
    beta <- b_new
    if (abs(dev - dev_old) / (abs(dev) + 0.1) < epsilon) break
    dev_old <- dev
  }
  beta[aliased] <- NA
  beta
}

.ct_independent_encounters <- function(events, threshold) {
  events <- events[order(events$camera_id, events$species, events$time), , drop = FALSE]
  if (threshold == 0) return(events)
  group_id <- interaction(events$camera_id, events$species, drop = TRUE)
  keep <- unlist(lapply(split(seq_len(nrow(events)), group_id), function(index) {
    times <- as.numeric(events$time[index])
    selected <- logical(length(index))
    selected[1] <- TRUE
    last_time <- times[1]
    if (length(index) > 1) {
      for (i in 2:length(index)) {
        if (times[i] - last_time >= threshold) {
          selected[i] <- TRUE
          last_time <- times[i]
        }
      }
    }
    index[selected]
  }), use.names = FALSE)
  events[sort(keep), , drop = FALSE]
}

# Build the discrete-time analysis grid: one row per camera-uptime interval, with
# the response count, exposure offset, time-since-last-trigger lag group, and diel
# and seasonal covariates. Factored out so the bin-width sensitivity analysis and
# the bootstrap can reuse exactly the same construction.
.ct_encounter_prepare <- function(events, deployments, trigger, response,
                                  interval, lag_breaks, lag_labels) {
  interval_data <- lapply(seq_len(nrow(deployments)), function(i) {
    dep <- deployments[i, , drop = FALSE]
    bin_start <- seq(as.numeric(dep$start), as.numeric(dep$end) - 1e-6, by = interval)
    bin_end <- pmin(bin_start + interval, as.numeric(dep$end))
    grid <- data.frame(
      camera_id = dep$camera_id,
      deployment_id = dep$deployment_id,
      bin_start = bin_start,
      exposure_seconds = bin_end - bin_start,
      stringsAsFactors = FALSE
    )
    dep_events <- events[events$camera_id == dep$camera_id &
                           as.numeric(events$time) >= as.numeric(dep$start) &
                           as.numeric(events$time) < as.numeric(dep$end), , drop = FALSE]
    trigger_times <- sort(as.numeric(dep_events$time[dep_events$species == trigger]))
    response_times <- as.numeric(dep_events$time[dep_events$species == response])
    response_bins <- findInterval(response_times, bin_start)
    response_bins <- response_bins[response_bins > 0 & response_times < bin_end[response_bins]]
    grid$count <- tabulate(response_bins, nbins = nrow(grid))
    latest_trigger <- findInterval(bin_start, trigger_times)
    lag <- rep(Inf, nrow(grid))
    has_trigger <- latest_trigger > 0
    lag[has_trigger] <- bin_start[has_trigger] - trigger_times[latest_trigger[has_trigger]]
    grid$lag_group <- .ct_encounter_lag_group(lag, lag_breaks)
    grid
  })
  interval_data <- do.call(rbind, interval_data)

  bin_time <- as.POSIXct(interval_data$bin_start, origin = "1970-01-01", tz = "UTC")
  bin_lt <- as.POSIXlt(bin_time, tz = "UTC")
  clock_hour <- bin_lt$hour + bin_lt$min / 60
  angle <- 2 * pi * clock_hour / 24
  interval_data$sin1 <- sin(angle)
  interval_data$cos1 <- cos(angle)
  interval_data$sin2 <- sin(2 * angle)
  interval_data$cos2 <- cos(2 * angle)
  interval_data$month <- factor(bin_lt$mon + 1)
  interval_data$camera_id <- factor(interval_data$camera_id)
  interval_data$deployment_id <- factor(interval_data$deployment_id)
  interval_data$lag_group <- factor(interval_data$lag_group,
                                    levels = c("No recent trigger", lag_labels))
  interval_data
}

# Fit the count model. "glm" -> camera-stratified quasi-Poisson (camera and
# deployment as fixed effects). "glmm" -> Poisson/NB mixed model with camera (and
# deployment) random intercepts, preferring glmmTMB's nbinom2 for overdispersion
# and falling back to lme4 with an observation-level random effect.
.ct_encounter_fit <- function(x, engine) {
  x$camera_id <- factor(x$camera_id)
  x$deployment_id <- factor(x$deployment_id)
  x$month <- factor(x$month)
  fixed <- c("lag_group", "sin1", "cos1", "sin2", "cos2")
  if (nlevels(x$month) > 1) fixed <- c(fixed, "month")

  if (engine == "glm") {
    if (nlevels(x$camera_id) > 1) fixed <- c(fixed, "camera_id")
    if (nlevels(x$deployment_id) > 1) fixed <- c(fixed, "deployment_id")
    form <- stats::as.formula(paste("count ~", paste(fixed, collapse = " + ")))
    return(stats::glm(
      form, family = stats::quasipoisson(link = "log"),
      offset = log(x$exposure_seconds), data = x
    ))
  }

  # Random-effects structure: nest deployment within camera when both vary.
  re <- if (nlevels(x$camera_id) > 1 && nlevels(x$deployment_id) > 1) {
    "(1 | camera_id/deployment_id)"
  } else if (nlevels(x$camera_id) > 1) {
    "(1 | camera_id)"
  } else if (nlevels(x$deployment_id) > 1) {
    "(1 | deployment_id)"
  } else {
    cli::cli_abort("{.code engine = \"glmm\"} needs more than one camera or deployment to estimate a random effect.")
  }
  rhs <- paste(c(fixed, re, "offset(log(exposure_seconds))"), collapse = " + ")
  form <- stats::as.formula(paste("count ~", rhs))

  fit_lme4 <- function() {
    x$.obs <- factor(seq_len(nrow(x)))
    # Observation-level random effect absorbs Poisson overdispersion.
    form_olre <- stats::update(form, . ~ . + (1 | .obs))
    lme4::glmer(form_olre, family = stats::poisson(link = "log"), data = x,
                control = lme4::glmerControl(optimizer = "bobyqa"))
  }

  if (requireNamespace("glmmTMB", quietly = TRUE)) {
    fit <- tryCatch(
      glmmTMB::glmmTMB(form, family = glmmTMB::nbinom2(link = "log"), data = x),
      error = function(e) e
    )
    if (!inherits(fit, "error")) return(fit)
    if (!requireNamespace("lme4", quietly = TRUE)) {
      cli::cli_abort(c("The {.pkg glmmTMB} fit failed.",
                       "x" = conditionMessage(fit),
                       "i" = "Install {.pkg lme4} to enable the fallback engine."))
    }
    cli::cli_inform("{.pkg glmmTMB} fit failed; falling back to {.pkg lme4}.")
    return(fit_lme4())
  }
  fit_lme4()
}

# Extract the fixed-effect coefficient table and an appropriate critical value in
# a way that works across glm (t), glmmTMB and lme4 (z).
.ct_encounter_coef <- function(fit) {
  if (inherits(fit, "glmmTMB")) {
    list(coef = summary(fit)$coefficients$cond, crit = stats::qnorm(0.975))
  } else if (inherits(fit, "glmerMod") || inherits(fit, "merMod")) {
    list(coef = summary(fit)$coefficients, crit = stats::qnorm(0.975))
  } else {
    list(coef = summary(fit)$coefficients, crit = stats::qt(0.975, df = fit$df.residual))
  }
}

# Overdispersion diagnostic that is comparable across engines (Pearson X^2 / df).
.ct_encounter_dispersion <- function(fit) {
  rp <- tryCatch(sum(stats::residuals(fit, type = "pearson")^2), error = function(e) NA_real_)
  df <- tryCatch(stats::df.residual(fit), error = function(e) NA_real_)
  if (is.na(rp) || is.na(df) || df <= 0) return(NA_real_)
  rp / df
}

.ct_encounter_lag_labels <- function(lag_breaks) {
  unit_label <- function(x) {
    if (x %% 3600 == 0) paste0(x / 3600, " h") else paste0(x / 60, " min")
  }
  paste0(utils::head(vapply(lag_breaks, unit_label, character(1)), -1), "--",
         utils::tail(vapply(lag_breaks, unit_label, character(1)), -1))
}

.ct_encounter_lag_group <- function(lag, lag_breaks) {
  labels <- .ct_encounter_lag_labels(lag_breaks)
  group <- rep("No recent trigger", length(lag))
  for (i in seq_along(labels)) {
    group[lag >= lag_breaks[i] & lag < lag_breaks[i + 1]] <- labels[i]
  }
  group
}

.ct_encounter_estimates <- function(fit, lag_labels) {
  ce <- .ct_encounter_coef(fit)
  sm <- ce$coef
  crit <- ce$crit
  lag_rows <- grep("^lag_group", rownames(sm))
  estimates <- data.frame(
    lag = c("No recent trigger", lag_labels),
    rate_ratio = 1,
    lower = 1,
    upper = 1,
    p_value = NA_real_,
    stringsAsFactors = FALSE
  )
  if (length(lag_rows)) {
    coefs <- sm[lag_rows, , drop = FALSE]
    labels <- sub("^lag_group", "", rownames(coefs))
    index <- match(labels, estimates$lag)
    estimates$rate_ratio[index] <- exp(coefs[, 1])
    estimates$lower[index] <- exp(coefs[, 1] - crit * coefs[, 2])
    estimates$upper[index] <- exp(coefs[, 1] + crit * coefs[, 2])
    estimates$p_value[index] <- coefs[, 4]
  }
  estimates
}

# A lag window with zero response events carries no information about its rate
# ratio: the fixed-effects GLM can even return a large finite (wrong-signed)
# coefficient there through non-convergence/separation. Setting such windows to
# NA is the honest, engine-independent behaviour. Requires an `n_response_events`
# column on `estimates`.
.ct_encounter_mask_empty <- function(estimates) {
  empty <- !is.na(estimates$n_response_events) & estimates$n_response_events == 0 &
    estimates$lag != "No recent trigger"
  for (col in c("rate_ratio", "lower", "upper", "p_value",
                "bootstrap_lower", "bootstrap_upper")) {
    if (!is.null(estimates[[col]])) estimates[[col]][empty] <- NA_real_
  }
  estimates
}

#' @export
print.ct_encounter_response <- function(x, ...) {
  cat("Conditional encounter-response model\n")
  cat("Trigger: ", x$settings$trigger, " | Response: ", x$settings$response, "\n", sep = "")
  cat("Engine: ", x$engine,
      if (x$settings$n_boot > 0) paste0(" | Camera-block bootstrap: ", x$settings$n_boot) else "",
      "\n", sep = "")
  print(x$estimates, row.names = FALSE)
  invisible(x)
}

#' @export
summary.ct_encounter_response <- function(object, ...) {
  out <- list(
    estimates = object$estimates,
    engine = object$engine,
    n_intervals = nrow(object$intervals),
    n_response_events = sum(object$intervals$count),
    dispersion = object$dispersion,
    settings = object$settings
  )
  class(out) <- "summary.ct_encounter_response"
  out
}

#' @export
print.summary.ct_encounter_response <- function(x, ...) {
  cat("Conditional encounter-response model\n")
  cat("Engine: ", x$engine,
      " | Inference: ",
      if (x$settings$n_boot > 0) paste0("camera-block bootstrap (", x$settings$n_boot, ")") else "model-based",
      "\n", sep = "")
  cat("Independent response events: ", x$n_response_events,
      " | Analysis intervals: ", x$n_intervals,
      " | Dispersion: ", format(round(x$dispersion, 3), nsmall = 3), "\n", sep = "")
  print(x$estimates, row.names = FALSE)
  invisible(x)
}
