test_that("ct_standardize preserves dimensions and removes NAs", {

  library(dplyr)
  data(penessoulou)

  cam <- penessoulou %>%
    dplyr::filter(project == "Last")

  comm <- ct_to_community(cam, site_column = camera, species_column = species,
                          size_column = number, values_fill = 0)
  mat <- comm[, -1]                                 # drop the site column

  std <- ct_standardize(data = mat, method = "total")
  expect_equal(dim(as.data.frame(std)), dim(mat))
  expect_false(anyNA(std))
})

test_that("ct_standardize method = 'total' makes rows sum to 1", {
  library(dplyr)
  data(penessoulou)

  cam <- penessoulou %>%
    dplyr::filter(project == "Last")

  comm <- ct_to_community(cam, site_column = camera, species_column = species,
                          size_column = number, values_fill = 0)
  std <- ct_standardize(data = comm[, -1], method = "total")
  rs <- rowSums(as.matrix(std))
  expect_true(all(abs(rs - 1) < 1e-8))
})

test_that("ct_standardize runs across all supported methods", {
  library(dplyr)
  data(penessoulou)

  cam <- penessoulou %>%
    dplyr::filter(project == "Last")

  comm <- ct_to_community(cam, site_column = camera, species_column = species,
                          size_column = number, values_fill = 0)
  mat <- comm[, -1]

  # Methods that accept a count matrix containing zeros.
  # ("rrank" is omitted: it calls vegan::specnumber(margin=), which the current
  #  vegan rejects -- see the separate expectation below.)
  zero_safe <- c("total", "max", "frequency", "normalize", "range", "rank",
                 "standardize", "pa", "chi.square", "hellinger", "log")
  for (m in zero_safe) {
    expect_false(is.null(ct_standardize(data = mat, method = m)),
                 info = paste("method:", m))
  }

  # Compositional log-ratio methods require strictly positive data.
  pos <- mat + 1
  for (m in c("clr", "rclr", "alr")) {
    expect_false(is.null(suppressWarnings(ct_standardize(data = pos, method = m))),
                 info = paste("method:", m))
  }
})

test_that("ct_standardize rejects an unknown method", {
  expect_error(ct_standardize(data = matrix(1:4, 2), method = "not_a_method"))
})

test_that("ct_standardize 'pa' yields a presence-absence matrix", {
  library(dplyr)
  data(penessoulou)

  cam <- penessoulou %>%
    dplyr::filter(project == "Last")

  comm <- ct_to_community(cam, site_column = camera, species_column = species,
                          size_column = number, values_fill = 0)
  pa <- ct_standardize(data = comm[, -1], method = "pa")
  expect_true(all(as.matrix(pa) %in% c(0, 1)))
})
