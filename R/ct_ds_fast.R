# Fast bootstrap for camera trap distance sampling
#
# For an intercept-only detection function fitted to binned point-transect
# distances, the likelihood depends on the data only through the number of
# detections in each distance bin:
#
#   log L = sum_b n_b * (log I_b - log I_all),   I_b = int_bin g(r) r dr.
#
# mrds evaluates the same quantity, but rebuilds a character key for every
# observation at each likelihood call, which makes a refit on ~10^4 camera
# snapshots take minutes. Here each bootstrap replicate is reduced to a vector
# of bin counts and an effort total, the detection function is refitted from
# those counts, and density is computed as in Distance::bootdht(). The
# detection function, the monotonicity constraints (mrds reference points) and
# the covered area pi * (w^2 - left^2) follow mrds and Distance.


# Can the fitted model use the fast bootstrap?
ds_fast_eligible <- function(model, data) {
  o <- tryCatch(model$ddf$ds$aux$ddfobj, error = function(e) NULL)
  md <- model$ddf$meta.data
  if (is.null(o) || is.null(md)) return(FALSE)
  adj <- o$adjustment
  isTRUE(o$intercept.only) && isTRUE(md$binned) && isTRUE(md$point) &&
    o$type %in% c("hn", "hr", "unif") &&
    (is.null(adj) || (adj$series %in% c("cos", "poly") && !isTRUE(adj$exp) &&
                        identical(adj$scale, "width"))) &&
    length(unique(data$Region.Label)) == 1 &&
    isTRUE(all.equal(c(md$left, md$width), range(md$breaks)))
}


# Specification of the detection function, taken from the fitted mrds object.
ds_fast_spec <- function(model) {
  o <- model$ddf$ds$aux$ddfobj
  md <- model$ddf$meta.data
  aux <- model$ddf$ds$aux
  adj <- o$adjustment
  n_key <- switch(o$type, hn = 1L, hr = 2L, unif = 0L)
  gl <- gauss_legendre(24)
  list(key = o$type, n_key = n_key,
       series = if (is.null(adj)) NULL else adj$series,
       order = if (is.null(adj)) NULL else adj$order,
       width = md$width, left = md$left, breaks = md$breaks,
       mono = isTRUE(md$mono) && !is.null(adj),
       strict = isTRUE(md$mono.strict),
       mono_points = if (is.null(aux$mono.points)) 20 else aux$mono.points,
       nodes = gl$nodes, weights = gl$weights,
       par = unname(model$ddf$par))
}


# Gauss-Legendre nodes and weights on [-1, 1] (Golub-Welsch).
gauss_legendre <- function(n) {
  i <- seq_len(n - 1)
  b <- i / sqrt(4 * i^2 - 1)
  J <- matrix(0, n, n)
  J[cbind(i, i + 1)] <- b
  J[cbind(i + 1, i)] <- b
  e <- eigen(J, symmetric = TRUE)
  o <- order(e$values)
  list(nodes = e$values[o], weights = 2 * e$vectors[1, o]^2)
}


# Standardised detection function g(r) / g(0), as in mrds::detfct().
ds_fast_g <- function(r, par, spec) {
  key <- switch(spec$key,
    hn = exp(-(r / (sqrt(2) * exp(par[1])))^2),
    hr = 1 - exp(-(r / exp(par[2]))^(-exp(par[1]))),
    unif = rep(1, length(r)))
  if (is.null(spec$series)) return(key)
  a <- par[spec$n_key + seq_along(spec$order)]
  adj_fun <- function(x) {
    x <- x / spec$width
    s <- 0
    for (j in seq_along(spec$order)) {
      s <- s + a[j] * switch(spec$series,
                             cos = cos(spec$order[j] * pi * x),
                             poly = x^spec$order[j])
    }
    s
  }
  key * (1 + adj_fun(r)) / (1 + adj_fun(0))
}


# Integral of g(r) r over each distance bin.
ds_fast_bin_integrals <- function(par, spec) {
  lo <- utils::head(spec$breaks, -1)
  hi <- utils::tail(spec$breaks, -1)
  half <- (hi - lo) / 2
  mid <- (hi + lo) / 2
  r <- outer(half, spec$nodes) + mid
  f <- matrix(ds_fast_g(as.vector(r), par, spec), nrow = length(lo)) * r
  drop(f %*% spec$weights) * half
}


ds_fast_nll <- function(par, counts, spec) {
  ib <- ds_fast_bin_integrals(par, spec)
  if (any(!is.finite(ib)) || any(ib <= 0)) return(1e10)
  -sum(counts * (log(ib) - log(sum(ib))))
}


# Monotonicity constraints of mrds (flnl.constr), written as h(par) >= 0.
ds_fast_constraints <- function(par, spec) {
  nd <- spec$mono_points
  ref <- (seq_len(nd)^1.5) * spec$width / nd^1.5
  gv <- ds_fast_g(ref, par, spec)
  prev <- if (spec$strict) c(1, utils::head(gv, -1)) else rep(1, nd)
  c(prev - gv, gv)
}


# Maximum-likelihood fit from bin counts. Several starting points are tried
# and the best admissible optimum is kept.
ds_fast_fit <- function(counts, spec, starts = list(spec$par)) {
  if (length(spec$par) == 0) {
    return(list(par = numeric(0), nll = ds_fast_nll(numeric(0), counts, spec), ok = TRUE))
  }
  fn <- function(p) ds_fast_nll(p, counts, spec)
  best <- list(par = NA, nll = Inf, ok = FALSE)
  for (s in starts) {
    fit <- if (spec$mono) {
      tryCatch({
        res <- nloptr::nloptr(
          x0 = s, eval_f = fn,
          eval_grad_f = function(p) nloptr::nl.grad(p, fn),
          eval_g_ineq = function(p) -ds_fast_constraints(p, spec),
          eval_jac_g_ineq = function(p) nloptr::nl.jacobian(p, function(q) -ds_fast_constraints(q, spec)),
          opts = list(algorithm = "NLOPT_LD_SLSQP", xtol_rel = 1e-10,
                      ftol_rel = 1e-12, maxeval = 2000))
        list(par = res$solution, nll = res$objective,
             ok = res$status > 0 && all(ds_fast_constraints(res$solution, spec) >= -1e-6))
      }, error = function(e) NULL)
    } else {
      tryCatch({
        res <- stats::optim(s, fn, method = "BFGS", control = list(reltol = 1e-12, maxit = 1000))
        list(par = res$par, nll = res$value, ok = res$convergence == 0)
      }, error = function(e) NULL)
    }
    if (!is.null(fit) && fit$ok && is.finite(fit$nll) && fit$nll < best$nll) best <- fit
  }
  best
}


# Starting values: the full-data estimates, and (as mrds does) the key
# function fitted alone to these counts with zero adjustment terms.
ds_fast_starts <- function(counts, spec) {
  starts <- list(spec$par)
  if (!is.null(spec$series) && spec$n_key > 0) {
    key_spec <- spec
    key_spec$series <- NULL
    key_spec$order <- NULL
    key_spec$mono <- FALSE
    key_spec$par <- spec$par[seq_len(spec$n_key)]
    kf <- ds_fast_fit(counts, key_spec)
    if (kf$ok) starts <- c(starts, list(c(kf$par, rep(0, length(spec$order)))))
  }
  starts
}


# Average detection probability as reported by mrds (integral over [left, w]
# divided by w^2 / 2; the covered area carries the pi * (w^2 - left^2) term).
ds_fast_pa <- function(par, spec) {
  sum(ds_fast_bin_integrals(par, spec)) / (spec$width^2 / 2)
}


# Per-station bin counts and effort (Effort x sampling fraction).
ds_fast_station_table <- function(data, spec) {
  stations <- unique(as.character(data$Sample.Label))
  eff <- tapply(data$Effort * data$fraction, as.character(data$Sample.Label), `[`, 1)
  keep <- !is.na(data$distance) & data$distance >= spec$left & data$distance <= spec$width
  bin <- findInterval(data$distance[keep], spec$breaks, rightmost.closed = TRUE,
                      left.open = FALSE)
  nb <- length(spec$breaks) - 1
  lab <- factor(as.character(data$Sample.Label[keep]), levels = stations)
  counts <- as.matrix(table(lab, factor(bin, levels = seq_len(nb))))
  list(stations = stations, counts = counts, effort = as.numeric(eff[stations]))
}


# Covered area per unit of effort, read from the fitted model so that the
# unit conversion is exactly the one Distance applied.
ds_fast_area_factor <- function(model) {
  s <- model$dht$individuals$summary
  s$CoveredArea[1] / s$Effort[1]
}

# Density for given counts, effort (Effort x sampling fraction) and fit.
ds_fast_density <- function(n, effort, pa, area_factor, rate) {
  n / (effort * area_factor * pa) / rate
}


# Bootstrap over camera stations, mirroring Distance::bootdht() with
# resample_transects = TRUE for a single stratum.
ds_fast_bootstrap <- function(model, data, n_bootstrap, multipliers, estimate) {
  spec <- ds_fast_spec(model)
  area_factor <- ds_fast_area_factor(model)
  tab <- ds_fast_station_table(data, spec)
  fixed_rate <- prod(vapply(Filter(Negate(is.function), multipliers),
                            function(m) prod(m$rate), numeric(1)))
  if (!length(fixed_rate)) fixed_rate <- 1
  rate_funs <- Filter(is.function, multipliers)
  area <- unique(data$Area)[1]

  out <- vapply(seq_len(n_bootstrap), function(b) {
    idx <- sample.int(length(tab$stations), replace = TRUE)
    counts <- colSums(tab$counts[idx, , drop = FALSE])
    fit <- ds_fast_fit(counts, spec, ds_fast_starts(counts, spec))
    if (!fit$ok) return(NA_real_)
    rate <- fixed_rate * prod(vapply(rate_funs, function(f) f(), numeric(1)))
    d <- ds_fast_density(sum(counts), sum(tab$effort[idx]),
                         ds_fast_pa(fit$par, spec), area_factor, rate)
    if (estimate == "density") d else d * area
  }, numeric(1))

  ok <- is.finite(out)
  res <- data.frame(Label = "Total", est = out[ok], bootstrap_ID = which(ok))
  names(res)[2] <- if (estimate == "density") "Dhat" else "Nhat"
  attr(res, "nboot") <- n_bootstrap
  attr(res, "failures") <- sum(!ok)
  class(res) <- c("dht_bootstrap", "data.frame")
  res
}
