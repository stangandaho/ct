test_that("ct_spatial_coverage returns a raster, bandwidth and stats", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")

  f <- system.file("penessoulou_season2.csv", package = "ct")
  skip_if(f == "", "bundled CSV not found")

  cam <- read.csv(f)
  cam <- cam[cam$Species == "Erythrocebus patas" & cam$Count > 0, ]

  spc <- ct_spatial_coverage(
    data = cam,
    site_column = Camera,
    longitude = Longitude,
    latitude = Latitude,
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
