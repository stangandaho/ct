
test_that("Create hierarchical subject in metadata", {
  # Define the URL of the image to be downloaded
  skip('skip')
  image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")

  output <- ct_create_hs(path = image_path, value = c("Species" = "Vulture"))
  testthat::expect_equal(class(output), "noquote")

  # Complete HS to existing
  null_output2 <- ct_create_hs(path = image_path, value = c("Species" = "Vulture", "Sex" = "Female"))
  testthat::expect_equal(null_output2, "1 image files updated")

  # Wrong hirarchical subject format
  testthat::expect_error(ct_create_hs(path = image_path))
  testthat::expect_error(ct_create_hs(path = image_path, value = c("Species")))
  testthat::expect_error(ct_create_hs(path = image_path, value = c("Species" = "BBB", "Sex")))

  #unlink(image_path)
  unlink(paste0(image_path, "_original"))

})


