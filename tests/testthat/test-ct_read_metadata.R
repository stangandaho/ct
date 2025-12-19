test_that("Get image metadata", {
  image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")
  image_dir <- dirname(image_path)

  metadata_df <- ct_read_metadata(path = image_path)
  testthat::expect_true(is.data.frame(metadata_df))

  # Test for folder path
  ## Creat folder to copy image into.
  if (!dir.exists(file.path(image_dir, "unitest/justme"))) {
    dir.create(path = file.path(image_dir, "unitest/justme"), recursive = T)
  }
  ## Repeat image copy
  for (i in 1:3) {
    file.copy(from = image_path, to = paste0(image_dir, "/unitest/justme/", i, basename(image_path)))
  }

  metadata_df2 <- ct_read_metadata(path = paste0(image_dir, "/unitest"), recursive = T)
  testthat::expect_true(nrow(metadata_df2) == 3)

  # wrong file name
  testthat::expect_error(ct::ct_read_metadata(path = "no/file/path/image.jpeg"))
  testthat::expect_error(ct::ct_read_metadata(path = image_url))

})
