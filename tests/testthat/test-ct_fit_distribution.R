test_that("Poisson fit recovers lambda and returns the expected columns", {
  set.seed(1)
  x <- stats::rpois(2000, 4)
  res <- ct_fit_distribution(x, "poisson")
  expect_s3_class(res, "tbl_df")
  expect_equal(res$distribution, "poisson")
  expect_equal(res$lambda, 4, tolerance = 0.1)
  expect_true(all(c("lambda", "lambda_se", "loglik", "aic", "bic", "n") %in% names(res)))
  expect_equal(res$n, 2000L)
})

test_that("Negative binomial fit recovers size and mu", {
  set.seed(2)
  x <- stats::rnbinom(3000, size = 2, mu = 5)
  res <- ct_fit_distribution(x, "nbinomial")
  expect_equal(res$distribution, "nbinomial")
  expect_equal(res$mu, 5, tolerance = 0.3)
  expect_equal(res$size, 2, tolerance = 0.6)
})

test_that("Binomial fit recovers the success probability", {
  set.seed(3)
  x <- stats::rbinom(2000, size = 1, prob = 0.3)
  res <- ct_fit_distribution(x, "binomial")
  expect_equal(res$distribution, "binomial")
  expect_equal(res$prob, 0.3, tolerance = 0.05)
  expect_equal(res$successes, sum(x))
})

test_that("binomial rejects non 0/1 input", {
  expect_error(ct_fit_distribution(c(0, 1, 2), "binomial"), "0 and 1")
})

test_that("unknown distribution is rejected", {
  expect_error(ct_fit_distribution(1:10, "gamma"))
})

test_that("NA counts are treated as zero", {
  res <- ct_fit_distribution(c(NA, 0, 0, 0), "poisson")
  expect_equal(res$lambda, 0)
})
