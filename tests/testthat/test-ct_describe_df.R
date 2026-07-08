test_that("ct_describe_df summarises selected columns without error", {
  df <- data.frame(
    x = c(1:3, NA),
    y = c(3:4, NA, NA),
    z = c("A", "A", "B", "A")
  )
  out <- ct_describe_df(df, y, x, z,
                        fn = list("sum" = list(na.rm = TRUE),
                                  "sd" = list(na.rm = TRUE)),
                        by_group = FALSE
                        )
  expect_false(is.null(out))
})

test_that("ct_describe_df defaults to all columns when none are selected", {
  df <- data.frame(a = 1:5, b = letters[1:5])
  expect_no_error(ct_describe_df(df, by_group = FALSE))
})

test_that("ct_describe_df errors on an unknown column", {
  df <- data.frame(a = 1:5)
  expect_error(ct_describe_df(df, not_here, by_group = FALSE))

  df <- data.frame(a = 1:5, b = 1:5)
  expect_error(ct_describe_df(df, a, not_here, by_group = FALSE))
})

test_that("ct_describe_df by group", {
  data("penessoulou")

  descr <- penessoulou %>%
    dplyr::filter(project == "Last") %>%
    dplyr::select(species, number) %>%
    ct_describe_df(by_group = TRUE)

  expect_s3_class(descr, "tbl")

})
