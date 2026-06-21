test_that("ct_describe_df summarises selected columns without error", {
  df <- data.frame(
    x = c(1:3, NA),
    y = c(3:4, NA, NA),
    z = c("A", "A", "B", "A")
  )
  out <- ct_describe_df(df, y, x, z,
                        fn = list("sum" = list(na.rm = TRUE),
                                  "sd" = list(na.rm = TRUE)))
  expect_false(is.null(out))
})

test_that("ct_describe_df defaults to all columns when none are selected", {
  df <- data.frame(a = 1:5, b = letters[1:5])
  expect_no_error(ct_describe_df(df))
})

test_that("ct_describe_df errors on an unknown column", {
  df <- data.frame(a = 1:5)
  expect_error(ct_describe_df(df, not_here))
})
