library(testthat)

# Simple tests for ct_boot_ci function
test_that("ct_boot_ci function exists and is callable", {
  expect_true(exists("ct_boot_ci"))
  expect_true(is.function(ct_boot_ci))
})

test_that("ct_boot_ci has correct function signature", {
  args <- formals(ct_boot_ci)
  expect_true("t0" %in% names(args))
  expect_true("bt" %in% names(args))
  expect_true("conf" %in% names(args))
  expect_equal(args$conf, 0.95)  # Check default value
})

test_that("ct_boot_ci validates required parameters", {
  # Test missing parameters
  expect_error(ct_boot_ci(), "argument \"bt\" is missing")
  expect_error(ct_boot_ci(t0 = 0.5), "argument \"bt\" is missing")
})

test_that("ct_boot_ci returns correct structure with default confidence", {
  skip_if_not_installed("overlap")

  # Simple test data
  t0 <- 0.5
  bt <- c(0.45, 0.48, 0.52, 0.47, 0.53, 0.49, 0.51, 0.46, 0.54, 0.50)

  result <- ct_boot_ci(t0 = t0, bt = bt)

  # Check return structure
  expect_type(result, "double")
  expect_true(length(result) > 0)

})

test_that("ct_boot_ci works with custom confidence levels", {
  skip_if_not_installed("overlap")

  t0 <- 0.6
  bt <- c(0.55, 0.58, 0.62, 0.57, 0.63, 0.59, 0.61, 0.56, 0.64, 0.60)

  # Test 90% confidence
  result_90 <- ct_boot_ci(t0 = t0, bt = bt, conf = 0.90)
  expect_type(result_90, "double")

})
