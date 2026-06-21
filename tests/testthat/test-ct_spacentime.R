# spaceNtime-style estimators (TTE / STE / ISE). These fit quickly on the small
# documented example data (no MCMC, no large bootstrap).

make_stn_data <- function() {
  list(
    data = dplyr::tibble(
      cam = c(1, 1, 2, 2, 2),
      datetime = as.POSIXct(c("2026-01-02 12:00:00", "2026-01-03 13:12:00",
                              "2026-01-02 12:00:00", "2026-01-02 14:00:00",
                              "2026-01-03 16:53:42"), tz = "Africa/Lagos"),
      count = c(1, 0, 2, 1, 2)
    ),
    deployment_data = dplyr::tibble(
      cam = c(1, 2, 2, 2),
      start = as.POSIXct(c("2025-12-01 15:00:00", "2025-12-08 00:00:00",
                           "2026-01-01 00:00:00", "2026-01-02 00:00:00"),
                         tz = "Africa/Lagos"),
      end = as.POSIXct(c("2026-01-05 00:00:00", "2025-12-19 03:30:00",
                         "2026-01-01 05:00:00", "2026-01-05 00:00:00"),
                       tz = "Africa/Lagos"),
      area = c(300, 200, 200, 450)
    )
  )
}

test_that("ct_fit_ste estimates abundance", {
  d <- make_stn_data()
  res <- ct_fit_ste(d$data, d$deployment_data,
                    sampling_frequency = 3600, sampling_length = 10,
                    study_area = 1e6, quiet = TRUE)
  expect_s3_class(res, "data.frame")
  expect_true("N" %in% names(res))
  expect_true(is.finite(res$N[1]))
})

test_that("ct_fit_ise estimates abundance", {
  d <- make_stn_data()
  res <- ct_fit_ise(d$data, d$deployment_data,
                    sampling_frequency = 3600, sampling_length = 10,
                    study_area = 1e6, quiet = TRUE)
  expect_s3_class(res, "data.frame")
  expect_true("N" %in% names(res))
  expect_true(is.finite(res$N[1]))
})

test_that("ct_fit_tte estimates abundance", {
  d <- make_stn_data()
  res <- ct_fit_tte(
    d$data, d$deployment_data,
    viewshed_transit_time = sqrt(mean(d$deployment_data$area)) / (30 / 3600),
    periods_per_occasion = 24,
    time_between_occasions = 2 * 3600,
    study_area = 1e6, quiet = TRUE
  )
  expect_s3_class(res, "data.frame")
  expect_true("N" %in% names(res))
})
