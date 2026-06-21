test_that("ct_overlap_estimates returns coefficients in [0, 1]", {
  set.seed(42)
  species_A <- runif(100, 1.2, 2 * pi)
  species_B <- runif(100, 0.23, 2 * pi)

  all_est <- ct_overlap_estimates(species_A, species_B)
  expect_true(all(all_est >= 0 & all_est <= 1, na.rm = TRUE))

  one <- ct_overlap_estimates(species_A, species_B, type = "Dhat4")
  expect_length(as.numeric(one), 1)
  expect_true(one >= 0 && one <= 1)
})

test_that("ct_bootstrap / ct_boot_ci produce a sensible interval", {
  set.seed(42)
  species_A <- runif(100, 1.2, 2 * pi)
  species_B <- runif(100, 0.23, 2 * pi)

  est <- ct_overlap_estimates(species_A, species_B, type = "Dhat4")
  boots <- ct_bootstrap(species_A, species_B, 50, type = "Dhat4", cores = 1)

  expect_type(boots, "double")
  expect_length(boots, 50)

  ci <- ct_boot_ci(est, boots)
  expect_true(all(is.finite(unlist(ci))))
})

test_that("ct_resample + ct_boot_estimates form the two-step bootstrap", {
  set.seed(42)
  species_A <- runif(80, 1.2, 2 * pi)
  species_B <- runif(80, 0.23, 2 * pi)

  a_gen <- ct_resample(species_A, 30)
  b_gen <- ct_resample(species_B, 30)
  boots <- ct_boot_estimates(a_gen, b_gen, type = "Dhat4", cores = 1)

  expect_length(boots, 30)
  expect_true(all(boots >= 0 & boots <= 1, na.rm = TRUE))
})

test_that("ct_overlap_matrix returns a square species-by-species matrix", {
  df <- data.frame(
    species = c("A", "A", "A", "B", "B", "B"),
    time = c("10:30:00", "11:00:00", "23:00:00", "22:00:00", "02:00:00", "03:00:00")
  )
  m <- ct_overlap_matrix(df, species_column = species, time_column = time,
                         convert_time = TRUE, format = "%H:%M:%S")
  expect_true(is.matrix(m))
  expect_equal(dim(m), c(2, 2))
})
