library(testthat)
library(dplyr)

# Example function definition here, assuming it's available as ct_independence

test_that("ct_independence handles data.frame input correctly", {
  # Test data
  df <- data.frame(datetime = as.POSIXct(c("2024-08-01 10:00:00", "2024-08-01 10:15:00",
                                           "2024-08-01 10:45:00", "2024-08-01 11:00:00")))

  # Test with threshold of 15 minutes (900 seconds)
  result <- ct_independence(data = df, datetime = "datetime", format = "%Y-%m-%d %H:%M:%S", threshold = 900)

  expect_contains(class(result), "tbl_df")
})

test_that("ct_independence returns only independent events when 'only' is TRUE", {
  # Test data
  df <- data.frame(datetime = as.POSIXct(c("2024-08-01 10:00:00", "2024-08-01 10:15:00",
                                           "2024-08-01 10:45:00", "2024-08-01 11:00:00")))

  result <- ct_independence(data = df, datetime = "datetime",
                              format = "%Y-%m-%d %H:%M:%S", threshold = 10, only = TRUE)

  expect_true(all(class(result) %in% c("data.frame", "tbl_df", "tbl")))
})


test_that("ct_independence handles missing datetime and format with data", {
  # Test data
  df <- data.frame(datetime = as.POSIXct(c("2024-08-01 10:00:00", "2024-08-01 10:15:00",
                                           "2024-08-01 10:45:00", "2024-08-01 11:00:00")))

  expect_error(ct_independence(data = df))
  expect_error(ct_independence(data = df, datetime = "datetime"))
})

test_that("ct_independence handles ambiguous datetime formats", {
  df <- data.frame(datetime = c("2024-08-01 10:00:00", "2024-08-01 10:15:00", "unknown datetime"),
                   value = c(1, 2, 3))

  expect_warning(ct_independence(data = df, datetime = "datetime", format = "%Y-%m-%d %H:%M:%S"))
})

test_that("ct_independence returns all rows when 'only' is FALSE", {
  # Test data
  df <- data.frame(datetime = as.POSIXct(c("2024-08-01 10:00:00", "2024-08-01 10:15:00",
                                           "2024-08-01 10:45:00", "2024-08-01 11:00:00")),
                   value = c(1, 2, 3, 4))

  result <- ct_independence(data = df, datetime = "datetime",
                              format = "%Y-%m-%d %H:%M:%S", threshold = 20, only = FALSE)
  expect_equal(nrow(result), nrow(df))
})


test_that("ct_independence handles empty data.frame correctly", {
  df <- data.frame(datetime = as.POSIXct(character(0)), value = numeric(0))

  expect_error(ct_independence(data = df, datetime = "datetime",
                                 format = "%Y-%m-%d %H:%M:%S"))
})

test_that("ct_independence ambiguous date", {
  df <- data.frame(datetime = c("202408-01 10:00:00", "2024-08-01 10:15:00",
                                           "2024-08-01 10:30:00"),
                   value = c(1, 2, 3))

  expect_warning(ct_independence(data = df, datetime = "datetime",
                                   format = "%Y-%m-%d %H:%M:%S", threshold = 10))

})
