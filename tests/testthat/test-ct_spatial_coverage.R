test_that("ct_spatial_coverage returns a raster, bandwidth and stats", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")

  data(penessoulou)
  cam <- penessoulou %>%
    dplyr::filter(project == "First") %>%
    dplyr::filter(species == "Erythrocebus patas", number > 0)


  spc <- ct_spatial_coverage(
    data = cam,
    site_column = camera,
    longitude = longitude,
    latitude = latitude,
    crs = "EPSG:32631",
    resolution = 100,
    isopleth = 0.95,
    n_boot = 10
  )

  expect_named(spc, c("Coverage raster", "Bandwidth", "Coverage stats"))
  expect_s4_class(spc[["Coverage raster"]], "SpatRaster")
  expect_s3_class(spc[["Coverage stats"]], "data.frame")
  expect_true("sigma" %in% names(spc[["Bandwidth"]]))
})
