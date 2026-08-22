test_that("ct_plot_overlap returns a ggplot", {
  set.seed(42)
  species_A <- runif(100, 0, 2 * pi)
  species_B <- runif(100, 0, 2 * pi)

  p <- ct_plot_overlap(A = species_A, B = species_B)
  expect_s3_class(p, "ggplot")
  expect_true("species" %in% names(p$data) || any(vapply(
    p$layers, function(layer) "species" %in% names(layer$data), logical(1)
  )))
})

test_that("ct_plot_overlap supports a labelled, styled species legend", {
  set.seed(42)
  p <- ct_plot_overlap(
    A = runif(100, 0, 2 * pi), B = runif(100, 0, 2 * pi),
    species_names = c("Leopard", "Duiker"), legend_title = "Animal",
    line_color = c("red", "blue"), line_type = c(1, 3), line_width = c(1, 2)
  )

  expect_identical(p$scales$get_scales("colour")$name, "Animal")
  expect_identical(unname(p$scales$get_scales("colour")$palette(2)), c("red", "blue"))
})

test_that("ct_plot_overlap accepts styling options", {
  set.seed(42)
  species_A <- runif(80, 0, 2 * pi)
  species_B <- runif(80, 0, 2 * pi)

  p <- ct_plot_overlap(A = species_A, B = species_B,
                       overlap_alpha = 0.5, line_color = c("red", "green"))
  expect_s3_class(p, "ggplot")
})
