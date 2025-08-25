# tests/testthat/test-ct_convert_unit.R
test_that("distance conversions work", {
  expect_equal(ct_convert_unit(1000, "m", "km"), 1)
  expect_equal(ct_convert_unit(1, "mile", "m"), 1609.344)
  expect_equal(ct_convert_unit(12, "in", "ft"), 1)
  expect_equal(ct_convert_unit(3, "yd", "ft"), 9)
})

test_that("area conversions work", {
  expect_equal(ct_convert_unit(1, "acre", "m2"), 4046.8564224, tolerance = 1e-6)
  expect_equal(ct_convert_unit(2, "km2", "hectare"), 200)
  expect_equal(ct_convert_unit(10000, "cm2", "m2"), 1)
})

test_that("angle conversions work", {
  expect_equal(ct_convert_unit(180, "deg", "rad"), pi, tolerance = 1e-6)
  expect_equal(ct_convert_unit(pi, "rad", "deg"), 180, tolerance = 1e-6)
  expect_equal(ct_convert_unit(400, "grad", "deg"), 360)
})

test_that("synonyms are recognized", {
  expect_equal(ct_convert_unit(1, "metre", "m"), 1)
  expect_equal(ct_convert_unit(1, "feet", "ft"), 1)
  expect_equal(ct_convert_unit(1, "°", "deg"), 1)
  expect_equal(ct_convert_unit(60, "arcmin", "deg"), 1)
})

test_that("identity conversion returns input", {
  expect_equal(ct_convert_unit(123, "m", "m"), 123)
  expect_equal(ct_convert_unit(5, "rad", "rad"), 5)
})

test_that("invalid or mismatched units error", {
  expect_error(ct_convert_unit(1, "meter", "acre"))   # distance vs area
  expect_error(ct_convert_unit(1, "banana", "m"))     # invalid
  expect_error(ct_convert_unit(1, "m", "apple"))      # invalid
})

test_that("show_units = TRUE returns a tibble", {
  tbl <- ct_convert_unit(show_units = TRUE)
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c("unit", "unit_name", "category") %in% names(tbl)))
  expect_true(any(tbl$unit == "m"))
  expect_true(any(tbl$unit_name == "m2"))
})
