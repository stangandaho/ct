test_that("ct_temporal_shift (plot = FALSE) returns the expected columns", {
  set.seed(1)
  fp <- runif(80, 1.5, 3.5)
  sp <- runif(80, 2.0, 4.0)

  res <- ct_temporal_shift(fp, sp, plot = FALSE, n_boot = 0)
  expect_s3_class(res, "data.frame")
  expect_true(all(c("First period range", "Second period range",
                    "Shift size (in hour)", "Displacement (in hour)",
                    "Move") %in% names(res)))
})

test_that("Displacement captures a pure time shift that Shift size misses", {
  set.seed(1)
  hr2rad <- function(h) h / 24 * 2 * pi
  p1 <- hr2rad(rnorm(200, 10, 1)) %% (2 * pi)       # active ~10:00
  p2 <- hr2rad(rnorm(200, 13, 1)) %% (2 * pi)       # active ~13:00 (3 h later)

  res <- ct_temporal_shift(p1, p2, plot = FALSE, n_boot = 0)
  expect_lt(abs(res[["Shift size (in hour)"]]), 1)  # duration barely changes
  expect_gt(res[["Displacement (in hour)"]], 2)     # window slid ~3 h later
  expect_identical(res[["Move"]], "Forward")
})

test_that("bootstrap CI columns appear only when n_boot > 0", {
  set.seed(1)
  fp <- runif(60, 1.5, 3.5)
  sp <- runif(60, 2.0, 4.0)

  res <- ct_temporal_shift(fp, sp, plot = FALSE, n_boot = 50, boot_ci = 0.95)
  expect_true(any(grepl("Shift CI lower", names(res))))
  expect_true(any(grepl("Shift CI upper", names(res))))
})

test_that("period_names relabels the plot legend", {
  set.seed(1)
  fp <- runif(60, 1.5, 3.5)
  sp <- runif(60, 2.0, 4.0)

  grDevices::pdf(NULL)                               # swallow the printed plot
  on.exit(grDevices::dev.off(), add = TRUE)

  res <- ct_temporal_shift(fp, sp, plot = TRUE, n_boot = 0,
                           period_names = c("Dry", "Rainy"),
                           legend_title = "Season")
  expect_s3_class(res$plot, "ggplot")
  expect_identical(levels(res$plot$data$Period), c("Dry", "Rainy"))
})

test_that("ct_temporal_shift validates width_at and boot_ci", {
  expect_error(ct_temporal_shift(runif(20, 0, 2 * pi), runif(20, 0, 2 * pi),
                                 width_at = 2, plot = FALSE, n_boot = 0))
  expect_error(ct_temporal_shift(runif(20, 0, 2 * pi), runif(20, 0, 2 * pi),
                                 boot_ci = 1.5, n_boot = 10, plot = FALSE))
})
