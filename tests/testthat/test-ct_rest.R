# REST / RAD-REST data-preparation helpers (fast). The model fit itself
# (ct_fit_rest) compiles a nimble model and runs MCMC, so it is gated behind an
# opt-in environment variable to keep the routine test run fast.

test_that("ct_rest_stay builds staying-time records", {
  data(rest_detection)
  data(rest_station)
  stay <- ct_rest_stay(rest_detection, rest_station)
  expect_s3_class(stay, "data.frame")
  expect_true(all(c("Station", "Species", "Stay", "Cens") %in% names(stay)))
})

test_that("ct_rest_passes returns per-station passes for REST and RAD-REST", {
  data(rest_detection)
  data(rest_station)

  rest <- ct_rest_passes(rest_detection, rest_station, model = "REST")
  expect_s3_class(rest, "data.frame")
  expect_true(all(c("Station", "Species", "Y") %in% names(rest)))

  rad <- ct_rest_passes(rest_detection, rest_station, model = "RAD-REST")
  expect_true(any(grepl("^y_\\d+$", names(rad))))      # y_0, y_1, ... columns
})

test_that("ct_rest_effort adds an Effort column", {
  data(rest_detection)
  data(rest_station)
  stations <- ct_rest_passes(rest_detection, rest_station, model = "REST")
  eff <- ct_rest_effort(rest_detection, stations)
  expect_s3_class(eff, "data.frame")
  expect_true("Effort" %in% names(eff))
})

test_that("ct_rest_activity returns detection times in radians", {
  data(rest_detection)
  activity <- ct_rest_activity(rest_detection, independence_minutes = 30)
  expect_s3_class(activity, "data.frame")
  expect_true(all(c("Species", "time") %in% names(activity)))
  expect_true(all(activity$time >= 0 & activity$time <= 2 * pi, na.rm = TRUE))
})

test_that("ct_fit_rest returns a posterior density summary (opt-in, slow)", {
  skip_on_cran()
  skip_if_not_installed("nimble")
  skip_if_not(identical(Sys.getenv("CT_TEST_REST"), "true"),
              "set CT_TEST_REST=true to run the slow REST MCMC test")

  data(rest_detection)
  data(rest_station)
  stay <- ct_rest_stay(rest_detection, rest_station)
  stations <- ct_rest_effort(rest_detection,
                ct_rest_passes(rest_detection, rest_station, model = "REST"))
  activity <- ct_rest_activity(rest_detection)

  fit <- ct_fit_rest(
    stay_data = stay, station_data = stations, activity_data = activity,
    species = "Red duiker", focal_area = 3.0, model = "REST",
    stay_distribution = "lognormal",
    iterations = 400, burnin = 100, thin = 1, chains = 1, cores = 1, quiet = TRUE
  )
  expect_s3_class(fit, "ct_rest")
  expect_true("density" %in% fit$summary$Variable | any(grepl("density", fit$summary$Variable)))
})
