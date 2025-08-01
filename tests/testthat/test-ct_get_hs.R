
test_that("Get hierarchical subject in metadata", {
  skip('skip')
  image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")
  ct_remove_hs(image_path)

  null_output <- ct_get_hs(path = image_path)
  testthat::expect_equal(null_output, NULL)

  ct_create_hs(path = image_path, value = c("Species" = "Vulture"))
  sh_out <- ct_get_hs(path = image_path)
  testthat::expect_equal(sh_out, "Species|Vulture")

  testthat::expect_error(ct_get_hs())
  #unlink(image_path)
  unlink(paste0(image_path, "_original"))
})
