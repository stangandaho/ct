# nimble model code for the REST / RAD-REST estimator.
#
# These builders return quoted BUGS code that nimble turns into a model graph.
# The staying-time sub-model is identical for REST and RAD-REST, so it is
# written once and spliced onto the model-specific encounter block. The `if()`
# statements inside the code are resolved by nimble at model-build time from the
# constants (`stay_family`, `nPreds_stay`, `nLevels_stay`, ...), so only the
# relevant lines end up in the graph.

#' Concatenate several quoted `{...}` blocks into one
#' @keywords internal
#' @noRd
rest_combine <- function(...) {
  parts <- lapply(list(...), function(e) as.list(e)[-1L])  # drop the leading `{`
  as.call(c(as.name("{"), do.call(c, parts)))
}

#' Staying-time survival sub-model (shared by REST and RAD-REST)
#' @keywords internal
#' @noRd
rest_block_stay <- function() {
  quote({
    for (i in 1:N_stay) {
      # Interval censoring: censored[i] = 1 means the true stay exceeds c_time[i]
      # (animal still present when the clip ended); 0 means it is known exactly.
      censored[i] ~ dinterval(stay[i], c_time[i])

      if (stay_family == "exponential") {
        stay[i] ~ dexp(rate = 1 / scale[i])
        pred_t[i] ~ dexp(rate = 1 / scale[i])
        loglike_obs_stay[i] <- (1 - step(censored[i] - 0.5)) * dexp(stay[i], rate = 1 / scale[i], log = 1) +
          step(censored[i] - 0.5) * log(1 - pexp(c_time[i], rate = 1 / scale[i]))
        loglike_pred_stay[i] <- dexp(pred_t[i], rate = 1 / scale[i], log = 1)
      }
      if (stay_family == "gamma") {
        stay[i] ~ dgamma(shape = theta_stay, rate = exp(-log(scale[i])))
        pred_t[i] ~ dgamma(shape = theta_stay, rate = exp(-log(scale[i])))
        loglike_obs_stay[i] <- (1 - step(censored[i] - 0.5)) * dgamma(stay[i], shape = theta_stay, rate = exp(-log(scale[i])), log = 1) +
          step(censored[i] - 0.5) * log(1 - pgamma(c_time[i], shape = theta_stay, rate = exp(-log(scale[i]))))
        loglike_pred_stay[i] <- dgamma(pred_t[i], shape = theta_stay, rate = exp(-log(scale[i])), log = 1)
      }
      if (stay_family == "lognormal") {
        stay[i] ~ dlnorm(meanlog = log(scale[i]), sdlog = theta_stay)
        pred_t[i] ~ dlnorm(meanlog = log(scale[i]), sdlog = theta_stay)
        loglike_obs_stay[i] <- (1 - step(censored[i] - 0.5)) * dlnorm(stay[i], meanlog = log(scale[i]), sdlog = theta_stay, log = 1) +
          step(censored[i] - 0.5) * log(1 - plnorm(c_time[i], meanlog = log(scale[i]), sdlog = theta_stay))
        loglike_pred_stay[i] <- dlnorm(pred_t[i], meanlog = log(scale[i]), sdlog = theta_stay, log = 1)
        meanlog[i] <- log(scale[i])
      }
      if (stay_family == "weibull") {
        stay[i] ~ dweibull(shape = theta_stay, scale = scale[i])
        pred_t[i] ~ dweibull(shape = theta_stay, scale = scale[i])
        loglike_obs_stay[i] <- (1 - step(censored[i] - 0.5)) * dweibull(stay[i], shape = theta_stay, scale = scale[i], log = 1) +
          step(censored[i] - 0.5) * log(1 - pweibull(c_time[i], shape = theta_stay, scale = scale[i]))
        loglike_pred_stay[i] <- dweibull(pred_t[i], shape = theta_stay, scale = scale[i], log = 1)
      }

      # Linear predictor on log staying-time scale, with optional covariates and
      # a station-level random effect.
      if (nPreds_stay > 1) {
        if (nLevels_stay == 0) {
          log(scale[i]) <- inprod(beta_stay[1:nPreds_stay], X_stay[i, 1:nPreds_stay])
        } else {
          log(scale[i]) <- inprod(beta_stay[1:nPreds_stay], X_stay[i, 1:nPreds_stay]) + random_effect_stay[group_stay[i]]
        }
      } else {
        if (nLevels_stay == 0) {
          log(scale[i]) <- beta_stay[1]
        } else {
          log(scale[i]) <- beta_stay[1] + random_effect_stay[group_stay[i]]
        }
      }
    }

    # Priors for the staying-time model.
    theta_stay ~ dgamma(1, 1)
    if (stay_family == "lognormal") { sdlog <- theta_stay } else { shape <- theta_stay }
    for (j in 1:nPreds_stay) { beta_stay[j] ~ dnorm(0, sd = 5) }
    if (nLevels_stay > 0) {
      for (k in 1:nLevels_stay) { random_effect_stay[k] ~ dnorm(0, sd = sigma_stay) }
      sigma_stay ~ T(dnorm(0, sd = 100), 0, 5)
    }

    # Mean staying time implied by the fitted distribution (this is the \eqn{\bar t}
    # that enters the REST density equation).
    if (nPreds_stay == 1) {
      if (stay_family == "exponential") { mean_stay <- exp(beta_stay[1]) }
      if (stay_family == "gamma") { mean_stay <- theta_stay * exp(beta_stay[1]) }
      if (stay_family == "lognormal") { mean_stay <- exp(beta_stay[1] + theta_stay ^ 2 / 2) }
      if (stay_family == "weibull") { mean_stay <- lgamma(1 + 1 / theta_stay) + exp(beta_stay[1]) }
    }
    if (nPreds_stay > 1) {
      if (stay_family == "exponential") { for (i in 1:N_station) { mean_stay[i] <- exp(inprod(beta_stay[1:nPreds_stay], X_stay[i, 1:nPreds_stay])) } }
      if (stay_family == "gamma") { for (i in 1:N_station) { mean_stay[i] <- theta_stay * exp(inprod(beta_stay[1:nPreds_stay], X_stay[i, 1:nPreds_stay])) } }
      if (stay_family == "lognormal") { for (i in 1:N_station) { mean_stay[i] <- exp(inprod(beta_stay[1:nPreds_stay], X_stay[i, 1:nPreds_stay]) + theta_stay ^ 2 / 2) } }
      if (stay_family == "weibull") { for (i in 1:N_station) { mean_stay[i] <- lgamma(1 + 1 / theta_stay) + exp(inprod(beta_stay[1:nPreds_stay], X_stay[i, 1:nPreds_stay])) } }
    }
  })
}

#' Encounter sub-model + REST density equation (original REST)
#' @keywords internal
#' @noRd
rest_block_rest <- function() {
  quote({
    # Number of passes Y per station ~ negative binomial (overdispersed Poisson).
    for (i in 1:N_station) {
      y[i] ~ dnbinom(size = size, prob = p[i])
      p[i] <- size / (size + mu[i])
      y_rep[i] ~ dnbinom(size = size, prob = p[i])
      loglike_obs_y[i]  <- dnbinom(y[i], size, p[i], log = 1)
      loglike_pred_y[i] <- dnbinom(y_rep[i], size, p[i], log = 1)
    }
    size ~ dgamma(1, 1)

    # REST equation on the log scale: expected passes
    #   log(mu) = log(D) + log(S) + log(T) - log(mean_stay) + log(p_act)
    # so density D is identified from Y, effort and staying time.
    if (nPreds_density == 1) {
      for (i in 1:N_station) {
        if (nPreds_stay == 1) {
          log(mu[i]) <- log(density) + log(S[i]) + log(N_period[i]) - log(mean_stay) + log(activity_proportion)
        } else {
          log(mu[i]) <- log(density) + log(S[i]) + log(N_period[i]) - log(mean_stay[i]) + log(activity_proportion)
        }
      }
      log(density) <- beta_density
      beta_density ~ dnorm(0, sd = 100)
    }
    if (nPreds_density > 1) {
      for (i in 1:N_station) {
        if (nPreds_stay == 1) {
          log(mu[i]) <- log_local_density[i] + log(S[i]) + log(N_period[i]) - log(mean_stay) + log(activity_proportion)
        } else {
          log(mu[i]) <- log(density) + log(S[i]) + log(N_period[i]) - log(mean_stay[i]) + log(activity_proportion)
        }
        log_local_density[i] <- inprod(beta_density[1:nPreds_density], X_density[i, 1:nPreds_density])
      }
      for (j in 1:nPreds_density) { beta_density[j] ~ dnorm(0, sd = 100) }
      for (i in 1:N_station) {
        density[i] <- exp(inprod(beta_density[1:nPreds_density], X_density[i, 1:nPreds_density]))
      }
    }
  })
}

#' Encounter sub-model + REST density equation (RAD-REST extension)
#' @keywords internal
#' @noRd
rest_block_radrest <- function() {
  quote({
    # Pass-count classification: each video shows 0, 1, 2, ... passes. A
    # proportional-odds (cumulative logit) model gives the category probabilities,
    # and a Dirichlet-multinomial absorbs over-dispersion in the counts.
    for (k in 1:nPreds_enter) { beta_enter[k] ~ dnorm(0, sd = 2) }
    cutpoint[1] ~ dnorm(0, sd = 3)
    for (g in 2:(N_group - 1)) {
      delta[g - 1] ~ dgamma(1, 1)
      cutpoint[g] <- cutpoint[g - 1] + delta[g - 1]   # ordered cut-points
    }
    theta_enter ~ dgamma(2, 0.1)

    for (i in 1:N_station) {
      # Linear predictor for the pass model. The single-predictor case is written
      # without inprod() because nimble cannot compile a degenerate 1:1 index range.
      if (nPreds_enter == 1) {
        eta[i] <- beta_enter[1] * X_enter[i, 1]
      } else {
        eta[i] <- inprod(beta_enter[1:nPreds_enter], X_enter[i, 1:nPreds_enter])
      }
      for (g in 1:(N_group - 1)) { cum_p[i, g] <- ilogit(cutpoint[g] - eta[i]) }
      p_expected[i, 1] <- cum_p[i, 1]
      for (g in 2:(N_group - 1)) { p_expected[i, g] <- cum_p[i, g] - cum_p[i, g - 1] }
      p_expected[i, N_group] <- 1 - cum_p[i, N_group - 1]
      for (g in 1:N_group) { alpha_Dirichlet[i, g] <- theta_enter * p_expected[i, g] }

      # Mean number of passes per detected video. `pass_count` is a constant
      # vector (0, 1, 2, ...) giving the passes each category represents, so this
      # is just E[passes]. A tiny floor keeps log(mean_pass) finite. (Using a
      # constant vector here avoids an inline 1:(N_group-1) sequence, which
      # nimble cannot compile inside arithmetic.)
      mean_pass[i] <- inprod(p_expected[i, 1:N_group], pass_count[1:N_group]) + 0.001

      y[i, 1:N_group] ~ ddirchmulti(alpha_Dirichlet[i, 1:N_group], N_judge[i])
      pred_y[i, 1:N_group] ~ ddirchmulti(alpha_Dirichlet[i, 1:N_group], N_judge[i])
      loglike_obs_y[i]  <- ddirchmulti(y[i, 1:N_group], alpha_Dirichlet[i, 1:N_group], N_judge[i], log = TRUE)
      loglike_pred_y[i] <- ddirchmulti(pred_y[i, 1:N_group], alpha_Dirichlet[i, 1:N_group], N_judge[i], log = TRUE)
    }

    # Number of detected videos ~ negative binomial.
    for (i in 1:N_station) {
      N_detection[i] ~ dnbinom(size = size, prob = p[i])
      p[i] <- size / (size + mu[i])
      N_detection_rep[i] ~ dnbinom(size = size, prob = p[i])
      loglike_obs_detection[i]  <- dnbinom(N_detection[i], size, p[i], log = 1)
      loglike_pred_detection[i] <- dnbinom(N_detection_rep[i], size, p[i], log = 1)
    }
    size ~ dgamma(1, 1)

    # REST equation with the extra -log(mean_pass) correction for multi-pass videos.
    if (nPreds_density == 1) {
      for (i in 1:N_station) {
        if (nPreds_stay == 1) {
          log(mu[i]) <- log(density) + log(S[i]) + log(N_period[i]) - log(mean_stay) + log(activity_proportion) - log(mean_pass[i])
        } else {
          log(mu[i]) <- log(density) + log(S[i]) + log(N_period[i]) - log(mean_stay[i]) + log(activity_proportion) - log(mean_pass[i])
        }
      }
      log(density) <- beta_density
      beta_density ~ dnorm(0, sd = 5)
    }
    if (nPreds_density > 1) {
      for (i in 1:N_station) {
        if (nPreds_stay == 1) {
          log(mu[i]) <- log(density[i]) + log(S[i]) + log(N_period[i]) - log(mean_stay) + log(activity_proportion) - log(mean_pass[i])
        } else {
          log(mu[i]) <- log(density[i]) + log(S[i]) + log(N_period[i]) - log(mean_stay[i]) + log(activity_proportion) - log(mean_pass[i])
        }
        log(density[i]) <- inprod(beta_density[1:nPreds_density], X_density[i, 1:nPreds_density])
      }
      for (j in 1:nPreds_density) { beta_density[j] ~ dnorm(0, sd = 5) }
    }
  })
}

#' Build the full nimble code for a REST or RAD-REST model
#' @keywords internal
#' @noRd
rest_code <- function(model = c("REST", "RAD-REST")) {
  model <- match.arg(model)
  tail <- if (model == "REST") rest_block_rest() else rest_block_radrest()
  rest_combine(rest_block_stay(), tail)
}

#' Bayesian von Mises mixture for the activity proportion
#' @keywords internal
#' @noRd
rest_code_activity <- function() {
  nimble::nimbleCode({
    for (k in 1:(C - 1)) { v[k] ~ dbeta(1, alpha) }
    alpha ~ dgamma(1, 1)
    w[1:C] <- stick_breaking(v[1:(C - 1)]) # Dirichlet-process weights
    for (k in 1:C) {
      mu_mix[k] ~ dunif(0, 2 * 3.141592654)
      kappa_mix[k] ~ dgamma(1, 0.01)
    }
    for (n in 1:N) {
      group[n] ~ dcat(w[1:C])
      act_data[n] ~ dvonMises(mu_mix[group[n]], kappa_mix[group[n]])
      act_data_pred[n] ~ dvonMises(mu_mix[group[n]], kappa_mix[group[n]])
      loglike_obs_act[n]  <- dvonMises(act_data[n], mu_mix[group[n]], kappa_mix[group[n]], log = 1)
      loglike_pred_act[n] <- dvonMises(act_data_pred[n], mu_mix[group[n]], kappa_mix[group[n]], log = 1)
    }
    for (j in 1:ndens) {
      for (i in 1:C) { dens.cpt[i, j] <- w[i] * dvonMises(dens.x[j], mu_mix[i], kappa_mix[i], log = 0) }
      activity_density[j] <- sum(dens.cpt[1:C, j])
    }
    # Activity proportion = 1 / (2*pi * peak density) (Rowcliffe et al. 2014).
    activity_proportion <- 1.0 / (2 * 3.141592654 * max(activity_density[1:ndens]))
  })
}

#' Quoted worker setup: define + register the custom nimble distributions
#'
#' Returned expression is evaluated in each parallel worker's global environment
#' so the von Mises (and, for RAD-REST, Dirichlet-multinomial) distributions are
#' available when the model is compiled there.
#' @keywords internal
#' @noRd
rest_worker_setup <- function(dirmnom) {
  base <- quote({
    # nimble's compiler calls several of its own functions unqualified, so the
    # package must be attached (not merely loaded) on each worker. attachNamespace
    # does this without a library()/require() call (which R CMD check disallows
    # for a Suggests-only package).
    if (!"package:nimble" %in% search()) {
      requireNamespace("nimble", quietly = TRUE)
      attachNamespace("nimble")
    }
    dvonMises <- nimble::nimbleFunction(
      run = function(x = double(0), kappa = double(0), mu = double(0), log = integer(0)) {
        returnType(double(0))
        ccrit <- 1E-6; s <- 1; i <- 1; inc <- 1; x_2i <- 0; satisfied <- FALSE
        while (!satisfied) {
          x_2i <- kappa / (2 * i); inc <- inc * x_2i * x_2i; s <- s + inc
          i <- i + 1; satisfied <- inc < ccrit
        }
        prob <- exp(kappa * cos(x - mu)) / (2 * pi * s)
        if (log) return(log(prob)) else return(prob)
      })
    rvonMises <- nimble::nimbleFunction(
      run = function(n = integer(0), kappa = double(0), mu = double(0)) {
        returnType(double(0)); return(0)
      })
    .dist <- list(dvonMises = list(
      BUGSdist = "dvonMises(kappa, mu)",
      types = c("value = double(0)", "kappa = double(0)", "mu = double(0)"),
      pqAvail = FALSE))
  })
  dirmnom_block <- quote({
    ddirchmulti <- nimble::nimbleFunction(
      run = function(x = double(1), alpha = double(1), size = double(0), log = integer(0)) {
        returnType(double(0))
        logProb <- lgamma(size + 1) - sum(lgamma(x + 1)) + lgamma(sum(alpha)) -
          sum(lgamma(alpha)) + sum(lgamma(alpha + x)) - lgamma(sum(alpha) + size)
        if (log) return(logProb) else return(exp(logProb))
      })
    rdirchmulti <- nimble::nimbleFunction(
      run = function(n = integer(0), alpha = double(1), size = double(0)) {
        returnType(double(1))
        if (n != 1) print("rdirchmulti only allows n = 1; using n = 1.")
        p <- rdirch(1, alpha); return(rmulti(1, size = size, prob = p))
      })
    .dist$ddirchmulti <- list(
      BUGSdist = "ddirchmulti(alpha, size)",
      types = c("value = double(1)", "alpha = double(1)", "size = double(0)"),
      pqAvail = FALSE)
  })
  register <- quote({ suppressMessages(nimble::registerDistributions(.dist)) })
  if (dirmnom) rest_combine(base, dirmnom_block, register) else rest_combine(base, register)
}
