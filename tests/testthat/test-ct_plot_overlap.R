test_that("ct_plot_overlap returns a ggplot", {
  set.seed(42)
  species_A <- runif(100, 0, 2 * pi)
  species_B <- runif(100, 0, 2 * pi)

  p <- ct_plot_overlap(A = species_A, B = species_B)
  expect_s3_class(p, "ggplot")
})

test_that("ct_plot_overlap accepts styling and rug options", {
  set.seed(42)
  species_A <- runif(80, 0, 2 * pi)
  species_B <- runif(80, 0, 2 * pi)

  p <- ct_plot_overlap(A = species_A, B = species_B, rug = TRUE,
                       overlap_alpha = 0.5, line_color = c("red", "green"))
  expect_s3_class(p, "ggplot")
})
