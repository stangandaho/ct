fit_duiker_subset <- function(key, nadj) {
  data("duikers", package = "ct", envir = environment())
  set.seed(3)
  d <- duikers$DaytimeDistances
  names(d)[names(d) == "multiplier"] <- "fraction"
  d <- d[sample(nrow(d), round(0.05 * nrow(d))), ]
  cu <- Distance::convert_units("meter", NULL, "square kilometer")
  m <- suppressWarnings(suppressMessages(Distance::ds(
    d, transect = "point", key = key,
    adjustment = if (nadj > 0) "cos" else NULL,
    nadj = if (nadj > 0) nadj else NULL,
    cutpoints = c(seq(2, 8, 1), 10, 12, 15),
    truncation = list(left = 2, right = 15),
    convert_units = cu, er_var = "P2")))
  list(model = m, data = d)
}

test_that("bin-count likelihood, p and density reproduce Distance", {
  skip_on_cran()
  for (cfg in list(list("hn", 0), list("hr", 2))) {
    f <- fit_duiker_subset(cfg[[1]], cfg[[2]])
    m <- f$model
    expect_true(ds_fast_eligible(m, f$data))
    spec <- ds_fast_spec(m)
    d1 <- f$data
    d1$fraction <- 1
    tab <- ds_fast_station_table(d1, spec)
    counts <- colSums(tab$counts)
    expect_equal(sum(counts), m$dht$individuals$summary$n)
    expect_equal(ds_fast_nll(spec$par, counts, spec), -m$ddf$lnl, tolerance = 1e-8)
    pa <- ds_fast_pa(spec$par, spec)
    expect_equal(pa, unname(summary(m)$ds$average.p), tolerance = 1e-6)
    expect_equal(ds_fast_density(sum(counts), sum(tab$effort), pa,
                                 ds_fast_area_factor(m), 1),
                 m$dht$individuals$D$Estimate, tolerance = 1e-6)
    refit <- ds_fast_fit(counts, spec, ds_fast_starts(counts, spec))
    expect_true(refit$ok)
    expect_lte(refit$nll, -m$ddf$lnl + 1e-6)
  }
})

test_that("fast bootstrap returns a dht_bootstrap object Distance can summarise", {
  skip_on_cran()
  f <- fit_duiker_subset("hn", 0)
  set.seed(1)
  b <- ds_fast_bootstrap(f$model, f$data, n_bootstrap = 20,
                         multipliers = list(creation = data.frame(rate = 0.4, SE = 0.03)),
                         estimate = "density")
  expect_s3_class(b, "dht_bootstrap")
  expect_equal(attr(b, "nboot") - attr(b, "failures"), nrow(b))
  s <- summary(b)
  expect_true(all(c("median", "mean", "se", "lcl", "ucl", "cv") %in% names(s$tab)))
  expect_true(all(is.finite(b$Dhat)) && all(b$Dhat > 0))
})

test_that("models outside the fast path are not flagged as eligible", {
  skip_on_cran()
  f <- fit_duiker_subset("hn", 0)
  d2 <- f$data
  d2$Region.Label[1] <- "Other"
  expect_false(ds_fast_eligible(f$model, d2))
})
