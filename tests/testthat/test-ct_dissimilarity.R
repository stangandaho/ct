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
  expect_equal(attr(d, "Size"), 3) # three sites


  d <- ct_dissimilarity(df, to_community = TRUE, site_column = site,
                        species_column = species,
                        method = "bray")
  expect_s3_class(d, "dist")
  expect_equal(attr(d, "Size"), 3)
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


test_that("ct_dissimilarity supports maxtrix", {
  df <- data.frame(sp1 = 1:3, sp2 = 3:5) %>%
    as.matrix()
  rownames(df) <- c("cam1", "cam2", "cam3")
  d <- ct_dissimilarity(df, site_column = site,
                        method = "jaccard", binary = TRUE)
  expect_s3_class(d, "dist")
  expect_true(all(d >= 0 & d <= 1))
})
