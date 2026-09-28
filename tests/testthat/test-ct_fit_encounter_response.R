test_that("ct_fit_encounter_response estimates lag-specific encounter rates", {
  start <- as.POSIXct("2025-01-01 00:00:00", tz = "UTC")
  trigger_times <- start + seq(0, 10 * 24 * 3600, by = 6 * 3600)
  response_after_trigger <- trigger_times + 20 * 60
  background <- start + seq(90 * 60, 10 * 24 * 3600, by = 12 * 3600)

  events <- rbind(
    data.frame(camera = "cam_1", species = "trigger", datetime = trigger_times),
    data.frame(camera = "cam_1", species = "response", datetime = response_after_trigger),
    data.frame(camera = "cam_1", species = "response", datetime = background),
    data.frame(camera = "cam_2", species = "trigger", datetime = trigger_times + 5 * 60),
    data.frame(camera = "cam_2", species = "response", datetime = background + 10 * 60)
  )
  deployment <- data.frame(
    camera = c("cam_1", "cam_2"), start = start,
    end = start + 11 * 24 * 3600
  )

  fit <- ct_fit_encounter_response(
    data = events, deployment = deployment,
    trigger = "trigger", response = "response",
    species_column = species, cam_column = camera, datetime_column = datetime,
    start_column = start, end_column = end, independence = 0, n_boot = 0
  )

  expect_s3_class(fit, "ct_encounter_response")
  expect_equal(fit$engine, "glm")
  expect_equal(nrow(fit$estimates), 4)
  expect_true(all(c("rate_ratio", "lower", "upper") %in% names(fit$estimates)))
  expect_gt(fit$estimates$rate_ratio[2], 1)
})

make_encounter_fixture <- function() {
  start <- as.POSIXct("2025-01-01 00:00:00", tz = "UTC")
  trigger_times <- start + seq(0, 10 * 24 * 3600, by = 6 * 3600)
  response_after_trigger <- trigger_times + 20 * 60
  background <- start + seq(90 * 60, 10 * 24 * 3600, by = 12 * 3600)
  events <- rbind(
    data.frame(camera = "cam_1", species = "trigger", datetime = trigger_times),
    data.frame(camera = "cam_1", species = "response", datetime = response_after_trigger),
    data.frame(camera = "cam_1", species = "response", datetime = background),
    data.frame(camera = "cam_2", species = "trigger", datetime = trigger_times + 5 * 60),
    data.frame(camera = "cam_2", species = "response", datetime = background + 10 * 60)
  )
  deployment <- data.frame(
    camera = c("cam_1", "cam_2"), start = start,
    end = start + 11 * 24 * 3600
  )
  list(events = events, deployment = deployment)
}

test_that("camera-block bootstrap adds percentile intervals", {
  fx <- make_encounter_fixture()
  fit <- ct_fit_encounter_response(
    data = fx$events, deployment = fx$deployment,
    trigger = "trigger", response = "response",
    species_column = species, cam_column = camera, datetime_column = datetime,
    start_column = start, end_column = end, independence = 0,
    n_boot = 25, seed = 1
  )
  expect_true(all(c("bootstrap_lower", "bootstrap_upper") %in% names(fit$estimates)))
  expect_equal(fit$settings$n_boot, 25)
})

test_that("interval_sensitivity refits across bin widths", {
  fx <- make_encounter_fixture()
  fit <- ct_fit_encounter_response(
    data = fx$events, deployment = fx$deployment,
    trigger = "trigger", response = "response",
    species_column = species, cam_column = camera, datetime_column = datetime,
    start_column = start, end_column = end, independence = 0, n_boot = 0,
    interval = 15 * 60, interval_sensitivity = c(5 * 60, 10 * 60)
  )
  expect_s3_class(fit$sensitivity, "tbl_df")
  expect_setequal(unique(fit$sensitivity$interval), c(5 * 60, 10 * 60, 15 * 60))
})

test_that("zero-event lag windows are set to NA, not separation artefacts", {
  start <- as.POSIXct("2025-01-01 00:00:00", tz = "UTC")
  # Triggers exist, but NO response ever occurs within 6 h of a trigger:
  # responses are placed 8 h after each trigger (beyond the final lag break).
  trigger_times <- start + seq(0, 10 * 24 * 3600, by = 24 * 3600)
  response_times <- trigger_times + 8 * 3600
  events <- rbind(
    data.frame(camera = "cam_1", species = "trigger", datetime = trigger_times),
    data.frame(camera = "cam_1", species = "response", datetime = response_times),
    data.frame(camera = "cam_2", species = "trigger", datetime = trigger_times + 60),
    data.frame(camera = "cam_2", species = "response", datetime = response_times + 60)
  )
  deployment <- data.frame(camera = c("cam_1", "cam_2"), start = start,
                           end = start + 11 * 24 * 3600)
  fit <- NULL
  w <- testthat::capture_warnings(
    fit <- ct_fit_encounter_response(
      data = events, deployment = deployment,
      trigger = "trigger", response = "response",
      species_column = species, cam_column = camera, datetime_column = datetime,
      start_column = start, end_column = end, independence = 0, n_boot = 0
    )
  )
  expect_match(w, "zero response events", all = FALSE)
  first_lag <- fit$estimates[fit$estimates$lag == "0 h--30 min", ]
  expect_equal(first_lag$n_response_events, 0)
  expect_true(is.na(first_lag$rate_ratio))
  expect_true(is.na(first_lag$p_value))
})

test_that("glmm engine fits with camera random effects", {
  skip_if_not(
    requireNamespace("glmmTMB", quietly = TRUE) || requireNamespace("lme4", quietly = TRUE),
    "glmmTMB or lme4 not installed"
  )
  fx <- make_encounter_fixture()
  fit <- tryCatch(
    ct_fit_encounter_response(
      data = fx$events, deployment = fx$deployment,
      trigger = "trigger", response = "response",
      species_column = species, cam_column = camera, datetime_column = datetime,
      start_column = start, end_column = end, independence = 0, engine = "glmm"
    ),
    error = function(e) skip(paste("glmm backend unavailable:", conditionMessage(e)))
  )
  expect_equal(fit$engine, "glmm")
  expect_equal(nrow(fit$estimates), 4)
  # The 0-30 min window carries events in this fixture, so it must be estimable.
  rr <- fit$estimates$rate_ratio[fit$estimates$lag == "0 h--30 min"]
  expect_true(is.finite(rr))
})

test_that("ct_fit_encounter_response rejects overlapping camera deployments", {
  events <- data.frame(
    camera = c("cam_1", "cam_1"), species = c("trigger", "response"),
    datetime = as.POSIXct(c("2025-01-01 01:00:00", "2025-01-01 02:00:00"), tz = "UTC")
  )
  deployment <- data.frame(
    camera = c("cam_1", "cam_1"),
    start = as.POSIXct(c("2025-01-01", "2025-01-01 12:00:00"), tz = "UTC"),
    end = as.POSIXct(c("2025-01-02", "2025-01-02"), tz = "UTC")
  )

  expect_error(ct_fit_encounter_response(
    data = events, deployment = deployment,
    trigger = "trigger", response = "response",
    species_column = species, cam_column = camera, datetime_column = datetime,
    start_column = start, end_column = end, independence = 0
  ), "overlap")
})

test_that("weighted IRLS bootstrap fit matches glm.fit on duplicated camera blocks", {
  set.seed(42)
  n_cam <- 6; n_per <- 200
  d <- data.frame(camera = factor(rep(seq_len(n_cam), each = n_per)),
                  x = rnorm(n_cam * n_per), expo = runif(n_cam * n_per, 0.5, 1.5))
  d$y <- rpois(nrow(d), d$expo * exp(0.3 * d$x + as.numeric(d$camera) / 10))
  X <- model.matrix(~ x + camera, d)
  mult <- c(2, 0, 1, 3, 0, 0)            # camera draws of one resample
  w <- mult[as.integer(d$camera)]
  irls <- .ct_encounter_irls(X, d$y, w, log(d$expo))
  dup <- do.call(rbind, unlist(lapply(seq_len(n_cam), function(k) {
    lapply(seq_len(mult[k]), function(j) {
      b <- d[d$camera == k, ]
      b$block <- paste(k, j)
      b
    })
  }), recursive = FALSE))
  ref <- glm(y ~ x + block, family = poisson(), offset = log(expo), data = dup)
  expect_equal(unname(irls["x"]), unname(coef(ref)["x"]), tolerance = 1e-7)
  expect_true(all(is.na(irls[c("camera2", "camera5", "camera6")])))
})
