# Random Encounter Model (REM) workflow on the bundled Camtrap DP example.

get_rem_inputs <- function() {
  data("ctdp")
  list(
    deployments = ctdp$data$deployments,
    observations = ctdp$data$observations %>%
      dplyr::filter(scientificName == "Vulpes vulpes")
  )
}

test_that("ct_get_effort returns per-deployment effort", {
  x <- get_rem_inputs()
  eff <- ct_get_effort(deployment_data = x$deployments,
                       deployment_column = deploymentID,
                       start_column = start, end_column = end)
  expect_s3_class(eff, "data.frame")
  expect_gt(nrow(eff), 0)
})

test_that("ct_traprate_data assembles detection + effort data", {
  x <- get_rem_inputs()
  tr <- ct_traprate_data(observation_data = x$observations,
                         deployment_data = x$deployments,
                         use_deployment = TRUE,
                         deployment_column = deploymentID,
                         datetime_column = timestamp,
                         start = start, end = "end")
  expect_false(is.null(tr))
})

test_that("ct_traprate_estimate produces a trap-rate estimate", {
  x <- get_rem_inputs()
  tr <- ct_traprate_data(observation_data = x$observations,
                         deployment_data = x$deployments,
                         use_deployment = FALSE,
                         deployment_column = deploymentID,
                         datetime_column = timestamp,
                         start = start, end = "end")
  est <- ct_traprate_estimate(data = tr, n_bootstrap = 50)
  expect_false(is.null(est))
})

test_that("ct_fit_activity returns an activity-level estimate", {
  x <- get_rem_inputs()
  rad <- ct_to_radian(times = x$observations$timestamp)
  fit_act <- ct_fit_activity(time_of_day = rad, sample = "model",
                             n_bootstrap = 50, show = FALSE)
  expect_true("activity" %in% names(fit_act))
  expect_true(is.finite(fit_act$activity[["act"]]))
})

test_that("ct_fit_rem returns a density estimate (small bootstrap)", {
  skip_on_cran()
  x <- get_rem_inputs()
  obs <- x$observations %>% dplyr::mutate(time_of_day = ct_to_radian(times = timestamp))

  trap_rate <- ct_traprate_data(observation_data = obs,
                                deployment_data = x$deployments,
                                deployment_column = deploymentID,
                                datetime_column = timestamp,
                                start = start, end = "end")

  rem_fit <- ct_fit_rem(data = obs, traprate_data = trap_rate,
                        time_of_day = time_of_day, n_bootstrap = 10)
  expect_s3_class(rem_fit, "data.frame")
  expect_true("estimate" %in% names(rem_fit))
})
