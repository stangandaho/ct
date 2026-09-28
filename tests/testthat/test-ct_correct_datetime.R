library(ct)
library(testthat)
library(dplyr)

test_that("ct_correct_datetime applies corrections correctly", {
  # Sample data
  data <- data.frame(
    id = 1:3,
    datetime = c("2023-01-01 12:00:00", "2023-01-01 13:00:00", "2023-01-01 14:00:00"),
    deployment = "CAM01",
    stringsAsFactors = FALSE
  )

  corrector <- data.frame(
    deployment = "CAM01",
    sign = "+",
    datetimes = "2023-01-01 12:05:00",
    stringsAsFactors = FALSE
  )

  # Apply function
  corrected <- ct_correct_datetime(data, datetime, deployment, corrector, format = "%Y-%m-%d %H:%M:%S")

  # Check structure
  expect_s3_class(corrected, "data.frame")
  expect_true(all(c("corrected_datetime", "correction_applied", "time_offset_seconds", "corrector_reference") %in% names(corrected)))

  # Check datetime correction logic (+5 minutes)
  expect_equal(as.numeric(difftime(corrected$corrected_datetime[1], as.POSIXct(corrected$datetime[1], tz = "UTC"), units = "mins")), 5)
  expect_equal(unique(corrected$correction_applied), "+")
  expect_equal(unique(corrected$time_offset_seconds), 300)
})

test_that("ct_correct_datetime handles missing data for deployment", {
  data <- data.frame(
    datetime = "2023-01-01 12:00:00",
    deployment = "CAM02"
  )
  corrector <- data.frame(
    deployment = "CAM01",
    sign = "+",
    datetimes = "2023-01-01 12:05:00"
  )

  expect_warning(
    result <- ct_correct_datetime(data, datetime, deployment, corrector, format = "%Y-%m-%d %H:%M:%S")
  )

  expect_equal(nrow(result), 1)  # Original unchanged
})

test_that("ct_correct_datetime handles invalid inputs", {
  corrector <- data.frame(deployment = "CAM01", sign = "+", datetimes = "2023-01-01 12:00:00")

  expect_error(ct_correct_datetime("not_df", datetime, deployment, corrector))

  expect_error(ct_correct_datetime(data.frame(), datetime, deployment, "not_df"))

  # Missing required column
  bad_corrector <- data.frame(deployment = "CAM01", sign = "+")
  expect_error(ct_correct_datetime(data.frame(deployment = "CAM01",
                                              datetime = "2023-01-01"),
                                   datetime, deployment, bad_corrector))
})

test_that("ct_correct_datetime works with auto format detection", {
  data <- data.frame(
    id = 1,
    datetime = "2023/01/01 12:00",
    deployment = "CAM01"
  )
  corrector <- data.frame(
    deployment = "CAM01",
    sign = "-",
    datetimes = "2023/01/01 11:55"
  )

  result <- ct_correct_datetime(data, datetime, deployment, corrector)

  expect_s3_class(result$corrected_datetime, "POSIXct")
  expect_equal(as.numeric(difftime(as.POSIXct(result$datetime, format = "%Y/%m/%d %H:%M", tz = "UTC"), result$corrected_datetime, units = "mins")), 5)
})

test_that("ct_correct_datetime handles invalid sign", {
  data <- data.frame(
    datetime = "2023-01-01 12:00:00",
    deployment = "CAM01"
  )
  corrector <- data.frame(
    deployment = "CAM01",
    sign = "x",
    datetimes = "2023-01-01 12:05:00"
  )

  expect_error(ct_correct_datetime(data, datetime, deployment, corrector, format = "%Y-%m-%d %H:%M:%S"),
               "Invalid sign")
})

test_that("end_datetimes corrects linear clock drift", {
  d <- data.frame(cam = "C1",
                  dt = c("2024-01-01 00:00:00", "2024-01-06 00:00:00", "2024-01-11 00:00:00"))
  crt <- data.frame(cam = "C1", sign = "+",
                    datetimes = "2024-01-01 01:00:00",        # 1 h slow at the start
                    end_datetimes = "2024-01-11 01:10:00")    # 1 h 10 min slow at the end
  out <- ct_correct_datetime(d, dt, cam, crt)
  expect_equal(out$time_offset_seconds, c(3600, 3900, 4200))
  expect_equal(format(out$corrected_datetime, "%Y-%m-%d %H:%M:%S"),
               c("2024-01-01 01:00:00", "2024-01-06 01:05:00", "2024-01-11 01:10:00"))
  # without end_datetimes the offset stays constant
  out0 <- ct_correct_datetime(d, dt, cam, crt[, c("cam", "sign", "datetimes")])
  expect_equal(unique(out0$time_offset_seconds), 3600)
})

test_that("default UTC parsing keeps wall-clock times across a daylight-saving change", {
  # 2024-03-31 02:30 does not exist in Europe/Paris (clocks jump from 02:00 to 03:00)
  d <- data.frame(cam = "C1",
                  dt = c("2024-03-30 12:00:00", "2024-03-31 02:30:00", "2024-04-01 12:00:00"))
  crt <- data.frame(cam = "C1", sign = "+", datetimes = "2024-03-30 12:10:00")
  out <- ct_correct_datetime(d, dt, cam, crt)
  expect_false(anyNA(out$corrected_datetime))
  expect_equal(format(out$corrected_datetime, "%Y-%m-%d %H:%M:%S"),
               c("2024-03-30 12:10:00", "2024-03-31 02:40:00", "2024-04-01 12:10:00"))
  expect_equal(attr(out$corrected_datetime, "tzone"), "UTC")
})
