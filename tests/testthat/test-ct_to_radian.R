test_that("ct_to_radian maps clock times into [0, 2*pi]", {
  times <- c("00:00:00", "06:00:00", "12:00:00", "18:00:00")
  r <- ct_to_radian(times = times, format = "%H:%M:%S")

  expect_type(r, "double")
  expect_length(r, 4)
  expect_true(all(r >= 0 & r <= 2 * pi))
  expect_equal(r[1], 0, tolerance = 1e-6)         # midnight
  expect_equal(r[2], pi / 2, tolerance = 1e-6)    # 06:00
  expect_equal(r[3], pi, tolerance = 1e-6)        # noon
})

test_that("ct_to_radian appends a radian column when given a data frame", {
  df <- data.frame(times = c("06:00:00", "18:00:00"))
  out <- ct_to_radian(data = df, times = times, format = "%H:%M:%S")
  expect_s3_class(out, "data.frame")
  expect_true("time_radian" %in% names(out))
  expect_equal(out$time_radian[1], pi / 2, tolerance = 1e-6)
})

test_that("ct_to_radian errors when the column is absent", {
  df <- data.frame(times = "06:00:00")
  expect_error(ct_to_radian(data = df, times = not_a_column, format = "%H:%M:%S"))
})

test_that("ct_to_time inverts a radian into a clock string", {
  expect_type(ct_to_time(1.6), "character")
  expect_match(ct_to_time(pi), "^12:00")          # pi -> midday
  expect_match(ct_to_time(0), "^00:00")
})

test_that("ct_to_time rejects non-numeric input", {
  expect_error(ct_to_time("a"))
})
