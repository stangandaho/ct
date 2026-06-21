test_that("ct_dissimilarity returns a dist object from raw records", {
  df <- dplyr::tibble(
    site = c("A", "A", "B", "B", "C"),
    species = c("sp1", "sp2", "sp1", "sp3", "sp2"),
    abundance = c(5, 2, 3, 1, 4)
  )
  d <- ct_dissimilarity(df, to_community = TRUE, site_column = site,
                        species_column = species, size_column = abundance,
                        method = "bray")
  expect_s3_class(d, "dist")
  expect_equal(attr(d, "Size"), 3)                  # three sites
})

test_that("ct_dissimilarity supports a binary (presence-absence) measure", {
  df <- dplyr::tibble(
    site = c("A", "A", "B", "B", "C"),
    species = c("sp1", "sp2", "sp1", "sp3", "sp2"),
    abundance = c(5, 2, 3, 1, 4)
  )
  d <- ct_dissimilarity(df, to_community = TRUE, site_column = site,
                        species_column = species, size_column = abundance,
                        method = "jaccard", binary = TRUE)
  expect_s3_class(d, "dist")
  expect_true(all(d >= 0 & d <= 1))
})
