# Building a ggplot does not open a graphics device, so these tests do not
# create Rplots.pdf. They check that the plotting helpers return ggplot objects.

test_that("ct_plot_density returns a ggplot", {
  set.seed(42)
  A <- runif(100, 0, 2 * pi)
  p <- ct_plot_density(A)
  expect_s3_class(p, "ggplot")
})

test_that("ct_plot_overlap_coef returns a ggplot for either triangle", {
  m <- matrix(c(1, 0.8, 0.7, 0.8, 1, 0.9, 0.7, 0.9, 1), ncol = 3)
  colnames(m) <- rownames(m) <- c("A", "B", "C")

  expect_s3_class(ct_plot_overlap_coef(m, side = "lower", show = "shape"), "ggplot")
  expect_s3_class(ct_plot_overlap_coef(m, side = "upper", show = "value"), "ggplot")
})

test_that("ct_plot_rose_diagram returns a ggplot", {
  set.seed(129)
  rf <- runif(123, 0, 6)
  p <- ct_plot_rose_diagram(data = NULL, times = rf, frequencies = "relative")
  expect_s3_class(p, "ggplot")
})
