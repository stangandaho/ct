
test_that("Remove hierarchical subject in metadata", {
  skip('skip')
  image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")

  ct_create_hs(path = image_path, value = c("Species" = "Vulture"))
  ct::ct_remove_hs(path = image_path, hierarchy = c("Species" = "Vulture"))
  null_output <- ct::ct_get_hs(image_path)
  testthat::expect_equal(null_output, NULL)

  # To remove all HS
  ct_create_hs(path = image_path, value = c("Species" = "Vulture", "Sex" = "Female"))
  ct::ct_remove_hs(path = image_path, hierarchy = NULL)
  null_output2 <- ct::ct_get_hs(image_path)
  testthat::expect_equal(null_output2, NULL)

  # No change for unexisting HS
  testthat::expect_equal(ct::ct_remove_hs(path = image_path, c("Not" = "Exist")), NULL)

  #unlink(image_path)
  unlink(paste0(image_path, "_original"))

})


