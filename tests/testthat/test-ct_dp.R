# Camera Trap Data Package (Camtrap DP) integration. ct_dp_example() ships with
# camtrapdp and loads offline; ct_dp_read() (remote URL) is not tested here.

test_that("ct_dp_example loads a Camtrap DP object", {
  skip_if_not_installed("camtrapdp")
  dp <- ct_dp_example()
  expect_s3_class(dp, "camtrapdp")
})

test_that("ct_dp_table extracts a table as a tibble", {
  skip_if_not_installed("camtrapdp")
  dp <- ct_dp_example()

  obs <- ct_dp_table(dp, "observations")
  expect_s3_class(obs, "tbl_df")
  expect_gt(nrow(obs), 0)

  deps <- ct_dp_table(dp, "deployments")
  expect_s3_class(deps, "tbl_df")

  deps <- ct_dp_table(dp, "media")
  expect_s3_class(deps, "tbl_df")

  deps <- ct_dp_table(dp, "events")
  expect_s3_class(deps, "tbl_df")

  deps <- ct_dp_table(dp, "taxa")
  expect_s3_class(deps, "tbl_df")
})

test_that("ct_dp_version returns the standard version", {
  skip_if_not_installed("camtrapdp")
  dp <- ct_dp_example()
  v <- ct_dp_version(dp)
  expect_true(nzchar(as.character(v)))
})

test_that("ct_dp_filter subsets a table and returns a Camtrap DP object", {
  skip_if_not_installed("camtrapdp")
  dp <- ct_dp_example()

  flt <- ct_dp_filter(package = dp, table = "observations",
                      scientificName == "Vulpes vulpes")
  expect_s3_class(flt, "camtrapdp")
  obs <- ct_dp_table(flt, "observations")
  expect_true(all(obs$scientificName == "Vulpes vulpes" | is.na(obs$scientificName)))

  flt <- ct_dp_filter(package = dp, table = "deployments")
  expect_s3_class(flt, "camtrapdp")

  flt <- ct_dp_filter(package = dp, table = "media")
  expect_s3_class(flt, "camtrapdp")

})
