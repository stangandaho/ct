test_that("ct_stack_df row-binds frames with differing columns", {
  x <- data.frame(age = 15, fruit = "Apple", weight = 12)
  y <- data.frame(age = 51, fruit = "Tomato")
  z <- data.frame(age = 26, fruit = "Lemo", weight = 12, height = 45)

  out <- ct_stack_df(list(x, y, z))

  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 3)
  # union of all columns is preserved
  expect_true(all(c("age", "fruit", "weight", "height") %in% colnames(out)))
  # missing cells are filled with NA
  expect_true(is.na(out$height[out$fruit == "Apple"]))
})
