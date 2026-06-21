make_obs <- function() {
  dplyr::tibble(
    site = c("A", "A", "B", "B", "C"),
    species = c("sp1", "sp2", "sp1", "sp3", "sp2"),
    abundance = c(5, 2, 3, 1, 4)
  )
}

test_that("ct_to_community returns one row per site and one column per species", {
  m <- ct_to_community(make_obs(), site_column = site, species_column = species,
                       values_fill = 0)
  expect_s3_class(m, "data.frame")
  expect_equal(nrow(m), 3)                          # A, B, C
  expect_true(all(c("sp1", "sp2", "sp3") %in% colnames(m)))
})

test_that("ct_to_community uses the abundance column when supplied", {
  m <- ct_to_community(make_obs(), site_column = site, species_column = species,
                       size_column = abundance, values_fill = 0)
  # site A has sp1 = 5 from the abundance column (not a count of rows)
  a_row <- m[m[[1]] == "A", ]
  expect_equal(as.numeric(a_row[["sp1"]]), 5)
})

test_that("ct_to_community requires site and species columns", {
  expect_error(ct_to_community(make_obs(), species_column = species))
})
